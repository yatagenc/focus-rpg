import '../data/potion_catalog.dart';
import '../models/inventory_potion.dart';
import '../models/potion_definition.dart';
import '../models/potion_rarity.dart';

class InventoryService {
  InventoryService._();

  static final InventoryService instance = InventoryService._();

  final Map<int, Map<String, int>> _inventoryByProfile =
      <int, Map<String, int>>{};

  List<InventoryPotion> getInventoryPotions({required int profileId}) {
    final Map<String, int> inventory = _inventoryFor(profileId);
    return inventory.entries
        .where((MapEntry<String, int> entry) => entry.value > 0)
        .map(
          (MapEntry<String, int> entry) =>
              InventoryPotion(potionId: entry.key, quantity: entry.value),
        )
        .toList()
      ..sort((InventoryPotion a, InventoryPotion b) {
        final PotionDefinition left = PotionCatalog.byId(a.potionId);
        final PotionDefinition right = PotionCatalog.byId(b.potionId);
        final int rarityCompare = left.rarity.index.compareTo(
          right.rarity.index,
        );
        if (rarityCompare != 0) {
          return rarityCompare;
        }
        return left.name.compareTo(right.name);
      });
  }

  InventoryMutationResult addPotion({
    required int profileId,
    required String potionId,
    int amount = 1,
  }) {
    final InventoryMutationResult capacityResult = canAddPotion(
      profileId: profileId,
      potionId: potionId,
      amount: amount,
    );
    if (!capacityResult.success) {
      return capacityResult;
    }

    final Map<String, int> inventory = _inventoryFor(profileId);
    inventory[potionId] = (inventory[potionId] ?? 0) + amount;
    return const InventoryMutationResult.success();
  }

  InventoryMutationResult removePotion({
    required int profileId,
    required String potionId,
    int amount = 1,
  }) {
    if (amount <= 0) {
      return const InventoryMutationResult.failure(
        'Potion amount must be greater than zero.',
      );
    }

    final Map<String, int> inventory = _inventoryFor(profileId);
    final int currentQuantity = inventory[potionId] ?? 0;
    if (currentQuantity < amount) {
      return const InventoryMutationResult.failure(
        'Not enough potions in inventory.',
      );
    }

    final int nextQuantity = currentQuantity - amount;
    if (nextQuantity == 0) {
      inventory.remove(potionId);
    } else {
      inventory[potionId] = nextQuantity;
    }
    return const InventoryMutationResult.success();
  }

  InventoryMutationResult canAddPotion({
    required int profileId,
    required String potionId,
    int amount = 1,
  }) {
    if (amount <= 0) {
      return const InventoryMutationResult.failure(
        'Potion amount must be greater than zero.',
      );
    }

    final PotionDefinition definition = PotionCatalog.byId(potionId);
    final int? capacity = getPotionCapacityByRarity(definition.rarity);
    if (capacity == null) {
      return const InventoryMutationResult.success();
    }

    final int currentQuantity = _inventoryFor(profileId)[potionId] ?? 0;
    if (currentQuantity + amount > capacity) {
      return InventoryMutationResult.failure(
        'Inventory capacity reached for ${definition.rarity.label} potions.',
      );
    }

    return const InventoryMutationResult.success();
  }

  int? getPotionCapacityByRarity(PotionRarity rarity) {
    switch (rarity) {
      case PotionRarity.common:
        return 3;
      case PotionRarity.rare:
        return 2;
      case PotionRarity.epic:
        return null;
    }
  }

  PotionLoadoutValidationResult validateSessionPotionLoadout(
    List<String> selectedPotionIds,
  ) {
    int commonCount = 0;
    int rareCount = 0;
    int epicCount = 0;

    for (final String potionId in selectedPotionIds) {
      final PotionDefinition definition = PotionCatalog.byId(potionId);
      switch (definition.rarity) {
        case PotionRarity.common:
          commonCount += 1;
          break;
        case PotionRarity.rare:
          rareCount += 1;
          break;
        case PotionRarity.epic:
          epicCount += 1;
          break;
      }
    }

    if (commonCount > 2) {
      return const PotionLoadoutValidationResult.invalid(
        'You can only use up to 2 Common potions.',
      );
    }
    if (rareCount > 3) {
      return const PotionLoadoutValidationResult.invalid(
        'You can only use up to 3 Rare potions.',
      );
    }
    if (epicCount > 1) {
      return const PotionLoadoutValidationResult.invalid(
        'Only 1 Epic potion can be used per session.',
      );
    }
    if (commonCount > 0 && rareCount > 1) {
      return const PotionLoadoutValidationResult.invalid(
        'Common potions can only be combined with 1 Rare potion.',
      );
    }

    return const PotionLoadoutValidationResult.valid();
  }

  InventoryMutationResult consumeSelectedPotionsForSession({
    required int profileId,
    required List<String> selectedPotionIds,
  }) {
    final PotionLoadoutValidationResult validation =
        validateSessionPotionLoadout(selectedPotionIds);
    if (!validation.isValid) {
      return InventoryMutationResult.failure(validation.message!);
    }

    final Map<String, int> requiredCounts = <String, int>{};
    for (final String potionId in selectedPotionIds) {
      requiredCounts[potionId] = (requiredCounts[potionId] ?? 0) + 1;
    }

    final Map<String, int> inventory = _inventoryFor(profileId);
    for (final MapEntry<String, int> entry in requiredCounts.entries) {
      final int available = inventory[entry.key] ?? 0;
      if (available < entry.value) {
        final PotionDefinition definition = PotionCatalog.byId(entry.key);
        return InventoryMutationResult.failure(
          'Not enough ${definition.name} in inventory.',
        );
      }
    }

    for (final MapEntry<String, int> entry in requiredCounts.entries) {
      final int nextQuantity = (inventory[entry.key] ?? 0) - entry.value;
      if (nextQuantity == 0) {
        inventory.remove(entry.key);
      } else {
        inventory[entry.key] = nextQuantity;
      }
    }

    return const InventoryMutationResult.success();
  }

  InventoryMutationResult purchasePotion({
    required int profileId,
    required String potionId,
  }) {
    final PotionDefinition definition = PotionCatalog.byId(potionId);
    if (!definition.isPurchasable) {
      return const InventoryMutationResult.failure(
        'Epic potions can only be earned as rewards.',
      );
    }

    return addPotion(profileId: profileId, potionId: potionId);
  }

  Map<String, int> _inventoryFor(int profileId) {
    return _inventoryByProfile.putIfAbsent(
      profileId,
      () => <String, int>{
        'bestkeeper_tonic': 1,
        'focus_philter': 1,
        'chronomancers_extract': 1,
        'phoenix_brew': 1,
      },
    );
  }
}

class InventoryMutationResult {
  const InventoryMutationResult._({required this.success, this.message});

  const InventoryMutationResult.success() : this._(success: true);

  const InventoryMutationResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String? message;
}

class PotionLoadoutValidationResult {
  const PotionLoadoutValidationResult._({required this.isValid, this.message});

  const PotionLoadoutValidationResult.valid() : this._(isValid: true);

  const PotionLoadoutValidationResult.invalid(String message)
    : this._(isValid: false, message: message);

  final bool isValid;
  final String? message;
}
