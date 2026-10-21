import 'package:dio/dio.dart';

/// A newer Zedu Desktop release.
class AppUpdate {
  const AppUpdate({required this.version, required this.url});

  final String version;

  /// Release page, where the person downloads the new version.
  final String url;
}

/// Compares the running version with the latest public GitHub release.
class UpdateCheckService {
  UpdateCheckService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            ),
          );

  static const latestReleaseUrl =
      'https://api.github.com/repos/zeduchat/zedu-desktop/releases/latest';

  final Dio _dio;

  /// The newer release, or null when up to date or the check fails. A failed
  /// check never blocks the app.
  Future<AppUpdate?> latestIfNewer(String currentVersion) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(latestReleaseUrl);
      final data = response.data;
      final tag = data?['tag_name'] as String?;
      final url = data?['html_url'] as String?;
      if (tag == null || url == null) return null;
      if (!isNewer(tag, currentVersion)) return null;
      return AppUpdate(version: tag.replaceFirst(RegExp(r'^v'), ''), url: url);
    } catch (_) {
      return null;
    }
  }

  /// True when [latest] (for example "v0.2.0") is a higher version than
  /// [current] (for example "0.1.0"). Build numbers after "+" are ignored.
  static bool isNewer(String latest, String current) {
    final a = _parts(latest);
    final b = _parts(current);
    for (var i = 0; i < 3; i++) {
      if (a[i] != b[i]) return a[i] > b[i];
    }
    return false;
  }

  static List<int> _parts(String version) {
    final core = version.replaceFirst(RegExp(r'^v'), '').split(RegExp(r'[+-]'));
    final numbers = core.first.split('.');
    return List<int>.generate(
      3,
      (i) => i < numbers.length ? int.tryParse(numbers[i]) ?? 0 : 0,
    );
  }
}
