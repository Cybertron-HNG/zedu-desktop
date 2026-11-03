import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../../helpers/helpers.dart';

Widget buildUnderTest(List<TeamMember> members) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
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

List<TeamMember> createMembers(int count) {
  return List.generate(
    count,
    (i) => TeamMember(
      id: '$i',
      email: 'member$i@example.com',
      name: 'Member $i',
      role: i % 2 == 0 ? 'User' : 'Administrator',
      dateJoined: 'Oct 1, 2026',
      status: TeamMemberStatus.active,
    ),
  );
}

void main() {
  group('UserManagementSection Invites tab navigation (#205 / Ziki #204)', () {
    testWidgets(
      'clicking Invites tab switches to invites view with empty state',
      (tester) async {
        await tester.pumpWidget(buildUnderTest(createMembers(3)));
        await tester.pumpAndSettle();

        expect(find.text('member0@example.com'), findsOneWidget);
        expect(find.text('No pending invitations'), findsNothing);

        // Tap Invites tab
        await tester.tap(find.text('Invites'));
        await tester.pumpAndSettle();

        expect(find.text('No pending invitations'), findsOneWidget);
        expect(find.text('member0@example.com'), findsNothing);

        // Tap Members tab to switch back
        await tester.tap(find.text('Members'));
        await tester.pumpAndSettle();

        expect(find.text('member0@example.com'), findsOneWidget);
        expect(find.text('No pending invitations'), findsNothing);
      },
    );

    testWidgets('renders pending invitations in invites tab when present', (
      tester,
    ) async {
      final membersWithPending = [
        const TeamMember(
          id: '1',
          email: 'active@example.com',
          name: 'Active User',
          role: 'Administrator',
          dateJoined: 'Oct 1, 2026',
          status: TeamMemberStatus.active,
        ),
        const TeamMember(
          id: '2',
          email: 'invited@example.com',
          name: 'Invited User',
          role: 'User',
          dateJoined: 'Oct 2, 2026',
          status: TeamMemberStatus.pending,
        ),
      ];

      await tester.pumpWidget(buildUnderTest(membersWithPending));
      await tester.pumpAndSettle();

      // Invites badge should show '1'
      expect(find.text('Invites'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Switch to Invites
      await tester.tap(find.text('Invites'));
      await tester.pumpAndSettle();

      // Should show invited user in the table, not empty state
      expect(find.text('No pending invitations'), findsNothing);
      expect(find.text('invited@example.com'), findsOneWidget);
      expect(find.text('Date Invited'), findsOneWidget);
    });
  });
}
