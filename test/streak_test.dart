import 'package:flutter_test/flutter_test.dart';
import 'package:focus_rpg/core/streak.dart';

void main() {
  group('streak calculation', () {
    test('starts at one after the first valid session', () {
      final StreakState streak = calculateNextStreak(
        currentCount: 0,
        lastCompletedOn: null,
        completedAt: DateTime(2026, 5, 12, 14),
        durationMinutes: 25,
      );

      expect(streak.count, 1);
      expect(streak.lastCompletedOn, '2026-05-12');
    });

    test('does not increment more than once per day', () {
      final StreakState streak = calculateNextStreak(
        currentCount: 4,
        lastCompletedOn: '2026-05-12',
        completedAt: DateTime(2026, 5, 12, 20),
        durationMinutes: 10,
      );

      expect(streak.count, 4);
      expect(streak.lastCompletedOn, '2026-05-12');
    });

    test('increments on the next day', () {
      final StreakState streak = calculateNextStreak(
        currentCount: 4,
        lastCompletedOn: '2026-05-12',
        completedAt: DateTime(2026, 5, 13, 9),
        durationMinutes: 10,
      );

      expect(streak.count, 5);
      expect(streak.lastCompletedOn, '2026-05-13');
    });

    test('resets after a missed day', () {
      final StreakState streak = calculateNextStreak(
        currentCount: 4,
        lastCompletedOn: '2026-05-12',
        completedAt: DateTime(2026, 5, 14, 9),
        durationMinutes: 10,
      );

      expect(streak.count, 1);
      expect(streak.lastCompletedOn, '2026-05-14');
    });

    test('ignores zero minute sessions', () {
      final StreakState streak = calculateNextStreak(
        currentCount: 4,
        lastCompletedOn: '2026-05-12',
        completedAt: DateTime(2026, 5, 13, 9),
        durationMinutes: 0,
      );

      expect(streak.count, 4);
      expect(streak.lastCompletedOn, '2026-05-12');
    });
  });
}
