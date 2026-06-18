class AppSettings {
  final bool vibrationEnabled;
  final String bellSound;

  const AppSettings({
    this.vibrationEnabled = true,
    this.bellSound = 'temple_bell',
  });

  AppSettings copyWith({
    bool? vibrationEnabled,
    String? bellSound,
  }) {
    return AppSettings(
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      bellSound: bellSound ?? this.bellSound,
    );
  }

  Map<String, dynamic> toMap() => {
        'vibrationEnabled': vibrationEnabled,
        'bellSound': bellSound,
      };

  factory AppSettings.fromMap(Map<String, dynamic> map) => AppSettings(
        vibrationEnabled: map['vibrationEnabled'] as bool? ?? true,
        bellSound: map['bellSound'] as String? ?? 'temple_bell',
      );

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
