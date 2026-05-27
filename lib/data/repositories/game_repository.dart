import 'package:sqflite/sqflite.dart';

import '../../core/progression.dart';
import '../../core/elo.dart';
import '../../core/streak.dart';
import '../../data/cosmetic_catalog.dart';
import '../../models/cosmetic_definition.dart';
import '../../models/cosmetic_type.dart';
import '../database/app_database.dart';
import '../database/database_schema.dart';
import '../models/equipped_cosmetic.dart';
import '../models/game_session.dart';
import '../models/owned_cosmetic.dart';
import '../models/profile.dart';
import '../models/profile_item.dart';

class GameRepository {
  GameRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<Profile> createProfile({
    required int profileId,
    required String profileClass,
    String? createdAt,
  }) async {
    final Database db = await _database.database;
    final String timestamp = createdAt ?? DateTime.now().toIso8601String();

    return db.transaction<Profile>((Transaction txn) async {
      final int count =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM ${DatabaseSchema.profileTable}',
            ),
          ) ??
          0;

      if (count >= 3) {
        throw const DatabaseValidationException(
          'Cannot create more than 3 profiles.',
        );
      }

      final int insertedRows = await txn.rawInsert(
        '''
        INSERT INTO ${DatabaseSchema.profileTable} (
          profile_id,
          profile_class,
          profile_created_at
        )
        SELECT ?, ?, ?
        WHERE (SELECT COUNT(*) FROM ${DatabaseSchema.profileTable}) < 3
        ''',
        <Object?>[profileId, profileClass.toLowerCase(), timestamp],
      );

      // Critical 3-profile rule is enforced here and at the SQLite trigger level.
      if (insertedRows == 0) {
        throw const DatabaseValidationException(
          'Cannot create more than 3 profiles.',
        );
      }

      await _grantDefaultCosmetics(
        txn: txn,
        profileId: profileId,
        timestamp: timestamp,
      );

      final List<Map<String, Object?>> rows = await txn.query(
        DatabaseSchema.profileTable,
        where: 'profile_id = ?',
        whereArgs: <Object?>[profileId],
        limit: 1,
      );

      if (rows.isEmpty) {
        throw const DatabaseValidationException(
          'Profile creation failed unexpectedly.',
        );
      }

      return Profile.fromMap(rows.first);
    });
  }

  Future<List<Profile>> getAllProfiles() async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseSchema.profileTable,
      orderBy: 'profile_id ASC',
    );

    return rows.map(Profile.fromMap).toList();
  }

  Future<Profile> completeFocusSession({
    required int profileId,
    required int durationMinutes,
    String sessionType = 'focus',
    String? startedAt,
    String? endedAt,
    double xpMultiplier = 1.0,
    double goldMultiplier = 1.0,
    int rewardBonusMinutes = 0,
    int eventBonusXp = 0,
    int eventBonusGold = 0,
    double firstSessionXpBonusMultiplier = 1.0,
    bool allowStreakProgress = true,
  }) async {
    _validateNonNegative(durationMinutes, 'duration_minutes');
    _validateNonNegative(rewardBonusMinutes, 'reward_bonus_minutes');
    _validateNonNegative(eventBonusXp, 'event_bonus_xp');
    _validateNonNegative(eventBonusGold, 'event_bonus_gold');

    final Database db = await _database.database;
    final String endTimestamp = endedAt ?? DateTime.now().toIso8601String();
    final String startTimestamp = startedAt ?? endTimestamp;

    return db.transaction<Profile>((Transaction txn) async {
      final List<Map<String, Object?>> profileRows = await txn.query(
        DatabaseSchema.profileTable,
        where: 'profile_id = ?',
        whereArgs: <Object?>[profileId],
        limit: 1,
      );

      if (profileRows.isEmpty) {
        throw const DatabaseValidationException('Profile does not exist.');
      }

      final Profile currentProfile = Profile.fromMap(profileRows.first);
      final DateTime completedAt = DateTime.parse(endTimestamp);
      final bool isFirstSessionToday =
          currentProfile.profileLastStreakDate != _formatDateOnly(completedAt);
      final double effectiveXpMultiplier =
          xpMultiplier *
          (isFirstSessionToday ? firstSessionXpBonusMultiplier : 1.0);
      final SessionRewards rewards = progressionSystem.calculateSessionRewards(
        durationMinutes + rewardBonusMinutes,
        xpMultiplier: effectiveXpMultiplier,
        goldMultiplier: goldMultiplier,
      );
      final int xpEarned = rewards.earnedXp + eventBonusXp;
      final int goldEarned = rewards.earnedGold + eventBonusGold;
      final int nextXp = currentProfile.profileXp + xpEarned;
      final int nextLevel = progressionSystem.getLevelFromTotalXp(nextXp).level;
      final int nextElo =
          currentProfile.profileElo +
          EloSystem.sessionElo(
            durationMinutes: durationMinutes,
            xpEarned: xpEarned,
            goldEarned: goldEarned,
            levelsGained: nextLevel - currentProfile.profileLevel,
          );
      final StreakState nextStreak = calculateNextStreak(
        currentCount: currentProfile.profileStreakDays,
        lastCompletedOn: currentProfile.profileLastStreakDate,
        completedAt: completedAt,
        durationMinutes: allowStreakProgress ? durationMinutes : 0,
      );

      await txn.insert(
        DatabaseSchema.sessionTable,
        GameSession(
          profileId: profileId,
          sessionType: sessionType,
          startedAt: startTimestamp,
          endedAt: endTimestamp,
          durationMinutes: durationMinutes,
          completed: true,
          xpEarned: xpEarned,
          goldEarned: goldEarned,
        ).toMap()..remove('session_id'),
      );

      await txn.update(
        DatabaseSchema.profileTable,
        <String, Object?>{
          'profile_xp': nextXp,
          'profile_level': nextLevel,
          'profile_gold': currentProfile.profileGold + goldEarned,
          'profile_elo': nextElo,
          'profile_last_played_at': endTimestamp,
          'profile_total_study_minutes':
              currentProfile.profileTotalStudyMinutes + durationMinutes,
          'profile_total_completed_sessions':
              currentProfile.profileTotalCompletedSessions + 1,
          'profile_streak_days': nextStreak.count,
          'profile_last_streak_date': nextStreak.lastCompletedOn,
        },
        where: 'profile_id = ?',
        whereArgs: <Object?>[profileId],
      );

      await _unlockEligibleFrameCosmetics(
        txn: txn,
        profileId: profileId,
        elo: nextElo,
        timestamp: endTimestamp,
      );

      final List<Map<String, Object?>> updatedRows = await txn.query(
        DatabaseSchema.profileTable,
        where: 'profile_id = ?',
        whereArgs: <Object?>[profileId],
        limit: 1,
      );

      return Profile.fromMap(updatedRows.first);
    });
  }

  Future<Profile?> getProfileById(int profileId) async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseSchema.profileTable,
      where: 'profile_id = ?',
      whereArgs: <Object?>[profileId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Profile.fromMap(rows.first);
  }

  Future<Profile> spendGold({
    required int profileId,
    required int amount,
  }) async {
    _validateNonNegative(amount, 'amount');

    final Database db = await _database.database;
    return db.transaction<Profile>((Transaction txn) async {
      final List<Map<String, Object?>> profileRows = await txn.query(
        DatabaseSchema.profileTable,
        where: 'profile_id = ?',
        whereArgs: <Object?>[profileId],
        limit: 1,
      );

      if (profileRows.isEmpty) {
        throw const DatabaseValidationException('Profile does not exist.');
      }

      final Profile currentProfile = Profile.fromMap(profileRows.first);
      if (currentProfile.profileGold < amount) {
        throw const DatabaseValidationException('Not enough gold.');
      }

      final int nextElo =
          currentProfile.profileElo + EloSystem.goldSpentElo(amount);
      await txn.update(
        DatabaseSchema.profileTable,
        <String, Object?>{
          'profile_gold': currentProfile.profileGold - amount,
          'profile_elo': nextElo,
        },
        where: 'profile_id = ?',
        whereArgs: <Object?>[profileId],
      );

      await _unlockEligibleFrameCosmetics(
        txn: txn,
        profileId: profileId,
        elo: nextElo,
        timestamp: DateTime.now().toIso8601String(),
      );

      final List<Map<String, Object?>> updatedRows = await txn.query(
        DatabaseSchema.profileTable,
        where: 'profile_id = ?',
        whereArgs: <Object?>[profileId],
        limit: 1,
      );

      return Profile.fromMap(updatedRows.first);
    });
  }

  Future<bool> deleteProfile(int profileId) async {
    final Database db = await _database.database;
    final int deletedCount = await db.delete(
      DatabaseSchema.profileTable,
      where: 'profile_id = ?',
      whereArgs: <Object?>[profileId],
    );
    return deletedCount > 0;
  }

  Future<int> insertSession(GameSession session) async {
    _validateNonNegative(session.durationMinutes, 'duration_minutes');
    _validateNonNegative(session.xpEarned, 'xp_earned');
    _validateNonNegative(session.goldEarned, 'gold_earned');

    final Database db = await _database.database;
    return db.insert(
      DatabaseSchema.sessionTable,
      session.toMap()..remove('session_id'),
    );
  }

  Future<List<GameSession>> getSessionsForProfile(int profileId) async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseSchema.sessionTable,
      where: 'profile_id = ?',
      whereArgs: <Object?>[profileId],
      orderBy: 'started_at DESC',
    );

    return rows.map(GameSession.fromMap).toList();
  }

  Future<List<GameSession>> getRecentSessionsForProfile({
    required int profileId,
    int limit = 10,
  }) async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseSchema.sessionTable,
      where: 'profile_id = ?',
      whereArgs: <Object?>[profileId],
      orderBy: 'started_at DESC',
      limit: limit,
    );

    return rows.map(GameSession.fromMap).toList();
  }

  Future<void> addItemToProfile({
    required int profileId,
    required int itemId,
    required int quantity,
  }) async {
    _validateNonNegative(quantity, 'quantity');

    final Database db = await _database.database;
    await db.transaction((Transaction txn) async {
      final List<Map<String, Object?>> existingRows = await txn.query(
        DatabaseSchema.profileItemTable,
        where: 'profile_id = ? AND item_id = ?',
        whereArgs: <Object?>[profileId, itemId],
        limit: 1,
      );

      if (existingRows.isEmpty) {
        await txn.insert(
          DatabaseSchema.profileItemTable,
          ProfileItem(
            profileId: profileId,
            itemId: itemId,
            quantity: quantity,
          ).toMap(),
        );
        return;
      }

      final int currentQuantity = existingRows.first['quantity'] as int;
      await txn.update(
        DatabaseSchema.profileItemTable,
        <String, Object?>{'quantity': currentQuantity + quantity},
        where: 'profile_id = ? AND item_id = ?',
        whereArgs: <Object?>[profileId, itemId],
      );
    });
  }

  Future<void> updateProfileItemQuantity({
    required int profileId,
    required int itemId,
    required int quantity,
  }) async {
    _validateNonNegative(quantity, 'quantity');

    final Database db = await _database.database;
    final int updated = await db.update(
      DatabaseSchema.profileItemTable,
      <String, Object?>{'quantity': quantity},
      where: 'profile_id = ? AND item_id = ?',
      whereArgs: <Object?>[profileId, itemId],
    );

    if (updated == 0) {
      throw const DatabaseValidationException(
        'Cannot update quantity for a missing profile item.',
      );
    }
  }

  Future<void> unlockCosmeticForProfile({
    required int profileId,
    required int cosmeticId,
    String? unlockedAt,
  }) async {
    final Database db = await _database.database;
    await db.insert(
      DatabaseSchema.ownedCosmeticsTable,
      OwnedCosmetic(
        profileId: profileId,
        cosmeticId: cosmeticId,
        unlockedAt: unlockedAt ?? DateTime.now().toIso8601String(),
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<Profile> purchaseCosmeticForProfile({
    required int profileId,
    required int cosmeticId,
    required int priceGold,
    String? unlockedAt,
  }) async {
    _validateNonNegative(priceGold, 'price_gold');

    final Database db = await _database.database;
    return db.transaction<Profile>((Transaction txn) async {
      final List<Map<String, Object?>> profileRows = await txn.query(
        DatabaseSchema.profileTable,
        where: 'profile_id = ?',
        whereArgs: <Object?>[profileId],
        limit: 1,
      );
      if (profileRows.isEmpty) {
        throw const DatabaseValidationException('Profile does not exist.');
      }

      final bool cosmeticExists = (await txn.query(
        DatabaseSchema.cosmeticsTable,
        columns: <String>['cosmetic_id'],
        where: 'cosmetic_id = ?',
        whereArgs: <Object?>[cosmeticId],
        limit: 1,
      )).isNotEmpty;
      if (!cosmeticExists) {
        throw const DatabaseValidationException('Cosmetic does not exist.');
      }

      final Profile currentProfile = Profile.fromMap(profileRows.first);
      if (currentProfile.profileGold < priceGold) {
        throw const DatabaseValidationException('Not enough gold.');
      }

      final int nextElo =
          currentProfile.profileElo + EloSystem.goldSpentElo(priceGold);
      await txn.update(
        DatabaseSchema.profileTable,
        <String, Object?>{
          'profile_gold': currentProfile.profileGold - priceGold,
          'profile_elo': nextElo,
        },
        where: 'profile_id = ?',
        whereArgs: <Object?>[profileId],
      );

      await txn.insert(
        DatabaseSchema.ownedCosmeticsTable,
        OwnedCosmetic(
          profileId: profileId,
          cosmeticId: cosmeticId,
          unlockedAt: unlockedAt ?? DateTime.now().toIso8601String(),
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      final List<Map<String, Object?>> updatedRows = await txn.query(
        DatabaseSchema.profileTable,
        where: 'profile_id = ?',
        whereArgs: <Object?>[profileId],
        limit: 1,
      );

      return Profile.fromMap(updatedRows.first);
    });
  }

  Future<List<OwnedCosmetic>> getOwnedCosmeticsForProfile(int profileId) async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseSchema.ownedCosmeticsTable,
      where: 'profile_id = ?',
      whereArgs: <Object?>[profileId],
      orderBy: 'unlocked_at DESC',
    );

    return rows.map(OwnedCosmetic.fromMap).toList();
  }

  Future<void> equipCosmetic({
    required int profileId,
    required String slotType,
    required int cosmeticId,
    String? equippedAt,
  }) async {
    final Database db = await _database.database;

    await db.transaction((Transaction txn) async {
      final bool isOwned = (await txn.query(
        DatabaseSchema.ownedCosmeticsTable,
        columns: <String>['profile_id'],
        where: 'profile_id = ? AND cosmetic_id = ?',
        whereArgs: <Object?>[profileId, cosmeticId],
        limit: 1,
      )).isNotEmpty;

      if (!isOwned) {
        throw const DatabaseValidationException(
          'Cannot equip a cosmetic that is not owned by the profile.',
        );
      }

      await txn.insert(
        DatabaseSchema.equippedCosmeticsTable,
        EquippedCosmetic(
          profileId: profileId,
          slotType: slotType,
          cosmeticId: cosmeticId,
          equippedAt: equippedAt ?? DateTime.now().toIso8601String(),
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<List<EquippedCosmetic>> getEquippedCosmeticsForProfile(
    int profileId,
  ) async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      DatabaseSchema.equippedCosmeticsTable,
      where: 'profile_id = ?',
      whereArgs: <Object?>[profileId],
      orderBy: 'slot_type ASC',
    );

    return rows.map(EquippedCosmetic.fromMap).toList();
  }

  Future<void> unlockEligibleFrameCosmeticsForProfile(int profileId) async {
    final Database db = await _database.database;
    await db.transaction((Transaction txn) async {
      final List<Map<String, Object?>> profileRows = await txn.query(
        DatabaseSchema.profileTable,
        columns: <String>['profile_elo'],
        where: 'profile_id = ?',
        whereArgs: <Object?>[profileId],
        limit: 1,
      );
      if (profileRows.isEmpty) {
        throw const DatabaseValidationException('Profile does not exist.');
      }
      await _unlockEligibleFrameCosmetics(
        txn: txn,
        profileId: profileId,
        elo: profileRows.first['profile_elo'] as int? ?? 0,
        timestamp: DateTime.now().toIso8601String(),
      );
    });
  }

  void _validateNonNegative(int value, String field) {
    if (value < 0) {
      throw DatabaseValidationException('$field cannot be negative.');
    }
  }

  String _formatDateOnly(DateTime value) {
    final String year = value.year.toString().padLeft(4, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _grantDefaultCosmetics({
    required Transaction txn,
    required int profileId,
    required String timestamp,
  }) async {
    for (final int cosmeticId in CosmeticCatalog.defaultCosmeticIds) {
      await txn.insert(
        DatabaseSchema.ownedCosmeticsTable,
        OwnedCosmetic(
          profileId: profileId,
          cosmeticId: cosmeticId,
          unlockedAt: timestamp,
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    final Map<CosmeticType, int> defaultEquipment = <CosmeticType, int>{
      CosmeticType.hat: CosmeticCatalog.defaultHatId,
      CosmeticType.torso: CosmeticCatalog.defaultTorsoId,
      CosmeticType.frame: CosmeticCatalog.defaultWoodFrameId,
    };

    for (final MapEntry<CosmeticType, int> entry in defaultEquipment.entries) {
      await txn.insert(
        DatabaseSchema.equippedCosmeticsTable,
        EquippedCosmetic(
          profileId: profileId,
          slotType: entry.key.storageKey,
          cosmeticId: entry.value,
          equippedAt: timestamp,
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _unlockEligibleFrameCosmetics({
    required Transaction txn,
    required int profileId,
    required int elo,
    required String timestamp,
  }) async {
    for (final CosmeticDefinition frame in CosmeticCatalog.framesUnlockedAtElo(
      elo,
    )) {
      await txn.insert(
        DatabaseSchema.ownedCosmeticsTable,
        OwnedCosmetic(
          profileId: profileId,
          cosmeticId: frame.cosmeticId,
          unlockedAt: timestamp,
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }
}

class DatabaseValidationException implements Exception {
  const DatabaseValidationException(this.message);

  final String message;

  @override
  String toString() => 'DatabaseValidationException: $message';
}
