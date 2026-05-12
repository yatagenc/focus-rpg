import 'package:flutter/material.dart';

import '../data/potion_catalog.dart';
import '../models/inventory_potion.dart';
import '../models/player_save.dart';
import '../models/potion_definition.dart';
import '../services/inventory_service.dart';
import '../services/save_service.dart';
import '../widgets/potion_card.dart';
import '../widgets/potion_detail_sheet.dart';

class PotionShopPage extends StatefulWidget {
  const PotionShopPage({super.key});

  @override
  State<PotionShopPage> createState() => _PotionShopPageState();
}

class _PotionShopPageState extends State<PotionShopPage> {
  final SaveService _saveService = SaveService();
  final InventoryService _inventoryService = InventoryService.instance;

  int? _profileId;
  late Future<PlayerSave?> _saveFuture;
  final Map<String, int> _cart = <String, int>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profileId != null) {
      return;
    }

    _profileId = ModalRoute.of(context)?.settings.arguments as int?;
    _saveFuture = _saveService.getSaveById(_profileId ?? -1);
  }

  Future<void> _buyCart() async {
    final int? profileId = _profileId;
    if (profileId == null || _cart.isEmpty) {
      return;
    }

    final PlayerSave? save = await _saveFuture;
    final int totalGold = _cartTotalGold();
    if (save == null || save.gold < totalGold) {
      _showFeedback('Not enough gold.');
      return;
    }

    for (final MapEntry<String, int> entry in _cart.entries) {
      final InventoryMutationResult capacityResult = _inventoryService
          .canAddPotion(
            profileId: profileId,
            potionId: entry.key,
            amount: entry.value,
          );
      if (!capacityResult.success) {
        _showFeedback(capacityResult.message ?? 'Inventory capacity reached.');
        return;
      }
    }

    try {
      await _saveService.spendGold(profileId: profileId, amount: totalGold);
      for (final MapEntry<String, int> entry in _cart.entries) {
        final InventoryMutationResult result = _inventoryService.addPotion(
          profileId: profileId,
          potionId: entry.key,
          amount: entry.value,
        );
        if (!result.success) {
          _showFeedback(result.message ?? 'Could not buy potion.');
          return;
        }
      }

      _showFeedback('Selected potions added to inventory.');
      setState(() {
        _cart.clear();
        _saveFuture = _saveService.getSaveById(profileId);
      });
    } catch (error) {
      _showFeedback(error.toString());
    }
  }

  void _addToCart({
    required PotionDefinition definition,
    required PlayerSave? save,
  }) {
    final int? profileId = _profileId;
    final int? priceGold = definition.priceGold;
    if (profileId == null || priceGold == null) {
      return;
    }

    final int nextCartAmount = (_cart[definition.id] ?? 0) + 1;
    final InventoryMutationResult capacityResult = _inventoryService
        .canAddPotion(
          profileId: profileId,
          potionId: definition.id,
          amount: nextCartAmount,
        );
    if (!capacityResult.success) {
      _showFeedback(capacityResult.message ?? 'Inventory capacity reached.');
      return;
    }

    setState(() {
      _cart[definition.id] = nextCartAmount;
    });
  }

  void _clearCart() {
    setState(_cart.clear);
  }

  int _cartTotalGold() {
    int total = 0;
    for (final MapEntry<String, int> entry in _cart.entries) {
      total += (PotionCatalog.byId(entry.key).priceGold ?? 0) * entry.value;
    }
    return total;
  }

  int _cartItemCount() {
    return _cart.values.fold<int>(0, (int total, int value) => total + value);
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Map<String, int> _inventoryCounts(int profileId) {
    return <String, int>{
      for (final InventoryPotion potion
          in _inventoryService.getInventoryPotions(profileId: profileId))
        potion.potionId: potion.quantity,
    };
  }

  @override
  Widget build(BuildContext context) {
    final int? profileId = _profileId;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/potionshop1.png', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xAA000000),
                  Color(0x33000000),
                  Color(0x77000000),
                  Color(0xEE000000),
                ],
                stops: [0, 0.28, 0.58, 1],
              ),
            ),
          ),
          SafeArea(
            child: profileId == null
                ? const Center(child: Text('Profile not found.'))
                : FutureBuilder<PlayerSave?>(
                    future: _saveFuture,
                    builder: (context, snapshot) {
                      final PlayerSave? save = snapshot.data;
                      final Map<String, int> quantities = _inventoryCounts(
                        profileId,
                      );
                      final List<PotionDefinition> purchasablePotions =
                          PotionCatalog.potions
                              .where(
                                (PotionDefinition potion) =>
                                    potion.isPurchasable,
                              )
                              .toList();

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final double panelWidth =
                              (constraints.maxWidth *
                                      (constraints.maxWidth >= 700
                                          ? 0.46
                                          : 0.62))
                                  .clamp(260.0, 380.0);
                          return Stack(
                            children: [
                              Positioned(
                                left: 16,
                                top: 18,
                                child: Row(
                                  children: [
                                    _BackButton(
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    const SizedBox(width: 8),
                                    _ShopTitle(
                                      title: 'Potions',
                                      subtitle: 'The Bitter Bloom',
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                right: 14,
                                top: 20,
                                child: _GoldPill(gold: save?.gold),
                              ),
                              Positioned(
                                left: 0,
                                top: 110,
                                bottom: 18,
                                child: SizedBox(
                                  width: panelWidth + 26,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.44,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                      border: Border.all(
                                        color: const Color(0x66F3D49C),
                                      ),
                                    ),
                                    child:
                                        snapshot.connectionState !=
                                            ConnectionState.done
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : Column(
                                            children: [
                                              Expanded(
                                                child: ListView.separated(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                        10,
                                                        12,
                                                        10,
                                                        10,
                                                      ),
                                                  itemCount:
                                                      purchasablePotions.length,
                                                  separatorBuilder: (_, _) =>
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                  itemBuilder: (context, index) {
                                                    final PotionDefinition
                                                    definition =
                                                        purchasablePotions[index];
                                                    final int quantity =
                                                        quantities[definition
                                                            .id] ??
                                                        0;
                                                    final int cartQuantity =
                                                        _cart[definition.id] ??
                                                        0;

                                                    return _ShopPotionCard(
                                                      definition: definition,
                                                      quantity: quantity,
                                                      cartQuantity:
                                                          cartQuantity,
                                                      onTap: () =>
                                                          showPotionDetailSheet(
                                                            context: context,
                                                            definition:
                                                                definition,
                                                            quantity: quantity,
                                                          ),
                                                      onAdd: () => _addToCart(
                                                        definition: definition,
                                                        save: save,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              _CartFooter(
                                                itemCount: _cartItemCount(),
                                                totalGold: _cartTotalGold(),
                                                onClear: _cart.isEmpty
                                                    ? null
                                                    : _clearCart,
                                                onPurchase: _cart.isEmpty
                                                    ? null
                                                    : () {
                                                        if (save == null ||
                                                            save.gold <
                                                                _cartTotalGold()) {
                                                          _showFeedback(
                                                            'Not enough gold.',
                                                          );
                                                          return;
                                                        }
                                                        _buyCart();
                                                      },
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ShopPotionCard extends StatelessWidget {
  const _ShopPotionCard({
    required this.definition,
    required this.quantity,
    required this.cartQuantity,
    required this.onTap,
    required this.onAdd,
  });

  final PotionDefinition definition;
  final int quantity;
  final int cartQuantity;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.copyWith(
          titleMedium: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
          labelSmall: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
        ),
      ),
      child: PotionCard(
        definition: definition,
        quantity: quantity,
        selectedCount: cartQuantity,
        onTap: onTap,
        trailing: FilledButton(
          onPressed: onAdd,
          style: FilledButton.styleFrom(
            minimumSize: const Size(68, 36),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: const Text('Add'),
        ),
      ),
    );
  }
}

class _CartFooter extends StatelessWidget {
  const _CartFooter({
    required this.itemCount,
    required this.totalGold,
    required this.onClear,
    required this.onPurchase,
  });

  final int itemCount;
  final int totalGold;
  final VoidCallback? onClear;
  final VoidCallback? onPurchase;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xCC16110C),
        border: Border(top: BorderSide(color: Color(0x66F3D49C))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total fee',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalGold Gold • $itemCount item',
                    style: const TextStyle(
                      color: Color(0xFFFFF2D4),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onClear, child: const Text('Clear')),
            const SizedBox(width: 6),
            FilledButton(
              onPressed: onPurchase,
              style: FilledButton.styleFrom(
                minimumSize: const Size(76, 38),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Purchase'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: IconButton(
        tooltip: 'Back',
        onPressed: onPressed,
        color: Colors.white,
        icon: const Icon(Icons.arrow_back),
      ),
    );
  }
}

class _GoldPill extends StatelessWidget {
  const _GoldPill({required this.gold});

  final int? gold;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x99F3D49C)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.toll, color: Color(0xFFE3A704), size: 18),
            const SizedBox(width: 6),
            Text(
              '${gold ?? 0} Gold',
              style: const TextStyle(
                color: Color(0xFFFFF2D4),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopTitle extends StatelessWidget {
  const _ShopTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFFFFF2D4),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
