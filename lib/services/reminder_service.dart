import 'package:uuid/uuid.dart';
import 'supabase_service.dart';
import '../models/reminder.dart';

class ReminderService {
  final _client = SupabaseService.client;
  final _uuid = const Uuid();

  // Get all reminders for user
  Future<List<Reminder>> getReminders() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    final response = await _client
        .from('reminders')
        .select()
        .eq('user_id', userId)
        .order('due_date', ascending: true);

    return (response as List).map((e) => Reminder.fromJson(e)).toList();
  }

  // Get reminders for a specific pet
  Future<List<Reminder>> getPetReminders(String petId) async {
    final response = await _client
        .from('reminders')
        .select()
        .eq('pet_id', petId)
        .order('due_date', ascending: true);

    return (response as List).map((e) => Reminder.fromJson(e)).toList();
  }

  // Get active (incomplete) reminders
  Future<List<Reminder>> getActiveReminders() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    final response = await _client
        .from('reminders')
        .select()
        .eq('user_id', userId)
        .eq('is_completed', false)
        .order('due_date', ascending: true);

    return (response as List).map((e) => Reminder.fromJson(e)).toList();
  }

  // Get upcoming reminders (next 7 days)
  Future<List<Reminder>> getUpcomingReminders() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));

    final response = await _client
        .from('reminders')
        .select()
        .eq('user_id', userId)
        .eq('is_completed', false)
        .gte('due_date', now.toUtc().toIso8601String())
        .lte('due_date', weekFromNow.toUtc().toIso8601String())
        .order('due_date', ascending: true);

    return (response as List).map((e) => Reminder.fromJson(e)).toList();
  }

  // Get overdue reminders
  Future<List<Reminder>> getOverdueReminders() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    final now = DateTime.now().toUtc().toIso8601String();

    final response = await _client
        .from('reminders')
        .select()
        .eq('user_id', userId)
        .eq('is_completed', false)
        .lt('due_date', now)
        .order('due_date', ascending: true);

    return (response as List).map((e) => Reminder.fromJson(e)).toList();
  }

  // Get today's reminders
  Future<List<Reminder>> getTodayReminders() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await _client
        .from('reminders')
        .select()
        .eq('user_id', userId)
        .gte('due_date', startOfDay.toUtc().toIso8601String())
        .lt('due_date', endOfDay.toUtc().toIso8601String())
        .order('due_date', ascending: true);

    return (response as List).map((e) => Reminder.fromJson(e)).toList();
  }

  // Create a reminder
  Future<Reminder> createReminder(Reminder reminder) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final now = DateTime.now().toUtc().toIso8601String();
    final data = reminder.toJson();
    data['id'] = _uuid.v4();
    data['user_id'] = userId;
    data['created_at'] = now;
    data['updated_at'] = now;

    final response = await _client
        .from('reminders')
        .insert(data)
        .select()
        .single();

    return Reminder.fromJson(response);
  }

  // Update a reminder
  Future<Reminder> updateReminder(Reminder reminder) async {
    final data = reminder.toJson();
    data['updated_at'] = DateTime.now().toUtc().toIso8601String();

    final response = await _client
        .from('reminders')
        .update(data)
        .eq('id', reminder.id)
        .select()
        .single();

    return Reminder.fromJson(response);
  }

  // Mark reminder as completed. Returns the completed reminder plus the
  // next occurrence when the reminder is recurring, so callers can schedule
  // a notification for it.
  Future<({Reminder completed, Reminder? next})> markAsCompleted(
    String reminderId,
  ) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final response = await _client
        .from('reminders')
        .update({'is_completed': true, 'updated_at': now})
        .eq('id', reminderId)
        .select()
        .single();

    final reminder = Reminder.fromJson(response);

    // If recurring, create next reminder
    Reminder? next;
    if (reminder.isRecurring && reminder.recurringPattern != null) {
      next = await _createNextRecurringReminder(reminder);
    }

    return (completed: reminder, next: next);
  }

  // Create next recurring reminder
  Future<Reminder?> _createNextRecurringReminder(Reminder original) async {
    DateTime nextDue;
    switch (original.recurringPattern) {
      case 'daily':
        nextDue = original.dueDate.add(const Duration(days: 1));
        break;
      case 'weekly':
        nextDue = original.dueDate.add(const Duration(days: 7));
        break;
      case 'monthly':
        var year = original.dueDate.year;
        var month = original.dueDate.month + 1;
        if (month > 12) {
          month = 1;
          year++;
        }
        // Clamp to the last day of the next month (Jan 31 -> Feb 28/29).
        final lastDay = DateTime(year, month + 1, 0).day;
        nextDue = DateTime(
          year,
          month,
          original.dueDate.day > lastDay ? lastDay : original.dueDate.day,
          original.dueDate.hour,
          original.dueDate.minute,
        );
        break;
      default:
        return null;
    }

    final newReminder = Reminder(
      id: '',
      userId: original.userId,
      petId: original.petId,
      type: original.type,
      title: original.title,
      description: original.description,
      dueDate: nextDue,
      isRecurring: true,
      recurringPattern: original.recurringPattern,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return createReminder(newReminder);
  }

  // Delete a reminder
  Future<void> deleteReminder(String reminderId) async {
    await _client.from('reminders').delete().eq('id', reminderId);
  }
}
