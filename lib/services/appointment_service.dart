import 'package:uuid/uuid.dart';
import 'supabase_service.dart';
import '../models/appointment.dart';

class AppointmentService {
  final _client = SupabaseService.client;
  final _uuid = const Uuid();

  // Get all appointments for user
  Future<List<Appointment>> getAppointments() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    final response = await _client
        .from('appointments')
        .select()
        .eq('user_id', userId)
        .order('date_time', ascending: true);

    return (response as List).map((e) => Appointment.fromJson(e)).toList();
  }

  // Get appointments for a specific pet
  Future<List<Appointment>> getPetAppointments(String petId) async {
    final response = await _client
        .from('appointments')
        .select()
        .eq('pet_id', petId)
        .order('date_time', ascending: true);

    return (response as List).map((e) => Appointment.fromJson(e)).toList();
  }

  // Get upcoming appointments
  Future<List<Appointment>> getUpcomingAppointments({int? limit}) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    final now = DateTime.now().toUtc().toIso8601String();
    var query = _client
        .from('appointments')
        .select()
        .eq('user_id', userId)
        .eq('is_completed', false)
        .gte('date_time', now)
        .order('date_time', ascending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return (response as List).map((e) => Appointment.fromJson(e)).toList();
  }

  // Get appointments for a date range
  Future<List<Appointment>> getAppointmentsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    final response = await _client
        .from('appointments')
        .select()
        .eq('user_id', userId)
        .gte('date_time', start.toUtc().toIso8601String())
        .lte('date_time', end.toUtc().toIso8601String())
        .order('date_time', ascending: true);

    return (response as List).map((e) => Appointment.fromJson(e)).toList();
  }

  // Get appointments for a specific day
  Future<List<Appointment>> getAppointmentsForDay(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getAppointmentsInRange(startOfDay, endOfDay);
  }

  // Get today's appointments
  Future<List<Appointment>> getTodayAppointments() async {
    return getAppointmentsForDay(DateTime.now());
  }

  // Create an appointment
  Future<Appointment> createAppointment(Appointment appointment) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final now = DateTime.now().toUtc().toIso8601String();
    final data = appointment.toJson();
    data['id'] = _uuid.v4();
    data['user_id'] = userId;
    data['created_at'] = now;
    data['updated_at'] = now;

    final response = await _client
        .from('appointments')
        .insert(data)
        .select()
        .single();

    return Appointment.fromJson(response);
  }

  // Update an appointment
  Future<Appointment> updateAppointment(Appointment appointment) async {
    final data = appointment.toJson();
    data['updated_at'] = DateTime.now().toUtc().toIso8601String();

    final response = await _client
        .from('appointments')
        .update(data)
        .eq('id', appointment.id)
        .select()
        .single();

    return Appointment.fromJson(response);
  }

  // Mark appointment as completed
  Future<Appointment> markAsCompleted(String appointmentId) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final response = await _client
        .from('appointments')
        .update({'is_completed': true, 'updated_at': now})
        .eq('id', appointmentId)
        .select()
        .single();

    return Appointment.fromJson(response);
  }

  // Delete an appointment
  Future<void> deleteAppointment(String appointmentId) async {
    await _client.from('appointments').delete().eq('id', appointmentId);
  }

  // Get appointment count for month
  Future<Map<DateTime, int>> getMonthlyAppointmentCounts(
    int year,
    int month,
  ) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return {};

    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    final appointments = await getAppointmentsInRange(startOfMonth, endOfMonth);

    final counts = <DateTime, int>{};
    for (final appointment in appointments) {
      final date = DateTime(
        appointment.dateTime.year,
        appointment.dateTime.month,
        appointment.dateTime.day,
      );
      counts[date] = (counts[date] ?? 0) + 1;
    }

    return counts;
  }
}
