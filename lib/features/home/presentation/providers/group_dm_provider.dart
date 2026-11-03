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

  @override
  List<GroupDM> build() {
    _listenToWebsockets();
    _listenToNetwork();
    // Groups live on the server, so they come back after a restart and the
    // list starts over when the workspace or the signed-in user changes.
    final orgId = ref.watch(currentOrgIdProvider);
    final userId = ref.watch(groupDmUserIdProvider);
    if (orgId.isNotEmpty) unawaited(_load(orgId, userId));
    return [];
  }

  Future<void> _load(String orgId, String? userId) async {
    try {
      final groups = await ref
          .read(groupDmRepositoryProvider)
          .list(orgId: orgId, currentUserId: userId);
      if (!ref.mounted) return;
      // Keep groups created while the list was loading.
      final loadedIds = groups.map((g) => g.id).toSet();
      state = [...groups, ...state.where((g) => !loadedIds.contains(g.id))];
      _connectWebsocket();
    } catch (_) {
      // Without the list the sidebar stays empty; creating a group still works.
    }
  }

  void _connectWebsocket() {
    ref.read(chatWebsocketProvider).connect(state.map((g) => g.id).toList());
  }

  void _listenToWebsockets() {
    _wsSubscription?.cancel();
    final ws = ref.read(chatWebsocketProvider);
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
    if (!ref.mounted) return Success(created);

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
      // Queue it
      _offlineQueue.putIfAbsent(groupDmId, () => []).add(messageText);
      // We can also optimistic UI append it with a pending flag, but for now just append
      state = [
        for (final group in state)
          if (group.id == groupDmId)
            group.copyWith(
              messages: [...group.messages, '$messageText (Pending...)'],
            )
          else
            group,
      ];
      return;
    }

    try {
      await ref
          .read(groupDmRepositoryProvider)
          .sendMessage(groupDmId, messageText);
    } catch (_) {
      if (!ref.mounted) return;
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
    if (!ref.mounted) return;

    state = [
      for (final group in state)
        if (group.id == groupDmId)
          group.copyWith(messages: [...group.messages, messageText])
        else
          group,
    ];

    await ref.read(chatStorageProvider).appendMessage(groupDmId, messageText);
  }

  Future<void> _flushOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;

    // Simulate sending queued messages
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Just clear the queue for the mock and assume they were sent
    // We already appended "Pending..." so let's clean them up
    // In a real app we'd replace the pending messages with real ones
    _offlineQueue.clear();
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
