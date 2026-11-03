import 'package:zedu/features/features.dart';

import '../../../../../../helpers/helpers.dart';

const _members = [
  TeamMember(
    id: '1',
    email: 'a@z.co',
    role: 'User',
    dateJoined: 'Jan 1',
    status: TeamMemberStatus.active,
  ),
  TeamMember(
    id: '2',
    email: 'b@z.co',
    role: 'User',
    dateJoined: 'Feb 1',
    status: TeamMemberStatus.active,
  ),
];

Future<void> _pumpSection(
  WidgetTester tester, {
  List<TeamMember> members = _members,
}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    buildTestMaterialApp(
      Scaffold(
        body: SingleChildScrollView(
          child: UserManagementSection(
            members: members,
            isSaving: false,
            onInvite: ({required email, required role}) async {},
            onUpdate: (_) {},
            onRemove: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('UserManagementSection empty state', () {
    testWidgets('no placeholder while members match', (tester) async {
      await _pumpSection(tester);

      expect(find.text('a@z.co'), findsOneWidget);
      expect(find.text('No results found'), findsNothing);
    });

    testWidgets('search with no matches shows "No results found"', (
      tester,
    ) async {
      await _pumpSection(tester);

      await tester.enterText(find.byType(TextField), 'nobody');
      await tester.pump();

      expect(find.text('a@z.co'), findsNothing);
      expect(find.text('No results found'), findsOneWidget);
      expect(
        find.text('Try a different search term or role filter.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      expect(find.text('No results found'), findsNothing);
      expect(find.text('a@z.co'), findsOneWidget);
    });

    testWidgets('role filter with no matches shows "No results found"', (
      tester,
    ) async {
      await _pumpSection(tester);

      await tester.tap(find.text('All Roles'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Manager').last);
      await tester.pumpAndSettle();

      expect(find.text('No results found'), findsOneWidget);
    });

    testWidgets('an empty team shows "No team members yet"', (tester) async {
      await _pumpSection(tester, members: const []);

      expect(find.text('No team members yet'), findsOneWidget);
      expect(find.text('No results found'), findsNothing);
    });
  });
}
