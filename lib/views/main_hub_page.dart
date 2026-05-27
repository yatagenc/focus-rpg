import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/progression.dart';
import '../models/player_save.dart';
import '../services/save_service.dart';
import '../widgets/layered_avatar.dart';

class MainHubPage extends StatefulWidget {
  const MainHubPage({super.key});

  @override
  State<MainHubPage> createState() => _MainHubPageState();
}

class _MainHubPageState extends State<MainHubPage> {
  final SaveService _saveService = SaveService();

  int? _profileId;
  late Future<PlayerSave?> _saveFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profileId != null) {
      return;
    }

    _profileId = ModalRoute.of(context)?.settings.arguments as int?;
    _saveFuture = _saveService.getSaveById(_profileId ?? -1);
  }

  Future<void> _reload() async {
    final int? profileId = _profileId;
    if (profileId == null) {
      return;
    }

    setState(() {
      _saveFuture = _saveService.getSaveById(profileId);
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
      body: FutureBuilder<PlayerSave?>(
        future: _saveFuture,
        builder: (context, snapshot) {
          final PlayerSave? save = snapshot.data;

          if (snapshot.connectionState != ConnectionState.done) {
            return const _TownBackground(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (save == null) {
            return const _TownBackground(
              child: Center(child: Text('Save profile not found.')),
            );
          }

          return _TownBackground(
            child: SafeArea(
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
                                _StreakPill(days: save.streakDays),
                                const SizedBox(width: 10),
                                _ProfileSummary(
                                  save: save,
                                  onInventoryPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.inventory,
                                      arguments: save.profileId,
                                    );
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

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/town1.png', fit: BoxFit.cover),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color: Colors.white,
        icon: Icon(icon),
      ),
    );
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
            backgroundColor: const Color(0xCC2B2117),
            foregroundColor: const Color(0xFFFFF2D4),
            padding: const EdgeInsets.symmetric(horizontal: 9),
            minimumSize: const Size(0, 34),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
              side: const BorderSide(color: Color(0x99F3D49C)),
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
    required this.onInventoryPressed,
    required this.onProfilePressed,
  });

  final PlayerSave save;
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
      width: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onProfilePressed,
              child: LayeredAvatar(playerClass: save.playerClass, size: 58),
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
          const SizedBox(height: 4),
          Text(
            '${save.elo} Elo',
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: FilledButton.icon(
              onPressed: onInventoryPressed,
              icon: const Icon(Icons.inventory_2, size: 14),
              label: const Text('Inventory'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xCC2B2117),
                foregroundColor: const Color(0xFFFFF2D4),
                padding: const EdgeInsets.symmetric(horizontal: 9),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                  side: const BorderSide(color: Color(0x99F3D49C)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool active = days > 0;
    final Color flameColor = _flameColor(colors);
    final Color backgroundColor = active
        ? flameColor.withValues(alpha: 0.14)
        : colors.surfaceContainerHighest;
    final Color borderColor = active
        ? flameColor.withValues(alpha: 0.56)
        : colors.outlineVariant;
    final Color textColor = active ? colors.onSurface : colors.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
        boxShadow: active && days >= 30
            ? <BoxShadow>[
                BoxShadow(
                  color: flameColor.withValues(alpha: 0.22),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              size: _iconSize(),
              color: active ? flameColor : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              '$days',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _flameColor(ColorScheme colors) {
    if (days >= 100) {
      return const Color(0xFF8B5CF6);
    }
    if (days >= 30) {
      return const Color(0xFFE11D48);
    }
    if (days >= 10) {
      return const Color(0xFFF97316);
    }
    return colors.tertiary;
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
