class MagicLinkDeepLinkParser {
  const MagicLinkDeepLinkParser._();

  static String? extractToken(Uri uri) {
    if (!_isSupportedMagicLinkUri(uri)) return null;
    final token = uri.queryParameters['token']?.trim();
    if (token == null || token.isEmpty) return null;
    return token;
  }

  static bool _isSupportedMagicLinkUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    final path = _normalizePath(uri.path);

    // The dev backend API routes use the `magick-link` spelling, but the
    // link built into the email uses `magic-link` (services/auth/magic_link.go
    // builds `auth/login/magic-link?token=`). Accept both so the emailed
    // link always opens the app.
    if (scheme == 'zedu' && host == 'auth' && _isVerifyPath(path)) {
      return true;
    }

    if ((scheme == 'https' || scheme == 'http') &&
        (_endsWithVerifyPath(path, '/auth/magick-link/verify') ||
            _endsWithVerifyPath(path, '/auth/magic-link/verify') ||
            _endsWithVerifyPath(path, '/auth/login/magic-link'))) {
      return true;
    }

    return false;
  }

  static bool _isVerifyPath(String path) =>
      path == '/magick-link/verify' || path == '/magic-link/verify';

  static bool _endsWithVerifyPath(String path, String suffix) =>
      path == suffix || path.endsWith(suffix);

  static String _normalizePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return '/';
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }
}
