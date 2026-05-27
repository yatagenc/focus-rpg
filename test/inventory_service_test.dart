import 'package:flutter_test/flutter_test.dart';
import 'package:focus_rpg/services/inventory_service.dart';

void main() {
  group('InventoryService', () {
    test('caps common potions at 3 per type', () async {
      final InventoryService service = InventoryService.memory();
      const int profileId = 9001;

      expect(
        (await service.addPotion(
          profileId: profileId,
          potionId: 'bestkeeper_tonic',
          amount: 2,
        )).success,
        isTrue,
      );
      expect(
        (await service.canAddPotion(
          profileId: profileId,
          potionId: 'bestkeeper_tonic',
        )).success,
        isFalse,
      );
    });

    test('allows unlimited epic potion rewards', () async {
      final InventoryService service = InventoryService.memory();
      const int profileId = 9002;

      final InventoryMutationResult result = await service.addPotion(
        profileId: profileId,
        potionId: 'phoenix_brew',
        amount: 10,
      );

      expect(result.success, isTrue);
    });

    test('rejects invalid common rare session combinations', () {
      final InventoryService service = InventoryService.memory();

      expect(
        service.validateSessionPotionLoadout(<String>[
          'bestkeeper_tonic',
          'focus_philter',
          'chronomancers_extract',
          'gamblers_essence',
        ]).isValid,
        isFalse,
      );
      expect(
        service.validateSessionPotionLoadout(<String>[
          'chronomancers_extract',
          'gamblers_essence',
          'bestkeeper_tonic',
        ]).isValid,
        isFalse,
      );
    });

    test('allows up to 3 rare potions without common potions', () {
      final InventoryService service = InventoryService.memory();

      expect(
        service.validateSessionPotionLoadout(<String>[
          'chronomancers_extract',
          'gamblers_essence',
          'streakkeeper_serum',
        ]).isValid,
        isTrue,
      );
    });

    test('allows epic alongside valid common rare loadouts', () {
      final InventoryService service = InventoryService.memory();

      expect(
        service.validateSessionPotionLoadout(<String>[
          'bestkeeper_tonic',
          'focus_philter',
          'chronomancers_extract',
          'phoenix_brew',
        ]).isValid,
        isTrue,
      );
    });

    test('consumes selected potions for a session', () async {
      final InventoryService service = InventoryService.memory();
      const int profileId = 9004;

      final InventoryMutationResult result = await service
          .consumeSelectedPotionsForSession(
            profileId: profileId,
            selectedPotionIds: <String>['focus_philter'],
          );
      final potions = await service.getInventoryPotions(profileId: profileId);
      final int quantity = potions
          .where((potion) => potion.potionId == 'focus_philter')
          .fold<int>(0, (total, potion) => total + potion.quantity);

      expect(result.success, isTrue);
      expect(quantity, 0);
    });
  });
}
