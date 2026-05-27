import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/player_save.dart';
import '../services/save_service.dart';

class CharacterSelectionPage extends StatefulWidget {
  const CharacterSelectionPage({super.key});

  @override
  State<CharacterSelectionPage> createState() => _CharacterSelectionPageState();
}

class _CharacterSelectionPageState extends State<CharacterSelectionPage> {
  static const List<_ClassProfile> _classes = <_ClassProfile>[
    _ClassProfile(
      name: 'Mage',
      subtitle: 'Arcane focus',
      summary: 'Builds momentum through long, uninterrupted focus sessions.',
      assetPath: 'assets/images/avatars/base/default_mage_full.png',
      videoPath: 'assets/videos/avatars/default_mage_video.mp4',
      color: Color(0xFF4169A9),
      accentColor: Color(0xFF7C6CE0),
      traits: <String>['Deep work', 'Mana burst', 'Planning'],
    ),
    _ClassProfile(
      name: 'Knight',
      subtitle: 'Steady defender',
      summary: 'Rewards consistent sessions and protects your daily streak.',
      assetPath: 'assets/images/avatars/base/default_knight_full.png',
      videoPath: 'assets/videos/avatars/default_knight_video.mp4',
      color: Color(0xFF5F6670),
      accentColor: Color(0xFFE3A704),
      traits: <String>['Consistency', 'Streak guard', 'Discipline'],
    ),
    _ClassProfile(
      name: 'Archer',
      subtitle: 'Precise striker',
      summary: 'Excels at short, accurate goals and fast task completion.',
      assetPath: 'assets/images/avatars/base/default_archer_full.png',
      color: Color(0xFF2F6B3A),
      accentColor: Color(0xFF8FB34B),
      traits: <String>['Precision', 'Short sprints', 'Targeting'],
    ),
    _ClassProfile(
      name: 'Thief',
      subtitle: 'Swift opportunist',
      summary: 'Turns spare moments into progress with flexible focus bursts.',
      assetPath: 'assets/images/avatars/base/default_thief_full.png',
      videoPath: 'assets/videos/avatars/default_thief_video.mp4',
      color: Color(0xFFC95F21),
      accentColor: Color(0xFFF19A3E),
      traits: <String>['Agility', 'Bonus loot', 'Flexibility'],
    ),
  ];
  final SaveService _saveService = SaveService();

  String? _selectedClass;
  int _selectionTrigger = 0;
  bool _isSaving = false;

  Future<void> _createProfile() async {
    final String? selectedClass = _selectedClass;
    if (selectedClass == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final List<PlayerSave> saves = await _saveService.getAllSaves();
      final Set<int> usedIds = saves
          .map((PlayerSave save) => save.profileId)
          .toSet();

      int? nextId;
      for (int candidate = 1; candidate <= 3; candidate++) {
        if (!usedIds.contains(candidate)) {
          nextId = candidate;
          break;
        }
      }

      if (nextId == null) {
        throw StateError('All profile slots are already occupied.');
      }

      await _saveService.createSave(
        profileId: nextId,
        playerClass: selectedClass,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Choose a class',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap a class to inspect its role and starting profile.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _classes.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final _ClassProfile profile = _classes[index];
                        final bool isSelected = _selectedClass == profile.name;

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _selectedClass = profile.name;
                              _selectionTrigger++;
                            });
                          },
                          child: _ClassCard(
                            profile: profile,
                            isSelected: isSelected,
                            playbackTrigger: _selectionTrigger,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            child: const Text('Back'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _selectedClass == null || _isSaving
                                ? null
                                : _createProfile,
                            child: Text(_isSaving ? 'Saving...' : 'Continue'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassProfile {
  const _ClassProfile({
    required this.name,
    required this.subtitle,
    required this.summary,
    required this.assetPath,
    this.videoPath,
    required this.color,
    required this.accentColor,
    required this.traits,
  });

  final String name;
  final String subtitle;
  final String summary;
  final String assetPath;
  final String? videoPath;
  final Color color;
  final Color accentColor;
  final List<String> traits;
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.profile,
    required this.isSelected,
    required this.playbackTrigger,
  });

  final _ClassProfile profile;
  final bool isSelected;
  final int playbackTrigger;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      height: isSelected ? 232 : 118,
      decoration: BoxDecoration(
        color: Color.lerp(
          colors.surfaceContainerHighest,
          profile.color,
          isSelected ? 0.16 : 0.06,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? profile.accentColor
              : colors.outlineVariant.withValues(alpha: 0.8),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: <BoxShadow>[
          if (isSelected)
            BoxShadow(
              color: profile.color.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: <Color>[
                    profile.color.withValues(alpha: isSelected ? 0.24 : 0.12),
                    colors.surface.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: isSelected ? -4 : 0,
            bottom: 0,
            top: 0,
            width: isSelected ? 176 : 122,
            child: _ClassPortrait(
              assetPath: profile.assetPath,
              videoPath: profile.videoPath,
              isSelected: isSelected,
              playbackTrigger: playbackTrigger,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 124, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      width: isSelected ? 30 : 24,
                      height: isSelected ? 30 : 24,
                      decoration: BoxDecoration(
                        color: profile.accentColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: profile.accentColor.withValues(alpha: 0.8),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          profile.name.substring(0, 1),
                          style: TextStyle(
                            color: isSelected
                                ? profile.accentColor
                                : colors.onSurfaceVariant,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 20,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? profile.accentColor
                                  : colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            profile.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: isSelected
                      ? _ExpandedClassDetails(profile: profile)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassPortrait extends StatelessWidget {
  const _ClassPortrait({
    required this.assetPath,
    required this.videoPath,
    required this.isSelected,
    required this.playbackTrigger,
  });

  final String assetPath;
  final String? videoPath;
  final bool isSelected;
  final int playbackTrigger;

  @override
  Widget build(BuildContext context) {
    final String? selectedVideoPath = isSelected ? videoPath : null;

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minWidth: 0,
        maxWidth: double.infinity,
        minHeight: 0,
        maxHeight: double.infinity,
        child: SizedBox(
          width: isSelected ? 206 : 146,
          height: isSelected ? 360 : 240,
          child: selectedVideoPath == null
              ? Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                )
              : _OneShotClassVideo(
                  key: ValueKey<String>('$selectedVideoPath-$playbackTrigger'),
                  assetPath: selectedVideoPath,
                  fallbackAssetPath: assetPath,
                ),
        ),
      ),
    );
  }
}

class _OneShotClassVideo extends StatefulWidget {
  const _OneShotClassVideo({
    super.key,
    required this.assetPath,
    required this.fallbackAssetPath,
  });

  final String assetPath;
  final String fallbackAssetPath;

  @override
  State<_OneShotClassVideo> createState() => _OneShotClassVideoState();
}

class _OneShotClassVideoState extends State<_OneShotClassVideo> {
  late final VideoPlayerController _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.assetPath)
      ..setLooping(false)
      ..setVolume(0)
      ..initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isReady = true;
        });
        _controller.seekTo(Duration.zero);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Image.asset(
        widget.fallbackAssetPath,
        fit: BoxFit.contain,
        alignment: Alignment.topCenter,
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }
}

class _ExpandedClassDetails extends StatelessWidget {
  const _ExpandedClassDetails({required this.profile});

  final _ClassProfile profile;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      key: ValueKey<String>(profile.name),
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.summary,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: profile.traits
                .map(
                  (String trait) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: profile.accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: profile.accentColor.withValues(alpha: 0.36),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      child: Text(
                        trait,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 11,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
