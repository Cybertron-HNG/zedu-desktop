import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// The latest messages of a channel, newest first.
final channelHistoryProvider = FutureProvider.autoDispose
    .family<List<ChannelMessage>, String>((ref, channelId) async {
      final result = await ref
          .watch(channelRepositoryProvider)
          .fetchChannelMessages(channelId);
      return switch (result) {
        Success<List<ChannelMessage>>(:final value) => value,
        Failure<List<ChannelMessage>>(:final error) => throw error,
      };
    });
