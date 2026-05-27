import 'package:flutter/material.dart';

import '../data/cosmetic_catalog.dart';
import '../data/models/equipped_cosmetic.dart';
import '../models/avatar_equipment.dart';
import '../models/cosmetic_definition.dart';

class LayeredAvatar extends StatelessWidget {
  const LayeredAvatar({
    super.key,
    required this.playerClass,
    this.equippedCosmetics = const <EquippedCosmetic>[],
    this.size = 120,
    this.showFrame = true,
  });

  final String playerClass;
  final List<EquippedCosmetic> equippedCosmetics;
  final double size;
  final bool showFrame;

  @override
  Widget build(BuildContext context) {
    final AvatarEquipment equipment = CosmeticCatalog.equipmentFromIds(
      AvatarEquipment.equippedIdByType(equippedCosmetics),
    );
    final String basePath = CosmeticCatalog.iconAvatarPathForClass(playerClass);

    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          _AvatarAssetLayer(
            assetPath: basePath,
            placeholder: _BaseAvatarPlaceholder(playerClass: playerClass),
          ),
          _AvatarAssetLayer(
            assetPath: equipment.torso.assetPath,
            placeholder: const SizedBox.shrink(),
          ),
          _AvatarAssetLayer(
            assetPath: equipment.hat.assetPath,
            placeholder: const SizedBox.shrink(),
          ),
          if (showFrame)
            _AvatarAssetLayer(
              assetPath: equipment.frame.assetPath,
              placeholder: _FramePlaceholder(definition: equipment.frame),
            ),
        ],
      ),
    );
  }
}

class _AvatarAssetLayer extends StatelessWidget {
  const _AvatarAssetLayer({required this.assetPath, required this.placeholder});

  final String assetPath;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}

class _BaseAvatarPlaceholder extends StatelessWidget {
  const _BaseAvatarPlaceholder({required this.playerClass});

  final String playerClass;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String initial = playerClass.isEmpty
        ? '?'
        : playerClass.substring(0, 1).toUpperCase();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _classColor(colors, playerClass).withValues(alpha: 0.22),
          border: Border.all(
            color: _classColor(colors, playerClass).withValues(alpha: 0.7),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            initial,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Color _classColor(ColorScheme colors, String value) {
    return switch (value.toLowerCase()) {
      'mage' => const Color(0xFF7C3AED),
      'knight' || 'warrior' => const Color(0xFFB45309),
      'archer' || 'ranger' => const Color(0xFF15803D),
      'thief' || 'rogue' => const Color(0xFF475569),
      _ => colors.primary,
    };
  }
}

class _FramePlaceholder extends StatelessWidget {
  const _FramePlaceholder({required this.definition});

  final CosmeticDefinition definition;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _tierFillColor(definition.tier),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _tierColor(definition.tier), width: 5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _tierColor(definition.tier).withValues(alpha: 0.24),
            blurRadius: 12,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _innerLineColor(definition.tier).withValues(alpha: 0.84),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Color _tierColor(String tier) {
    return switch (tier) {
      'wood' => const Color(0xFF8B5E34),
      'bronze' => const Color(0xFFB45309),
      'silver' => const Color(0xFF94A3B8),
      'gold' => const Color(0xFFEAB308),
      'platinum' => const Color(0xFF67E8F9),
      'emerald' => const Color(0xFF10B981),
      'diamond' => const Color(0xFF60A5FA),
      _ => const Color(0xFF8B5E34),
    };
  }

  Color _tierFillColor(String tier) {
    return switch (tier) {
      'wood' => const Color(0x332F1D0E),
      'bronze' => const Color(0x33B45309),
      'silver' => const Color(0x3394A3B8),
      'gold' => const Color(0x33EAB308),
      'platinum' => const Color(0x3367E8F9),
      'emerald' => const Color(0x3310B981),
      'diamond' => const Color(0x3360A5FA),
      _ => const Color(0x332F1D0E),
    };
  }

  Color _innerLineColor(String tier) {
    return switch (tier) {
      'wood' => const Color(0xFFE7D0A8),
      'bronze' => const Color(0xFFFFD2A1),
      'silver' => const Color(0xFFE2E8F0),
      'gold' => const Color(0xFFFFF0A6),
      'platinum' => const Color(0xFFE0F7FF),
      'emerald' => const Color(0xFFD1FAE5),
      'diamond' => const Color(0xFFDBEAFE),
      _ => const Color(0xFFE7D0A8),
    };
  }
}
