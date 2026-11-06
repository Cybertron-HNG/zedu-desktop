import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';

void main() {
  group('initialOf', () {
    test('returns the uppercased first character', () {
      expect(initialOf('ada'), 'A');
      expect(initialOf('  okafor  '), 'O');
    });

    test('returns the fallback for null, empty, and whitespace', () {
      expect(initialOf(null), '?');
      expect(initialOf(''), '?');
      expect(initialOf('   '), '?');
      expect(initialOf('', fallback: 'W'), 'W');
    });

    test('keeps a surrogate pair whole instead of splitting an emoji', () {
      expect(initialOf('🎉 party'), '🎉');
    });
  });
}
