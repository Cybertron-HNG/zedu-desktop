import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

const _ada = TeamMember(
  id: 'u-1',
  email: 'ada@zedu.test',
  role: 'Admin',
  dateJoined: '2026-01-01',
  status: TeamMemberStatus.active,
  name: 'Ada Lovelace',
);

const _bob = TeamMember(
  id: 'u-2',
  email: 'bob@zedu.test',
  role: 'Member',
  dateJoined: '2026-01-02',
  status: TeamMemberStatus.active,
  name: 'Bob Stone',
);

class _FakeProfileNotifier extends UserProfileNotifier {
  @override
  UserProfileState build() => const UserProfileState(teamMembers: [_ada, _bob]);
}

/// Behaves like [GroupDmNotifier.createGroupDm]: returns the group with the
/// same members if there is one, otherwise adds a new group to the list and
/// returns it.
class _FakeGroupDmNotifier extends GroupDmNotifier {
  _FakeGroupDmNotifier(this._initial);

  final List<GroupDM> _initial;

  @override
  List<GroupDM> build() => _initial;

  @override
  Future<Result<GroupDM>> createGroupDm(List<TeamMember> members) async {
    final ids = members.map((m) => m.id).toSet();
    for (final group in state) {
      final groupIds = group.members.map((m) => m.id).toSet();
      if (groupIds.length == ids.length && groupIds.containsAll(ids)) {
        return Success(group);
      }
    }
    final group = GroupDM(
      id: 'group-new',
      name: 'Ada Lovelace, Bob Stone',
      members: members,
    );
    state = [...state, group];
    return Success(group);
  }
}

void main() {
  // The snackbars' context reads the app config.
  setUp(() {
    if (locator.isRegistered<AppConfig>()) locator.unregister<AppConfig>();
    locator.registerSingleton<AppConfig>(
      const AppConfig(apiBaseUrl: 'http://test', usesMockData: false),
    );
  });

  tearDown(() {
    if (locator.isRegistered<AppConfig>()) locator.unregister<AppConfig>();
  });

  Future<void> createWithAdaAndBob(
    WidgetTester tester, {
    List<GroupDM> existing = const [],
  }) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileNotifierProvider.overrideWith(_FakeProfileNotifier.new),
          groupDmProvider.overrideWith(() => _FakeGroupDmNotifier(existing)),
        ],
        child: buildTestMaterialApp(const Scaffold(body: NewGroupChatView())),
      ),
    );
    await tester.pumpAndSettle();

    for (final name in ['Ada Lovelace', 'Bob Stone']) {
      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(name).first);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
  }

  testWidgets('a brand-new group says it was created (#2929)', (tester) async {
    await createWithAdaAndBob(tester);

    expect(find.textContaining('created successfully'), findsOneWidget);
    expect(find.textContaining('Opening existing conversation'), findsNothing);
  });

  testWidgets('a group that already existed says it is being opened', (
    tester,
  ) async {
    await createWithAdaAndBob(
      tester,
      existing: const [
        GroupDM(id: 'group-old', name: 'Ada and Bob', members: [_ada, _bob]),
      ],
    );

    expect(
      find.text('Opening existing conversation with Ada and Bob...'),
      findsOneWidget,
    );
    expect(find.textContaining('created successfully'), findsNothing);
  });
}
