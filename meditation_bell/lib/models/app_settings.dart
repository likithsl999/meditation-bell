// Sentinel used by copyWith to distinguish "not provided" from "explicitly null".
class _Absent {
  const _Absent();
}

const _absent = _Absent();

class AppSettings {
  final bool vibrationEnabled;
  final String bellSound;
  final double bellVolume;
  final double backgroundVolume;

  /// null  → no background sound
  /// 'rain' → built-in rain loop
  final String? backgroundSound;

  const AppSettings({
    this.vibrationEnabled = true,
    this.bellSound = 'bell',
    this.bellVolume = 1.0,
    this.backgroundVolume = 0.5,
    this.backgroundSound = 'rain',
  });

  AppSettings copyWith({
    bool? vibrationEnabled,
    String? bellSound,
    double? bellVolume,
    double? backgroundVolume,
    // Use Object? + sentinel so callers can pass null to clear the sound.
    Object? backgroundSound = _absent,
  }) {
    return AppSettings(
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      bellSound: bellSound ?? this.bellSound,
      bellVolume: bellVolume ?? this.bellVolume,
      backgroundVolume: backgroundVolume ?? this.backgroundVolume,
      backgroundSound: backgroundSound is _Absent
          ? this.backgroundSound
          : backgroundSound as String?,
    );
  }

  // ── Bell sounds ───────────────────────────────────────────────────────────

  /// Built-in bell sound asset keys (maps to assets/audio/<key>.mp3).
  static const List<String> bellSoundOptions = [
    'bell',
    'temple_bell',
    'singing_bowl',
    'soft_chime',
  ];

  static String bellSoundLabel(String key) {
    switch (key) {
      case 'bell':
        return 'Bell';
      case 'temple_bell':
        return 'Temple Bell';
      case 'singing_bowl':
        return 'Singing Bowl';
      case 'soft_chime':
        return 'Soft Chime';
      default:
        return 'Bell';
    }
  }

  // ── Background sounds ─────────────────────────────────────────────────────

  /// Built-in background sound options. null = none.
  static const List<String?> backgroundSoundOptions = [
    null,
    'rain',
  ];

  static String backgroundSoundLabel(String? key) {
    switch (key) {
      case 'rain':
        return 'Rain';
      default:
        return 'None';
    }
  }

  static IconInfo backgroundSoundIcon(String? key) {
    switch (key) {
      case 'rain':
        return const IconInfo(codePoint: 0xe54e, label: 'Rainy');
      default:
        return const IconInfo(codePoint: 0xe050, label: 'Block');
    }
  }
}

/// Lightweight struct returned by [AppSettings.backgroundSoundIcon].
class IconInfo {
  final int codePoint;
  final String label;
  const IconInfo({required this.codePoint, required this.label});
}
