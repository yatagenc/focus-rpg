import 'package:flutter_test/flutter_test.dart';
import 'package:focus_rpg/data/cosmetic_catalog.dart';
import 'package:focus_rpg/models/cosmetic_type.dart';

void main() {
  group('CosmeticCatalog', () {
    test('maps classes to base avatar assets', () {
      expect(
        CosmeticCatalog.baseAvatarPathForClass('Mage'),
        'assets/images/avatars/base/default_mage_full.png',
      );
      expect(
        CosmeticCatalog.baseAvatarPathForClass('Knight'),
        'assets/images/avatars/base/default_knight_full.png',
      );
      expect(
        CosmeticCatalog.baseAvatarPathForClass('Archer'),
        'assets/images/avatars/base/default_archer_full.png',
      );
      expect(
        CosmeticCatalog.baseAvatarPathForClass('Thief'),
        'assets/images/avatars/base/default_thief_full.png',
      );
    });

    test('maps classes to framed avatar icon assets', () {
      expect(
        CosmeticCatalog.iconAvatarPathForClass('Mage'),
        'assets/images/avatars/icons/mage_icon.png',
      );
      expect(
        CosmeticCatalog.iconAvatarPathForClass('Knight'),
        'assets/images/avatars/icons/knight_icon.png',
      );
      expect(
        CosmeticCatalog.iconAvatarPathForClass('Archer'),
        'assets/images/avatars/icons/archer_icon.png',
      );
      expect(
        CosmeticCatalog.iconAvatarPathForClass('Thief'),
        'assets/images/avatars/icons/thief_icon.png',
      );
    });

    test('returns default equipment when no equipped ids are present', () {
      final equipment = CosmeticCatalog.equipmentFromIds(
        const <CosmeticType, int>{},
      );

      expect(equipment.hat.cosmeticId, CosmeticCatalog.defaultHatId);
      expect(equipment.torso.cosmeticId, CosmeticCatalog.defaultTorsoId);
      expect(equipment.frame.cosmeticId, CosmeticCatalog.defaultWoodFrameId);
    });

    test('defines rank frame tiers', () {
      final frameTiers = CosmeticCatalog.cosmetics
          .where((cosmetic) => cosmetic.type == CosmeticType.frame)
          .map((cosmetic) => cosmetic.tier);

      expect(
        frameTiers,
        containsAll(<String>[
          'wood',
          'bronze',
          'silver',
          'gold',
          'platinum',
          'emerald',
          'diamond',
        ]),
      );
    });

    test('unlocks frame tiers by Elo threshold', () {
      final unlockedAtZero = CosmeticCatalog.framesUnlockedAtElo(
        0,
      ).map((frame) => frame.cosmeticId);
      final unlockedAtGold = CosmeticCatalog.framesUnlockedAtElo(
        1500,
      ).map((frame) => frame.cosmeticId);

      expect(unlockedAtZero, contains(CosmeticCatalog.defaultWoodFrameId));
      expect(unlockedAtZero, isNot(contains(3002)));
      expect(unlockedAtGold, containsAll(<int>[3001, 3002, 3003, 3004]));
      expect(unlockedAtGold, isNot(contains(3005)));
    });

    test('filters purchasable shop cosmetics by class and type', () {
      final mageHeads = CosmeticCatalog.shopItemsForClass(
        playerClass: 'Mage',
        type: CosmeticType.hat,
      );
      final mageTorso = CosmeticCatalog.shopItemsForClass(
        playerClass: 'Mage',
        type: CosmeticType.torso,
      );
      final knightHeads = CosmeticCatalog.shopItemsForClass(
        playerClass: 'Knight',
        type: CosmeticType.hat,
      );

      expect(mageHeads.map((cosmetic) => cosmetic.cosmeticId), <int>[
        1101,
        1102,
      ]);
      expect(mageTorso.map((cosmetic) => cosmetic.cosmeticId), <int>[
        2101,
        2102,
      ]);
      expect(knightHeads.map((cosmetic) => cosmetic.cosmeticId), <int>[
        1201,
        1202,
      ]);
      for (final cosmetic in mageHeads) {
        expect(cosmetic.type, CosmeticType.hat);
        expect(cosmetic.classRestriction, 'mage');
        expect(cosmetic.isPurchasable, isTrue);
      }
    });
  });
}
