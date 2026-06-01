import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/player_save.dart';
import '../services/save_service.dart';
import '../widgets/app_safe_layout.dart';

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
      videoPath: 'assets/videos/avatars/default_archer_video.mp4',
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
      body: AppSafeLayout(
        maxWidth: 390,
        center: true,
        horizontal: 16,
        top: 4,
        bottom: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose a class',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _ClassCardsLayout(
                profiles: _classes,
                selectedClass: _selectedClass,
                playbackTrigger: _selectionTrigger,
                onSelected: (_ClassProfile profile) {
                  setState(() {
                    _selectedClass = profile.name;
                    _selectionTrigger++;
                  });
                },
              ),
            ),
            const SizedBox(height: 10),
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
    );
  }
}

class _ClassCardsLayout extends StatelessWidget {
  const _ClassCardsLayout({
    required this.profiles,
    required this.selectedClass,
    required this.playbackTrigger,
    required this.onSelected,
  });

  final List<_ClassProfile> profiles;
  final String? selectedClass;
  final int playbackTrigger;
  final ValueChanged<_ClassProfile> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double gap = 10;
        final bool hasSelection = selectedClass != null;
        final double availableHeight = constraints.maxHeight;
        final double cardAreaHeight = availableHeight - gap * 3;
        final double selectedHeight = hasSelection
            ? (cardAreaHeight * 0.34).clamp(206.0, 230.0)
            : cardAreaHeight / 4;
        final double unselectedHeight = hasSelection
            ? (cardAreaHeight - selectedHeight) / 3
            : selectedHeight;

        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            for (int index = 0; index < profiles.length; index++) ...[
              Builder(
                builder: (context) {
                  final _ClassProfile profile = profiles[index];
                  final bool isSelected = selectedClass == profile.name;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelected(profile),
                    child: _ClassCard(
                      profile: profile,
                      isSelected: isSelected,
                      playbackTrigger: playbackTrigger,
                      height: isSelected ? selectedHeight : unselectedHeight,
                    ),
                  );
                },
              ),
              if (index != profiles.length - 1) const SizedBox(height: gap),
            ],
          ],
        );
      },
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
    required this.height,
  });

  final _ClassProfile profile;
  final bool isSelected;
  final int playbackTrigger;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      height: height,
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
            padding: EdgeInsets.fromLTRB(16, 14, isSelected ? 184 : 124, 14),
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
                      ? Expanded(child: _ExpandedClassDetails(profile: profile))
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
  bool _hasFinished = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.assetPath)
      ..setLooping(false)
      ..setVolume(0);
    _controller.addListener(_handlePlayback);
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isReady = true;
        _hasFinished = false;
      });
      _controller.seekTo(Duration.zero);
      _controller.play();
    });
  }

  void _handlePlayback() {
    if (!mounted || !_controller.value.isInitialized || _hasFinished) {
      return;
    }

    final Duration duration = _controller.value.duration;
    final Duration position = _controller.value.position;
    if (duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 80)) {
      setState(() {
        _hasFinished = true;
      });
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handlePlayback)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady || _hasFinished) {
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
    const Color textColor = Color(0xFFF1ECE3);

    return Padding(
      key: ValueKey<String>(profile.name),
      padding: const EdgeInsets.only(top: 10),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 206),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xDD17120D),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: profile.accentColor.withValues(alpha: 0.28),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 11,
                      height: 1.14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: profile.traits
                        .map(
                          (String trait) => DecoratedBox(
                            decoration: BoxDecoration(
                              color: profile.accentColor.withValues(
                                alpha: 0.18,
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: profile.accentColor.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              child: Text(
                                trait,
                                style: const TextStyle(
                                  color: textColor,
                                  fontSize: 9,
                                  height: 1,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
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
