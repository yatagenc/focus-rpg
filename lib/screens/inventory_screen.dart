import 'package:flutter/material.dart';

import '../core/elo.dart';
import '../data/cosmetic_catalog.dart';
import '../data/models/equipped_cosmetic.dart';
import '../data/models/owned_cosmetic.dart';
import '../data/potion_catalog.dart';
import '../models/cosmetic_definition.dart';
import '../models/cosmetic_type.dart';
import '../models/inventory_potion.dart';
import '../models/player_save.dart';
import '../models/potion_definition.dart';
import '../models/potion_rarity.dart';
import '../services/inventory_service.dart';
import '../services/save_service.dart';
import '../widgets/layered_avatar.dart';
import '../widgets/potion_card.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  int? _profileId;
  PotionRarity? _rarityFilter;
  _InventoryMode _mode = _InventoryMode.potions;

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
                  child: _InventoryModeSelector(
                    selectedMode: _mode,
                    onChanged: (_InventoryMode mode) {
                      setState(() {
                        _mode = mode;
                      });
                    },
                  ),
                ),
                if (_mode == _InventoryMode.potions)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
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
                  child: _mode == _InventoryMode.potions
                      ? _PotionList(
                          profileId: profileId,
                          rarityFilter: _rarityFilter,
                        )
                      : _FrameInventory(profileId: profileId),
                ),
              ],
            ),
    );
  }
}

enum _InventoryMode { potions, frames }

class _InventoryModeSelector extends StatelessWidget {
  const _InventoryModeSelector({
    required this.selectedMode,
    required this.onChanged,
  });

  final _InventoryMode selectedMode;
  final ValueChanged<_InventoryMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_InventoryMode>(
      segments: const <ButtonSegment<_InventoryMode>>[
        ButtonSegment<_InventoryMode>(
          value: _InventoryMode.potions,
          icon: Icon(Icons.local_drink),
          label: Text('Potions'),
        ),
        ButtonSegment<_InventoryMode>(
          value: _InventoryMode.frames,
          icon: Icon(Icons.crop_square),
          label: Text('Frames'),
        ),
      ],
      selected: <_InventoryMode>{selectedMode},
      onSelectionChanged: (Set<_InventoryMode> selection) {
        onChanged(selection.first);
      },
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

class _FrameInventory extends StatefulWidget {
  const _FrameInventory({required this.profileId});

  final int profileId;

  @override
  State<_FrameInventory> createState() => _FrameInventoryState();
}

class _FrameInventoryState extends State<_FrameInventory> {
  final SaveService _saveService = SaveService();
  late Future<_FrameInventoryData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant _FrameInventory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileId != widget.profileId) {
      _future = _load();
    }
  }

  Future<_FrameInventoryData> _load() async {
    final PlayerSave? save = await _saveService.getSaveById(widget.profileId);
    if (save == null) {
      throw StateError('Profile not found.');
    }

    final List<OwnedCosmetic> owned = await _saveService
        .getOwnedCosmeticsForProfile(profileId: widget.profileId);
    final List<EquippedCosmetic> equipped = await _saveService
        .getEquippedCosmeticsForProfile(profileId: widget.profileId);

    return _FrameInventoryData(save: save, owned: owned, equipped: equipped);
  }

  Future<void> _equipFrame(CosmeticDefinition frame) async {
    await _saveService.equipCosmetic(
      profileId: widget.profileId,
      slotType: CosmeticType.frame.storageKey,
      cosmeticId: frame.cosmeticId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_FrameInventoryData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Text('Failed to load frames.\n${snapshot.error}'),
          );
        }

        final _FrameInventoryData data = snapshot.data!;
        final Set<int> ownedIds = data.owned
            .map((OwnedCosmetic cosmetic) => cosmetic.cosmeticId)
            .toSet();
        final int equippedFrameId =
            data.equipped
                .where(
                  (EquippedCosmetic cosmetic) =>
                      cosmetic.slotType == CosmeticType.frame.storageKey,
                )
                .map((EquippedCosmetic cosmetic) => cosmetic.cosmeticId)
                .firstOrNull ??
            CosmeticCatalog.defaultWoodFrameId;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _EloHeader(save: data.save),
            const SizedBox(height: 12),
            ...CosmeticCatalog.frames.map(
              (CosmeticDefinition frame) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FrameTile(
                  save: data.save,
                  frame: frame,
                  owned: ownedIds.contains(frame.cosmeticId),
                  equipped: equippedFrameId == frame.cosmeticId,
                  onEquip: () => _equipFrame(frame),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EloHeader extends StatelessWidget {
  const _EloHeader({required this.save});

  final PlayerSave save;

  @override
  Widget build(BuildContext context) {
    final EloRank rank = EloSystem.rankForElo(save.elo);
    final EloRank? nextRank = EloSystem.nextRankForElo(save.elo);
    final int previousElo = rank.minimumElo;
    final int nextElo = nextRank?.minimumElo ?? previousElo;
    final double progress = nextRank == null
        ? 1
        : ((save.elo - previousElo) / (nextElo - previousElo)).clamp(0, 1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.military_tech),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${rank.name} Rank',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${save.elo} Elo',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: progress, minHeight: 8),
            ),
            const SizedBox(height: 8),
            Text(
              nextRank == null
                  ? 'Highest frame rank reached.'
                  : '${nextRank.minimumElo - save.elo} Elo to ${nextRank.name}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _FrameTile extends StatelessWidget {
  const _FrameTile({
    required this.save,
    required this.frame,
    required this.owned,
    required this.equipped,
    required this.onEquip,
  });

  final PlayerSave save;
  final CosmeticDefinition frame;
  final bool owned;
  final bool equipped;
  final VoidCallback onEquip;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool unlockable = save.elo >= frame.unlockElo;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Opacity(
              opacity: owned ? 1 : 0.46,
              child: LayeredAvatar(
                playerClass: save.playerClass,
                equippedCosmetics: <EquippedCosmetic>[
                  EquippedCosmetic(
                    profileId: save.profileId,
                    slotType: CosmeticType.frame.storageKey,
                    cosmeticId: frame.cosmeticId,
                    equippedAt: '',
                  ),
                ],
                size: 76,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    frame.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    frame.unlockElo == 0
                        ? 'Default frame'
                        : '${frame.unlockElo} Elo required',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (!owned && unlockable) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Unlocks automatically on refresh.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 92,
              child: FilledButton(
                onPressed: owned && !equipped ? onEquip : null,
                child: Text(
                  equipped
                      ? 'Equipped'
                      : owned
                      ? 'Equip'
                      : 'Locked',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrameInventoryData {
  const _FrameInventoryData({
    required this.save,
    required this.owned,
    required this.equipped,
  });

  final PlayerSave save;
  final List<OwnedCosmetic> owned;
  final List<EquippedCosmetic> equipped;
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
  late Future<List<InventoryPotion>> _potionsFuture;

  @override
  void initState() {
    super.initState();
    _potionsFuture = InventoryService.instance.getInventoryPotions(
      profileId: widget.profileId,
    );
  }

  @override
  void didUpdateWidget(covariant _PotionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileId != widget.profileId) {
      _potionsFuture = InventoryService.instance.getInventoryPotions(
        profileId: widget.profileId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<InventoryPotion>>(
      future: _potionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final Map<String, int> quantities = <String, int>{
          for (final InventoryPotion potion
              in snapshot.data ?? const <InventoryPotion>[])
            potion.potionId: potion.quantity,
        };
        final List<PotionDefinition> definitions = PotionCatalog.potions
            .where(
              (PotionDefinition potion) =>
                  widget.rarityFilter == null ||
                  potion.rarity == widget.rarityFilter,
            )
            .where(
              (PotionDefinition potion) => (quantities[potion.id] ?? 0) > 0,
            )
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
      },
    );
  }
}
