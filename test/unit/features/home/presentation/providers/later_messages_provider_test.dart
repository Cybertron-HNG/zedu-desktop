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
}

void main() {
  group('SavedLaterItem and LaterMessagesStore', () {
    test('serialization roundtrip preserves all fields', () {
      final now = DateTime.now();
      final item = SavedLaterItem(
        id: 'ch-1::m-1',
        messageId: 'm-1',
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
      );

      final json = item.toJson();
      final decoded = SavedLaterItem.fromJson(json);

      expect(decoded.id, item.id);
      expect(decoded.messageId, item.messageId);
      expect(decoded.channelId, item.channelId);
      expect(decoded.conversationName, item.conversationName);
      expect(decoded.isChannel, isTrue);
      expect(decoded.isPrivateChannel, isTrue);
      expect(decoded.senderName, item.senderName);
      expect(decoded.senderAvatarUrl, item.senderAvatarUrl);
      expect(decoded.content, item.content);
      expect(decoded.isCompleted, isTrue);
    });

    test('LaterMessagesStore reads and writes through storage', () async {
      final storage = _FakeSecureStorageService();
      final store = LaterMessagesStore(storage);

      expect(await store.read('org-1'), isEmpty);

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

      await store.write('org-1', [item]);
      final loaded = await store.read('org-1');
      expect(loaded, hasLength(1));
      expect(loaded.first.id, 'c::m');
      expect(loaded.first.content, 'Check this later');
    });
  });

  group('LaterMessagesNotifier', () {
    late _FakeSecureStorageService storage;
    late LaterMessagesStore store;

    setUp(() {
      storage = _FakeSecureStorageService();
      store = LaterMessagesStore(storage);
    });

    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [laterMessagesStoreProvider.overrideWithValue(store)],
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

      await notifier.clearCompleted();
      expect(container.read(laterMessagesProvider).items, isEmpty);
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
