import 'package:flutter/foundation.dart';
import '../models/activity.dart';
import '../services/activity_service.dart';

class ActivityProvider with ChangeNotifier {
  final ActivityService _activityService = ActivityService();

  List<Activity> _activities = [];
  Map<String, int> _weeklySummary = {};
  int _totalPoints = 0;
  int _currentStreak = 0;
  bool _isLoading = false;
  String? _error;

  // Timer state
  DateTime? _timerStartTime;
  String? _activeActivityType;
  String? _activeActivityPetId;

  List<Activity> get activities => _activities;
  Map<String, int> get weeklySummary => _weeklySummary;
  int get totalPoints => _totalPoints;
  int get currentStreak => _currentStreak;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveTimer => _timerStartTime != null;
  DateTime? get timerStartTime => _timerStartTime;
  String? get activeActivityType => _activeActivityType;

  Future<void> loadActivities(String petId, {int? limit}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _activities = await _activityService.getActivities(petId, limit: limit);
      _weeklySummary = await _activityService.getWeeklySummary(petId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStats() async {
    try {
      _totalPoints = await _activityService.getTotalPoints();
      _currentStreak = await _activityService.getCurrentStreak();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> logActivity(Activity activity) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final newActivity = await _activityService.logActivity(activity);
      _activities.insert(0, newActivity);

      // Reload stats
      await loadStats();
      if (activity.petId.isNotEmpty) {
        _weeklySummary = await _activityService.getWeeklySummary(activity.petId);
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteActivity(String activityId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _activityService.deleteActivity(activityId);
      _activities.removeWhere((a) => a.id == activityId);

      // Reload stats
      await loadStats();

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Timer methods
  void startTimer(String activityType, String petId) {
    _timerStartTime = DateTime.now();
    _activeActivityType = activityType;
    _activeActivityPetId = petId;
    notifyListeners();
  }

  Duration get timerDuration {
    if (_timerStartTime == null) return Duration.zero;
    return DateTime.now().difference(_timerStartTime!);
  }

  Future<Activity?> stopTimer({String? notes}) async {
    if (_timerStartTime == null ||
        _activeActivityType == null ||
        _activeActivityPetId == null) {
      return null;
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(_timerStartTime!).inMinutes;

    final activity = Activity(
      id: '',
      petId: _activeActivityPetId!,
      userId: '',
      type: _activeActivityType!,
      startTime: _timerStartTime!,
      endTime: endTime,
      durationMinutes: duration,
      notes: notes,
      points: 0,
      createdAt: DateTime.now(),
    );

    // Reset timer
    _timerStartTime = null;
    _activeActivityType = null;
    _activeActivityPetId = null;

    // Log the activity
    final success = await logActivity(activity);
    if (success) {
      return _activities.first;
    }
    return null;
  }

  void cancelTimer() {
    _timerStartTime = null;
    _activeActivityType = null;
    _activeActivityPetId = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _activities = [];
    _weeklySummary = {};
    _totalPoints = 0;
    _currentStreak = 0;
    _isLoading = false;
    _error = null;
    _timerStartTime = null;
    _activeActivityType = null;
    _activeActivityPetId = null;
    notifyListeners();
  }
}
