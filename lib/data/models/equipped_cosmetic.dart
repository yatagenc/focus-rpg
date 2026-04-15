class EquippedCosmetic {
  const EquippedCosmetic({
    required this.profileId,
    required this.slotType,
    required this.cosmeticId,
    required this.equippedAt,
  });

  final int profileId;
  final String slotType;
  final int cosmeticId;
  final String equippedAt;

  factory EquippedCosmetic.fromMap(Map<String, Object?> map) {
    return EquippedCosmetic(
      profileId: map['profile_id'] as int,
      slotType: map['slot_type'] as String,
      cosmeticId: map['cosmetic_id'] as int,
      equippedAt: map['equipped_at'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'profile_id': profileId,
      'slot_type': slotType,
      'cosmetic_id': cosmeticId,
      'equipped_at': equippedAt,
    };
  }
}
