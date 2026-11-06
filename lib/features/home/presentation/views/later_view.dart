import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Left sidebar for the `Later` tab, allowing users to filter saved items by
/// status or conversation type and browse bookmarked messages.
class LaterSidebar extends ConsumerWidget {
  const LaterSidebar({super.key});

  static IconData iconFor(LaterFilter filter) => switch (filter) {
    LaterFilter.inProgress => Icons.schedule_outlined,
    LaterFilter.all => Icons.bookmark_border,
    LaterFilter.channels => Icons.tag,
    LaterFilter.dms => Icons.chat_bubble_outline,
    LaterFilter.completed => Icons.check_circle_outline,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(laterMessagesProvider);
    final notifier = ref.read(laterMessagesProvider.notifier);
    final items = state.filteredItems;
    final selectedId = state.selectedItem?.id;

    return Container(
      width: 320,
      color: colors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WorkspaceSwitcherHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.bookmark_border, color: colors.onPrimary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Later',
                    style: context.textTheme.titleMedium?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                for (final filter in LaterFilter.values)
                  _LaterFilterRow(
                    key: ValueKey('later-sidebar-filter-${filter.name}'),
                    icon: iconFor(filter),
                    label: filter.label,
                    count: state.countFor(filter),
                    isSelected: state.filter == filter,
                    onTap: () => notifier.setFilter(filter),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: colors.onPrimary.withValues(alpha: 0.14)),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No saved messages in this view',
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.onPrimary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = item.id == selectedId;
                      return _SidebarSavedItemTile(
                        key: ValueKey('later-sidebar-item-${item.id}'),
                        item: item,
                        isSelected: isSelected,
                        onTap: () => notifier.selectItem(item.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LaterFilterRow extends StatelessWidget {
  const _LaterFilterRow({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = colors.onPrimary.withValues(
      alpha: isSelected ? 1 : 0.85,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? colors.onPrimary.withValues(alpha: 0.14) : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(icon, color: foreground, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: foreground,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.onPrimary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarSavedItemTile extends StatelessWidget {
  const _SidebarSavedItemTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final SavedLaterItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initial = avatarInitial(item.senderName);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colors.onPrimary.withValues(alpha: 0.14) : null,
            border: Border(
              bottom: BorderSide(
                color: colors.onPrimary.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    item.isChannel
                        ? (item.isPrivateChannel
                              ? Icons.lock_outline
                              : Icons.tag)
                        : Icons.chat_bubble_outline,
                    size: 13,
                    color: colors.onPrimary.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.conversationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: colors.onPrimary.withValues(alpha: 0.85),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: colors.primary,
                    foregroundImage:
                        item.senderAvatarUrl != null &&
                            item.senderAvatarUrl!.isNotEmpty
                        ? NetworkImage(item.senderAvatarUrl!)
                        : null,
                    onForegroundImageError:
                        item.senderAvatarUrl != null &&
                            item.senderAvatarUrl!.isNotEmpty
                        ? ignoreAvatarError
                        : null,
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.senderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.onPrimary.withValues(alpha: 0.78),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Main area of the `Later` view displaying bookmarked channel and DM messages
/// with filter tabs, search, completion toggles, and direct navigation back to
/// the original conversation.
class LaterView extends ConsumerStatefulWidget {
  const LaterView({super.key});

  @override
  ConsumerState<LaterView> createState() => _LaterViewState();
}

class _LaterViewState extends ConsumerState<LaterView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openConversation(SavedLaterItem item) {
    if (item.isChannel) {
      ref.read(homeSidebarProvider.notifier).setType(HomeSidebarType.home);
      ref
          .read(activeChatProvider.notifier)
          .selectChannel(item.conversationName, channelId: item.channelId);
      return;
    }

    ref.read(homeSidebarProvider.notifier).setType(HomeSidebarType.dms);
    ref
        .read(selectedDmProvider.notifier)
        .select(
          DmConversation(
            channelId: item.channelId,
            username: item.conversationName,
            participantId: item.participantId ?? '',
            avatarUrl: item.senderAvatarUrl,
            previewMessage: item.content,
            unreadCount: 0,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(laterMessagesProvider);
    final notifier = ref.read(laterMessagesProvider.notifier);
    final items = state.filteredItems;
    final completedCount = state.countFor(LaterFilter.completed);

    return Container(
      color: colors.onPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.divider)),
            ),
            child: Row(
              children: [
                Icon(Icons.bookmark_border, color: colors.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Later',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.divider),
                  ),
                  child: Text(
                    '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 260,
                  height: 36,
                  child: TextField(
                    key: const ValueKey('later-search-input'),
                    controller: _searchController,
                    onChanged: notifier.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search saved messages...',
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18,
                        color: colors.textSecondary,
                      ),
                      suffixIcon: state.searchQuery.isNotEmpty
                          ? IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                notifier.setSearchQuery('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colors.divider),
                      ),
                    ),
                  ),
                ),
                if (state.filter == LaterFilter.completed &&
                    completedCount > 0) ...[
                  const SizedBox(width: 12),
                  TextButton.icon(
                    key: const ValueKey('later-clear-completed'),
                    onPressed: notifier.clearCompleted,
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text('Clear completed'),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.divider)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in LaterFilter.values)
                    _FilterTab(
                      key: ValueKey('later-tab-${filter.name}'),
                      label: '${filter.label} (${state.countFor(filter)})',
                      isSelected: state.filter == filter,
                      onTap: () => notifier.setFilter(filter),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? _LaterEmptyState(
                    hasAnySaved: state.items.isNotEmpty,
                    hasSearch: state.searchQuery.trim().isNotEmpty,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _SavedLaterCard(
                        key: ValueKey('later-item-${item.id}'),
                        item: item,
                        isSelected: state.selectedItem?.id == item.id,
                        onSelect: () => notifier.selectItem(item.id),
                        onOpenConversation: () => _openConversation(item),
                        onToggleCompleted: () async {
                          await notifier.toggleCompleted(item.id);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  item.isCompleted
                                      ? 'Moved back to In progress'
                                      : 'Marked as completed',
                                ),
                              ),
                            );
                        },
                        onRemove: () async {
                          await notifier.removeSaved(item.id);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text('Removed from Later'),
                              ),
                            );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? colors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: context.textTheme.bodyMedium?.copyWith(
            color: isSelected ? colors.primary : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _LaterEmptyState extends StatelessWidget {
  const _LaterEmptyState({required this.hasAnySaved, required this.hasSearch});

  final bool hasAnySaved;
  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subtitle = hasSearch
        ? 'No saved messages match your search query.'
        : hasAnySaved
        ? 'No saved messages in this filter.'
        : 'Bookmark any channel or direct message with "Save for later" to review it here.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.primaryBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.bookmark_border,
                size: 32,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Saved Later Messages',
              style: context.textTheme.titleMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedLaterCard extends StatelessWidget {
  const _SavedLaterCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onSelect,
    required this.onOpenConversation,
    required this.onToggleCompleted,
    required this.onRemove,
  });

  final SavedLaterItem item;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onOpenConversation;
  final VoidCallback onToggleCompleted;
  final VoidCallback onRemove;

  String _formatTimestamp(BuildContext context, DateTime value) {
    final local = value.toLocal();
    final time = TimeOfDay.fromDateTime(local).format(context);
    return '${local.day}/${local.month}/${local.year} · $time';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initial = avatarInitial(item.senderName);
    final sourceLabel = item.isChannel
        ? '#${item.conversationName}'
        : 'Direct message · ${item.conversationName}';

    return Material(
      color: colors.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? colors.primary : colors.divider,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colors.divider),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.isChannel
                              ? (item.isPrivateChannel
                                    ? Icons.lock_outline
                                    : Icons.tag)
                              : Icons.chat_bubble_outline,
                          size: 14,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          sourceLabel,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.isCompleted) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Completed',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (item.isDeleted) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Deleted',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (!item.isDeleted)
                    TextButton.icon(
                      key: ValueKey('later-open-${item.id}'),
                      onPressed: onOpenConversation,
                      icon: const Icon(Icons.open_in_new, size: 15),
                      label: const Text('Open in conversation'),
                    ),
                  IconButton(
                    key: ValueKey('later-complete-${item.id}'),
                    tooltip: item.isCompleted
                        ? 'Move to in progress'
                        : 'Mark complete',
                    icon: Icon(
                      item.isCompleted
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      size: 19,
                      color: item.isCompleted
                          ? colors.primary
                          : colors.textSecondary,
                    ),
                    onPressed: onToggleCompleted,
                  ),
                  IconButton(
                    key: ValueKey('later-remove-${item.id}'),
                    tooltip: 'Remove from saved',
                    icon: Icon(
                      Icons.bookmark_remove_outlined,
                      size: 19,
                      color: colors.textSecondary,
                    ),
                    onPressed: onRemove,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: colors.primary,
                    foregroundImage:
                        item.senderAvatarUrl != null &&
                            item.senderAvatarUrl!.isNotEmpty
                        ? NetworkImage(item.senderAvatarUrl!)
                        : null,
                    onForegroundImageError:
                        item.senderAvatarUrl != null &&
                            item.senderAvatarUrl!.isNotEmpty
                        ? ignoreAvatarError
                        : null,
                    child: Text(
                      initial,
                      style: TextStyle(color: colors.onPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.senderName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTimestamp(context, item.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        MessageLinkScope(
                          builder: (context, links) => SelectableText.rich(
                            links.span(
                              item.content,
                              TextStyle(
                                fontSize: 15,
                                color: item.isDeleted
                                    ? colors.textSecondary
                                    : colors.textPrimary,
                                fontStyle: item.isDeleted
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
