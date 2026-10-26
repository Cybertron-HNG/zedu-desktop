import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

void main() {
  group('EditProfileDialog', () {
    testWidgets('close button has Close tooltip and dismisses dialog on tap', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: buildTestMaterialApp(
            Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showEditProfileDialog(
                    context,
                    ProfileAccount.empty(),
                    (_) {},
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify dialog is opened
      expect(find.text('Edit your profile'), findsOneWidget);

      // Verify close IconButton has tooltip: 'Close'
      final closeButtonFinder = find.byTooltip('Close');
      expect(closeButtonFinder, findsOneWidget);
      expect(
        find.descendant(
          of: closeButtonFinder,
          matching: find.byIcon(Icons.close),
        ),
        findsOneWidget,
      );

      // Tap close button and verify dialog dismisses
      await tester.tap(closeButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Edit your profile'), findsNothing);
    });
  });
}
