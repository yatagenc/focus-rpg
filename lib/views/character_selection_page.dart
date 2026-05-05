import 'package:flutter/material.dart';

import '../models/player_save.dart';
import '../services/save_service.dart';

class CharacterSelectionPage extends StatefulWidget {
  const CharacterSelectionPage({super.key});

  @override
  State<CharacterSelectionPage> createState() => _CharacterSelectionPageState();
}

class _CharacterSelectionPageState extends State<CharacterSelectionPage> {
  static const List<String> _classes = ['Mage', 'Knight', 'Archer', 'Thief'];
  final SaveService _saveService = SaveService();

  String? _selectedClass;
  bool _isSaving = false;

  Future<void> _createProfile() async {
    final String? selectedClass = _selectedClass;
    if (selectedClass == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final List<PlayerSave> saves = await _saveService.getAllSaves();
      final Set<int> usedIds = saves
          .map((PlayerSave save) => save.profileId)
          .toSet();

      int? nextId;
      for (int candidate = 1; candidate <= 3; candidate++) {
        if (!usedIds.contains(candidate)) {
          nextId = candidate;
          break;
        }
      }

      if (nextId == null) {
        throw StateError('All profile slots are already occupied.');
      }

      await _saveService.createSave(
        profileId: nextId,
        playerClass: selectedClass,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Choose a class',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      itemCount: _classes.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.92,
                          ),
                      itemBuilder: (context, index) {
                        final String characterClass = _classes[index];
                        final bool isSelected =
                            _selectedClass == characterClass;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedClass = characterClass;
                            });
                          },
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 120),
                            scale: isSelected ? 1.03 : 1.0,
                            child: _ClassCard(
                              label: characterClass,
                              isSelected: isSelected,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            child: const Text('Back'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _selectedClass == null || _isSaving
                                ? null
                                : _createProfile,
                            child: Text(_isSaving ? 'Saving...' : 'Continue'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.label, required this.isSelected});

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.surfaceContainerHighest,
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected ? const Color(0xFFE3A704) : colors.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isSelected ? const Color(0xFFE3A704) : colors.onSurface,
          ),
        ),
      ),
    );
  }
}
