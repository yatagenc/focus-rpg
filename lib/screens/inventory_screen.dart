import 'package:flutter/material.dart';

import '../data/potion_catalog.dart';
import '../models/inventory_potion.dart';
import '../models/potion_definition.dart';
import '../models/potion_rarity.dart';
import '../services/inventory_service.dart';
import '../widgets/potion_card.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  int? _profileId;
  PotionRarity? _rarityFilter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profileId ??= ModalRoute.of(context)?.settings.arguments as int?;
  }

  @override
  Widget build(BuildContext context) {
    final int? profileId = _profileId;

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: profileId == null
          ? const Center(child: Text('Profile not found.'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: _InventoryFilters(
                    selectedRarity: _rarityFilter,
                    onChanged: (PotionRarity? rarity) {
                      setState(() {
                        _rarityFilter = rarity;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _PotionList(
                    profileId: profileId,
                    rarityFilter: _rarityFilter,
                  ),
                ),
              ],
            ),
    );
  }
}

class _InventoryFilters extends StatelessWidget {
  const _InventoryFilters({
    required this.selectedRarity,
    required this.onChanged,
  });

  final PotionRarity? selectedRarity;
  final ValueChanged<PotionRarity?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: selectedRarity == null,
            onSelected: (_) => onChanged(null),
          ),
          const SizedBox(width: 8),
          for (final PotionRarity rarity in PotionRarity.values) ...[
            FilterChip(
              label: Text(rarity.label),
              selected: selectedRarity == rarity,
              onSelected: (_) => onChanged(rarity),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _PotionList extends StatefulWidget {
  const _PotionList({required this.profileId, this.rarityFilter});

  final int profileId;
  final PotionRarity? rarityFilter;

  @override
  State<_PotionList> createState() => _PotionListState();
}

class _PotionListState extends State<_PotionList> {
  String? _expandedPotionId;

  @override
  Widget build(BuildContext context) {
    final InventoryService service = InventoryService.instance;
    final Map<String, int> quantities = <String, int>{
      for (final InventoryPotion potion in service.getInventoryPotions(
        profileId: widget.profileId,
      ))
        potion.potionId: potion.quantity,
    };
    final List<PotionDefinition> definitions = PotionCatalog.potions
        .where(
          (PotionDefinition potion) =>
              widget.rarityFilter == null ||
              potion.rarity == widget.rarityFilter,
        )
        .where((PotionDefinition potion) => (quantities[potion.id] ?? 0) > 0)
        .toList();

    if (definitions.isEmpty) {
      return const Center(child: Text('No potions in this tab.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: definitions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final PotionDefinition definition = definitions[index];
        return PotionCard(
          definition: definition,
          quantity: quantities[definition.id] ?? 0,
          expanded: _expandedPotionId == definition.id,
          onTap: () {
            setState(() {
              _expandedPotionId = _expandedPotionId == definition.id
                  ? null
                  : definition.id;
            });
          },
        );
      },
    );
  }
}
