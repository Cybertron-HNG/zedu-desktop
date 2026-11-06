import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class MockDmRepository extends Mock implements DmRepository {}

class _FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState(
    selectedWorkspace: Workspace(id: 'org-1', name: 'Org', avatar: ''),
  );
}

DmConversation _conversation(String id) => DmConversation(
  channelId: id,
  username: 'User $id',
  participantId: 'user-$id',
  previewMessage: 'Message $id',
  unreadCount: 0,
);

void main() {
  group('DmListNotifier.loadMore', () {
    late MockDmRepository repository;
    late ProviderContainer container;
    late DmListNotifier notifier;
    late List<DmConversation> firstPage;

    setUp(() async {
      repository = MockDmRepository();
      firstPage = List.generate(
        DmRepository.pageSize,
        (index) => _conversation('first-$index'),
      );
      var page2Calls = 0;

      when(
        () => repository.getConversations(orgId: 'org-1', page: 1),
      ).thenAnswer((_) async => firstPage);
      when(
        () => repository.getConversations(orgId: 'org-1', page: 2),
      ).thenAnswer((_) async {
        page2Calls++;
        if (page2Calls == 1) throw Exception('network down');
        return [_conversation('second-0')];
      });

      container = ProviderContainer(
        overrides: [
          dmRepositoryProvider.overrideWithValue(repository),
          workspaceProvider.overrideWith(_FakeWorkspaceNotifier.new),
        ],
      );
      notifier = container.read(dmListProvider.notifier);
      await pumpEventQueue();
    });

    tearDown(() => container.dispose());

    test('retries the same page after a failed load', () async {
      expect(notifier.state.value, hasLength(DmRepository.pageSize));

      await expectLater(notifier.loadMore(), throwsException);
      expect(notifier.state.value, hasLength(DmRepository.pageSize));

      await notifier.loadMore();

      expect(notifier.state.value, hasLength(DmRepository.pageSize + 1));
      verify(
        () => repository.getConversations(orgId: 'org-1', page: 2),
      ).called(2);
      verifyNever(
        () => repository.getConversations(orgId: 'org-1', page: 3),
      );
    });
  });
}
