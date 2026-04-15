class GameSession {
  const GameSession({
    this.sessionId,
    required this.profileId,
    required this.sessionType,
    required this.startedAt,
    this.endedAt,
    this.durationMinutes = 0,
    this.completed = false,
    this.xpEarned = 0,
    this.goldEarned = 0,
  });

  final int? sessionId;
  final int profileId;
  final String sessionType;
  final String startedAt;
  final String? endedAt;
  final int durationMinutes;
  final bool completed;
  final int xpEarned;
  final int goldEarned;

  factory GameSession.fromMap(Map<String, Object?> map) {
    return GameSession(
      sessionId: map['session_id'] as int,
      profileId: map['profile_id'] as int,
      sessionType: map['session_type'] as String,
      startedAt: map['started_at'] as String,
      endedAt: map['ended_at'] as String?,
      durationMinutes: map['duration_minutes'] as int,
      completed: (map['completed'] as int) == 1,
      xpEarned: map['xp_earned'] as int,
      goldEarned: map['gold_earned'] as int,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'session_id': sessionId,
      'profile_id': profileId,
      'session_type': sessionType,
      'started_at': startedAt,
      'ended_at': endedAt,
      'duration_minutes': durationMinutes,
      'completed': completed ? 1 : 0,
      'xp_earned': xpEarned,
      'gold_earned': goldEarned,
    };
  }
}
