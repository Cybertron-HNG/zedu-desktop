import 'dart:async';

import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class _MockDmRepository extends Mock implements DmRepository {}

class _FakeAuthNotifier extends AuthNotifier {
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
      currentOrganisationSlug: 'org-slug',
      avatarUrl: '',
      defaultAvatarUrl: '',
    ),
  );
}

Map<String, dynamic> serverMessage(String id, String threadId, String text) => {
  'id': id,
  'thread_id': threadId,
  'content': text,
  'user_id': 'user-1',
  'created_at': '2026-11-04T10:00:00Z',
};

void main() {
  group('ChatHistoryNotifier does not show a sent message twice (#1754)', () {
    late _MockDmRepository repository;
    late List<Map<String, dynamic>> serverPage;
    late ProviderContainer container;

    setUp(() {
      repository = _MockDmRepository();
      serverPage = [];
      when(
        () => repository.getMessages(any(), page: any(named: 'page')),
      ).thenAnswer((_) async => List.of(serverPage));
    });

    // Polling runs on a 10 s periodic stream, so these tests use the widget
    // test clock to make it fire.
    Future<ChatHistoryNotifier> start(WidgetTester tester) async {
      container = ProviderContainer(
        overrides: [
          dmRepositoryProvider.overrideWithValue(repository),
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
        ],
      );
      final notifier = container.read(chatHistoryProvider('ch-1'));
      await tester.pump();
      return notifier;
    }

    void stubSend(Future<String> Function() answer) {
      when(
        () => repository.sendMessage(
          any(),
          any(),
          media: any(named: 'media'),
          mentions: any(named: 'mentions'),
          isChannel: any(named: 'isChannel'),
        ),
      ).thenAnswer((_) => answer());
    }

    testWidgets(
      'the next poll replaces the sent message with the server copy',
      (tester) async {
        stubSend(() async => 'thread-1');
        final notifier = await start(tester);

        await notifier.sendMessage('hello');
        serverPage = [serverMessage('msg-1', 'thread-1', 'hello')];
        await tester.pump(const Duration(seconds: 10));
        await tester.pump();

        expect(notifier.messages, hasLength(1));
        expect(notifier.messages.single['id'], 'msg-1');
        expect(notifier.messages.single['content'], 'hello');

        // Later polls keep a single copy.
        await tester.pump(const Duration(seconds: 10));
        await tester.pump();
        expect(notifier.messages, hasLength(1));

        // Stops the 10 s polling timer before the test ends.
        container.dispose();
      },
    );

    testWidgets('a poll that lands before the send finishes leaves one copy', (
      tester,
    ) async {
      final send = Completer<String>();
      stubSend(() => send.future);
      final notifier = await start(tester);

      unawaited(notifier.sendMessage('hello'));
      await tester.pump();
      serverPage = [serverMessage('msg-1', 'thread-1', 'hello')];
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();

      send.complete('thread-1');
      await tester.pump();

      expect(notifier.messages, hasLength(1));
      expect(notifier.messages.single['id'], 'msg-1');

      // Stops the 10 s polling timer before the test ends.
      container.dispose();
    });

    testWidgets('a new message from someone else is still added', (
      tester,
    ) async {
      stubSend(() async => 'thread-1');
      final notifier = await start(tester);

      await notifier.sendMessage('hello');
      serverPage = [
        {...serverMessage('msg-2', 'thread-2', 'hi back'), 'user_id': 'user-2'},
        serverMessage('msg-1', 'thread-1', 'hello'),
      ];
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();

      expect(notifier.messages.map((m) => m['id']), ['msg-2', 'msg-1']);

      // Stops the 10 s polling timer before the test ends.
      container.dispose();
    });
  });
}
