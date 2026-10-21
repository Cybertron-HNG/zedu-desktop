import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// "A new version of Zedu is available" with a Download button. It never
/// installs anything: Download opens the release page.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(appUpdateProvider).value;
    final dismissed = ref.watch(dismissedUpdateProvider);
    if (update == null || dismissed == update.version) {
      return const SizedBox.shrink();
    }

    final colors = context.colors;
    return Container(
      width: double.infinity,
      color: colors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'A new version of Zedu is available (${update.version}).',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () => launchUrl(Uri.parse(update.url)),
            child: const Text('Download'),
          ),
          IconButton(
            tooltip: 'Dismiss',
            icon: const Icon(Icons.close, size: 18, color: Colors.white),
            onPressed: () => ref
                .read(dismissedUpdateProvider.notifier)
                .dismiss(update.version),
          ),
        ],
      ),
    );
  }
}
