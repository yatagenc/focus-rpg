import 'package:flutter/material.dart';

enum PotionRarity {
  common,
  rare,
  epic;

  String get label {
    switch (this) {
      case PotionRarity.common:
        return 'Common';
      case PotionRarity.rare:
        return 'Rare';
      case PotionRarity.epic:
        return 'Epic';
    }
  }
}

class PotionRarityStyle {
  const PotionRarityStyle({
    required this.base,
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color base;
  final Color background;
  final Color foreground;
  final Color border;
}

class PotionRarityPalette {
  const PotionRarityPalette._();

  static PotionRarityStyle styleOf(PotionRarity rarity) {
    switch (rarity) {
      case PotionRarity.common:
        return const PotionRarityStyle(
          base: Color(0xFF7A8794),
          background: Color(0xFFE8EDF2),
          foreground: Color(0xFF26313B),
          border: Color(0xFF9AA8B5),
        );
      case PotionRarity.rare:
        return const PotionRarityStyle(
          base: Color(0xFF2563EB),
          background: Color(0xFFE4EEFF),
          foreground: Color(0xFF123A89),
          border: Color(0xFF75A2F8),
        );
      case PotionRarity.epic:
        return const PotionRarityStyle(
          base: Color(0xFF9D174D),
          background: Color(0xFFFFE4F0),
          foreground: Color(0xFF5F0F2E),
          border: Color(0xFFF0A3C1),
        );
    }
  }
}
