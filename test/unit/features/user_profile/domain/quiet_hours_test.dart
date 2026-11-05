import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

NotificationPreferences preferences({
  bool enabled = true,
  int pauseFrom = 9 * 60,
  int resumeAt = 17 * 60,
}) {
  return NotificationPreferences(
    mode: NotificationMode.allMessages,
    quietHoursEnabled: enabled,
    pauseFrom: pauseFrom,
    resumeAt: resumeAt,
    emailNotifications: true,
    differentMobileSettings: false,
  );
}

DateTime at(int hour, int minute) => DateTime(2026, 11, 5, hour, minute);

void main() {
  group('isWithinQuietHours', () {
    test('is false when quiet hours are off', () {
      expect(
        isWithinQuietHours(preferences(enabled: false), at(12, 0)),
        isFalse,
      );
    });

    test('is false when start and end are the same', () {
      expect(
        isWithinQuietHours(
          preferences(pauseFrom: 9 * 60, resumeAt: 9 * 60),
          at(9, 0),
        ),
        isFalse,
      );
    });

    test('covers a same-day window, start inclusive and end exclusive', () {
      final prefs = preferences();

      expect(isWithinQuietHours(prefs, at(8, 59)), isFalse);
      expect(isWithinQuietHours(prefs, at(9, 0)), isTrue);
      expect(isWithinQuietHours(prefs, at(12, 30)), isTrue);
      expect(isWithinQuietHours(prefs, at(16, 59)), isTrue);
      expect(isWithinQuietHours(prefs, at(17, 0)), isFalse);
      expect(isWithinQuietHours(prefs, at(23, 0)), isFalse);
    });

    test('wraps a window that crosses midnight', () {
      final prefs = preferences(pauseFrom: 22 * 60, resumeAt: 7 * 60);

      expect(isWithinQuietHours(prefs, at(21, 59)), isFalse);
      expect(isWithinQuietHours(prefs, at(22, 0)), isTrue);
      expect(isWithinQuietHours(prefs, at(23, 59)), isTrue);
      expect(isWithinQuietHours(prefs, at(0, 0)), isTrue);
      expect(isWithinQuietHours(prefs, at(6, 59)), isTrue);
      expect(isWithinQuietHours(prefs, at(7, 0)), isFalse);
      expect(isWithinQuietHours(prefs, at(12, 0)), isFalse);
    });

    test('treats a midnight-to-midnight window as all day', () {
      final prefs = preferences(
        pauseFrom: 0,
        resumeAt: NotificationPreferences.minutesPerDay - 1,
      );

      expect(isWithinQuietHours(prefs, at(0, 0)), isTrue);
      expect(isWithinQuietHours(prefs, at(23, 58)), isTrue);
      expect(isWithinQuietHours(prefs, at(23, 59)), isFalse);
    });
  });

  group('shouldSuppressMessageNotification', () {
    test('suppresses while the manual Do Not Disturb timer runs', () {
      expect(
        shouldSuppressMessageNotification(
          isDndActive: true,
          quietHours: null,
          now: at(12, 0),
        ),
        isTrue,
      );
    });

    test('suppresses inside the quiet-hours window', () {
      expect(
        shouldSuppressMessageNotification(
          isDndActive: false,
          quietHours: preferences(pauseFrom: 22 * 60, resumeAt: 7 * 60),
          now: at(23, 30),
        ),
        isTrue,
      );
    });

    test('allows a message outside the window', () {
      expect(
        shouldSuppressMessageNotification(
          isDndActive: false,
          quietHours: preferences(pauseFrom: 22 * 60, resumeAt: 7 * 60),
          now: at(9, 0),
        ),
        isFalse,
      );
    });

    test('allows a message when no preferences are loaded', () {
      expect(
        shouldSuppressMessageNotification(
          isDndActive: false,
          quietHours: null,
          now: at(23, 30),
        ),
        isFalse,
      );
    });
  });
}
