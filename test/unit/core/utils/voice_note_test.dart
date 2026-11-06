import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/utils/voice_note.dart';

void main() {
  group('formatClockDuration', () {
    test('formats seconds, minutes and hours like a clock', () {
      expect(formatClockDuration(Duration.zero), '0:00');
      expect(formatClockDuration(const Duration(seconds: 5)), '0:05');
      expect(formatClockDuration(const Duration(seconds: 59)), '0:59');
      expect(formatClockDuration(const Duration(seconds: 60)), '1:00');
      expect(formatClockDuration(const Duration(seconds: 125)), '2:05');
      expect(formatClockDuration(const Duration(seconds: 3600)), '1:00:00');
      expect(formatClockDuration(const Duration(seconds: 3723)), '1:02:03');
    });

    test('never shows a negative length', () {
      expect(formatClockDuration(const Duration(seconds: -3)), '0:00');
    });
  });

  group('voice note marker', () {
    test('round-trips the recording length', () {
      final marker = voiceNoteMarker(
        const Duration(seconds: 12, milliseconds: 700),
      );
      expect(marker, '[Voice Note Attached:12]');
      expect(hasVoiceNoteMarker(marker), isTrue);
      expect(voiceNoteLength(marker), const Duration(seconds: 12));
    });

    test('an older marker without a length is still a voice note', () {
      const legacy = '[Voice Note Attached]';
      expect(hasVoiceNoteMarker(legacy), isTrue);
      expect(voiceNoteLength(legacy), isNull);
    });

    test('ordinary or malformed text is not a voice note with a length', () {
      expect(hasVoiceNoteMarker('hello'), isFalse);
      expect(voiceNoteLength('hello'), isNull);
      expect(hasVoiceNoteMarker('[Voice Note Attached:abc]'), isFalse);
      expect(voiceNoteLength('[Voice Note Attached:]'), isNull);
    });
  });
}
