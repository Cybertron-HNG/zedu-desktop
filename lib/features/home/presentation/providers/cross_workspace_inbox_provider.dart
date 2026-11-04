import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

enum InboxItemType { mention, directMessage, unreadChannel }

/// One row in the cross-workspace inbox.
class InboxItem {
  const InboxItem({
    required this.type,
    required this.workspaceId,
    required this.workspaceName,
    required this.channelId,
    required this.title,
    required this.preview,
    this.timestamp,
    this.unreadCount = 0,
    this.conversation,
    this.channel,
  });

  final InboxItemType type;
  final String workspaceId;
  final String workspaceName;
  final String channelId;
  final String title;
  final String preview;
  final DateTime? timestamp;
  final int unreadCount;

  /// Set for direct messages so the inbox can open the conversation directly.
  final DmConversation? conversation;

  /// Set for channel items so the inbox can select the channel by name.
  final Channel? channel;
}

class CrossWorkspaceInbox {
  const CrossWorkspaceInbox({
    this.mentions = const [],
    this.directMessages = const [],
    this.unreadChannels = const [],
  });

  final List<InboxItem> mentions;
  final List<InboxItem> directMessages;
  final List<InboxItem> unreadChannels;

  bool get isEmpty =>
      mentions.isEmpty && directMessages.isEmpty && unreadChannels.isEmpty;
}

final crossWorkspaceInboxProvider =
    AsyncNotifierProvider<CrossWorkspaceInboxNotifier, CrossWorkspaceInbox>(
      CrossWorkspaceInboxNotifier.new,
    );

/// Collects mentions, direct messages and unread channels from every
/// workspace the user belongs to.
///
/// The API has no mentions endpoint, so mentions are found by scanning the
/// first page of unread channels for the signed-in username. The scan is
/// capped so opening the inbox never fans out into an unbounded number of
/// requests.
class CrossWorkspaceInboxNotifier extends AsyncNotifier<CrossWorkspaceInbox> {
  static const int mentionScanLimit = 12;
  static const int mentionsPerChannel = 2;
  static const int itemsPerWorkspace = 10;

  @override
  Future<CrossWorkspaceInbox> build() async {
    final workspaces = ref.watch(workspaceProvider.select((s) => s.workspaces));
    final user = ref.watch(authNotifierProvider.select((s) => s.user));
    if (workspaces.isEmpty || user == null) {
      return const CrossWorkspaceInbox();
    }

    final dmRepository = ref.read(dmRepositoryProvider);
    final channelRepository = ref.read(channelRepositoryProvider);
    final username = user.username.toLowerCase();
    final userId = user.id;

    final mentions = <InboxItem>[];
    final directMessages = <InboxItem>[];
    final unreadChannels = <InboxItem>[];
    var mentionBudget = mentionScanLimit;

    for (final workspace in workspaces) {
      final channels = await _loadChannels(channelRepository, workspace.id);

      for (final channel in channels) {
        if (channel.unreadCount <= 0) continue;
        if (unreadChannels.length < itemsPerWorkspace * workspaces.length) {
          unreadChannels.add(
            InboxItem(
              type: InboxItemType.unreadChannel,
              workspaceId: workspace.id,
              workspaceName: workspace.name,
              channelId: channel.id,
              title: '#${channel.name}',
              preview: channel.unreadCount == 1
                  ? '1 unread message'
                  : '${channel.unreadCount} unread messages',
              unreadCount: channel.unreadCount,
              channel: channel,
            ),
          );
        }

        if (mentionBudget <= 0 || username.isEmpty) continue;
        mentionBudget--;
        final found = await _loadMentions(
          dmRepository,
          channel: channel,
          workspace: workspace,
          username: username,
          userId: userId,
        );
        mentions.addAll(found);
      }

      final conversations = await _loadConversations(
        dmRepository,
        workspace.id,
      );
      for (final conversation in conversations.take(itemsPerWorkspace)) {
        directMessages.add(
          InboxItem(
            type: InboxItemType.directMessage,
            workspaceId: workspace.id,
            workspaceName: workspace.name,
            channelId: conversation.channelId,
            title: conversation.displayName,
            preview: conversation.previewMessage,
            timestamp: conversation.hasActivity
                ? conversation.lastActivityAt
                : null,
            unreadCount: conversation.unreadCount,
            conversation: conversation,
          ),
        );
      }
    }

    mentions.sort((a, b) => _latestFirst(a, b));
    directMessages.sort((a, b) => _latestFirst(a, b));
    unreadChannels.sort((a, b) => b.unreadCount.compareTo(a.unreadCount));

    return CrossWorkspaceInbox(
      mentions: mentions,
      directMessages: directMessages,
      unreadChannels: unreadChannels,
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<List<Channel>> _loadChannels(
    ChannelRepository repository,
    String orgId,
  ) async {
    try {
      final result = await repository.fetchChannels(orgId);
      return switch (result) {
        Success<List<Channel>>(:final value) => value,
        Failure<List<Channel>>() => const [],
      };
    } catch (_) {
      return const [];
    }
  }

  Future<List<DmConversation>> _loadConversations(
    DmRepository repository,
    String orgId,
  ) async {
    try {
      return await repository.getConversations(orgId: orgId);
    } catch (_) {
      return const [];
    }
  }

  Future<List<InboxItem>> _loadMentions(
    DmRepository repository, {
    required Channel channel,
    required Workspace workspace,
    required String username,
    required String userId,
  }) async {
    final List<Map<String, dynamic>> messages;
    try {
      messages = await repository.getMessages(channel.id);
    } catch (_) {
      return const [];
    }

    final found = <InboxItem>[];
    for (final message in messages) {
      if (found.length >= mentionsPerChannel) break;
      final content = (message['content'] ?? '').toString();
      if (!mentionsUser(content, username)) continue;
      final senderId = (message['user_id'] ?? message['userId']).toString();
      if (senderId == userId || senderId == 'me') continue;
      final senderName = (message['sender_name'] ?? message['username'] ?? '')
          .toString()
          .trim();
      found.add(
        InboxItem(
          type: InboxItemType.mention,
          workspaceId: workspace.id,
          workspaceName: workspace.name,
          channelId: channel.id,
          title: senderName.isEmpty
              ? 'Mentioned in #${channel.name}'
              : '$senderName mentioned you in #${channel.name}',
          preview: inboxPreview(content),
          timestamp: DateTime.tryParse(message['created_at']?.toString() ?? ''),
          channel: channel,
        ),
      );
    }
    return found;
  }

  int _latestFirst(InboxItem a, InboxItem b) {
    final aTime = a.timestamp;
    final bTime = b.timestamp;
    if (aTime == null && bTime == null) return 0;
    if (aTime == null) return 1;
    if (bTime == null) return -1;
    return bTime.compareTo(aTime);
  }
}

/// True when [content] contains `@username` as a whole handle. The leading
/// guard keeps email addresses such as `hi@joshua.com` from counting.
bool mentionsUser(String content, String username) {
  final handle = username.trim().toLowerCase();
  if (handle.isEmpty) return false;
  final pattern = RegExp(
    '(?<![\\w.@])@${RegExp.escape(handle)}(?![\\w])',
    caseSensitive: false,
  );
  return pattern.hasMatch(content);
}

/// A short, tag-free preview for inbox rows.
String inboxPreview(String content, {int maxLength = 120}) {
  var text = content
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (text.isEmpty) text = '[Message]';
  if (text.length > maxLength) {
    text = '${text.substring(0, maxLength - 3)}...';
  }
  return text;
}
