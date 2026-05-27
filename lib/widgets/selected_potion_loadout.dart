import 'package:flutter/material.dart';

import '../data/potion_catalog.dart';
import '../models/potion_definition.dart';

class SelectedPotionLoadout extends StatelessWidget {
  const SelectedPotionLoadout({
    super.key,
    required this.selectedPotionIds,
    this.onRemove,
  });

  final List<String> selectedPotionIds;
  final ValueChanged<String>? onRemove;

  @override
  Widget build(BuildContext context) {
    final Map<String, int> counts = <String, int>{};
    for (final String potionId in selectedPotionIds) {
      counts[potionId] = (counts[potionId] ?? 0) + 1;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected Loadout',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (counts.isEmpty)
              Text(
                'No potions selected',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: counts.entries.map((MapEntry<String, int> entry) {
                  final PotionDefinition definition = PotionCatalog.byId(
                    entry.key,
                  );
                  return InputChip(
                    avatar: const Icon(Icons.local_drink, size: 18),
                    label: Text('${definition.name} x${entry.value}'),
                    onDeleted: onRemove == null
                        ? null
                        : () => onRemove!(entry.key),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
