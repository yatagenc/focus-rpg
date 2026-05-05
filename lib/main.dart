import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/routes.dart';
import 'data/database/app_database.dart';
import 'services/settings_service.dart';
import 'views/character_selection_page.dart';
import 'views/focus_session_page.dart';
import 'views/main_hub_page.dart';
import 'views/main_menu_page.dart';
import 'views/profile_page.dart';
import 'views/settings_page.dart';
import 'views/slots_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  if (!kIsWeb) {
    await AppDatabase.instance.database;
  }
  await SettingsService.instance.load();
  runApp(const FocusRPGApp());
}

class FocusRPGApp extends StatelessWidget {
  const FocusRPGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: SettingsService.instance.settingsNotifier,
      builder: (context, settings, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Focus RPG',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFE3A704),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFE3A704),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: AppRoutes.home,
          routes: {
            AppRoutes.home: (context) => const MainMenuPage(),
            AppRoutes.characterSelection: (context) =>
                const CharacterSelectionPage(),
            AppRoutes.mainHub: (context) => const MainHubPage(),
            AppRoutes.focusSession: (context) => const FocusSessionPage(),
            AppRoutes.profile: (context) => const ProfilePage(),
            AppRoutes.slots: (context) => const SlotsPage(),
            AppRoutes.settings: (context) => const SettingsPage(),
          },
        );
      },
    );
  }
}
