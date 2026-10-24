import '../../../../helpers/helpers.dart';
import 'package:zedu/features/features.dart';

void main() {
  test('ChannelMessage.fromJson maps a thread', () {
    final message = ChannelMessage.fromJson({
      'thread_id': 't-1',
      'full_name': 'Ada Lovelace',
      'avatar_url': 'https://cdn.zedu.chat/a.png',
      'message': 'hello',
      'created_at': '2026-10-21T05:14:46Z',
    });

    expect(message.senderName, 'Ada Lovelace');
    expect(message.avatarUrl, 'https://cdn.zedu.chat/a.png');
    expect(message.createdAt, DateTime.utc(2026, 10, 21, 5, 14, 46).toLocal());
  });

  test('ChannelMessage.fromJson falls back and strips HTML', () {
    final message = ChannelMessage.fromJson({
      'full_name': ' ',
      'username': 'gold_salam',
      'default_avatar_url': 'https://cdn.zedu.chat/default.png',
      'message': '<p>Hi &amp; welcome</p><p>Line&nbsp;two</p>',
    });

    expect(message.senderName, 'gold_salam');
    expect(message.avatarUrl, 'https://cdn.zedu.chat/default.png');
    expect(message.text, 'Hi & welcome\nLine two');
  });
}
