import 'package:flutter/foundation.dart';

import '../data/models/app_settings.dart';
import '../data/repositories/settings_repository.dart';
import 'web_settings_storage_stub.dart'
    if (dart.library.html) 'web_settings_storage_web.dart';

class SettingsService {
  SettingsService._();

  static final SettingsService instance = SettingsService._();

  final SettingsRepository _repository = SettingsRepository();
  final WebSettingsStorage _webStorage = WebSettingsStorage();
  final ValueNotifier<AppSettings> settingsNotifier =
      ValueNotifier<AppSettings>(AppSettings.defaults());

  Future<void> load() async {
    if (kIsWeb) {
      settingsNotifier.value = _webStorage.load() ?? AppSettings.defaults();
      return;
    }

    settingsNotifier.value = await _repository.getSettings();
  }

  Future<void> update(AppSettings settings) async {
    final AppSettings nextSettings = settings.copyWith(
      musicVolume: settings.musicVolume.clamp(0, 1).toDouble(),
      sfxVolume: settings.sfxVolume.clamp(0, 1).toDouble(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    settingsNotifier.value = nextSettings;

    if (kIsWeb) {
      _webStorage.save(nextSettings);
      return;
    }

    await _repository.saveSettings(nextSettings);
  }
}
