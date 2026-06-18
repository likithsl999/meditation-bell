import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../models/meditation_session.dart';

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

  Future<void> start({
    required int durationMinutes,
    required int intervalSeconds,
    required String bellSound,
    required bool vibrate,
  }) async {
    _session = MeditationSession(
      durationMinutes: durationMinutes,
      intervalSeconds: intervalSeconds,
      startedAt: DateTime.now(),
    );
    _remainingSeconds = durationMinutes * 60;
    _secondsSinceLastBell = 0;
    _state = MeditationState.running;

    await WakelockPlus.enable();
    await _audio.playBell(bellSound);
    if (vibrate) _triggerVibration();

    _startTicker(bellSound: bellSound, vibrate: vibrate);
    notifyListeners();
  }

  void _startTicker({required String bellSound, required bool vibrate}) {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_state != MeditationState.running) return;

      _remainingSeconds--;
      _secondsSinceLastBell++;

      final intervalSec = _session!.intervalSeconds;
      if (_secondsSinceLastBell >= intervalSec && _remainingSeconds > 0) {
        _secondsSinceLastBell = 0;
        await _audio.playBell(bellSound);
        if (vibrate) _triggerVibration();
      }

      if (_remainingSeconds <= 0) {
        await _finish(bellSound: bellSound, vibrate: vibrate);
        return;
      }

      notifyListeners();
    });
  }

  Future<void> _finish({
    required String bellSound,
    required bool vibrate,
  }) async {
    _ticker?.cancel();
    _state = MeditationState.finished;
    await _audio.playBell(bellSound);
    if (vibrate) _triggerVibration();
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

  void resume({required String bellSound, required bool vibrate}) {
    if (_state != MeditationState.paused) return;
    _state = MeditationState.running;
    _startTicker(bellSound: bellSound, vibrate: vibrate);
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

  void _triggerVibration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        Vibration.vibrate(pattern: [0, 300, 100, 300]);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
