import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

TeamMember _member({required String id, String? name, String email = ''}) {
  return TeamMember(
    id: id,
    email: email,
    role: 'member',
    dateJoined: '2026-11-01',
    status: TeamMemberStatus.active,
    name: name,
  );
}

Future<void> _pumpWithMembers(WidgetTester tester, List<TeamMember> members) {
  return tester.pumpWidget(
    buildTestMaterialApp(
      Scaffold(
        body: GroupDetailsPanel(
          group: GroupDM(id: 'group-1', name: 'Design', members: members),
          onClose: () {},
          onRename: (_) {},
          onLeave: () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('member avatars never crash on empty or padded names', (
    tester,
  ) async {
    await _pumpWithMembers(tester, [
      _member(id: 'a', name: '', email: 'mo@zedu.chat'),
      _member(id: 'b', name: ' john'),
      _member(id: 'c', name: '   ', email: '  '),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('M'), findsOneWidget);
    expect(find.text('J'), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('a member with an empty name is labelled with their email', (
    tester,
  ) async {
    await _pumpWithMembers(tester, [
      _member(id: 'a', name: '', email: 'mo@zedu.chat'),
      _member(id: 'b', name: '   ', email: '  '),
    ]);

    expect(find.text('mo@zedu.chat'), findsOneWidget);
    expect(find.text('Unknown member'), findsOneWidget);
  });

  Future<void> pumpGroup(WidgetTester tester, GroupDM group) {
    // Same widget tree each time, so the panel's State is kept and
    // didUpdateWidget runs, as when the panel stays open.
    return tester.pumpWidget(
      buildTestMaterialApp(
        Scaffold(
          body: GroupDetailsPanel(
            group: group,
            onClose: () {},
            onRename: (_) {},
            onLeave: () {},
          ),
        ),
      ),
    );
  }

  String fieldText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  testWidgets('the name field follows a rename made while the panel is open', (
    tester,
  ) async {
    await pumpGroup(
      tester,
      const GroupDM(id: 'g1', name: 'Design', members: []),
    );
    await pumpGroup(
      tester,
      const GroupDM(id: 'g1', name: 'Design team', members: []),
    );

    expect(find.text('Design team'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();

    expect(fieldText(tester), 'Design team');
  });

  testWidgets('switching to another group closes the name editor', (
    tester,
  ) async {
    await pumpGroup(
      tester,
      const GroupDM(id: 'g1', name: 'Design', members: []),
    );
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Half typed');

    await pumpGroup(
      tester,
      const GroupDM(id: 'g2', name: 'Marketing', members: []),
    );

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Marketing'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();

    expect(fieldText(tester), 'Marketing');
  });

  testWidgets('a rename elsewhere does not wipe a name being typed', (
    tester,
  ) async {
    await pumpGroup(
      tester,
      const GroupDM(id: 'g1', name: 'Design', members: []),
    );
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'My new name');

    await pumpGroup(
      tester,
      const GroupDM(id: 'g1', name: 'Design team', members: []),
    );

    expect(fieldText(tester), 'My new name');
  });

  Future<void> pumpPanel(WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestMaterialApp(
        Scaffold(
          body: GroupDetailsPanel(
            group: const GroupDM(id: 'group-1', name: 'Team', members: []),
            onClose: () {},
            onRename: (_) {},
            onLeave: () {},
          ),
        ),
      ),
    );
  }

  Finder buttonWith(IconData icon) =>
      find.ancestor(of: find.byIcon(icon), matching: find.byType(IconButton));

  String? tooltipOf(WidgetTester tester, IconData icon) =>
      tester.widget<IconButton>(buttonWith(icon)).tooltip;

  /// What a screen reader announces for the button.
  String semanticNameOf(WidgetTester tester, IconData icon) =>
      tester.getSemantics(buttonWith(icon)).getSemanticsData().tooltip;

  testWidgets('the close and edit buttons have tooltips', (tester) async {
    await pumpPanel(tester);

    expect(tooltipOf(tester, Icons.close), 'Close group details');
    expect(tooltipOf(tester, Icons.edit), 'Edit group name');
  });

  testWidgets('the save button has a tooltip while editing the name', (
    tester,
  ) async {
    await pumpPanel(tester);

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();

    expect(tooltipOf(tester, Icons.check), 'Save group name');
  });

  testWidgets('a screen reader gets a distinct name for each button', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpPanel(tester);

    expect(semanticNameOf(tester, Icons.close), 'Close group details');
    expect(semanticNameOf(tester, Icons.edit), 'Edit group name');

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();

    expect(semanticNameOf(tester, Icons.check), 'Save group name');
    semantics.dispose();
  });
}
