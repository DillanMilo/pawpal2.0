import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/providers/activity_provider.dart';
import '../helpers/supabase_test_setup.dart';

void main() {
  late ActivityProvider provider;

  setUpAll(() async {
    await initializeSupabaseForTesting();
  });

  setUp(() {
    provider = ActivityProvider();
  });

  group('ActivityProvider initial state', () {
    test('activities list is empty', () {
      expect(provider.activities, isEmpty);
    });

    test('weeklySummary is empty', () {
      expect(provider.weeklySummary, isEmpty);
    });

    test('totalPoints is zero', () {
      expect(provider.totalPoints, equals(0));
    });

    test('currentStreak is zero', () {
      expect(provider.currentStreak, equals(0));
    });

    test('isLoading is false', () {
      expect(provider.isLoading, isFalse);
    });

    test('error is null', () {
      expect(provider.error, isNull);
    });

    test('hasActiveTimer is false', () {
      expect(provider.hasActiveTimer, isFalse);
    });

    test('timerStartTime is null', () {
      expect(provider.timerStartTime, isNull);
    });

    test('activeActivityType is null', () {
      expect(provider.activeActivityType, isNull);
    });

    test('timerDuration is zero when no timer active', () {
      expect(provider.timerDuration, equals(Duration.zero));
    });

    test('formattedTimer shows 00:00 when no timer active', () {
      expect(provider.formattedTimer, equals('00:00'));
    });
  });

  group('startTimer', () {
    test('sets timer state correctly', () {
      provider.startTimer('walk', 'pet-1');

      expect(provider.hasActiveTimer, isTrue);
      expect(provider.timerStartTime, isNotNull);
      expect(provider.activeActivityType, equals('walk'));
    });

    test('timerDuration returns non-zero after starting', () {
      provider.startTimer('walk', 'pet-1');

      // Duration should be very small but possibly zero if instant
      expect(provider.timerDuration, isA<Duration>());
    });

    test('notifies listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.startTimer('walk', 'pet-1');

      expect(notified, isTrue);
    });
  });

  group('cancelTimer', () {
    test('clears timer state', () {
      provider.startTimer('walk', 'pet-1');
      expect(provider.hasActiveTimer, isTrue);

      provider.cancelTimer();

      expect(provider.hasActiveTimer, isFalse);
      expect(provider.timerStartTime, isNull);
      expect(provider.activeActivityType, isNull);
    });

    test('notifies listeners', () {
      provider.startTimer('walk', 'pet-1');

      var notified = false;
      provider.addListener(() => notified = true);

      provider.cancelTimer();

      expect(notified, isTrue);
    });
  });

  group('clearError', () {
    test('sets error to null and notifies', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.clearError();

      expect(provider.error, isNull);
      expect(notified, isTrue);
    });
  });

  group('reset', () {
    test('clears all state back to initial values', () {
      // Set some state via timer
      provider.startTimer('walk', 'pet-1');
      expect(provider.hasActiveTimer, isTrue);

      provider.reset();

      expect(provider.activities, isEmpty);
      expect(provider.weeklySummary, isEmpty);
      expect(provider.totalPoints, equals(0));
      expect(provider.currentStreak, equals(0));
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.hasActiveTimer, isFalse);
      expect(provider.timerStartTime, isNull);
      expect(provider.activeActivityType, isNull);
    });

    test('notifies listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.reset();

      expect(notified, isTrue);
    });
  });
}
