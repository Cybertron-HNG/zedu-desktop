import '../../../../helpers/helpers.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('UnreadBadgeService', () {
    late List<int> shown;

    setUp(() {
      shown = [];
    });

    UnreadBadgeService buildService({
      bool isSupported = true,
      Future<void> Function(int count)? updateBadge,
    }) {
      return UnreadBadgeService(
        isSupported: isSupported,
        updateBadge:
            updateBadge ??
            (count) async {
              shown.add(count);
            },
      );
    }

    test('shows the unread count on the icon', () async {
      final service = buildService();

      await service.update(7);

      expect(shown, [7]);
    });

    test('clears the badge when the count drops to zero', () async {
      final service = buildService();

      await service.update(4);
      await service.update(0);

      expect(shown, [4, 0]);
    });

    test('skips a count that is already shown', () async {
      final service = buildService();

      await service.update(3);
      await service.update(3);

      expect(shown, [3]);
    });

    test('treats a negative count as zero', () async {
      final service = buildService();

      await service.update(-2);

      expect(shown, [0]);
    });

    test('does nothing on a platform without badge support', () async {
      final service = buildService(isSupported: false);

      await service.update(5);

      expect(shown, isEmpty);
    });

    test('logs a failure instead of throwing, and retries later', () async {
      var calls = 0;
      final service = buildService(
        updateBadge: (count) async {
          calls++;
          if (calls == 1) throw Exception('badge failed');
          shown.add(count);
        },
      );

      await service.update(2);
      expect(shown, isEmpty);

      await service.update(2);
      expect(shown, [2]);
    });
  });
}
