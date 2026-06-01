import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_theme.dart';
import 'core/routes.dart';
import 'data/database/app_database.dart';
import 'screens/inventory_screen.dart';
import 'screens/potion_selection_screen.dart';
import 'services/button_click_sound_service.dart';
import 'services/settings_service.dart';
import 'services/shop_sound_service.dart';
import 'views/character_selection_page.dart';
import 'views/focus_session_page.dart';
import 'views/main_hub_page.dart';
import 'views/main_menu_page.dart';
import 'views/potion_shop_page.dart';
import 'views/profile_page.dart';
import 'views/settings_page.dart';
import 'views/slots_page.dart';
import 'views/thread_shop_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  if (!kIsWeb) {
    await AppDatabase.instance.database;
  }
  await SettingsService.instance.load();
  await ButtonClickSoundService.instance.initialize();
  await ShopSoundService.instance.initialize();
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
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) {
            return ButtonClickSoundLayer(
              child: child ?? const SizedBox.shrink(),
            );
          },
          initialRoute: AppRoutes.home,
          routes: {
            AppRoutes.home: (context) => const MainMenuPage(),
            AppRoutes.characterSelection: (context) =>
                const CharacterSelectionPage(),
            AppRoutes.mainHub: (context) => const MainHubPage(),
            AppRoutes.focusSession: (context) => const FocusSessionPage(),
            AppRoutes.inventory: (context) => const InventoryScreen(),
            AppRoutes.potionShop: (context) => const PotionShopPage(),
            AppRoutes.potionSelection: (context) =>
                const PotionSelectionScreen(),
            AppRoutes.profile: (context) => const ProfilePage(),
            AppRoutes.slots: (context) => const SlotsPage(),
            AppRoutes.settings: (context) => const SettingsPage(),
            AppRoutes.threadShop: (context) => const ThreadShopPage(),
          },
        );
      },
    );
  }
}
