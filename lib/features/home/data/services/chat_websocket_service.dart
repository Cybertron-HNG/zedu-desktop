import 'dart:async';

import 'package:zedu/core/core.dart';

class ChatWebsocketMessage {
  final String groupDmId;
  final String text;
  final String authorName;
  final DateTime timestamp;

  const ChatWebsocketMessage({
    required this.groupDmId,
    required this.text,
    required this.authorName,
    required this.timestamp,
  });
}

class ChatWebsocketService {
  final _messageController = StreamController<ChatWebsocketMessage>.broadcast();
  Timer? _mockTimer;

  Stream<ChatWebsocketMessage> get messageStream => _messageController.stream;

  void connect(List<String> activeGroupDmIds) {
    // Simulate connection establishing
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      debugPrint('Mock WebSocket Connected');
      _startMockingMessages(activeGroupDmIds);
    });
  }

  void disconnect() {
    _mockTimer?.cancel();
    debugPrint('Mock WebSocket Disconnected');
  }

  void _startMockingMessages(List<String> activeGroupDmIds) {
    if (activeGroupDmIds.isEmpty) return;

    // Periodically send a fake incoming message to simulate real-time activity
    _mockTimer?.cancel();
    _mockTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      // Pick a random group DM
      final groupId = activeGroupDmIds[timer.tick % activeGroupDmIds.length];

      _messageController.add(
        ChatWebsocketMessage(
          groupDmId: groupId,
          text:
              'This is a simulated real-time incoming message (#${timer.tick})',
          authorName: 'Mock Member',
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void sendMessage(String groupDmId, String text) {
    // In a real implementation, this sends over the WebSocket.
    // For mock, we assume success or handle failure outside.
  }

  void dispose() {
    _mockTimer?.cancel();
    _messageController.close();
  }
}

final chatWebsocketProvider = Provider<ChatWebsocketService>((ref) {
  final service = ChatWebsocketService();
  ref.onDispose(service.dispose);
  return service;
});
