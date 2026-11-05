import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class _FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState(
    selectedWorkspace: Workspace(id: 'org-1', name: 'Workspace A', avatar: ''),
  );
}

class _FakeChannelNotifier extends ChannelNotifier {
  @override
  Future<List<Channel>> build() async => [
    Channel(
      id: 'channel-general',
      name: 'general',
      description: '',
      organisationId: 'org-1',
      ownerId: 'u-1',
    ),
  ];
}

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

Future<void> _pumpLater(
  WidgetTester tester, {
  required LaterMessagesStore store,
  List<SavedLaterItem> initialItems = const [],
}) async {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workspaceProvider.overrideWith(_FakeWorkspaceNotifier.new),
        channelProvider.overrideWith(_FakeChannelNotifier.new),
        laterMessagesStoreProvider.overrideWithValue(store),
      ],
      child: buildTestMaterialApp(
        const Scaffold(
          body: Row(
            children: [
              LaterSidebar(),
              Expanded(child: LaterView()),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  if (initialItems.isNotEmpty) {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LaterView)),
    );
    for (final item in initialItems) {
      await container.read(laterMessagesProvider.notifier).toggleSaved(item);
    }
    await tester.pumpAndSettle();
  }
}

void main() {
  late _FakeSecureStorageService storage;
  late LaterMessagesStore store;

  setUp(() {
    storage = _FakeSecureStorageService();
    store = LaterMessagesStore(storage);
  });

  final now = DateTime(2026, 11, 5, 14, 30);
  final testChannelItem = SavedLaterItem(
    id: 'channel-general::m-1',
    messageId: 'm-1',
    channelId: 'channel-general',
    conversationName: 'general',
    isChannel: true,
    senderName: 'Ada Lovelace',
    content: 'Review deployment checklist',
    createdAt: now,
    savedAt: now,
  );

  final testDmItem = SavedLaterItem(
    id: 'dm-1::m-2',
    messageId: 'm-2',
    channelId: 'dm-1',
    conversationName: 'Grace Hopper',
    isChannel: false,
    participantId: 'user-gh',
    senderName: 'Grace Hopper',
    content: 'Meeting notes from 1-on-1',
    createdAt: now,
    savedAt: now.add(const Duration(minutes: 5)),
  );

  testWidgets('shows empty state when no saved messages exist', (tester) async {
    await _pumpLater(tester, store: store);

    expect(find.text('Saved Later Messages'), findsOneWidget);
    expect(
      find.text(
        'Bookmark any channel or direct message with "Save for later" to review it here.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders saved items and counts in sidebar and main view', (
    tester,
  ) async {
    await _pumpLater(
      tester,
      store: store,
      initialItems: [testChannelItem, testDmItem],
    );

    expect(find.text('Review deployment checklist'), findsWidgets);
    expect(find.text('Meeting notes from 1-on-1'), findsWidgets);
    expect(find.text('#general'), findsOneWidget);
    expect(find.text('Direct message · Grace Hopper'), findsOneWidget);

    // Sidebar filter counts
    expect(
      find.byKey(const ValueKey('later-sidebar-filter-inProgress')),
      findsOneWidget,
    );
    expect(find.text('2 items'), findsOneWidget);
  });

  testWidgets('filters items when switching tabs', (tester) async {
    await _pumpLater(
      tester,
      store: store,
      initialItems: [testChannelItem, testDmItem],
    );

    await tester.tap(find.byKey(const ValueKey('later-tab-channels')));
    await tester.pumpAndSettle();

    expect(find.text('Review deployment checklist'), findsWidgets);
    expect(find.text('Meeting notes from 1-on-1'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('later-tab-dms')));
    await tester.pumpAndSettle();

    expect(find.text('Review deployment checklist'), findsNothing);
    expect(find.text('Meeting notes from 1-on-1'), findsWidgets);
  });

  testWidgets('search box filters visible saved messages', (tester) async {
    await _pumpLater(
      tester,
      store: store,
      initialItems: [testChannelItem, testDmItem],
    );

    await tester.enterText(
      find.byKey(const ValueKey('later-search-input')),
      'deployment',
    );
    await tester.pumpAndSettle();

    expect(find.text('Review deployment checklist'), findsWidgets);
    expect(find.text('Meeting notes from 1-on-1'), findsNothing);
  });

  testWidgets('marking an item complete moves it to Completed tab', (
    tester,
  ) async {
    await _pumpLater(tester, store: store, initialItems: [testChannelItem]);

    expect(find.text('Review deployment checklist'), findsWidgets);

    await tester.tap(
      find.byKey(ValueKey('later-complete-${testChannelItem.id}')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Marked as completed'), findsOneWidget);
    // In progress tab is now empty
    expect(find.text('Saved Later Messages'), findsOneWidget);

    // Switch to Completed tab
    await tester.tap(find.byKey(const ValueKey('later-tab-completed')));
    await tester.pumpAndSettle();

    expect(find.text('Review deployment checklist'), findsWidgets);
    expect(find.text('Completed'), findsWidgets);
  });

  testWidgets('removing an item deletes it from Later', (tester) async {
    await _pumpLater(tester, store: store, initialItems: [testChannelItem]);

    await tester.tap(
      find.byKey(ValueKey('later-remove-${testChannelItem.id}')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Removed from Later'), findsOneWidget);
    expect(find.text('Saved Later Messages'), findsOneWidget);
  });

  testWidgets('open in conversation navigates to channel or dm', (
    tester,
  ) async {
    await _pumpLater(
      tester,
      store: store,
      initialItems: [testChannelItem, testDmItem],
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LaterView)),
    );

    await tester.tap(find.byKey(ValueKey('later-open-${testChannelItem.id}')));
    await tester.pumpAndSettle();

    expect(container.read(homeSidebarProvider), HomeSidebarType.home);
    expect(container.read(activeChatProvider).id, 'general');

    await tester.tap(find.byKey(ValueKey('later-open-${testDmItem.id}')));
    await tester.pumpAndSettle();

    expect(container.read(homeSidebarProvider), HomeSidebarType.dms);
    expect(container.read(selectedDmProvider)?.channelId, 'dm-1');
  });
}
