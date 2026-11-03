import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// "View profile" from the DM menu: who you're talking to, with their picture
/// (or initial), name and email. Internal ids are never shown.
class DmParticipantProfileDialog extends StatelessWidget {
  const DmParticipantProfileDialog({super.key, required this.conversation});

  final DmConversation conversation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = conversation.displayName;
    final email = conversation.participantEmail?.trim() ?? '';
    final avatarUrl = conversation.effectiveAvatarUrl;
    final trimmed = name.trim();
    // A whole character, so a name that starts with an emoji isn't cut in half.
    final initial = trimmed.isEmpty
        ? '?'
        : trimmed.characters.first.toUpperCase();

    return AlertDialog(
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            CircleAvatar(
              radius: 36,
              backgroundColor: colors.primary,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 14),
            Text(
              name,
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 6),
              SelectableText(
                email,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.textHint,
                ),
              ),
            ],
          ],
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
