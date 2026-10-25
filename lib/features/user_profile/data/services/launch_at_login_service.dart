import 'dart:io';

import 'package:launch_at_startup/launch_at_startup.dart';

/// Turns "start Zedu when I log in" on or off for this computer.
abstract class LaunchAtLoginService {
  /// Only macOS and Windows have a login item to manage.
  bool get isSupported;

  Future<bool> isEnabled();

  Future<void> setEnabled(bool enabled);
}

/// The macOS login item API (SMAppService) needs macOS 13 or later.
/// [osVersion] looks like "Version 14.5 (Build 23F79)".
bool macOsSupportsLoginItem(String osVersion) {
  final major = int.tryParse(
    RegExp(r'Version (\d+)').firstMatch(osVersion)?.group(1) ?? '',
  );
  return major != null && major >= 13;
}

/// Uses the operating system's own login item, so the choice is kept between
/// launches without the app saving anything itself.
class PlatformLaunchAtLoginService implements LaunchAtLoginService {
  PlatformLaunchAtLoginService() {
    if (isSupported) {
      launchAtStartup.setup(
        appName: 'Zedu',
        appPath: Platform.resolvedExecutable,
      );
    }
  }

  @override
  bool get isSupported =>
      Platform.isWindows ||
      (Platform.isMacOS &&
          macOsSupportsLoginItem(Platform.operatingSystemVersion));

  @override
  Future<bool> isEnabled() => launchAtStartup.isEnabled();

  @override
  Future<void> setEnabled(bool enabled) async {
    if (enabled) {
      await launchAtStartup.enable();
    } else {
      await launchAtStartup.disable();
    }
  }
}
