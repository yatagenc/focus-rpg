import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

class AmbientSound {
  const AmbientSound({
    required this.id,
    required this.label,
    required this.assetPath,
  });

  final String id;
  final String label;
  final String assetPath;
}

class AmbientAudioService {
  AmbientAudioService._();

  static final AmbientAudioService instance = AmbientAudioService._();

  static const List<AmbientSound> sounds = <AmbientSound>[
    AmbientSound(
      id: 'city_crowded',
      label: 'City Crowded',
      assetPath: 'ambience_sounds/city_crowded.mp3',
    ),
    AmbientSound(
      id: 'crowded_tavern',
      label: 'Crowded Tavern',
      assetPath: 'ambience_sounds/crowded_tavern.mp3',
    ),
    AmbientSound(
      id: 'harbor',
      label: 'Harbor',
      assetPath: 'ambience_sounds/harbor.mp3',
    ),
    AmbientSound(
      id: 'library_with_rain',
      label: 'Library with Rain',
      assetPath: 'ambience_sounds/library_with_rain.mp3',
    ),
    AmbientSound(
      id: 'urban_campfire',
      label: 'Urban Campfire',
      assetPath: 'ambience_sounds/urban_campfire.mp3',
    ),
  ];

  final AudioPlayer _player = AudioPlayer()
    ..audioCache = AudioCache(prefix: '');
  final Random _random = Random();
  StreamSubscription<void>? _completionSubscription;
  final List<String> _previousSoundIds = <String>[];
  String? _activeSoundId;
  bool _isShuffleEnabled = false;
  bool _isPaused = false;

  String? get activeSoundId => _activeSoundId;
  bool get isShuffleEnabled => _isShuffleEnabled;
  bool get isPaused => _isPaused;
  bool get canPlayPrevious => _previousSoundIds.isNotEmpty;

  Future<void> play(AmbientSound sound) async {
    _isShuffleEnabled = false;
    await _playSound(sound, releaseMode: ReleaseMode.loop, trackHistory: true);
  }

  Future<void> playShuffle() async {
    _isShuffleEnabled = true;
    await _player.setVolume(0.65);
    await _player.setReleaseMode(ReleaseMode.stop);
    await _ensureCompletionListener();
    await _playNextShuffleSound(trackHistory: true);
  }

  Future<void> enableShuffleAfterCurrent() async {
    _isShuffleEnabled = true;
    await _ensureCompletionListener();
    await _player.setReleaseMode(ReleaseMode.stop);
    if (_activeSoundId == null) {
      await _playNextShuffleSound(trackHistory: true);
    }
  }

  Future<void> setShuffleEnabled(bool enabled) async {
    if (enabled) {
      await playShuffle();
      return;
    }

    _isShuffleEnabled = false;
    if (_activeSoundId != null) {
      await _player.setReleaseMode(ReleaseMode.loop);
    }
  }

  Future<void> stop() async {
    _isShuffleEnabled = false;
    await _player.stop();
    _activeSoundId = null;
    _isPaused = false;
  }

  Future<bool> togglePause() async {
    if (_activeSoundId == null) {
      return _isPaused;
    }

    if (_isPaused) {
      await _player.resume();
      _isPaused = false;
    } else {
      await _player.pause();
      _isPaused = true;
    }
    return _isPaused;
  }

  Future<void> skipToNext() async {
    if (_isShuffleEnabled) {
      await _playNextShuffleSound(trackHistory: true);
      return;
    }

    final AmbientSound nextSound = _nextSequentialSound();
    await _playSound(
      nextSound,
      releaseMode: ReleaseMode.loop,
      trackHistory: true,
    );
  }

  Future<void> playPrevious() async {
    final String? previousSoundId = _previousSoundIds.isEmpty
        ? null
        : _previousSoundIds.removeLast();
    if (previousSoundId == null) {
      return;
    }

    final AmbientSound previousSound = sounds.firstWhere(
      (AmbientSound sound) => sound.id == previousSoundId,
      orElse: () => sounds.first,
    );
    await _playSound(
      previousSound,
      releaseMode: _isShuffleEnabled ? ReleaseMode.stop : ReleaseMode.loop,
      trackHistory: false,
    );
  }

  Future<void> dispose() async {
    await _completionSubscription?.cancel();
    _completionSubscription = null;
    await _player.dispose();
    _isShuffleEnabled = false;
    _activeSoundId = null;
    _isPaused = false;
  }

  Future<void> _playNextShuffleSound({required bool trackHistory}) async {
    final AmbientSound nextSound = _randomSoundExcept(_activeSoundId);
    await _playSound(
      nextSound,
      releaseMode: ReleaseMode.stop,
      trackHistory: trackHistory,
    );
  }

  Future<void> _ensureCompletionListener() async {
    _completionSubscription ??= _player.onPlayerComplete.listen((_) {
      if (_isShuffleEnabled) {
        unawaited(_playNextShuffleSound(trackHistory: true));
      }
    });
  }

  Future<void> _playSound(
    AmbientSound sound, {
    required ReleaseMode releaseMode,
    required bool trackHistory,
  }) async {
    final String? previousSoundId = _activeSoundId;
    if (trackHistory &&
        previousSoundId != null &&
        previousSoundId != sound.id) {
      _previousSoundIds.add(previousSoundId);
    }

    await _player.setReleaseMode(releaseMode);
    await _player.setVolume(0.65);
    await _player.stop();
    await _player.play(AssetSource(sound.assetPath));
    _activeSoundId = sound.id;
    _isPaused = false;
  }

  AmbientSound _nextSequentialSound() {
    final String? activeSoundId = _activeSoundId;
    if (activeSoundId == null) {
      return sounds.first;
    }

    final int activeIndex = sounds.indexWhere(
      (AmbientSound sound) => sound.id == activeSoundId,
    );
    if (activeIndex < 0) {
      return sounds.first;
    }
    return sounds[(activeIndex + 1) % sounds.length];
  }

  AmbientSound _randomSoundExcept(String? previousSoundId) {
    final List<AmbientSound> candidates = sounds
        .where((AmbientSound sound) => sound.id != previousSoundId)
        .toList(growable: false);
    final List<AmbientSound> pool = candidates.isEmpty ? sounds : candidates;
    return pool[_random.nextInt(pool.length)];
  }
}
