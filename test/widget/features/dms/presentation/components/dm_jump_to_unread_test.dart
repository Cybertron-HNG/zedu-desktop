import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class _MockDmRepository extends Mock implements DmRepository {}

class _MockSecureStorageService extends Mock implements SecureStorageService {}

class _SignedInAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: User(
      id: 'user-1',
      firstName: 'Test',
      lastName: 'User',
      email: 'test@example.com',
      phone: '',
      username: 'testuser',
      isVerified: true,
      isOnboarded: true,
      createdAt: DateTime(2026),
      currentOrg: 'org-1',
      currentOrganisationSlug: 'test-org',
      avatarUrl: '',
      defaultAvatarUrl: '',
    ),
  );
}

/// [count] messages from the other person, newest first (m0 is the newest).
List<Map<String, dynamic>> _messages(int count) => [
  for (var i = 0; i < count; i++)
    {
      'id': 'm$i',
      'content': 'Message number $i',
      'user_id': 'u-2',
      'created_at': '2026-10-17T08:00:00Z',
    },
];

void main() {
  Future<void> pumpDm(
    WidgetTester tester, {
    required int messageCount,
    required int unreadCount,
  }) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _MockDmRepository();
    final messages = _messages(messageCount);
    when(
      () => repository.getMessages(any(), page: any(named: 'page')),
    ).thenAnswer((_) async => messages);
    final storage = _MockSecureStorageService();
    when(() => storage.readData(any())).thenAnswer((_) async => null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dmRepositoryProvider.overrideWithValue(repository),
          authNotifierProvider.overrideWith(_SignedInAuthNotifier.new),
          dmDraftStoreProvider.overrideWith(
            (ref) => DmDraftStore(storage, userId: 'user-1', orgId: 'org-1'),
          ),
        ],
        child: buildTestMaterialApp(
          Scaffold(
            body: DmChatArea(
              conversation: DmConversation(
                channelId: 'ch-1',
                username: 'Ada Lovelace',
                participantId: 'u-2',
                previewMessage: '',
                unreadCount: unreadCount,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final jumpButton = find.byKey(const ValueKey('dm-jump-to-first-unread'));

  testWidgets('many unread messages offer a jump button with the count', (
    tester,
  ) async {
    await pumpDm(tester, messageCount: 40, unreadCount: 25);

    expect(jumpButton, findsOneWidget);
    expect(find.text('Jump to first unread · 25 new'), findsOneWidget);
  });

  testWidgets('the jump scrolls to the first unread message and hides', (
    tester,
  ) async {
    await pumpDm(tester, messageCount: 40, unreadCount: 25);
    // The 25th newest message (m24) is the first unread one, far above the
    // bottom of the list.
    expect(find.text('Message number 24', findRichText: true), findsNothing);

    await tester.tap(jumpButton);
    await tester.pumpAndSettle();

    expect(find.text('New messages'), findsOneWidget);
    expect(find.text('Message number 24', findRichText: true), findsOneWidget);
    expect(jumpButton, findsNothing);
  });

  testWidgets('a few unread messages get the divider but no button', (
    tester,
  ) async {
    await pumpDm(tester, messageCount: 5, unreadCount: 2);

    expect(find.text('New messages'), findsOneWidget);
    expect(jumpButton, findsNothing);
  });

  testWidgets('nothing unread shows neither the divider nor the button', (
    tester,
  ) async {
    await pumpDm(tester, messageCount: 40, unreadCount: 0);

    expect(find.text('New messages'), findsNothing);
    expect(jumpButton, findsNothing);
  });
}
