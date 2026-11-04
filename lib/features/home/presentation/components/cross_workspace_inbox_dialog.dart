import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Lists mentions, direct messages and unread channels from every workspace
/// the signed-in user belongs to, without switching workspaces first.
class CrossWorkspaceInboxDialog extends ConsumerWidget {
  const CrossWorkspaceInboxDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final inbox = ref.watch(crossWorkspaceInboxProvider);

    return Dialog(
      backgroundColor: colors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 640,
        height: 600,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
              child: Row(
                children: [
                  Icon(Icons.all_inbox_outlined, color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inbox',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Mentions, messages and unread channels from all your workspaces',
                          style: TextStyle(
                            color: colors.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh inbox',
                    icon: Icon(Icons.refresh, color: colors.textHint),
                    onPressed: () => ref
                        .read(crossWorkspaceInboxProvider.notifier)
                        .refresh(),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: Icon(Icons.close, color: colors.textHint),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.divider),
            Expanded(
              child: inbox.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Could not load your inbox.',
                        style: TextStyle(color: colors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref
                            .read(crossWorkspaceInboxProvider.notifier)
                            .refresh(),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
                data: (inbox) => inbox.isEmpty
                    ? Center(
                        child: Text(
                          "You're all caught up.",
                          style: TextStyle(color: colors.textHint),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 16),
                        children: [
                          if (inbox.mentions.isNotEmpty) ...[
                            _SectionHeader(
                              label: 'Mentions',
                              count: inbox.mentions.length,
                            ),
                            for (final item in inbox.mentions)
                              _InboxTile(item: item),
                          ],
                          if (inbox.directMessages.isNotEmpty) ...[
                            _SectionHeader(
                              label: 'Direct messages',
                              count: inbox.directMessages.length,
                            ),
                            for (final item in inbox.directMessages)
                              _InboxTile(item: item),
                          ],
                          if (inbox.unreadChannels.isNotEmpty) ...[
                            _SectionHeader(
                              label: 'Unread channels',
                              count: inbox.unreadChannels.length,
                            ),
                            for (final item in inbox.unreadChannels)
                              _InboxTile(item: item),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: colors.textHint,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: TextStyle(color: colors.textHint, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _InboxTile extends ConsumerWidget {
  const _InboxTile({required this.item});

  final InboxItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final (icon, color) = switch (item.type) {
      InboxItemType.mention => (Icons.alternate_email, colors.accent),
      InboxItemType.directMessage => (
        Icons.chat_bubble_outline,
        colors.primary,
      ),
      InboxItemType.unreadChannel => (Icons.tag, colors.primary),
    };

    return InkWell(
      onTap: () => _open(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.workspaceName} · ${item.preview}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textHint, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (item.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${item.unreadCount}',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (item.timestamp != null)
              Text(
                _when(item.timestamp),
                style: TextStyle(color: colors.textHint, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final workspace = _workspace(ref, item.workspaceId);
    if (workspace != null) {
      await ref.read(workspaceProvider.notifier).switchWorkspace(workspace);
    }
    if (!context.mounted) return;

    if (item.type == InboxItemType.directMessage && item.conversation != null) {
      ref.read(homeSidebarProvider.notifier).setType(HomeSidebarType.dms);
      ref.read(selectedDmProvider.notifier).select(item.conversation);
    } else if (item.channel != null) {
      ref.read(homeSidebarProvider.notifier).setType(HomeSidebarType.home);
      ref
          .read(activeChatProvider.notifier)
          .selectChannel(item.channel!.name.toLowerCase());
    }

    Navigator.pop(context);
    context.go(AppRouter.home);
  }

  Workspace? _workspace(WidgetRef ref, String workspaceId) {
    for (final workspace in ref.read(workspaceProvider).workspaces) {
      if (workspace.id == workspaceId) return workspace;
    }
    return null;
  }

  String _when(DateTime? time) {
    if (time == null) return '';
    final difference = DateTime.now().difference(time.toLocal());
    if (difference.inMinutes < 1) return 'now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }
}
