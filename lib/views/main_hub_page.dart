import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/progression.dart';
import '../data/models/equipped_cosmetic.dart';
import '../data/models/app_settings.dart';
import '../models/player_save.dart';
import '../services/save_service.dart';
import '../services/settings_service.dart';
import '../widgets/app_safe_layout.dart';
import '../services/shop_sound_service.dart';
import '../widgets/layered_avatar.dart';

class MainHubPage extends StatefulWidget {
  const MainHubPage({super.key});

  @override
  State<MainHubPage> createState() => _MainHubPageState();
}

class _MainHubPageState extends State<MainHubPage> {
  final SaveService _saveService = SaveService();

  int? _profileId;
  late Future<_MainHubViewData?> _hubFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profileId != null) {
      return;
    }

    _profileId = ModalRoute.of(context)?.settings.arguments as int?;
    _hubFuture = _loadHubData(_profileId ?? -1);
  }

  Future<_MainHubViewData?> _loadHubData(int profileId) async {
    final PlayerSave? save = await _saveService.getSaveById(profileId);
    if (save == null) {
      return null;
    }

    final List<EquippedCosmetic> equippedCosmetics = await _saveService
        .getEquippedCosmeticsForProfile(profileId: profileId);
    return _MainHubViewData(save: save, equippedCosmetics: equippedCosmetics);
  }

  Future<void> _reload() async {
    final int? profileId = _profileId;
    if (profileId == null) {
      return;
    }

    setState(() {
      _hubFuture = _loadHubData(profileId);
    });
  }

  Future<void> _startSession() async {
    final int? profileId = _profileId;
    if (profileId == null) {
      return;
    }

    final Object? result = await Navigator.pushNamed(
      context,
      AppRoutes.potionSelection,
      arguments: profileId,
    );

    if (result == true) {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<_MainHubViewData?>(
        future: _hubFuture,
        builder: (context, snapshot) {
          final _MainHubViewData? data = snapshot.data;

          if (snapshot.connectionState != ConnectionState.done) {
            return const _TownBackground(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (data == null) {
            return const _TownBackground(
              child: Center(child: Text('Save profile not found.')),
            );
          }

          final PlayerSave save = data.save;
          return _TownBackground(
            child: AppSafeLayout(
              horizontal: 0,
              top: 10,
              bottom: 12,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final Size size = constraints.biggest;
                  final double contentWidth = size.width.clamp(0, 390);

                  return Stack(
                    children: [
                      Positioned(
                        left: 16,
                        right: 16,
                        top: 18,
                        child: Center(
                          child: SizedBox(
                            width: contentWidth,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _HubIconButton(
                                      tooltip: 'Exit to Main Menu',
                                      icon: Icons.logout,
                                      onPressed: () {
                                        Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          AppRoutes.home,
                                          (route) => false,
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _HubIconButton(
                                      tooltip: 'Settings',
                                      icon: Icons.settings,
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.settings,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                _ProfileSummary(
                                  save: save,
                                  streakDays: save.streakDays,
                                  equippedCosmetics: data.equippedCosmetics,
                                  onInventoryPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.inventory,
                                      arguments: save.profileId,
                                    ).then((_) => _reload());
                                  },
                                  onProfilePressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.profile,
                                      arguments: save.profileId,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _ShopHotspot(
                        alignment: const Alignment(-0.82, 0.43),
                        icon: Icons.science,
                        label: 'Potions',
                        onPressed: () {
                          ShopSoundService.instance
                              .playShopEntryAfterButtonClick();
                          Navigator.pushNamed(
                            context,
                            AppRoutes.potionShop,
                            arguments: save.profileId,
                          ).then((_) => _reload());
                        },
                      ),
                      _ShopHotspot(
                        alignment: const Alignment(0.72, 0.31),
                        icon: Icons.checkroom,
                        label: 'Threads',
                        onPressed: () {
                          ShopSoundService.instance
                              .playShopEntryAfterButtonClick();
                          Navigator.pushNamed(
                            context,
                            AppRoutes.threadShop,
                            arguments: save.profileId,
                          ).then((_) => _reload());
                        },
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 22,
                        child: Center(
                          child: SizedBox(
                            width: contentWidth,
                            height: 54,
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.potionSelection,
                                        arguments: save.profileId,
                                      ).then((Object? result) {
                                        if (result == true) {
                                          _reload();
                                        }
                                      });
                                    },
                                    icon: const Icon(Icons.local_drink),
                                    label: const Text('Prepare'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _startSession,
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Start'),
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
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TownBackground extends StatelessWidget {
  const _TownBackground({required this.child});

  static const String _dayBackgroundAsset = 'assets/images/town1.png';
  static const String _nightBackgroundAsset = 'assets/images/town_night.png';

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: SettingsService.instance.settingsNotifier,
      builder: (context, settings, _) {
        final String backgroundAsset = settings.darkMode
            ? _nightBackgroundAsset
            : _dayBackgroundAsset;

        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              backgroundAsset,
              key: ValueKey<String>(backgroundAsset),
              fit: BoxFit.cover,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66000000),
                    Color(0x00000000),
                    Color(0x33000000),
                    Color(0x99000000),
                  ],
                  stops: [0, 0.28, 0.66, 1],
                ),
              ),
            ),
            child,
          ],
        );
      },
    );
  }
}

class _HubIconButton extends StatelessWidget {
  const _HubIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(tooltip: tooltip, onPressed: onPressed, icon: Icon(icon));
  }
}

class _ShopHotspot extends StatelessWidget {
  const _ShopHotspot({
    required this.alignment,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Alignment alignment;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: SizedBox(
        height: 34,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 14),
          label: Text(label),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            minimumSize: const Size(0, 34),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.save,
    required this.streakDays,
    required this.equippedCosmetics,
    required this.onInventoryPressed,
    required this.onProfilePressed,
  });

  final PlayerSave save;
  final int streakDays;
  final List<EquippedCosmetic> equippedCosmetics;
  final VoidCallback onInventoryPressed;
  final VoidCallback onProfilePressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final LevelProgress progress = progressionSystem.getLevelFromTotalXp(
      save.xp,
    );
    final int currentLevelXp = progress.currentLevelXp;
    final int? requiredXp = progress.requiredXpForNextLevel;

    return SizedBox(
      width: 178,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _StreakPill(days: streakDays),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onProfilePressed,
                  child: LayeredAvatar(
                    playerClass: save.playerClass,
                    equippedCosmetics: equippedCosmetics,
                    size: 58,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Level ${save.level}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.progressRatio,
              minHeight: 8,
              backgroundColor: colors.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            requiredXp == null
                ? 'Max Level'
                : '$currentLevelXp / $requiredXp XP',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${save.gold} Gold',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: FilledButton.icon(
              onPressed: onInventoryPressed,
              icon: const Icon(Icons.inventory_2, size: 14),
              label: const Text('Inventory'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 9),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainHubViewData {
  const _MainHubViewData({required this.save, required this.equippedCosmetics});

  final PlayerSave save;
  final List<EquippedCosmetic> equippedCosmetics;
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final bool active = days > 0;
    final Color flameColor = _flameColor();
    final Color iconColor = active ? flameColor : const Color(0xFFD7D2C8);
    final Color borderColor = active
        ? flameColor.withValues(alpha: 0.68)
        : const Color(0xFFE7DCC6).withValues(alpha: 0.5);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE51A1712),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
          if (active && days >= 30)
            BoxShadow(
              color: flameColor.withValues(alpha: 0.22),
              blurRadius: 12,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              size: _iconSize(),
              color: iconColor,
            ),
            const SizedBox(width: 6),
            Text(
              '$days',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFFF7F0E4),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                shadows: const <Shadow>[
                  Shadow(
                    color: Color(0x99000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _flameColor() {
    if (days >= 100) {
      return const Color(0xFF8B5CF6);
    }
    if (days >= 30) {
      return const Color(0xFFE11D48);
    }
    if (days >= 10) {
      return const Color(0xFFF97316);
    }
    return const Color(0xFF8FD694);
  }

  double _iconSize() {
    if (days >= 100) {
      return 24;
    }
    if (days >= 30) {
      return 22;
    }
    return 20;
  }
}
