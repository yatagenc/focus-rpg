import 'dart:async';

import 'package:flutter/material.dart';

import '../data/potion_catalog.dart';
import '../models/potion_definition.dart';
import '../models/potion_effect_type.dart';
import '../services/inventory_service.dart';
import '../services/save_service.dart';

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
  static const int _breakUnlockSeconds = 60;
  static const int _baseBreakDurationSeconds = 10 * 60;

  final SaveService _saveService = SaveService();
  final InventoryService _inventoryService = InventoryService.instance;

  Timer? _timer;
  int? _profileId;
  List<String> _selectedPotionIds = <String>[];
  late PotionSessionEffects _sessionEffects = const PotionSessionEffects();
  DateTime? _startedAt;
  DateTime? _focusResumedAt;
  DateTime? _breakStartedAt;
  int _focusAccumulatedMilliseconds = 0;
  int _elapsedMilliseconds = 0;
  int _totalSessionMilliseconds = 0;
  int _breakRemainingSeconds = _baseBreakDurationSeconds;
  bool _hasUsedBreak = false;
  bool _isSaving = false;
  bool _isStarting = false;

  bool get _isRunning => _startedAt != null;
  bool get _isBreakActive => _breakStartedAt != null;
  bool get _canSetBreak =>
      _isRunning &&
      !_isBreakActive &&
      !_hasUsedBreak &&
      _elapsedMilliseconds >= _breakUnlockSeconds * 1000;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    _sessionEffects = PotionSessionEffects.fromPotionIds(_selectedPotionIds);
  }

  @override
  void dispose() {
    _timer?.cancel();
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

    final InventoryMutationResult consumeResult = _inventoryService
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

    setState(() {
      _startedAt = DateTime.now();
      _focusResumedAt = _startedAt;
      _focusAccumulatedMilliseconds = 0;
      _elapsedMilliseconds = 0;
      _totalSessionMilliseconds = 0;
      _breakStartedAt = null;
      _breakRemainingSeconds = _sessionEffects.breakDurationSeconds;
      _hasUsedBreak = false;
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

      setState(() {
        _totalSessionMilliseconds = now.difference(startedAt).inMilliseconds;

        if (breakStartedAt == null && focusResumedAt != null) {
          _elapsedMilliseconds =
              _focusAccumulatedMilliseconds +
              now.difference(focusResumedAt).inMilliseconds;
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

  void _addTestMinute() {
    if (!_isRunning) {
      return;
    }

    setState(() {
      _focusAccumulatedMilliseconds += 60000;
      _elapsedMilliseconds += 60000;
    });
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
        rewardBonusMinutes: _sessionEffects.rewardBonusMinutes,
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: _isSaving || _isStarting ? null : _cancelSession,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Focus Session'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _TotalSessionPill(totalTimerText: totalTimerText),
                  ),
                  if (_selectedPotionIds.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ActivePotionEffects(effects: _sessionEffects),
                  ],
                  const Spacer(),
                  Text(
                    timerText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 56,
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
                  const Spacer(),
                  SizedBox(
                    height: 54,
                    child: _primarySessionButton(breakProgress),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isRunning && !_isSaving && !_isStarting
                          ? _addTestMinute
                          : null,
                      icon: const Icon(Icons.add),
                      label: const Text('+1 min'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed:
                          _isRunning &&
                              !_isSaving &&
                              !_isBreakActive &&
                              !_isStarting
                          ? _complete
                          : null,
                      icon: const Icon(Icons.check),
                      label: Text(_isSaving ? 'Saving...' : 'Complete Session'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _isSaving || _isStarting
                          ? null
                          : _cancelSession,
                      child: const Text('Cancel'),
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
    return 'Session running';
  }

  String _formatDuration(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class PotionSessionEffects {
  const PotionSessionEffects({
    this.xpMultiplier = 1.0,
    this.goldMultiplier = 1.0,
    this.rewardBonusMinutes = 0,
    this.breakBonusSeconds = 0,
    this.breaksDisabled = false,
    this.labels = const <String>[],
  });

  final double xpMultiplier;
  final double goldMultiplier;
  final int rewardBonusMinutes;
  final int breakBonusSeconds;
  final bool breaksDisabled;
  final List<String> labels;

  int get breakDurationSeconds => breaksDisabled
      ? 0
      : _FocusSessionPageState._baseBreakDurationSeconds + breakBonusSeconds;

  static PotionSessionEffects fromPotionIds(List<String> potionIds) {
    double xpMultiplier = 1.0;
    double goldMultiplier = 1.0;
    int rewardBonusMinutes = 0;
    int breakBonusSeconds = 0;
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
          break;
        case PotionEffectType.overmind:
          xpMultiplier *= 1.5;
          goldMultiplier *= 1.5;
          breaksDisabled = true;
          break;
        case PotionEffectType.eventPenaltyReduction:
        case PotionEffectType.eventRewardBoost:
        case PotionEffectType.streakProtection:
        case PotionEffectType.failureProtection:
        case PotionEffectType.idlePenaltyReduction:
        case PotionEffectType.dailyFirstSessionBonus:
        case PotionEffectType.shopDiscount:
        case PotionEffectType.rareEventChance:
          break;
      }
    }

    return PotionSessionEffects(
      xpMultiplier: xpMultiplier,
      goldMultiplier: goldMultiplier,
      rewardBonusMinutes: rewardBonusMinutes,
      breakBonusSeconds: breakBonusSeconds,
      breaksDisabled: breaksDisabled,
      labels: List<String>.unmodifiable(labels),
    );
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

    return Material(
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
