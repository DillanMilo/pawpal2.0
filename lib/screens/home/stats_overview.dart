import 'package:flutter/material.dart';
import '../../providers/activity_provider.dart';
import '../../utils/activity_scoring.dart';
import '../../utils/theme.dart';

class StatsOverview extends StatelessWidget {
  final ActivityProvider activityProvider;

  const StatsOverview({super.key, required this.activityProvider});

  @override
  Widget build(BuildContext context) {
    final totalPoints = activityProvider.totalPoints;
    final level = ActivityScoring.levelForPoints(totalPoints);
    final rankName = ActivityScoring.rankName(totalPoints);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.local_fire_department_rounded,
              color: AppTheme.accentRose,
              value: '${activityProvider.currentStreak}',
              label: 'Day Streak',
              helper: activityProvider.currentStreak > 0
                  ? 'Keep it going'
                  : 'Log today',
              progress: (activityProvider.currentStreak / 7).clamp(0, 1),
              progressLabel:
                  '${activityProvider.currentStreak.clamp(0, 7)} of 7 day goal',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.auto_awesome_rounded,
              color: AppTheme.accentColor,
              value: '$totalPoints',
              label: 'Paw Points',
              helper: 'Level $level • $rankName',
              progress: ActivityScoring.levelProgress(totalPoints),
              progressLabel: ActivityScoring.levelProgressLabel(totalPoints),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String? helper;
  final double? progress;
  final String? progressLabel;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.helper,
    this.progress,
    this.progressLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.shadowFor(context),
        border: AppTheme.borderFor(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 13),
          Text(
            value,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryText(context),
              letterSpacing: 0,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.secondaryText(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 4),
            Text(
              helper!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress!.clamp(0, 1),
                minHeight: 7,
                backgroundColor: color.withValues(alpha: 0.14),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            if (progressLabel != null) ...[
              const SizedBox(height: 6),
              Text(
                progressLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.mutedText(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
