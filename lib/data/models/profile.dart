class Profile {
  const Profile({
    required this.profileId,
    required this.profileClass,
    required this.profileXp,
    required this.profileLevel,
    required this.profileGold,
    required this.profileCreatedAt,
    required this.profileLastPlayedAt,
    required this.profileTotalStudyMinutes,
    required this.profileTotalCompletedSessions,
  });

  final int profileId;
  final String profileClass;
  final int profileXp;
  final int profileLevel;
  final int profileGold;
  final String profileCreatedAt;
  final String? profileLastPlayedAt;
  final int profileTotalStudyMinutes;
  final int profileTotalCompletedSessions;

  factory Profile.fromMap(Map<String, Object?> map) {
    return Profile(
      profileId: map['profile_id'] as int,
      profileClass: map['profile_class'] as String,
      profileXp: map['profile_xp'] as int,
      profileLevel: map['profile_level'] as int,
      profileGold: map['profile_gold'] as int,
      profileCreatedAt: map['profile_created_at'] as String,
      profileLastPlayedAt: map['profile_last_played_at'] as String?,
      profileTotalStudyMinutes: map['profile_total_study_minutes'] as int,
      profileTotalCompletedSessions:
          map['profile_total_completed_sessions'] as int,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'profile_id': profileId,
      'profile_class': profileClass,
      'profile_xp': profileXp,
      'profile_level': profileLevel,
      'profile_gold': profileGold,
      'profile_created_at': profileCreatedAt,
      'profile_last_played_at': profileLastPlayedAt,
      'profile_total_study_minutes': profileTotalStudyMinutes,
      'profile_total_completed_sessions': profileTotalCompletedSessions,
    };
  }
}
