import 'package:flutter/material.dart';

import '../data/models/app_settings.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _update(AppSettings settings) {
    return SettingsService.instance.update(settings);
  }

  @override
  Widget build(BuildContext context) {
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
                      padding: const EdgeInsets.all(16),
                      child: ValueListenableBuilder<AppSettings>(
                        valueListenable:
                            SettingsService.instance.settingsNotifier,
                        builder: (context, settings, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Back',
                                    onPressed: () =>
                                        Navigator.of(context).maybePop(),
                                    icon: const Icon(Icons.arrow_back),
                                  ),
                                  const Expanded(
                                    child: Text(
                                      'Settings',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 48),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _SettingsSwitch(
                                title: 'Dark Mode',
                                icon: Icons.dark_mode,
                                value: settings.darkMode,
                                onChanged: (value) {
                                  _update(settings.copyWith(darkMode: value));
                                },
                              ),
                              const SizedBox(height: 12),
                              _SettingsSwitch(
                                title: 'Music',
                                icon: Icons.music_note,
                                value: settings.musicEnabled,
                                onChanged: (value) {
                                  _update(
                                    settings.copyWith(musicEnabled: value),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _SettingsSwitch(
                                title: 'SFX',
                                icon: Icons.volume_up,
                                value: settings.sfxEnabled,
                                onChanged: (value) {
                                  _update(settings.copyWith(sfxEnabled: value));
                                },
                              ),
                              const SizedBox(height: 24),
                              _VolumeSlider(
                                title: 'Music Volume',
                                value: settings.musicVolume,
                                enabled: settings.musicEnabled,
                                onChanged: (value) {
                                  _update(
                                    settings.copyWith(musicVolume: value),
                                  );
                                },
                              ),
                              const SizedBox(height: 18),
                              _VolumeSlider(
                                title: 'SFX Volume',
                                value: settings.sfxVolume,
                                enabled: settings.sfxEnabled,
                                onChanged: (value) {
                                  _update(settings.copyWith(sfxVolume: value));
                                },
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).maybePop(),
                                  child: const Text('Continue'),
                                ),
                              ),
                            ],
                          );
                        },
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

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: SwitchListTile(
        secondary: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    required this.title,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final int percent = (value * 100).round();
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '%$percent.0',
              style: TextStyle(
                color: enabled ? colors.onSurface : colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(0, 1).toDouble(),
          onChanged: enabled ? onChanged : null,
          divisions: 100,
        ),
      ],
    );
  }
}
