import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_rpg/widgets/layered_avatar.dart';

void main() {
  testWidgets('renders a frame overlay layer', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LayeredAvatar(playerClass: 'archer')),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('avatarFrameLayer')),
      findsOneWidget,
    );
  });

  testWidgets('can hide the frame layer', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LayeredAvatar(playerClass: 'archer', showFrame: false),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('avatarFrameLayer')),
      findsNothing,
    );
  });
}
