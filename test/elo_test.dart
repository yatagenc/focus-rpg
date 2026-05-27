import 'package:flutter_test/flutter_test.dart';
import 'package:focus_rpg/core/elo.dart';

void main() {
  group('EloSystem', () {
    test('maps Elo to frame ranks', () {
      expect(EloSystem.rankForElo(0).name, 'Wooden');
      expect(EloSystem.rankForElo(250).name, 'Bronze');
      expect(EloSystem.rankForElo(1499).name, 'Silver');
      expect(EloSystem.rankForElo(1500).name, 'Gold');
    });

    test('calculates Elo from session and gold spend activity', () {
      expect(
        EloSystem.sessionElo(
          durationMinutes: 50,
          xpEarned: 400,
          goldEarned: 40,
          levelsGained: 1,
        ),
        255,
      );
      expect(EloSystem.goldSpentElo(101), 50);
    });
  });
}
