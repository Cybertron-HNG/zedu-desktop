import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

Map<String, dynamic> _json({Object? lastReadAt}) => {
  'channel_id': 'c1',
  'username': 'ada',
  'participant_id': 'u1',
  'preview_message': '',
  'last_read_at': lastReadAt,
};

void main() {
  group('DmConversation last_read_at', () {
    test('the zero time for a DM never read counts as not read', () {
      final dm = DmConversation.fromJson(
        _json(lastReadAt: '0001-01-01T00:00:00Z'),
      );

      expect(dm.lastReadAt, isNull);
      expect(dm.hasActivity, isFalse);
    });

    test('a real read time is kept', () {
      final dm = DmConversation.fromJson(
        _json(lastReadAt: '2026-11-04T10:30:00Z'),
      );

      expect(dm.lastReadAt, DateTime.utc(2026, 11, 4, 10, 30).toLocal());
      expect(dm.hasActivity, isTrue);
    });

    test('a missing or unreadable read time counts as not read', () {
      expect(DmConversation.fromJson(_json()).lastReadAt, isNull);
      expect(
        DmConversation.fromJson(_json(lastReadAt: 'not a date')).lastReadAt,
        isNull,
      );
    });
  });
}
