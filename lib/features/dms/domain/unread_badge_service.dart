import 'dart:io';

import 'package:zedu/core/core.dart';

/// Sets the number shown on the app icon.
typedef BadgeUpdater = Future<void> Function(int count);

final unreadBadgeServiceProvider = Provider<UnreadBadgeService>((ref) {
  return UnreadBadgeService();
});

/// Mirrors the unread total on the app icon: the Dock badge on macOS.
///
/// The badge package has no Windows or Linux support, so on those platforms
/// [update] does nothing.
class UnreadBadgeService {
  UnreadBadgeService({BadgeUpdater? updateBadge, bool? isSupported})
    : _updateBadge = updateBadge ?? _updateNativeBadge,
      _isSupported = isSupported ?? Platform.isMacOS;

  final BadgeUpdater _updateBadge;
  final bool _isSupported;
  int? _lastCount;

  static Future<void> _updateNativeBadge(int count) async {
    await AppBadgePlus.updateBadge(count);
  }

  /// Shows [count] on the icon, and clears the badge at zero. A repeated count
  /// is skipped, and a failure is logged instead of thrown, so a badge problem
  /// never breaks the app.
  Future<void> update(int count) async {
    if (!_isSupported) return;

    final next = count < 0 ? 0 : count;
    if (next == _lastCount) return;

    try {
      await _updateBadge(next);
      _lastCount = next;
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to update the unread badge',
        tag: 'UnreadBadgeService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
