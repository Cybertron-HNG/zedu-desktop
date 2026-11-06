import 'dart:async';
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
    this.serverSavedId,
    required this.messageId,
    this.threadId,
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
    this.isDeleted = false,
  });

  final String id;
  final String? serverSavedId;
  final String messageId;
  final String? threadId;
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
  final bool isDeleted;

  static String composeId({
    required String channelId,
    required String messageKey,
  }) => '$channelId::$messageKey';

  SavedLaterItem copyWith({
    String? id,
    String? serverSavedId,
    String? messageId,
    String? threadId,
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
    bool? isDeleted,
  }) {
    return SavedLaterItem(
      id: id ?? this.id,
      serverSavedId: serverSavedId ?? this.serverSavedId,
      messageId: messageId ?? this.messageId,
      threadId: threadId ?? this.threadId,
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
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (serverSavedId != null) 'server_saved_id': serverSavedId,
    'message_id': messageId,
    if (threadId != null) 'thread_id': threadId,
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
    'is_deleted': isDeleted,
  };

  factory SavedLaterItem.fromJson(Map<String, dynamic> json) {
    final channelId = (json['channel_id'] ?? '').toString();
    final messageId = (json['message_id'] ?? '').toString();
    final rawId = (json['id'] ?? '').toString();
    return SavedLaterItem(
      id: rawId.isNotEmpty
          ? rawId
          : composeId(channelId: channelId, messageKey: messageId),
      serverSavedId: json['server_saved_id'] as String?,
      messageId: messageId,
      threadId: json['thread_id'] as String?,
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
      isDeleted: json['is_deleted'] == true,
    );
  }

  factory SavedLaterItem.fromServerJson(Map<String, dynamic> json) {
    final serverId = (json['id'] ?? '').toString();
    final threadId = json['thread_id'] as String?;
    final messageId = (json['message_id'] ?? threadId ?? serverId).toString();
    final channelId = (json['channel_id'] ?? '').toString();
    final channelType = (json['channel_type'] ?? '').toString().toLowerCase();
    final isDm = channelType.contains('dm') || channelType.contains('direct');
    final isChannel = !isDm;
    final content = (json['content'] ?? '').toString();
    final isDeleted = content == 'A message you saved was not found.';

    return SavedLaterItem(
      id: composeId(channelId: channelId, messageKey: messageId),
      serverSavedId: serverId.isNotEmpty ? serverId : null,
      messageId: messageId,
      threadId: threadId,
      channelId: channelId,
      conversationName:
          (json['channel_name'] ?? (isChannel ? 'channel' : 'Direct Message'))
              .toString(),
      isChannel: isChannel,
      senderName: (json['username'] ?? 'Unknown').toString(),
      senderAvatarUrl: json['avatar_url'] as String?,
      content: isDeleted ? 'This message was deleted.' : content,
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      savedAt:
          DateTime.tryParse((json['saved_at'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      isCompleted: json['completed'] == true,
      isDeleted: isDeleted,
    );
  }
}

/// Client-side secure storage for saved later messages.
///
/// Keys are strictly scoped by [userId] and [orgId] (`zedu_later_{userId}_{orgId}`)
/// so private bookmarked messages never leak across user accounts on shared computers,
/// and can be completely wiped at sign-out via [deleteAllForUser].
class LaterMessagesStore {
  const LaterMessagesStore([this._storage]);

  final SecureStorageService? _storage;

  static const _tag = 'LaterMessagesStore';

  static String userPrefix(String userId) => 'zedu_later_${userId}_';

  static String storageKey({required String userId, required String orgId}) =>
      '${userPrefix(userId)}$orgId';

  /// Removes all saved messages for [userId] across every workspace on this
  /// computer, ensuring private bookmarked DMs and channels do not outlive logout.
  static Future<void> deleteAllForUser(
    SecureStorageService storage,
    String userId,
  ) async {
    if (userId.isEmpty) return;
    final prefix = userPrefix(userId);
    final stored = await storage.readAll();
    for (final key in stored.keys.where((k) => k.startsWith(prefix))) {
      await storage.deleteValue(key);
    }
  }

  SecureStorageService? get _effectiveStorage {
    if (_storage != null) return _storage;
    if (locator.isRegistered<SecureStorageService>()) {
      return locator<SecureStorageService>();
    }
    return null;
  }

  Future<List<SavedLaterItem>> read({
    required String userId,
    required String orgId,
  }) async {
    if (userId.isEmpty) return const [];
    final storage = _effectiveStorage;
    if (storage == null) return const [];
    try {
      final raw = await storage.readData(
        storageKey(userId: userId, orgId: orgId),
      );
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

  Future<void> write({
    required String userId,
    required String orgId,
    required List<SavedLaterItem> items,
  }) async {
    if (userId.isEmpty) return;
    final storage = _effectiveStorage;
    if (storage == null) return;
    try {
      final payload = jsonEncode(items.map((item) => item.toJson()).toList());
      await storage.writeData(
        storageKey(userId: userId, orgId: orgId),
        payload,
      );
    } catch (error) {
      AppLogger.w('Could not write saved later items - $error', tag: _tag);
    }
  }
}

final laterMessagesStoreProvider = Provider<LaterMessagesStore>(
  (ref) => const LaterMessagesStore(),
);

/// Remote data source that talks to the Zedu backend saved-messages API,
/// allowing saved bookmarks to follow the user across web, desktop, and mobile.
abstract class LaterMessagesRemoteDataSource {
  Future<List<SavedLaterItem>> fetchSavedMessages(String orgId);

  Future<bool> saveThread({
    required String orgId,
    required String channelId,
    required String threadId,
  });

  Future<bool> saveMessage({
    required String orgId,
    required String channelId,
    required String threadId,
    required String messageId,
  });

  Future<void> deleteSavedMessage({
    required String orgId,
    required String savedMessageId,
  });

  Future<void> markComplete({
    required String orgId,
    required String savedMessageId,
    required bool completed,
  });
}

class LaterMessagesRemoteDataSourceImpl
    implements LaterMessagesRemoteDataSource {
  const LaterMessagesRemoteDataSourceImpl({this.apiBaseService});

  final ApiBaseService? apiBaseService;

  static const _tag = 'LaterMessagesRemote';

  ApiBaseService? get _effectiveApi {
    if (apiBaseService != null) return apiBaseService;
    if (locator.isRegistered<ApiBaseService>()) {
      return locator<ApiBaseService>();
    }
    return null;
  }

  @override
  Future<List<SavedLaterItem>> fetchSavedMessages(String orgId) async {
    final api = _effectiveApi;
    if (api == null || orgId.isEmpty || orgId == 'default') return const [];
    try {
      final response = await api.get<Map<String, dynamic>>(
        path: '/organisations/$orgId/saved/message',
      );
      final rawData = response.data['data'];
      final rawList = rawData is List
          ? rawData
          : (rawData is Map && rawData['messages'] is List
                ? rawData['messages'] as List
                : const <dynamic>[]);
      return rawList
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (m) => SavedLaterItem.fromServerJson(Map<String, dynamic>.from(m)),
          )
          .toList();
    } catch (error) {
      AppLogger.w(
        'Could not fetch saved messages from server - $error',
        tag: _tag,
      );
      return const [];
    }
  }

  @override
  Future<bool> saveThread({
    required String orgId,
    required String channelId,
    required String threadId,
  }) async {
    final api = _effectiveApi;
    if (api == null || orgId.isEmpty || orgId == 'default') return false;
    try {
      await api.post<dynamic>(
        path: '/organisations/$orgId/thread/save',
        data: {
          'channels_id': channelId,
          'thread_id': threadId,
          'type': 'message',
        },
      );
      return true;
    } catch (error) {
      AppLogger.w('Could not save thread on server - $error', tag: _tag);
      return false;
    }
  }

  @override
  Future<bool> saveMessage({
    required String orgId,
    required String channelId,
    required String threadId,
    required String messageId,
  }) async {
    final api = _effectiveApi;
    if (api == null || orgId.isEmpty || orgId == 'default') return false;
    try {
      await api.post<dynamic>(
        path: '/organisations/$orgId/message/save',
        data: {
          'channels_id': channelId,
          'thread_id': threadId,
          'message_id': messageId,
          'type': 'message',
        },
      );
      return true;
    } catch (error) {
      AppLogger.w('Could not save message reply on server - $error', tag: _tag);
      return false;
    }
  }

  @override
  Future<void> deleteSavedMessage({
    required String orgId,
    required String savedMessageId,
  }) async {
    final api = _effectiveApi;
    if (api == null || orgId.isEmpty || orgId == 'default') return;
    try {
      await api.delete<dynamic>(
        path: '/organisations/$orgId/saved/message/$savedMessageId',
      );
    } catch (error) {
      AppLogger.w(
        'Could not delete saved message from server - $error',
        tag: _tag,
      );
    }
  }

  @override
  Future<void> markComplete({
    required String orgId,
    required String savedMessageId,
    required bool completed,
  }) async {
    final api = _effectiveApi;
    if (api == null || orgId.isEmpty || orgId == 'default') return;
    try {
      await api.put<dynamic>(
        path: '/organisations/$orgId/mark-complete/$savedMessageId',
        data: {'completed': completed},
      );
    } catch (error) {
      AppLogger.w('Could not mark completed on server - $error', tag: _tag);
    }
  }
}

final laterMessagesRemoteDataSourceProvider =
    Provider<LaterMessagesRemoteDataSource>(
      (ref) => const LaterMessagesRemoteDataSourceImpl(),
    );

class LaterMessagesState {
  const LaterMessagesState({
    this.items = const [],
    this.filter = LaterFilter.inProgress,
    this.selectedItemId,
    this.searchQuery = '',
    this.isLoading = false,
  });

  final List<SavedLaterItem> items;
  final LaterFilter filter;
  final String? selectedItemId;
  final String searchQuery;
  final bool isLoading;

  bool isSaved(String id) => items.any(
    (item) =>
        item.id == id ||
        item.messageId == id ||
        (item.threadId != null && item.threadId == id),
  );

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
    bool? isLoading,
  }) {
    return LaterMessagesState(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      selectedItemId: clearSelectedItem
          ? null
          : (selectedItemId ?? this.selectedItemId),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

String _resolveLaterOrgId(Ref ref) {
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
  } catch (_) {}
  return orgId;
}

String _resolveLaterUserId(Ref ref) {
  try {
    final id = ref.watch(authNotifierProvider.select((s) => s.user?.id));
    if (id != null && id.isNotEmpty) return id;
  } catch (_) {}
  return 'default-user';
}

class LaterMessagesNotifier extends Notifier<LaterMessagesState> {
  late String _userId;
  late String _orgId;

  @override
  LaterMessagesState build() {
    _userId = _resolveLaterUserId(ref);
    _orgId = _resolveLaterOrgId(ref);

    final store = ref.watch(laterMessagesStoreProvider);
    final remote = ref.watch(laterMessagesRemoteDataSourceProvider);

    _hydrate(store, remote, userId: _userId, orgId: _orgId);
    return const LaterMessagesState();
  }

  Future<void> _hydrate(
    LaterMessagesStore store,
    LaterMessagesRemoteDataSource remote, {
    required String userId,
    required String orgId,
  }) async {
    // 1. Instant local load scoped to user + org
    final stored = await store.read(userId: userId, orgId: orgId);
    if (_userId != userId || _orgId != orgId) return;

    if (stored.isNotEmpty) {
      final existingById = {for (final item in state.items) item.id: item};
      for (final item in stored) {
        existingById.putIfAbsent(item.id, () => item);
      }
      state = state.copyWith(items: existingById.values.toList());
    }

    // 2. Background sync from server (cross-device support)
    if (orgId.isNotEmpty && orgId != 'default') {
      final remoteItems = await remote.fetchSavedMessages(orgId);
      if (_userId != userId || _orgId != orgId) return;

      if (remoteItems.isNotEmpty) {
        final merged = {for (final item in state.items) item.id: item};
        for (final item in remoteItems) {
          merged[item.id] = item;
        }
        final next = merged.values.toList();
        state = state.copyWith(items: next);
        await store.write(userId: userId, orgId: orgId, items: next);
      }
    }
  }

  Future<void> _persist(List<SavedLaterItem> nextItems) async {
    await ref
        .read(laterMessagesStoreProvider)
        .write(userId: _userId, orgId: _orgId, items: nextItems);
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

    final remote = ref.read(laterMessagesRemoteDataSourceProvider);
    if (exists) {
      if (item.serverSavedId != null) {
        unawaited(
          remote.deleteSavedMessage(
            orgId: _orgId,
            savedMessageId: item.serverSavedId!,
          ),
        );
      }
    } else {
      if (item.isChannel && item.threadId != null) {
        unawaited(
          remote.saveThread(
            orgId: _orgId,
            channelId: item.channelId,
            threadId: item.threadId!,
          ),
        );
      } else if (!item.isChannel && item.threadId != null) {
        unawaited(
          remote.saveThread(
            orgId: _orgId,
            channelId: item.channelId,
            threadId: item.threadId!,
          ),
        );
      }
    }

    return !exists;
  }

  Future<void> removeSaved(String id) async {
    final target = state.items.firstWhere(
      (item) => item.id == id,
      orElse: () => state.items.first,
    );
    final nextItems = state.items.where((item) => item.id != id).toList();
    state = state.copyWith(
      items: nextItems,
      clearSelectedItem: state.selectedItemId == id,
    );
    await _persist(nextItems);

    if (target.serverSavedId != null) {
      unawaited(
        ref
            .read(laterMessagesRemoteDataSourceProvider)
            .deleteSavedMessage(
              orgId: _orgId,
              savedMessageId: target.serverSavedId!,
            ),
      );
    }
  }

  Future<void> toggleCompleted(String id) async {
    SavedLaterItem? target;
    final nextItems = [
      for (final item in state.items)
        if (item.id == id)
          () {
            final updated = item.copyWith(isCompleted: !item.isCompleted);
            target = updated;
            return updated;
          }()
        else
          item,
    ];
    state = state.copyWith(items: nextItems);
    await _persist(nextItems);

    if (target != null && target!.serverSavedId != null) {
      unawaited(
        ref
            .read(laterMessagesRemoteDataSourceProvider)
            .markComplete(
              orgId: _orgId,
              savedMessageId: target!.serverSavedId!,
              completed: target!.isCompleted,
            ),
      );
    }
  }

  Future<void> clearCompleted() async {
    final toRemove = state.items.where((item) => item.isCompleted).toList();
    final nextItems = state.items.where((item) => !item.isCompleted).toList();
    state = state.copyWith(items: nextItems, clearSelectedItem: true);
    await _persist(nextItems);

    final remote = ref.read(laterMessagesRemoteDataSourceProvider);
    for (final item in toRemove) {
      if (item.serverSavedId != null) {
        unawaited(
          remote.deleteSavedMessage(
            orgId: _orgId,
            savedMessageId: item.serverSavedId!,
          ),
        );
      }
    }
  }

  /// Updates any saved items when the original message is edited in a channel or DM.
  void handleMessageEdited({
    required String channelId,
    required String messageId,
    String? threadId,
    required String newContent,
  }) {
    bool changed = false;
    final nextItems = [
      for (final item in state.items)
        if (item.channelId == channelId &&
            (item.messageId == messageId ||
                (threadId != null &&
                    (item.threadId == threadId || item.messageId == threadId))))
          () {
            changed = true;
            return item.copyWith(content: newContent);
          }()
        else
          item,
    ];
    if (changed) {
      state = state.copyWith(items: nextItems);
      _persist(nextItems);
    }
  }

  /// Updates any saved items when the original message is deleted in a channel or DM.
  void handleMessageDeleted({
    required String channelId,
    required String messageId,
    String? threadId,
  }) {
    bool changed = false;
    final nextItems = [
      for (final item in state.items)
        if (item.channelId == channelId &&
            (item.messageId == messageId ||
                (threadId != null &&
                    (item.threadId == threadId || item.messageId == threadId))))
          () {
            changed = true;
            return item.copyWith(
              isDeleted: true,
              content: 'This message was deleted.',
            );
          }()
        else
          item,
    ];
    if (changed) {
      state = state.copyWith(items: nextItems);
      _persist(nextItems);
    }
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
