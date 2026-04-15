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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Choose a class',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 32),

              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 720,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 24,
                      runSpacing: 24,
                      children: _classes.map((characterClass) {
                        final isSelected = _selectedClass == characterClass;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedClass = characterClass;
                            });
                          },
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 120),
                            scale: isSelected ? 1.04 : 1.0,
                            child: SizedBox(
                              width: 280,
                              height: 240,
                              child: _ClassCard(
                                label: characterClass,
                                isSelected: isSelected,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 160,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Back'),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _selectedClass == null || _isSaving
                          ? null
                          : _createProfile,
                      child: Text(_isSaving ? 'Saving...' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ],
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
    return Card(
      color: const Color(0xFF1A1822),
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected
              ? const Color.fromARGB(255, 227, 167, 4)
              : Colors.white24,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? const Color.fromARGB(255, 227, 167, 4)
                : Colors.grey,
          ),
        ),
      ),
    );
  }
}
