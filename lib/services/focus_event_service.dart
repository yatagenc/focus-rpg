import 'dart:math' as math;

import '../models/focus_event.dart';

class FocusEventConfig {
  const FocusEventConfig({
    this.eventInterval = const Duration(minutes: 1),
    this.responseSeconds = 12,
    this.baseGoldReward = 8,
    this.baseXpReward = 12,
    this.perfectGoldReward = 12,
    this.perfectXpReward = 18,
  });

  final Duration eventInterval;
  final int responseSeconds;
  final int baseGoldReward;
  final int baseXpReward;
  final int perfectGoldReward;
  final int perfectXpReward;
}

class FocusEventService {
  FocusEventService({
    FocusEventConfig config = const FocusEventConfig(),
    math.Random? random,
  }) : _config = config,
       _random = random ?? math.Random();

  final FocusEventConfig _config;
  final math.Random _random;

  FocusEventConfig get config => _config;

  int nextEventDeadlineMilliseconds({required int baseMilliseconds}) {
    return baseMilliseconds + _config.eventInterval.inMilliseconds;
  }

  FocusEventChallenge createChallenge({required String playerClass}) {
    final FocusEventType type =
        FocusEventType.values[_random.nextInt(FocusEventType.values.length)];

    return switch (type) {
      FocusEventType.sequence => _createSequenceChallenge(playerClass),
      FocusEventType.holdRelease => _createHoldReleaseChallenge(playerClass),
      FocusEventType.dodge => _createDodgeChallenge(),
    };
  }

  FocusEventChallenge _createSequenceChallenge(String playerClass) {
    final _SequenceTheme theme = _sequenceThemeFor(playerClass);
    final int sequenceLength = 3 + _random.nextInt(2);
    final List<FocusEventToken> sequence = List<FocusEventToken>.generate(
      sequenceLength,
      (_) => theme.tokens[_random.nextInt(theme.tokens.length)],
    );

    return FocusEventChallenge(
      id: 'sequence_${DateTime.now().microsecondsSinceEpoch}',
      type: FocusEventType.sequence,
      title: theme.title,
      description: theme.description,
      responseSeconds: _config.responseSeconds,
      goldReward: _config.baseGoldReward,
      xpReward: _config.baseXpReward,
      perfectGoldReward: _config.perfectGoldReward,
      perfectXpReward: _config.perfectXpReward,
      sequence: List<FocusEventToken>.unmodifiable(sequence),
    );
  }

  FocusEventChallenge _createHoldReleaseChallenge(String playerClass) {
    final String normalizedClass = playerClass.toLowerCase();
    final String description = switch (normalizedClass) {
      'mage' => 'Hold the channel, then release as the mana stabilizes.',
      'knight' || 'warrior' => 'Hold your guard, then release at the opening.',
      'archer' || 'ranger' => 'Draw the string, then release on the mark.',
      'thief' || 'rogue' => 'Hold your breath, then move through the gap.',
      _ => 'Hold steady, then release in the marked zone.',
    };

    return FocusEventChallenge(
      id: 'hold_${DateTime.now().microsecondsSinceEpoch}',
      type: FocusEventType.holdRelease,
      title: 'Hold & Release',
      description: description,
      responseSeconds: math.max(6, (_config.responseSeconds * 0.75).round()),
      goldReward: _config.baseGoldReward,
      xpReward: _config.baseXpReward,
      perfectGoldReward: _config.perfectGoldReward,
      perfectXpReward: _config.perfectXpReward,
      holdButtonCount: _random.nextBool() ? 1 : 2,
      successStart: 0.49,
      successEnd: 0.69,
      perfectStart: 0.57,
      perfectEnd: 0.61,
    );
  }

  FocusEventChallenge _createDodgeChallenge() {
    const List<String> descriptions = <String>[
      'A sudden shadow lunges from the trees. Dodge!',
      'Falling debris! Swipe to avoid it.',
      'A cursed spark flies toward you. Move quickly!',
    ];

    return FocusEventChallenge(
      id: 'dodge_${DateTime.now().microsecondsSinceEpoch}',
      type: FocusEventType.dodge,
      title: 'Dodge',
      description: descriptions[_random.nextInt(descriptions.length)],
      responseSeconds: _config.responseSeconds,
      goldReward: _config.baseGoldReward,
      xpReward: _config.baseXpReward,
      perfectGoldReward: _config.perfectGoldReward,
      perfectXpReward: _config.perfectXpReward,
      direction: FocusEventDirection
          .values[_random.nextInt(FocusEventDirection.values.length)],
    );
  }

  _SequenceTheme _sequenceThemeFor(String playerClass) {
    return switch (playerClass.toLowerCase()) {
      'mage' => const _SequenceTheme(
        title: 'Rune Sequence',
        description: 'The spell circle is fading. Repeat the rune sequence.',
        tokens: <FocusEventToken>[
          FocusEventToken(id: 'spark', label: 'Spark', iconKey: 'spark'),
          FocusEventToken(id: 'moon', label: 'Moon', iconKey: 'moon'),
          FocusEventToken(id: 'sigil', label: 'Sigil', iconKey: 'sigil'),
          FocusEventToken(id: 'star', label: 'Star', iconKey: 'star'),
        ],
      ),
      'knight' || 'warrior' => const _SequenceTheme(
        title: 'Stance Sequence',
        description: 'Time your stance before the strike lands.',
        tokens: <FocusEventToken>[
          FocusEventToken(id: 'guard', label: 'Guard', iconKey: 'shield'),
          FocusEventToken(id: 'parry', label: 'Parry', iconKey: 'sword'),
          FocusEventToken(id: 'brace', label: 'Brace', iconKey: 'anchor'),
          FocusEventToken(id: 'riposte', label: 'Riposte', iconKey: 'bolt'),
        ],
      ),
      'archer' || 'ranger' => const _SequenceTheme(
        title: 'Target Sequence',
        description: 'Track the marked targets in order.',
        tokens: <FocusEventToken>[
          FocusEventToken(id: 'mark', label: 'Mark', iconKey: 'target'),
          FocusEventToken(id: 'draw', label: 'Draw', iconKey: 'bow'),
          FocusEventToken(id: 'wind', label: 'Wind', iconKey: 'air'),
          FocusEventToken(id: 'release', label: 'Release', iconKey: 'arrow'),
        ],
      ),
      'thief' || 'rogue' => const _SequenceTheme(
        title: 'Lockpick Sequence',
        description: 'Pick the lock before the guard turns.',
        tokens: <FocusEventToken>[
          FocusEventToken(id: 'pin', label: 'Pin', iconKey: 'key'),
          FocusEventToken(id: 'shadow', label: 'Shadow', iconKey: 'shadow'),
          FocusEventToken(id: 'step', label: 'Step', iconKey: 'footstep'),
          FocusEventToken(id: 'turn', label: 'Turn', iconKey: 'rotate'),
        ],
      ),
      _ => const _SequenceTheme(
        title: 'Focus Sequence',
        description: 'Repeat the marked sequence before it fades.',
        tokens: <FocusEventToken>[
          FocusEventToken(id: 'focus', label: 'Focus', iconKey: 'focus'),
          FocusEventToken(id: 'spark', label: 'Spark', iconKey: 'spark'),
          FocusEventToken(id: 'guard', label: 'Guard', iconKey: 'shield'),
          FocusEventToken(id: 'mark', label: 'Mark', iconKey: 'target'),
        ],
      ),
    };
  }
}

class _SequenceTheme {
  const _SequenceTheme({
    required this.title,
    required this.description,
    required this.tokens,
  });

  final String title;
  final String description;
  final List<FocusEventToken> tokens;
}
