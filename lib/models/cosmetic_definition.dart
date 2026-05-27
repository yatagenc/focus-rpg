import 'cosmetic_type.dart';

class CosmeticDefinition {
  const CosmeticDefinition({
    required this.cosmeticId,
    required this.name,
    required this.type,
    required this.assetPath,
    required this.tier,
    this.classRestriction = 'all',
    this.priceGold = 0,
    this.unlockElo = 0,
    this.unlockRequirement,
  });

  final int cosmeticId;
  final String name;
  final CosmeticType type;
  final String assetPath;
  final String tier;
  final String classRestriction;
  final int priceGold;
  final int unlockElo;
  final String? unlockRequirement;

  bool get isPurchasable => priceGold > 0;

  bool isAvailableForClass(String playerClass) {
    final String normalizedRestriction = classRestriction.toLowerCase();
    final String normalizedClass = playerClass.toLowerCase();
    return normalizedRestriction == 'all' ||
        normalizedRestriction == normalizedClass ||
        (normalizedRestriction == 'knight' && normalizedClass == 'warrior') ||
        (normalizedRestriction == 'archer' && normalizedClass == 'ranger') ||
        (normalizedRestriction == 'thief' && normalizedClass == 'rogue');
  }
}
