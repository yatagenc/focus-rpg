import 'package:flutter/material.dart';

import '../data/cosmetic_catalog.dart';
import '../data/models/equipped_cosmetic.dart';
import '../models/avatar_equipment.dart';

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
      playerClass: playerClass,
      equippedIds: AvatarEquipment.equippedIdByType(equippedCosmetics),
    );
    final String basePath = CosmeticCatalog.iconAvatarPathForClass(playerClass);

    return AvatarLayeredWidget(
      size: size,
      framePath: showFrame ? equipment.frame.assetPath : null,
      baseAvatarPath: basePath,
      torsoPath: equipment.torso.assetPath,
      headPath: equipment.hat.assetPath,
      weaponPath: equipment.weapon.assetPath,
    );
  }
}

class AvatarLayeredWidget extends StatelessWidget {
  const AvatarLayeredWidget({
    super.key,
    this.size = 160,
    this.framePath,
    required this.baseAvatarPath,
    this.torsoPath,
    this.headPath,
    this.weaponPath,
  });

  final double size;
  final String? framePath;
  final String baseAvatarPath;
  final String? torsoPath;
  final String? headPath;
  final String? weaponPath;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: Stack(
                children: [
                  if (weaponPath != null)
                    AvatarLayerImage(assetPath: weaponPath!),
                  AvatarLayerImage(assetPath: baseAvatarPath),
                  if (torsoPath != null)
                    AvatarLayerImage(assetPath: torsoPath!),
                  if (headPath != null) AvatarLayerImage(assetPath: headPath!),
                ],
              ),
            ),
          ),
          if (framePath != null)
            AvatarLayerImage(
              key: const ValueKey<String>('avatarFrameLayer'),
              assetPath: framePath!,
            ),
        ],
      ),
    );
  }
}

class AvatarLayerImage extends StatelessWidget {
  const AvatarLayerImage({super.key, required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }
}
