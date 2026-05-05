import 'package:flutter_test/flutter_test.dart';
import 'package:focus_rpg/core/progression.dart';

void main() {
  group('level thresholds', () {
    test('generate expected fixed early thresholds', () {
      final thresholds = generateLevelThresholds();

      expect(thresholds.length, 99);
      expect(thresholds[1], 100);
      expect(thresholds[2], 150);
      expect(thresholds[3], 250);
      expect(thresholds[4], 400);
    });

    test('thresholds are positive and monotonically increasing', () {
      final thresholds = generateLevelThresholds();

      int previous = 0;
      for (int level = 1; level <= 99; level++) {
        final threshold = thresholds[level]!;
        expect(threshold, greaterThan(0));
        expect(threshold, greaterThanOrEqualTo(previous));
        previous = threshold;
      }
    });

    test('cumulative XP lands in target range', () {
      final totalXp = generateLevelThresholds().values.reduce((a, b) => a + b);

      expect(totalXp, greaterThanOrEqualTo(1400000));
      expect(totalXp, lessThanOrEqualTo(1700000));
    });

    test('level is capped at 100', () {
      final progress = getLevelFromTotalXp(999999999);

      expect(progress.level, 100);
      expect(progress.requiredXpForNextLevel, isNull);
      expect(progress.progressRatio, 1);
    });
  });

  group('session rewards', () {
    test('short sessions below one valid minute do not grant rewards', () {
      final rewards = calculateSessionRewards(0);

      expect(rewards.earnedXp, 0);
      expect(rewards.earnedGold, 0);
    });

    test('calculates XP and gold from valid study minutes', () {
      final threeHourRewards = calculateSessionRewards(180);
      final fourHourRewards = calculateSessionRewards(240);

      expect(threeHourRewards.earnedXp, 1440);
      expect(threeHourRewards.earnedGold, 144);
      expect(fourHourRewards.earnedXp, 1920);
      expect(fourHourRewards.earnedGold, 192);
    });
  });

  group('user application helpers', () {
    test('applies XP and reports level gains', () {
      const user = ProgressionUser(totalXp: 0, level: 1, gold: 0);

      final result = applyXpToUser(user, 250);

      expect(result.user.totalXp, 250);
      expect(result.user.level, 3);
      expect(result.levelsGained, 2);
    });

    test('applies gold to user balance', () {
      const user = ProgressionUser(totalXp: 0, level: 1, gold: 10);

      final updatedUser = applyGoldToUser(user, 144);

      expect(updatedUser.gold, 154);
    });
  });
}
