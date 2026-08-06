import 'constants.dart';

class ActivityScoring {
  static const int dailyPointsLimit = 100;
  static const int initialLevelCost = 80;
  static const int levelCostGrowth = 10;
  static const int maxLevel = 50;
  static const int maxPoints =
      (maxLevel - 1) * initialLevelCost +
      ((maxLevel - 1) * (maxLevel - 2) ~/ 2) * levelCostGrowth;

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

  static int remainingDailyPoints(int earnedToday) =>
      (dailyPointsLimit - earnedToday).clamp(0, dailyPointsLimit);

  static int calculateAward(
    String type, {
    int? durationMinutes,
    int earnedToday = 0,
  }) {
    final activityPoints = calculatePoints(
      type,
      durationMinutes: durationMinutes,
    );
    return activityPoints.clamp(0, remainingDailyPoints(earnedToday));
  }

  static int levelForPoints(int totalPoints) {
    final safePoints = totalPoints.clamp(0, maxPoints);
    for (var level = maxLevel; level > 1; level--) {
      if (safePoints >= pointsRequiredForLevel(level)) return level;
    }
    return 1;
  }

  static int pointsRequiredForLevel(int level) {
    final safeLevel = level.clamp(1, maxLevel);
    final transitions = safeLevel - 1;
    return transitions * initialLevelCost +
        (transitions * (transitions - 1) ~/ 2) * levelCostGrowth;
  }

  static int pointsRequiredForNextLevel(int level) {
    final safeLevel = level.clamp(1, maxLevel);
    if (safeLevel >= maxLevel) return 0;
    return pointsRequiredForLevel(safeLevel + 1) -
        pointsRequiredForLevel(safeLevel);
  }

  static int pointsIntoCurrentLevel(int totalPoints) {
    if (totalPoints <= 0) return 0;
    if (totalPoints >= maxPoints) return 0;
    final level = levelForPoints(totalPoints);
    return totalPoints - pointsRequiredForLevel(level);
  }

  static int pointsToNextLevel(int totalPoints) {
    if (totalPoints >= maxPoints) return 0;
    final level = levelForPoints(totalPoints);
    return pointsRequiredForLevel(level + 1) - totalPoints.clamp(0, maxPoints);
  }

  static double levelProgress(int totalPoints) {
    if (totalPoints >= maxPoints) return 1;
    final level = levelForPoints(totalPoints);
    final levelCost = pointsRequiredForNextLevel(level);
    if (levelCost == 0) return 1;
    return pointsIntoCurrentLevel(totalPoints) / levelCost;
  }

  static String rankName(int totalPoints) {
    return levelTitle(levelForPoints(totalPoints));
  }

  static String levelTitle(int level) {
    final safeLevel = level.clamp(1, maxLevel);
    if (safeLevel <= levelTitles.length) return levelTitles[safeLevel - 1];
    if (safeLevel <= 25) return 'Devoted Companion';
    if (safeLevel <= 30) return 'Wellness Guardian';
    if (safeLevel <= 35) return 'Care Luminary';
    if (safeLevel <= 40) return 'Legendary Companion';
    if (safeLevel <= 45) return 'Master Caregiver';
    if (safeLevel < maxLevel) return 'PawPal Icon';
    return 'Forever Guardian';
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
