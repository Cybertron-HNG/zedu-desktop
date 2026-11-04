import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('mentionsUser', () {
    test('matches the handle regardless of case and punctuation', () {
      expect(mentionsUser('Hi @Joshua, can you check?', 'joshua'), isTrue);
      expect(mentionsUser('Thanks @joshua.', 'joshua'), isTrue);
    });

    test('does not match longer handles or email addresses', () {
      expect(mentionsUser('Hi @joshuab', 'joshua'), isFalse);
      expect(mentionsUser('Write to hi@joshua.com', 'joshua'), isFalse);
    });

    test('ignores an empty username', () {
      expect(mentionsUser('Hi @joshua', ''), isFalse);
    });
  });

  group('inboxPreview', () {
    test('strips markup and collapses whitespace', () {
      expect(
        inboxPreview('<p>Fish &amp; chips</p>\n\n  <b>today</b>'),
        'Fish & chips today',
      );
    });

    test('shortens long messages and fills empty ones', () {
      final preview = inboxPreview('a' * 200);
      expect(preview.length, 120);
      expect(preview, endsWith('...'));
      expect(inboxPreview('   '), '[Message]');
    });
  });
}
