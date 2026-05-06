import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';

class HomeHeader extends StatelessWidget {
  final String greeting;
  final String userName;
  final double scrollOffset;

  const HomeHeader({
    super.key,
    required this.greeting,
    required this.userName,
    this.scrollOffset = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.textPrimary;
    final secondaryText = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: TextStyle(
                    fontSize: 16,
                    color: secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: primaryText,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          _NotificationBadge(),
        ],
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/reminders'),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.inkColor,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: AppTheme.darkDivider) : null,
          boxShadow: isDark
              ? AppTheme.coloredShadow(AppTheme.primaryColor)
              : AppTheme.softShadow,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 27,
            ),
            Positioned(
              top: 13,
              right: 13,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
