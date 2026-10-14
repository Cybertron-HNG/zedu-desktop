import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final channelRepositoryProvider = Provider<ChannelRepository>((ref) {
  final apiBaseService = locator<ApiBaseService>();
  final remoteDataSource = ChannelRemoteDataSourceImpl(
    apiBaseService: apiBaseService,
  );
  return ChannelRepositoryImpl(remoteDataSource: remoteDataSource);
});

class ChannelNotifier extends AsyncNotifier<List<Channel>> {
  @override
  Future<List<Channel>> build() async {
    // Watching the workspace id rebuilds this provider when the workspace
    // changes, and Riverpod drops the result of the older request.
    final orgId = ref.watch(
      workspaceProvider.select((s) => s.selectedWorkspace?.id),
    );
    if (orgId == null) return const [];

    final result = await ref
        .read(channelRepositoryProvider)
        .fetchChannels(orgId);

    return switch (result) {
      Success<List<Channel>>(:final value) => value,
      Failure<List<Channel>>(:final error) => throw error,
    };
  }

  Future<bool> createChannel({
    required String name,
    required String description,
    required bool isPrivate,
    String? topic,
  }) async {
    // A second tap before the screen rebuilds must not start a second create.
    if (state.isLoading) return false;

    final String? orgId = ref.read(workspaceProvider).selectedWorkspace?.id;
    final authState = ref.read(authNotifierProvider);
    final String? username =
        authState.user?.username ?? authState.user?.email.split('@').first;

    if (orgId == null || username == null) return false;

    // Loading and error states keep the channels that are already listed
    final channels = state.value ?? const <Channel>[];
    state = const AsyncLoading<List<Channel>>();

    final result = await ref
        .read(channelRepositoryProvider)
        .createChannel(
          name: name,
          description: description,
          orgId: orgId,
          username: username,
          isPrivate: isPrivate,
          topic: topic,
        );

    // The workspace changed while creating, and build() has already reloaded
    // the list for the new one, so leave the state alone.
    if (ref.read(workspaceProvider).selectedWorkspace?.id != orgId) {
      return result is Success<Channel>;
    }

    switch (result) {
      case Success<Channel>(:final value):
        state = AsyncData([...channels.where((c) => c.id != value.id), value]);
        return true;
      case Failure<Channel>(:final error):
        state = AsyncError<List<Channel>>(error, StackTrace.current);
        return false;
    }
  }

  Future<bool> updateChannelTopicOrDescription({
    required String channelId,
    String? topic,
    String? description,
  }) async {
    final repository = ref.read(channelRepositoryProvider);
    final result = await repository.updateChannelTopicOrDescription(
      channelId: channelId,
      topic: topic,
      description: description,
    );

    if (result is Success<void>) {
      // Update local state
      final updatedChannels = (state.value ?? const <Channel>[]).map((c) {
        if (c.id == channelId) {
          return Channel(
            id: c.id,
            name: c.name,
            description: description ?? c.description,
            organisationId: c.organisationId,
            isPrivate: c.isPrivate,
            ownerId: c.ownerId,
            archived: c.archived,
            topic: topic ?? c.topic,
            unreadCount: c.unreadCount,
            membersCount: c.membersCount,
          );
        }
        return c;
      }).toList();
      state = AsyncData(updatedChannels);
      return true;
    }
    return false;
  }
}

final channelProvider = AsyncNotifierProvider<ChannelNotifier, List<Channel>>(
  ChannelNotifier.new,
  // A failed load is shown once instead of being retried in the background.
  retry: (_, _) => null,
);
