import '../../../../../helpers/helpers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zedu/features/features.dart';

DmConversation _dm(String id, int unread) => DmConversation(
  channelId: id,
  username: 'User $id',
  participantId: 'p-$id',
  previewMessage: '',
  unreadCount: unread,
);

Channel _channel(String id, int unread) => Channel(
  id: id,
  name: 'channel-$id',
  description: '',
  organisationId: 'org-1',
  ownerId: 'owner-1',
  unreadCount: unread,
);

void main() {
  group('totalUnreadCount', () {
    test('is zero when there are no DMs or channels', () {
      expect(totalUnreadCount(dms: const [], channels: const []), 0);
    });

    test('adds DM and channel unread counts together', () {
      final total = totalUnreadCount(
        dms: [_dm('1', 3), _dm('2', 0), _dm('3', 4)],
        channels: [_channel('a', 5), _channel('b', 1)],
      );

      expect(total, 13);
    });

    test('is zero when everything is read', () {
      final total = totalUnreadCount(
        dms: [_dm('1', 0)],
        channels: [_channel('a', 0)],
      );

      expect(total, 0);
    });
  });

  group('settledListValue', () {
    test('returns the list once it has loaded', () {
      expect(
        settledListValue<DmConversation>(AsyncData([_dm('1', 3)]))?.length,
        1,
      );
    });

    test('ignores the old list while it reloads', () {
      // copyWithPrevious is how Riverpod itself keeps the old value on a reload.
      final reloading = const AsyncLoading<List<DmConversation>>()
          // ignore: invalid_use_of_internal_member
          .copyWithPrevious(AsyncData([_dm('1', 9)]));

      expect(settledListValue<DmConversation>(reloading), isNull);
    });

    test('ignores the old list after a failed reload', () {
      final failed = AsyncError<List<DmConversation>>(
        Exception('network'),
        StackTrace.empty,
        // ignore: invalid_use_of_internal_member
      ).copyWithPrevious(AsyncData([_dm('1', 9)]));

      expect(settledListValue<DmConversation>(failed), isNull);
    });
  });
}
