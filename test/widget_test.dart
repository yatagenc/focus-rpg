import 'package:flutter_test/flutter_test.dart';

import 'package:focus_rpg/main.dart';

void main() {
  testWidgets('shows the Focus RPG main menu', (WidgetTester tester) async {
    await tester.pumpWidget(const FocusRPGApp());

    expect(find.text('Focus RPG'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });
}
