import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zedu/features/features.dart';

import '../../../../../../helpers/helpers.dart';

void main() {
  testWidgets('Invite People opens the invite dialog', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: buildTestMaterialApp(
          Scaffold(
            body: SingleChildScrollView(
              child: BillingSection(
                billing: BillingInfo.empty(),
                onInvite: ({required email, required role}) async {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Invite People'));
    await tester.pumpAndSettle();

    expect(find.text('Invite Team Member'), findsOneWidget);
  });

  Future<void> pumpBilling(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: buildTestMaterialApp(
          Scaffold(
            body: SingleChildScrollView(
              child: BillingSection(
                billing: BillingInfo.empty(),
                onInvite: ({required email, required role}) async {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('the billing actions sit below the description when narrow', (
    tester,
  ) async {
    await pumpBilling(tester, 480);

    expect(tester.takeException(), isNull);
    final description = find.textContaining('You are enjoying');
    expect(
      tester.getTopLeft(find.text('Compare plans')).dy,
      greaterThan(tester.getBottomLeft(description).dy),
    );
    expect(
      tester.getTopLeft(find.text('Invite People')).dy,
      greaterThan(tester.getBottomLeft(description).dy),
    );
  });

  testWidgets('the billing actions stay beside the description when wide', (
    tester,
  ) async {
    await pumpBilling(tester, 1200);

    expect(tester.takeException(), isNull);
    final description = find.textContaining('You are enjoying');
    expect(
      tester.getTopLeft(find.text('Compare plans')).dy,
      lessThan(tester.getBottomLeft(description).dy),
    );
  });
}
