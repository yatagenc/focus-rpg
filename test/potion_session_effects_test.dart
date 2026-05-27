import 'package:flutter_test/flutter_test.dart';
import 'package:focus_rpg/views/focus_session_page.dart';

void main() {
  group('PotionSessionEffects', () {
    test('applies reward, break, and duration modifiers', () {
      final PotionSessionEffects effects =
          PotionSessionEffects.fromPotionIds(<String>[
            'focus_philter',
            'coinkeeper_flask',
            'bestkeeper_tonic',
            'chronomancers_extract',
          ]);

      expect(effects.xpMultiplier, 1.10);
      expect(effects.goldMultiplier, 1.15);
      expect(effects.breakBonusSeconds, 180);
      expect(effects.rewardBonusMinutes, 10);
    });

    test('applies focus event modifiers and protections', () {
      final PotionSessionEffects effects =
          PotionSessionEffects.fromPotionIds(<String>[
            'steadfast_brew',
            'scholars_fortune',
            'lucid_draught',
            'streakkeeper_serum',
            'phoenix_brew',
            'destiny_draught',
          ]);

      expect(effects.eventPenaltyMultiplier, 0.5);
      expect(effects.eventRewardMultiplier, 1.5);
      expect(effects.idlePenaltyMultiplier, 0.5);
      expect(effects.streakProtectionCharges, 1);
      expect(effects.failureProtectionCharges, 1);
      expect(effects.rareEventChanceBonus, 0.35);
    });

    test('applies risk, overmind, first session, and merchant modifiers', () {
      final PotionSessionEffects effects = PotionSessionEffects.fromPotionIds(
        <String>[
          'gamblers_essence',
          'overmind_elixir',
          'quickstart_elixir',
          'merchants_tonic',
        ],
      );

      expect(effects.xpMultiplier, 3.0);
      expect(effects.goldMultiplier, 3.2);
      expect(effects.failurePenaltyMultiplier, 2.0);
      expect(effects.firstSessionXpBonusMultiplier, 1.25);
      expect(effects.breaksDisabled, isTrue);
    });
  });
}
