import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../data/potion_catalog.dart';
import '../models/inventory_potion.dart';
import '../models/potion_definition.dart';
import '../services/inventory_service.dart';
import '../views/focus_session_page.dart';
import '../widgets/potion_card.dart';
import '../widgets/potion_detail_sheet.dart';
import '../widgets/selected_potion_loadout.dart';

class PotionSelectionScreen extends StatefulWidget {
  const PotionSelectionScreen({super.key});

  @override
  State<PotionSelectionScreen> createState() => _PotionSelectionScreenState();
}

class _PotionSelectionScreenState extends State<PotionSelectionScreen> {
  final InventoryService _inventoryService = InventoryService.instance;
  final List<String> _selectedPotionIds = <String>[];

  int? _profileId;
  Future<List<InventoryPotion>>? _inventoryFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profileId == null) {
      _profileId = ModalRoute.of(context)?.settings.arguments as int?;
      final int? profileId = _profileId;
      if (profileId != null) {
        _inventoryFuture = _inventoryService.getInventoryPotions(
          profileId: profileId,
        );
      }
    }
  }

  void _togglePotion(String potionId, Map<String, int> inventoryCounts) {
    final int available = inventoryCounts[potionId] ?? 0;
    final int selected = _selectedPotionIds
        .where((String selectedId) => selectedId == potionId)
        .length;

    if (selected >= available) {
      _showFeedback('Not enough potions in inventory.');
      return;
    }

    final List<String> nextSelection = <String>[
      ..._selectedPotionIds,
      potionId,
    ];
    final PotionLoadoutValidationResult validation = _inventoryService
        .validateSessionPotionLoadout(nextSelection);

    if (!validation.isValid) {
      _showFeedback(validation.message ?? 'Invalid potion loadout.');
      return;
    }

    setState(() {
      _selectedPotionIds.add(potionId);
    });
  }

  void _removePotion(String potionId) {
    final int index = _selectedPotionIds.lastIndexOf(potionId);
    if (index == -1) {
      return;
    }

    setState(() {
      _selectedPotionIds.removeAt(index);
    });
  }

  void _startSession() {
    final int? profileId = _profileId;
    if (profileId == null) {
      return;
    }

    final PotionLoadoutValidationResult validation = _inventoryService
        .validateSessionPotionLoadout(_selectedPotionIds);
    if (!validation.isValid) {
      _showFeedback(validation.message ?? 'Invalid potion loadout.');
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.focusSession,
      arguments: FocusSessionArguments(
        profileId: profileId,
        selectedPotionIds: List<String>.unmodifiable(_selectedPotionIds),
      ),
    );
  }

  Map<String, int> _inventoryCounts(List<InventoryPotion> potions) {
    return <String, int>{
      for (final InventoryPotion potion in potions)
        potion.potionId: potion.quantity,
    };
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final int? profileId = _profileId;

    return Scaffold(
      appBar: AppBar(title: const Text('Session Preparation')),
      body: profileId == null
          ? const Center(child: Text('Profile not found.'))
          : FutureBuilder<List<InventoryPotion>>(
              future: _inventoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                final Map<String, int> quantities = _inventoryCounts(
                  snapshot.data ?? const <InventoryPotion>[],
                );
                final List<PotionDefinition> ownedPotions = PotionCatalog
                    .potions
                    .where(
                      (PotionDefinition potion) =>
                          (quantities[potion.id] ?? 0) > 0,
                    )
                    .toList();

                return SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: SelectedPotionLoadout(
                          selectedPotionIds: _selectedPotionIds,
                          onRemove: _removePotion,
                        ),
                      ),
                      Expanded(
                        child: ownedPotions.isEmpty
                            ? const Center(child: Text('No potions available.'))
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: ownedPotions.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final PotionDefinition definition =
                                      ownedPotions[index];
                                  final int selectedCount = _selectedPotionIds
                                      .where(
                                        (String potionId) =>
                                            potionId == definition.id,
                                      )
                                      .length;

                                  return PotionCard(
                                    definition: definition,
                                    quantity: quantities[definition.id] ?? 0,
                                    selectedCount: selectedCount,
                                    onTap: () => showPotionDetailSheet(
                                      context: context,
                                      definition: definition,
                                      quantity: quantities[definition.id] ?? 0,
                                    ),
                                    trailing: IconButton.filledTonal(
                                      tooltip: 'Select',
                                      onPressed: () => _togglePotion(
                                        definition.id,
                                        quantities,
                                      ),
                                      icon: const Icon(Icons.add),
                                    ),
                                  );
                                },
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton.icon(
                            onPressed: _startSession,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Session'),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
