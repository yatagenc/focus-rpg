import 'dart:async';

import 'package:flutter/material.dart';

import '../data/potion_catalog.dart';
import '../models/focus_event.dart';
import '../models/inventory_potion.dart';
import '../models/player_save.dart';
import '../models/potion_definition.dart';
import '../models/potion_effect_type.dart';
import '../services/focus_event_service.dart';
import '../services/focus_event_sound_service.dart';
import '../services/ambient_audio_service.dart';
import '../services/inventory_service.dart';
import '../services/save_service.dart';
import '../widgets/app_safe_layout.dart';
import '../widgets/focus_event_dialog.dart';

class FocusSessionArguments {
  const FocusSessionArguments({
    required this.profileId,
    this.selectedPotionIds = const <String>[],
  });

  final int profileId;
  final List<String> selectedPotionIds;
}

class FocusSessionPage extends StatefulWidget {
  const FocusSessionPage({super.key});

  @override
  State<FocusSessionPage> createState() => _FocusSessionPageState();
}

class _FocusSessionPageState extends State<FocusSessionPage> {
  static const int _breakUnlockSeconds = 30 * 60;
  static const int _baseBreakDurationSeconds = 10 * 60;
  static const int _baseFocusTargetSeconds = 40 * 60;

  final SaveService _saveService = SaveService();
  final InventoryService _inventoryService = InventoryService.instance;
  final FocusEventService _eventService = FocusEventService();
  final AmbientAudioService _ambientAudioService = AmbientAudioService.instance;

  Timer? _timer;
  int? _profileId;
  String _playerClass = '';
  List<String> _selectedPotionIds = <String>[];
  late PotionSessionEffects _sessionEffects = const PotionSessionEffects();
  DateTime? _startedAt;
  DateTime? _focusResumedAt;
  DateTime? _breakStartedAt;
  int _focusAccumulatedMilliseconds = 0;
  int _elapsedMilliseconds = 0;
  int _totalSessionMilliseconds = 0;
  int _breakRemainingSeconds = _baseBreakDurationSeconds;
  int _debugTimeMultiplier = 1;
  int? _lastTreeDebugElapsedSecond;
  bool _hasUsedBreak = false;
  bool _isSaving = false;
  bool _isStarting = false;
  bool _isUsingPotion = false;
  bool _streakBlockedByEvent = false;
  int _eventRewardBonusMinutes = 0;
  int _eventBonusXp = 0;
  int _eventBonusGold = 0;
  int _completedFocusEvents = 0;
  int _failedFocusEvents = 0;
  int? _nextFocusEventAtMilliseconds;
  bool _isFocusEventActive = false;
  bool _didPrecacheFocusTreeAssets = false;
  String? _selectedAmbientSoundId;
  bool _isAmbientShuffleEnabled = false;
  final List<FocusEventResult> _eventResults = <FocusEventResult>[];
  Timer? _sessionToastTimer;
  String? _sessionToastText;
  bool _sessionToastVisible = false;

  bool get _isRunning => _startedAt != null;
  bool get _isBreakActive => _breakStartedAt != null;
  bool get _canSetBreak =>
      _isRunning &&
      !_isBreakActive &&
      !_hasUsedBreak &&
      _elapsedMilliseconds >= _breakUnlockSeconds * 1000;
  int get _totalFocusSeconds =>
      _baseFocusTargetSeconds + (_sessionEffects.rewardBonusMinutes * 60);
  double get _focusProgress =>
      (_elapsedMilliseconds / (_totalFocusSeconds * 1000)).clamp(0.0, 1.0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheFocusTreeAssets();
    unawaited(FocusEventSoundService.instance.initialize());
    if (_profileId != null) {
      return;
    }

    final Object? arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is FocusSessionArguments) {
      _profileId = arguments.profileId;
      _selectedPotionIds = List<String>.from(arguments.selectedPotionIds);
    } else if (arguments is int) {
      _profileId = arguments;
    }
    _recalculatePotionEffects();
  }

  void _precacheFocusTreeAssets() {
    if (_didPrecacheFocusTreeAssets) {
      return;
    }
    _didPrecacheFocusTreeAssets = true;
    for (final String assetPath in _AncientWorldTreeBackground.treeStages) {
      precacheImage(AssetImage(assetPath), context);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sessionToastTimer?.cancel();
    unawaited(_ambientAudioService.stop());
    super.dispose();
  }

  Future<void> _confirmStart() async {
    if (_isRunning) {
      return;
    }

    final bool shouldStart =
        await _showConfirmDialog(
          title: 'Start Session',
          content: 'Do you want to start a session?',
          confirmLabel: 'Start',
        ) ??
        false;

    if (!shouldStart) {
      return;
    }

    await _start();
  }

  Future<void> _start() async {
    final int? profileId = _profileId;
    if (profileId == null || _isStarting) {
      return;
    }

    setState(() {
      _isStarting = true;
    });

    final InventoryMutationResult consumeResult = await _inventoryService
        .consumeSelectedPotionsForSession(
          profileId: profileId,
          selectedPotionIds: _selectedPotionIds,
        );

    if (!consumeResult.success) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(consumeResult.message ?? 'Invalid loadout.')),
      );
      setState(() {
        _isStarting = false;
      });
      return;
    }

    final PlayerSave? save = await _saveService.getSaveById(profileId);
    if (!mounted) {
      return;
    }

    setState(() {
      _playerClass = save?.playerClass ?? '';
      _startedAt = DateTime.now();
      _focusResumedAt = _startedAt;
      _focusAccumulatedMilliseconds = 0;
      _elapsedMilliseconds = 0;
      _totalSessionMilliseconds = 0;
      _breakStartedAt = null;
      _breakRemainingSeconds = _sessionEffects.breakDurationSeconds;
      _debugTimeMultiplier = 1;
      _lastTreeDebugElapsedSecond = null;
      _hasUsedBreak = false;
      _eventRewardBonusMinutes = 0;
      _eventBonusXp = 0;
      _eventBonusGold = 0;
      _completedFocusEvents = 0;
      _failedFocusEvents = 0;
      _eventResults.clear();
      _nextFocusEventAtMilliseconds = _eventService
          .nextEventDeadlineMilliseconds(baseMilliseconds: 0);
      _isFocusEventActive = false;
      _streakBlockedByEvent = false;
      _sessionToastTimer?.cancel();
      _sessionToastText = null;
      _sessionToastVisible = false;
      _isStarting = false;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final DateTime? startedAt = _startedAt;
      if (startedAt == null || !mounted) {
        return;
      }

      final DateTime now = DateTime.now();
      final DateTime? breakStartedAt = _breakStartedAt;
      final DateTime? focusResumedAt = _focusResumedAt;

      if (!mounted) {
        return;
      }

      setState(() {
        _totalSessionMilliseconds = now.difference(startedAt).inMilliseconds;

        if (breakStartedAt == null && focusResumedAt != null) {
          _elapsedMilliseconds =
              _focusAccumulatedMilliseconds +
              now.difference(focusResumedAt).inMilliseconds *
                  _debugTimeMultiplier;
        } else {
          _elapsedMilliseconds = _focusAccumulatedMilliseconds;
        }

        if (breakStartedAt != null) {
          final int breakElapsed = now.difference(breakStartedAt).inSeconds;
          _breakRemainingSeconds =
              (_sessionEffects.breakDurationSeconds - breakElapsed)
                  .clamp(0, _sessionEffects.breakDurationSeconds)
                  .toInt();

          if (_breakRemainingSeconds == 0) {
            _breakStartedAt = null;
            _focusResumedAt = now;
          }
        }
      });

      _logTreeDebug();
      _maybeLaunchScheduledFocusEvent();
    });
  }

  void _setDebugTimeMultiplier(int multiplier) {
    if (_debugTimeMultiplier == multiplier) {
      return;
    }

    final DateTime now = DateTime.now();
    setState(() {
      if (_isRunning && !_isBreakActive) {
        _focusAccumulatedMilliseconds = _elapsedMilliseconds;
        _focusResumedAt = now;
      }
      _debugTimeMultiplier = multiplier;
    });
  }

  Future<void> _setBreak() async {
    if (!_canSetBreak) {
      return;
    }

    final bool shouldSetBreak =
        await _showConfirmDialog(
          title: 'Set a Break',
          content: 'Are you sure you want to start a 10 minute break?',
          confirmLabel: 'Yes',
        ) ??
        false;

    if (!shouldSetBreak) {
      return;
    }

    setState(() {
      _focusAccumulatedMilliseconds = _elapsedMilliseconds;
      _breakStartedAt = DateTime.now();
      _focusResumedAt = null;
      _breakRemainingSeconds = _sessionEffects.breakDurationSeconds;
      _hasUsedBreak = true;
    });
  }

  Future<void> _cancelSession() async {
    if (!_isRunning) {
      Navigator.of(context).maybePop();
      return;
    }

    final bool shouldClose =
        await _showConfirmDialog(
          title: 'Close Session',
          content: 'Are you sure you want to close the session?',
          confirmLabel: 'Yes',
        ) ??
        false;

    if (!shouldClose || !mounted) {
      return;
    }

    Navigator.of(context).pop(false);
  }

  Future<void> _openAmbientSoundMenu() async {
    bool draftShuffleEnabled = _isAmbientShuffleEnabled;
    String? draftSoundId = draftShuffleEnabled ? null : _selectedAmbientSoundId;
    bool draftIsPaused = _ambientAudioService.isPaused;
    bool draftCanPlayPrevious = _ambientAudioService.canPlayPrevious;

    void syncAmbientState() {
      if (!mounted) {
        return;
      }
      setState(() {
        _isAmbientShuffleEnabled = _ambientAudioService.isShuffleEnabled;
        _selectedAmbientSoundId = _ambientAudioService.activeSoundId;
      });
    }

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close ambient sound menu',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final Animation<Offset> offsetAnimation =
            Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        return SlideTransition(position: offsetAnimation, child: child);
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        final Size screenSize = MediaQuery.sizeOf(context);
        final double panelWidth = (screenSize.width * 0.72).clamp(280.0, 340.0);
        final double panelHeight = (screenSize.height * 0.56).clamp(
          360.0,
          480.0,
        );

        return AppSafeLayout(
          horizontal: 0,
          top: 8,
          bottom: 8,
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: panelWidth,
              height: panelHeight,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                elevation: 12,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18),
                ),
                clipBehavior: Clip.antiAlias,
                child: StatefulBuilder(
                  builder: (context, setSheetState) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Ambient Sound',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _ShuffleAmbientButton(
                                  isEnabled: draftShuffleEnabled,
                                  onPressed: () async {
                                    final bool nextShuffleEnabled =
                                        !draftShuffleEnabled;
                                    if (nextShuffleEnabled) {
                                      await _ambientAudioService
                                          .enableShuffleAfterCurrent();
                                    } else {
                                      await _ambientAudioService
                                          .setShuffleEnabled(false);
                                    }
                                    syncAmbientState();
                                    setSheetState(() {
                                      draftShuffleEnabled =
                                          _ambientAudioService.isShuffleEnabled;
                                      if (draftShuffleEnabled) {
                                        draftSoundId = null;
                                      } else {
                                        draftSoundId =
                                            _ambientAudioService.activeSoundId;
                                      }
                                      draftIsPaused =
                                          _ambientAudioService.isPaused;
                                      draftCanPlayPrevious =
                                          _ambientAudioService.canPlayPrevious;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              _AmbientTransportButton(
                                icon: Icons.chevron_left,
                                onPressed: draftCanPlayPrevious
                                    ? () async {
                                        await _ambientAudioService
                                            .playPrevious();
                                        syncAmbientState();
                                        setSheetState(() {
                                          draftShuffleEnabled =
                                              _ambientAudioService
                                                  .isShuffleEnabled;
                                          draftSoundId = draftShuffleEnabled
                                              ? null
                                              : _ambientAudioService
                                                    .activeSoundId;
                                          draftIsPaused =
                                              _ambientAudioService.isPaused;
                                          draftCanPlayPrevious =
                                              _ambientAudioService
                                                  .canPlayPrevious;
                                        });
                                      }
                                    : null,
                              ),
                              const SizedBox(width: 6),
                              _AmbientTransportButton(
                                icon: draftIsPaused
                                    ? Icons.play_arrow
                                    : Icons.pause,
                                onPressed:
                                    _ambientAudioService.activeSoundId == null
                                    ? null
                                    : () async {
                                        final bool isPaused =
                                            await _ambientAudioService
                                                .togglePause();
                                        setSheetState(() {
                                          draftIsPaused = isPaused;
                                        });
                                      },
                              ),
                              const SizedBox(width: 6),
                              _AmbientTransportButton(
                                icon: Icons.chevron_right,
                                onPressed: () async {
                                  await _ambientAudioService.skipToNext();
                                  syncAmbientState();
                                  setSheetState(() {
                                    draftShuffleEnabled =
                                        _ambientAudioService.isShuffleEnabled;
                                    draftSoundId = draftShuffleEnabled
                                        ? null
                                        : _ambientAudioService.activeSoundId;
                                    draftIsPaused =
                                        _ambientAudioService.isPaused;
                                    draftCanPlayPrevious =
                                        _ambientAudioService.canPlayPrevious;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: GridView.builder(
                              itemCount: AmbientAudioService.sounds.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 1,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 4.2,
                                  ),
                              itemBuilder: (context, index) {
                                final AmbientSound sound =
                                    AmbientAudioService.sounds[index];
                                final bool isSelected =
                                    draftSoundId == sound.id;
                                return OutlinedButton.icon(
                                  onPressed: () async {
                                    try {
                                      await _ambientAudioService.play(sound);
                                    } catch (error) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Ambient sound could not be played.',
                                            ),
                                          ),
                                        );
                                      }
                                      return;
                                    }
                                    syncAmbientState();
                                    setSheetState(() {
                                      draftShuffleEnabled =
                                          _ambientAudioService.isShuffleEnabled;
                                      draftSoundId = draftShuffleEnabled
                                          ? null
                                          : _ambientAudioService.activeSoundId;
                                      draftIsPaused =
                                          _ambientAudioService.isPaused;
                                      draftCanPlayPrevious =
                                          _ambientAudioService.canPlayPrevious;
                                    });
                                  },
                                  icon: Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                  ),
                                  label: Text(
                                    sound.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    alignment: Alignment.centerLeft,
                                    side: isSelected
                                        ? BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _recalculatePotionEffects() {
    _sessionEffects = PotionSessionEffects.fromPotionIds(_selectedPotionIds);
  }

  Future<void> _openPotionBag() async {
    final int? profileId = _profileId;
    if (profileId == null || !_isRunning || _isUsingPotion) {
      return;
    }

    final List<InventoryPotion> potions = await _inventoryService
        .getInventoryPotions(profileId: profileId);
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final List<PotionDefinition> definitions = PotionCatalog.potions
            .where(
              (PotionDefinition potion) => potions.any(
                (InventoryPotion owned) =>
                    owned.potionId == potion.id && owned.quantity > 0,
              ),
            )
            .toList();

        if (definitions.isEmpty) {
          return AppSafeLayout(
            horizontal: 24,
            top: 8,
            bottom: 18,
            child: const Center(child: Text('No potions available.')),
          );
        }

        final Map<String, int> quantities = <String, int>{
          for (final InventoryPotion potion in potions)
            potion.potionId: potion.quantity,
        };

        return AppSafeLayout(
          horizontal: 0,
          top: 4,
          bottom: 8,
          child: ListView.separated(
            padding: AppSafeSpacing.listPadding(context, top: 8, bottom: 18),
            itemCount: definitions.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final PotionDefinition definition = definitions[index];
              return ListTile(
                leading: const Icon(Icons.local_drink),
                title: Text(definition.name),
                subtitle: Text(definition.effectSummary),
                trailing: FilledButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _usePotion(definition.id);
                  },
                  child: Text('Use (${quantities[definition.id] ?? 0})'),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _usePotion(String potionId) async {
    final int? profileId = _profileId;
    if (profileId == null || !_isRunning || _isUsingPotion) {
      return;
    }

    final List<String> nextSelection = <String>[
      ..._selectedPotionIds,
      potionId,
    ];
    final PotionLoadoutValidationResult validation = _inventoryService
        .validateSessionPotionLoadout(nextSelection);
    if (!validation.isValid) {
      _showSnack(validation.message ?? 'Invalid potion loadout.');
      return;
    }

    setState(() {
      _isUsingPotion = true;
    });

    final InventoryMutationResult result = await _inventoryService.removePotion(
      profileId: profileId,
      potionId: potionId,
    );
    if (!mounted) {
      return;
    }

    if (!result.success) {
      _showSnack(result.message ?? 'Could not use potion.');
      setState(() {
        _isUsingPotion = false;
      });
      return;
    }

    setState(() {
      _selectedPotionIds.add(potionId);
      _recalculatePotionEffects();
      _breakRemainingSeconds = _sessionEffects.breakDurationSeconds;
      _isUsingPotion = false;
    });
    _showSnack('${PotionCatalog.byId(potionId).name} used.');
  }

  void _maybeLaunchScheduledFocusEvent() {
    final int? nextEventAt = _nextFocusEventAtMilliseconds;
    if (nextEventAt == null ||
        !_isRunning ||
        _isBreakActive ||
        _isFocusEventActive ||
        _isSaving ||
        _elapsedMilliseconds < nextEventAt) {
      return;
    }

    setState(() {
      _isFocusEventActive = true;
    });
    unawaited(_launchFocusEvent());
  }

  Future<void> _launchFocusEvent() async {
    final FocusEventChallenge challenge = _eventService.createChallenge(
      playerClass: _playerClass,
    );
    // ignore: avoid_print
    print('EVENT DIALOG OPEN');
    unawaited(FocusEventSoundService.instance.playIncomingEvent());

    final FocusEventResult result =
        await showDialog<FocusEventResult>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return FocusEventDialog(challenge: challenge);
          },
        ) ??
        FocusEventResult(
          challenge: challenge,
          outcome: FocusEventOutcome.missed,
        );

    if (!mounted) {
      return;
    }

    late final String toastMessage;
    setState(() {
      toastMessage = _resolveFocusEvent(result);
      _nextFocusEventAtMilliseconds = _eventService
          .nextEventDeadlineMilliseconds(
            baseMilliseconds: _elapsedMilliseconds,
          );
      _isFocusEventActive = false;
    });
    _showSessionToast(toastMessage);
  }

  String _resolveFocusEvent(FocusEventResult result) {
    _eventResults.add(result);

    if (result.isSuccess) {
      final int earnedGold =
          (result.earnedGold * _sessionEffects.eventRewardMultiplier).round();
      final int earnedXp =
          (result.earnedXp * _sessionEffects.eventRewardMultiplier).round();
      _completedFocusEvents += 1;
      _eventBonusGold += earnedGold;
      _eventBonusXp += earnedXp;
      return result.outcome == FocusEventOutcome.perfect
          ? 'Perfect timing! +$earnedGold Gold'
          : 'Success! +$earnedGold Gold';
    }

    _failedFocusEvents += 1;
    return 'Event Failed';
  }

  void _showSessionToast(String message) {
    _sessionToastTimer?.cancel();
    setState(() {
      _sessionToastText = message;
      _sessionToastVisible = true;
    });

    _sessionToastTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _sessionToastVisible = false;
      });

      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) {
          return;
        }
        if (!_sessionToastVisible && _sessionToastText == message) {
          setState(() {
            _sessionToastText = null;
          });
        }
      });
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _logTreeDebug() {
    final int elapsedFocusSeconds = _elapsedMilliseconds ~/ 1000;
    if (_lastTreeDebugElapsedSecond == elapsedFocusSeconds) {
      return;
    }
    _lastTreeDebugElapsedSecond = elapsedFocusSeconds;

    final double progress = _focusProgress;
    final int stageIndex = _AncientWorldTreeBackground.stageIndexForProgress(
      progress,
    );
    final String assetPath = _AncientWorldTreeBackground.treeStages[stageIndex];
    final List<double> stageOpacities =
        _AncientWorldTreeBackground.stageOpacitiesForProgress(progress);

    // ignore: avoid_print
    print(
      'TREE_DEBUG: '
      'elapsedFocusSeconds=$elapsedFocusSeconds '
      'totalFocusSeconds=$_totalFocusSeconds '
      'progress=${progress.toStringAsFixed(3)} '
      'stageIndex=$stageIndex '
      'assetPath=$assetPath '
      'stageOpacities=$stageOpacities',
    );
  }

  int? _secondsUntilNextFocusEvent() {
    final int? nextEventAt = _nextFocusEventAtMilliseconds;
    if (!_isRunning || nextEventAt == null) {
      return null;
    }
    return ((nextEventAt - _elapsedMilliseconds) / 1000).ceil().clamp(0, 9999);
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _complete() async {
    final int? profileId = _profileId;
    final DateTime? startedAt = _startedAt;
    if (profileId == null || startedAt == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final DateTime endedAt = DateTime.now();
    final int durationMinutes = (_elapsedMilliseconds ~/ 60000)
        .clamp(0, 999)
        .toInt();

    try {
      await _saveService.completeFocusSession(
        profileId: profileId,
        durationMinutes: durationMinutes,
        startedAt: startedAt.toIso8601String(),
        endedAt: endedAt.toIso8601String(),
        xpMultiplier: _sessionEffects.xpMultiplier,
        goldMultiplier: _sessionEffects.goldMultiplier,
        rewardBonusMinutes:
            _sessionEffects.rewardBonusMinutes + _eventRewardBonusMinutes,
        eventBonusXp: _eventBonusXp,
        eventBonusGold: _eventBonusGold,
        firstSessionXpBonusMultiplier:
            _sessionEffects.firstSessionXpBonusMultiplier,
        allowStreakProgress: !_streakBlockedByEvent,
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
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String timerText = _formatDuration(_elapsedMilliseconds ~/ 1000);
    final String totalTimerText = _formatDuration(
      _totalSessionMilliseconds ~/ 1000,
    );
    final double breakProgress =
        (_elapsedMilliseconds / (_breakUnlockSeconds * 1000))
            .clamp(0, 1)
            .toDouble();
    final double sessionProgress = _focusProgress;
    // ignore: avoid_print
    print('FocusSession build');
    // ignore: avoid_print
    print('progress: $sessionProgress');

    return Scaffold(
      body: AppSafeLayout(
        horizontal: 0,
        top: 10,
        bottom: 8,
        child: Stack(
          children: [
            Positioned.fill(
              child: _AncientWorldTreeBackground(progress: sessionProgress),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FocusSessionHeader(
                        totalTimerText: totalTimerText,
                        onBack: _isSaving || _isStarting
                            ? null
                            : _cancelSession,
                      ),
                      const SizedBox(height: 12),
                      _FocusEventStatusPill(
                        secondsUntilNext: _secondsUntilNextFocusEvent(),
                        isActive: _isFocusEventActive,
                        completedCount: _completedFocusEvents,
                        failedCount: _failedFocusEvents,
                        bonusGold: _eventBonusGold,
                        bonusXp: _eventBonusXp,
                        formatDuration: _formatDuration,
                      ),
                      if (_selectedPotionIds.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _ActivePotionEffects(effects: _sessionEffects),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _PotionMenuButton(
                            isEnabled:
                                _isRunning &&
                                !_isSaving &&
                                !_isStarting &&
                                !_isFocusEventActive,
                            isUsingPotion: _isUsingPotion,
                            onPressed: _openPotionBag,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _PotionMenuButton(
                            isEnabled:
                                _isRunning &&
                                !_isSaving &&
                                !_isStarting &&
                                !_isFocusEventActive,
                            isUsingPotion: _isUsingPotion,
                            onPressed: _openPotionBag,
                          ),
                        ),
                      ],
                      const Spacer(flex: 5),
                      Text(
                        timerText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _statusText(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_isBreakActive) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Break ${_formatDuration(_breakRemainingSeconds)}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                      const Spacer(flex: 3),
                      if (_sessionToastText != null) ...[
                        _RewardToast(
                          message: _sessionToastText!,
                          isVisible: _sessionToastVisible,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _DebugTimeMultiplierControl(
                        multiplier: _debugTimeMultiplier,
                        isEnabled: !_isSaving && !_isStarting,
                        onChanged: _setDebugTimeMultiplier,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 54,
                        child: _primarySessionButton(breakProgress),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton(
                                onPressed: _isSaving || _isStarting
                                    ? null
                                    : _cancelSession,
                                child: const Text('Cancel'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: FilledButton(
                                onPressed:
                                    _isRunning &&
                                        !_isSaving &&
                                        !_isBreakActive &&
                                        !_isStarting &&
                                        !_isFocusEventActive
                                    ? _complete
                                    : null,
                                style: FilledButton.styleFrom(
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    height: 1.05,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check, size: 17),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _isSaving
                                            ? 'Saving...'
                                            : 'Complete\nSession',
                                        maxLines: 2,
                                        overflow: TextOverflow.visible,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
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
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: _AmbientDrawerTab(
                  isEnabled: !_isSaving && !_isStarting,
                  onPressed: _openAmbientSoundMenu,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primarySessionButton(double breakProgress) {
    if (!_isRunning) {
      return ElevatedButton.icon(
        onPressed: _isStarting ? null : _confirmStart,
        icon: const Icon(Icons.play_arrow),
        label: Text(_isStarting ? 'Starting...' : 'Start'),
      );
    }

    return _BreakProgressButton(
      progress: breakProgress,
      enabled: _canSetBreak && !_sessionEffects.breaksDisabled,
      label: _sessionEffects.breaksDisabled
          ? 'Breaks Disabled'
          : _hasUsedBreak
          ? 'Break Used'
          : 'Set a Break',
      onPressed: _setBreak,
    );
  }

  String _statusText() {
    if (!_isRunning) {
      return 'Ready to focus';
    }
    if (_isBreakActive) {
      return 'Break running';
    }
    if (_isFocusEventActive) {
      return 'Focus event active';
    }
    return 'Session running';
  }

  String _formatDuration(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _ShuffleAmbientButton extends StatelessWidget {
  const _ShuffleAmbientButton({
    required this.isEnabled,
    required this.onPressed,
  });

  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 38,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(isEnabled ? Icons.shuffle_on : Icons.shuffle, size: 18),
        label: Text(isEnabled ? 'Shuffle ON' : 'Shuffle OFF'),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          backgroundColor: isEnabled
              ? colors.primary.withValues(alpha: 0.16)
              : null,
          side: BorderSide(
            color: isEnabled ? colors.primary : colors.outlineVariant,
            width: isEnabled ? 2 : 1,
          ),
        ),
      ),
    );
  }
}

class _AmbientTransportButton extends StatelessWidget {
  const _AmbientTransportButton({required this.icon, required this.onPressed});

  final IconData icon;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isEnabled = onPressed != null;

    return SizedBox.square(
      dimension: 38,
      child: OutlinedButton(
        onPressed: isEnabled ? () => unawaited(onPressed!()) : null,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(
            color: isEnabled ? colors.primary : colors.outlineVariant,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

class _AmbientDrawerTab extends StatelessWidget {
  const _AmbientDrawerTab({required this.isEnabled, required this.onPressed});

  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      enabled: isEnabled,
      onTap: isEnabled ? onPressed : null,
      child: Material(
        color: isEnabled
            ? colors.primaryContainer
            : colors.surfaceContainerHigh,
        elevation: isEnabled ? 4 : 0,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          child: SizedBox(
            width: 34,
            height: 52,
            child: Center(
              child: Text(
                '<',
                style: TextStyle(
                  color: isEnabled
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PotionMenuButton extends StatelessWidget {
  const _PotionMenuButton({
    required this.isEnabled,
    required this.isUsingPotion,
    required this.onPressed,
  });

  final bool isEnabled;
  final bool isUsingPotion;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: OutlinedButton.icon(
        onPressed: isEnabled ? onPressed : null,
        icon: const Icon(Icons.local_drink, size: 18),
        label: Text(isUsingPotion ? 'Using...' : 'Potions'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class PotionSessionEffects {
  const PotionSessionEffects({
    this.xpMultiplier = 1.0,
    this.goldMultiplier = 1.0,
    this.eventRewardMultiplier = 1.0,
    this.eventPenaltyMultiplier = 1.0,
    this.idlePenaltyMultiplier = 1.0,
    this.failurePenaltyMultiplier = 1.0,
    this.firstSessionXpBonusMultiplier = 1.0,
    this.rareEventChanceBonus = 0.0,
    this.rewardBonusMinutes = 0,
    this.breakBonusSeconds = 0,
    this.breaksDisabled = false,
    this.failureProtectionCharges = 0,
    this.streakProtectionCharges = 0,
    this.labels = const <String>[],
  });

  final double xpMultiplier;
  final double goldMultiplier;
  final double eventRewardMultiplier;
  final double eventPenaltyMultiplier;
  final double idlePenaltyMultiplier;
  final double failurePenaltyMultiplier;
  final double firstSessionXpBonusMultiplier;
  final double rareEventChanceBonus;
  final int rewardBonusMinutes;
  final int breakBonusSeconds;
  final bool breaksDisabled;
  final int failureProtectionCharges;
  final int streakProtectionCharges;
  final List<String> labels;

  int get breakDurationSeconds => breaksDisabled
      ? 0
      : _FocusSessionPageState._baseBreakDurationSeconds + breakBonusSeconds;

  static PotionSessionEffects fromPotionIds(List<String> potionIds) {
    double xpMultiplier = 1.0;
    double goldMultiplier = 1.0;
    double eventRewardMultiplier = 1.0;
    double eventPenaltyMultiplier = 1.0;
    double idlePenaltyMultiplier = 1.0;
    double failurePenaltyMultiplier = 1.0;
    double firstSessionXpBonusMultiplier = 1.0;
    double rareEventChanceBonus = 0.0;
    int rewardBonusMinutes = 0;
    int breakBonusSeconds = 0;
    int failureProtectionCharges = 0;
    int streakProtectionCharges = 0;
    bool breaksDisabled = false;
    final List<String> labels = <String>[];

    for (final String potionId in potionIds) {
      final PotionDefinition potion = PotionCatalog.byId(potionId);
      labels.add(potion.effectSummary);

      switch (potion.effectType) {
        case PotionEffectType.xpBoost:
          xpMultiplier += potion.effectValue;
          break;
        case PotionEffectType.goldBoost:
          goldMultiplier += potion.effectValue;
          break;
        case PotionEffectType.breakExtension:
          breakBonusSeconds += (potion.effectValue * 60).round();
          break;
        case PotionEffectType.focusDurationExtension:
          rewardBonusMinutes += potion.effectValue.round();
          break;
        case PotionEffectType.rewardRisk:
          xpMultiplier *= potion.effectValue;
          goldMultiplier *= potion.effectValue;
          failurePenaltyMultiplier *= potion.effectValue;
          break;
        case PotionEffectType.overmind:
          xpMultiplier *= 1.5;
          goldMultiplier *= 1.5;
          breaksDisabled = true;
          break;
        case PotionEffectType.eventPenaltyReduction:
          eventPenaltyMultiplier *= 0.5;
          break;
        case PotionEffectType.eventRewardBoost:
          eventRewardMultiplier *= 1.5;
          break;
        case PotionEffectType.streakProtection:
          streakProtectionCharges += potion.effectValue.round();
          break;
        case PotionEffectType.failureProtection:
          failureProtectionCharges += potion.effectValue.round();
          break;
        case PotionEffectType.idlePenaltyReduction:
          idlePenaltyMultiplier *= 0.5;
          break;
        case PotionEffectType.dailyFirstSessionBonus:
          firstSessionXpBonusMultiplier *= 1.25;
          break;
        case PotionEffectType.shopDiscount:
          goldMultiplier += potion.effectValue;
          break;
        case PotionEffectType.rareEventChance:
          rareEventChanceBonus += 0.35;
          break;
      }
    }

    return PotionSessionEffects(
      xpMultiplier: xpMultiplier,
      goldMultiplier: goldMultiplier,
      eventRewardMultiplier: eventRewardMultiplier,
      eventPenaltyMultiplier: eventPenaltyMultiplier,
      idlePenaltyMultiplier: idlePenaltyMultiplier,
      failurePenaltyMultiplier: failurePenaltyMultiplier,
      firstSessionXpBonusMultiplier: firstSessionXpBonusMultiplier,
      rareEventChanceBonus: rareEventChanceBonus,
      rewardBonusMinutes: rewardBonusMinutes,
      breakBonusSeconds: breakBonusSeconds,
      breaksDisabled: breaksDisabled,
      failureProtectionCharges: failureProtectionCharges,
      streakProtectionCharges: streakProtectionCharges,
      labels: List<String>.unmodifiable(labels),
    );
  }
}

class _AncientWorldTreeBackground extends StatelessWidget {
  static const List<String> treeStages = <String>[
    'assets/focus_tree/tree_stage_1.png',
    'assets/focus_tree/tree_stage_2.png',
    'assets/focus_tree/tree_stage_3.png',
    'assets/focus_tree/tree_stage_4.png',
  ];

  final double progress;

  const _AncientWorldTreeBackground({required this.progress});

  @override
  Widget build(BuildContext context) {
    // ignore: avoid_print
    print('background mounted');
    final List<double> stageOpacities = stageOpacitiesForProgress(progress);

    return IgnorePointer(
      ignoring: true,
      child: RepaintBoundary(
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (int index = 0; index < treeStages.length; index += 1)
                Opacity(
                  opacity: stageOpacities[index],
                  child: Image.asset(
                    treeStages[index],
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.low,
                  ),
                ),
              const ColoredBox(color: Color(0x66000000)),
            ],
          ),
        ),
      ),
    );
  }

  static int stageIndexForProgress(double rawProgress) {
    final double progress = rawProgress.clamp(0.0, 1.0);
    if (progress < 0.25) {
      return 0;
    }
    if (progress < 0.50) {
      return 1;
    }
    if (progress < 0.75) {
      return 2;
    }
    return 3;
  }

  static List<double> stageOpacitiesForProgress(double progress) {
    return switch (stageIndexForProgress(progress)) {
      0 => const <double>[1, 0, 0, 0],
      1 => const <double>[0, 1, 0, 0],
      2 => const <double>[0, 0, 1, 0],
      _ => const <double>[0, 0, 0, 1],
    };
  }
}

class _ActivePotionEffects extends StatelessWidget {
  const _ActivePotionEffects({required this.effects});

  final PotionSessionEffects effects;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Potions',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            for (final String label in effects.labels.take(3))
              Text('• $label', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _RewardToast extends StatelessWidget {
  const _RewardToast({required this.message, required this.isVisible});

  final String message;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: isVisible ? 1 : 0,
        duration: Duration(milliseconds: isVisible ? 300 : 500),
        curve: Curves.easeOutCubic,
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.brightness == Brightness.dark
                ? const Color(0xFFFFF3C4)
                : Colors.white,
            fontWeight: FontWeight.w800,
            shadows: const <Shadow>[
              Shadow(
                color: Colors.black87,
                offset: Offset(0, 1),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusEventStatusPill extends StatelessWidget {
  const _FocusEventStatusPill({
    required this.secondsUntilNext,
    required this.isActive,
    required this.completedCount,
    required this.failedCount,
    required this.bonusGold,
    required this.bonusXp,
    required this.formatDuration,
  });

  final int? secondsUntilNext;
  final bool isActive;
  final int completedCount;
  final int failedCount;
  final int bonusGold;
  final int bonusXp;
  final String Function(int totalSeconds) formatDuration;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int? next = secondsUntilNext;
    final String status = isActive
        ? 'Focus event active'
        : next == null
        ? 'Events pending'
        : 'Next event ${formatDuration(next)}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Icon(Icons.bolt, size: 18, color: colors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                status,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '$completedCount / $failedCount  +$bonusGold G  +$bonusXp XP',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakProgressButton extends StatelessWidget {
  const _BreakProgressButton({
    required this.progress,
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  final double progress;
  final bool enabled;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final BorderRadius borderRadius = BorderRadius.circular(999);
    final Color borderColor = enabled ? colors.primary : colors.outlineVariant;
    final Color contentColor = enabled
        ? colors.primary
        : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      enabled: enabled,
      onTap: enabled ? onPressed : null,
      child: Material(
        color: colors.surface,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: enabled ? onPressed : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(color: borderColor),
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: ColoredBox(
                      color: colors.primary.withValues(alpha: 0.32),
                    ),
                  ),
                  Center(
                    child: IconTheme(
                      data: IconThemeData(color: contentColor, size: 20),
                      child: DefaultTextStyle(
                        style: TextStyle(
                          color: contentColor,
                          fontWeight: FontWeight.w700,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.free_breakfast),
                            const SizedBox(width: 10),
                            Text(label),
                          ],
                        ),
                      ),
                    ),
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

class _DebugTimeMultiplierControl extends StatelessWidget {
  const _DebugTimeMultiplierControl({
    required this.multiplier,
    required this.isEnabled,
    required this.onChanged,
  });

  final int multiplier;
  final bool isEnabled;
  final ValueChanged<int> onChanged;

  static const List<int> _multipliers = <int>[1, 5, 15];

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 38,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.76),
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Row(
            children: [
              for (final int value in _multipliers)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _DebugTimeMultiplierButton(
                      value: value,
                      isSelected: multiplier == value,
                      isEnabled: isEnabled,
                      onPressed: () => onChanged(value),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebugTimeMultiplierButton extends StatelessWidget {
  const _DebugTimeMultiplierButton({
    required this.value,
    required this.isSelected,
    required this.isEnabled,
    required this.onPressed,
  });

  final int value;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color foregroundColor = isSelected
        ? colors.onPrimary
        : colors.onSurfaceVariant;

    return TextButton(
      onPressed: isEnabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor,
        backgroundColor: isSelected ? colors.primary : Colors.transparent,
        disabledForegroundColor: colors.onSurface.withValues(alpha: 0.38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        padding: EdgeInsets.zero,
      ),
      child: Text('${value}x'),
    );
  }
}

class _FocusSessionHeader extends StatelessWidget {
  const _FocusSessionHeader({
    required this.totalTimerText,
    required this.onBack,
  });

  final String totalTimerText;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.primary.withValues(alpha: 0.6)),
            ),
            child: IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Focus Session',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFFF2D4),
                shadows: const <Shadow>[
                  Shadow(
                    color: Colors.black87,
                    offset: Offset(0, 1),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _TotalSessionPill(totalTimerText: totalTimerText),
        ],
      ),
    );
  }
}

class _TotalSessionPill extends StatelessWidget {
  const _TotalSessionPill({required this.totalTimerText});

  final String totalTimerText;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          'Total $totalTimerText',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
