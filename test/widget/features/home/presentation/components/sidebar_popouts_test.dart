import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class _FakeProfileNotifier extends UserProfileNotifier {
  _FakeProfileNotifier(this.initial);

  final UserProfileState initial;
  int loadCalls = 0;

  @override
  UserProfileState build() => initial;

  @override
  Future<void> load() async => loadCalls++;
}

const _ada = TeamMember(
  id: 'u-1',
  email: 'ada@zedu.test',
  role: 'Admin',
  dateJoined: '2026-01-01',
  status: TeamMemberStatus.active,
  name: 'Ada Lovelace',
);

Future<_FakeProfileNotifier> _pumpPeopleCard(
  WidgetTester tester,
  UserProfileState state,
) async {
  final notifier = _FakeProfileNotifier(state);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [userProfileNotifierProvider.overrideWith(() => notifier)],
      child: buildTestMaterialApp(
        Scaffold(
          body: SidebarPopoutCard(
            HomeSidebarType.people,
            () {},
            () {},
            (_) {},
            (_) {},
          ),
        ),
      ),
    ),
  );
  return notifier;
}

void main() {
  group('People pop-out card', () {
    testWidgets('lists loaded people even when another request failed', (
      tester,
    ) async {
      await _pumpPeopleCard(
        tester,
        const UserProfileState(
          teamMembers: [_ada],
          error: 'Could not load billing info.',
        ),
      );

      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('Could not load billing info.'), findsNothing);
    });

    testWidgets('shows the error when there are no people to list', (
      tester,
    ) async {
      await _pumpPeopleCard(
        tester,
        const UserProfileState(error: 'Could not load billing info.'),
      );

      expect(find.text('Could not load billing info.'), findsOneWidget);
    });

    testWidgets(
      'shows an empty message when there are no people and no error',
      (tester) async {
        await _pumpPeopleCard(tester, const UserProfileState());

        expect(find.text('No people to show'), findsOneWidget);
      },
    );
  });
}
