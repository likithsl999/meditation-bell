import 'package:audioplayers/audioplayers.dart';
import '../models/custom_sound.dart';
import '../models/app_settings.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  static const _builtInSounds = AppSettings.bellSoundOptions;

  /// Plays a bell identified by [soundKey].
  /// For built-in sounds the key is the asset name (e.g. 'temple_bell').
  /// For custom sounds pass the matching [CustomSound] via [customSounds].
  Future<void> playBell(
    String soundKey, {
    List<CustomSound> customSounds = const [],
  }) async {
    try {
      await _player.stop();

      if (_builtInSounds.contains(soundKey)) {
        await _player.play(AssetSource('audio/$soundKey.mp3'));
      } else {
        final match = customSounds.where((s) => s.id == soundKey).toList();
        if (match.isNotEmpty) {
          await _player.play(DeviceFileSource(match.first.filePath));
        }
      }
    } catch (_) {
      // Graceful degradation — sound failure must not break the session.
    }
  }

  /// Convenience method used for direct preview of a file path.
  Future<void> playFile(String filePath) async {
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(filePath));
    } catch (_) {}
  }

  Future<void> stopAll() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
