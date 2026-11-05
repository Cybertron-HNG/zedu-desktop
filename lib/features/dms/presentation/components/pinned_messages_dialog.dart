import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// "Pinned messages" for a DM: displays pinned messages in the conversation.
/// Shows an empty state when no messages are pinned.
class PinnedMessagesDialog extends StatelessWidget {
  const PinnedMessagesDialog({
    super.key,
    required this.conversationName,
    required this.messages,
  });

  final String conversationName;
  final List<dynamic> messages;

  static bool isPinned(dynamic message) {
    if (message is! Map) return false;
    return message['is_pinned'] == true ||
        message['pinned'] == true ||
        message['isPinned'] == true;
  }

  static String plainText(dynamic content) {
    if (content == null) return '';
    final raw = content.toString();
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pinned = messages.where(isPinned).toList();

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pinned messages'),
          if (conversationName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                conversationName,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textHint,
                ),
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: pinned.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.push_pin_outlined,
                        color: colors.textHint,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No pinned messages',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Messages pinned in $conversationName will show up here.',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.textHint,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: pinned.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = pinned[index];
                    final content = plainText(item['content']);
                    final sender =
                        item['sender_name']?.toString() ??
                        item['username']?.toString() ??
                        'Message';
                    final time = DateTime.tryParse(
                      item['created_at']?.toString() ?? '',
                    )?.toLocal();
                    final timeStr = time != null
                        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                        : '';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      leading: const Icon(Icons.push_pin, size: 20),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              sender,
                              style: context.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (timeStr.isNotEmpty)
                            Text(
                              timeStr,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: colors.textHint,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          content,
                          style: context.textTheme.bodyMedium,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
