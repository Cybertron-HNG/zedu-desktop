import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

void main() {
  const account = ProfileAccount(
    name: 'Ada Lovelace',
    email: 'ada@zedu.test',
    timezone: 'Africa/Lagos',
  );

  /// Opens Edit Account for [start] and returns what Save sends, if anything.
  Future<List<ProfileAccount>> openDialog(
    WidgetTester tester, {
    ProfileAccount start = account,
  }) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final saved = <ProfileAccount>[];
    await tester.pumpWidget(
      buildTestMaterialApp(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showEditAccountDialog(context, start, saved.add),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return saved;
  }

  testWidgets('Timezone is a list of zones, not free text (#2923)', (
    tester,
  ) async {
    await openDialog(tester);

    // Name and email are the only text fields; the timezone is a dropdown.
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.text('(UTC+01:00) West Central Africa'), findsOneWidget);
  });

  testWidgets('saves the IANA id of the zone that was picked', (tester) async {
    final saved = await openDialog(tester);

    await tester.tap(find.text('(UTC+01:00) West Central Africa'));
    await tester.pumpAndSettle();
    // A zone near the current one, so the open list has built its row.
    await tester.tap(find.text('(UTC+02:00) Cairo, Helsinki, Bucharest').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(saved.single.timezone, 'Africa/Cairo');
  });

  testWidgets('a label saved by older builds opens as its zone', (
    tester,
  ) async {
    final saved = await openDialog(
      tester,
      start: account.copyWith(timezone: '(UTC+09:00) Tokyo, Seoul, Osaka'),
    );

    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(saved.single.timezone, 'Asia/Tokyo');
  });

  testWidgets('saving closes the dialog cleanly', (tester) async {
    await openDialog(tester);

    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    // On main this threw "A TextEditingController was used after being
    // disposed" during the close animation.
    expect(tester.takeException(), isNull);
    expect(find.text('Edit Account'), findsNothing);
  });
}
