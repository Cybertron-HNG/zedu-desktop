import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

void main() {
  group('CreditsPurchaseShell', () {
    testWidgets('uses theme background color on Scaffold in light theme', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
            orgCreditBalanceProvider.overrideWithValue(100),
          ],
          child: buildTestMaterialApp(
            const CreditsPurchaseShell(
              child: SizedBox(),
            ),
            theme: AppTheme.light.copyWith(splashFactory: NoSplash.splashFactory),
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final BuildContext context = tester.element(find.byType(CreditsPurchaseShell));
      expect(scaffold.backgroundColor, equals(context.colors.background));
    });

    testWidgets('uses theme background color on Scaffold in dark theme', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
            orgCreditBalanceProvider.overrideWithValue(100),
          ],
          child: buildTestMaterialApp(
            const CreditsPurchaseShell(
              child: SizedBox(),
            ),
            theme: ThemeData.dark().copyWith(splashFactory: NoSplash.splashFactory),
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final BuildContext context = tester.element(find.byType(CreditsPurchaseShell));
      expect(scaffold.backgroundColor, equals(context.colors.background));
    });
  });
}
