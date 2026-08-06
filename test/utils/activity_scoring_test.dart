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

    test('caps the total PawPoints awarded in one day', () {
      expect(ActivityScoring.calculateAward('Walk', earnedToday: 95), 5);
      expect(ActivityScoring.calculateAward('Vet Visit', earnedToday: 100), 0);
      expect(ActivityScoring.remainingDailyPoints(125), 0);
    });

    test(
      'uses a fast-early, progressively slower level curve capped at 50',
      () {
        expect(ActivityScoring.levelForPoints(0), 1);
        expect(ActivityScoring.pointsRequiredForLevel(2), 80);
        expect(ActivityScoring.pointsRequiredForLevel(3), 170);
        expect(ActivityScoring.levelForPoints(79), 1);
        expect(ActivityScoring.levelForPoints(80), 2);
        expect(ActivityScoring.pointsRequiredForNextLevel(2), 90);
        expect(ActivityScoring.pointsRequiredForNextLevel(49), 560);
        expect(ActivityScoring.pointsRequiredForLevel(50), 15680);
        expect(ActivityScoring.levelForPoints(15679), 49);
        expect(ActivityScoring.levelForPoints(15680), 50);
        expect(ActivityScoring.levelForPoints(99999), 50);
        expect(ActivityScoring.pointsIntoCurrentLevel(125), 45);
        expect(ActivityScoring.pointsToNextLevel(125), 45);
        expect(ActivityScoring.levelProgress(125), 0.5);
        expect(ActivityScoring.pointsToNextLevel(15680), 0);
        expect(ActivityScoring.levelProgress(15680), 1.0);
      },
    );

    test('returns rank names from level progression', () {
      expect(ActivityScoring.rankName(0), 'New Pal');
      expect(ActivityScoring.rankName(80), 'Care Cadet');
      expect(ActivityScoring.rankName(270), 'Walk Wrangler');
      expect(ActivityScoring.rankName(630), 'Wellness Watcher');
      expect(ActivityScoring.rankName(15680), 'Forever Guardian');
      expect(ActivityScoring.nextRankName(79), 'Care Cadet');
      expect(ActivityScoring.nextRankName(15680), isNull);
      expect(ActivityScoring.levelProgressLabel(79), '1 to Care Cadet');
      expect(ActivityScoring.levelProgressLabel(15680), 'Max rank reached');
    });
  });
}
