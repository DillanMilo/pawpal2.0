import 'constants.dart';

class ActivityScoring {
  static const int pointsPerLevel = 250;

  static const Map<String, int> durationBonusPerTenMinutes = {
    'Walk': 2,
    'Play': 1,
    'Train': 2,
    'Feed': 0,
    'Groom': 1,
    'Vet Visit': 0,
    'Social': 1,
    'Rest': 0,
  };

  static const Map<String, int> maxPointsPerActivity = {
    'Walk': 30,
    'Play': 22,
    'Train': 35,
    'Feed': 5,
    'Groom': 16,
    'Vet Visit': 20,
    'Social': 24,
    'Rest': 3,
  };

  static int calculatePoints(String type, {int? durationMinutes}) {
    final base = AppConstants.activityPoints[type] ?? 5;
    final bonusRate = durationBonusPerTenMinutes[type] ?? 0;
    final duration = durationMinutes == null || durationMinutes < 0
        ? 0
        : durationMinutes;
    final durationBonus = (duration ~/ 10) * bonusRate;
    final rawPoints = base + durationBonus;
    final cap = maxPointsPerActivity[type] ?? rawPoints;
    return rawPoints.clamp(base, cap).toInt();
  }

  static int levelForPoints(int totalPoints) {
    if (totalPoints <= 0) return 1;
    return (totalPoints ~/ pointsPerLevel) + 1;
  }

  static int pointsIntoCurrentLevel(int totalPoints) {
    if (totalPoints <= 0) return 0;
    return totalPoints % pointsPerLevel;
  }

  static int pointsToNextLevel(int totalPoints) {
    final current = pointsIntoCurrentLevel(totalPoints);
    return current == 0 && totalPoints > 0
        ? pointsPerLevel
        : pointsPerLevel - current;
  }

  static double levelProgress(int totalPoints) {
    return pointsIntoCurrentLevel(totalPoints) / pointsPerLevel;
  }

  static String rankName(int totalPoints) {
    if (totalPoints >= 3000) return 'PawPal Elite';
    if (totalPoints >= 1500) return 'Wellness Pro';
    if (totalPoints >= 750) return 'Routine Builder';
    if (totalPoints >= 250) return 'Care Cadet';
    return 'New Pal';
  }
}
