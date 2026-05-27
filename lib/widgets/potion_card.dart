import 'package:flutter/material.dart';

import '../models/potion_definition.dart';
import '../models/potion_rarity.dart';
import 'rarity_badge.dart';

class PotionCard extends StatelessWidget {
  const PotionCard({
    super.key,
    required this.definition,
    required this.quantity,
    this.trailing,
    this.selectedCount = 0,
    this.expanded = false,
    this.onTap,
  });

  final PotionDefinition definition;
  final int quantity;
  final Widget? trailing;
  final int selectedCount;
  final bool expanded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final PotionRarityStyle rarityStyle = PotionRarityPalette.styleOf(
      definition.rarity,
    );
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isEpic = definition.rarity == PotionRarity.epic;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isEpic ? rarityStyle.border : colors.outlineVariant,
              width: isEpic ? 1.8 : 1,
            ),
            boxShadow: isEpic
                ? <BoxShadow>[
                    BoxShadow(
                      color: rarityStyle.base.withValues(alpha: 0.24),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool compact = constraints.maxWidth < 340;

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PotionIcon(rarityStyle: rarityStyle),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PotionSummary(
                              definition: definition,
                              quantity: quantity,
                              selectedCount: selectedCount,
                              expanded: expanded,
                              colors: colors,
                            ),
                          ),
                        ],
                      ),
                      if (trailing != null) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: trailing!,
                        ),
                      ],
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PotionIcon(rarityStyle: rarityStyle),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PotionSummary(
                        definition: definition,
                        quantity: quantity,
                        selectedCount: selectedCount,
                        expanded: expanded,
                        colors: colors,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 10),
                      trailing!,
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PotionSummary extends StatelessWidget {
  const _PotionSummary({
    required this.definition,
    required this.quantity,
    required this.selectedCount,
    required this.expanded,
    required this.colors,
  });

  final PotionDefinition definition;
  final int quantity;
  final int selectedCount;
  final bool expanded;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          definition.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 7),
        RarityBadge(rarity: definition.rarity),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoPill(label: 'Qty $quantity'),
            if (definition.priceGold != null)
              _InfoPill(label: '${definition.priceGold} Gold'),
            if (selectedCount > 0) _InfoPill(label: 'Selected $selectedCount'),
          ],
        ),
        if (expanded) ...[
          const SizedBox(height: 12),
          Divider(color: colors.outlineVariant),
          const SizedBox(height: 8),
          Text(
            definition.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          _ExpandedDetail(
            icon: Icons.auto_awesome,
            text: definition.effectSummary,
          ),
        ],
      ],
    );
  }
}

class _ExpandedDetail extends StatelessWidget {
  const _ExpandedDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _PotionIcon extends StatelessWidget {
  const _PotionIcon({required this.rarityStyle});

  final PotionRarityStyle rarityStyle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: rarityStyle.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: rarityStyle.border),
      ),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Icon(Icons.local_drink, color: rarityStyle.base, size: 28),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
