import 'package:flutter/foundation.dart';

import '../core/progression.dart';
import '../core/elo.dart';
import '../core/streak.dart';
import '../data/models/game_session.dart';
import '../data/models/equipped_cosmetic.dart';
import '../data/models/owned_cosmetic.dart';
import '../data/repositories/game_repository.dart';
import '../models/player_save.dart';
import 'web_save_storage_stub.dart'
    if (dart.library.html) 'web_save_storage_web.dart';

class SaveService {
  SaveService({GameRepository? repository})
    : _repository = repository ?? GameRepository(),
      _useMemoryStore = repository == null && kIsWeb;

  static const int startingGoldForNewSaves = 1000;

  final GameRepository _repository;
  final bool _useMemoryStore;
  final WebSaveStorage _webStorage = WebSaveStorage();

  static final Map<int, PlayerSave> _webSaves = <int, PlayerSave>{};
  static bool _webSavesLoaded = false;

  Future<List<PlayerSave>> getAllSaves() async {
    if (_useMemoryStore) {
      _loadWebSavesIfNeeded();
      return _webSaves.values.toList()..sort(
        (PlayerSave a, PlayerSave b) => a.profileId.compareTo(b.profileId),
      );
    }

    final profiles = await _repository.getAllProfiles();
    return profiles.map(PlayerSave.fromProfile).toList();
  }

  Future<PlayerSave?> getSaveById(int profileId) async {
    if (_useMemoryStore) {
      _loadWebSavesIfNeeded();
      return _webSaves[profileId];
    }

    final profile = await _repository.getProfileById(profileId);
    if (profile == null) {
      return null;
    }
    return PlayerSave.fromProfile(profile);
  }

  Future<PlayerSave> createSave({
    required int profileId,
    required String playerClass,
  }) async {
    if (_useMemoryStore) {
      _loadWebSavesIfNeeded();
      if (_webSaves.length >= 3 && !_webSaves.containsKey(profileId)) {
        throw StateError('Cannot create more than 3 profiles.');
      }

      final PlayerSave save = PlayerSave(
        profileId: profileId,
        playerClass: playerClass.toLowerCase(),
        level: 1,
        xp: 0,
        gold: startingGoldForNewSaves,
        elo: 0,
        createdAt: DateTime.now().toIso8601String(),
        totalStudyMinutes: 0,
        totalCompletedSessions: 0,
        streakDays: 0,
        lastStreakDate: null,
      );
      _webSaves[profileId] = save;
      _persistWebSaves();
      return save;
    }

    final profile = await _repository.createProfile(
      profileId: profileId,
      profileClass: playerClass,
    );
    return PlayerSave.fromProfile(profile);
  }

  Future<bool> deleteSave(int profileId) {
    if (_useMemoryStore) {
      _loadWebSavesIfNeeded();
      final bool removed = _webSaves.remove(profileId) != null;
      if (removed) {
        _persistWebSaves();
      }
      return Future<bool>.value(removed);
    }

    return _repository.deleteProfile(profileId);
  }

  Future<PlayerSave> completeFocusSession({
    required int profileId,
    required int durationMinutes,
    required String startedAt,
    required String endedAt,
    double xpMultiplier = 1.0,
    double goldMultiplier = 1.0,
    int rewardBonusMinutes = 0,
    int eventBonusXp = 0,
    int eventBonusGold = 0,
    double firstSessionXpBonusMultiplier = 1.0,
    bool allowStreakProgress = true,
  }) async {
    if (_useMemoryStore) {
      _loadWebSavesIfNeeded();
      final PlayerSave? currentSave = _webSaves[profileId];
      if (currentSave == null) {
        throw StateError('Profile does not exist.');
      }

      final bool isFirstSessionToday =
          currentSave.lastStreakDate !=
          _formatDateOnly(DateTime.parse(endedAt));
      final double effectiveXpMultiplier =
          xpMultiplier *
          (isFirstSessionToday ? firstSessionXpBonusMultiplier : 1.0);
      final SessionRewards rewards = progressionSystem.calculateSessionRewards(
        durationMinutes + rewardBonusMinutes,
        xpMultiplier: effectiveXpMultiplier,
        goldMultiplier: goldMultiplier,
      );
      final int earnedXp = rewards.earnedXp + eventBonusXp;
      final int earnedGold = rewards.earnedGold + eventBonusGold;
      final int nextXp = currentSave.xp + earnedXp;
      final int nextLevel = progressionSystem.getLevelFromTotalXp(nextXp).level;
      final StreakState nextStreak = calculateNextStreak(
        currentCount: currentSave.streakDays,
        lastCompletedOn: currentSave.lastStreakDate,
        completedAt: DateTime.parse(endedAt),
        durationMinutes: allowStreakProgress ? durationMinutes : 0,
      );
      final PlayerSave updatedSave = currentSave.copyWith(
        xp: nextXp,
        level: nextLevel,
        gold: currentSave.gold + earnedGold,
        elo:
            currentSave.elo +
            EloSystem.sessionElo(
              durationMinutes: durationMinutes,
              xpEarned: earnedXp,
              goldEarned: earnedGold,
              levelsGained: nextLevel - currentSave.level,
            ),
        lastPlayedAt: endedAt,
        totalStudyMinutes: currentSave.totalStudyMinutes + durationMinutes,
        totalCompletedSessions: currentSave.totalCompletedSessions + 1,
        streakDays: nextStreak.count,
        lastStreakDate: nextStreak.lastCompletedOn,
      );
      _webSaves[profileId] = updatedSave;
      _persistWebSaves();
      return updatedSave;
    }

    final profile = await _repository.completeFocusSession(
      profileId: profileId,
      durationMinutes: durationMinutes,
      startedAt: startedAt,
      endedAt: endedAt,
      xpMultiplier: xpMultiplier,
      goldMultiplier: goldMultiplier,
      rewardBonusMinutes: rewardBonusMinutes,
      eventBonusXp: eventBonusXp,
      eventBonusGold: eventBonusGold,
      firstSessionXpBonusMultiplier: firstSessionXpBonusMultiplier,
      allowStreakProgress: allowStreakProgress,
    );
    return PlayerSave.fromProfile(profile);
  }

  Future<PlayerSave> spendGold({
    required int profileId,
    required int amount,
  }) async {
    if (_useMemoryStore) {
      _loadWebSavesIfNeeded();
      final PlayerSave? currentSave = _webSaves[profileId];
      if (currentSave == null) {
        throw StateError('Profile does not exist.');
      }
      if (currentSave.gold < amount) {
        throw StateError('Not enough gold.');
      }

      final PlayerSave updatedSave = currentSave.copyWith(
        gold: currentSave.gold - amount,
        elo: currentSave.elo + EloSystem.goldSpentElo(amount),
      );
      _webSaves[profileId] = updatedSave;
      _persistWebSaves();
      return updatedSave;
    }

    final profile = await _repository.spendGold(
      profileId: profileId,
      amount: amount,
    );
    return PlayerSave.fromProfile(profile);
  }

  Future<List<GameSession>> getRecentSessionsForProfile({
    required int profileId,
    int limit = 10,
  }) async {
    if (_useMemoryStore) {
      return <GameSession>[];
    }

    return _repository.getRecentSessionsForProfile(
      profileId: profileId,
      limit: limit,
    );
  }

  Future<List<EquippedCosmetic>> getEquippedCosmeticsForProfile({
    required int profileId,
  }) async {
    if (_useMemoryStore) {
      return <EquippedCosmetic>[];
    }

    return _repository.getEquippedCosmeticsForProfile(profileId);
  }

  Future<List<OwnedCosmetic>> getOwnedCosmeticsForProfile({
    required int profileId,
  }) async {
    if (_useMemoryStore) {
      return <OwnedCosmetic>[];
    }

    await _repository.unlockEligibleFrameCosmeticsForProfile(profileId);
    return _repository.getOwnedCosmeticsForProfile(profileId);
  }

  Future<void> equipCosmetic({
    required int profileId,
    required String slotType,
    required int cosmeticId,
  }) async {
    if (_useMemoryStore) {
      return;
    }

    await _repository.equipCosmetic(
      profileId: profileId,
      slotType: slotType,
      cosmeticId: cosmeticId,
    );
  }

  Future<void> unlockCosmeticForProfile({
    required int profileId,
    required int cosmeticId,
  }) async {
    if (_useMemoryStore) {
      return;
    }

    await _repository.unlockCosmeticForProfile(
      profileId: profileId,
      cosmeticId: cosmeticId,
    );
  }

  Future<PlayerSave> purchaseCosmeticForProfile({
    required int profileId,
    required int cosmeticId,
    required int priceGold,
  }) async {
    if (_useMemoryStore) {
      _loadWebSavesIfNeeded();
      final PlayerSave? currentSave = _webSaves[profileId];
      if (currentSave == null) {
        throw StateError('Profile does not exist.');
      }
      if (currentSave.gold < priceGold) {
        throw StateError('Not enough gold.');
      }
      final PlayerSave updatedSave = currentSave.copyWith(
        gold: currentSave.gold - priceGold,
        elo: currentSave.elo + EloSystem.goldSpentElo(priceGold),
      );
      _webSaves[profileId] = updatedSave;
      _persistWebSaves();
      return updatedSave;
    }

    final profile = await _repository.purchaseCosmeticForProfile(
      profileId: profileId,
      cosmeticId: cosmeticId,
      priceGold: priceGold,
    );
    return PlayerSave.fromProfile(profile);
  }

  void _loadWebSavesIfNeeded() {
    if (_webSavesLoaded) {
      return;
    }

    _webSaves
      ..clear()
      ..addEntries(
        _webStorage.load().map(
          (PlayerSave save) => MapEntry<int, PlayerSave>(save.profileId, save),
        ),
      );
    _webSavesLoaded = true;
  }

  void _persistWebSaves() {
    _webStorage.save(_webSaves.values.toList());
  }

  String _formatDateOnly(DateTime value) {
    final String year = value.year.toString().padLeft(4, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
