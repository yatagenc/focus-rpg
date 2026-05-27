enum CosmeticType {
  hat,
  torso,
  frame;

  String get storageKey {
    return switch (this) {
      CosmeticType.hat => 'hat',
      CosmeticType.torso => 'torso',
      CosmeticType.frame => 'frame',
    };
  }

  static CosmeticType? fromStorageKey(String value) {
    return switch (value) {
      'hat' => CosmeticType.hat,
      'torso' => CosmeticType.torso,
      'frame' => CosmeticType.frame,
      _ => null,
    };
  }
}
