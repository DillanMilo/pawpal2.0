import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../utils/theme.dart';

class BrandMark extends StatelessWidget {
  final double size;
  final bool withShadow;

  const BrandMark({super.key, this.size = 96, this.withShadow = true});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'PawPal logo',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.24),
          boxShadow: withShadow ? AppTheme.mediumShadow : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: SvgPicture.asset(
          'assets/icons/logo_mark.svg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class BrandTipIcon extends StatelessWidget {
  final String type;
  final double size;

  const BrandTipIcon({super.key, required this.type, this.size = 64});

  IconData get _icon {
    switch (type) {
      case 'hydration':
        return Icons.water_drop_rounded;
      case 'exercise':
        return Icons.directions_run_rounded;
      case 'dental':
        return Icons.health_and_safety_rounded;
      case 'social':
        return Icons.favorite_rounded;
      default:
        return Icons.pets_rounded;
    }
  }

  Color get _accent {
    switch (type) {
      case 'hydration':
        return const Color(0xFF74B9FF);
      case 'exercise':
        return AppTheme.secondaryColor;
      case 'dental':
        return AppTheme.accentColor;
      case 'social':
        return AppTheme.accentRose;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.32),
          width: 1.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: size * 0.12,
            top: size * 0.12,
            child: Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
            ),
          ),
          Icon(_icon, color: Colors.white, size: size * 0.52),
        ],
      ),
    );
  }
}
