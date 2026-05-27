import '../data/models/profile.dart';

class PlayerSave {
  const PlayerSave({
    required this.profileId,
    required this.playerClass,
    required this.level,
    required this.xp,
    required this.gold,
    required this.elo,
    required this.createdAt,
    this.lastPlayedAt,
    required this.totalStudyMinutes,
    required this.totalCompletedSessions,
    required this.streakDays,
    required this.lastStreakDate,
  });

  final int profileId;
  final String playerClass;
  final int level;
  final int xp;
  final int gold;
  final int elo;
  final String createdAt;
  final String? lastPlayedAt;
  final int totalStudyMinutes;
  final int totalCompletedSessions;
  final int streakDays;
  final String? lastStreakDate;

  factory PlayerSave.fromProfile(Profile profile) {
    return PlayerSave(
      profileId: profile.profileId,
      playerClass: profile.profileClass,
      level: profile.profileLevel,
      xp: profile.profileXp,
      gold: profile.profileGold,
      elo: profile.profileElo,
      createdAt: profile.profileCreatedAt,
      lastPlayedAt: profile.profileLastPlayedAt,
      totalStudyMinutes: profile.profileTotalStudyMinutes,
      totalCompletedSessions: profile.profileTotalCompletedSessions,
      streakDays: profile.profileStreakDays,
      lastStreakDate: profile.profileLastStreakDate,
    );
  }

  factory PlayerSave.fromMap(Map<String, Object?> map) {
    return PlayerSave(
      profileId: _readInt(map, 'profile_id'),
      playerClass: _readString(map, 'profile_class'),
      level: _readInt(map, 'profile_level', fallback: 1),
      xp: _readInt(map, 'profile_xp'),
      gold: _readInt(map, 'profile_gold'),
      elo: _readInt(map, 'profile_elo'),
      createdAt: _readString(map, 'profile_created_at'),
      lastPlayedAt: map['profile_last_played_at'] as String?,
      totalStudyMinutes: _readInt(map, 'profile_total_study_minutes'),
      totalCompletedSessions: _readInt(map, 'profile_total_completed_sessions'),
      streakDays: _readInt(map, 'profile_streak_days'),
      lastStreakDate: map['profile_last_streak_date'] as String?,
    );
  }

  PlayerSave copyWith({
    int? profileId,
    String? playerClass,
    int? level,
    int? xp,
    int? gold,
    int? elo,
    String? createdAt,
    String? lastPlayedAt,
    int? totalStudyMinutes,
    int? totalCompletedSessions,
    int? streakDays,
    String? lastStreakDate,
  }) {
    return PlayerSave(
      profileId: profileId ?? this.profileId,
      playerClass: playerClass ?? this.playerClass,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      gold: gold ?? this.gold,
      elo: elo ?? this.elo,
      createdAt: createdAt ?? this.createdAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      totalStudyMinutes: totalStudyMinutes ?? this.totalStudyMinutes,
      totalCompletedSessions:
          totalCompletedSessions ?? this.totalCompletedSessions,
      streakDays: streakDays ?? this.streakDays,
      lastStreakDate: lastStreakDate ?? this.lastStreakDate,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'profile_id': profileId,
      'profile_class': playerClass,
      'profile_level': level,
      'profile_xp': xp,
      'profile_gold': gold,
      'profile_elo': elo,
      'profile_created_at': createdAt,
      'profile_last_played_at': lastPlayedAt,
      'profile_total_study_minutes': totalStudyMinutes,
      'profile_total_completed_sessions': totalCompletedSessions,
      'profile_streak_days': streakDays,
      'profile_last_streak_date': lastStreakDate,
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
