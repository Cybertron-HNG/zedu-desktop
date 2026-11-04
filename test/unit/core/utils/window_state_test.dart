import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';

void main() {
  group('WindowState', () {
    test('round-trips bounds and the maximized flag', () {
      const state = WindowState(
        bounds: Rect.fromLTWH(120, 80, 1280, 800),
        isMaximized: true,
      );

      final parsed = WindowState.tryParse(state.encode());

      expect(parsed, isNotNull);
      expect(parsed!.bounds, const Rect.fromLTWH(120, 80, 1280, 800));
      expect(parsed.isMaximized, isTrue);
    });

    test('treats a missing maximized flag as not maximized', () {
      final parsed = WindowState.tryParse(
        '{"left":0,"top":0,"width":800,"height":600}',
      );

      expect(parsed, isNotNull);
      expect(parsed!.isMaximized, isFalse);
    });

    test('rejects missing, empty and malformed values', () {
      expect(WindowState.tryParse(null), isNull);
      expect(WindowState.tryParse(''), isNull);
      expect(WindowState.tryParse('not json'), isNull);
      expect(WindowState.tryParse('[]'), isNull);
      expect(WindowState.tryParse('{"left":0,"top":0,"width":800}'), isNull);
    });

    test('rejects bounds that are too small to use', () {
      expect(
        WindowState.tryParse(
          '{"left":0,"top":0,"width":320,"height":200,"maximized":false}',
        ),
        isNull,
      );
    });

    test('rejects non-finite and implausible coordinates', () {
      expect(
        WindowState.tryParse(
          '{"left":100000,"top":0,"width":800,"height":600,"maximized":false}',
        ),
        isNull,
      );
    });
  });
}
