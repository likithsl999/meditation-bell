import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _keyTotalMinutes = 'total_meditation_minutes';
  static const _keyTotalSessions = 'total_completed_sessions';
  static const _keyCurrentStreak = 'current_streak';
  static const _keyLastSessionDate = 'last_session_date';
  static const _keyVibrationEnabled = 'vibration_enabled';
  static const _keyBellSound = 'bell_sound';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Stats
  int get totalMinutes => _prefs.getInt(_keyTotalMinutes) ?? 0;
  int get totalSessions => _prefs.getInt(_keyTotalSessions) ?? 0;
  int get currentStreak => _prefs.getInt(_keyCurrentStreak) ?? 0;
  String? get lastSessionDate => _prefs.getString(_keyLastSessionDate);

  Future<void> recordCompletedSession(int minutes) async {
    final newTotal = totalMinutes + minutes;
    final newSessions = totalSessions + 1;
    await _prefs.setInt(_keyTotalMinutes, newTotal);
    await _prefs.setInt(_keyTotalSessions, newSessions);
    await _updateStreak();
  }

  Future<void> _updateStreak() async {
    final today = _dateString(DateTime.now());
    final last = lastSessionDate;

    if (last == null) {
      await _prefs.setInt(_keyCurrentStreak, 1);
    } else {
      final lastDate = DateTime.parse(last);
      final yesterday = _dateString(DateTime.now().subtract(const Duration(days: 1)));

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

  // Settings
  bool get vibrationEnabled => _prefs.getBool(_keyVibrationEnabled) ?? true;
  String get bellSound => _prefs.getString(_keyBellSound) ?? 'temple_bell';

  Future<void> setVibrationEnabled(bool value) =>
      _prefs.setBool(_keyVibrationEnabled, value);

  Future<void> setBellSound(String value) =>
      _prefs.setString(_keyBellSound, value);
}
