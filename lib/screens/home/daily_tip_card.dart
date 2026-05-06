import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../widgets/brand_mark.dart';

class DailyTipCard extends StatelessWidget {
  final Map<String, String> tip;

  const DailyTipCard({
    super.key,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppTheme.actionBlueLight],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.actionBlue.withValues(alpha: 0.22)),
        boxShadow: AppTheme.coloredShadow(AppTheme.actionBlue),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Tip',
                  style: TextStyle(
                    color: AppTheme.actionBlueDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tip['title']!,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tip['tip']!,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          BrandTipIcon(type: tip['iconType'] ?? 'default'),
        ],
      ),
    );
  }
}
