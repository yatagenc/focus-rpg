import 'potion_effect_type.dart';
import 'potion_rarity.dart';

class PotionDefinition {
  const PotionDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.effectSummary,
    required this.rarity,
    required this.effectType,
    required this.effectValue,
    required this.durationType,
    required this.iconPath,
    required this.isPurchasable,
    this.priceGold,
  });

  final String id;
  final String name;
  final String description;
  final String effectSummary;
  final PotionRarity rarity;
  final PotionEffectType effectType;
  final double effectValue;
  final String durationType;
  final String iconPath;
  final bool isPurchasable;
  final int? priceGold;
}
