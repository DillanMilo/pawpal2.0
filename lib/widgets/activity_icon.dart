import 'package:flutter/material.dart';
import '../utils/theme.dart';

class ActivityIcon extends StatelessWidget {
  final String type;
  final double size;
  final Color? color;
  final bool isActive;
  final bool showBorder;

  const ActivityIcon({
    super.key,
    required this.type,
    this.size = 32,
    this.color,
    this.isActive = false,
    this.showBorder = true,
  });

  IconData _getIconData() {
    switch (type.toLowerCase()) {
      case 'walk':
        return Icons.directions_walk_rounded;
      case 'play':
        return Icons.sports_baseball_rounded;
      case 'feed':
        return Icons.restaurant_rounded;
      case 'groom':
      case 'grooming':
        return Icons.content_cut_rounded;
      case 'bath':
        return Icons.bathtub_rounded;
      case 'haircut':
        return Icons.content_cut_rounded;
      case 'nail trim':
        return Icons.auto_fix_normal_rounded;
      case 'ear cleaning':
        return Icons.hearing_rounded;
      case 'teeth brushing':
        return Icons.health_and_safety_rounded;
      case 'deshedding':
        return Icons.brush_rounded;
      case 'flea treatment':
        return Icons.bug_report_rounded;
      case 'full groom':
        return Icons.auto_awesome_rounded;
      case 'vet':
      case 'vet visit':
        return Icons.local_hospital_rounded;
      case 'log':
        return Icons.edit_note_rounded;
      case 'medication':
        return Icons.medication_rounded;
      case 'vaccination':
        return Icons.vaccines_rounded;
      case 'appointment':
        return Icons.calendar_today_rounded;
      case 'social':
        return Icons.groups_rounded;
      case 'rest':
        return Icons.bedtime_rounded;
      case 'train':
        return Icons.school_rounded;
      default:
        return Icons.pets_rounded;
    }
  }

  Color _getIconColor() {
    if (color != null) return color!;

    switch (type.toLowerCase()) {
      case 'walk':
        return AppTheme.secondaryColor; // Teal
      case 'play':
        return AppTheme.accentColor; // Yellow
      case 'feed':
        return AppTheme.accentMint; // Mint green
      case 'groom':
      case 'grooming':
        return AppTheme.accentPeach; // Peach/Orange
      case 'vet':
      case 'vet visit':
        return AppTheme.errorColor; // Red for medical
      case 'medication':
        return AppTheme.accentRose; // Pink
      case 'log':
        return AppTheme.accentLavender; // Lavender
      case 'add':
        return AppTheme.primaryColor; // Purple for add pet
      case 'social':
        return const Color(0xFF74B9FF); // Light blue
      case 'rest':
        return AppTheme.textLight; // Gray
      case 'train':
        return AppTheme.primaryColor; // Purple
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColor();
    final iconData = _getIconData();

    return Semantics(
      label: '$type activity',
      child: Container(
        width: size * 2,
        height: size * 2,
        decoration: BoxDecoration(
          color: isActive ? iconColor : iconColor.withValues(alpha: 0.11),
          shape: BoxShape.circle,
          border: showBorder
              ? Border.all(
                  color: isActive
                      ? iconColor.withValues(alpha: 0.24)
                      : AppTheme.dividerColor,
                  width: 1.5,
                )
              : null,
          boxShadow: isActive ? AppTheme.coloredShadow(iconColor) : null,
        ),
        child: Center(
          child: Icon(
            iconData,
            color: isActive ? Colors.white : iconColor,
            size: size,
          ),
        ),
      ),
    );
  }
}
