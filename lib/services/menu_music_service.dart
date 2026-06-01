import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import '../core/routes.dart';
import '../data/models/app_settings.dart';
import 'settings_service.dart';

class MenuMusicService {
  MenuMusicService._() {
    SettingsService.instance.settingsNotifier.addListener(_syncWithSettings);
  }

  static final MenuMusicService instance = MenuMusicService._();

  static const String _assetPath = 'assets/music/menu_music.mp3';

  final AudioPlayer _player = AudioPlayer()
    ..audioCache = AudioCache(prefix: '');

  bool _isSuppressedForFocusSession = false;
  bool _isPlaying = false;
  bool _isPausedForFocusSession = false;
  Future<void> _lastOperation = Future<void>.value();

  void setRoute(String? routeName) {
    final bool shouldSuppress = routeName == AppRoutes.focusSession;
    _isSuppressedForFocusSession = shouldSuppress;
    _enqueue(_applyDesiredState);
  }

  void startForCurrentRoute() {
    _enqueue(_applyDesiredState);
  }

  Future<void> dispose() async {
    SettingsService.instance.settingsNotifier.removeListener(_syncWithSettings);
    await _player.dispose();
  }

  void _syncWithSettings() {
    _enqueue(_applyDesiredState);
  }

  void _enqueue(Future<void> Function() operation) {
    _lastOperation = _lastOperation.then((_) => operation()).catchError((_) {});
  }

  Future<void> _applyDesiredState() async {
    final AppSettings settings =
        SettingsService.instance.settingsNotifier.value;
    final double volume = settings.musicVolume.clamp(0, 1).toDouble();

    if (!settings.musicEnabled || volume <= 0) {
      if (_isPlaying) {
        await _player.stop();
        _isPlaying = false;
      }
      _isPausedForFocusSession = false;
      return;
    }

    if (_isSuppressedForFocusSession) {
      if (_isPlaying) {
        await _player.pause();
        _isPlaying = false;
        _isPausedForFocusSession = true;
      }
      return;
    }

    await _player.setVolume(volume);
    if (_isPlaying) {
      return;
    }

    if (_isPausedForFocusSession) {
      await _player.resume();
      _isPlaying = true;
      _isPausedForFocusSession = false;
      return;
    }

    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource(_assetPath), volume: volume);
    _isPlaying = true;
  }
}

class MenuMusicRouteObserver extends NavigatorObserver {
  MenuMusicRouteObserver({required this.service});

  final MenuMusicService service;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute<dynamic>) {
      return;
    }
    service.setRoute(route.settings.name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute<dynamic>) {
      return;
    }
    service.setRoute(previousRoute?.settings.name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute is PopupRoute<dynamic>) {
      return;
    }
    service.setRoute(newRoute?.settings.name);
  }
}
