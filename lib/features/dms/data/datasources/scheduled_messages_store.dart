import 'dart:async';
import 'dart:convert';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// A message the user wrote now but wants sent later, on this computer.
class ScheduledMessage {
  const ScheduledMessage({
    required this.id,
    required this.channelId,
    required this.conversationName,
    required this.content,
    required this.sendAt,
    required this.createdAt,
    this.isChannel = false,
    this.lastError,
    this.retryAt,
  });

  final String id;
  final String channelId;
  final String conversationName;
  final String content;

  /// When the message should go out. Kept unchanged after a failed attempt so
  /// the queue still shows the time the user picked; [retryAt] says when the
  /// next attempt happens.
  final DateTime sendAt;
  final DateTime createdAt;
  final bool isChannel;

  /// Why the last attempt failed, if it did. Cleared by an edit.
  final String? lastError;
  final DateTime? retryAt;

  ScheduledMessage copyWith({
    String? content,
    DateTime? sendAt,
    String? lastError,
    DateTime? retryAt,
    bool clearError = false,
  }) => ScheduledMessage(
    id: id,
    channelId: channelId,
    conversationName: conversationName,
    content: content ?? this.content,
    sendAt: sendAt ?? this.sendAt,
    createdAt: createdAt,
    isChannel: isChannel,
    lastError: clearError ? null : (lastError ?? this.lastError),
    retryAt: clearError ? null : (retryAt ?? this.retryAt),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'channelId': channelId,
    'conversationName': conversationName,
    'content': content,
    'sendAt': sendAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'isChannel': isChannel,
    if (lastError != null) 'lastError': lastError,
    if (retryAt != null) 'retryAt': retryAt!.toIso8601String(),
  };

  factory ScheduledMessage.fromJson(Map<String, dynamic> json) =>
      ScheduledMessage(
        id: json['id'] as String? ?? '',
        channelId: json['channelId'] as String? ?? '',
        conversationName: json['conversationName'] as String? ?? '',
        content: json['content'] as String? ?? '',
        sendAt:
            DateTime.tryParse(json['sendAt']?.toString() ?? '') ??
            DateTime.now(),
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        isChannel: json['isChannel'] as bool? ?? false,
        lastError: json['lastError'] as String?,
        retryAt: DateTime.tryParse(json['retryAt']?.toString() ?? ''),
      );
}

/// Messages waiting to be sent, keyed to the signed-in user.
///
/// A single timer is armed for the next due message, so scheduled messages
/// leave even when their conversation is not open. Sending is injected so this
/// class stays independent of the API client and can be tested with a fake
/// clock.
class ScheduledMessagesStore extends ChangeNotifier {
  ScheduledMessagesStore(
    this._storage, {
    required this.userId,
    this.clock = DateTime.now,
    Future<void> Function(ScheduledMessage message)? onSend,
    this.armTimers = true,
  }) : _onSend = onSend;

  /// How long to wait before trying a message whose send failed.
  static const retryDelay = Duration(minutes: 1);

  final SecureStorageService? _storage;
  final String userId;
  final DateTime Function() clock;
  final Future<void> Function(ScheduledMessage message)? _onSend;

  /// Tests turn this off so no timer outlives them; checkDue still runs.
  final bool armTimers;

  final List<ScheduledMessage> _items = [];
  bool _loaded = false;
  bool _disposed = false;
  bool _sending = false;
  int _counter = 0;
  Timer? _timer;

  String? get _storageKey =>
      userId.isEmpty ? null : 'scheduled_messages_$userId';

  bool get isLoaded => _loaded;

  /// Pending messages, soonest first.
  List<ScheduledMessage> get items {
    final sorted = [..._items]..sort((a, b) => a.sendAt.compareTo(b.sendAt));
    return List.unmodifiable(sorted);
  }

  Future<void> load() async {
    if (_loaded) return;
    final key = _storageKey;
    if (key != null) {
      try {
        final raw = await _storage?.readData(key);
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            _items
              ..clear()
              ..addAll(
                decoded
                    .whereType<Map<dynamic, dynamic>>()
                    .map(
                      (json) => ScheduledMessage.fromJson(
                        Map<String, dynamic>.from(json),
                      ),
                    )
                    .where((message) => message.id.isNotEmpty),
              );
          }
        }
      } catch (_) {
        // A corrupt entry must not stop the user from scheduling new ones.
      }
    }
    _loaded = true;
    if (_disposed) return;
    notifyListeners();
    // Messages that came due while the app was closed go out now.
    await checkDue();
  }

  Future<ScheduledMessage> add({
    required String channelId,
    required String conversationName,
    required String content,
    required DateTime sendAt,
    bool isChannel = false,
  }) async {
    final now = clock();
    final message = ScheduledMessage(
      id: 'scheduled-${now.microsecondsSinceEpoch}-${_counter++}',
      channelId: channelId,
      conversationName: conversationName,
      content: content,
      sendAt: sendAt.isBefore(now) ? now : sendAt,
      createdAt: now,
      isChannel: isChannel,
    );
    _items.add(message);
    await _persist();
    if (_disposed) return message;
    notifyListeners();
    _armTimer();
    return message;
  }

  Future<void> update(String id, {String? content, DateTime? sendAt}) async {
    final index = _items.indexWhere((message) => message.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(
      content: content,
      sendAt: sendAt,
      clearError: true,
    );
    await _persist();
    if (_disposed) return;
    notifyListeners();
    _armTimer();
  }

  Future<void> cancel(String id) async {
    final before = _items.length;
    _items.removeWhere((message) => message.id == id);
    if (_items.length == before) return;
    await _persist();
    if (_disposed) return;
    notifyListeners();
    _armTimer();
  }

  /// Sends everything that is due. Called by the timer, after loading, and by
  /// tests. Waits for an attempt already in flight instead of sending twice.
  Future<void> checkDue() async {
    if (!_loaded || _sending || _disposed) return;
    _sending = true;
    var changed = false;
    try {
      final now = clock();
      final due = _items
          .where((message) => !(message.retryAt ?? message.sendAt).isAfter(now))
          .toList();
      for (final message in due) {
        if (_onSend == null) break;
        try {
          await _onSend(message);
          _items.removeWhere((item) => item.id == message.id);
        } catch (_) {
          final index = _items.indexWhere((item) => item.id == message.id);
          if (index >= 0) {
            _items[index] = _items[index].copyWith(
              lastError: "Couldn't send. Retrying automatically.",
              retryAt: now.add(retryDelay),
            );
          }
        }
        changed = true;
      }
    } finally {
      _sending = false;
    }
    if (changed) await _persist();
    if (_disposed) return;
    if (changed) notifyListeners();
    _armTimer();
  }

  void _armTimer() {
    _timer?.cancel();
    if (!armTimers || _disposed || _items.isEmpty) return;
    final now = clock();
    DateTime? next;
    for (final message in _items) {
      final at = message.retryAt ?? message.sendAt;
      if (at.isAfter(now) && (next == null || at.isBefore(next))) next = at;
    }
    // Nothing left in the future: everything is due but could not be sent
    // (no transport yet, or a failed attempt), so try again shortly.
    _timer = Timer(
      next == null ? retryDelay : next.difference(now),
      () => unawaited(checkDue()),
    );
  }

  Future<void> _persist() async {
    final key = _storageKey;
    final storage = _storage;
    if (key == null || storage == null) return;
    try {
      await storage.writeData(
        key,
        jsonEncode([for (final message in _items) message.toJson()]),
      );
    } catch (_) {
      // Losing the saved copy is not worth surfacing; the timer still runs.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

final scheduledMessagesStoreProvider =
    ChangeNotifierProvider<ScheduledMessagesStore>((ref) {
      final userId = ref.watch(
        authNotifierProvider.select((state) => state.user?.id ?? ''),
      );
      final store = ScheduledMessagesStore(
        locator.isRegistered<SecureStorageService>()
            ? locator<SecureStorageService>()
            : null,
        userId: userId,
        onSend: (message) => ref
            .read(dmRepositoryProvider)
            .sendMessage(
              message.channelId,
              message.content,
              isChannel: message.isChannel,
            ),
      );
      unawaited(store.load());
      return store;
    });
