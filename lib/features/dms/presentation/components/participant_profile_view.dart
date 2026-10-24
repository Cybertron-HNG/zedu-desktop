import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class ParticipantProfileView extends StatelessWidget {
  final String userId;
  final DmConversation? conversation;

  const ParticipantProfileView({
    super.key,
    required this.userId,
    this.conversation,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = conversation?.displayName ?? 'User';
    final nameParts = name.trim().split(RegExp(r'\s+'));
    final handle = nameParts.length > 1
        ? '@${nameParts.first}_${nameParts.last}'
        : '@${nameParts.first}';
    final avatarUrl = conversation?.effectiveAvatarUrl;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.go(AppRouter.home),
        ),
        title: Text(
          'Profile',
          style: TextStyle(color: colors.textPrimary, fontSize: 16),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: colors.primary,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 40,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  handle,
                  style: TextStyle(fontSize: 14, color: colors.textSecondary),
                ),
                const SizedBox(height: 16),
                Text(
                  'User ID: $userId',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
