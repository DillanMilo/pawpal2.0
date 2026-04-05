import 'package:flutter/material.dart';
import '../../utils/theme.dart';

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
        gradient: AppTheme.playfulGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.coloredShadow(AppTheme.primaryColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Tip',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  tip['title']!,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  tip['tip']!,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(tip['emoji']!, style: const TextStyle(fontSize: 48)),
        ],
      ),
    );
  }
}
