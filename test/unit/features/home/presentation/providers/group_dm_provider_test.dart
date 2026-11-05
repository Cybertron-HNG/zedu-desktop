import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockChatWebsocketService extends Mock implements ChatWebsocketService {}

class MockGroupDmRepository extends Mock implements GroupDmRepository {}

class MockChatStorageService extends Mock implements ChatStorageService {}

void main() {
  const member1 = TeamMember(
    id: 'm1',
    email: 'test@example.com',
    role: 'member',
    dateJoined: '2026-01-01',
    status: TeamMemberStatus.active,
    name: 'Ada',
  );

  const member2 = TeamMember(
    id: 'm2',
    email: 'test2@example.com',
    role: 'member',
    dateJoined: '2026-01-01',
    status: TeamMemberStatus.active,
    name: 'Bola',
  );

  late MockChatWebsocketService mockWs;
  late StreamController<ChatWebsocketMessage> wsController;
  late MockGroupDmRepository repository;
  late MockChatStorageService storage;
  late ProviderContainer container;
  var serverGroups = <GroupDM>[];
  var nextId = 0;

  ProviderContainer makeContainer({String orgId = 'org-1'}) {
    return ProviderContainer(
      overrides: [
        chatWebsocketProvider.overrideWithValue(mockWs),
        groupDmRepositoryProvider.overrideWithValue(repository),
        chatStorageProvider.overrideWithValue(storage),
        currentOrgIdProvider.overrideWithValue(orgId),
        groupDmUserIdProvider.overrideWithValue('me'),
      ],
    );
  }

  setUp(() {
    mockWs = MockChatWebsocketService();
    wsController = StreamController<ChatWebsocketMessage>.broadcast();
    when(() => mockWs.messageStream).thenAnswer((_) => wsController.stream);
    when(() => mockWs.connect(any())).thenReturn(null);

    serverGroups = [];
    nextId = 0;
    repository = MockGroupDmRepository();
    when(
      () => repository.list(
        orgId: any(named: 'orgId'),
        currentUserId: any(named: 'currentUserId'),
      ),
    ).thenAnswer((_) async => List.of(serverGroups));
    when(
      () => repository.create(
        orgId: any(named: 'orgId'),
        memberIds: any(named: 'memberIds'),
        currentUserId: any(named: 'currentUserId'),
      ),
    ).thenAnswer((invocation) async {
      final ids = invocation.namedArguments[#memberIds] as List<String>;
      final members = [member1, member2].where((m) => ids.contains(m.id));
      final group = GroupDM(
        id: 'server-${nextId++}',
        name: groupDmName(members.toList()),
        members: members.toList(),
      );
      serverGroups.add(group);
      return group;
    });
    when(() => repository.sendMessage(any(), any())).thenAnswer((_) async {});

    storage = MockChatStorageService();
    when(() => storage.appendMessage(any(), any())).thenAnswer((_) async {});

    container = makeContainer();
  });

  tearDown(() {
    container.dispose();
    wsController.close();
  });

  group('GroupDmNotifier on the server (#2315)', () {
    test('creating a group calls the server and uses its group id', () async {
      container.read(groupDmProvider);
      final result = await container
          .read(groupDmProvider.notifier)
          .createGroupDm([member1, member2]);

      expect(result, isA<Success<GroupDM>>());
      final group = (result as Success<GroupDM>).value;
      expect(group.id, 'server-0');
      expect(group.name, 'Ada, Bola');
      verify(
        () => repository.create(
          orgId: 'org-1',
          memberIds: ['m1', 'm2'],
          currentUserId: 'me',
        ),
      ).called(1);
      expect(container.read(groupDmProvider).map((g) => g.id), ['server-0']);
    });

    test(
      'a failed create returns the error and adds no group to the list',
      () async {
        when(
          () => repository.create(
            orgId: any(named: 'orgId'),
            memberIds: any(named: 'memberIds'),
            currentUserId: any(named: 'currentUserId'),
          ),
        ).thenThrow(
          const ApiFailure(
            message: 'Validation failed',
            kind: ApiFailureKind.client,
          ),
        );
        container.read(groupDmProvider);

        final result = await container
            .read(groupDmProvider.notifier)
            .createGroupDm([member1, member2]);

        expect(result, isA<Failure<GroupDM>>());
        expect(
          (result as Failure<GroupDM>).error.friendlyMessage,
          'Validation failed',
        );
        expect(container.read(groupDmProvider), isEmpty);
      },
    );

    test('without a workspace nothing is sent to the server', () async {
      container.dispose();
      container = makeContainer(orgId: '');
      container.read(groupDmProvider);

      final result = await container
          .read(groupDmProvider.notifier)
          .createGroupDm([member1, member2]);

      expect(result, isA<Failure<GroupDM>>());
      verifyNever(
        () => repository.create(
          orgId: any(named: 'orgId'),
          memberIds: any(named: 'memberIds'),
          currentUserId: any(named: 'currentUserId'),
        ),
      );
      verifyNever(
        () => repository.list(
          orgId: any(named: 'orgId'),
          currentUserId: any(named: 'currentUserId'),
        ),
      );
    });

    test('groups load from the server again after a restart', () async {
      container.read(groupDmProvider);
      await container.read(groupDmProvider.notifier).createGroupDm([
        member1,
        member2,
      ]);

      // A new container is a fresh app start: nothing is kept in memory.
      container.dispose();
      clearInteractions(mockWs);
      container = makeContainer();
      expect(container.read(groupDmProvider), isEmpty);
      await Future<void>.delayed(Duration.zero);

      final groups = container.read(groupDmProvider);
      expect(groups.map((g) => g.id), ['server-0']);
      expect(groups.single.name, 'Ada, Bola');
      verify(() => mockWs.connect(['server-0'])).called(1);
    });

    test('a failed list load is reported and a retry clears it', () async {
      container.dispose();
      when(
        () => repository.list(
          orgId: any(named: 'orgId'),
          currentUserId: any(named: 'currentUserId'),
        ),
      ).thenThrow(const ApiFailure(message: 'Server unavailable'));
      container = makeContainer();
      container.read(groupDmProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(groupDmLoadFailedProvider), isTrue);
      expect(container.read(groupDmProvider), isEmpty);

      serverGroups.add(
        GroupDM(id: 'g-9', name: 'Ada, Bola', members: [member1, member2]),
      );
      when(
        () => repository.list(
          orgId: any(named: 'orgId'),
          currentUserId: any(named: 'currentUserId'),
        ),
      ).thenAnswer((_) async => List.of(serverGroups));
      await container.read(groupDmProvider.notifier).retryLoad();

      expect(container.read(groupDmLoadFailedProvider), isFalse);
      expect(container.read(groupDmProvider).map((g) => g.id), ['g-9']);
    });

    test('picking the same members again opens the existing group', () async {
      container.read(groupDmProvider);
      final notifier = container.read(groupDmProvider.notifier);
      await notifier.createGroupDm([member1, member2]);

      final again = await notifier.createGroupDm([member2, member1]);

      expect((again as Success<GroupDM>).value.id, 'server-0');
      verify(
        () => repository.create(
          orgId: any(named: 'orgId'),
          memberIds: any(named: 'memberIds'),
          currentUserId: any(named: 'currentUserId'),
        ),
      ).called(1);
    });

    test('sending a message posts it to the group on the server', () async {
      container.read(groupDmProvider);
      await container.read(groupDmProvider.notifier).createGroupDm([
        member1,
        member2,
      ]);

      await container
          .read(groupDmProvider.notifier)
          .sendMessage('server-0', 'Hello team');

      verify(() => repository.sendMessage('server-0', 'Hello team')).called(1);
      expect(
        container.read(groupDmProvider).single.messages,
        contains('Hello team'),
      );
    });

    test('a message the server rejects is marked as not sent', () async {
      when(
        () => repository.sendMessage(any(), any()),
      ).thenThrow(const ApiFailure(message: 'boom'));
      container.read(groupDmProvider);
      await container.read(groupDmProvider.notifier).createGroupDm([
        member1,
        member2,
      ]);

      await container
          .read(groupDmProvider.notifier)
          .sendMessage('server-0', 'Hello team');

      expect(
        container.read(groupDmProvider).single.messages,
        contains('Hello team (Not sent)'),
      );
      verifyNever(() => storage.appendMessage(any(), any()));
    });
  });

  group('GroupDmNotifier websocket lifecycle and subscription cleanup', () {
    test(
      'initializes with empty state and listens to message stream',
      () async {
        final initial = container.read(groupDmProvider);
        expect(initial, isEmpty);

        final result = await container
            .read(groupDmProvider.notifier)
            .createGroupDm([member1]);
        expect(result, isA<Success<GroupDM>>());
        final groupId = (result as Success<GroupDM>).value.id;

        wsController.add(
          ChatWebsocketMessage(
            groupDmId: groupId,
            text: 'Hello from websocket',
            authorName: 'Test Author',
            timestamp: DateTime.now(),
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        final groups = container.read(groupDmProvider);
        expect(groups.length, 1);
        expect(groups.first.messages, contains('Hello from websocket'));
        expect(groups.first.unreadCount, 1);
      },
    );

    test(
      'cancels websocket subscription when provider container is disposed',
      () async {
        container.read(groupDmProvider);
        container.dispose();

        // Emitting after disposal must not throw StateError.
        expect(
          () => wsController.add(
            ChatWebsocketMessage(
              groupDmId: 'g1',
              text: 'Message after dispose',
              authorName: 'Test Author',
              timestamp: DateTime.now(),
            ),
          ),
          returnsNormally,
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
    );

    test(
      'rebuilding notifier does not create duplicate subscriptions',
      () async {
        await container.read(groupDmProvider.notifier).createGroupDm([member1]);

        container.invalidate(groupDmProvider);
        container.read(groupDmProvider);
        await Future<void>.delayed(Duration.zero);

        final newResult = await container
            .read(groupDmProvider.notifier)
            .createGroupDm([member2]);
        final newGroupId = (newResult as Success<GroupDM>).value.id;

        wsController.add(
          ChatWebsocketMessage(
            groupDmId: newGroupId,
            text: 'Single event test',
            authorName: 'Test Author',
            timestamp: DateTime.now(),
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));

        final groups = container.read(groupDmProvider);
        final group = groups.firstWhere((g) => g.id == newGroupId);
        expect(group.messages.where((m) => m == 'Single event test').length, 1);
        expect(group.unreadCount, 1);
      },
    );
  });
}
