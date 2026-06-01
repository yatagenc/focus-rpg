import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_rpg/models/focus_event.dart';
import 'package:focus_rpg/widgets/focus_event_dialog.dart';

void main() {
  testWidgets('renders hold release challenge without layout exceptions', (
    WidgetTester tester,
  ) async {
    const FocusEventChallenge challenge = FocusEventChallenge(
      id: 'test_hold',
      type: FocusEventType.holdRelease,
      title: 'Hold the Rune',
      description: 'Release inside the marked window.',
      responseSeconds: 5,
      goldReward: 1,
      xpReward: 1,
      perfectGoldReward: 2,
      perfectXpReward: 2,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FocusEventDialog(challenge: challenge)),
      ),
    );

    expect(find.text('Hold the Rune'), findsOneWidget);
    expect(find.text('Hold'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders sequence challenge without shrink wrapping viewport', (
    WidgetTester tester,
  ) async {
    const List<FocusEventToken> sequence = <FocusEventToken>[
      FocusEventToken(id: 'spark', label: 'Spark', iconKey: 'spark'),
      FocusEventToken(id: 'moon', label: 'Moon', iconKey: 'moon'),
      FocusEventToken(id: 'shield', label: 'Shield', iconKey: 'shield'),
      FocusEventToken(id: 'bolt', label: 'Bolt', iconKey: 'bolt'),
    ];
    const FocusEventChallenge challenge = FocusEventChallenge(
      id: 'test_sequence',
      type: FocusEventType.sequence,
      title: 'Trace the Sigils',
      description: 'Tap the symbols in order.',
      responseSeconds: 5,
      goldReward: 1,
      xpReward: 1,
      perfectGoldReward: 2,
      perfectXpReward: 2,
      sequence: sequence,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FocusEventDialog(challenge: challenge)),
      ),
    );

    expect(find.text('Trace the Sigils'), findsOneWidget);
    expect(find.text('Spark'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
