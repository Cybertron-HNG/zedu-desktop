import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class CreditsPaymentDeepLinkListener extends ConsumerStatefulWidget {
  const CreditsPaymentDeepLinkListener({
    super.key,
    required this.child,
    this.appLinks,
  });

  final Widget child;
  final AppLinks? appLinks;

  @override
  ConsumerState<CreditsPaymentDeepLinkListener> createState() =>
      _CreditsPaymentDeepLinkListenerState();
}

class _CreditsPaymentDeepLinkListenerState
    extends ConsumerState<CreditsPaymentDeepLinkListener> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  String? _lastProcessedSessionId;

  /// A payment link that arrived before any workspace was known, as on a
  /// cold start from the link. It is verified once a workspace is.
  String? _pendingSessionId;

  static const _tag = 'CreditsPaymentDeepLinkListener';

  @override
  void initState() {
    super.initState();
    _appLinks = widget.appLinks ?? AppLinks();
    ref.listenManual<String>(creditsOrgIdProvider, (_, orgId) {
      final pending = _pendingSessionId;
      if (pending != null && orgId.isNotEmpty) {
        unawaited(_verifySession(pending));
      }
    });
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleUri(initialUri);
      }
    } catch (error) {
      AppLogger.w('Failed to read initial payment deep link', tag: _tag);
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => unawaited(_handleUri(uri)),
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.w('Payment deep link stream error: $error', tag: _tag);
      },
    );
  }

  Future<void> _handleUri(Uri uri) async {
    final sessionId = CreditsPaymentDeepLinkParser.extractSessionId(uri);
    if (sessionId == null) return;
    await _verifySession(sessionId);
  }

  Future<void> _verifySession(String sessionId) async {
    if (sessionId == _lastProcessedSessionId) return;

    // The purchase was made for the workspace selected in the sidebar.
    final orgId = ref.read(creditsOrgIdProvider);
    if (orgId.isEmpty) {
      // Not signed in yet: keep the link instead of dropping the purchase.
      _pendingSessionId = sessionId;
      return;
    }
    _pendingSessionId = null;
    _lastProcessedSessionId = sessionId;

    AppLogger.i('Verifying credit payment session', tag: _tag);
    final verified = await ref
        .read(creditsNotifierProvider.notifier)
        .verifyPayment(sessionId: sessionId, orgId: orgId);

    if (!mounted) return;

    // Mounted from `App`'s builder, above the Navigator: see the note in
    // AuthDeepLinkListener.
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    if (verified) {
      AppToastService.showAtRoot(
        navigator,
        type: AppToastType.success,
        message: 'AI credits purchased successfully!',
      );
      if (GoRouter.of(
            navigator.context,
          ).routerDelegate.currentConfiguration.uri.path !=
          AppRouter.buyCredits) {
        navigator.context.go(AppRouter.buyCredits);
      }
      return;
    }

    final error = ref.read(creditsNotifierProvider).error;
    if (error != null) {
      AppToastService.showAtRoot(
        navigator,
        type: AppToastType.error,
        message: error,
      );
    }
  }

  @override
  void dispose() {
    unawaited(_linkSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
