import 'dart:async';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final updateCheckServiceProvider = Provider<UpdateCheckService>(
  (ref) => UpdateCheckService(),
);

/// The newer release, if there is one. Checked when the app starts and again
/// once a day. Null when up to date or when the check fails.
final appUpdateProvider = FutureProvider<AppUpdate?>((ref) async {
  final timer = Timer(const Duration(days: 1), ref.invalidateSelf);
  ref.onDispose(timer.cancel);

  final info = await PackageInfo.fromPlatform();
  return ref.read(updateCheckServiceProvider).latestIfNewer(info.version);
});

/// The version whose banner was dismissed, so it stays hidden until the next
/// release, including after the app is restarted.
class DismissedUpdateNotifier extends Notifier<String?> {
  static const storageKey = 'dismissed_update_version';

  @override
  String? build() {
    _restore();
    return null;
  }

  Future<void> _restore() async {
    try {
      final saved = await locator<SecureStorageService>().readData(storageKey);
      if (saved != null && state == null) state = saved;
    } catch (_) {
      // Nothing saved or storage unavailable: the banner just shows again.
    }
  }

  void dismiss(String version) {
    state = version;
    _save(version);
  }

  Future<void> _save(String version) async {
    try {
      await locator<SecureStorageService>().writeData(storageKey, version);
    } catch (_) {}
  }
}

final dismissedUpdateProvider =
    NotifierProvider<DismissedUpdateNotifier, String?>(
      DismissedUpdateNotifier.new,
    );
