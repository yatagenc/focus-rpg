import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../widgets/menu_button.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 390),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton.filledTonal(
                              tooltip: 'Settings',
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.settings,
                                );
                              },
                              icon: const Icon(Icons.settings),
                            ),
                          ),
                          const SizedBox(height: 36),
                          Text(
                            'Focus RPG',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.4,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Study. Earn. Progress.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 42),
                          _FocusEmblem(colors: colors),
                          const SizedBox(height: 42),
                          _StatusStrip(colors: colors),
                          SizedBox(
                            height: constraints.maxHeight < 760 ? 28 : 56,
                          ),
                          MenuButton(
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.slots);
                            },
                            text: 'Start',
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.settings,
                                );
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
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FocusEmblem extends StatelessWidget {
  const _FocusEmblem({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.25,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 142,
              height: 142,
              child: CircularProgressIndicator(
                value: 0.72,
                strokeWidth: 10,
                backgroundColor: colors.surface,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colors.outlineVariant),
              ),
              child: const SizedBox(
                width: 106,
                height: 106,
                child: Icon(Icons.auto_awesome, size: 42),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricPill(colors: colors, icon: Icons.timer, label: 'Focus'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricPill(
            colors: colors,
            icon: Icons.shield,
            label: 'Level',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricPill(colors: colors, icon: Icons.paid, label: 'Gold'),
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.colors,
    required this.icon,
    required this.label,
  });

  final ColorScheme colors;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
