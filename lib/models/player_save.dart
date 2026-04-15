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
}
