class OwnedCosmetic {
  const OwnedCosmetic({
    required this.profileId,
    required this.cosmeticId,
    required this.unlockedAt,
  });

  final int profileId;
  final int cosmeticId;
  final String unlockedAt;

  factory OwnedCosmetic.fromMap(Map<String, Object?> map) {
    return OwnedCosmetic(
      profileId: map['profile_id'] as int,
      cosmeticId: map['cosmetic_id'] as int,
      unlockedAt: map['unlocked_at'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'profile_id': profileId,
      'cosmetic_id': cosmeticId,
      'unlocked_at': unlockedAt,
    };
  }
}
