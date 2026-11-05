import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class MockDmRepository extends Mock implements DmRepository {}

class _FakePeopleRepository implements PeopleRepository {
  final requests = <(int, String)>[];
  bool failPage2 = false;

  /// When set, answers every request (by org and page) instead.
  Future<Result<MembersPage>> Function(String orgId, int page)? answer;

  @override
  Future<Result<MembersPage>> fetchMembers({
    required String orgId,
    int page = 1,
    String search = '',
  }) async {
    requests.add((page, search));
    if (answer case final answer?) return answer(orgId, page);
    if (page == 2 && failPage2) {
      return const Failure(ApiFailure(message: 'offline'));
    }
    return Success(
      MembersPage(
        members: page == 1
            ? const [
                OrgMember(id: 'u-1', name: 'Ada'),
                OrgMember(id: 'u-2', name: 'Grace'),
              ]
            // u-2 again: pages can overlap when someone joins meanwhile.
            : const [
                OrgMember(id: 'u-2', name: 'Grace'),
                OrgMember(id: 'u-3', name: 'Linus'),
              ],
        currentPage: page,
        totalPages: 2,
        totalItems: 3,
      ),
    );
  }
}

class _OrgId extends Notifier<String> {
  @override
  String build() => 'org-a';

  void select(String id) => state = id;
}

final _orgId = NotifierProvider<_OrgId, String>(_OrgId.new);

MembersPage _page(String orgId, int page, {int totalPages = 2}) => MembersPage(
  members: [OrgMember(id: '$orgId-$page', name: '$orgId member $page')],
  currentPage: page,
  totalPages: totalPages,
  totalItems: totalPages,
);

void main() {
  late _FakePeopleRepository people;
  late MockDmRepository dms;
  late ProviderContainer container;

  setUp(() {
    people = _FakePeopleRepository();
    dms = MockDmRepository();
    container = ProviderContainer(
      overrides: [
        currentOrgIdProvider.overrideWithValue('org-1'),
        peopleRepositoryProvider.overrideWithValue(people),
        dmRepositoryProvider.overrideWithValue(dms),
      ],
    );
    addTearDown(container.dispose);
  });

  group('PeopleListNotifier', () {
    test('loads the first page for its search', () async {
      final sub = container.listen(peopleListProvider('ada'), (_, _) {});
      addTearDown(sub.close);

      final list = await container.read(peopleListProvider('ada').future);

      expect(people.requests, [(1, 'ada')]);
      expect(list.members.map((m) => m.id), ['u-1', 'u-2']);
      expect(list.hasMore, isTrue);
      expect(list.total, 3);
    });

    test('load more adds the next page without duplicates', () async {
      final sub = container.listen(peopleListProvider(''), (_, _) {});
      addTearDown(sub.close);
      await container.read(peopleListProvider('').future);

      await container.read(peopleListProvider('').notifier).loadMore();

      final list = container.read(peopleListProvider('')).value!;
      expect(list.members.map((m) => m.id), ['u-1', 'u-2', 'u-3']);
      expect(list.hasMore, isFalse);

      // Nothing more to load.
      await container.read(peopleListProvider('').notifier).loadMore();
      expect(people.requests, [(1, ''), (2, '')]);
    });

    test('a failed load more keeps the members and can retry', () async {
      people.failPage2 = true;
      final sub = container.listen(peopleListProvider(''), (_, _) {});
      addTearDown(sub.close);
      await container.read(peopleListProvider('').future);

      await container.read(peopleListProvider('').notifier).loadMore();

      final list = container.read(peopleListProvider('')).value!;
      expect(list.members, hasLength(2));
      expect(list.loadMoreFailed, isTrue);
      expect(list.hasMore, isTrue);
    });
  });

  group('PeopleListNotifier after a workspace switch (Ziki #2718)', () {
    late ProviderContainer switching;
    late Completer<Result<MembersPage>> orgAPage2;

    setUp(() {
      orgAPage2 = Completer();
      people.answer = (orgId, page) => orgId == 'org-a' && page == 2
          ? orgAPage2.future
          : Future.value(Success(_page(orgId, page)));
      switching = ProviderContainer(
        overrides: [
          currentOrgIdProvider.overrideWith((ref) => ref.watch(_orgId)),
          peopleRepositoryProvider.overrideWithValue(people),
        ],
      );
      addTearDown(switching.dispose);
    });

    Future<List<String>> switchDuringLoadMore() async {
      final sub = switching.listen(peopleListProvider(''), (_, _) {});
      addTearDown(sub.close);
      await switching.read(peopleListProvider('').future);

      // Page 2 of the old workspace is still in flight when it switches.
      unawaited(switching.read(peopleListProvider('').notifier).loadMore());
      switching.read(_orgId.notifier).select('org-b');
      final afterSwitch = await switching.read(peopleListProvider('').future);
      expect(afterSwitch.members.map((m) => m.id), ['org-b-1']);
      return [for (final m in afterSwitch.members) m.id];
    }

    test('a late page from the old workspace is dropped', () async {
      await switchDuringLoadMore();
      orgAPage2.complete(Success(_page('org-a', 2)));
      await pumpEventQueue();

      final list = switching.read(peopleListProvider('')).value!;
      expect(list.members.map((m) => m.id), ['org-b-1']);
      expect(list.isLoadingMore, isFalse);
    });

    test('a late failure from the old workspace is dropped', () async {
      await switchDuringLoadMore();
      orgAPage2.complete(const Failure(ApiFailure(message: 'offline')));
      await pumpEventQueue();

      final list = switching.read(peopleListProvider('')).value!;
      expect(list.members.map((m) => m.id), ['org-b-1']);
      expect(list.loadMoreFailed, isFalse);
    });

    test('Load more in the new workspace pages from it', () async {
      await switchDuringLoadMore();
      orgAPage2.complete(Success(_page('org-a', 2)));
      await pumpEventQueue();

      await switching.read(peopleListProvider('').notifier).loadMore();

      final list = switching.read(peopleListProvider('')).value!;
      expect(list.members.map((m) => m.id), ['org-b-1', 'org-b-2']);
    });
  });

  group('PeopleActionsNotifier.openChat', () {
    const ada = OrgMember(id: 'u-1', name: 'Ada', email: 'ada@zedu.test');

    test('opens the DM and shows it in the DMs tab', () async {
      when(
        () => dms.openConversation(orgId: 'org-1', participantId: 'u-1'),
      ).thenAnswer((_) async => (channelId: 'c-1', participantId: 'u-1'));

      final opened = await container
          .read(peopleActionsProvider.notifier)
          .openChat(ada);

      expect(opened, isTrue);
      final dm = container.read(selectedDmProvider)!;
      expect(dm.channelId, 'c-1');
      expect(dm.displayName, 'Ada');
      expect(dm.participantEmail, 'ada@zedu.test');
      expect(container.read(homeSidebarProvider), HomeSidebarType.dms);
      expect(container.read(peopleActionsProvider), isNull);
    });

    test('reports a failure and stays on People', () async {
      when(
        () => dms.openConversation(orgId: 'org-1', participantId: 'u-1'),
      ).thenThrow(const ApiFailure(message: 'offline'));
      container
          .read(homeSidebarProvider.notifier)
          .setType(HomeSidebarType.people);

      final opened = await container
          .read(peopleActionsProvider.notifier)
          .openChat(ada);

      expect(opened, isFalse);
      expect(container.read(selectedDmProvider), isNull);
      expect(container.read(homeSidebarProvider), HomeSidebarType.people);
      expect(container.read(peopleActionsProvider), isNull);
    });
  });
}
