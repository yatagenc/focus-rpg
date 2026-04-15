import 'package:flutter/material.dart';

import 'core/routes.dart';
import 'data/database/app_database.dart';
import 'views/character_selection_page.dart';
import 'views/main_menu_page.dart';
import 'views/settings_page.dart';
import 'views/slots_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.database;
  runApp(const FocusRPGApp());
}

class FocusRPGApp extends StatelessWidget {
  const FocusRPGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Focus RPG',
      theme: ThemeData.dark(),
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (context) => const MainMenuPage(),
        AppRoutes.characterSelection: (context) =>
            const CharacterSelectionPage(),
        AppRoutes.slots: (context) => const SlotsPage(),
        AppRoutes.settings: (context) => const SettingsPage(),
      },
    );
  }
}
