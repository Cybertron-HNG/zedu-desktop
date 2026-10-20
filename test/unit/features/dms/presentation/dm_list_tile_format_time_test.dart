import '../../../../helpers/helpers.dart';
import 'package:zedu/features/features.dart';

void main() {
  final now = DateTime(2026, 10, 20, 15, 30);

  group('DmListTile.formatTime', () {
    test('shows the time for a message from today', () {
      expect(
        DmListTile.formatTime(DateTime(2026, 10, 20, 9, 5), now: now),
        '9:05 AM',
      );
    });

    test('shows "Yesterday" for a message from yesterday', () {
      expect(
        DmListTile.formatTime(DateTime(2026, 10, 19, 22), now: now),
        'Yesterday',
      );
    });

    test('shows the month as a word for an older date this year', () {
      expect(DmListTile.formatTime(DateTime(2026, 6, 5), now: now), '5 Jun');
      expect(DmListTile.formatTime(DateTime(2026, 5, 6), now: now), '6 May');
    });

    test('adds the year for a date in an earlier year', () {
      expect(
        DmListTile.formatTime(DateTime(2025, 12, 31), now: now),
        '31 Dec 2025',
      );
    });
  });
}
