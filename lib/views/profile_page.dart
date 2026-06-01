import 'package:flutter/material.dart';

import '../data/models/game_session.dart';
import '../data/models/equipped_cosmetic.dart';
import '../models/player_save.dart';
import '../services/save_service.dart';
import '../widgets/app_safe_layout.dart';
import '../widgets/layered_avatar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SaveService _saveService = SaveService();

  int? _profileId;
  late Future<_ProfileViewData> _profileFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profileId != null) {
      return;
    }

    _profileId = ModalRoute.of(context)?.settings.arguments as int?;
    _profileFuture = _loadProfileData(_profileId ?? -1);
  }

  Future<_ProfileViewData> _loadProfileData(int profileId) async {
    final PlayerSave? save = await _saveService.getSaveById(profileId);
    if (save == null) {
      throw StateError('Profile not found.');
    }

    final List<GameSession> sessions = await _saveService
        .getRecentSessionsForProfile(profileId: profileId, limit: 10);
    final List<EquippedCosmetic> equippedCosmetics = await _saveService
        .getEquippedCosmeticsForProfile(profileId: profileId);

    return _ProfileViewData(
      save: save,
      recentSessions: sessions,
      equippedCosmetics: equippedCosmetics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: AppSafeLayout(
        horizontal: 0,
        top: 4,
        bottom: 8,
        child: FutureBuilder<_ProfileViewData>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Failed to load profile.\n${snapshot.error ?? ''}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final _ProfileViewData data = snapshot.data!;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: ListView(
                  padding: AppSafeSpacing.listPadding(
                    context,
                    top: 12,
                    bottom: 18,
                  ),
                  children: [
                    _ProfileHeader(
                      save: data.save,
                      equippedCosmetics: data.equippedCosmetics,
                    ),
                    const SizedBox(height: 16),
                    _ProfileStats(save: data.save),
                    const SizedBox(height: 16),
                    _RecentSessionsSection(sessions: data.recentSessions),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.save, required this.equippedCosmetics});

  final PlayerSave save;
  final List<EquippedCosmetic> equippedCosmetics;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            LayeredAvatar(
              playerClass: save.playerClass,
              equippedCosmetics: equippedCosmetics,
              size: 118,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    save.playerClass.toUpperCase(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Level ${save.level}'),
                  const SizedBox(height: 6),
                  Text('${save.gold} Gold'),
                  const SizedBox(height: 6),
                  Text('${save.elo} Elo'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.save});

  final PlayerSave save;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatTile(label: 'Class', value: save.playerClass.toUpperCase()),
        _StatTile(label: 'Level', value: save.level.toString()),
        _StatTile(label: 'Total XP', value: save.xp.toString()),
        _StatTile(label: 'Gold', value: save.gold.toString()),
        _StatTile(label: 'Elo', value: save.elo.toString()),
        const _StatTile(label: 'Total Gold Spent', value: '0'),
        _StatTile(
          label: 'Total Session Minutes',
          value: save.totalStudyMinutes.toString(),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSessionsSection extends StatelessWidget {
  const _RecentSessionsSection({required this.sessions});

  final List<GameSession> sessions;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
      initiallyExpanded: true,
      title: const Text(
        'Recent Sessions',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: const Text('Last 10 completed sessions'),
      children: [
        if (sessions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No sessions yet.'),
          )
        else
          ...sessions.map(_SessionCard.new),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard(this.session);

  final GameSession session;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${session.durationMinutes} min ${session.sessionType}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text('XP ${session.xpEarned}')),
                Expanded(
                  child: Text(
                    'Gold ${session.goldEarned}',
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatTimestamp(session.startedAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    final DateTime? parsed = DateTime.tryParse(timestamp);
    if (parsed == null) {
      return timestamp;
    }

    final String date =
        '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    final String time =
        '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}

class _ProfileViewData {
  const _ProfileViewData({
    required this.save,
    required this.recentSessions,
    required this.equippedCosmetics,
  });

  final PlayerSave save;
  final List<GameSession> recentSessions;
  final List<EquippedCosmetic> equippedCosmetics;
}
