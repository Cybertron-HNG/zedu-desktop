import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

Map<String, dynamic> _thread(Object? createdAt) => {
  'thread_id': 't1',
  'message': 'hi',
  'user_id': 'u1',
  'username': 'ada',
  'created_at': createdAt,
};

void main() {
  group('DmPreviewThread.fromJson', () {
    test('reads an ISO 8601 created_at as local time', () {
      final thread = DmPreviewThread.fromJson(_thread('2026-10-17T08:01:00Z'));
      expect(thread.createdAt, DateTime.utc(2026, 10, 17, 8, 1).toLocal());
    });

    test('does not throw on a malformed created_at', () {
      for (final bad in ['17/10/2026 08:01', 'yesterday', '', 1729152060]) {
        final before = DateTime.now();
        final thread = DmPreviewThread.fromJson(_thread(bad));
        expect(
          thread.createdAt.isBefore(
            before.subtract(const Duration(seconds: 1)),
          ),
          isFalse,
          reason: '$bad falls back to now',
        );
      }
    });

    test('falls back to now when created_at is missing', () {
      final thread = DmPreviewThread.fromJson(_thread(null));
      expect(
        DateTime.now().difference(thread.createdAt).inSeconds,
        lessThan(5),
      );
    });
  });
}
