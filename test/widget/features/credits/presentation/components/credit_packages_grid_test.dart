import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

Future<List<FilledButton>> _buttons(
  WidgetTester tester, {
  String? purchasingPackageId,
}) async {
  tester.view.physicalSize = const Size(2400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    buildTestMaterialApp(
      Scaffold(
        body: SingleChildScrollView(
          child: CreditPackagesGrid(
            packages: const [],
            currentPlanSlug: 'free',
            purchasingPackageId: purchasingPackageId,
            onPurchase: (_) {},
          ),
        ),
      ),
    ),
  );
  return tester.widgetList<FilledButton>(find.byType(FilledButton)).toList();
}

void main() {
  testWidgets('paid plans can be bought when nothing is pending', (
    tester,
  ) async {
    final buttons = await _buttons(tester);

    expect(buttons.where((b) => b.onPressed != null), isNotEmpty);
  });

  testWidgets('every plan is disabled while a purchase is pending', (
    tester,
  ) async {
    final buttons = await _buttons(tester, purchasingPackageId: 'pro');

    expect(buttons, isNotEmpty);
    expect(buttons.where((b) => b.onPressed != null), isEmpty);
  });
}
