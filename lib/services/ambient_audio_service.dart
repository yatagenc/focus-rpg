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
  String? _activeSoundId;

  String? get activeSoundId => _activeSoundId;

  Future<void> play(AmbientSound sound) async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(0.65);
    await _player.stop();
    await _player.play(AssetSource(sound.assetPath));
    _activeSoundId = sound.id;
  }

  Future<void> stop() async {
    await _player.stop();
    _activeSoundId = null;
  }

  Future<void> dispose() async {
    await _player.dispose();
    _activeSoundId = null;
  }
}
