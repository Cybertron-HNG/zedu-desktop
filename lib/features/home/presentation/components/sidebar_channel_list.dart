import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// The workspace's channels in the home sidebar. Tapping a row opens it.
class SidebarChannelList extends ConsumerWidget {
  const SidebarChannelList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref
        .watch(channelProvider)
        .channels
        .where((c) => !c.archived)
        .toList();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 240),
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: [
          for (final channel in channels)
            SidebarChannelItem(
              label: channel.name,
              onTap: () => ref
                  .read(activeChatProvider.notifier)
                  .selectChannel(channel.name),
            ),
        ],
      ),
    );
  }
}

class SidebarChannelItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const SidebarChannelItem({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Text(
              '#',
              style: TextStyle(
                color: colors.onPrimary.withValues(alpha: 0.54),
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(color: colors.onPrimary, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
