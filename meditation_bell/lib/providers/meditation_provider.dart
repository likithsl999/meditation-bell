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
  Timer? _ticker;

  // DateTime-based tracking — accurate even when ticks are throttled.
  DateTime? _sessionEndTime;
  DateTime? _nextBellTime;
  DateTime? _pausedAt;  // set when paused, used to shift end/bell times on resume

  int _remainingSeconds = 0;

  // Captured at session start — sound stays consistent even if settings change mid-session.
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
    final now = DateTime.now();
    _session = MeditationSession(
      durationMinutes: durationMinutes,
      intervalSeconds: intervalSeconds,
      startedAt: now,
    );
    _remainingSeconds = durationMinutes * 60;
    _sessionEndTime = now.add(Duration(minutes: durationMinutes));
    _nextBellTime = now.add(Duration(seconds: intervalSeconds));
    _pausedAt = null;
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

      final now = DateTime.now();
      final remaining = _sessionEndTime!.difference(now).inSeconds;

      if (remaining <= 0) {
        _remainingSeconds = 0;
        notifyListeners();
        await _finish();
        return;
      }

      _remainingSeconds = remaining;

      // Ring the bell when the next scheduled bell time has passed.
      if (_nextBellTime != null && now.isAfter(_nextBellTime!)) {
        // Advance to the next interval (catch-up if multiple ticks were missed).
        final intervalSec = _session!.intervalSeconds;
        while (_nextBellTime!.isBefore(now)) {
          _nextBellTime =
              _nextBellTime!.add(Duration(seconds: intervalSec));
        }
        await _audio.playBell(_activeBellSound,
            customSounds: _activeCustomSounds);
        if (_activeVibrate) _triggerVibration();
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
    _pausedAt = DateTime.now();
    _state = MeditationState.paused;
    _ticker?.cancel();
    notifyListeners();
  }

  void resume() {
    if (_state != MeditationState.paused) return;

    // Shift the end time and next bell time forward by the duration we were paused,
    // so the timer remains accurate.
    if (_pausedAt != null) {
      final pausedDuration = DateTime.now().difference(_pausedAt!);
      if (_sessionEndTime != null) {
        _sessionEndTime = _sessionEndTime!.add(pausedDuration);
      }
      if (_nextBellTime != null) {
        _nextBellTime = _nextBellTime!.add(pausedDuration);
      }
      _pausedAt = null;
    }

    _state = MeditationState.running;
    _startTicker();
    notifyListeners();
  }

  Future<void> stop() async {
    _ticker?.cancel();
    _state = MeditationState.idle;
    _session = null;
    _remainingSeconds = 0;
    _sessionEndTime = null;
    _nextBellTime = null;
    _pausedAt = null;
    await WakelockPlus.disable();
    notifyListeners();
  }

  // ── Haptics ───────────────────────────────────────────────────────────────

  // ignore: avoid_void_async
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
