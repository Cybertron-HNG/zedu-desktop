import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// How many unread messages make a channel worth jumping into. Fewer than
/// this fit on one screen of a desktop window, so the button would only add
/// noise.
const int channelUnreadJumpThreshold = 5;

/// The child index in the newest-first message list where the unread divider
/// belongs, or `null` when the boundary is not known yet.
///
/// The divider sits after the oldest unread message, so a list with `n`
/// unread messages puts it at child index `n`. When the unread count is
/// larger than the loaded history, the divider can only be placed once every
/// page has been loaded; while pages remain it returns `null` instead of
/// pointing at the wrong message.
int? unreadDividerIndex({
  required int messageCount,
  required int unreadCount,
  required bool hasMore,
}) {
  if (messageCount <= 0 || unreadCount <= 0) return null;
  if (unreadCount <= messageCount) return unreadCount;
  if (!hasMore) return messageCount;
  return null;
}

/// The channel message history with an unread divider and a control that
/// scrolls back to the first unread message.
class ChannelMessageList extends ConsumerStatefulWidget {
  const ChannelMessageList({
    super.key,
    required this.channelId,
    required this.channelName,
    required this.unreadCount,
  });

  final String channelId;
  final String channelName;
  final int unreadCount;

  @override
  ConsumerState<ChannelMessageList> createState() => _ChannelMessageListState();
}

class _ChannelMessageListState extends ConsumerState<ChannelMessageList> {
  final _scrollController = ScrollController();
  final _dividerKey = GlobalKey();
  String? _firstUnreadMessageId;
  bool _jumping = false;
  bool _reachedUnread = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int? _dividerIndex(
    List<Map<String, dynamic>> messages, {
    required bool hasMore,
  }) {
    // Follow the message itself once the boundary is known so newly arrived
    // messages do not shift the divider onto read history.
    final trackedId = _firstUnreadMessageId;
    if (trackedId != null) {
      final index = messages.indexWhere(
        (message) => message['id']?.toString() == trackedId,
      );
      if (index >= 0) return index + 1;
    }

    final index = unreadDividerIndex(
      messageCount: messages.length,
      unreadCount: widget.unreadCount,
      hasMore: hasMore,
    );
    if (index != null) {
      _firstUnreadMessageId = messages[index - 1]['id']?.toString();
    }
    return index;
  }

  Future<void> _jumpToFirstUnread() async {
    if (_jumping) return;
    setState(() => _jumping = true);

    final history = ref.read(chatHistoryProvider(widget.channelId));
    var loaded = 0;
    while (loaded++ < 10 &&
        widget.unreadCount > history.messages.length &&
        history.hasMore &&
        !history.isLoading) {
      await history.loadMore();
      await WidgetsBinding.instance.endOfFrame;
    }

    var reached = false;
    // The divider is only built when it is close to the viewport, so walk the
    // list in viewport-sized steps until it exists, then reveal it exactly.
    for (var attempt = 0; attempt < 40; attempt++) {
      if (!mounted) return;
      final dividerContext = _dividerKey.currentContext;
      if (dividerContext != null) {
        if (!dividerContext.mounted) break;
        await Scrollable.ensureVisible(
          dividerContext,
          alignment: 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
        reached = true;
        break;
      }
      if (!_scrollController.hasClients) break;
      final position = _scrollController.position;
      final next = (position.pixels + position.viewportDimension * 0.7).clamp(
        0.0,
        position.maxScrollExtent,
      );
      if ((next - position.pixels).abs() < 1) break;
      _scrollController.jumpTo(next);
      await WidgetsBinding.instance.endOfFrame;
    }

    if (!mounted) return;
    setState(() {
      _jumping = false;
      _reachedUnread = reached;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final history = ref.watch(chatHistoryProvider(widget.channelId));
    final messages = history.messages;
    final dividerIndex = _dividerIndex(messages, hasMore: history.hasMore);
    final itemCount = messages.length + (dividerIndex == null ? 0 : 1);
    final showJump =
        !_reachedUnread &&
        dividerIndex != null &&
        widget.unreadCount >= channelUnreadJumpThreshold;

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (!history.isLoading &&
                history.hasMore &&
                scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent * 0.8) {
              ref.read(chatHistoryProvider(widget.channelId)).loadMore();
            }
            return false;
          },
          child: CustomScrollView(
            controller: _scrollController,
            reverse: true,
            // ignore: deprecated_member_use
            cacheExtent: 2000,
            slivers: [
              if (messages.isEmpty && history.isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (messages.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No messages yet. Say hello to #${widget.channelName}.',
                      style: TextStyle(color: colors.textHint),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (dividerIndex != null && index == dividerIndex) {
                        return _UnreadDivider(key: _dividerKey);
                      }
                      final messageIndex =
                          dividerIndex != null && index > dividerIndex
                          ? index - 1
                          : index;
                      return _ChannelMessageBubble(
                        message: messages[messageIndex],
                      );
                    }, childCount: itemCount),
                  ),
                ),
              if (history.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
        if (showJump)
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(
              child: FilledButton.icon(
                onPressed: _jumping ? null : _jumpToFirstUnread,
                icon: const Icon(Icons.arrow_upward, size: 18),
                label: Text(_jumping ? 'Jumping…' : 'Jump to first unread'),
              ),
            ),
          ),
      ],
    );
  }
}

class _ChannelMessageBubble extends StatelessWidget {
  const _ChannelMessageBubble({required this.message});

  final Map<String, dynamic> message;

  String get _author {
    final name = (message['sender_name'] ?? message['username'] ?? '')
        .toString()
        .trim();
    return name.isEmpty ? 'Unknown' : name;
  }

  String get _timestamp {
    final createdAt = DateTime.tryParse(
      message['created_at']?.toString() ?? '',
    )?.toLocal();
    if (createdAt == null) return '';
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get _text {
    final content = (message['content'] ?? '').toString().trim();
    if (content.isNotEmpty) return content;
    final media = message['media'];
    if (media is List && media.isNotEmpty) return '[Attachment]';
    return '[Message]';
  }

  @override
  Widget build(BuildContext context) {
    return MessageBubble(author: _author, text: _text, timestamp: _timestamp);
  }
}

class _UnreadDivider extends StatelessWidget {
  const _UnreadDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: colors.primary)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'New messages',
              style: TextStyle(
                color: colors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Divider(color: colors.primary)),
        ],
      ),
    );
  }
}
