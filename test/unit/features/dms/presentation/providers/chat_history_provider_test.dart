import 'dart:async';

import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockDmRepository extends Mock implements DmRepository {}

class _SignedOutAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

void main() {
  group('ChatHistoryNotifier polling', () {
    late MockDmRepository repository;

    List<Map<String, dynamic>> history(String content) => [
      {'id': 'm1', 'content': content, 'user_id': 'u1'},
    ];

    ChatHistoryNotifier open(ProviderContainer container) =>
        container.read(chatHistoryProvider('ch-1'));

    setUp(() => repository = MockDmRepository());

    testWidgets('replaces the text of a message edited elsewhere', (
      tester,
    ) async {
      {
        final reads = [history('original'), history('corrected')];
        when(
          () => repository.getMessages(any(), page: any(named: 'page')),
        ).thenAnswer((_) async => reads.removeAt(0));
        final container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith(_SignedOutAuth.new),
            dmRepositoryProvider.overrideWithValue(repository),
          ],
        );
        final notifier = open(container);
        await tester.pump();
        expect(notifier.messages.single['content'], 'original');

        await tester.pump(const Duration(seconds: 10));
        await tester.pump();

        expect(notifier.messages, hasLength(1));
        expect(notifier.messages.single['id'], 'm1');
        expect(notifier.messages.single['content'], 'corrected');
        container.dispose();
      }
    });

    testWidgets('leaves the list alone when the response is unchanged', (
      tester,
    ) async {
      {
        when(
          () => repository.getMessages(any(), page: any(named: 'page')),
        ).thenAnswer((_) async => history('same'));
        final container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith(_SignedOutAuth.new),
            dmRepositoryProvider.overrideWithValue(repository),
          ],
        );
        final notifier = open(container);
        await tester.pump();
        var notified = 0;
        notifier.addListener(() => notified++);

        await tester.pump(const Duration(seconds: 10));
        await tester.pump();

        expect(notifier.messages.single['content'], 'same');
        expect(notified, 0);
        container.dispose();
      }
    });

    testWidgets(
      'still prepends new arrivals and updates edited text together',
      (tester) async {
        {
          final reads = [
            history('original'),
            [
              {'id': 'm2', 'content': 'new', 'user_id': 'me'},
              ...history('corrected'),
            ],
          ];
          when(
            () => repository.getMessages(any(), page: any(named: 'page')),
          ).thenAnswer((_) async => reads.removeAt(0));
          final container = ProviderContainer(
            overrides: [
              authNotifierProvider.overrideWith(_SignedOutAuth.new),
              dmRepositoryProvider.overrideWithValue(repository),
            ],
          );
          final notifier = open(container);
          await tester.pump();

          await tester.pump(const Duration(seconds: 10));
          await tester.pump();

          expect(notifier.messages.map((m) => m['id']), ['m2', 'm1']);
          expect(notifier.messages.last['content'], 'corrected');
          container.dispose();
        }
      },
    );

    testWidgets('does not overwrite an edit that is still being saved', (
      tester,
    ) async {
      {
        final reads = [history('original'), history('original')];
        when(
          () => repository.getMessages(any(), page: any(named: 'page')),
        ).thenAnswer((_) async => reads.removeAt(0));
        final saving = Completer<void>();
        when(
          () => repository.editMessage(any(), content: any(named: 'content')),
        ).thenAnswer((_) => saving.future);
        final container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith(_SignedOutAuth.new),
            dmRepositoryProvider.overrideWithValue(repository),
          ],
        );
        final notifier = open(container);
        await tester.pump();

        unawaited(notifier.saveEdit('m1', 'my edit'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 10));
        await tester.pump();

        expect(notifier.messages.single['content'], 'my edit');
        saving.complete();
        await tester.pump();
        container.dispose();
      }
    });
  });

  _deleteTests();
  group('ChatHistoryNotifier.saveEdit', () {
    late MockDmRepository mockRepository;
    late ProviderContainer container;
    late ChatHistoryNotifier notifier;

    final initialMessages = <Map<String, dynamic>>[
      {'id': 'm1', 'content': 'hello', 'user_id': 'u1'},
    ];

    setUp(() async {
      mockRepository = MockDmRepository();
      when(
        () => mockRepository.getMessages(any(), page: any(named: 'page')),
      ).thenAnswer(
        (_) async => List<Map<String, dynamic>>.from(initialMessages),
      );

      container = ProviderContainer(
        overrides: [dmRepositoryProvider.overrideWithValue(mockRepository)],
      );
      notifier = container.read(chatHistoryProvider('ch-1'));
      await pumpEventQueue();
    });

    tearDown(() {
      container.dispose();
    });

    test('keeps the new content when the edit request succeeds', () async {
      when(
        () => mockRepository.editMessage(any(), content: any(named: 'content')),
      ).thenAnswer((_) async {});

      notifier.startEditing('m1');
      await notifier.saveEdit('m1', 'edited');

      expect(notifier.editingMessageId, isNull);
      expect(notifier.messages.single['content'], 'edited');
    });

    test(
      'reverts to the original content when the edit request fails',
      () async {
        when(
          () =>
              mockRepository.editMessage(any(), content: any(named: 'content')),
        ).thenThrow(Exception('network error'));

        notifier.startEditing('m1');
        await notifier.saveEdit('m1', 'edited');

        expect(notifier.editingMessageId, isNull);
        expect(notifier.messages.single['content'], 'hello');
      },
    );

    test(
      'reverts to null content when the edited message had no content',
      () async {
        when(
          () =>
              mockRepository.editMessage(any(), content: any(named: 'content')),
        ).thenThrow(Exception('network error'));

        notifier.messages = [
          {'id': 'm1', 'content': null, 'user_id': 'u1'},
        ];

        notifier.startEditing('m1');
        await notifier.saveEdit('m1', 'edited');

        expect(notifier.editingMessageId, isNull);
        expect(notifier.messages.single['content'], isNull);
      },
    );

    test(
      'keeps the newer edit when an older pending edit fails later',
      () async {
        final firstRequest = Completer<void>();
        var callCount = 0;
        when(
          () =>
              mockRepository.editMessage(any(), content: any(named: 'content')),
        ).thenAnswer((_) {
          callCount++;
          if (callCount == 1) return firstRequest.future;
          return Future.value();
        });

        notifier.startEditing('m1');
        final first = notifier.saveEdit('m1', 'edited1');
        notifier.startEditing('m1');
        final second = notifier.saveEdit('m1', 'edited2');

        firstRequest.completeError(Exception('network error'));
        await second;
        await first;

        expect(notifier.messages.single['content'], 'edited2');
      },
    );

    test(
      'keeps the newer save when an older edit with the same content fails',
      () async {
        final firstRequest = Completer<void>();
        var callCount = 0;
        when(
          () =>
              mockRepository.editMessage(any(), content: any(named: 'content')),
        ).thenAnswer((_) {
          callCount++;
          if (callCount == 1) return firstRequest.future;
          return Future.value();
        });

        notifier.startEditing('m1');
        final first = notifier.saveEdit('m1', 'edited');
        notifier.startEditing('m1');
        final second = notifier.saveEdit('m1', 'edited');

        firstRequest.completeError(Exception('network error'));
        await second;
        await first;

        expect(notifier.messages.single['content'], 'edited');
      },
    );

    test(
      'keeps another message being edited when a queued save starts',
      () async {
        final firstRequest = Completer<void>();
        var callCount = 0;
        when(
          () =>
              mockRepository.editMessage(any(), content: any(named: 'content')),
        ).thenAnswer((_) {
          callCount++;
          if (callCount == 1) return firstRequest.future;
          return Future.value();
        });

        notifier.messages = [
          {'id': 'm1', 'content': 'hello', 'user_id': 'u1'},
          {'id': 'm2', 'content': 'other', 'user_id': 'u1'},
        ];

        notifier.startEditing('m1');
        final first = notifier.saveEdit('m1', 'edited1');
        notifier.startEditing('m2');
        final second = notifier.saveEdit('m1', 'edited1b');

        firstRequest.complete();
        await first;
        await second;

        expect(notifier.editingMessageId, 'm2');
        expect(notifier.messages.first['content'], 'edited1b');
      },
    );

    test('reverts when two overlapping edits both fail', () async {
      when(
        () => mockRepository.editMessage(any(), content: any(named: 'content')),
      ).thenThrow(Exception('network error'));

      notifier.startEditing('m1');
      final first = notifier.saveEdit('m1', 'edited1');
      notifier.startEditing('m1');
      final second = notifier.saveEdit('m1', 'edited2');

      await first;
      await second;

      expect(notifier.messages.single['content'], 'hello');
    });
  });
}

void _deleteTests() {
  group('ChatHistoryNotifier.deleteMessage', () {
    late MockDmRepository mockRepository;
    late ProviderContainer container;
    late ChatHistoryNotifier notifier;

    setUp(() async {
      mockRepository = MockDmRepository();
      when(
        () => mockRepository.getMessages(any(), page: any(named: 'page')),
      ).thenAnswer(
        (_) async => [
          {'id': 'm1', 'content': 'hello', 'user_id': 'u1'},
          {'id': 'm2', 'content': 'again', 'user_id': 'u1'},
        ],
      );
      container = ProviderContainer(
        overrides: [dmRepositoryProvider.overrideWithValue(mockRepository)],
      );
      notifier = container.read(chatHistoryProvider('ch-1'));
      await pumpEventQueue();
    });

    tearDown(() => container.dispose());

    test('removes the message and calls the delete endpoint', () async {
      when(
        () => mockRepository.deleteMessage(
          threadId: any(named: 'threadId'),
          channelId: any(named: 'channelId'),
        ),
      ).thenAnswer((_) async {});

      await notifier.deleteMessage('m1');

      expect(notifier.messages.map((m) => m['id']), ['m2']);
      verify(
        () => mockRepository.deleteMessage(threadId: 'm1', channelId: 'ch-1'),
      ).called(1);
    });

    test('does not bring a deleted message back when polling', () async {
      when(
        () => mockRepository.deleteMessage(
          threadId: any(named: 'threadId'),
          channelId: any(named: 'channelId'),
        ),
      ).thenAnswer((_) async {});

      await notifier.deleteMessage('m1');
      await notifier.loadMore();

      expect(notifier.messages.map((m) => m['id']), isNot(contains('m1')));
    });

    test('puts the message back when the request fails', () async {
      when(
        () => mockRepository.deleteMessage(
          threadId: any(named: 'threadId'),
          channelId: any(named: 'channelId'),
        ),
      ).thenThrow(Exception('network error'));

      await notifier.deleteMessage('m1');

      expect(notifier.messages.map((m) => m['id']), ['m1', 'm2']);
    });
  });
}
