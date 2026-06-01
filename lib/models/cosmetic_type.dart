enum CosmeticType {
  hat,
  torso,
  weapon,
  frame;

  String get storageKey {
    return switch (this) {
      CosmeticType.hat => 'hat',
      CosmeticType.torso => 'torso',
      CosmeticType.weapon => 'weapon',
      CosmeticType.frame => 'frame',
    };
  }

  static CosmeticType? fromStorageKey(String value) {
    return switch (value) {
      'hat' => CosmeticType.hat,
      'torso' => CosmeticType.torso,
      'weapon' => CosmeticType.weapon,
      'frame' => CosmeticType.frame,
      _ => null,
    };
  }
}
