import '../data/repositories/game_repository.dart';
import '../models/player_save.dart';

class SaveService {
  SaveService({GameRepository? repository})
    : _repository = repository ?? GameRepository();

  final GameRepository _repository;

  Future<List<PlayerSave>> getAllSaves() async {
    final profiles = await _repository.getAllProfiles();
    return profiles.map(PlayerSave.fromProfile).toList();
  }

  Future<PlayerSave> createSave({
    required int profileId,
    required String playerClass,
  }) async {
    final profile = await _repository.createProfile(
      profileId: profileId,
      profileClass: playerClass,
    );
    return PlayerSave.fromProfile(profile);
  }

  Future<bool> deleteSave(int profileId) {
    return _repository.deleteProfile(profileId);
  }
}
