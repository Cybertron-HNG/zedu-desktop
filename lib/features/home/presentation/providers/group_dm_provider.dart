import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class GroupDM {
  final String id;
  final String name;
  final List<TeamMember> members;
  final int unreadCount;
  final List<String> messages;

  const GroupDM({
    required this.id,
    required this.name,
    required this.members,
    this.unreadCount = 0,
    this.messages = const [],
  });

  GroupDM copyWith({
    String? id,
    String? name,
    List<TeamMember>? members,
    int? unreadCount,
    List<String>? messages,
  }) {
    return GroupDM(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
      unreadCount: unreadCount ?? this.unreadCount,
      messages: messages ?? this.messages,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupDM &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          unreadCount == other.unreadCount;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ unreadCount.hashCode;
}

class GroupDmNotifier extends Notifier<List<GroupDM>> {
  final Map<String, List<String>> _offlineQueue = {};
  StreamSubscription<ChatWebsocketMessage>? _wsSubscription;

  /// Changes every time the provider is rebuilt (sign-out invalidates it, and
  /// the same notifier is reused for the next session). A delayed operation
  /// remembers the value it started with and gives up if it changed, so work
  /// begun in one session never lands in the next one's list.
  int _generation = 0;

  bool _isStale(int generation) => !ref.mounted || generation != _generation;

  @override
  List<GroupDM> build() {
    _generation++;
    _listenToWebsockets();
    _listenToNetwork();
    ref.onDispose(() => _wsSubscription?.cancel());
    // Groups live on the server, so they come back after a restart and the
    // list starts over when the workspace or the signed-in user changes.
    final orgId = ref.watch(currentOrgIdProvider);
    final userId = ref.watch(groupDmUserIdProvider);
    if (orgId.isNotEmpty) unawaited(_load(orgId, userId));
    return [];
  }

  Future<void> _load(String orgId, String? userId) async {
    final generation = _generation;
    final loadFailed = ref.read(groupDmLoadFailedProvider.notifier);
    // build() starts this; let it finish before anything here updates
    // another provider, even when the request fails at once.
    await Future<void>.value();
    try {
      final groups = await ref
          .read(groupDmRepositoryProvider)
          .list(orgId: orgId, currentUserId: userId);
      if (_isStale(generation)) return;
      // A group already on screen keeps its local copy (with the messages
      // shown so far), and groups created while the list was loading stay.
      final shown = {for (final g in state) g.id: g};
      final loadedIds = groups.map((g) => g.id).toSet();
      state = [
        for (final g in groups) shown[g.id] ?? g,
        ...state.where((g) => !loadedIds.contains(g.id)),
      ];
      loadFailed.set(false);
      _connectWebsocket();
    } catch (error, stackTrace) {
      if (_isStale(generation)) return;
      // Say so instead of silently showing no groups: whatever lists them can
      // show an error and call retryLoad.
      AppLogger.w(
        'Could not load group DMs',
        tag: 'GroupDmNotifier',
        error: error,
        stackTrace: stackTrace,
      );
      loadFailed.set(true);
    }
  }

  /// Loads the group list again, for example from a Retry button after a
  /// failed load.
  Future<void> retryLoad() async {
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId.isEmpty) return;
    await _load(orgId, ref.read(groupDmUserIdProvider));
  }

  void _connectWebsocket() {
    ref.read(chatWebsocketProvider).connect(state.map((g) => g.id).toList());
  }

  void _listenToWebsockets() {
    _wsSubscription?.cancel();
    final ws = ref.read(chatWebsocketProvider);
    // Store the subscription so it can be cancelled when the provider is disposed.
    // Without this, the WebSocket listener leaks after the provider is removed.
    _wsSubscription = ws.messageStream.listen((msg) {
      if (!ref.mounted) return;
      _handleIncomingMessage(msg.groupDmId, msg.text);
    });
    ref.onDispose(() {
      _wsSubscription?.cancel();
      _wsSubscription = null;
    });
  }

  void _listenToNetwork() {
    ref.listen<NetworkStatus>(networkStatusProvider, (previous, next) {
      if (next == NetworkStatus.online) {
        _flushOfflineQueue();
      }
    });
  }

  void _handleIncomingMessage(String groupId, String text) {
    if (!ref.mounted) return;
    state = [
      for (final group in state)
        if (group.id == groupId)
          group.copyWith(
            messages: [...group.messages, text],
            unreadCount: group.unreadCount + 1,
          )
        else
          group,
    ];
  }

  Future<Result<GroupDM>> createGroupDm(
    List<TeamMember> selectedMembers,
  ) async {
    final generation = _generation;

    final selectedIds = selectedMembers.map((m) => m.id).toSet();
    for (final group in state) {
      final groupIds = group.members.map((m) => m.id).toSet();
      if (groupIds.length == selectedIds.length &&
          groupIds.containsAll(selectedIds)) {
        return Success(group);
      }
    }

    final orgId = ref.read(currentOrgIdProvider);
    if (orgId.isEmpty) {
      return const Failure(
        ApiFailure(
          message: 'Select a workspace to start a group chat.',
          kind: ApiFailureKind.client,
        ),
      );
    }

    final GroupDM created;
    try {
      created = await ref
          .read(groupDmRepositoryProvider)
          .create(
            orgId: orgId,
            memberIds: selectedIds.toList(),
            currentUserId: ref.read(groupDmUserIdProvider),
          );
    } catch (error) {
      // Nothing is added, so a failed create leaves no group in the sidebar.
      return Failure(_failureFrom(error, 'Could not create the group chat.'));
    }
    // A sign-out or workspace switch while the request ran: don't add a group
    // to the new session's list.
    if (_isStale(generation)) {
      return Failure<GroupDM>(
        const ApiFailure(
          message: 'Your session changed before the group was created.',
        ),
      );
    }

    // The server returns the members it added; fall back to the ones picked
    // when it sends none back.
    final members = created.members.isNotEmpty
        ? created.members
        : selectedMembers;
    final newGroup = created.copyWith(
      name: groupDmName(members),
      members: members,
    );

    state = [...state.where((g) => g.id != newGroup.id), newGroup];
    _connectWebsocket();

    return Success(newGroup);
  }

  ApiFailure _failureFrom(Object error, String fallback) {
    if (error is ApiFailure) return error;
    if (error is DioException) {
      final inner = error.error;
      return inner is ApiFailure ? inner : ApiFailure.fromDioException(error);
    }
    return ApiFailure(message: fallback, kind: ApiFailureKind.client);
  }

  Future<void> sendMessage(String groupDmId, String messageText) async {
    final network = ref.read(networkStatusProvider);

    if (network == NetworkStatus.offline) {
      _offlineQueue.putIfAbsent(groupDmId, () => <String>[]).add(messageText);
      _appendMessage(groupDmId, _pendingLabel(messageText));
      return;
    }

    final generation = _generation;
    try {
      await ref
          .read(groupDmRepositoryProvider)
          .sendMessage(groupDmId, messageText);
    } catch (_) {
      if (_isStale(generation)) return;
      state = [
        for (final group in state)
          if (group.id == groupDmId)
            group.copyWith(
              messages: [...group.messages, '$messageText (Not sent)'],
            )
          else
            group,
      ];
      return;
    }
    if (_isStale(generation)) return;

    _appendMessage(groupDmId, messageText);
    await _persistMessage(groupDmId, messageText);
  }

  Future<void> _flushOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;

    final queued = <String, List<String>>{
      for (final entry in _offlineQueue.entries)
        entry.key: List<String>.of(entry.value),
    };
    _offlineQueue.clear();

    for (final entry in queued.entries) {
      for (final messageText in entry.value) {
        try {
          // Simulate API delay
          await Future<void>.delayed(const Duration(milliseconds: 300));
          await _persistMessage(entry.key, messageText);
          _replacePending(entry.key, messageText);
        } catch (error) {
          // Leave the message queued so the next reconnect retries it.
          _offlineQueue
              .putIfAbsent(entry.key, () => <String>[])
              .add(messageText);
          debugPrint('Could not flush a queued message: $error');
        }
      }
    }
  }

  Future<void> _persistMessage(String groupDmId, String messageText) async {
    await ref.read(chatStorageProvider).appendMessage(groupDmId, messageText);
  }

  void _appendMessage(String groupDmId, String messageText) {
    state = [
      for (final group in state)
        if (group.id == groupDmId)
          group.copyWith(messages: [...group.messages, messageText])
        else
          group,
    ];
  }

  void _replacePending(String groupDmId, String messageText) {
    final pending = _pendingLabel(messageText);
    state = [
      for (final group in state)
        if (group.id == groupDmId)
          group.copyWith(
            messages: _replaceFirst(group.messages, pending, messageText),
          )
        else
          group,
    ];
  }

  String _pendingLabel(String messageText) => '$messageText (Pending...)';

  List<String> _replaceFirst(List<String> messages, String from, String to) {
    final index = messages.indexOf(from);
    if (index == -1) return messages;
    return [
      for (var i = 0; i < messages.length; i++)
        if (i == index) to else messages[i],
    ];
  }

  void renameGroupDm(String groupId, String newName) {
    state = [
      for (final group in state)
        if (group.id == groupId) group.copyWith(name: newName) else group,
    ];
  }
}

final groupDmProvider = NotifierProvider<GroupDmNotifier, List<GroupDM>>(
  GroupDmNotifier.new,
);

/// Whether the last attempt to load the group DM list failed.
class GroupDmLoadFailedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool failed) => state = failed;
}

final groupDmLoadFailedProvider =
    NotifierProvider<GroupDmLoadFailedNotifier, bool>(
      GroupDmLoadFailedNotifier.new,
    );
