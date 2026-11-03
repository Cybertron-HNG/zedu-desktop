import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: kIsWeb ? 'Zedu | Team Messaging & Collaboration' : 'Zedu',
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
      builder: (context, child) => DesktopWindowTitleListener(
        child: CreditsPaymentDeepLinkListener(
          child: AuthDeepLinkListener(
            child: SessionExpiryListener(
              child: QuickSwitcherShortcut(
                child: isDesktopApp
                    // Close-to-tray, the tray menu and desktop notifications.
                    ? DesktopManager(child: child ?? const SizedBox.shrink())
                    : child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
