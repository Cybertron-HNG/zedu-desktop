import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

void main() {
  Future<(ProviderContainer, GoRouter)> pumpMenu(
    WidgetTester tester, {
    required String start,
  }) async {
    Widget screen(String name) => Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: const [TopUserMenu(userName: 'Ada')],
      ),
    );
    final router = GoRouter(
      initialLocation: start,
      routes: [
        GoRoute(path: AppRouter.home, builder: (_, _) => screen('Home')),
        GoRoute(
          path: AppRouter.profile,
          builder: (_, _) => screen('Preferences'),
        ),
        GoRoute(
          path: AppRouter.buyCredits,
          builder: (_, _) => screen('Buy credits'),
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [orgCreditBalanceProvider.overrideWithValue(5)],
    );
    addTearDown(container.dispose);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return (container, router);
  }

  Future<void> chooseProfile(WidgetTester tester) async {
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
  }

  for (final (start, name) in [
    (AppRouter.profile, 'Preferences'),
    (AppRouter.buyCredits, 'Buy credits'),
  ]) {
    testWidgets('Profile from $name opens Home with the profile panel', (
      tester,
    ) async {
      final (container, router) = await pumpMenu(tester, start: start);
      expect(find.text(name), findsOneWidget);

      await chooseProfile(tester);

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRouter.home,
      );
      expect(container.read(personalProfilePanelProvider), isTrue);
    });
  }

  testWidgets('Profile on Home stays on Home and opens the panel', (
    tester,
  ) async {
    final (container, router) = await pumpMenu(tester, start: AppRouter.home);

    await chooseProfile(tester);

    expect(router.routerDelegate.currentConfiguration.uri.path, AppRouter.home);
    expect(container.read(personalProfilePanelProvider), isTrue);
  });
}
