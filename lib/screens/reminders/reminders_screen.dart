import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/reminder.dart';
import '../../models/subscription_feature.dart';
import '../../providers/subscription_provider.dart';
import '../../services/reminder_service.dart';
import '../../services/notification_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/premium_feature_gate.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final ReminderService _reminderService = ReminderService();
  List<Reminder> _reminders = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, today, upcoming, overdue

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    try {
      _reminders = await _reminderService.getActiveReminders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading reminders: $e')));
      }
    }
    setState(() => _isLoading = false);
  }

  List<Reminder> get _filteredReminders {
    switch (_filter) {
      case 'today':
        return _reminders.where((r) => r.isDueToday).toList();
      case 'upcoming':
        return _reminders.where((r) => r.isUpcoming).toList();
      case 'overdue':
        return _reminders.where((r) => r.isDue).toList();
      default:
        return _reminders;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add reminder',
            onPressed: _showAddReminderDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Today',
                  isSelected: _filter == 'today',
                  onTap: () => setState(() => _filter = 'today'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Upcoming',
                  isSelected: _filter == 'upcoming',
                  onTap: () => setState(() => _filter = 'upcoming'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Overdue',
                  isSelected: _filter == 'overdue',
                  color: AppTheme.errorColor,
                  onTap: () => setState(() => _filter = 'overdue'),
                ),
              ],
            ),
          ),
          // Reminders list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredReminders.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadReminders,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredReminders.length,
                      itemBuilder: (context, index) {
                        final reminder = _filteredReminders[index];
                        return _ReminderCard(
                          reminder: reminder,
                          onComplete: () => _completeReminder(reminder),
                          onDelete: () => _deleteReminder(reminder),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderDialog,
        tooltip: 'Add reminder',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    switch (_filter) {
      case 'today':
        message = 'No reminders for today';
        break;
      case 'upcoming':
        message = 'No upcoming reminders';
        break;
      case 'overdue':
        message = 'No overdue reminders';
        break;
      default:
        message = 'No reminders yet';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add a reminder',
              style: TextStyle(color: AppTheme.secondaryText(context)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddReminderDialog() async {
    if (!context.read<SubscriptionProvider>().canAddReminder(
      _reminders.length,
    )) {
      final viewPlans = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Keep every reminder with Plus'),
          content: Text(
            'PawPal Base includes up to 5 active reminders. Complete or delete one to add another, or upgrade for unlimited reminders.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Not now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('View plans'),
            ),
          ],
        ),
      );
      if (viewPlans == true && mounted) context.push('/pricing');
      return;
    }

    final titleController = TextEditingController();
    String selectedType = 'Custom';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    bool isRecurring = false;
    String? recurringPattern;
    final canUseRecurring = context.read<SubscriptionProvider>().canUse(
      SubscriptionFeature.recurringReminders,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (modalContext, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.divider(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'New Reminder',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Reminder Title',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  prefixIcon: Icon(Icons.category),
                ),
                items: AppConstants.reminderTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setModalState(() => selectedType = value!);
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: modalContext,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (!modalContext.mounted) return;
                  if (date != null) {
                    final time = await showTimePicker(
                      context: modalContext,
                      initialTime: TimeOfDay.now(),
                    );
                    if (!modalContext.mounted) return;
                    if (time != null) {
                      setModalState(() {
                        selectedDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date & Time',
                    prefixIcon: Icon(Icons.calendar_today),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    DateFormat('MMM d, y - h:mm a').format(selectedDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text('Recurring'),
                subtitle: canUseRecurring
                    ? null
                    : Text('Included with PawPal Plus'),
                value: isRecurring,
                onChanged: (value) async {
                  if (value && !canUseRecurring) {
                    final viewPlans = await showPremiumUpgradeDialog(
                      modalContext,
                      SubscriptionFeature.recurringReminders,
                    );
                    if (!mounted || !modalContext.mounted) return;
                    if (viewPlans) {
                      Navigator.pop(modalContext);
                      context.push('/pricing');
                    }
                    return;
                  }
                  setModalState(() {
                    isRecurring = value;
                    if (!value) recurringPattern = null;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              if (isRecurring) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: recurringPattern,
                  decoration: const InputDecoration(
                    labelText: 'Repeat',
                    prefixIcon: Icon(Icons.repeat),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  ],
                  onChanged: (value) {
                    setModalState(() => recurringPattern = value);
                  },
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) {
                    ScaffoldMessenger.of(modalContext).showSnackBar(
                      const SnackBar(content: Text('Please enter a title')),
                    );
                    return;
                  }

                  final now = DateTime.now();
                  final reminder = Reminder(
                    id: '',
                    userId: '',
                    type: selectedType,
                    title: titleController.text.trim(),
                    dueDate: selectedDate,
                    isRecurring: isRecurring,
                    recurringPattern: recurringPattern,
                    createdAt: now,
                    updatedAt: now,
                  );

                  try {
                    // Schedule against the created reminder: it carries the
                    // real id, which the notification ids are derived from.
                    final created = await _reminderService.createReminder(
                      reminder,
                    );
                    await NotificationService().scheduleReminderNotification(
                      created,
                    );
                    if (!mounted || !modalContext.mounted) return;
                    Navigator.pop(modalContext);
                    await _loadReminders();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reminder created')),
                    );
                  } catch (e) {
                    if (modalContext.mounted) {
                      ScaffoldMessenger.of(
                        modalContext,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: Text('Create Reminder'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeReminder(Reminder reminder) async {
    try {
      final result = await _reminderService.markAsCompleted(reminder.id);
      await NotificationService().cancelReminderNotifications(reminder.id);
      if (result.next != null) {
        await NotificationService().scheduleReminderNotification(result.next!);
      }
      await _loadReminders();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reminder completed!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Reminder?'),
        content: Text('Delete "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _reminderService.deleteReminder(reminder.id);
        await NotificationService().cancelReminderNotifications(reminder.id);
        await _loadReminders();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Reminder deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.primaryColor;
    return Semantics(
      label: '$label filter',
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? chipColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? chipColor : AppTheme.divider(context),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AppTheme.foregroundOn(chipColor)
                  : AppTheme.secondaryText(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onComplete,
    required this.onDelete,
  });

  Color get _statusColor {
    if (reminder.isDue) return AppTheme.errorColor;
    if (reminder.isDueToday) return AppTheme.warningColor;
    return AppTheme.primaryColor;
  }

  IconData get _typeIcon {
    switch (reminder.type) {
      case 'Medication':
        return Icons.medication;
      case 'Vaccination':
        return Icons.vaccines;
      case 'Appointment':
        return Icons.calendar_today;
      case 'Grooming':
        return Icons.content_cut;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${reminder.title} reminder, ${_formatDueDate()}',
      child: Dismissible(
        key: Key(reminder.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          color: AppTheme.errorColor,
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) => onDelete(),
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_typeIcon, color: _statusColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: TextStyle(
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
                            color: AppTheme.mutedText(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDueDate(),
                            style: TextStyle(
                              color: _statusColor,
                              fontSize: 13,
                              fontWeight: reminder.isDue
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          if (reminder.isRecurring) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.repeat,
                              size: 14,
                              color: AppTheme.mutedText(context),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onComplete,
                  tooltip: 'Mark as complete',
                  icon: const Icon(Icons.check_circle_outline),
                  color: AppTheme.successColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDueDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = DateTime(
      reminder.dueDate.year,
      reminder.dueDate.month,
      reminder.dueDate.day,
    );

    if (dueDay.isBefore(today)) {
      final days = today.difference(dueDay).inDays;
      return 'Overdue by $days ${days == 1 ? 'day' : 'days'}';
    } else if (dueDay == today) {
      return 'Today at ${DateFormat('h:mm a').format(reminder.dueDate)}';
    } else if (dueDay == tomorrow) {
      return 'Tomorrow at ${DateFormat('h:mm a').format(reminder.dueDate)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(reminder.dueDate);
    }
  }
}
