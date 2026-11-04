/// A top-level message in a channel, as returned by
/// `GET /threads/channels/{channel_id}`.
class ChannelMessage {
  final String id;
  final String? threadId;
  final String senderName;
  final String? avatarUrl;
  final String text;
  final DateTime? createdAt;

  const ChannelMessage({
    this.id = '',
    this.threadId,
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
      id: nonEmpty(json['id']) ?? nonEmpty(json['message_id']) ?? '',
      threadId: nonEmpty(json['thread_id']),
      senderName:
          nonEmpty(json['full_name']) ??
          nonEmpty(json['username']) ??
          'Unknown',
      avatarUrl:
          nonEmpty(json['avatar_url']) ?? nonEmpty(json['default_avatar_url']),
      // Messages sent from the web app arrive as HTML (`<p>hi</p>`).
      text: (json['message']?.toString() ?? '')
          .replaceAll(
            RegExp(r'</(p|div|li)>\s*<(p|div|li|ul|ol)\b[^>]*>|<br\s*/?>'),
            '\n',
          )
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .trim(),
      createdAt: DateTime.tryParse(
        json['created_at']?.toString() ?? '',
      )?.toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (threadId != null) 'thread_id': threadId,
      'sender_name': senderName,
      'text': text,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  ChannelMessage copyWith({
    String? id,
    String? threadId,
    String? senderName,
    String? avatarUrl,
    String? text,
    DateTime? createdAt,
  }) {
    return ChannelMessage(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      senderName: senderName ?? this.senderName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
