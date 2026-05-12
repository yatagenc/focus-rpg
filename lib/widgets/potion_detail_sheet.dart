import 'package:flutter/material.dart';

import '../models/potion_definition.dart';
import '../models/potion_rarity.dart';
import '../services/inventory_service.dart';
import 'rarity_badge.dart';

Future<void> showPotionDetailSheet({
  required BuildContext context,
  required PotionDefinition definition,
  required int quantity,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      return PotionDetailSheet(definition: definition, quantity: quantity);
    },
  );
}

class PotionDetailSheet extends StatelessWidget {
  const PotionDetailSheet({
    super.key,
    required this.definition,
    required this.quantity,
  });

  final PotionDefinition definition;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final PotionRarityStyle rarityStyle = PotionRarityPalette.styleOf(
      definition.rarity,
    );
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isEpic = definition.rarity == PotionRarity.epic;
    final int? capacity = InventoryService.instance.getPotionCapacityByRarity(
      definition.rarity,
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isEpic ? rarityStyle.border : colors.outlineVariant,
              width: isEpic ? 1.6 : 1,
            ),
            boxShadow: isEpic
                ? <BoxShadow>[
                    BoxShadow(
                      color: rarityStyle.base.withValues(alpha: 0.25),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LargePotionIcon(rarityStyle: rarityStyle, isEpic: isEpic),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            definition.name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          RarityBadge(rarity: definition.rarity),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  definition.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.auto_awesome,
                  label: 'Effect',
                  value: definition.effectSummary,
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  icon: Icons.toll,
                  label: 'Cost',
                  value: definition.priceGold == null
                      ? 'Reward only'
                      : '${definition.priceGold} Gold',
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  icon: Icons.inventory_2,
                  label: 'Quantity',
                  value: '$quantity owned',
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  icon: Icons.all_inclusive,
                  label: 'Capacity',
                  value: capacity == null
                      ? 'Unlimited'
                      : '$quantity / $capacity per potion',
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LargePotionIcon extends StatelessWidget {
  const _LargePotionIcon({required this.rarityStyle, required this.isEpic});

  final PotionRarityStyle rarityStyle;
  final bool isEpic;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: rarityStyle.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: rarityStyle.border, width: isEpic ? 1.6 : 1),
      ),
      child: SizedBox(
        width: isEpic ? 70 : 62,
        height: isEpic ? 70 : 62,
        child: Icon(
          Icons.local_drink,
          color: rarityStyle.base,
          size: isEpic ? 42 : 36,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: colors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
