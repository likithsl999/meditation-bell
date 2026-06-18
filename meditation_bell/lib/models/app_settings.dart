class AppSettings {
  final bool vibrationEnabled;
  final String bellSound;
  final double bellVolume;
  final double backgroundVolume;

  const AppSettings({
    this.vibrationEnabled = true,
    this.bellSound = 'temple_bell',
    this.bellVolume = 1.0,
    this.backgroundVolume = 0.0,
  });

  AppSettings copyWith({
    bool? vibrationEnabled,
    String? bellSound,
    double? bellVolume,
    double? backgroundVolume,
  }) {
    return AppSettings(
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      bellSound: bellSound ?? this.bellSound,
      bellVolume: bellVolume ?? this.bellVolume,
      backgroundVolume: backgroundVolume ?? this.backgroundVolume,
    );
  }

  static const List<String> bellSoundOptions = [
    'temple_bell',
    'singing_bowl',
    'soft_chime',
  ];

  static String bellSoundLabel(String key) {
    switch (key) {
      case 'temple_bell':
        return 'Temple Bell';
      case 'singing_bowl':
        return 'Singing Bowl';
      case 'soft_chime':
        return 'Soft Chime';
      default:
        return 'Temple Bell';
    }
  }
}
