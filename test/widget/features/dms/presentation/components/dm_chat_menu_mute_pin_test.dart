import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class MockChatHistory extends Mock implements ChatHistoryNotifier {}

class MockDraftStore extends Mock implements DmDraftStore {}

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

void main() {
  setUp(() {
    if (locator.isRegistered<AppConfig>()) {
      locator.unregister<AppConfig>();
    }
    locator.registerSingleton<AppConfig>(
      const AppConfig(apiBaseUrl: 'http://test', usesMockData: false),
    );
  });

  tearDown(() {
    if (locator.isRegistered<AppConfig>()) {
      locator.unregister<AppConfig>();
    }
  });

  Future<void> pumpChat(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final history = MockChatHistory();
    when(() => history.messages).thenReturn([]);
    when(() => history.isLoading).thenReturn(false);
    when(() => history.hasMore).thenReturn(false);
    when(() => history.loadFailed).thenReturn(false);
    when(() => history.loadMoreFailed).thenReturn(false);
    when(() => history.historyCleared).thenReturn(false);
    final drafts = MockDraftStore();
    when(() => drafts.load(any())).thenAnswer((_) async => null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          chatHistoryProvider('chat-1').overrideWith((ref) => history),
          dmDraftStoreProvider.overrideWith((ref) => drafts),
        ],
        child: buildTestMaterialApp(
          Scaffold(
            body: DmChatArea(
              conversation: DmConversation(
                channelId: 'chat-1',
                username: 'Menu Tester',
                participantId: 'user-1',
                previewMessage: '',
                unreadCount: 0,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
  }

  testWidgets('the menu offers Unmute once the conversation is muted (#2950)', (
    tester,
  ) async {
    await pumpChat(tester);

    await openMenu(tester);
    expect(find.text('Unmute notifications'), findsNothing);
    await tester.tap(find.text('Mute notifications'));
    await tester.pumpAndSettle();

    await openMenu(tester);
    expect(find.text('Unmute notifications'), findsOneWidget);
    expect(find.text('Mute notifications'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('the menu offers Unpin once the conversation is pinned (#2950)', (
    tester,
  ) async {
    await pumpChat(tester);

    await openMenu(tester);
    expect(find.text('Unpin conversation'), findsNothing);
    await tester.tap(find.text('Pin conversation'));
    await tester.pumpAndSettle();

    await openMenu(tester);
    expect(find.text('Unpin conversation'), findsOneWidget);
    expect(find.text('Pin conversation'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
