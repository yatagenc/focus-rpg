import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../models/player_save.dart';
import '../services/save_service.dart';

class SlotsPage extends StatefulWidget {
  const SlotsPage({super.key});

  @override
  State<SlotsPage> createState() => _SlotsPageState();
}

class _SlotsPageState extends State<SlotsPage> {
  final SaveService _saveService = SaveService();

  late Future<List<PlayerSave>> _savesFuture;

  @override
  void initState() {
    super.initState();
    _savesFuture = _saveService.getAllSaves();
  }

  Future<void> _reload() async {
    setState(() {
      _savesFuture = _saveService.getAllSaves();
    });
  }

  Future<void> _deleteProfile(int profileId) async {
    await _saveService.deleteSave(profileId);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final slots = List.generate(3, (index) => index + 1);

    return Scaffold(
      appBar: AppBar(title: const Text('Save Slots')),
      body: FutureBuilder<List<PlayerSave>>(
        future: _savesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load save slots.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final Map<int, PlayerSave> savesById = <int, PlayerSave>{
            for (final PlayerSave save in snapshot.data ?? <PlayerSave>[])
              save.profileId: save,
          };

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: slots
                    .map(
                      (slotNumber) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                          width: 240,
                          height: 360,
                          child: _SlotCard(
                            slotNumber: slotNumber,
                            save: savesById[slotNumber],
                            onCreate: () async {
                              final result = await Navigator.pushNamed(
                                context,
                                AppRoutes.characterSelection,
                              );

                              if (result == true) {
                                await _reload();
                              }
                            },
                            onDelete: savesById[slotNumber] == null
                                ? null
                                : () => _deleteProfile(slotNumber),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slotNumber,
    required this.save,
    required this.onCreate,
    required this.onDelete,
  });

  final int slotNumber;
  final PlayerSave? save;
  final VoidCallback onCreate;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final PlayerSave? currentSave = save;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Slot $slotNumber',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            if (currentSave == null) ...<Widget>[
              Text(
                'Empty Save',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ] else ...<Widget>[
              Text(
                currentSave.playerClass.toUpperCase(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Level ${currentSave.level}  XP ${currentSave.xp}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('Gold ${currentSave.gold}', textAlign: TextAlign.center),
            ],
            const Spacer(),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: currentSave == null ? onCreate : null,
                child: const Text('Create'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: onDelete,
                child: const Text('Delete'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
