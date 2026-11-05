import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

Map<String, dynamic> _json(Map<String, dynamic> extra) => {
  'channel_id': 'c1',
  'username': 'ada',
  'participant_id': 'u1',
  'preview_message': '',
  ...extra,
};

void main() {
  group('DmConversation unread count', () {
    test('uses unread_count when the server sends it', () {
      final dm = DmConversation.fromJson(
        _json({'unread_count': 2, 'thread_count': 40}),
      );

      expect(dm.unreadCount, 2);
      expect(dm.threadCount, 40);
    });

    test('shows no unread messages when unread_count is missing', () {
      final dm = DmConversation.fromJson(_json({'thread_count': 40}));

      expect(dm.unreadCount, 0);
      expect(dm.threadCount, 40);
    });
  });
}
