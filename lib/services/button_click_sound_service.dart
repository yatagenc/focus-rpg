import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'settings_service.dart';

class ButtonClickSoundService {
  ButtonClickSoundService._();

  static final ButtonClickSoundService instance = ButtonClickSoundService._();

  static const String _assetPath = 'assets/sounds/button_click.wav';
  static const Duration effectDuration = Duration(milliseconds: 500);

  final AudioCache _audioCache = AudioCache(prefix: '');
  final AudioPlayer _fallbackPlayer = AudioPlayer()
    ..audioCache = AudioCache(prefix: '');

  Future<AudioPool>? _poolFuture;

  Future<void> initialize() async {
    try {
      _poolFuture ??= _createPool();
      await _poolFuture;
    } catch (_) {
      _poolFuture = null;
    }
  }

  Future<void> play() async {
    final settings = SettingsService.instance.settingsNotifier.value;
    if (!settings.sfxEnabled || settings.sfxVolume <= 0) {
      return;
    }

    try {
      final AudioPool pool = await (_poolFuture ??= _createPool());
      await pool.start(volume: settings.sfxVolume.clamp(0, 1).toDouble());
    } catch (_) {
      _poolFuture = null;
      await _playFallback(settings.sfxVolume.clamp(0, 1).toDouble());
    }
  }

  Future<AudioPool> _createPool() {
    return AudioPool.createFromAsset(
      path: _assetPath,
      minPlayers: 2,
      maxPlayers: 5,
      audioCache: _audioCache,
      playerMode: PlayerMode.mediaPlayer,
    );
  }

  Future<void> _playFallback(double volume) async {
    try {
      await _fallbackPlayer.stop();
      await _fallbackPlayer.play(AssetSource(_assetPath), volume: volume);
    } catch (_) {
      // Button feedback should never interrupt the user's action.
    }
  }

  static VoidCallback? wrap(VoidCallback? callback) {
    if (callback == null) {
      return null;
    }

    return () {
      unawaited(instance.play());
      callback();
    };
  }

  Future<void> dispose() async {
    final AudioPool? pool = await _poolFuture;
    await pool?.dispose();
    await _fallbackPlayer.dispose();
  }
}

class ButtonClickSoundLayer extends StatelessWidget {
  const ButtonClickSoundLayer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (PointerDownEvent event) {
        if (event.buttons == kPrimaryButton &&
            _isLikelyInteractiveHit(event.position, event.viewId)) {
          unawaited(ButtonClickSoundService.instance.play());
        }
      },
      child: child,
    );
  }

  bool _isLikelyInteractiveHit(Offset position, int viewId) {
    final HitTestResult result = HitTestResult();
    GestureBinding.instance.hitTestInView(result, position, viewId);

    for (final HitTestEntry entry in result.path) {
      final HitTestTarget target = entry.target;
      if (target is! RenderObject) {
        continue;
      }

      if (target is RenderSemanticsGestureHandler && target.onTap != null) {
        return true;
      }

      final SemanticsConfiguration config = SemanticsConfiguration();
      // ignore: invalid_use_of_protected_member
      target.describeSemanticsConfiguration(config);
      if (config.onTap != null) {
        return true;
      }
    }

    return result.path.isNotEmpty;
  }
}
