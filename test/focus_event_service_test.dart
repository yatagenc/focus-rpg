import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_rpg/models/focus_event.dart';
import 'package:focus_rpg/services/focus_event_service.dart';

void main() {
  group('FocusEventService', () {
    test('uses configurable one minute test event interval', () {
      final FocusEventService service = FocusEventService();

      expect(
        service.nextEventDeadlineMilliseconds(baseMilliseconds: 3000),
        63000,
      );
    });

    test('creates valid focus event challenges', () {
      final FocusEventService service = FocusEventService(
        random: math.Random(1),
      );

      final Set<FocusEventType> types = <FocusEventType>{};
      for (int i = 0; i < 20; i++) {
        final FocusEventChallenge challenge = service.createChallenge(
          playerClass: 'Mage',
        );
        types.add(challenge.type);

        expect(challenge.responseSeconds, 12);
        expect(challenge.goldReward, 8);
        expect(challenge.xpReward, 12);
        if (challenge.type == FocusEventType.sequence) {
          expect(challenge.sequence.length, inInclusiveRange(3, 4));
        }
        if (challenge.type == FocusEventType.dodge) {
          expect(challenge.direction, isNotNull);
        }
      }

      expect(types, containsAll(FocusEventType.values));
    });
  });
}
