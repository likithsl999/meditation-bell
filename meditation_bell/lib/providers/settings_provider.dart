import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;
  late AppSettings _settings;

  SettingsProvider(this._storage) {
    _settings = AppSettings(
      vibrationEnabled: _storage.vibrationEnabled,
      bellSound: _storage.bellSound,
    );
  }

  AppSettings get settings => _settings;
  bool get vibrationEnabled => _settings.vibrationEnabled;
  String get bellSound => _settings.bellSound;

  Future<void> setVibrationEnabled(bool value) async {
    _settings = _settings.copyWith(vibrationEnabled: value);
    await _storage.setVibrationEnabled(value);
    notifyListeners();
  }

  Future<void> setBellSound(String value) async {
    _settings = _settings.copyWith(bellSound: value);
    await _storage.setBellSound(value);
    notifyListeners();
  }
}
