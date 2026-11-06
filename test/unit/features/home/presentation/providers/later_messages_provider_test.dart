import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class _FakeSecureStorageService extends Fake implements SecureStorageService {
  final Map<String, String> data = {};

  @override
  Future<String?> readData(String key) async => data[key];

  @override
  Future<void> writeData(String key, String value) async {
    data[key] = value;
  }

  @override
  Future<void> deleteValue(String key) async {
    data.remove(key);
  }

  @override
  Future<Map<String, String>> readAll() async => Map.of(data);
}

class _FakeRemoteDataSource extends Fake
    implements LaterMessagesRemoteDataSource {
  final List<SavedLaterItem> remoteMessages = [];
  final List<String> deletedIds = [];
  final List<String> completedIds = [];

  @override
  Future<List<SavedLaterItem>> fetchSavedMessages(String orgId) async =>
      remoteMessages;

  @override
  Future<bool> saveThread({
    required String orgId,
    required String channelId,
    required String threadId,
  }) async => true;

  @override
  Future<bool> saveMessage({
    required String orgId,
    required String channelId,
    required String threadId,
    required String messageId,
  }) async => true;

  @override
  Future<void> deleteSavedMessage({
    required String orgId,
    required String savedMessageId,
  }) async {
    deletedIds.add(savedMessageId);
  }

  @override
  Future<void> markComplete({
    required String orgId,
    required String savedMessageId,
    required bool completed,
  }) async {
    completedIds.add(savedMessageId);
  }
}

void main() {
  group('SavedLaterItem and LaterMessagesStore', () {
    test('serialization roundtrip preserves all fields', () {
      final now = DateTime.now();
      final item = SavedLaterItem(
        id: 'ch-1::m-1',
        serverSavedId: 'srv-123',
        messageId: 'm-1',
        threadId: 'th-1',
        channelId: 'ch-1',
        conversationName: 'announcements',
        isChannel: true,
        isPrivateChannel: true,
        senderName: 'Ada Lovelace',
        senderAvatarUrl: 'https://example.com/ada.png',
        content: 'Important company update',
        createdAt: now,
        savedAt: now,
        isCompleted: true,
        isDeleted: false,
      );

      final json = item.toJson();
      final decoded = SavedLaterItem.fromJson(json);

      expect(decoded.id, item.id);
      expect(decoded.serverSavedId, item.serverSavedId);
      expect(decoded.messageId, item.messageId);
      expect(decoded.threadId, item.threadId);
      expect(decoded.channelId, item.channelId);
      expect(decoded.conversationName, item.conversationName);
      expect(decoded.isChannel, isTrue);
      expect(decoded.isPrivateChannel, isTrue);
      expect(decoded.senderName, item.senderName);
      expect(decoded.senderAvatarUrl, item.senderAvatarUrl);
      expect(decoded.content, item.content);
      expect(decoded.isCompleted, isTrue);
      expect(decoded.isDeleted, isFalse);
    });

    test('SavedLaterItem.fromServerJson maps backend response correctly', () {
      final serverMap = {
        'id': 'srv-999',
        'thread_id': 'th-100',
        'message_id': 'msg-200',
        'avatar_url': 'https://example.com/avatar.png',
        'username': 'Grace Hopper',
        'content': 'Compiler ready',
        'user_id': 'u-gh',
        'channel_id': 'ch-compiler',
        'channel_name': 'dev-chat',
        'type': 'message',
        'channel_type': 'public',
        'saved_at': '2026-11-06T05:00:00Z',
        'created_at': '2026-11-06T04:30:00Z',
        'completed': true,
      };

      final parsed = SavedLaterItem.fromServerJson(serverMap);
      expect(parsed.serverSavedId, 'srv-999');
      expect(parsed.threadId, 'th-100');
      expect(parsed.messageId, 'msg-200');
      expect(parsed.senderName, 'Grace Hopper');
      expect(parsed.content, 'Compiler ready');
      expect(parsed.conversationName, 'dev-chat');
      expect(parsed.isChannel, isTrue);
      expect(parsed.isCompleted, isTrue);
      expect(parsed.isDeleted, isFalse);
    });

    test(
      'fromServerJson marks deleted message when backend message was not found',
      () {
        final serverMap = {
          'id': 'srv-del',
          'thread_id': 'th-del',
          'content': 'A message you saved was not found.',
          'channel_id': 'ch-1',
        };
        final parsed = SavedLaterItem.fromServerJson(serverMap);
        expect(parsed.isDeleted, isTrue);
        expect(parsed.content, 'This message was deleted.');
      },
    );

    test('LaterMessagesStore is scoped per user and workspace', () async {
      final storage = _FakeSecureStorageService();
      final store = LaterMessagesStore(storage);

      expect(await store.read(userId: 'u1', orgId: 'org-1'), isEmpty);

      final now = DateTime.now();
      final item = SavedLaterItem(
        id: 'c::m',
        messageId: 'm',
        channelId: 'c',
        conversationName: 'general',
        isChannel: true,
        senderName: 'Bob',
        content: 'Check this later',
        createdAt: now,
        savedAt: now,
      );

      await store.write(userId: 'u1', orgId: 'org-1', items: [item]);

      // u1 can read their saved message
      final loadedU1 = await store.read(userId: 'u1', orgId: 'org-1');
      expect(loadedU1, hasLength(1));
      expect(loadedU1.first.content, 'Check this later');

      // u2 on same org cannot see u1's saved message (privacy protection)
      final loadedU2 = await store.read(userId: 'u2', orgId: 'org-1');
      expect(loadedU2, isEmpty);
    });

    test(
      'deleteAllForUser wipes all saved messages for that user across workspaces',
      () async {
        final storage = _FakeSecureStorageService();
        storage.data['zedu_later_u1_org-1'] = '[{"id":"1"}]';
        storage.data['zedu_later_u1_org-2'] = '[{"id":"2"}]';
        storage.data['zedu_later_u2_org-1'] = '[{"id":"3"}]';

        await LaterMessagesStore.deleteAllForUser(storage, 'u1');

        expect(storage.data.containsKey('zedu_later_u1_org-1'), isFalse);
        expect(storage.data.containsKey('zedu_later_u1_org-2'), isFalse);
        expect(storage.data.containsKey('zedu_later_u2_org-1'), isTrue);
      },
    );
  });

  group('LaterMessagesNotifier', () {
    late _FakeSecureStorageService storage;
    late LaterMessagesStore store;
    late _FakeRemoteDataSource remote;

    setUp(() {
      storage = _FakeSecureStorageService();
      store = LaterMessagesStore(storage);
      remote = _FakeRemoteDataSource();
    });

    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [
          laterMessagesStoreProvider.overrideWithValue(store),
          laterMessagesRemoteDataSourceProvider.overrideWithValue(remote),
        ],
      );
    }

    test('starts with empty items and in-progress filter', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final state = container.read(laterMessagesProvider);
      expect(state.items, isEmpty);
      expect(state.filter, LaterFilter.inProgress);
    });

    test(
      'toggleSaved bookmarks a new item and toggling again removes it',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(laterMessagesProvider.notifier);
        final now = DateTime.now();
        final item = SavedLaterItem(
          id: 'c::m1',
          messageId: 'm1',
          channelId: 'c',
          conversationName: 'general',
          isChannel: true,
          senderName: 'Alice',
          content: 'Hello world',
          createdAt: now,
          savedAt: now,
        );

        final saved = await notifier.toggleSaved(item);
        expect(saved, isTrue);
        expect(container.read(laterMessagesProvider).isSaved('c::m1'), isTrue);
        expect(container.read(laterMessagesProvider).items, hasLength(1));

        final removed = await notifier.toggleSaved(item);
        expect(removed, isFalse);
        expect(container.read(laterMessagesProvider).isSaved('c::m1'), isFalse);
        expect(container.read(laterMessagesProvider).items, isEmpty);
      },
    );

    test('toggleCompleted and clearCompleted manage item completion', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(laterMessagesProvider.notifier);
      final now = DateTime.now();
      final item = SavedLaterItem(
        id: 'dm::m2',
        serverSavedId: 'srv-dm-2',
        messageId: 'm2',
        channelId: 'dm',
        conversationName: 'Direct Chat',
        isChannel: false,
        senderName: 'Charlie',
        content: 'Finish design review',
        createdAt: now,
        savedAt: now,
      );

      await notifier.toggleSaved(item);
      expect(
        container.read(laterMessagesProvider).countFor(LaterFilter.inProgress),
        1,
      );
      expect(
        container.read(laterMessagesProvider).countFor(LaterFilter.completed),
        0,
      );

      await notifier.toggleCompleted('dm::m2');
      expect(
        container.read(laterMessagesProvider).countFor(LaterFilter.inProgress),
        0,
      );
      expect(
        container.read(laterMessagesProvider).countFor(LaterFilter.completed),
        1,
      );
      expect(remote.completedIds, contains('srv-dm-2'));

      await notifier.clearCompleted();
      expect(container.read(laterMessagesProvider).items, isEmpty);
      expect(remote.deletedIds, contains('srv-dm-2'));
    });

    test('handleMessageEdited updates the content of saved item', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(laterMessagesProvider.notifier);
      final now = DateTime.now();
      await notifier.toggleSaved(
        SavedLaterItem(
          id: 'dm::msg-edit',
          messageId: 'msg-edit',
          threadId: 'th-edit',
          channelId: 'dm',
          conversationName: 'Bob',
          isChannel: false,
          senderName: 'Bob',
          content: 'Initial draft message',
          createdAt: now,
          savedAt: now,
        ),
      );

      notifier.handleMessageEdited(
        channelId: 'dm',
        messageId: 'msg-edit',
        threadId: 'th-edit',
        newContent: 'Updated message text after edit',
      );

      final item = container.read(laterMessagesProvider).items.first;
      expect(item.content, 'Updated message text after edit');
    });

    test('handleMessageDeleted marks the saved item as deleted', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(laterMessagesProvider.notifier);
      final now = DateTime.now();
      await notifier.toggleSaved(
        SavedLaterItem(
          id: 'dm::msg-del',
          messageId: 'msg-del',
          threadId: 'th-del',
          channelId: 'dm',
          conversationName: 'Alice',
          isChannel: false,
          senderName: 'Alice',
          content: 'This will be deleted',
          createdAt: now,
          savedAt: now,
        ),
      );

      notifier.handleMessageDeleted(
        channelId: 'dm',
        messageId: 'msg-del',
        threadId: 'th-del',
      );

      final item = container.read(laterMessagesProvider).items.first;
      expect(item.isDeleted, isTrue);
      expect(item.content, 'This message was deleted.');
    });

    test('filters and search queries return matching items', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(laterMessagesProvider.notifier);
      final now = DateTime.now();

      await notifier.toggleSaved(
        SavedLaterItem(
          id: 'c1::m1',
          messageId: 'm1',
          channelId: 'c1',
          conversationName: 'frontend',
          isChannel: true,
          senderName: 'Dan',
          content: 'Flutter update docs',
          createdAt: now,
          savedAt: now,
        ),
      );

      await notifier.toggleSaved(
        SavedLaterItem(
          id: 'dm1::m2',
          messageId: 'm2',
          channelId: 'dm1',
          conversationName: 'Sarah Connor',
          isChannel: false,
          senderName: 'Sarah Connor',
          content: 'Server status check',
          createdAt: now,
          savedAt: now.add(const Duration(seconds: 1)),
        ),
      );

      notifier.setFilter(LaterFilter.channels);
      expect(container.read(laterMessagesProvider).filteredItems, hasLength(1));
      expect(
        container.read(laterMessagesProvider).filteredItems.first.id,
        'c1::m1',
      );

      notifier.setFilter(LaterFilter.dms);
      expect(container.read(laterMessagesProvider).filteredItems, hasLength(1));
      expect(
        container.read(laterMessagesProvider).filteredItems.first.id,
        'dm1::m2',
      );

      notifier.setFilter(LaterFilter.all);
      expect(container.read(laterMessagesProvider).filteredItems, hasLength(2));

      notifier.setSearchQuery('Flutter');
      expect(container.read(laterMessagesProvider).filteredItems, hasLength(1));
      expect(
        container.read(laterMessagesProvider).filteredItems.first.content,
        contains('Flutter'),
      );
    });
  });
}
