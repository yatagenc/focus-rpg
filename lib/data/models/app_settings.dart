class AppSettings {
  const AppSettings({
    required this.darkMode,
    required this.musicEnabled,
    required this.sfxEnabled,
    required this.musicVolume,
    required this.sfxVolume,
    required this.updatedAt,
  });

  factory AppSettings.defaults() {
    return AppSettings(
      darkMode: true,
      musicEnabled: true,
      sfxEnabled: true,
      musicVolume: 0.15,
      sfxVolume: 0.55,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  factory AppSettings.fromMap(Map<String, Object?> map) {
    return AppSettings(
      darkMode: (map['dark_mode'] as int) == 1,
      musicEnabled: (map['music_enabled'] as int) == 1,
      sfxEnabled: (map['sfx_enabled'] as int) == 1,
      musicVolume: (map['music_volume'] as num).toDouble(),
      sfxVolume: (map['sfx_volume'] as num).toDouble(),
      updatedAt: map['updated_at'] as String,
    );
  }

  final bool darkMode;
  final bool musicEnabled;
  final bool sfxEnabled;
  final double musicVolume;
  final double sfxVolume;
  final String updatedAt;

  AppSettings copyWith({
    bool? darkMode,
    bool? musicEnabled,
    bool? sfxEnabled,
    double? musicVolume,
    double? sfxVolume,
    String? updatedAt,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'settings_id': 1,
      'dark_mode': darkMode ? 1 : 0,
      'music_enabled': musicEnabled ? 1 : 0,
      'sfx_enabled': sfxEnabled ? 1 : 0,
      'music_volume': musicVolume.clamp(0, 1).toDouble(),
      'sfx_volume': sfxVolume.clamp(0, 1).toDouble(),
      'updated_at': updatedAt,
    };
  }
}
