import 'package:flutter_test/flutter_test.dart';
import 'package:focus_rpg/data/repositories/game_repository.dart';
import 'package:focus_rpg/services/save_service.dart';

void main() {
  test('uses the temporary 1000 gold starting balance for new saves', () {
    expect(SaveService.startingGoldForNewSaves, 1000);
    expect(GameRepository.startingGoldForNewProfiles, 1000);
  });
}
