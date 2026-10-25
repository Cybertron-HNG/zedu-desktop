import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Adds up the unread counts of the given DMs and channels.
int totalUnreadCount({
  required List<DmConversation> dms,
  required List<Channel> channels,
}) {
  final dmTotal = dms.fold<int>(0, (sum, dm) => sum + dm.unreadCount);
  final channelTotal = channels.fold<int>(
    0,
    (sum, channel) => sum + channel.unreadCount,
  );
  return dmTotal + channelTotal;
}

/// Total unread messages in the selected organisation's DMs and channels.
///
/// It is zero while signed out, so nothing is loaded before login.
final unreadTotalProvider = Provider<int>((ref) {
  final isSignedIn = ref.watch(
    authNotifierProvider.select(
      (state) => state.status == AuthStatus.authenticated,
    ),
  );
  if (!isSignedIn) return 0;

  final dms =
      settledListValue(ref.watch(dmListProvider)) ?? const <DmConversation>[];
  final channels =
      settledListValue(ref.watch(channelProvider)) ?? const <Channel>[];
  return totalUnreadCount(dms: dms, channels: channels);
});

/// The loaded value, or null while it reloads or has failed. Riverpod keeps
/// the previous `.value` during a reload, which after a workspace switch is
/// the old workspace's list and would put a stale number on the Dock badge.
/// Each list is checked on its own, so a good one is still counted.
@visibleForTesting
List<T>? settledListValue<T>(AsyncValue<List<T>> async) {
  if (async.isLoading || async.hasError) return null;
  return async.value;
}
