import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../data/models/app_settings.dart';
import '../services/settings_service.dart';
import '../widgets/app_safe_layout.dart';
import '../widgets/menu_button.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  static const String _darkBackgroundAsset =
      'assets/images/main_menu_artwork.png';
  static const String _lightBackgroundAsset =
      'assets/images/main_menu_artwork_light.png';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: SettingsService.instance.settingsNotifier,
      builder: (context, settings, _) {
        final String backgroundAsset = settings.darkMode
            ? _darkBackgroundAsset
            : _lightBackgroundAsset;

        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                backgroundAsset,
                key: ValueKey<String>(backgroundAsset),
                fit: BoxFit.cover,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x33000000),
                      Color(0x00000000),
                      Color(0xCC000000),
                    ],
                    stops: [0, 0.5, 1],
                  ),
                ),
              ),
              AppSafeLayout(
                horizontal: 24,
                top: 0,
                bottom: 30,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MenuButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.slots);
                          },
                          text: 'Start',
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.settings);
                            },
                            icon: const Icon(Icons.tune),
                            label: const Text('Settings'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
