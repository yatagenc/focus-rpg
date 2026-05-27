import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database/app_database.dart';
import '../data/database/database_schema.dart';
import '../data/potion_catalog.dart';
import '../models/inventory_potion.dart';
import '../models/potion_definition.dart';
import '../models/potion_rarity.dart';

class InventoryService {
  InventoryService._({bool? useMemoryStore})
    : _useMemoryStore = useMemoryStore ?? kIsWeb;

  factory InventoryService.memory() {
    return InventoryService._(useMemoryStore: true);
  }

  static final InventoryService instance = InventoryService._();

  final bool _useMemoryStore;
  final Map<int, Map<String, int>> _memoryInventoryByProfile =
      <int, Map<String, int>>{};

  static const Map<String, int> _starterPotions = <String, int>{
    'bestkeeper_tonic': 1,
    'focus_philter': 1,
    'chronomancers_extract': 1,
    'phoenix_brew': 1,
  };

  Future<List<InventoryPotion>> getInventoryPotions({
    required int profileId,
  }) async {
    final Map<String, int> inventory = await _inventoryFor(profileId);
    return inventory.entries
        .where((MapEntry<String, int> entry) => entry.value > 0)
        .map(
          (MapEntry<String, int> entry) =>
              InventoryPotion(potionId: entry.key, quantity: entry.value),
        )
        .toList()
      ..sort(_compareInventoryPotions);
  }

  Future<InventoryMutationResult> addPotion({
    required int profileId,
    required String potionId,
    int amount = 1,
  }) async {
    final InventoryMutationResult capacityResult = await canAddPotion(
      profileId: profileId,
      potionId: potionId,
      amount: amount,
    );
    if (!capacityResult.success) {
      return capacityResult;
    }

    final Map<String, int> inventory = await _inventoryFor(profileId);
    await _setQuantity(
      profileId,
      potionId,
      (inventory[potionId] ?? 0) + amount,
    );
    return const InventoryMutationResult.success();
  }

  Future<InventoryMutationResult> removePotion({
    required int profileId,
    required String potionId,
    int amount = 1,
  }) async {
    if (amount <= 0) {
      return const InventoryMutationResult.failure(
        'Potion amount must be greater than zero.',
      );
    }

    final Map<String, int> inventory = await _inventoryFor(profileId);
    final int currentQuantity = inventory[potionId] ?? 0;
    if (currentQuantity < amount) {
      return const InventoryMutationResult.failure(
        'Not enough potions in inventory.',
      );
    }

    await _setQuantity(profileId, potionId, currentQuantity - amount);
    return const InventoryMutationResult.success();
  }

  Future<InventoryMutationResult> canAddPotion({
    required int profileId,
    required String potionId,
    int amount = 1,
  }) async {
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

    final int currentQuantity = (await _inventoryFor(profileId))[potionId] ?? 0;
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

  Future<InventoryMutationResult> consumeSelectedPotionsForSession({
    required int profileId,
    required List<String> selectedPotionIds,
  }) async {
    final PotionLoadoutValidationResult validation =
        validateSessionPotionLoadout(selectedPotionIds);
    if (!validation.isValid) {
      return InventoryMutationResult.failure(validation.message!);
    }

    final Map<String, int> requiredCounts = <String, int>{};
    for (final String potionId in selectedPotionIds) {
      requiredCounts[potionId] = (requiredCounts[potionId] ?? 0) + 1;
    }

    final Map<String, int> inventory = await _inventoryFor(profileId);
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
      await _setQuantity(
        profileId,
        entry.key,
        (inventory[entry.key] ?? 0) - entry.value,
      );
    }

    return const InventoryMutationResult.success();
  }

  Future<InventoryMutationResult> purchasePotion({
    required int profileId,
    required String potionId,
  }) async {
    final PotionDefinition definition = PotionCatalog.byId(potionId);
    if (!definition.isPurchasable) {
      return const InventoryMutationResult.failure(
        'Epic potions can only be earned as rewards.',
      );
    }

    return addPotion(profileId: profileId, potionId: potionId);
  }

  Future<Map<String, int>> _inventoryFor(int profileId) async {
    if (_useMemoryStore) {
      return _memoryInventoryByProfile.putIfAbsent(
        profileId,
        () => Map<String, int>.from(_starterPotions),
      );
    }

    final Database db = await AppDatabase.instance.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseSchema.profilePotionTable,
      columns: <String>['potion_id', 'quantity'],
      where: 'profile_id = ?',
      whereArgs: <Object?>[profileId],
    );

    if (rows.isEmpty) {
      await _insertStarterPotions(db, profileId);
      return Map<String, int>.from(_starterPotions);
    }

    return <String, int>{
      for (final Map<String, Object?> row in rows)
        row['potion_id'] as String: row['quantity'] as int,
    };
  }

  Future<void> _setQuantity(
    int profileId,
    String potionId,
    int quantity,
  ) async {
    if (_useMemoryStore) {
      final Map<String, int> inventory = await _inventoryFor(profileId);
      inventory[potionId] = quantity.clamp(0, 999999).toInt();
      return;
    }

    final Database db = await AppDatabase.instance.database;
    await db.insert(
      DatabaseSchema.profilePotionTable,
      <String, Object?>{
        'profile_id': profileId,
        'potion_id': potionId,
        'quantity': quantity.clamp(0, 999999).toInt(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _insertStarterPotions(Database db, int profileId) async {
    final Batch batch = db.batch();
    for (final MapEntry<String, int> entry in _starterPotions.entries) {
      batch.insert(
        DatabaseSchema.profilePotionTable,
        <String, Object?>{
          'profile_id': profileId,
          'potion_id': entry.key,
          'quantity': entry.value,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  static int _compareInventoryPotions(InventoryPotion a, InventoryPotion b) {
    final PotionDefinition left = PotionCatalog.byId(a.potionId);
    final PotionDefinition right = PotionCatalog.byId(b.potionId);
    final int rarityCompare = left.rarity.index.compareTo(right.rarity.index);
    if (rarityCompare != 0) {
      return rarityCompare;
    }
    return left.name.compareTo(right.name);
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
