import 'dart:async';
import 'dart:convert';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// A reminder to come back to a message at a set time.
///
/// The text is a snapshot taken when the reminder is set, because the original
/// message may be edited or deleted before the reminder fires.
class MessageReminder {
  const MessageReminder({
    required this.messageId,
    required this.channelId,
    required this.conversationName,
    required this.participantId,
    required this.content,
    required this.remindAt,
    required this.createdAt,
  });

  final String messageId;
  final String channelId;
  final String conversationName;

  /// The other person in the DM, so the notification opens the conversation.
  final String participantId;

  final String content;
  final DateTime remindAt;
  final DateTime createdAt;

  /// One reminder per message: setting another replaces this one.
  String get id => '$channelId:$messageId';

  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'channelId': channelId,
    'conversationName': conversationName,
    'participantId': participantId,
    'content': content,
    'remindAt': remindAt.millisecondsSinceEpoch,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory MessageReminder.fromJson(Map<String, dynamic> json) =>
      MessageReminder(
        messageId: json['messageId'] as String? ?? '',
        channelId: json['channelId'] as String? ?? '',
        conversationName: json['conversationName'] as String? ?? '',
        participantId: json['participantId'] as String? ?? '',
        content: json['content'] as String? ?? '',
        remindAt: DateTime.fromMillisecondsSinceEpoch(
          json['remindAt'] as int? ?? 0,
        ),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          json['createdAt'] as int? ?? 0,
        ),
      );
}

/// The ready-made times offered when setting a reminder on a message.
enum ReminderPreset { in20Minutes, in1Hour, thisEvening, tomorrowMorning }

extension ReminderPresetTiming on ReminderPreset {
  String get label => switch (this) {
    ReminderPreset.in20Minutes => 'In 20 minutes',
    ReminderPreset.in1Hour => 'In 1 hour',
    ReminderPreset.thisEvening => 'This evening',
    ReminderPreset.tomorrowMorning => 'Tomorrow morning',
  };

  /// The local time this preset means when chosen at [now]. Evening and
  /// morning are wall-clock times, so a preset chosen after 6pm moves to the
  /// next day rather than firing immediately.
  DateTime resolve(DateTime now) => switch (this) {
    ReminderPreset.in20Minutes => now.add(const Duration(minutes: 20)),
    ReminderPreset.in1Hour => now.add(const Duration(hours: 1)),
    ReminderPreset.thisEvening => _evening(now),
    ReminderPreset.tomorrowMorning => DateTime(
      now.year,
      now.month,
      now.day + 1,
      9,
    ),
  };

  static DateTime _evening(DateTime now) {
    final todayAtSix = DateTime(now.year, now.month, now.day, 18);
    return todayAtSix.isAfter(now)
        ? todayAtSix
        : DateTime(now.year, now.month, now.day + 1, 18);
  }
}

typedef ReminderDue = void Function(MessageReminder reminder);

/// Remembers on this computer which messages a person asked to be reminded
/// about, and notifies them when each one is due.
///
/// Kept per signed-in user, so another account on the same machine starts with
/// its own reminders. The backend has no reminder field yet, hence local
/// storage. A reminder due while the app was closed fires on the next launch.
class MessageRemindersStore extends ChangeNotifier {
  MessageRemindersStore(
    this._storage, {
    required String userId,
    ReminderDue? onDue,
    DateTime Function()? clock,
  }) : _storageKey = userId.isEmpty ? null : 'message_reminders_$userId',
       _onDue = onDue,
       _clock = clock ?? DateTime.now;

  final SecureStorageService? _storage;
  final String? _storageKey;
  final ReminderDue? _onDue;
  final DateTime Function() _clock;

  final List<MessageReminder> _items = [];
  Timer? _dueTimer;
  bool _loaded = false;
  bool _disposed = false;

  /// Pending reminders, soonest first.
  List<MessageReminder> get items => List.unmodifiable(_items);

  bool get isLoaded => _loaded;

  MessageReminder? forMessage(String channelId, String messageId) {
    for (final item in _items) {
      if (item.channelId == channelId && item.messageId == messageId) {
        return item;
      }
    }
    return null;
  }

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final storage = _storage;
    final key = _storageKey;
    if (storage != null && key != null) {
      try {
        final raw = await storage.readData(key);
        final decoded = raw == null || raw.isEmpty ? null : jsonDecode(raw);
        if (decoded is List) {
          for (final entry in decoded.whereType<Map<String, dynamic>>()) {
            final item = MessageReminder.fromJson(entry);
            if (item.messageId.isNotEmpty && item.channelId.isNotEmpty) {
              _items.add(item);
            }
          }
        }
      } catch (_) {
        // A corrupt or unreadable list starts empty; the next set rewrites it.
      }
    }
    _sort();
    _notify();
    // Deliver anything that came due while the app was closed, then wait for
    // the next one.
    await checkDue();
    _armTimer();
  }

  Future<void> add(MessageReminder reminder) async {
    if (reminder.messageId.isEmpty || reminder.channelId.isEmpty) return;
    _items.removeWhere((item) => item.id == reminder.id);
    _items.add(reminder);
    _sort();
    _notify();
    _armTimer();
    await _persist();
  }

  Future<void> cancel(String id) async {
    final before = _items.length;
    _items.removeWhere((item) => item.id == id);
    if (_items.length == before) return;
    _notify();
    _armTimer();
    await _persist();
  }

  /// Fires every reminder whose time has come and forgets it. Public so the
  /// store can be driven directly in tests and by the timer.
  Future<void> checkDue() async {
    if (_items.isEmpty) return;
    final now = _clock();
    final due = _items
        .where((item) => !item.remindAt.isAfter(now))
        .toList(growable: false);
    if (due.isEmpty) return;
    _items.removeWhere((item) => due.any((fired) => fired.id == item.id));
    _notify();
    for (final reminder in due) {
      _onDue?.call(reminder);
    }
    await _persist();
  }

  void _armTimer() {
    _dueTimer?.cancel();
    _dueTimer = null;
    if (_disposed || _items.isEmpty) return;
    var delay = _items.first.remindAt.difference(_clock());
    if (delay.isNegative) delay = Duration.zero;
    _dueTimer = Timer(delay, () {
      unawaited(checkDue().whenComplete(_armTimer));
    });
  }

  void _sort() => _items.sort((a, b) => a.remindAt.compareTo(b.remindAt));

  Future<void> _persist() async {
    final storage = _storage;
    final key = _storageKey;
    if (storage == null || key == null) return;
    try {
      await storage.writeData(
        key,
        jsonEncode(_items.map((item) => item.toJson()).toList()),
      );
    } catch (_) {
      // Storage failure keeps the in-memory list usable for this session.
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _dueTimer?.cancel();
    super.dispose();
  }
}

final messageRemindersStoreProvider =
    ChangeNotifierProvider<MessageRemindersStore>((ref) {
      // Rebuilding on a user change also drops the previous in-memory list.
      final userId = dmPreferencesUserId(ref) ?? '';
      final store = MessageRemindersStore(
        locator.isRegistered<SecureStorageService>()
            ? locator<SecureStorageService>()
            : null,
        userId: userId,
        onDue: (reminder) => _showReminderNotification(ref, reminder),
      );
      unawaited(store.load());
      return store;
    });

Future<void> _showReminderNotification(
  Ref ref,
  MessageReminder reminder,
) async {
  final preview = notificationPreview(reminder.content);
  final notification = LocalNotification(
    title: 'Reminder · ${reminder.conversationName}',
    body: preview,
  );
  notification.onClick = () => ref
      .read(notificationServiceProvider)
      .handleNotificationClick(
        channelId: reminder.channelId,
        senderName: reminder.conversationName,
        senderId: reminder.participantId,
        contentPreview: preview,
      );
  try {
    await notification.show();
  } catch (_) {
    // A missing notification backend must not stop other reminders firing.
  }
}
