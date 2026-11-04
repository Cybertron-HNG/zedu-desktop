import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('unreadDividerIndex', () {
    test('returns null when nothing is unread', () {
      expect(
        unreadDividerIndex(messageCount: 20, unreadCount: 0, hasMore: false),
        isNull,
      );
    });

    test('returns null for an empty history', () {
      expect(
        unreadDividerIndex(messageCount: 0, unreadCount: 4, hasMore: false),
        isNull,
      );
    });

    test('places the divider after the unread messages', () {
      expect(
        unreadDividerIndex(messageCount: 20, unreadCount: 3, hasMore: false),
        3,
      );
      expect(
        unreadDividerIndex(messageCount: 20, unreadCount: 20, hasMore: true),
        20,
      );
    });

    test('waits for more pages while the boundary is unknown', () {
      expect(
        unreadDividerIndex(messageCount: 20, unreadCount: 45, hasMore: true),
        isNull,
      );
      expect(
        unreadDividerIndex(messageCount: 20, unreadCount: 45, hasMore: false),
        20,
      );
    });
  });
}
