import 'dart:math' as math;

class EloRank {
  const EloRank({
    required this.name,
    required this.minimumElo,
    required this.frameCosmeticId,
  });

  final String name;
  final int minimumElo;
  final int frameCosmeticId;
}

class EloSystem {
  const EloSystem._();

  static const List<EloRank> ranks = <EloRank>[
    EloRank(name: 'Wooden', minimumElo: 0, frameCosmeticId: 3001),
    EloRank(name: 'Bronze', minimumElo: 250, frameCosmeticId: 3002),
    EloRank(name: 'Silver', minimumElo: 750, frameCosmeticId: 3003),
    EloRank(name: 'Gold', minimumElo: 1500, frameCosmeticId: 3004),
    EloRank(name: 'Platinum', minimumElo: 3000, frameCosmeticId: 3005),
    EloRank(name: 'Emerald', minimumElo: 5000, frameCosmeticId: 3006),
    EloRank(name: 'Diamond', minimumElo: 8000, frameCosmeticId: 3007),
  ];

  static EloRank rankForElo(int elo) {
    final int safeElo = math.max(0, elo);
    EloRank current = ranks.first;
    for (final EloRank rank in ranks) {
      if (safeElo < rank.minimumElo) {
        break;
      }
      current = rank;
    }
    return current;
  }

  static EloRank? nextRankForElo(int elo) {
    final int safeElo = math.max(0, elo);
    for (final EloRank rank in ranks) {
      if (rank.minimumElo > safeElo) {
        return rank;
      }
    }
    return null;
  }

  static int sessionElo({
    required int durationMinutes,
    required int xpEarned,
    required int goldEarned,
    required int levelsGained,
  }) {
    final int studyElo = math.max(0, durationMinutes);
    final int xpElo = math.max(0, xpEarned ~/ 10);
    final int goldElo = math.max(0, goldEarned);
    final int levelElo = math.max(0, levelsGained) * 100;
    return studyElo + xpElo + goldElo + levelElo + 25;
  }

  static int goldSpentElo(int amount) {
    return math.max(0, amount ~/ 2);
  }
}
