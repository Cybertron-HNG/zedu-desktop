import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

void main() {
  group('profile_dialogs controller lifecycle during close animation', () {
    testWidgets(
      'showEditAccountDialog can be cancelled and submitted without disposed controller errors',
      (tester) async {
        ProfileAccount? savedAccount;
        const initialAccount = ProfileAccount(
          name: 'Ada Lovelace',
          email: 'ada@zedu.chat',
          timezone: 'Africa/Lagos',
        );

        await tester.pumpWidget(
          buildTestMaterialApp(
            Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showEditAccountDialog(
                      context,
                      initialAccount,
                      (updated) => savedAccount = updated,
                    ),
                    child: const Text('Open Edit Account'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Edit Account'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(TextFormField).first);
        await tester.pump();

        await tester.tap(find.text('Cancel'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(savedAccount, isNull);

        await tester.tap(find.text('Open Edit Account'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'Grace Hopper',
        );
        await tester.pump();

        await tester.tap(find.text('Save changes'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(savedAccount?.name, 'Grace Hopper');
      },
    );

    testWidgets(
      'showChangePasswordDialog can be cancelled and submitted without disposed controller errors',
      (tester) async {
        String? savedCurrent;
        String? savedNew;

        await tester.pumpWidget(
          buildTestMaterialApp(
            Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showChangePasswordDialog(context, ({
                      required currentPassword,
                      required newPassword,
                    }) async {
                      savedCurrent = currentPassword;
                      savedNew = newPassword;
                    }),
                    child: const Text('Open Change Password'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Change Password'));
        await tester.pumpAndSettle();
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'old-secret');
        await tester.pump();

        await tester.tap(find.text('Cancel'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(savedCurrent, isNull);

        await tester.tap(find.text('Open Change Password'));
        await tester.pumpAndSettle();
        await tester.enterText(fields.at(0), 'old-secret');
        await tester.enterText(fields.at(1), 'new-secret-123');
        await tester.enterText(fields.at(2), 'new-secret-123');
        await tester.pump();

        await tester.tap(find.text('Update Password'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(savedCurrent, 'old-secret');
        expect(savedNew, 'new-secret-123');
      },
    );

    testWidgets(
      'showEditOrganizationDialog can be cancelled and submitted without disposed controller errors',
      (tester) async {
        OrganizationProfile? savedOrg;
        const initialOrg = OrganizationProfile(
          id: 'org-1',
          name: 'Cybertron',
          natureOfBusiness: 'Engineering',
          country: 'Nigeria',
        );

        await tester.pumpWidget(
          buildTestMaterialApp(
            Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showEditOrganizationDialog(
                      context,
                      initialOrg,
                      (updated) => savedOrg = updated,
                    ),
                    child: const Text('Open Edit Org'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Edit Org'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(TextFormField).first);
        await tester.pump();

        await tester.tap(find.text('Cancel'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(savedOrg, isNull);

        await tester.tap(find.text('Open Edit Org'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'Cybertron HQ',
        );
        await tester.pump();

        await tester.tap(find.text('Save changes'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(savedOrg?.name, 'Cybertron HQ');
      },
    );

    testWidgets(
      'showInviteMemberDialog can be cancelled and submitted without disposed controller errors',
      (tester) async {
        String? invitedEmail;
        String? invitedRole;

        await tester.pumpWidget(
          buildTestMaterialApp(
            Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showInviteMemberDialog(context, ({
                      required email,
                      required role,
                    }) async {
                      invitedEmail = email;
                      invitedRole = role;
                    }),
                    child: const Text('Open Invite Member'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Invite Member'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'teammate@zedu.chat',
        );
        await tester.pump();

        await tester.tap(find.text('Cancel'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(invitedEmail, isNull);

        await tester.tap(find.text('Open Invite Member'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'teammate@zedu.chat',
        );
        await tester.pump();

        await tester.tap(find.text('Send Invite'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(invitedEmail, 'teammate@zedu.chat');
        expect(invitedRole, 'User');
      },
    );
  });
}
