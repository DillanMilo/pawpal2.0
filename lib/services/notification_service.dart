import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/reminder.dart';
import '../utils/router.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    debugPrint('NotificationService initialized');
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    final router = AppRouter.instance;
    if (router == null) return;

    // Map payload to route
    if (payload.startsWith('reminder:')) {
      router.go('/reminders');
    } else if (payload == 'daily_activity' || payload == 'streak_reminder') {
      router.go('/log-activity');
    } else if (payload.startsWith('pet:')) {
      final petId = payload.substring(4);
      router.go('/pet/$petId');
    } else {
      // Fallback: try using payload directly as a route
      router.go('/home');
    }
  }

  Future<bool> requestPermissions() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    bool? granted;
    if (androidPlugin != null) {
      granted = await androidPlugin.requestNotificationsPermission();
    }
    if (iosPlugin != null) {
      granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return granted ?? false;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'pawpal_general',
      'General Notifications',
      channelDescription: 'General PawPal notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'pawpal_reminders',
      'Reminders',
      channelDescription: 'Pet care reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Returns true if the given notification preference key is enabled.
  /// Also returns false if the master toggle is off.
  Future<bool> _isNotificationEnabled(String prefKey) async {
    final prefs = await SharedPreferences.getInstance();
    final masterEnabled = prefs.getBool('notifications_enabled') ?? true;
    if (!masterEnabled) return false;
    return prefs.getBool(prefKey) ?? true;
  }

  Future<void> scheduleReminderNotification(Reminder reminder) async {
    if (!await _isNotificationEnabled('reminder_notifications')) return;

    // Schedule notification 1 hour before due date
    final notifyTime = reminder.dueDate.subtract(const Duration(hours: 1));

    if (notifyTime.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: reminder.id.hashCode,
        title: 'Reminder: ${reminder.title}',
        body: 'Due in 1 hour - ${reminder.type}',
        scheduledDate: notifyTime,
        payload: 'reminder:${reminder.id}',
      );
    }

    // Also schedule at due time
    if (reminder.dueDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: '${reminder.id}_due'.hashCode,
        title: 'Reminder Due: ${reminder.title}',
        body: '${reminder.type} is due now!',
        scheduledDate: reminder.dueDate,
        payload: 'reminder:${reminder.id}',
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelReminderNotifications(String reminderId) async {
    await _notifications.cancel(reminderId.hashCode);
    await _notifications.cancel('${reminderId}_due'.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Daily reminder for activity tracking
  Future<void> scheduleDailyActivityReminder({
    required int hour,
    required int minute,
  }) async {
    if (!await _isNotificationEnabled('streak_notifications')) return;

    const androidDetails = AndroidNotificationDetails(
      'pawpal_daily',
      'Daily Reminders',
      channelDescription: 'Daily pet care reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule daily at specified time
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      0, // ID for daily reminder
      "Don't forget your pet!",
      'Log an activity with your furry friend today',
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_activity',
    );
  }

  // Streak reminder
  Future<void> scheduleStreakReminder() async {
    if (!await _isNotificationEnabled('streak_notifications')) return;

    const androidDetails = AndroidNotificationDetails(
      'pawpal_streaks',
      'Streak Reminders',
      channelDescription: 'Activity streak reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule for 8 PM
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 20, 0);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      1, // ID for streak reminder
      'Keep your streak alive!',
      "You haven't logged any activity today. Don't lose your streak!",
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'streak_reminder',
    );
  }
}
