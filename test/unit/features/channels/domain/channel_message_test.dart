import '../../../../helpers/helpers.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('ChannelMessage', () {
    test('ChannelMessage.fromJson maps a thread with id and thread_id', () {
      final message = ChannelMessage.fromJson({
        'id': 'msg-123',
        'thread_id': 't-1',
        'full_name': 'Ada Lovelace',
        'avatar_url': 'https://cdn.zedu.chat/a.png',
        'message': 'hello',
        'created_at': '2026-10-21T05:14:46Z',
      });

      expect(message.id, 'msg-123');
      expect(message.threadId, 't-1');
      expect(message.senderName, 'Ada Lovelace');
      expect(message.avatarUrl, 'https://cdn.zedu.chat/a.png');
      expect(
        message.createdAt,
        DateTime.utc(2026, 10, 21, 5, 14, 46).toLocal(),
      );
    });

    test(
      'ChannelMessage.fromJson falls back to message_id when id is absent',
      () {
        final message = ChannelMessage.fromJson({
          'message_id': 'fallback-id-99',
          'thread_id': 't-2',
          'username': 'ada',
          'message': 'fallback message id test',
        });

        expect(message.id, 'fallback-id-99');
        expect(message.threadId, 't-2');
        expect(message.senderName, 'ada');
      },
    );

    test('ChannelMessage.fromJson falls back and strips HTML', () {
      final message = ChannelMessage.fromJson({
        'full_name': ' ',
        'username': 'gold_salam',
        'default_avatar_url': 'https://cdn.zedu.chat/default.png',
        'message':
            '<p>Hi &amp; welcome</p><div>Line&nbsp;two</div><ul><li>a</li><li>b</li></ul>',
      });

      expect(message.id, '');
      expect(message.threadId, isNull);
      expect(message.senderName, 'gold_salam');
      expect(message.avatarUrl, 'https://cdn.zedu.chat/default.png');
      expect(message.text, 'Hi & welcome\nLine two\na\nb');
    });

    test('ChannelMessage.toJson and copyWith work as expected', () {
      final now = DateTime.utc(2026, 11, 4, 10, 0, 0);
      const original = ChannelMessage(
        id: 'msg-1',
        threadId: 't-1',
        senderName: 'Alice',
        text: 'original text',
      );

      final modified = original.copyWith(
        id: 'msg-2',
        text: 'updated text',
        createdAt: now,
      );

      expect(modified.id, 'msg-2');
      expect(modified.threadId, 't-1');
      expect(modified.senderName, 'Alice');
      expect(modified.text, 'updated text');
      expect(modified.createdAt, now);

      final json = modified.toJson();
      expect(json['id'], 'msg-2');
      expect(json['thread_id'], 't-1');
      expect(json['sender_name'], 'Alice');
      expect(json['text'], 'updated text');
      expect(json['created_at'], now.toIso8601String());
    });
  });
}
