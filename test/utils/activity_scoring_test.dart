import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/utils/activity_scoring.dart';
import 'package:pawpal/utils/constants.dart';

void main() {
  group('ActivityScoring', () {
    test('every activity has duration and cap configuration', () {
      for (final type in AppConstants.activityTypes) {
        expect(
          ActivityScoring.durationBonusPerTenMinutes.containsKey(type),
          true,
          reason: '$type is missing duration bonus configuration',
        );
        expect(
          ActivityScoring.maxPointsPerActivity.containsKey(type),
          true,
          reason: '$type is missing max points configuration',
        );
      }
    });

    test('awards base points when no duration is provided', () {
      expect(ActivityScoring.calculatePoints('Walk'), 10);
      expect(ActivityScoring.calculatePoints('Feed'), 5);
    });

    test('adds duration bonus for meaningful timed activities', () {
      expect(ActivityScoring.calculatePoints('Walk', durationMinutes: 30), 16);
      expect(ActivityScoring.calculatePoints('Train', durationMinutes: 45), 23);
    });

    test('does not add duration bonus for simple care checks', () {
      expect(ActivityScoring.calculatePoints('Feed', durationMinutes: 60), 5);
      expect(
        ActivityScoring.calculatePoints('Vet Visit', durationMinutes: 90),
        20,
      );
    });

    test('caps large activity logs', () {
      expect(ActivityScoring.calculatePoints('Walk', durationMinutes: 999), 30);
      expect(
        ActivityScoring.calculatePoints('Train', durationMinutes: 999),
        35,
      );
    });

    test('calculates level progress', () {
      expect(ActivityScoring.levelForPoints(0), 1);
      expect(ActivityScoring.levelForPoints(249), 1);
      expect(ActivityScoring.levelForPoints(250), 2);
      expect(ActivityScoring.pointsIntoCurrentLevel(375), 125);
      expect(ActivityScoring.pointsToNextLevel(375), 125);
      expect(ActivityScoring.levelProgress(125), 0.5);
    });

    test('returns rank names from point bands', () {
      expect(ActivityScoring.rankName(0), 'New Pal');
      expect(ActivityScoring.rankName(250), 'Care Cadet');
      expect(ActivityScoring.rankName(750), 'Routine Builder');
      expect(ActivityScoring.rankName(1500), 'Wellness Pro');
      expect(ActivityScoring.rankName(3000), 'PawPal Elite');
    });
  });
}
