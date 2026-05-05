import 'dart:async';

import 'package:flutter/material.dart';

import '../services/save_service.dart';

class FocusSessionPage extends StatefulWidget {
  const FocusSessionPage({super.key});

  @override
  State<FocusSessionPage> createState() => _FocusSessionPageState();
}

class _FocusSessionPageState extends State<FocusSessionPage> {
  static const int _breakUnlockSeconds = 60;
  static const int _breakDurationSeconds = 10 * 60;

  final SaveService _saveService = SaveService();

  Timer? _timer;
  DateTime? _startedAt;
  DateTime? _focusResumedAt;
  DateTime? _breakStartedAt;
  int _focusAccumulatedMilliseconds = 0;
  int _elapsedMilliseconds = 0;
  int _totalSessionMilliseconds = 0;
  int _breakRemainingSeconds = _breakDurationSeconds;
  bool _hasUsedBreak = false;
  bool _isSaving = false;

  bool get _isRunning => _startedAt != null;
  bool get _isBreakActive => _breakStartedAt != null;
  bool get _canSetBreak =>
      _isRunning &&
      !_isBreakActive &&
      !_hasUsedBreak &&
      _elapsedMilliseconds >= _breakUnlockSeconds * 1000;

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

    _start();
  }

  void _start() {
    setState(() {
      _startedAt = DateTime.now();
      _focusResumedAt = _startedAt;
      _focusAccumulatedMilliseconds = 0;
      _elapsedMilliseconds = 0;
      _totalSessionMilliseconds = 0;
      _breakStartedAt = null;
      _breakRemainingSeconds = _breakDurationSeconds;
      _hasUsedBreak = false;
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
          _breakRemainingSeconds = (_breakDurationSeconds - breakElapsed)
              .clamp(0, _breakDurationSeconds)
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
      _breakRemainingSeconds = _breakDurationSeconds;
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
    final int? profileId = ModalRoute.of(context)?.settings.arguments as int?;
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
          onPressed: _isSaving ? null : _cancelSession,
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
                      onPressed: _isRunning && !_isSaving
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
                      onPressed: _isRunning && !_isSaving && !_isBreakActive
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
                      onPressed: _isSaving ? null : _cancelSession,
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
        onPressed: _confirmStart,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start'),
      );
    }

    return _BreakProgressButton(
      progress: breakProgress,
      enabled: _canSetBreak,
      label: _hasUsedBreak ? 'Break Used' : 'Set a Break',
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
