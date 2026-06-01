import '../data/models/equipped_cosmetic.dart';
import 'cosmetic_definition.dart';
import 'cosmetic_type.dart';

class AvatarEquipment {
  const AvatarEquipment({
    required this.hat,
    required this.torso,
    required this.weapon,
    required this.frame,
  });

  final CosmeticDefinition hat;
  final CosmeticDefinition torso;
  final CosmeticDefinition weapon;
  final CosmeticDefinition frame;

  List<CosmeticDefinition> get layers => <CosmeticDefinition>[
    torso,
    hat,
    weapon,
    frame,
  ];

  static Map<CosmeticType, int> equippedIdByType(
    List<EquippedCosmetic> equippedCosmetics,
  ) {
    final Map<CosmeticType, int> equippedIds = <CosmeticType, int>{};
    for (final EquippedCosmetic equipped in equippedCosmetics) {
      final CosmeticType? type = CosmeticType.fromStorageKey(equipped.slotType);
      if (type != null) {
        equippedIds[type] = equipped.cosmeticId;
      }
    }
    return equippedIds;
  }
}
