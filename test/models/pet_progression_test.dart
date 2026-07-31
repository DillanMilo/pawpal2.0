import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/models/pet_progression.dart';

void main() {
  group('PetProgression', () {
    test('derives pet level and progress from care points', () {
      const progression = PetProgression(125);

      expect(progression.level, 2);
      expect(progression.title, 'Care Cadet');
      expect(progression.progress, 0.5);
      expect(progression.pointsToNextLevel, 45);
      expect(progression.isMaxLevel, isFalse);
    });

    test('unlocks badges and cosmetics at their required level', () {
      const progression = PetProgression(380);

      expect(progression.level, 5);
      expect(
        progression.unlockedBadges.map((reward) => reward.id),
        containsAll(['care_starter', 'routine_rookie', 'care_champion']),
      );
      expect(progression.selectedFrame('sunset'), 'sunset');
      expect(progression.selectedAccessory('sparkles'), 'sparkles');
      expect(progression.selectedAccessory('crown'), 'none');
    });

    test('falls back safely for unknown or locked saved rewards', () {
      const progression = PetProgression(0);

      expect(progression.selectedFrame('starlight'), 'classic');
      expect(progression.selectedFrame('unknown'), 'classic');
      expect(progression.selectedAccessory('heart'), 'none');
      expect(progression.selectedAccessory('unknown'), 'none');
    });

    test('creates a celebration transition only when a level is crossed', () {
      expect(PetProgression.levelUpBetween(60, 79), isNull);
      expect(PetProgression.levelUpBetween(80, 110), isNull);
      expect(PetProgression.levelUpBetween(170, 169), isNull);

      final transition = PetProgression.levelUpBetween(79, 80);
      expect(transition, isNotNull);
      expect(transition!.previousLevel, 1);
      expect(transition.newLevel, 2);
      expect(transition.title, 'Care Cadet');
      expect(
        transition.unlockedRewards.map((reward) => reward.id),
        containsAll(['routine_rookie', 'meadow', 'heart']),
      );
    });

    test(
      'reports every reward unlocked when one log crosses several levels',
      () {
        final transition = PetProgression.levelUpBetween(79, 380);

        expect(transition!.newLevel, 5);
        expect(
          transition.unlockedRewards.map((reward) => reward.id),
          containsAll(['care_champion', 'sunset', 'sparkles']),
        );
      },
    );
  });
}
