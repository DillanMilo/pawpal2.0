import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/pet.dart';
import '../models/pet_progression.dart';
import '../utils/theme.dart';

class PetProgressionAvatar extends StatelessWidget {
  const PetProgressionAvatar({
    super.key,
    required this.pet,
    required this.points,
    required this.size,
    this.heroTag,
    this.fallbackColor,
  });

  final Pet pet;
  final int points;
  final double size;
  final String? heroTag;
  final Color? fallbackColor;

  static List<Color> frameColors(String frameId) => switch (frameId) {
    'meadow' => const [Color(0xFFB9F1D5), Color(0xFF4FAF8D)],
    'sunset' => const [Color(0xFFFFD39E), Color(0xFFE9789A)],
    'starlight' => const [Color(0xFFD5C4FF), Color(0xFF6750C7)],
    _ => const [Colors.white, Color(0xFFE9E4F4)],
  };

  @override
  Widget build(BuildContext context) {
    final progression = PetProgression(points);
    final frameId = progression.selectedFrame(pet.profileFrameId);
    final accessoryId = progression.selectedAccessory(pet.profileAccessoryId);
    final accessory = PetProgression.accessoryById(accessoryId);
    final borderWidth = (size * 0.045).clamp(4.0, 7.0);

    Widget avatar = Semantics(
      label: '${pet.name}, level ${progression.level}, ${progression.title}',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                padding: EdgeInsets.all(borderWidth),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: frameColors(frameId),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: frameColors(frameId).last.withValues(alpha: 0.28),
                      blurRadius: size * 0.16,
                      offset: Offset(0, size * 0.07),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: pet.photoUrl != null && pet.photoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: pet.photoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _PhotoFallback(
                            color:
                                fallbackColor ??
                                AppTheme.primaryColor.withValues(alpha: 0.24),
                            iconSize: size * 0.42,
                          ),
                          errorWidget: (context, url, error) => _PhotoFallback(
                            color:
                                fallbackColor ??
                                AppTheme.primaryColor.withValues(alpha: 0.24),
                            iconSize: size * 0.42,
                          ),
                        )
                      : _PhotoFallback(
                          color:
                              fallbackColor ??
                              AppTheme.primaryColor.withValues(alpha: 0.24),
                          iconSize: size * 0.42,
                        ),
                ),
              ),
            ),
            if (accessory?.emoji != null)
              Positioned(
                right: -size * 0.02,
                top: -size * 0.05,
                child: Container(
                  width: size * 0.34,
                  height: size * 0.34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground(context),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryLight, width: 2),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Text(
                    accessory!.emoji!,
                    style: TextStyle(fontSize: size * 0.18),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (heroTag != null) avatar = Hero(tag: heroTag!, child: avatar);
    return avatar;
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback({required this.color, required this.iconSize});

  final Color color;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Center(
        child: Icon(Icons.pets_rounded, color: Colors.white, size: iconSize),
      ),
    );
  }
}
