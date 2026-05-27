import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../models/player_save.dart';
import '../services/save_service.dart';
import '../widgets/layered_avatar.dart';

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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: slots.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final int slotNumber = slots[index];
                  return SizedBox(
                    height: 180,
                    child: _SlotCard(
                      slotNumber: slotNumber,
                      save: savesById[slotNumber],
                      onOpen: savesById[slotNumber] == null
                          ? null
                          : () async {
                              await Navigator.pushNamed(
                                context,
                                AppRoutes.mainHub,
                                arguments: slotNumber,
                              );
                              await _reload();
                            },
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

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slotNumber,
    required this.save,
    required this.onOpen,
    required this.onCreate,
    required this.onDelete,
  });

  final int slotNumber;
  final PlayerSave? save;
  final VoidCallback? onOpen;
  final VoidCallback onCreate;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final PlayerSave? currentSave = save;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 104,
              child: currentSave == null
                  ? const Icon(Icons.person_add, size: 54)
                  : LayeredAvatar(
                      playerClass: currentSave.playerClass,
                      size: 104,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Slot $slotNumber',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (currentSave == null) ...<Widget>[
                    Text(
                      'Empty Save',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ] else ...<Widget>[
                    Text(
                      currentSave.playerClass.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Level ${currentSave.level}'),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 104,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: currentSave == null ? onCreate : onOpen,
                      child: Text(currentSave == null ? 'Create' : 'Enter'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: onDelete,
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
