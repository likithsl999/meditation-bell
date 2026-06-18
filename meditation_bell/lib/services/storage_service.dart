import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/custom_sound.dart';

class StorageService {
  static const _keyTotalMinutes = 'total_meditation_minutes';
  static const _keyTotalSessions = 'total_completed_sessions';
  static const _keyCurrentStreak = 'current_streak';
  static const _keyLastSessionDate = 'last_session_date';
  static const _keyVibrationEnabled = 'vibration_enabled';
  static const _keyBellSound = 'bell_sound';
  static const _keyCustomSounds = 'custom_sounds';
  static const _keyBellVolume = 'bell_volume';
  static const _keyBackgroundVolume = 'background_volume';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  int get totalMinutes => _prefs.getInt(_keyTotalMinutes) ?? 0;
  int get totalSessions => _prefs.getInt(_keyTotalSessions) ?? 0;
  int get currentStreak => _prefs.getInt(_keyCurrentStreak) ?? 0;
  String? get lastSessionDate => _prefs.getString(_keyLastSessionDate);

  Future<void> recordCompletedSession(int minutes) async {
    await _prefs.setInt(_keyTotalMinutes, totalMinutes + minutes);
    await _prefs.setInt(_keyTotalSessions, totalSessions + 1);
    await _updateStreak();
  }

  Future<void> _updateStreak() async {
    final today = _dateString(DateTime.now());
    final last = lastSessionDate;

    if (last == null) {
      await _prefs.setInt(_keyCurrentStreak, 1);
    } else {
      final lastDate = DateTime.parse(last);
      final yesterday =
          _dateString(DateTime.now().subtract(const Duration(days: 1)));
      if (last == today) {
        // Already recorded today — no change
      } else if (_dateString(lastDate) == yesterday) {
        await _prefs.setInt(_keyCurrentStreak, currentStreak + 1);
      } else {
        await _prefs.setInt(_keyCurrentStreak, 1);
      }
    }
    await _prefs.setString(_keyLastSessionDate, today);
  }

  String _dateString(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  // ── Settings ──────────────────────────────────────────────────────────────

  bool get vibrationEnabled => _prefs.getBool(_keyVibrationEnabled) ?? true;
  String get bellSound => _prefs.getString(_keyBellSound) ?? 'temple_bell';
  double get bellVolume => _prefs.getDouble(_keyBellVolume) ?? 1.0;
  double get backgroundVolume => _prefs.getDouble(_keyBackgroundVolume) ?? 0.0;

  Future<void> setVibrationEnabled(bool value) =>
      _prefs.setBool(_keyVibrationEnabled, value);
  Future<void> setBellSound(String value) =>
      _prefs.setString(_keyBellSound, value);
  Future<void> setBellVolume(double value) =>
      _prefs.setDouble(_keyBellVolume, value);
  Future<void> setBackgroundVolume(double value) =>
      _prefs.setDouble(_keyBackgroundVolume, value);

  // ── Custom sounds ─────────────────────────────────────────────────────────

  List<CustomSound> getCustomSounds() {
    final raw = _prefs.getString(_keyCustomSounds);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => CustomSound.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveCustomSounds(List<CustomSound> sounds) async {
    final encoded = jsonEncode(sounds.map((s) => s.toMap()).toList());
    await _prefs.setString(_keyCustomSounds, encoded);
  }

  Future<void> addCustomSound(CustomSound sound) async {
    final list = getCustomSounds()..add(sound);
    await _saveCustomSounds(list);
  }

  Future<void> deleteCustomSound(String id) async {
    final list = getCustomSounds()..removeWhere((s) => s.id == id);
    await _saveCustomSounds(list);
  }

  Future<void> renameCustomSound(String id, String newName) async {
    final list = getCustomSounds()
        .map((s) => s.id == id ? s.copyWith(name: newName) : s)
        .toList();
    await _saveCustomSounds(list);
  }
}
