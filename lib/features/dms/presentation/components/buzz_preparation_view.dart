import 'package:zedu/core/core.dart';

class BuzzPreparationView extends StatelessWidget {
  final String remoteUserName;
  final VoidCallback onCancel;
  final VoidCallback onJoin;

  const BuzzPreparationView({
    super.key,
    required this.remoteUserName,
    required this.onCancel,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 64,
              backgroundColor: Color(0xFF6458F5),
              child: Icon(Icons.person, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 32),
            Text(
              'Preparing your buzz with',
              style: TextStyle(color: colors.textHint, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              remoteUserName,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    side: BorderSide(color: colors.divider),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: colors.textPrimary),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: onJoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6458F5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Join Call',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
