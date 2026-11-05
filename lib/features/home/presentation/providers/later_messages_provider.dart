import 'dart:convert';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

enum LaterFilter {
  inProgress('In progress'),
  all('All saved'),
  channels('Channels'),
  dms('Direct messages'),
  completed('Completed');

  const LaterFilter(this.label);

  final String label;
}

class SavedLaterItem {
  const SavedLaterItem({
    required this.id,
    required this.messageId,
    required this.channelId,
    required this.conversationName,
    required this.isChannel,
    this.isPrivateChannel = false,
    this.participantId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.content,
    required this.createdAt,
    required this.savedAt,
    this.isCompleted = false,
  });

  final String id;
  final String messageId;
  final String channelId;
  final String conversationName;
  final bool isChannel;
  final bool isPrivateChannel;
  final String? participantId;
  final String senderName;
  final String? senderAvatarUrl;
  final String content;
  final DateTime createdAt;
  final DateTime savedAt;
  final bool isCompleted;

  static String composeId({
    required String channelId,
    required String messageKey,
  }) => '$channelId::$messageKey';

  SavedLaterItem copyWith({
    String? id,
    String? messageId,
    String? channelId,
    String? conversationName,
    bool? isChannel,
    bool? isPrivateChannel,
    String? participantId,
    String? senderName,
    String? senderAvatarUrl,
    String? content,
    DateTime? createdAt,
    DateTime? savedAt,
    bool? isCompleted,
  }) {
    return SavedLaterItem(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      channelId: channelId ?? this.channelId,
      conversationName: conversationName ?? this.conversationName,
      isChannel: isChannel ?? this.isChannel,
      isPrivateChannel: isPrivateChannel ?? this.isPrivateChannel,
      participantId: participantId ?? this.participantId,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      savedAt: savedAt ?? this.savedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'message_id': messageId,
    'channel_id': channelId,
    'conversation_name': conversationName,
    'is_channel': isChannel,
    'is_private_channel': isPrivateChannel,
    'participant_id': participantId,
    'sender_name': senderName,
    'sender_avatar_url': senderAvatarUrl,
    'content': content,
    'created_at': createdAt.toUtc().toIso8601String(),
    'saved_at': savedAt.toUtc().toIso8601String(),
    'is_completed': isCompleted,
  };

  factory SavedLaterItem.fromJson(Map<String, dynamic> json) {
    final channelId = (json['channel_id'] ?? '').toString();
    final messageId = (json['message_id'] ?? '').toString();
    final rawId = (json['id'] ?? '').toString();
    return SavedLaterItem(
      id: rawId.isNotEmpty
          ? rawId
          : composeId(channelId: channelId, messageKey: messageId),
      messageId: messageId,
      channelId: channelId,
      conversationName: (json['conversation_name'] ?? '').toString(),
      isChannel: json['is_channel'] == true,
      isPrivateChannel: json['is_private_channel'] == true,
      participantId: json['participant_id'] as String?,
      senderName: (json['sender_name'] ?? 'Unknown').toString(),
      senderAvatarUrl: json['sender_avatar_url'] as String?,
      content: (json['content'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString())?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      savedAt:
          DateTime.tryParse((json['saved_at'] ?? '').toString())?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isCompleted: json['is_completed'] == true,
    );
  }
}

class LaterMessagesStore {
  const LaterMessagesStore([this._storage]);

  final SecureStorageService? _storage;

  static const _tag = 'LaterMessagesStore';

  static String storageKey(String scope) => 'zedu_later_messages_$scope';

  SecureStorageService? get _effectiveStorage {
    if (_storage != null) return _storage;
    if (locator.isRegistered<SecureStorageService>()) {
      return locator<SecureStorageService>();
    }
    return null;
  }

  Future<List<SavedLaterItem>> read(String scope) async {
    final storage = _effectiveStorage;
    if (storage == null) return const [];
    try {
      final raw = await storage.readData(storageKey(scope));
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (item) => SavedLaterItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (error) {
      AppLogger.w('Could not read saved later items - $error', tag: _tag);
      return const [];
    }
  }

  Future<void> write(String scope, List<SavedLaterItem> items) async {
    final storage = _effectiveStorage;
    if (storage == null) return;
    try {
      final payload = jsonEncode(items.map((item) => item.toJson()).toList());
      await storage.writeData(storageKey(scope), payload);
    } catch (error) {
      AppLogger.w('Could not write saved later items - $error', tag: _tag);
    }
  }
}

final laterMessagesStoreProvider = Provider<LaterMessagesStore>(
  (ref) => const LaterMessagesStore(),
);

class LaterMessagesState {
  const LaterMessagesState({
    this.items = const [],
    this.filter = LaterFilter.inProgress,
    this.selectedItemId,
    this.searchQuery = '',
  });

  final List<SavedLaterItem> items;
  final LaterFilter filter;
  final String? selectedItemId;
  final String searchQuery;

  bool isSaved(String id) => items.any((item) => item.id == id);

  int countFor(LaterFilter target) {
    return switch (target) {
      LaterFilter.inProgress => items.where((item) => !item.isCompleted).length,
      LaterFilter.all => items.length,
      LaterFilter.channels => items.where((item) => item.isChannel).length,
      LaterFilter.dms => items.where((item) => !item.isChannel).length,
      LaterFilter.completed => items.where((item) => item.isCompleted).length,
    };
  }

  List<SavedLaterItem> get filteredItems {
    final query = searchQuery.trim().toLowerCase();
    final matchesFilter = items.where((item) {
      final passesTab = switch (filter) {
        LaterFilter.inProgress => !item.isCompleted,
        LaterFilter.all => true,
        LaterFilter.channels => item.isChannel,
        LaterFilter.dms => !item.isChannel,
        LaterFilter.completed => item.isCompleted,
      };
      if (!passesTab) return false;
      if (query.isEmpty) return true;
      return item.content.toLowerCase().contains(query) ||
          item.senderName.toLowerCase().contains(query) ||
          item.conversationName.toLowerCase().contains(query);
    }).toList();
    matchesFilter.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return matchesFilter;
  }

  SavedLaterItem? get selectedItem {
    final visible = filteredItems;
    if (visible.isEmpty) return null;
    if (selectedItemId != null) {
      for (final item in visible) {
        if (item.id == selectedItemId) return item;
      }
    }
    return visible.first;
  }

  LaterMessagesState copyWith({
    List<SavedLaterItem>? items,
    LaterFilter? filter,
    String? selectedItemId,
    bool clearSelectedItem = false,
    String? searchQuery,
  }) {
    return LaterMessagesState(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      selectedItemId: clearSelectedItem
          ? null
          : (selectedItemId ?? this.selectedItemId),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

String _resolveLaterScope(Ref ref) {
  if (!locator.isRegistered<AppConfig>()) {
    return 'default';
  }
  var orgId = 'default';
  try {
    final selectedOrg = ref.watch(
      workspaceProvider.select((s) => s.selectedWorkspace?.id),
    );
    if (selectedOrg != null && selectedOrg.isNotEmpty) {
      orgId = selectedOrg;
    }
  } catch (_) {
    // WorkspaceNotifier may not be mounted in isolated widget tests.
  }
  return orgId;
}

class LaterMessagesNotifier extends Notifier<LaterMessagesState> {
  late String _scope;

  @override
  LaterMessagesState build() {
    _scope = _resolveLaterScope(ref);
    final store = ref.watch(laterMessagesStoreProvider);
    _hydrate(store, _scope);
    return const LaterMessagesState();
  }

  Future<void> _hydrate(LaterMessagesStore store, String scope) async {
    final stored = await store.read(scope);
    if (_scope != scope || stored.isEmpty) return;
    // Merge with any items toggled before async hydration completed.
    final existingById = {for (final item in state.items) item.id: item};
    for (final item in stored) {
      existingById.putIfAbsent(item.id, () => item);
    }
    state = state.copyWith(items: existingById.values.toList());
  }

  Future<void> _persist(List<SavedLaterItem> nextItems) async {
    await ref.read(laterMessagesStoreProvider).write(_scope, nextItems);
  }

  /// Saves [item] if not already saved, or removes it if already saved.
  /// Returns `true` when the item is now saved, or `false` when removed.
  Future<bool> toggleSaved(SavedLaterItem item) async {
    final exists = state.isSaved(item.id);
    final nextItems = exists
        ? state.items.where((entry) => entry.id != item.id).toList()
        : [item, ...state.items];
    state = state.copyWith(
      items: nextItems,
      selectedItemId: exists && state.selectedItemId == item.id
          ? null
          : (state.selectedItemId ?? item.id),
      clearSelectedItem: exists && state.selectedItemId == item.id,
    );
    await _persist(nextItems);
    return !exists;
  }

  Future<void> removeSaved(String id) async {
    final nextItems = state.items.where((item) => item.id != id).toList();
    state = state.copyWith(
      items: nextItems,
      clearSelectedItem: state.selectedItemId == id,
    );
    await _persist(nextItems);
  }

  Future<void> toggleCompleted(String id) async {
    final nextItems = [
      for (final item in state.items)
        if (item.id == id)
          item.copyWith(isCompleted: !item.isCompleted)
        else
          item,
    ];
    state = state.copyWith(items: nextItems);
    await _persist(nextItems);
  }

  Future<void> clearCompleted() async {
    final nextItems = state.items.where((item) => !item.isCompleted).toList();
    state = state.copyWith(items: nextItems, clearSelectedItem: true);
    await _persist(nextItems);
  }

  void setFilter(LaterFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void selectItem(String? id) {
    state = state.copyWith(selectedItemId: id, clearSelectedItem: id == null);
  }
}

final laterMessagesProvider =
    NotifierProvider<LaterMessagesNotifier, LaterMessagesState>(
      LaterMessagesNotifier.new,
    );
