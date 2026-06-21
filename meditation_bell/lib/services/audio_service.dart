import 'package:audioplayers/audioplayers.dart';
import '../models/custom_sound.dart';
import '../models/app_settings.dart';

class AudioService {
  final AudioPlayer _bellPlayer = AudioPlayer();
  final AudioPlayer _backgroundPlayer = AudioPlayer();

  static const _builtInSounds = AppSettings.bellSoundOptions;

  double _bellVolume = 1.0;
  double _backgroundVolume = 0.0;

  // ── Initialisation ────────────────────────────────────────────────────────
  // Must be called once from main() before runApp().

  Future<void> init() async {
    const ctx = AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {
          AVAudioSessionOptions.allowBluetooth,
          AVAudioSessionOptions.allowBluetoothA2DP,
        },
      ),
    );
    await AudioPlayer.global.setAudioContext(ctx);
  }

  // ── Volume ────────────────────────────────────────────────────────────────

  void setBellVolume(double volume) {
    _bellVolume = volume.clamp(0.0, 1.0);
    _bellPlayer.setVolume(_bellVolume);
  }

  void setBackgroundVolume(double volume) {
    _backgroundVolume = volume.clamp(0.0, 1.0);
    _backgroundPlayer.setVolume(_backgroundVolume);
  }

  // ── Bell ──────────────────────────────────────────────────────────────────

  Future<void> playBell(
    String soundKey, {
    List<CustomSound> customSounds = const [],
  }) async {
    try {
      await _bellPlayer.setVolume(_bellVolume);
      await _bellPlayer.stop();

      if (_builtInSounds.contains(soundKey)) {
        await _bellPlayer.play(AssetSource('audio/$soundKey.mp3'));
      } else {
        final match = customSounds.where((s) => s.id == soundKey).firstOrNull;
        if (match != null) {
          await _bellPlayer.play(DeviceFileSource(match.filePath));
        }
      }
    } catch (_) {
      // Graceful degradation — sound failure must never break the session.
    }
  }

  Future<void> playFile(String filePath) async {
    try {
      await _bellPlayer.setVolume(_bellVolume);
      await _bellPlayer.stop();
      await _bellPlayer.play(DeviceFileSource(filePath));
    } catch (_) {}
  }

  // ── Background / ambient ──────────────────────────────────────────────────

  /// Pass [assetPath] as e.g. 'audio/rain.mp3'.  Pass null to stop.
  Future<void> playBackground(String? assetPath) async {
    try {
      if (assetPath == null) {
        await _backgroundPlayer.stop();
        return;
      }
      await _backgroundPlayer.setVolume(_backgroundVolume);
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundPlayer.play(AssetSource(assetPath));
    } catch (_) {}
  }

  Future<void> stopBackground() async {
    try {
      await _backgroundPlayer.stop();
    } catch (_) {}
  }

  Future<void> stopAll() async {
    try {
      await _bellPlayer.stop();
      await _backgroundPlayer.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _bellPlayer.dispose();
    await _backgroundPlayer.dispose();
  }
}
