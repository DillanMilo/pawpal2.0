import 'constants.dart';

class ActivityScoring {
  static const int pointsPerLevel = 250;
  static const int maxLevel = 20;
  static const int maxPoints = maxLevel * pointsPerLevel;

  static const List<String> levelTitles = [
    'New Pal',
    'Care Cadet',
    'Routine Rookie',
    'Walk Wrangler',
    'Playtime Pro',
    'Training Scout',
    'Wellness Watcher',
    'Treat Tactician',
    'Grooming Guide',
    'Adventure Buddy',
    'Streak Specialist',
    'Health Hero',
    'Routine Builder',
    'Paw Planner',
    'Care Captain',
    'Wellness Pro',
    'Pack Leader',
    'PawPal Champion',
    'Legendary Guardian',
    'PawPal Elite',
  ];

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
    if (totalPoints >= maxPoints) return maxLevel;
    return ((totalPoints ~/ pointsPerLevel) + 1).clamp(1, maxLevel);
  }

  static int pointsIntoCurrentLevel(int totalPoints) {
    if (totalPoints <= 0) return 0;
    if (totalPoints >= maxPoints) return pointsPerLevel;
    return totalPoints % pointsPerLevel;
  }

  static int pointsToNextLevel(int totalPoints) {
    if (totalPoints >= maxPoints) return 0;
    final current = pointsIntoCurrentLevel(totalPoints);
    return current == 0 && totalPoints > 0
        ? pointsPerLevel
        : pointsPerLevel - current;
  }

  static double levelProgress(int totalPoints) {
    return pointsIntoCurrentLevel(totalPoints) / pointsPerLevel;
  }

  static String rankName(int totalPoints) {
    return levelTitle(levelForPoints(totalPoints));
  }

  static String levelTitle(int level) {
    final index = level.clamp(1, maxLevel) - 1;
    return levelTitles[index];
  }

  static String? nextRankName(int totalPoints) {
    final level = levelForPoints(totalPoints);
    if (totalPoints >= maxPoints || level >= maxLevel) return null;
    return levelTitle(level + 1);
  }

  static String levelProgressLabel(int totalPoints) {
    final pointsRemaining = pointsToNextLevel(totalPoints);
    if (totalPoints >= maxPoints) return 'Max rank reached';

    final nextRank = nextRankName(totalPoints);
    if (nextRank == null) return '$pointsRemaining to max';
    return '$pointsRemaining to $nextRank';
  }
}
