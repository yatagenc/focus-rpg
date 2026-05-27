import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/focus_event.dart';

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

    return AlertDialog(
      title: Row(
        children: [
          Icon(_eventTypeIcon(challenge.type), color: colors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(challenge.title)),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(challenge.description),
            const SizedBox(height: 14),
            _CountdownBar(
              remainingSeconds: _remainingSeconds,
              value: 1 - _timeProgress,
            ),
            const SizedBox(height: 18),
            switch (challenge.type) {
              FocusEventType.sequence => _buildSequence(context),
              FocusEventType.holdRelease => _buildHoldRelease(context),
              FocusEventType.dodge => _buildDodge(context),
            },
          ],
        ),
      ),
    );
  }

  Widget _buildSequence(BuildContext context) {
    final List<FocusEventToken> sequence = widget.challenge.sequence;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < sequence.length; i++)
              _SequenceStep(
                token: sequence[i],
                active: i == _sequenceIndex,
                completed: i < _sequenceIndex,
              ),
          ],
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final FocusEventToken token in _uniqueTokens(sequence))
              FilledButton.icon(
                onPressed: () => _handleSequenceTap(token),
                icon: Icon(_tokenIcon(token.iconKey), size: 22),
                label: Text(token.label),
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
      (int index) => Expanded(
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
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isHolding
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              challenge.holdButtonCount == 1 ? 'Hold' : 'Hold ${index + 1}',
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
        const SizedBox(height: 16),
        Row(
          children: [
            for (int i = 0; i < buttons.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              buttons[i],
            ],
          ],
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
          height: 180,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_directionIcon(direction), size: 58, color: colors.primary),
              const SizedBox(height: 12),
              Text(
                'Swipe ${direction.name.toUpperCase()}',
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
        const SizedBox(height: 8),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Positioned(
                left: challenge.successStart * width,
                width: (challenge.successEnd - challenge.successStart) * width,
                top: 0,
                bottom: 0,
                child: ColoredBox(color: colors.primaryContainer),
              ),
              Positioned(
                left: challenge.perfectStart * width,
                width: math.max(
                  4,
                  (challenge.perfectEnd - challenge.perfectStart) * width,
                ),
                top: 0,
                bottom: 0,
                child: ColoredBox(color: colors.primary),
              ),
              Positioned(
                left: (progress * width).clamp(0, width - 4),
                width: 4,
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.onSurface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          );
        },
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
