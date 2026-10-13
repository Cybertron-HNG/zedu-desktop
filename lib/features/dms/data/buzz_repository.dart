import 'package:zedu/core/core.dart';

final buzzRepositoryProvider = Provider<BuzzRepository>((ref) {
  return BuzzRepository();
});

class BuzzRepository {
  Future<Map<String, dynamic>> initiateDirectCall(String participantId) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return {
      'success': true,
      'buzzId': 'mock-buzz-id-${DateTime.now().millisecondsSinceEpoch}',
      'token': 'mock-agora-token',
      'channelName': 'mock-channel-$participantId',
    };
  }

  Future<bool> respondToInvitation(String buzzId, bool accept) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return true;
  }

  Future<bool> respondToDirectCall(String buzzId, bool accept) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return true;
  }
}
