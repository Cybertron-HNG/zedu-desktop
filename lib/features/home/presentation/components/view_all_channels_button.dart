import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// The sidebar row that opens the channel directory in the Home pane.
class ViewAllChannelsButton extends ConsumerWidget {
  const ViewAllChannelsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () =>
            ref.read(activeChatProvider.notifier).selectChannelDirectory(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: colors.onPrimary.withValues(alpha: 0.24)),
            borderRadius: BorderRadius.circular(6),
            color: colors.onPrimary.withValues(alpha: 0.05),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'View all channels',
                  style: TextStyle(
                    color: colors.onPrimary.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colors.onPrimary.withValues(alpha: 0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
