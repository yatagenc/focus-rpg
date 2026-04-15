import 'package:flutter/material.dart';
import '../core/routes.dart';
import '../widgets/menu_button.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Focus RPG',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),
            MenuButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.slots);
              },
              text: 'Start',
            ),
            const SizedBox(height: 20),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.settings);
              },
              icon: const Icon(Icons.settings),
            ),
          ],
        ),
      ),
    );
  }
}
