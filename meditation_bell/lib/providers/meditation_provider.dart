import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/custom_sound.dart';
import '../models/meditation_session.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';

enum MeditationState { idle, running, paused, finished }

class MeditationProvider extends ChangeNotifier {
  final AudioService _audio;
  final StorageService _storage;

  MeditationProvider(this._audio, this._storage);

  MeditationState _state = MeditationState.idle;
  MeditationSession? _session;

  int _remainingSeconds = 0;
  int _secondsSinceLastBell = 0;
  Timer? _ticker;

  // Captured at session start so the sound stays consistent even if settings
  // change mid-session.
  String _activeBellSound = 'temple_bell';
  List<CustomSound> _activeCustomSounds = const [];
  bool _activeVibrate = false;

  // ── Getters ───────────────────────────────────────────────────────────────

  MeditationState get state => _state;
  MeditationSession? get session => _session;
  int get remainingSeconds => _remainingSeconds;

  String get remainingFormatted {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get isRunning => _state == MeditationState.running;
  bool get isPaused => _state == MeditationState.paused;
  bool get isFinished => _state == MeditationState.finished;
  bool get isActive =>
      _state == MeditationState.running || _state == MeditationState.paused;

  // ── Session lifecycle ─────────────────────────────────────────────────────

  Future<void> start({
    required int durationMinutes,
    required int intervalSeconds,
    required String bellSound,
    required bool vibrate,
    List<CustomSound> customSounds = const [],
  }) async {
    _session = MeditationSession(
      durationMinutes: durationMinutes,
      intervalSeconds: intervalSeconds,
      startedAt: DateTime.now(),
    );
    _remainingSeconds = durationMinutes * 60;
    _secondsSinceLastBell = 0;
    _state = MeditationState.running;

    _activeBellSound = bellSound;
    _activeCustomSounds = customSounds;
    _activeVibrate = vibrate;

    await WakelockPlus.enable();
    await _audio.playBell(bellSound, customSounds: customSounds);
    if (vibrate) _triggerVibration();

    _startTicker();
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_state != MeditationState.running) return;

      _remainingSeconds--;
      _secondsSinceLastBell++;

      final intervalSec = _session!.intervalSeconds;
      if (_secondsSinceLastBell >= intervalSec && _remainingSeconds > 0) {
        _secondsSinceLastBell = 0;
        await _audio.playBell(_activeBellSound,
            customSounds: _activeCustomSounds);
        if (_activeVibrate) _triggerVibration();
      }

      if (_remainingSeconds <= 0) {
        await _finish();
        return;
      }

      notifyListeners();
    });
  }

  Future<void> _finish() async {
    _ticker?.cancel();
    _state = MeditationState.finished;
    await _audio.playBell(_activeBellSound, customSounds: _activeCustomSounds);
    if (_activeVibrate) _triggerVibration();
    await WakelockPlus.disable();
    await _storage.recordCompletedSession(_session!.durationMinutes);
    notifyListeners();
  }

  void pause() {
    if (_state != MeditationState.running) return;
    _state = MeditationState.paused;
    _ticker?.cancel();
    notifyListeners();
  }

  void resume() {
    if (_state != MeditationState.paused) return;
    _state = MeditationState.running;
    _startTicker();
    notifyListeners();
  }

  Future<void> stop() async {
    _ticker?.cancel();
    _state = MeditationState.idle;
    _session = null;
    _remainingSeconds = 0;
    _secondsSinceLastBell = 0;
    await WakelockPlus.disable();
    notifyListeners();
  }

  // ── Haptics ───────────────────────────────────────────────────────────────

  void _triggerVibration() async {
    try {
      final has = await Vibration.hasVibrator() ?? false;
      if (has) Vibration.vibrate(pattern: [0, 300, 100, 300]);
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
