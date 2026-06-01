import '../models/avatar_equipment.dart';
import '../models/cosmetic_definition.dart';
import '../models/cosmetic_type.dart';

class CosmeticCatalog {
  const CosmeticCatalog._();

  static const int defaultHatId = 1001;
  static const int defaultTorsoId = 2001;
  static const int defaultMageWeaponId = 4101;
  static const int defaultKnightWeaponId = 4201;
  static const int defaultArcherWeaponId = 4301;
  static const int defaultThiefWeaponId = 4401;
  static const int defaultWoodFrameId = 3001;

  static const List<CosmeticDefinition> cosmetics = <CosmeticDefinition>[
    CosmeticDefinition(
      cosmeticId: defaultHatId,
      name: 'Simple Cloth Hat',
      type: CosmeticType.hat,
      assetPath: 'assets/images/cosmetics/layers/hats/default_hat.png',
      tier: 'default',
    ),
    CosmeticDefinition(
      cosmeticId: 1101,
      name: 'Hogwarts Sorting Hat',
      type: CosmeticType.hat,
      assetPath: 'assets/images/cosmetics/layers/hats/mage_hogwarts_hat.png',
      tier: 'class',
      classRestriction: 'mage',
      priceGold: 120,
    ),
    CosmeticDefinition(
      cosmeticId: 1102,
      name: 'Crystal Wizard Hat',
      type: CosmeticType.hat,
      assetPath: 'assets/images/cosmetics/layers/hats/mage_crystal_hat.png',
      tier: 'class',
      classRestriction: 'mage',
      priceGold: 160,
    ),
    CosmeticDefinition(
      cosmeticId: 1201,
      name: 'Gothic Knight Helm',
      type: CosmeticType.hat,
      assetPath: 'assets/images/cosmetics/layers/hats/knight_gothic_helm.png',
      tier: 'class',
      classRestriction: 'knight',
      priceGold: 120,
    ),
    CosmeticDefinition(
      cosmeticId: 1202,
      name: 'Lionguard Knight Helm',
      type: CosmeticType.hat,
      assetPath: 'assets/images/cosmetics/layers/hats/knight_lion_helm.png',
      tier: 'class',
      classRestriction: 'knight',
      priceGold: 160,
    ),
    CosmeticDefinition(
      cosmeticId: 1301,
      name: 'Mirkwood Elven Hood',
      type: CosmeticType.hat,
      assetPath: 'assets/images/cosmetics/layers/hats/archer_elven_hood.png',
      tier: 'class',
      classRestriction: 'archer',
      priceGold: 120,
    ),
    CosmeticDefinition(
      cosmeticId: 1302,
      name: 'Crystal Scout Crown',
      type: CosmeticType.hat,
      assetPath: 'assets/images/cosmetics/layers/hats/archer_crystal_crown.png',
      tier: 'class',
      classRestriction: 'archer',
      priceGold: 160,
    ),
    CosmeticDefinition(
      cosmeticId: 1401,
      name: "Ezio's White Hood",
      type: CosmeticType.hat,
      assetPath: 'assets/images/cosmetics/layers/hats/thief_ezio_hood.png',
      tier: 'class',
      classRestriction: 'thief',
      priceGold: 120,
    ),
    CosmeticDefinition(
      cosmeticId: 1402,
      name: 'Rust Leather Skull Hood',
      type: CosmeticType.hat,
      assetPath:
          'assets/images/cosmetics/layers/hats/thief_rust_skull_hood.png',
      tier: 'class',
      classRestriction: 'thief',
      priceGold: 160,
    ),
    CosmeticDefinition(
      cosmeticId: defaultTorsoId,
      name: 'Plain Traveler Tunic',
      type: CosmeticType.torso,
      assetPath: 'assets/images/cosmetics/layers/torso/default_torso.png',
      tier: 'default',
    ),
    CosmeticDefinition(
      cosmeticId: 2101,
      name: 'Hogwarts Robe',
      type: CosmeticType.torso,
      assetPath: 'assets/images/cosmetics/layers/torso/mage_hogwarts_robe.png',
      tier: 'class',
      classRestriction: 'mage',
      priceGold: 180,
    ),
    CosmeticDefinition(
      cosmeticId: 2102,
      name: 'Crystal Wizard Robe',
      type: CosmeticType.torso,
      assetPath: 'assets/images/cosmetics/layers/torso/mage_crystal_robe.png',
      tier: 'class',
      classRestriction: 'mage',
      priceGold: 220,
    ),
    CosmeticDefinition(
      cosmeticId: 2201,
      name: 'Gothic Plate Armor',
      type: CosmeticType.torso,
      assetPath: 'assets/images/cosmetics/layers/torso/knight_gothic_plate.png',
      tier: 'class',
      classRestriction: 'knight',
      priceGold: 180,
    ),
    CosmeticDefinition(
      cosmeticId: 2202,
      name: 'Lionguard Plate Armor',
      type: CosmeticType.torso,
      assetPath: 'assets/images/cosmetics/layers/torso/knight_lion_plate.png',
      tier: 'class',
      classRestriction: 'knight',
      priceGold: 220,
    ),
    CosmeticDefinition(
      cosmeticId: 2301,
      name: 'Legolas Elven Armor',
      type: CosmeticType.torso,
      assetPath: 'assets/images/cosmetics/layers/torso/archer_elven_armor.png',
      tier: 'class',
      classRestriction: 'archer',
      priceGold: 180,
    ),
    CosmeticDefinition(
      cosmeticId: 2302,
      name: 'Gray Crystal Scout Armor',
      type: CosmeticType.torso,
      assetPath:
          'assets/images/cosmetics/layers/torso/archer_crystal_armor.png',
      tier: 'class',
      classRestriction: 'archer',
      priceGold: 220,
    ),
    CosmeticDefinition(
      cosmeticId: 2401,
      name: 'Auditore Robe',
      type: CosmeticType.torso,
      assetPath: 'assets/images/cosmetics/layers/torso/thief_auditore_robe.png',
      tier: 'class',
      classRestriction: 'thief',
      priceGold: 180,
    ),
    CosmeticDefinition(
      cosmeticId: 2402,
      name: 'Rust Leather Skull Vest',
      type: CosmeticType.torso,
      assetPath:
          'assets/images/cosmetics/layers/torso/thief_rust_skull_vest.png',
      tier: 'class',
      classRestriction: 'thief',
      priceGold: 220,
    ),
    CosmeticDefinition(
      cosmeticId: defaultMageWeaponId,
      name: 'Mage Staff',
      type: CosmeticType.weapon,
      assetPath:
          'assets/images/cosmetics/layers/weapons/default_mage_weapon.png',
      tier: 'default',
      classRestriction: 'mage',
    ),
    CosmeticDefinition(
      cosmeticId: defaultKnightWeaponId,
      name: 'Knight Sword',
      type: CosmeticType.weapon,
      assetPath:
          'assets/images/cosmetics/layers/weapons/default_knight_weapon.png',
      tier: 'default',
      classRestriction: 'knight',
    ),
    CosmeticDefinition(
      cosmeticId: defaultArcherWeaponId,
      name: 'Archer Bow',
      type: CosmeticType.weapon,
      assetPath:
          'assets/images/cosmetics/layers/weapons/default_archer_weapon.png',
      tier: 'default',
      classRestriction: 'archer',
    ),
    CosmeticDefinition(
      cosmeticId: defaultThiefWeaponId,
      name: 'Thief Dagger',
      type: CosmeticType.weapon,
      assetPath:
          'assets/images/cosmetics/layers/weapons/default_thief_weapon.png',
      tier: 'default',
      classRestriction: 'thief',
    ),
    CosmeticDefinition(
      cosmeticId: defaultWoodFrameId,
      name: 'Wooden Profile Frame',
      type: CosmeticType.frame,
      assetPath: 'assets/images/cosmetics/layers/frames/default_wood_frame.png',
      tier: 'wood',
    ),
    CosmeticDefinition(
      cosmeticId: 3002,
      name: 'Bronze Profile Frame',
      type: CosmeticType.frame,
      assetPath: 'assets/images/cosmetics/layers/frames/bronze_frame.png',
      tier: 'bronze',
      unlockElo: 250,
      unlockRequirement: 'Reach 250 Elo.',
    ),
    CosmeticDefinition(
      cosmeticId: 3003,
      name: 'Silver Profile Frame',
      type: CosmeticType.frame,
      assetPath: 'assets/images/cosmetics/layers/frames/silver_frame.png',
      tier: 'silver',
      unlockElo: 750,
      unlockRequirement: 'Reach 750 Elo.',
    ),
    CosmeticDefinition(
      cosmeticId: 3004,
      name: 'Gold Profile Frame',
      type: CosmeticType.frame,
      assetPath: 'assets/images/cosmetics/layers/frames/gold_frame.png',
      tier: 'gold',
      unlockElo: 1500,
      unlockRequirement: 'Reach 1500 Elo.',
    ),
    CosmeticDefinition(
      cosmeticId: 3005,
      name: 'Platinum Profile Frame',
      type: CosmeticType.frame,
      assetPath: 'assets/images/cosmetics/layers/frames/platinum_frame.png',
      tier: 'platinum',
      unlockElo: 3000,
      unlockRequirement: 'Reach 3000 Elo.',
    ),
    CosmeticDefinition(
      cosmeticId: 3006,
      name: 'Emerald Profile Frame',
      type: CosmeticType.frame,
      assetPath: 'assets/images/cosmetics/layers/frames/emerald_frame.png',
      tier: 'emerald',
      unlockElo: 5000,
      unlockRequirement: 'Reach 5000 Elo.',
    ),
    CosmeticDefinition(
      cosmeticId: 3007,
      name: 'Diamond Profile Frame',
      type: CosmeticType.frame,
      assetPath: 'assets/images/cosmetics/layers/frames/diamond_frame.png',
      tier: 'diamond',
      unlockElo: 8000,
      unlockRequirement: 'Reach 8000 Elo.',
    ),
  ];

  static const List<int> defaultCosmeticIds = <int>[
    defaultHatId,
    defaultTorsoId,
    defaultWoodFrameId,
  ];

  static List<CosmeticDefinition> get frames => cosmetics
      .where(
        (CosmeticDefinition cosmetic) => cosmetic.type == CosmeticType.frame,
      )
      .toList(growable: false);

  static List<CosmeticDefinition> shopItemsForClass({
    required String playerClass,
    required CosmeticType type,
  }) {
    return cosmetics
        .where(
          (CosmeticDefinition cosmetic) =>
              cosmetic.type == type &&
              cosmetic.isPurchasable &&
              cosmetic.isAvailableForClass(playerClass),
        )
        .toList(growable: false);
  }

  static List<CosmeticDefinition> framesUnlockedAtElo(int elo) {
    return frames
        .where((CosmeticDefinition frame) => frame.unlockElo <= elo)
        .toList(growable: false);
  }

  static String baseAvatarPathForClass(String playerClass) {
    return switch (playerClass.toLowerCase()) {
      'mage' => 'assets/images/avatars/base/default_mage_full.png',
      'knight' ||
      'warrior' => 'assets/images/avatars/base/default_knight_full.png',
      'archer' ||
      'ranger' => 'assets/images/avatars/base/default_archer_full.png',
      'thief' || 'rogue' => 'assets/images/avatars/base/default_thief_full.png',
      _ => 'assets/images/avatars/base/default_knight_full.png',
    };
  }

  static String iconAvatarPathForClass(String playerClass) {
    return switch (playerClass.toLowerCase()) {
      'mage' => 'assets/images/avatars/base/bare_mage_icon.png',
      'knight' ||
      'warrior' => 'assets/images/avatars/base/bare_knight_icon.png',
      'archer' || 'ranger' => 'assets/images/avatars/base/bare_archer_icon.png',
      'thief' || 'rogue' => 'assets/images/avatars/base/bare_thief_icon.png',
      _ => 'assets/images/avatars/base/bare_knight_icon.png',
    };
  }

  static CosmeticDefinition byId(int cosmeticId) {
    return cosmetics.firstWhere(
      (CosmeticDefinition cosmetic) => cosmetic.cosmeticId == cosmeticId,
      orElse: () => throw ArgumentError.value(
        cosmeticId,
        'cosmeticId',
        'Unknown cosmetic id',
      ),
    );
  }

  static CosmeticDefinition defaultForType(
    CosmeticType type, {
    String? playerClass,
  }) {
    return switch (type) {
      CosmeticType.hat => byId(defaultHatIdForClass(playerClass ?? '')),
      CosmeticType.torso => byId(defaultTorsoIdForClass(playerClass ?? '')),
      CosmeticType.weapon => byId(defaultWeaponIdForClass(playerClass ?? '')),
      CosmeticType.frame => byId(defaultWoodFrameId),
    };
  }

  static int defaultHatIdForClass(String playerClass) {
    return switch (playerClass.toLowerCase()) {
      'mage' => 1101,
      'knight' || 'warrior' => 1201,
      'archer' || 'ranger' => 1301,
      'thief' || 'rogue' => 1401,
      _ => defaultHatId,
    };
  }

  static int defaultTorsoIdForClass(String playerClass) {
    return switch (playerClass.toLowerCase()) {
      'mage' => 2101,
      'knight' || 'warrior' => 2201,
      'archer' || 'ranger' => 2301,
      'thief' || 'rogue' => 2401,
      _ => defaultTorsoId,
    };
  }

  static int defaultWeaponIdForClass(String playerClass) {
    return switch (playerClass.toLowerCase()) {
      'mage' => defaultMageWeaponId,
      'knight' || 'warrior' => defaultKnightWeaponId,
      'archer' || 'ranger' => defaultArcherWeaponId,
      'thief' || 'rogue' => defaultThiefWeaponId,
      _ => defaultKnightWeaponId,
    };
  }

  static List<int> defaultCosmeticIdsForClass(String playerClass) {
    return <int>[
      defaultHatIdForClass(playerClass),
      defaultTorsoIdForClass(playerClass),
      defaultWeaponIdForClass(playerClass),
      defaultWoodFrameId,
    ];
  }

  static Map<CosmeticType, int> defaultEquipmentIdsForClass(
    String playerClass,
  ) {
    return <CosmeticType, int>{
      CosmeticType.hat: defaultHatIdForClass(playerClass),
      CosmeticType.torso: defaultTorsoIdForClass(playerClass),
      CosmeticType.weapon: defaultWeaponIdForClass(playerClass),
      CosmeticType.frame: defaultWoodFrameId,
    };
  }

  static AvatarEquipment equipmentFromIds({
    required String playerClass,
    required Map<CosmeticType, int> equippedIds,
  }) {
    return AvatarEquipment(
      hat: _definitionOrDefault(CosmeticType.hat, equippedIds, playerClass),
      torso: _definitionOrDefault(CosmeticType.torso, equippedIds, playerClass),
      weapon: _definitionOrDefault(
        CosmeticType.weapon,
        equippedIds,
        playerClass,
      ),
      frame: _definitionOrDefault(CosmeticType.frame, equippedIds, playerClass),
    );
  }

  static CosmeticDefinition _definitionOrDefault(
    CosmeticType type,
    Map<CosmeticType, int> equippedIds,
    String playerClass,
  ) {
    final int? cosmeticId = equippedIds[type];
    if (cosmeticId == null) {
      return defaultForType(type, playerClass: playerClass);
    }
    if (type == CosmeticType.hat && cosmeticId == defaultHatId) {
      return defaultForType(type, playerClass: playerClass);
    }
    if (type == CosmeticType.torso && cosmeticId == defaultTorsoId) {
      return defaultForType(type, playerClass: playerClass);
    }
    try {
      final CosmeticDefinition definition = byId(cosmeticId);
      return definition.type == type
          ? definition
          : defaultForType(type, playerClass: playerClass);
    } on ArgumentError {
      return defaultForType(type, playerClass: playerClass);
    }
  }
}
