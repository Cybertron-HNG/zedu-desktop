/// A top-level message in a channel, as returned by
/// `GET /threads/channels/{channel_id}`.
class ChannelMessage {
  final String? id;
  final String? threadId;
  final String senderName;
  final String? avatarUrl;
  final String text;
  final DateTime? createdAt;
  final String? status;

  const ChannelMessage({
    this.id,
    this.threadId,
    required this.senderName,
    required this.text,
    this.avatarUrl,
    this.createdAt,
    this.status,
  });

  factory ChannelMessage.fromJson(Map<String, dynamic> json) {
    String? nonEmpty(Object? value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    return ChannelMessage(
      id: nonEmpty(json['id']) ?? nonEmpty(json['message_id']),
      threadId: nonEmpty(json['thread_id']) ?? nonEmpty(json['threadId']),
      senderName:
          nonEmpty(json['full_name']) ??
          nonEmpty(json['sender_name']) ??
          nonEmpty(json['username']) ??
          'Unknown',
      avatarUrl:
          nonEmpty(json['avatar_url']) ?? nonEmpty(json['default_avatar_url']),
      // Messages sent from the web app arrive as HTML (`<p>hi</p>`).
      text: _decodeHtmlEntities(
        (json['message']?.toString() ?? '')
            .replaceAll(
              RegExp(r'</(p|div|li)>\s*<(p|div|li|ul|ol)\b[^>]*>|<br\s*/?>'),
              '\n',
            )
            .replaceAll(RegExp(r'<[^>]*>'), ''),
      ).trim(),
      createdAt: DateTime.tryParse(
        json['created_at']?.toString() ?? '',
      )?.toLocal(),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (threadId != null) 'thread_id': threadId,
      'sender_name': senderName,
      'text': text,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (status != null) 'status': status,
    };
  }

  ChannelMessage copyWith({
    String? id,
    String? threadId,
    String? senderName,
    String? avatarUrl,
    String? text,
    DateTime? createdAt,
    String? status,
  }) {
    return ChannelMessage(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      senderName: senderName ?? this.senderName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  /// Decodes in a single pass, so `&amp;lt;` stays the literal text `&lt;`.
  static String _decodeHtmlEntities(String text) {
    const named = {
      'nbsp': ' ',
      'amp': '&',
      'lt': '<',
      'gt': '>',
      'quot': '"',
      'apos': "'",
    };

    return text.replaceAllMapped(
      RegExp(r'&(?:#(\d+)|#[xX]([0-9a-fA-F]+)|(nbsp|amp|lt|gt|quot|apos));'),
      (match) {
        final name = match[3];
        if (name != null) return named[name]!;

        final code = match[1] != null
            ? int.tryParse(match[1]!)
            : int.tryParse(match[2]!, radix: 16);
        final isCharacter =
            code != null &&
            code > 0 &&
            code <= 0x10FFFF &&
            (code < 0xD800 || code > 0xDFFF);
        return isCharacter ? String.fromCharCode(code) : match[0]!;
      },
    );
  }
}
