import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: enforce message deletion time limit (CYBERTRON-032)
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Zedu',
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
      builder: (context, child) => CreditsPaymentDeepLinkListener(
        child: AuthDeepLinkListener(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
