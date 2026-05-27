enum FocusEventType { sequence, holdRelease, dodge }

enum FocusEventOutcome { success, failed, missed, perfect }

enum FocusEventDirection { up, right, down, left }

class FocusEventToken {
  const FocusEventToken({
    required this.id,
    required this.label,
    required this.iconKey,
  });

  final String id;
  final String label;
  final String iconKey;
}

class FocusEventChallenge {
  const FocusEventChallenge({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.responseSeconds,
    required this.goldReward,
    required this.xpReward,
    required this.perfectGoldReward,
    required this.perfectXpReward,
    this.sequence = const <FocusEventToken>[],
    this.direction,
    this.holdButtonCount = 1,
    this.successStart = 0.45,
    this.successEnd = 0.72,
    this.perfectStart = 0.55,
    this.perfectEnd = 0.63,
  });

  final String id;
  final FocusEventType type;
  final String title;
  final String description;
  final int responseSeconds;
  final int goldReward;
  final int xpReward;
  final int perfectGoldReward;
  final int perfectXpReward;
  final List<FocusEventToken> sequence;
  final FocusEventDirection? direction;
  final int holdButtonCount;
  final double successStart;
  final double successEnd;
  final double perfectStart;
  final double perfectEnd;
}

class FocusEventResult {
  const FocusEventResult({required this.challenge, required this.outcome});

  final FocusEventChallenge challenge;
  final FocusEventOutcome outcome;

  bool get isSuccess =>
      outcome == FocusEventOutcome.success ||
      outcome == FocusEventOutcome.perfect;

  int get earnedGold {
    return switch (outcome) {
      FocusEventOutcome.perfect => challenge.perfectGoldReward,
      FocusEventOutcome.success => challenge.goldReward,
      FocusEventOutcome.failed || FocusEventOutcome.missed => 0,
    };
  }

  int get earnedXp {
    return switch (outcome) {
      FocusEventOutcome.perfect => challenge.perfectXpReward,
      FocusEventOutcome.success => challenge.xpReward,
      FocusEventOutcome.failed || FocusEventOutcome.missed => 0,
    };
  }

  String get feedback {
    return switch (outcome) {
      FocusEventOutcome.perfect => 'Perfect timing! +$earnedGold Gold',
      FocusEventOutcome.success => 'Success! +$earnedGold Gold',
      FocusEventOutcome.failed ||
      FocusEventOutcome.missed => 'The moment passes...',
    };
  }
}
