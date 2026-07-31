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
    final isDark = AppTheme.isDark(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: _accent.withValues(alpha: isDark ? 0.5 : 0.34),
          width: 1.75,
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: isDark ? 0.28 : 0.22),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
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
          Icon(_icon, color: _accent, size: size * 0.52),
        ],
      ),
    );
  }
}
