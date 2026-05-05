import '../data/models/profile.dart';

class PlayerSave {
  const PlayerSave({
    required this.profileId,
    required this.playerClass,
    required this.level,
    required this.xp,
    required this.gold,
    required this.createdAt,
    this.lastPlayedAt,
    required this.totalStudyMinutes,
    required this.totalCompletedSessions,
  });

  final int profileId;
  final String playerClass;
  final int level;
  final int xp;
  final int gold;
  final String createdAt;
  final String? lastPlayedAt;
  final int totalStudyMinutes;
  final int totalCompletedSessions;

  factory PlayerSave.fromProfile(Profile profile) {
    return PlayerSave(
      profileId: profile.profileId,
      playerClass: profile.profileClass,
      level: profile.profileLevel,
      xp: profile.profileXp,
      gold: profile.profileGold,
      createdAt: profile.profileCreatedAt,
      lastPlayedAt: profile.profileLastPlayedAt,
      totalStudyMinutes: profile.profileTotalStudyMinutes,
      totalCompletedSessions: profile.profileTotalCompletedSessions,
    );
  }

  factory PlayerSave.fromMap(Map<String, Object?> map) {
    return PlayerSave(
      profileId: _readInt(map, 'profile_id'),
      playerClass: _readString(map, 'profile_class'),
      level: _readInt(map, 'profile_level', fallback: 1),
      xp: _readInt(map, 'profile_xp'),
      gold: _readInt(map, 'profile_gold'),
      createdAt: _readString(map, 'profile_created_at'),
      lastPlayedAt: map['profile_last_played_at'] as String?,
      totalStudyMinutes: _readInt(map, 'profile_total_study_minutes'),
      totalCompletedSessions: _readInt(map, 'profile_total_completed_sessions'),
    );
  }

  PlayerSave copyWith({
    int? profileId,
    String? playerClass,
    int? level,
    int? xp,
    int? gold,
    String? createdAt,
    String? lastPlayedAt,
    int? totalStudyMinutes,
    int? totalCompletedSessions,
  }) {
    return PlayerSave(
      profileId: profileId ?? this.profileId,
      playerClass: playerClass ?? this.playerClass,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      gold: gold ?? this.gold,
      createdAt: createdAt ?? this.createdAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      totalStudyMinutes: totalStudyMinutes ?? this.totalStudyMinutes,
      totalCompletedSessions:
          totalCompletedSessions ?? this.totalCompletedSessions,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'profile_id': profileId,
      'profile_class': playerClass,
      'profile_level': level,
      'profile_xp': xp,
      'profile_gold': gold,
      'profile_created_at': createdAt,
      'profile_last_played_at': lastPlayedAt,
      'profile_total_study_minutes': totalStudyMinutes,
      'profile_total_completed_sessions': totalCompletedSessions,
    };
  }

  static int _readInt(
    Map<String, Object?> map,
    String key, {
    int fallback = 0,
  }) {
    final Object? value = map[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return fallback;
  }

  static String _readString(
    Map<String, Object?> map,
    String key, {
    String fallback = '',
  }) {
    final Object? value = map[key];
    if (value is String) {
      return value;
    }
    return fallback;
  }
}
