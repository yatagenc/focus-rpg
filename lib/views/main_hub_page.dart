import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/progression.dart';
import '../models/player_save.dart';
import '../services/save_service.dart';

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
      AppRoutes.focusSession,
      arguments: profileId,
    );

    if (result == true) {
      await _reload();
    }
  }

  void _showPlaceholder(String title) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title will be added later.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<PlayerSave?>(
          future: _saveFuture,
          builder: (context, snapshot) {
            final PlayerSave? save = snapshot.data;

            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (save == null) {
              return const Center(child: Text('Save profile not found.'));
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 28),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Exit to Main Menu',
                                onPressed: () {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    AppRoutes.home,
                                    (route) => false,
                                  );
                                },
                                icon: const Icon(Icons.logout),
                              ),
                              IconButton(
                                tooltip: 'Settings',
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.settings,
                                  );
                                },
                                icon: const Icon(Icons.settings),
                              ),
                            ],
                          ),
                          const Spacer(),
                          _ProfileSummary(
                            save: save,
                            onShopPressed: () => _showPlaceholder('Shop'),
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
                      const Spacer(),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _startSession,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Session'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.save,
    required this.onShopPressed,
    required this.onProfilePressed,
  });

  final PlayerSave save;
  final VoidCallback onShopPressed;
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
              customBorder: const CircleBorder(),
              onTap: onProfilePressed,
              child: CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFE3A704),
                child: Text(
                  save.playerClass.isEmpty
                      ? '?'
                      : save.playerClass.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
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
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 36,
              child: OutlinedButton.icon(
                onPressed: onShopPressed,
                icon: const Icon(Icons.storefront, size: 16),
                label: const Text('Shop'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
