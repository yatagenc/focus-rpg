import 'dart:math' as math;

class ProgressionConfig {
  const ProgressionConfig({
    this.maxLevel = 100,
    this.baseXpPerValidStudyMinute = 8,
    this.defaultXpMultiplier = 1.0,
    this.goldRatio = 0.1,
    this.minimumRewardMinutes = 1,
    this.capXpAtMaxLevel = false,
  });

  final int maxLevel;
  final int baseXpPerValidStudyMinute;
  final double defaultXpMultiplier;
  final double goldRatio;
  final int minimumRewardMinutes;
  final bool capXpAtMaxLevel;
}

class LevelProgress {
  const LevelProgress({
    required this.level,
    required this.currentLevelXp,
    required this.requiredXpForNextLevel,
    required this.progressRatio,
  });

  final int level;
  final int currentLevelXp;
  final int? requiredXpForNextLevel;
  final double progressRatio;
}

class SessionRewards {
  const SessionRewards({required this.earnedXp, required this.earnedGold});

  final int earnedXp;
  final int earnedGold;
}

class ProgressionUser {
  const ProgressionUser({
    required this.totalXp,
    required this.level,
    required this.gold,
  });

  final int totalXp;
  final int level;
  final int gold;

  ProgressionUser copyWith({int? totalXp, int? level, int? gold}) {
    return ProgressionUser(
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      gold: gold ?? this.gold,
    );
  }
}

class XpApplicationResult {
  const XpApplicationResult({required this.user, required this.levelsGained});

  final ProgressionUser user;
  final int levelsGained;
}

class ProgressionSystem {
  ProgressionSystem({this.config = const ProgressionConfig()});

  final ProgressionConfig config;

  late final Map<int, int> _thresholds = generateLevelThresholds(
    maxLevel: config.maxLevel,
  );

  Map<int, int> get thresholds => Map<int, int>.unmodifiable(_thresholds);

  static Map<int, int> generateLevelThresholds({int maxLevel = 100}) {
    if (maxLevel < 5) {
      throw ArgumentError.value(maxLevel, 'maxLevel', 'Must be at least 5.');
    }

    final Map<int, int> thresholds = <int, int>{1: 100, 2: 150, 3: 250, 4: 400};

    final int firstBandRemainingTarget =
        100000 - thresholds.values.reduce((int a, int b) => a + b);

    _addGeneratedBand(
      thresholds: thresholds,
      firstLevel: 5,
      lastLevel: math.min(24, maxLevel - 1),
      targetTotalXp: firstBandRemainingTarget,
      minWeight: 900,
      maxWeight: 8500,
      exponent: 1.35,
    );
    _addGeneratedBand(
      thresholds: thresholds,
      firstLevel: 25,
      lastLevel: math.min(49, maxLevel - 1),
      targetTotalXp: 300000,
      minWeight: 8500,
      maxWeight: 16000,
      exponent: 1.25,
    );
    _addGeneratedBand(
      thresholds: thresholds,
      firstLevel: 50,
      lastLevel: math.min(89, maxLevel - 1),
      targetTotalXp: 650000,
      minWeight: 15000,
      maxWeight: 19000,
      exponent: 1.15,
    );
    _addGeneratedBand(
      thresholds: thresholds,
      firstLevel: 90,
      lastLevel: maxLevel - 1,
      targetTotalXp: 450000,
      minWeight: 30000,
      maxWeight: 60000,
      exponent: 1.2,
    );

    return Map<int, int>.unmodifiable(thresholds);
  }

  int? getRequiredXpForNextLevel(int currentLevel) {
    if (currentLevel >= config.maxLevel) {
      return null;
    }
    return _thresholds[currentLevel];
  }

  LevelProgress getLevelFromTotalXp(int totalXp) {
    final int safeTotalXp = math.max(0, totalXp);
    int remainingXp = safeTotalXp;

    for (int level = 1; level < config.maxLevel; level++) {
      final int requiredXp = _thresholds[level]!;
      if (remainingXp < requiredXp) {
        return LevelProgress(
          level: level,
          currentLevelXp: remainingXp,
          requiredXpForNextLevel: requiredXp,
          progressRatio: requiredXp == 0 ? 0 : remainingXp / requiredXp,
        );
      }

      remainingXp -= requiredXp;
    }

    return LevelProgress(
      level: config.maxLevel,
      currentLevelXp: 0,
      requiredXpForNextLevel: null,
      progressRatio: 1,
    );
  }

  SessionRewards calculateSessionRewards(
    int validStudyMinutes, {
    int? xpPerMinute,
    double? xpMultiplier,
    double? goldRatio,
    int? minimumRewardMinutes,
  }) {
    final int safeMinutes = math.max(0, validStudyMinutes);
    final int minimumMinutes =
        minimumRewardMinutes ?? config.minimumRewardMinutes;
    if (safeMinutes < minimumMinutes) {
      return const SessionRewards(earnedXp: 0, earnedGold: 0);
    }

    final int baseXp =
        safeMinutes * (xpPerMinute ?? config.baseXpPerValidStudyMinute);
    final int earnedXp = (baseXp * (xpMultiplier ?? config.defaultXpMultiplier))
        .round();
    final int earnedGold = (earnedXp * (goldRatio ?? config.goldRatio)).floor();

    return SessionRewards(earnedXp: earnedXp, earnedGold: earnedGold);
  }

  XpApplicationResult applyXpToUser(ProgressionUser user, int earnedXp) {
    final int safeEarnedXp = math.max(0, earnedXp);
    final int nextTotalXp =
        config.capXpAtMaxLevel && user.level >= config.maxLevel
        ? user.totalXp
        : user.totalXp + safeEarnedXp;
    final LevelProgress nextProgress = getLevelFromTotalXp(nextTotalXp);
    final int nextLevel = math.min(nextProgress.level, config.maxLevel);

    return XpApplicationResult(
      user: user.copyWith(totalXp: nextTotalXp, level: nextLevel),
      levelsGained: math.max(0, nextLevel - user.level),
    );
  }

  ProgressionUser applyGoldToUser(ProgressionUser user, int earnedGold) {
    return user.copyWith(gold: user.gold + math.max(0, earnedGold));
  }

  static void _addGeneratedBand({
    required Map<int, int> thresholds,
    required int firstLevel,
    required int lastLevel,
    required int targetTotalXp,
    required double minWeight,
    required double maxWeight,
    required double exponent,
  }) {
    if (firstLevel > lastLevel) {
      return;
    }

    final int count = lastLevel - firstLevel + 1;
    final List<double> weights = List<double>.generate(count, (int index) {
      final double t = count == 1 ? 1 : index / (count - 1);
      return minWeight + ((maxWeight - minWeight) * math.pow(t, exponent));
    });
    final double weightTotal = weights.reduce((double a, double b) => a + b);
    final List<int> values = weights
        .map((double weight) => (weight / weightTotal * targetTotalXp).round())
        .toList();

    int diff = targetTotalXp - values.reduce((int a, int b) => a + b);
    int index = values.length - 1;
    while (diff != 0) {
      values[index] += diff > 0 ? 1 : -1;
      diff += diff > 0 ? -1 : 1;
      index = (index - 1) % values.length;
    }

    for (int i = 0; i < values.length; i++) {
      final int level = firstLevel + i;
      final int previous = thresholds[level - 1] ?? 0;
      thresholds[level] = math.max(values[i], previous + 1);
    }
  }
}

final ProgressionSystem progressionSystem = ProgressionSystem();

Map<int, int> generateLevelThresholds({int maxLevel = 100}) {
  return ProgressionSystem.generateLevelThresholds(maxLevel: maxLevel);
}

int? getRequiredXpForNextLevel(int currentLevel) {
  return progressionSystem.getRequiredXpForNextLevel(currentLevel);
}

LevelProgress getLevelFromTotalXp(int totalXp) {
  return progressionSystem.getLevelFromTotalXp(totalXp);
}

SessionRewards calculateSessionRewards(
  int validStudyMinutes, {
  int? xpPerMinute,
  double? xpMultiplier,
  double? goldRatio,
  int? minimumRewardMinutes,
}) {
  return progressionSystem.calculateSessionRewards(
    validStudyMinutes,
    xpPerMinute: xpPerMinute,
    xpMultiplier: xpMultiplier,
    goldRatio: goldRatio,
    minimumRewardMinutes: minimumRewardMinutes,
  );
}

XpApplicationResult applyXpToUser(ProgressionUser user, int earnedXp) {
  return progressionSystem.applyXpToUser(user, earnedXp);
}

ProgressionUser applyGoldToUser(ProgressionUser user, int earnedGold) {
  return progressionSystem.applyGoldToUser(user, earnedGold);
}
