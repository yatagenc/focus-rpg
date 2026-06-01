import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'button_click_sound_service.dart';
import 'settings_service.dart';

class ShopSoundService {
  ShopSoundService._();

  static final ShopSoundService instance = ShopSoundService._();

  static const String _bellAssetPath = 'assets/sounds/shop_bell.wav';
  static const String _doorAssetPath = 'assets/sounds/shop_door_opening.wav';

  final AudioCache _audioCache = AudioCache(prefix: '');

  Future<AudioPool>? _bellPoolFuture;
  Future<AudioPool>? _doorPoolFuture;

  Future<void> initialize() async {
    _bellPoolFuture ??= AudioPool.createFromAsset(
      path: _bellAssetPath,
      minPlayers: 1,
      maxPlayers: 3,
      audioCache: _audioCache,
    );
    _doorPoolFuture ??= AudioPool.createFromAsset(
      path: _doorAssetPath,
      minPlayers: 1,
      maxPlayers: 3,
      audioCache: _audioCache,
    );

    await Future.wait(<Future<AudioPool>>[_bellPoolFuture!, _doorPoolFuture!]);
  }

  void playShopEntryAfterButtonClick() {
    Timer(ButtonClickSoundService.effectDuration, () {
      unawaited(_playShopEntry());
    });
  }

  void playDoorAfterButtonClick() {
    Timer(ButtonClickSoundService.effectDuration, () {
      unawaited(_playDoor());
    });
  }

  Future<void> _playShopEntry() async {
    await Future.wait(<Future<void>>[_playBell(), _playDoor()]);
  }

  Future<void> _playBell() async {
    if (_bellPoolFuture == null) {
      await initialize();
    }
    await _startPool(_bellPoolFuture!);
  }

  Future<void> _playDoor() async {
    if (_doorPoolFuture == null) {
      await initialize();
    }
    await _startPool(_doorPoolFuture!);
  }

  Future<void> _startPool(Future<AudioPool> poolFuture) async {
    final settings = SettingsService.instance.settingsNotifier.value;
    if (!settings.sfxEnabled || settings.sfxVolume <= 0) {
      return;
    }

    try {
      final AudioPool pool = await poolFuture;
      await pool.start(volume: settings.sfxVolume.clamp(0, 1).toDouble());
    } catch (_) {
      // Shop ambience feedback should never block navigation.
    }
  }

  Future<void> dispose() async {
    final AudioPool? bellPool = await _bellPoolFuture;
    final AudioPool? doorPool = await _doorPoolFuture;
    await Future.wait(<Future<void>>[
      if (bellPool != null) bellPool.dispose(),
      if (doorPool != null) doorPool.dispose(),
    ]);
  }
}
