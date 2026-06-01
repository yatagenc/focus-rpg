import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../models/focus_event.dart';
import 'settings_service.dart';

class FocusEventSoundService {
  FocusEventSoundService._();

  static final FocusEventSoundService instance = FocusEventSoundService._();

  static const String _successAssetPath = 'assets/sounds/success_event.mp3';
  static const String _failureAssetPath = 'assets/sounds/failure_event.mp3';
  static const String _incomingAssetPath = 'assets/sounds/event_occured.mp3';

  final AudioCache _audioCache = AudioCache(prefix: '');
  Future<AudioPool>? _successPoolFuture;
  Future<AudioPool>? _failurePoolFuture;
  Future<AudioPool>? _incomingPoolFuture;

  Future<void> initialize() async {
    try {
      await Future.wait(<Future<AudioPool>>[
        _successPool(),
        _failurePool(),
        _incomingPool(),
      ]);
    } catch (_) {
      _successPoolFuture = null;
      _failurePoolFuture = null;
      _incomingPoolFuture = null;
    }
  }

  Future<void> playIncomingEvent() async {
    await _startPool(_incomingPool(), volumeScale: 0.75);
  }

  Future<void> playForOutcome(FocusEventOutcome outcome) async {
    final bool isSuccess =
        outcome == FocusEventOutcome.success ||
        outcome == FocusEventOutcome.perfect;
    await _startPool(isSuccess ? _successPool() : _failurePool());
  }

  Future<void> _startPool(
    Future<AudioPool> poolFuture, {
    double volumeScale = 1,
  }) async {
    final settings = SettingsService.instance.settingsNotifier.value;
    if (!settings.sfxEnabled || settings.sfxVolume <= 0) {
      return;
    }

    try {
      final AudioPool pool = await poolFuture;
      await pool.start(
        volume: (settings.sfxVolume * volumeScale).clamp(0, 1).toDouble(),
      );
    } catch (_) {
      // Event feedback should never delay or break the event flow.
    }
  }

  Future<AudioPool> _successPool() {
    return _successPoolFuture ??= _createPool(_successAssetPath);
  }

  Future<AudioPool> _failurePool() {
    return _failurePoolFuture ??= _createPool(_failureAssetPath);
  }

  Future<AudioPool> _incomingPool() {
    return _incomingPoolFuture ??= _createPool(_incomingAssetPath);
  }

  Future<AudioPool> _createPool(String assetPath) {
    return AudioPool.createFromAsset(
      path: assetPath,
      minPlayers: 1,
      maxPlayers: 3,
      audioCache: _audioCache,
      playerMode: PlayerMode.mediaPlayer,
    );
  }

  Future<void> dispose() async {
    final AudioPool? successPool = await _successPoolFuture;
    final AudioPool? failurePool = await _failurePoolFuture;
    final AudioPool? incomingPool = await _incomingPoolFuture;
    await Future.wait(<Future<void>>[
      if (successPool != null) successPool.dispose(),
      if (failurePool != null) failurePool.dispose(),
      if (incomingPool != null) incomingPool.dispose(),
    ]);
  }
}
