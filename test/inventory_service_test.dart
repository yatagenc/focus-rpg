import 'package:flutter_test/flutter_test.dart';
import 'package:focus_rpg/services/inventory_service.dart';

void main() {
  group('InventoryService', () {
    test('caps common potions at 3 per type', () {
      final InventoryService service = InventoryService.instance;
      const int profileId = 9001;

      expect(
        service
            .addPotion(
              profileId: profileId,
              potionId: 'bestkeeper_tonic',
              amount: 2,
            )
            .success,
        isTrue,
      );
      expect(
        service
            .canAddPotion(profileId: profileId, potionId: 'bestkeeper_tonic')
            .success,
        isFalse,
      );
    });

    test('allows unlimited epic potion rewards', () {
      final InventoryService service = InventoryService.instance;
      const int profileId = 9002;

      final InventoryMutationResult result = service.addPotion(
        profileId: profileId,
        potionId: 'phoenix_brew',
        amount: 10,
      );

      expect(result.success, isTrue);
    });

    test('rejects invalid common rare session combinations', () {
      final InventoryService service = InventoryService.instance;

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
      final InventoryService service = InventoryService.instance;

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
      final InventoryService service = InventoryService.instance;

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
  });
}
