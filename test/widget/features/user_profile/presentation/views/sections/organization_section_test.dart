import 'dart:async';

import 'package:zedu/features/features.dart';

import '../../../../../../helpers/helpers.dart';

void main() {
  const organization = OrganizationProfile(
    id: 'org-1',
    name: 'Acme',
    natureOfBusiness: 'Design agency',
    country: 'Nigeria',
  );

  Future<void> pump(
    WidgetTester tester, {
    Future<void> Function()? onLeave,
    Future<void> Function()? onDelete,
  }) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      buildTestMaterialApp(
        Scaffold(
          body: SingleChildScrollView(
            child: OrganizationSection(
              organization: organization,
              onSave: (_) {},
              onLeave: onLeave ?? () async {},
              onDelete: onDelete ?? () async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  OutlinedButton buttonLabelled(WidgetTester tester, String label) =>
      tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(OutlinedButton),
        ),
      );

  testWidgets('neither button spins until its own action runs (#2925)', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      buttonLabelled(tester, 'Sign out of workspace').onPressed,
      isNotNull,
    );
    expect(buttonLabelled(tester, 'Delete organization').onPressed, isNotNull);
  });

  testWidgets('only Sign out spins while signing out, then it stops', (
    tester,
  ) async {
    final leaving = Completer<void>();
    await pump(tester, onLeave: () => leaving.future);

    await tester.tap(find.text('Sign out of workspace'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pump();

    // The Sign out button shows the spinner in place of its label; Delete
    // keeps its label, without a spinner, and can't be pressed meanwhile.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Sign out of workspace'), findsNothing);
    expect(buttonLabelled(tester, 'Delete organization').onPressed, isNull);

    leaving.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(buttonLabelled(tester, 'Delete organization').onPressed, isNotNull);
  });

  testWidgets('only Delete spins while deleting, then it stops', (
    tester,
  ) async {
    final deleting = Completer<void>();
    await pump(tester, onDelete: () => deleting.future);

    await tester.tap(find.text('Delete organization'));
    await tester.pumpAndSettle();
    // The dialog's confirm button has the same label as the section's.
    await tester.tap(find.text('Delete organization').last);
    // Let the dialog finish closing (the spinner never settles).
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // The section's Delete button shows the spinner instead of its label.
    expect(
      find.descendant(
        of: find.byType(OrganizationSection),
        matching: find.text('Delete organization'),
      ),
      findsNothing,
    );
    expect(buttonLabelled(tester, 'Sign out of workspace').onPressed, isNull);

    deleting.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      buttonLabelled(tester, 'Sign out of workspace').onPressed,
      isNotNull,
    );
  });
}
