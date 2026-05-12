import '../models/potion_definition.dart';
import '../models/potion_effect_type.dart';
import '../models/potion_rarity.dart';

class PotionCatalog {
  const PotionCatalog._();

  static const List<PotionDefinition> potions = <PotionDefinition>[
    PotionDefinition(
      id: 'bestkeeper_tonic',
      name: 'Bestkeeper Tonic',
      description:
          'A calming tonic favored by exhausted scholars and overworked apprentices.',
      effectSummary: '+3 minute break duration',
      rarity: PotionRarity.common,
      effectType: PotionEffectType.breakExtension,
      effectValue: 3,
      durationType: 'session',
      iconPath: '',
      isPurchasable: true,
      priceGold: 50,
    ),
    PotionDefinition(
      id: 'steadfast_brew',
      name: 'Steadfast Brew',
      description:
          'A bitter herbal mixture that softens the impact of unfortunate events.',
      effectSummary: 'Reduces negative event effects.',
      rarity: PotionRarity.common,
      effectType: PotionEffectType.eventPenaltyReduction,
      effectValue: 1,
      durationType: 'session',
      iconPath: '',
      isPurchasable: true,
      priceGold: 40,
    ),
    PotionDefinition(
      id: 'scholars_fortune',
      name: "Scholar's Fortune",
      description:
          'A favored draught among ambitious students seeking greater rewards.',
      effectSummary: 'Increases event success rewards.',
      rarity: PotionRarity.common,
      effectType: PotionEffectType.eventRewardBoost,
      effectValue: 1,
      durationType: 'session',
      iconPath: '',
      isPurchasable: true,
      priceGold: 50,
    ),
    PotionDefinition(
      id: 'focus_philter',
      name: 'Focus Philter',
      description:
          'A clear liquid that sharpens concentration and accelerates learning.',
      effectSummary: 'Increases session XP gain by 10%.',
      rarity: PotionRarity.common,
      effectType: PotionEffectType.xpBoost,
      effectValue: 0.10,
      durationType: 'session',
      iconPath: '',
      isPurchasable: true,
      priceGold: 45,
    ),
    PotionDefinition(
      id: 'coinkeeper_flask',
      name: 'Coinkeeper Flask',
      description:
          'A small enchanted flask carried by treasure hunters and clever merchants.',
      effectSummary: 'Increases gold earned from sessions by 15%.',
      rarity: PotionRarity.common,
      effectType: PotionEffectType.goldBoost,
      effectValue: 0.15,
      durationType: 'session',
      iconPath: '',
      isPurchasable: true,
      priceGold: 45,
    ),
    PotionDefinition(
      id: 'lucid_draught',
      name: 'Lucid Draught',
      description: 'Helps maintain mental clarity during unstable focus periods.',
      effectSummary: 'Reduces idle punishment sensitivity for one session.',
      rarity: PotionRarity.common,
      effectType: PotionEffectType.idlePenaltyReduction,
      effectValue: 1,
      durationType: 'session',
      iconPath: '',
      isPurchasable: true,
      priceGold: 35,
    ),
    PotionDefinition(
      id: 'quickstart_elixir',
      name: 'Quickstart Elixir',
      description:
          'A stimulating mixture designed to ignite productive mornings.',
      effectSummary: 'First completed session of the day grants bonus XP.',
      rarity: PotionRarity.common,
      effectType: PotionEffectType.dailyFirstSessionBonus,
      effectValue: 1,
      durationType: 'dailyFirstSession',
      iconPath: '',
      isPurchasable: true,
      priceGold: 40,
    ),
    PotionDefinition(
      id: 'gamblers_essence',
      name: "Gambler's Essence",
      description:
          'A dangerous concoction embraced by risk-takers and desperate scholars.',
      effectSummary:
          'Doubles session rewards, but failure penalties are also doubled.',
      rarity: PotionRarity.rare,
      effectType: PotionEffectType.rewardRisk,
      effectValue: 2,
      durationType: 'session',
      iconPath: '',
      isPurchasable: true,
      priceGold: 120,
    ),
    PotionDefinition(
      id: 'chronomancers_extract',
      name: "Chronomancer's Extract",
      description:
          "A strange shimmering liquid said to distort one's perception of time.",
      effectSummary:
          'Extends focus session duration by 10 minutes and increases rewards proportionally.',
      rarity: PotionRarity.rare,
      effectType: PotionEffectType.focusDurationExtension,
      effectValue: 10,
      durationType: 'session',
      iconPath: '',
      isPurchasable: true,
      priceGold: 110,
    ),
    PotionDefinition(
      id: 'streakkeeper_serum',
      name: 'Streakkeeper Serum',
      description:
          'A prized serum carried by those terrified of losing momentum.',
      effectSummary: 'One failed session will not break your streak.',
      rarity: PotionRarity.rare,
      effectType: PotionEffectType.streakProtection,
      effectValue: 1,
      durationType: 'singleUse',
      iconPath: '',
      isPurchasable: true,
      priceGold: 150,
    ),
    PotionDefinition(
      id: 'merchants_tonic',
      name: "Merchant's Tonic",
      description: 'A favorite among traveling traders and bargain hunters.',
      effectSummary: 'Discounts all shop items by 20% for one day.',
      rarity: PotionRarity.rare,
      effectType: PotionEffectType.shopDiscount,
      effectValue: 0.20,
      durationType: 'day',
      iconPath: '',
      isPurchasable: true,
      priceGold: 130,
    ),
    PotionDefinition(
      id: 'overmind_elixir',
      name: 'Overmind Elixir',
      description:
          'A forbidden alchemical masterpiece that pushes the mind beyond safe limits.',
      effectSummary:
          'Greatly increases XP and gold rewards, but disables breaks during the session.',
      rarity: PotionRarity.epic,
      effectType: PotionEffectType.overmind,
      effectValue: 1,
      durationType: 'session',
      iconPath: '',
      isPurchasable: false,
      priceGold: 300,
    ),
    PotionDefinition(
      id: 'phoenix_brew',
      name: 'Phoenix Brew',
      description:
          'A legendary restorative mixture associated with rebirth and recovery.',
      effectSummary: 'Negates all penalties from the next failed event.',
      rarity: PotionRarity.epic,
      effectType: PotionEffectType.failureProtection,
      effectValue: 1,
      durationType: 'singleUse',
      iconPath: '',
      isPurchasable: false,
      priceGold: 280,
    ),
    PotionDefinition(
      id: 'destiny_draught',
      name: 'Destiny Draught',
      description:
          'An unpredictable potion whispered about in old academic myths.',
      effectSummary: 'Greatly increases the chance of triggering rare events.',
      rarity: PotionRarity.epic,
      effectType: PotionEffectType.rareEventChance,
      effectValue: 1,
      durationType: 'session',
      iconPath: '',
      isPurchasable: false,
      priceGold: 320,
    ),
  ];

  static PotionDefinition byId(String id) {
    return potions.firstWhere(
      (PotionDefinition potion) => potion.id == id,
      orElse: () => throw ArgumentError.value(id, 'id', 'Unknown potion id'),
    );
  }
}
