import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class DmSidebarList extends ConsumerStatefulWidget {
  const DmSidebarList({super.key});

  @override
  ConsumerState<DmSidebarList> createState() => _DmSidebarListState();
}

class _DmSidebarListState extends ConsumerState<DmSidebarList> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(DmConversation conversation) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return conversation.displayName.toLowerCase().contains(query) ||
        conversation.previewMessage.toLowerCase().contains(query);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 320,
      color: colors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceSwitcherHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              style: TextStyle(color: colors.onPrimary, fontSize: 12),
              cursorColor: colors.onPrimary,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.transparent,
                hintText: 'Find a Conversation',
                hintStyle: TextStyle(
                  color: colors.onPrimary.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: colors.onPrimary.withValues(alpha: 0.9),
                  size: 16,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _clearSearch,
                        icon: Icon(
                          Icons.close,
                          color: colors.onPrimary.withValues(alpha: 0.9),
                          size: 16,
                        ),
                        splashRadius: 16,
                        tooltip: 'Clear search',
                      ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(
                    color: colors.onPrimary.withValues(alpha: 0.68),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(
                    color: colors.onPrimary.withValues(alpha: 0.68),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: colors.primary),
                ),
              ),
            ),
          ),
          Expanded(
            child: ref
                .watch(dmListProvider)
                .when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      'Failed to load DMs',
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                  data: (conversations) {
                    final actions = ref.watch(dmConversationActionsProvider);
                    final visibleConversations =
                        conversations
                            .where(
                              (conversation) =>
                                  !actions.deletedIds.contains(
                                    conversation.channelId,
                                  ) &&
                                  _matches(conversation),
                            )
                            .toList()
                          ..sort((a, b) {
                            final aPinned = actions.pinnedIds.contains(
                              a.channelId,
                            );
                            final bPinned = actions.pinnedIds.contains(
                              b.channelId,
                            );
                            if (aPinned != bPinned) return aPinned ? -1 : 1;
                            return b.lastActivityAt.compareTo(a.lastActivityAt);
                          });
                    if (visibleConversations.isEmpty) {
                      return Center(
                        child: Text(
                          _query.trim().isEmpty
                              ? 'No recent chats'
                              : 'No conversations found',
                          style: TextStyle(
                            color: colors.onPrimary.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    }
                    return NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (scrollInfo is ScrollEndNotification &&
                            scrollInfo.metrics.pixels >=
                                scrollInfo.metrics.maxScrollExtent * 0.85) {
                          final notifier = ref.read(dmListProvider.notifier);
                          if (notifier.hasMore) {
                            notifier.loadMore();
                          }
                        }
                        return false;
                      },
                      // Transparent Material so each row's hover and
                      // selected ink paints above the sidebar colour.
                      child: Material(
                        type: MaterialType.transparency,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: visibleConversations.length,
                          itemBuilder: (context, index) {
                            return DmListTile(
                              conversation: visibleConversations[index],
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
