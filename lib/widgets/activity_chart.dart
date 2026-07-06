import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';

class ActivityChart extends StatelessWidget {
  final Map<String, int> weeklySummary;

  const ActivityChart({super.key, required this.weeklySummary});

  @override
  Widget build(BuildContext context) {
    if (weeklySummary.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.bar_chart,
                size: 48,
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              const Text(
                'No activity data yet',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Start logging activities to see your progress',
                style: TextStyle(color: AppTheme.textLight, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final sortedKeys = weeklySummary.keys.toList()..sort();
    final maxValue = weeklySummary.values.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );

    return Semantics(
      label: 'Weekly activity chart showing ${sortedKeys.length} days of data',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (maxValue == 0 ? 10 : maxValue * 1.2).toDouble(),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toInt()} pts',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= sortedKeys.length) {
                              return const SizedBox();
                            }
                            final dateStr = sortedKeys[value.toInt()];
                            final date = DateTime.parse(dateStr);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('E').format(date),
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: sortedKeys.asMap().entries.map((entry) {
                      final index = entry.key;
                      final dateStr = entry.value;
                      final value = weeklySummary[dateStr] ?? 0;
                      final isToday = _isToday(dateStr);

                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: value.toDouble(),
                            color: isToday
                                ? AppTheme.primaryColor
                                : AppTheme.primaryLight.withValues(alpha: 0.6),
                            width: 24,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendItem(color: AppTheme.primaryColor, label: 'Today'),
                  const SizedBox(width: 24),
                  _LegendItem(
                    color: AppTheme.primaryLight.withValues(alpha: 0.6),
                    label: 'This Week',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
