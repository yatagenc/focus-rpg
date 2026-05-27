import '../models/avatar_equipment.dart';
import '../models/cosmetic_definition.dart';
import '../models/cosmetic_type.dart';

class CosmeticCatalog {
  const CosmeticCatalog._();

  static const int defaultHatId = 1001;
  static const int defaultTorsoId = 2001;
  static const int defaultWoodFrameId = 3001;

  static const List<CosmeticDefinition> cosmetics = <CosmeticDefinition>[
    CosmeticDefinition(
      cosmeticId: defaultHatId,
      name: 'Simple Cloth Hat',
      type: CosmeticType.hat,
      assetPath: 'assets/images/cosmetics/hats/default_hat.png',
      tier: 'default',
    ),
    CosmeticDefinition(
      cosmeticId: 1101,
      name: 'Hogwarts Sorting Hat',
      type: CosmeticType.hat,
      assetPath: 'assets/images/cosmetics/hats/mage_hogwarts_hat.png',
      tier: 'class',
      classRestriction: 'mage',
      priceGold: 120,
    ),
    CosmeticDefinition(
      cosmeticId: 1102,
      name: 'Crystal Wizard Hat',
      type: CosmeticType.hat,
      assetPath: 'assets/images/cosmetics/hats/mage_crystal_hat.png',
      tier: 'class',
      classRestriction: 'mage',
      priceGold: 160,
    ),
    CosmeticDefinition(
      cosmeticId: 1201,
      name: 'Gothic Knight Helm',
      type: CosmeticType.hat,
      assetPath: 'assets/images/cosmetics/hats/knight_gothic_helm.png',
      tier: 'class',
      classRestriction: 'knight',
      priceGold: 120,
    ),
    CosmeticDefinition(
      cosmeticId: 1202,
      name: 'Lionguard Knight Helm',
      type: CosmeticType.hat,
      assetPath: 'assets/images/cosmetics/hats/knight_lion_helm.png',
      tier: 'class',
      classRestriction: 'knight',
      priceGold: 160,
    ),
    CosmeticDefinition(
      cosmeticId: 1301,
      name: 'Mirkwood Elven Hood',
      type: CosmeticType.hat,
      assetPath: 'assets/images/cosmetics/hats/archer_elven_hood.png',
      tier: 'class',
      classRestriction: 'archer',
      priceGold: 120,
    ),
    CosmeticDefinition(
      cosmeticId: 1302,
      name: 'Crystal Scout Crown',
      type: CosmeticType.hat,
      assetPath: 'assets/images/cosmetics/hats/archer_crystal_crown.png',
      tier: 'class',
      classRestriction: 'archer',
      priceGold: 160,
    ),
    CosmeticDefinition(
      cosmeticId: 1401,
      name: "Ezio's White Hood",
      type: CosmeticType.hat,
      assetPath: 'assets/images/cosmetics/hats/thief_ezio_hood.png',
      tier: 'class',
      classRestriction: 'thief',
      priceGold: 120,
    ),
    CosmeticDefinition(
      cosmeticId: 1402,
      name: 'Rust Leather Skull Hood',
      type: CosmeticType.hat,
      assetPath: 'assets/images/cosmetics/hats/thief_rust_skull_hood.png',
      tier: 'class',
      classRestriction: 'thief',
      priceGold: 160,
    ),
    CosmeticDefinition(
      cosmeticId: defaultTorsoId,
      name: 'Plain Traveler Tunic',
      type: CosmeticType.torso,
      assetPath: 'assets/images/cosmetics/torso/default_torso.png',
      tier: 'default',
    ),
    CosmeticDefinition(
      cosmeticId: 2101,
      name: 'Hogwarts Robe',
      type: CosmeticType.torso,
      assetPath: 'assets/images/cosmetics/torso/mage_hogwarts_robe.png',
      tier: 'class',
      classRestriction: 'mage',
      priceGold: 180,
    ),
    CosmeticDefinition(
      cosmeticId: 2102,
      name: 'Crystal Wizard Robe',
      type: CosmeticType.torso,
      assetPath: 'assets/images/cosmetics/torso/mage_crystal_robe.png',
      tier: 'class',
      classRestriction: 'mage',
      priceGold: 220,
    ),
    CosmeticDefinition(
      cosmeticId: 2201,
      name: 'Gothic Plate Armor',
      type: CosmeticType.torso,
      assetPath: 'assets/images/cosmetics/torso/knight_gothic_plate.png',
      tier: 'class',
      classRestriction: 'knight',
      priceGold: 180,
    ),
    CosmeticDefinition(
      cosmeticId: 2202,
      name: 'Lionguard Plate Armor',
      type: CosmeticType.torso,
      assetPath: 'assets/images/cosmetics/torso/knight_lion_plate.png',
      tier: 'class',
      classRestriction: 'knight',
      priceGold: 220,
    ),
    CosmeticDefinition(
      cosmeticId: 2301,
      name: 'Legolas Elven Armor',
      type: CosmeticType.torso,
      assetPath: 'assets/images/cosmetics/torso/archer_elven_armor.png',
      tier: 'class',
      classRestriction: 'archer',
      priceGold: 180,
    ),
    CosmeticDefinition(
      cosmeticId: 2302,
      name: 'Gray Crystal Scout Armor',
      type: CosmeticType.torso,
      assetPath: 'assets/images/cosmetics/torso/archer_crystal_armor.png',
      tier: 'class',
      classRestriction: 'archer',
      priceGold: 220,
    ),
    CosmeticDefinition(
      cosmeticId: 2401,
      name: 'Auditore Robe',
      type: CosmeticType.torso,
      assetPath: 'assets/images/cosmetics/torso/thief_auditore_robe.png',
      tier: 'class',
      classRestriction: 'thief',
      priceGold: 180,
    ),
    CosmeticDefinition(
      cosmeticId: 2402,
      name: 'Rust Leather Skull Vest',
      type: CosmeticType.torso,
      assetPath: 'assets/images/cosmetics/torso/thief_rust_skull_vest.png',
      tier: 'class',
      classRestriction: 'thief',
      priceGold: 220,
    ),
    CosmeticDefinition(
      cosmeticId: defaultWoodFrameId,
      name: 'Wooden Profile Frame',
      type: CosmeticType.frame,
      assetPath: 'assets/images/cosmetics/frames/default_wood_frame.png',
      tier: 'wood',
    ),
    CosmeticDefinition(
      cosmeticId: 3002,
      name: 'Bronze Profile Frame',
      type: CosmeticType.frame,
      assetPath: 'assets/images/cosmetics/frames/bronze_frame.png',
      tier: 'bronze',
      unlockElo: 250,
      unlockRequirement: 'Reach 250 Elo.',
    ),
    CosmeticDefinition(
      cosmeticId: 3003,
      name: 'Silver Profile Frame',
      type: CosmeticType.frame,
      assetPath: 'assets/images/cosmetics/frames/silver_frame.png',
      tier: 'silver',
      unlockElo: 750,
      unlockRequirement: 'Reach 750 Elo.',
    ),
    CosmeticDefinition(
      cosmeticId: 3004,
      name: 'Gold Profile Frame',
      type: CosmeticType.frame,
      assetPath: 'assets/images/cosmetics/frames/gold_frame.png',
      tier: 'gold',
      unlockElo: 1500,
      unlockRequirement: 'Reach 1500 Elo.',
    ),
    CosmeticDefinition(
      cosmeticId: 3005,
      name: 'Platinum Profile Frame',
      type: CosmeticType.frame,
      assetPath: 'assets/images/cosmetics/frames/platinum_frame.png',
      tier: 'platinum',
      unlockElo: 3000,
      unlockRequirement: 'Reach 3000 Elo.',
    ),
    CosmeticDefinition(
      cosmeticId: 3006,
      name: 'Emerald Profile Frame',
      type: CosmeticType.frame,
      assetPath: 'assets/images/cosmetics/frames/emerald_frame.png',
      tier: 'emerald',
      unlockElo: 5000,
      unlockRequirement: 'Reach 5000 Elo.',
    ),
    CosmeticDefinition(
      cosmeticId: 3007,
      name: 'Diamond Profile Frame',
      type: CosmeticType.frame,
      assetPath: 'assets/images/cosmetics/frames/diamond_frame.png',
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
      'mage' => 'assets/images/avatars/icons/mage_icon.png',
      'knight' || 'warrior' => 'assets/images/avatars/icons/knight_icon.png',
      'archer' || 'ranger' => 'assets/images/avatars/icons/archer_icon.png',
      'thief' || 'rogue' => 'assets/images/avatars/icons/thief_icon.png',
      _ => 'assets/images/avatars/icons/knight_icon.png',
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

  static CosmeticDefinition defaultForType(CosmeticType type) {
    return switch (type) {
      CosmeticType.hat => byId(defaultHatId),
      CosmeticType.torso => byId(defaultTorsoId),
      CosmeticType.frame => byId(defaultWoodFrameId),
    };
  }

  static AvatarEquipment equipmentFromIds(Map<CosmeticType, int> equippedIds) {
    return AvatarEquipment(
      hat: _definitionOrDefault(CosmeticType.hat, equippedIds),
      torso: _definitionOrDefault(CosmeticType.torso, equippedIds),
      frame: _definitionOrDefault(CosmeticType.frame, equippedIds),
    );
  }

  static CosmeticDefinition _definitionOrDefault(
    CosmeticType type,
    Map<CosmeticType, int> equippedIds,
  ) {
    final int? cosmeticId = equippedIds[type];
    if (cosmeticId == null) {
      return defaultForType(type);
    }
    try {
      final CosmeticDefinition definition = byId(cosmeticId);
      return definition.type == type ? definition : defaultForType(type);
    } on ArgumentError {
      return defaultForType(type);
    }
  }
}
