import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/home/data/services/chat_websocket_service.dart';

void main() {
  group('ChatWebsocketService lifecycle and timer safety', () {
    late ChatWebsocketService service;

    setUp(() {
      service = ChatWebsocketService();
    });

    tearDown(() {
      if (!service.isDisposed) {
        service.dispose();
      }
    });

    test('initial state is not disposed and has no pending connect timer', () {
      expect(service.isDisposed, isFalse);
      expect(service.hasPendingConnect, isFalse);
    });

    test('connect schedules a pending connect timer', () {
      service.connect(['group-1']);

      expect(service.hasPendingConnect, isTrue);
      expect(service.isDisposed, isFalse);
    });

    test('disconnect cancels pending connect timer', () {
      service.connect(['group-1']);
      expect(service.hasPendingConnect, isTrue);

      service.disconnect();
      expect(service.hasPendingConnect, isFalse);
    });

    test(
      'rapid connect then dispose does not throw Bad state on closed controller',
      () async {
        service.connect(['group-1', 'group-2']);
        expect(service.hasPendingConnect, isTrue);

        // Immediately dispose within the 500ms delay window
        service.dispose();
        expect(service.isDisposed, isTrue);
        expect(service.hasPendingConnect, isFalse);

        // Wait beyond the 500ms connection delay to verify no background timer fires on closed controller
        await Future<void>.delayed(const Duration(milliseconds: 600));

        // No exception thrown and service remains disposed
        expect(service.isDisposed, isTrue);
      },
    );

    test('calling connect on disposed service is a safe no-op', () {
      service.dispose();
      expect(service.isDisposed, isTrue);

      service.connect(['group-1']);
      expect(service.hasPendingConnect, isFalse);
    });

    test('disconnect and dispose can be called multiple times safely', () {
      service.disconnect();
      service.disconnect();
      service.dispose();
      service.dispose();

      expect(service.isDisposed, isTrue);
    });

    test('sendMessage is a safe call', () {
      expect(() => service.sendMessage('group-1', 'hello'), returnsNormally);
    });
  });
}
