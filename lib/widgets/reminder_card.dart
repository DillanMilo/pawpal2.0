import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../utils/theme.dart';
import 'activity_icon.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback? onComplete;
  final VoidCallback? onTap;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onComplete,
    this.onTap,
  });

  Color get _color {
    if (reminder.isDue) return AppTheme.errorColor;
    if (reminder.isDueToday) return AppTheme.warningColor;
    return AppTheme.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${reminder.title} reminder, ${_formatDueDate(reminder.dueDate)}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                ActivityIcon(type: reminder.type, size: 24, color: _color),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppTheme.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDueDate(reminder.dueDate),
                            style: TextStyle(
                              color: _color,
                              fontSize: 13,
                              fontWeight: reminder.isDue
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      if (reminder.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          reminder.description!,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Complete button
                if (onComplete != null && !reminder.isCompleted)
                  IconButton(
                    onPressed: onComplete,
                    tooltip: 'Mark as complete',
                    icon: Icon(
                      Icons.check_circle_outline,
                      color: AppTheme.successColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = DateTime(date.year, date.month, date.day);

    if (dueDay.isBefore(today)) {
      final days = today.difference(dueDay).inDays;
      return 'Overdue by $days ${days == 1 ? 'day' : 'days'}';
    } else if (dueDay == today) {
      return 'Today at ${DateFormat('h:mm a').format(date)}';
    } else if (dueDay == tomorrow) {
      return 'Tomorrow at ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }
}
