import 'package:uuid/uuid.dart';
import 'supabase_service.dart';
import '../models/activity.dart';
import '../utils/activity_scoring.dart';

class ActivityService {
  final _client = SupabaseService.client;
  final _uuid = const Uuid();

  // Get activities for a pet
  Future<List<Activity>> getActivities(String petId, {int? limit}) async {
    var query = _client
        .from('activities')
        .select()
        .eq('pet_id', petId)
        .order('start_time', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return (response as List).map((e) => Activity.fromJson(e)).toList();
  }

  // Get activities for a date range
  Future<List<Activity>> getActivitiesInRange(
    String petId,
    DateTime start,
    DateTime end,
  ) async {
    final response = await _client
        .from('activities')
        .select()
        .eq('pet_id', petId)
        .gte('start_time', start.toUtc().toIso8601String())
        .lte('start_time', end.toUtc().toIso8601String())
        .order('start_time', ascending: false);

    return (response as List).map((e) => Activity.fromJson(e)).toList();
  }

  // Get pet activities (alias for getActivities)
  Future<List<Activity>> getPetActivities(String petId, {int? limit}) async {
    return getActivities(petId, limit: limit);
  }

  // Get user activities (alias for getAllUserActivities)
  Future<List<Activity>> getUserActivities({int? limit}) async {
    return getAllUserActivities(limit: limit);
  }

  // Get all activities for user (all pets)
  Future<List<Activity>> getAllUserActivities({int? limit}) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    var query = _client
        .from('activities')
        .select()
        .eq('user_id', userId)
        .order('start_time', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return (response as List).map((e) => Activity.fromJson(e)).toList();
  }

  // Get today's activities
  Future<List<Activity>> getTodayActivities(String petId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getActivitiesInRange(petId, startOfDay, endOfDay);
  }

  // Log an activity
  Future<Activity> logActivity(Activity activity) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final points = ActivityScoring.calculatePoints(
      activity.type,
      durationMinutes: activity.durationMinutes,
    );

    final data = activity.toJson();
    data['id'] = _uuid.v4();
    data['user_id'] = userId;
    data['points'] = points;
    data['created_at'] = DateTime.now().toUtc().toIso8601String();

    final response = await _client
        .from('activities')
        .insert(data)
        .select()
        .single();

    return Activity.fromJson(response);
  }

  // Update an activity
  Future<Activity> updateActivity(Activity activity) async {
    final data = activity.toJson();

    final response = await _client
        .from('activities')
        .update(data)
        .eq('id', activity.id)
        .select()
        .single();

    return Activity.fromJson(response);
  }

  // Delete an activity
  Future<void> deleteActivity(String activityId) async {
    await _client.from('activities').delete().eq('id', activityId);
  }

  // Get total points for user
  Future<int> getTotalPoints() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return 0;

    final response = await _client
        .from('activities')
        .select('points')
        .eq('user_id', userId);

    int total = 0;
    for (final row in response as List) {
      total += (row['points'] as int?) ?? 0;
    }
    return total;
  }

  // Get activity count by type
  Future<Map<String, int>> getActivityCountsByType(String petId) async {
    final response = await _client
        .from('activities')
        .select('type')
        .eq('pet_id', petId);

    final counts = <String, int>{};
    for (final row in response as List) {
      final type = row['type'] as String;
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  // Get activity counts by type for the current user across all pets
  Future<Map<String, int>> getUserActivityCountsByType() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return {};

    final response = await _client
        .from('activities')
        .select('type')
        .eq('user_id', userId);

    final counts = <String, int>{};
    for (final row in response as List) {
      final type = row['type'] as String;
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  // Get current streak
  Future<int> getCurrentStreak() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cutoff = today.subtract(const Duration(days: 365));

    // Single query: fetch all user activities in the last 365 days
    final response = await _client
        .from('activities')
        .select('start_time')
        .eq('user_id', userId)
        .gte('start_time', cutoff.toUtc().toIso8601String())
        .order('start_time', ascending: false);

    if ((response as List).isEmpty) return 0;

    // Build a set of unique active dates (local calendar days)
    final activeDates = <DateTime>{};
    for (final row in response) {
      final dt = DateTime.parse(row['start_time'] as String).toLocal();
      activeDates.add(DateTime(dt.year, dt.month, dt.day));
    }

    // Compute streak by walking backwards from today (or yesterday if today has no activity)
    DateTime checkDate = today;
    if (!activeDates.contains(checkDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
      if (!activeDates.contains(checkDate)) return 0;
    }

    int streak = 0;
    while (activeDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
      if (streak > 365) break;
    }

    return streak;
  }

  // Get weekly activity summary
  Future<Map<String, int>> getWeeklySummary(String petId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final end = start.add(const Duration(days: 7));

    final activities = await getActivitiesInRange(petId, start, end);

    final summary = <String, int>{};
    for (int i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      final dayKey =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      summary[dayKey] = 0;
    }

    for (final activity in activities) {
      final day = activity.startTime;
      final dayKey =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      summary[dayKey] = (summary[dayKey] ?? 0) + activity.points;
    }

    return summary;
  }
}
