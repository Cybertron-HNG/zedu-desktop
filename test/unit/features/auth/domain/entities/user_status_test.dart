import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('StatusTimeout.expiryFrom', () {
    test('this week ends at 23:59 on Sunday when set on a Monday', () {
      final monday = DateTime(2026, 11, 2, 9, 15);

      expect(
        StatusTimeout.thisWeek.expiryFrom(monday),
        DateTime(2026, 11, 8, 23, 59),
      );
    });

    test('this week ends at 23:59 on Sunday when set mid-week', () {
      final thursday = DateTime(2026, 11, 5, 18, 40);

      expect(
        StatusTimeout.thisWeek.expiryFrom(thursday),
        DateTime(2026, 11, 8, 23, 59),
      );
    });

    test('this week set on a Sunday lasts until the end of that day', () {
      final sunday = DateTime(2026, 11, 8, 14, 30);

      expect(
        StatusTimeout.thisWeek.expiryFrom(sunday),
        DateTime(2026, 11, 8, 23, 59),
      );
    });

    test('this week rolls over the end of the month', () {
      final friday = DateTime(2026, 10, 30, 8);

      expect(
        StatusTimeout.thisWeek.expiryFrom(friday),
        DateTime(2026, 11, 1, 23, 59),
      );
    });

    test('other timeouts keep their expiry', () {
      final now = DateTime(2026, 11, 4, 10);

      expect(
        StatusTimeout.thirtyMinutes.expiryFrom(now),
        DateTime(2026, 11, 4, 10, 30),
      );
      expect(StatusTimeout.oneHour.expiryFrom(now), DateTime(2026, 11, 4, 11));
      expect(
        StatusTimeout.today.expiryFrom(now),
        DateTime(2026, 11, 4, 23, 59),
      );
      expect(StatusTimeout.dontRemove.expiryFrom(now), isNull);
    });
  });
}
