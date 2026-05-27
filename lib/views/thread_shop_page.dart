import 'package:flutter/material.dart';

import '../data/cosmetic_catalog.dart';
import '../data/models/equipped_cosmetic.dart';
import '../data/models/owned_cosmetic.dart';
import '../models/cosmetic_definition.dart';
import '../models/cosmetic_type.dart';
import '../models/player_save.dart';
import '../services/save_service.dart';

class ThreadShopPage extends StatefulWidget {
  const ThreadShopPage({super.key});

  @override
  State<ThreadShopPage> createState() => _ThreadShopPageState();
}

class _ThreadShopPageState extends State<ThreadShopPage> {
  final SaveService _saveService = SaveService();

  int? _profileId;
  late Future<_ThreadShopData?> _dataFuture;
  CosmeticType _selectedType = CosmeticType.hat;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profileId != null) {
      return;
    }

    _profileId = ModalRoute.of(context)?.settings.arguments as int?;
    _dataFuture = _loadData();
  }

  Future<_ThreadShopData?> _loadData() async {
    final int? profileId = _profileId;
    if (profileId == null) {
      return null;
    }

    final PlayerSave? save = await _saveService.getSaveById(profileId);
    if (save == null) {
      return null;
    }

    final List<OwnedCosmetic> owned = await _saveService
        .getOwnedCosmeticsForProfile(profileId: profileId);
    final List<EquippedCosmetic> equipped = await _saveService
        .getEquippedCosmeticsForProfile(profileId: profileId);
    return _ThreadShopData(save: save, owned: owned, equipped: equipped);
  }

  Future<void> _purchaseOrEquip(
    CosmeticDefinition cosmetic,
    _ThreadShopData data,
  ) async {
    final int profileId = data.save.profileId;
    final Set<int> ownedIds = data.ownedIds;
    final bool owned = ownedIds.contains(cosmetic.cosmeticId);

    if (!owned && data.save.gold < cosmetic.priceGold) {
      _showFeedback('Not enough gold.');
      return;
    }

    try {
      if (!owned) {
        await _saveService.purchaseCosmeticForProfile(
          profileId: profileId,
          cosmeticId: cosmetic.cosmeticId,
          priceGold: cosmetic.priceGold,
        );
      }

      await _saveService.equipCosmetic(
        profileId: profileId,
        slotType: cosmetic.type.storageKey,
        cosmeticId: cosmetic.cosmeticId,
      );

      _showFeedback(owned ? 'Cosmetic equipped.' : 'Cosmetic purchased.');
      setState(() {
        _dataFuture = _loadData();
      });
    } catch (error) {
      _showFeedback(error.toString());
    }
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/threadshop1.png', fit: BoxFit.cover),
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
            child: FutureBuilder<_ThreadShopData?>(
              future: _dataFuture,
              builder: (context, snapshot) {
                final _ThreadShopData? data = snapshot.data;
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (data == null) {
                  return const Center(child: Text('Profile not found.'));
                }

                final List<CosmeticDefinition> items =
                    CosmeticCatalog.shopItemsForClass(
                      playerClass: data.save.playerClass,
                      type: _selectedType,
                    );

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final double panelWidth =
                        (constraints.maxWidth *
                                (constraints.maxWidth >= 700 ? 0.50 : 0.72))
                            .clamp(300.0, 430.0);

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
                              const _ShopTitle(
                                title: 'Threads',
                                subtitle: 'The Gilded Thread',
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 14,
                          top: 20,
                          child: _GoldPill(gold: data.save.gold),
                        ),
                        Positioned(
                          left: 0,
                          top: 108,
                          bottom: 18,
                          child: SizedBox(
                            width: panelWidth + 26,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.44),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                                border: Border.all(
                                  color: const Color(0x66F3D49C),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      10,
                                      10,
                                      10,
                                      6,
                                    ),
                                    child: _ThreadTabs(
                                      selectedType: _selectedType,
                                      onChanged: (CosmeticType type) {
                                        setState(() {
                                          _selectedType = type;
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.separated(
                                      padding: const EdgeInsets.fromLTRB(
                                        10,
                                        6,
                                        10,
                                        12,
                                      ),
                                      itemCount: items.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (context, index) {
                                        final CosmeticDefinition cosmetic =
                                            items[index];
                                        return _CosmeticShopCard(
                                          cosmetic: cosmetic,
                                          owned: data.ownedIds.contains(
                                            cosmetic.cosmeticId,
                                          ),
                                          equipped:
                                              data.equippedIds[cosmetic.type] ==
                                              cosmetic.cosmeticId,
                                          onPressed: () =>
                                              _purchaseOrEquip(cosmetic, data),
                                        );
                                      },
                                    ),
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

class _ThreadTabs extends StatelessWidget {
  const _ThreadTabs({required this.selectedType, required this.onChanged});

  final CosmeticType selectedType;
  final ValueChanged<CosmeticType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<CosmeticType>(
      segments: const <ButtonSegment<CosmeticType>>[
        ButtonSegment<CosmeticType>(
          value: CosmeticType.hat,
          icon: Icon(Icons.face),
          label: Text('Head'),
        ),
        ButtonSegment<CosmeticType>(
          value: CosmeticType.torso,
          icon: Icon(Icons.checkroom),
          label: Text('Torso'),
        ),
      ],
      selected: <CosmeticType>{selectedType},
      onSelectionChanged: (Set<CosmeticType> value) {
        onChanged(value.first);
      },
      style: SegmentedButton.styleFrom(
        backgroundColor: const Color(0xAA16110C),
        selectedBackgroundColor: const Color(0xFFE7B957),
        selectedForegroundColor: const Color(0xFF1C160E),
        foregroundColor: const Color(0xFFFFF2D4),
        side: const BorderSide(color: Color(0x99F3D49C)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _CosmeticShopCard extends StatelessWidget {
  const _CosmeticShopCard({
    required this.cosmetic,
    required this.owned,
    required this.equipped,
    required this.onPressed,
  });

  final CosmeticDefinition cosmetic;
  final bool owned;
  final bool equipped;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final String actionLabel = equipped
        ? 'Equipped'
        : owned
        ? 'Equip'
        : 'Buy';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE61D1710),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: equipped ? const Color(0xFFE7B957) : const Color(0x66F3D49C),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 72,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0x44FFF2D4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x55F3D49C)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Image.asset(
                    cosmetic.assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.checkroom, color: Color(0xFFFFF2D4)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cosmetic.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFF2D4),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    owned ? 'Owned' : '${cosmetic.priceGold} Gold',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.74),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: equipped ? null : onPressed,
              style: FilledButton.styleFrom(
                minimumSize: const Size(82, 38),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              child: Text(actionLabel),
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

  final int gold;

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
              '$gold Gold',
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

class _ThreadShopData {
  const _ThreadShopData({
    required this.save,
    required this.owned,
    required this.equipped,
  });

  final PlayerSave save;
  final List<OwnedCosmetic> owned;
  final List<EquippedCosmetic> equipped;

  Set<int> get ownedIds =>
      owned.map((OwnedCosmetic cosmetic) => cosmetic.cosmeticId).toSet();

  Map<CosmeticType, int> get equippedIds {
    return <CosmeticType, int>{
      for (final EquippedCosmetic cosmetic in equipped)
        if (CosmeticType.fromStorageKey(cosmetic.slotType) != null)
          CosmeticType.fromStorageKey(cosmetic.slotType)!: cosmetic.cosmeticId,
    };
  }
}
