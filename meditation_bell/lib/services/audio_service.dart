import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playBell(String bellSound) async {
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/$bellSound.mp3'));
    } catch (e) {
      // Graceful degradation — sound failure should not break the session
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
