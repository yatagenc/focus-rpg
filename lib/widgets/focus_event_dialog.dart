import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/focus_event.dart';
import '../services/focus_event_sound_service.dart';
import 'app_safe_layout.dart';

class FocusEventDialog extends StatefulWidget {
  const FocusEventDialog({super.key, required this.challenge});

  final FocusEventChallenge challenge;

  @override
  State<FocusEventDialog> createState() => _FocusEventDialogState();
}

class _FocusEventDialogState extends State<FocusEventDialog> {
  Timer? _timer;
  int _elapsedMilliseconds = 0;
  int _sequenceIndex = 0;
  Offset _dragDelta = Offset.zero;
  bool _isHolding = false;
  bool _hasFinished = false;

  int get _totalMilliseconds => widget.challenge.responseSeconds * 1000;

  double get _timeProgress =>
      (_elapsedMilliseconds / _totalMilliseconds).clamp(0.0, 1.0);

  int get _remainingSeconds {
    return ((_totalMilliseconds - _elapsedMilliseconds) / 1000).ceil().clamp(
      0,
      widget.challenge.responseSeconds,
    );
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) {
        return;
      }

      if (_elapsedMilliseconds >= _totalMilliseconds) {
        _finish(FocusEventOutcome.missed);
        return;
      }

      setState(() {
        _elapsedMilliseconds += 50;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _finish(FocusEventOutcome outcome) {
    if (_hasFinished) {
      return;
    }
    _hasFinished = true;
    _timer?.cancel();
    unawaited(FocusEventSoundService.instance.playForOutcome(outcome));
    Navigator.of(
      context,
    ).pop(FocusEventResult(challenge: widget.challenge, outcome: outcome));
  }

  void _handleSequenceTap(FocusEventToken token) {
    final FocusEventToken expected = widget.challenge.sequence[_sequenceIndex];
    if (token.id != expected.id) {
      _finish(FocusEventOutcome.failed);
      return;
    }

    final int nextIndex = _sequenceIndex + 1;
    if (nextIndex >= widget.challenge.sequence.length) {
      _finish(FocusEventOutcome.success);
      return;
    }

    setState(() {
      _sequenceIndex = nextIndex;
    });
  }

  void _handleHoldRelease() {
    final FocusEventChallenge challenge = widget.challenge;
    final double progress = _timeProgress;
    if (progress >= challenge.perfectStart &&
        progress <= challenge.perfectEnd) {
      _finish(FocusEventOutcome.perfect);
      return;
    }
    if (progress >= challenge.successStart &&
        progress <= challenge.successEnd) {
      _finish(FocusEventOutcome.success);
      return;
    }
    _finish(FocusEventOutcome.failed);
  }

  void _handleSwipeEnd() {
    final FocusEventDirection? expected = widget.challenge.direction;
    if (expected == null || _dragDelta.distance < 32) {
      _finish(FocusEventOutcome.failed);
      return;
    }

    final FocusEventDirection actual;
    if (_dragDelta.dx.abs() > _dragDelta.dy.abs()) {
      actual = _dragDelta.dx > 0
          ? FocusEventDirection.right
          : FocusEventDirection.left;
    } else {
      actual = _dragDelta.dy > 0
          ? FocusEventDirection.down
          : FocusEventDirection.up;
    }

    _finish(
      actual == expected ? FocusEventOutcome.success : FocusEventOutcome.failed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final FocusEventChallenge challenge = widget.challenge;
    final ColorScheme colors = Theme.of(context).colorScheme;
    final double maxDialogHeight = MediaQuery.sizeOf(context).height * 0.72;

    return AlertDialog(
      insetPadding: EdgeInsets.fromLTRB(
        20,
        AppSafeSpacing.top(context, 18),
        20,
        AppSafeSpacing.bottom(context, 18),
      ),
      contentPadding: const EdgeInsets.all(16),
      title: Row(
        children: [
          Icon(_eventTypeIcon(challenge.type), color: colors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(challenge.title)),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 360, maxHeight: maxDialogHeight),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(challenge.description),
              const SizedBox(height: 10),
              _CountdownBar(
                remainingSeconds: _remainingSeconds,
                value: 1 - _timeProgress,
              ),
              const SizedBox(height: 12),
              switch (challenge.type) {
                FocusEventType.sequence => _buildSequence(context),
                FocusEventType.holdRelease => _buildHoldRelease(context),
                FocusEventType.dodge => _buildDodge(context),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSequence(BuildContext context) {
    final List<FocusEventToken> sequence = widget.challenge.sequence;
    final List<FocusEventToken> tokens = _uniqueTokens(sequence);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (int i = 0; i < sequence.length; i++)
              _SequenceStep(
                token: sequence[i],
                active: i == _sequenceIndex,
                completed: i < _sequenceIndex,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final FocusEventToken token in tokens)
              SizedBox(
                width: 144,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => _handleSequenceTap(token),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  icon: Icon(_tokenIcon(token.iconKey), size: 20),
                  label: Text(
                    token.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildHoldRelease(BuildContext context) {
    final FocusEventChallenge challenge = widget.challenge;
    final List<Widget> buttons = List<Widget>.generate(
      challenge.holdButtonCount,
      (int index) => SizedBox(
        width: challenge.holdButtonCount == 1 ? 220 : 148,
        child: GestureDetector(
          onTapDown: (_) {
            setState(() {
              _isHolding = true;
            });
          },
          onTapUp: (_) => _handleHoldRelease(),
          onTapCancel: () => _finish(FocusEventOutcome.failed),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isHolding
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              challenge.holdButtonCount == 1 ? 'Hold' : 'Hold ${index + 1}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _isHolding
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TimingBar(challenge: challenge, progress: _timeProgress),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [for (final Widget button in buttons) button],
        ),
      ],
    );
  }

  Widget _buildDodge(BuildContext context) {
    final FocusEventDirection direction = widget.challenge.direction!;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onPanStart: (_) {
        _dragDelta = Offset.zero;
      },
      onPanUpdate: (DragUpdateDetails details) {
        _dragDelta += details.delta;
      },
      onPanEnd: (_) => _handleSwipeEnd(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: SizedBox(
          height: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_directionIcon(direction), size: 50, color: colors.primary),
              const SizedBox(height: 8),
              Text(
                'Swipe ${direction.name.toUpperCase()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FocusEventToken> _uniqueTokens(List<FocusEventToken> sequence) {
    final Map<String, FocusEventToken> tokens = <String, FocusEventToken>{};
    for (final FocusEventToken token in sequence) {
      tokens[token.id] = token;
    }
    return tokens.values.toList();
  }
}

class _CountdownBar extends StatelessWidget {
  const _CountdownBar({required this.remainingSeconds, required this.value});

  final int remainingSeconds;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(value: value, minHeight: 8),
        ),
        const SizedBox(height: 6),
        Text(
          '${remainingSeconds}s',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _TimingBar extends StatelessWidget {
  const _TimingBar({required this.challenge, required this.progress});

  final FocusEventChallenge challenge;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 34,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: colors.surfaceContainerHighest),
            _TimingBarRange(
              start: challenge.successStart,
              end: challenge.successEnd,
              color: colors.primaryContainer,
            ),
            _TimingBarRange(
              start: challenge.perfectStart,
              end: challenge.perfectEnd,
              color: colors.primary,
            ),
            Align(
              alignment: Alignment((progress.clamp(0.0, 1.0) * 2) - 1, 0),
              child: SizedBox(
                width: 4,
                height: double.infinity,
                child: ColoredBox(color: colors.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimingBarRange extends StatelessWidget {
  const _TimingBarRange({
    required this.start,
    required this.end,
    required this.color,
  });

  final double start;
  final double end;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double widthFactor = math.max(0.01, end - start).clamp(0.0, 1.0);
    final double midpoint = ((start + end) / 2).clamp(0.0, 1.0);

    return Align(
      alignment: Alignment((midpoint * 2) - 1, 0),
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        heightFactor: 1,
        child: ColoredBox(color: color),
      ),
    );
  }
}

class _SequenceStep extends StatelessWidget {
  const _SequenceStep({
    required this.token,
    required this.active,
    required this.completed,
  });

  final FocusEventToken token;
  final bool active;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color background = completed
        ? colors.primary
        : active
        ? colors.primaryContainer
        : colors.surfaceContainerHighest;
    final Color foreground = completed
        ? colors.onPrimary
        : active
        ? colors.onPrimaryContainer
        : colors.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: 70,
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_tokenIcon(token.iconKey), color: foreground, size: 18),
            const SizedBox(height: 2),
            Text(
              token.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _eventTypeIcon(FocusEventType type) {
  return switch (type) {
    FocusEventType.sequence => Icons.schema,
    FocusEventType.holdRelease => Icons.timer,
    FocusEventType.dodge => Icons.swipe,
  };
}

IconData _directionIcon(FocusEventDirection direction) {
  return switch (direction) {
    FocusEventDirection.up => Icons.keyboard_arrow_up,
    FocusEventDirection.right => Icons.keyboard_arrow_right,
    FocusEventDirection.down => Icons.keyboard_arrow_down,
    FocusEventDirection.left => Icons.keyboard_arrow_left,
  };
}

IconData _tokenIcon(String iconKey) {
  return switch (iconKey) {
    'spark' => Icons.auto_awesome,
    'moon' => Icons.dark_mode,
    'sigil' => Icons.blur_circular,
    'star' => Icons.star,
    'shield' => Icons.shield,
    'sword' => Icons.flash_on,
    'anchor' => Icons.anchor,
    'bolt' => Icons.bolt,
    'target' => Icons.my_location,
    'bow' => Icons.architecture,
    'air' => Icons.air,
    'arrow' => Icons.near_me,
    'key' => Icons.key,
    'shadow' => Icons.visibility_off,
    'footstep' => Icons.directions_walk,
    'rotate' => Icons.rotate_right,
    'focus' => Icons.center_focus_strong,
    _ => Icons.circle,
  };
}
