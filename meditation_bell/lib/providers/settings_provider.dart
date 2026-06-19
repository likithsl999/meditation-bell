import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_settings.dart';
import '../models/custom_sound.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;
  final AudioService _audio;

  late AppSettings _settings;
  List<CustomSound> _customSounds = [];

  bool _importing = false;
  String? _importError;

  SettingsProvider(this._storage, this._audio) {
    _settings = AppSettings(
      vibrationEnabled: _storage.vibrationEnabled,
      bellSound: _storage.bellSound,
      bellVolume: _storage.bellVolume,
      backgroundVolume: _storage.backgroundVolume,
      backgroundSound: _storage.backgroundSound,
    );
    _customSounds = _storage.getCustomSounds();

    // Apply persisted volumes immediately on startup.
    _audio.setBellVolume(_settings.bellVolume);
    _audio.setBackgroundVolume(_settings.backgroundVolume);
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  AppSettings get settings => _settings;
  bool get vibrationEnabled => _settings.vibrationEnabled;
  String get bellSound => _settings.bellSound;
  double get bellVolume => _settings.bellVolume;
  double get backgroundVolume => _settings.backgroundVolume;
  String? get backgroundSound => _settings.backgroundSound;
  List<CustomSound> get customSounds => List.unmodifiable(_customSounds);
  bool get importing => _importing;
  String? get importError => _importError;

  // ── Mutations ─────────────────────────────────────────────────────────────

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

  Future<void> setBellVolume(double value) async {
    _settings = _settings.copyWith(bellVolume: value);
    _audio.setBellVolume(value);
    await _storage.setBellVolume(value);
    notifyListeners();
  }

  Future<void> setBackgroundVolume(double value) async {
    _settings = _settings.copyWith(backgroundVolume: value);
    _audio.setBackgroundVolume(value);
    await _storage.setBackgroundVolume(value);
    notifyListeners();
  }

  /// null = no background sound, 'rain' = built-in rain loop.
  Future<void> setBackgroundSound(String? value) async {
    _settings = _settings.copyWith(backgroundSound: value);
    await _storage.setBackgroundSound(value);
    notifyListeners();
  }

  // ── Custom sound import ───────────────────────────────────────────────────

  Future<void> importSound() async {
    _importing = true;
    _importError = null;
    notifyListeners();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3'],
        allowMultiple: true,
        withData: false,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) {
        _importing = false;
        notifyListeners();
        return;
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final soundsDir = Directory('${docsDir.path}/custom_sounds');
      if (!soundsDir.existsSync()) soundsDir.createSync(recursive: true);

      for (final file in result.files) {
        final sourcePath = file.path;
        if (sourcePath == null) continue;

        final id = DateTime.now().microsecondsSinceEpoch.toString();
        final ext = file.extension ?? 'mp3';
        final destPath = '${soundsDir.path}/$id.$ext';

        await File(sourcePath).copy(destPath);

        final rawName = file.name
            .replaceAll(RegExp(r'\.mp3$', caseSensitive: false), '');
        final sound = CustomSound(id: id, name: rawName, filePath: destPath);

        await _storage.addCustomSound(sound);
        _customSounds.add(sound);
      }
    } catch (e) {
      _importError = 'Import failed: $e';
    }

    _importing = false;
    notifyListeners();
  }

  // ── Custom sound mutations ────────────────────────────────────────────────

  Future<void> deleteSound(String id) async {
    final sound = _customSounds.firstWhere((s) => s.id == id,
        orElse: () => throw StateError('Sound not found'));

    if (_settings.bellSound == id) {
      await setBellSound(AppSettings.bellSoundOptions.first);
    }

    try {
      final file = File(sound.filePath);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}

    await _storage.deleteCustomSound(id);
    _customSounds.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  Future<void> renameSound(String id, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    await _storage.renameCustomSound(id, trimmed);
    _customSounds = _customSounds
        .map((s) => s.id == id ? s.copyWith(name: trimmed) : s)
        .toList();
    notifyListeners();
  }

  Future<void> previewSound(CustomSound sound) async {
    await _audio.playFile(sound.filePath);
  }

  Future<void> previewBuiltIn(String key) async {
    await _audio.playBell(key);
  }
}
