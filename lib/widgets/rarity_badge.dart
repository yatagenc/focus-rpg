import 'package:flutter/material.dart';

import '../models/potion_rarity.dart';

class RarityBadge extends StatelessWidget {
  const RarityBadge({super.key, required this.rarity});

  final PotionRarity rarity;

  @override
  Widget build(BuildContext context) {
    final PotionRarityStyle style = PotionRarityPalette.styleOf(rarity);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          rarity.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: style.foreground,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
