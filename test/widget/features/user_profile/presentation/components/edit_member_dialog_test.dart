import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

TeamMember _member(String role) => TeamMember(
  id: 'm1',
  email: 'lead@example.com',
  role: role,
  dateJoined: '2026-01-01',
  status: TeamMemberStatus.active,
);

/// Opens the dialog for [member] and returns what Save hands back.
Future<List<TeamMember>> _open(WidgetTester tester, TeamMember member) async {
  final saved = <TeamMember>[];
  await tester.pumpWidget(
    buildTestMaterialApp(
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showEditMemberDialog(context, member, saved.add),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return saved;
}

void main() {
  group('Edit Team Member role (Ziki #55)', () {
    testWidgets('opens for a role outside the dropdown options and shows it', (
      tester,
    ) async {
      await _open(tester, _member('Project Lead'));

      expect(tester.takeException(), isNull);
      expect(find.text('Edit Team Member'), findsOneWidget);
      expect(find.text('Project Lead'), findsOneWidget);
    });

    testWidgets('saving without a change keeps the existing role', (
      tester,
    ) async {
      final saved = await _open(tester, _member('Project Lead'));

      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(saved.single.role, 'Project Lead');
    });

    testWidgets('the existing role can be changed to a supported one', (
      tester,
    ) async {
      final saved = await _open(tester, _member('Project Lead'));

      await tester.tap(find.text('Project Lead'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Manager').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(saved.single.role, 'Manager');
    });

    testWidgets('a supported role still opens as before', (tester) async {
      await _open(tester, _member('Manager'));

      expect(tester.takeException(), isNull);
      expect(find.text('Manager'), findsOneWidget);
      expect(find.text('Project Lead'), findsNothing);
    });
  });
}
