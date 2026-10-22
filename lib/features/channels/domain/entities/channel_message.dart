/// A top-level message in a channel, as returned by
/// `GET /threads/channels/{channel_id}`.
class ChannelMessage {
  final String senderName;
  final String? avatarUrl;
  final String text;
  final DateTime? createdAt;

  const ChannelMessage({
    required this.senderName,
    required this.text,
    this.avatarUrl,
    this.createdAt,
  });

  factory ChannelMessage.fromJson(Map<String, dynamic> json) {
    String? nonEmpty(Object? value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    return ChannelMessage(
      senderName:
          nonEmpty(json['full_name']) ??
          nonEmpty(json['username']) ??
          'Unknown',
      avatarUrl:
          nonEmpty(json['avatar_url']) ?? nonEmpty(json['default_avatar_url']),
      // Messages sent from the web app arrive as HTML (`<p>hi</p>`).
      text: (json['message']?.toString() ?? '')
          .replaceAll(RegExp(r'</p>\s*<p>|<br\s*/?>'), '\n')
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .trim(),
      createdAt: DateTime.tryParse(
        json['created_at']?.toString() ?? '',
      )?.toLocal(),
    );
  }
}
