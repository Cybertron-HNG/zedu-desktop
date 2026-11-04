import '../../../../../helpers/helpers.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('ChannelMessage (entities)', () {
    test(
      'ChannelMessage.fromJson parses id, thread_id, and message fields',
      () {
        final message = ChannelMessage.fromJson({
          'id': 'msg-100',
          'thread_id': 'th-50',
          'full_name': 'Test User',
          'message': 'Testing message entities',
          'created_at': '2026-11-04T05:00:00Z',
        });

        expect(message.id, 'msg-100');
        expect(message.threadId, 'th-50');
        expect(message.senderName, 'Test User');
        expect(message.text, 'Testing message entities');
      },
    );

    test('ChannelMessage.fromJson deserializes message_id fallback', () {
      final message = ChannelMessage.fromJson({
        'message_id': 'alt-msg-200',
        'thread_id': 'th-60',
        'username': 'bob',
        'message': 'Testing alt message_id',
      });

      expect(message.id, 'alt-msg-200');
      expect(message.threadId, 'th-60');
      expect(message.senderName, 'bob');
    });

    test('ChannelMessage.toJson and copyWith serialize properly', () {
      const message = ChannelMessage(
        id: 'msg-300',
        threadId: 'th-70',
        senderName: 'Charlie',
        text: 'hello world',
      );

      final copy = message.copyWith(text: 'updated hello');
      expect(copy.id, 'msg-300');
      expect(copy.threadId, 'th-70');
      expect(copy.text, 'updated hello');

      final json = copy.toJson();
      expect(json['id'], 'msg-300');
      expect(json['thread_id'], 'th-70');
      expect(json['sender_name'], 'Charlie');
      expect(json['text'], 'updated hello');
    });
  });
}
