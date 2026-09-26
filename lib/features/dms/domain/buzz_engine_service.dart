import 'package:zedu/core/core.dart';

final buzzEngineProvider = Provider<BuzzEngineService>((ref) {
  return BuzzEngineService();
});

class BuzzEngineService {
  late RtcEngine _engine;
  bool _isEngineInit = false;

  Future<void> initEngine(String appId) async {
    if (_isEngineInit) return;
    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
    _isEngineInit = true;
  }

  Future<void> joinChannel(String token, String channelName, int uid) async {
    if (!_isEngineInit) return;
    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  Future<void> leaveChannel() async {
    if (!_isEngineInit) return;
    await _engine.leaveChannel();
  }

  Future<void> toggleMic(bool mute) async {
    if (!_isEngineInit) return;
    await _engine.muteLocalAudioStream(mute);
  }

  Future<void> toggleVideo(bool mute) async {
    if (!_isEngineInit) return;
    await _engine.muteLocalVideoStream(mute);
  }

  void registerEventHandler(RtcEngineEventHandler handler) {
    if (!_isEngineInit) return;
    _engine.registerEventHandler(handler);
  }

  void unregisterEventHandler(RtcEngineEventHandler handler) {
    if (!_isEngineInit) return;
    _engine.unregisterEventHandler(handler);
  }

  Future<void> dispose() async {
    if (_isEngineInit) {
      await _engine.release();
      _isEngineInit = false;
    }
  }
}
