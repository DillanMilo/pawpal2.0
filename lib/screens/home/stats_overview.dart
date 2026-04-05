import 'package:flutter/material.dart';
import '../../providers/activity_provider.dart';
import '../../utils/theme.dart';

class StatsOverview extends StatelessWidget {
  final ActivityProvider activityProvider;

  const StatsOverview({
    super.key,
    required this.activityProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            color: AppTheme.accentRose,
            value: '${activityProvider.currentStreak > 0 ? activityProvider.currentStreak : 7}',
            label: 'Day Streak',
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _StatCard(
            icon: Icons.auto_awesome_rounded,
            color: AppTheme.accentColor,
            value: '${activityProvider.totalPoints > 0 ? activityProvider.totalPoints : 2450}',
            label: 'Paw Points',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.softShadow,
        border: AppTheme.thickBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
              letterSpacing: -1,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
