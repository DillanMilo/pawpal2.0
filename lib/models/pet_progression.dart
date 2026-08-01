import '../utils/activity_scoring.dart';

enum PetRewardType { badge, frame, accessory }

class PetReward {
  const PetReward({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.requiredLevel,
    this.emoji,
  });

  final String id;
  final String name;
  final String description;
  final PetRewardType type;
  final int requiredLevel;
  final String? emoji;
}

class PetLevelUpTransition {
  const PetLevelUpTransition({
    required this.previousLevel,
    required this.newLevel,
    required this.title,
    required this.unlockedRewards,
  });

  final int previousLevel;
  final int newLevel;
  final String title;
  final List<PetReward> unlockedRewards;
}

class PetProgression {
  const PetProgression(this.points);

  final int points;

  int get level => ActivityScoring.levelForPoints(points);
  String get title => ActivityScoring.rankName(points);
  double get progress => ActivityScoring.levelProgress(points);
  int get pointsToNextLevel => ActivityScoring.pointsToNextLevel(points);
  bool get isMaxLevel => points >= ActivityScoring.maxPoints;

  bool isUnlocked(PetReward reward) => level >= reward.requiredLevel;

  List<PetReward> get unlockedBadges =>
      badges.where(isUnlocked).toList(growable: false);

  static PetLevelUpTransition? levelUpBetween(
    int previousPoints,
    int currentPoints,
  ) {
    final previousLevel = ActivityScoring.levelForPoints(previousPoints);
    final newLevel = ActivityScoring.levelForPoints(currentPoints);
    if (newLevel <= previousLevel) return null;

    final unlockedRewards = allRewards
        .where(
          (reward) =>
              reward.requiredLevel > previousLevel &&
              reward.requiredLevel <= newLevel,
        )
        .toList(growable: false);
    return PetLevelUpTransition(
      previousLevel: previousLevel,
      newLevel: newLevel,
      title: ActivityScoring.levelTitle(newLevel),
      unlockedRewards: unlockedRewards,
    );
  }

  String selectedFrame(String requestedId) {
    final requested = frameById(requestedId);
    return requested != null && isUnlocked(requested)
        ? requested.id
        : 'classic';
  }

  String selectedAccessory(String requestedId) {
    final requested = accessoryById(requestedId);
    return requested != null && isUnlocked(requested) ? requested.id : 'none';
  }

  static PetReward? frameById(String id) {
    for (final reward in frames) {
      if (reward.id == id) return reward;
    }
    return null;
  }

  static PetReward? accessoryById(String id) {
    for (final reward in accessories) {
      if (reward.id == id) return reward;
    }
    return null;
  }

  static const badges = [
    PetReward(
      id: 'care_starter',
      name: 'Care Starter',
      description: 'Begin earning PawPoints through everyday care.',
      type: PetRewardType.badge,
      requiredLevel: 1,
      emoji: '🐾',
    ),
    PetReward(
      id: 'routine_rookie',
      name: 'Routine Rookie',
      description: 'Reach level 2 by keeping up healthy routines.',
      type: PetRewardType.badge,
      requiredLevel: 2,
      emoji: '🌟',
    ),
    PetReward(
      id: 'care_champion',
      name: 'Care Champion',
      description: 'Reach level 4 through consistent pet care.',
      type: PetRewardType.badge,
      requiredLevel: 4,
      emoji: '🏅',
    ),
    PetReward(
      id: 'pawpal_star',
      name: 'PawPal Star',
      description: 'Reach level 7 and become a care routine pro.',
      type: PetRewardType.badge,
      requiredLevel: 7,
      emoji: '🌟',
    ),
  ];

  static const frames = [
    PetReward(
      id: 'classic',
      name: 'Classic',
      description: 'A clean PawPal profile frame.',
      type: PetRewardType.frame,
      requiredLevel: 1,
    ),
    PetReward(
      id: 'meadow',
      name: 'Meadow',
      description: 'A fresh mint frame for healthy habits.',
      type: PetRewardType.frame,
      requiredLevel: 2,
    ),
    PetReward(
      id: 'sunset',
      name: 'Sunset',
      description: 'A warm frame for a devoted care buddy.',
      type: PetRewardType.frame,
      requiredLevel: 4,
    ),
    PetReward(
      id: 'starlight',
      name: 'Starlight',
      description: 'A sparkling frame for PawPal stars.',
      type: PetRewardType.frame,
      requiredLevel: 7,
    ),
  ];

  static const accessories = [
    PetReward(
      id: 'none',
      name: 'No accessory',
      description: 'Keep the profile simple.',
      type: PetRewardType.accessory,
      requiredLevel: 1,
    ),
    PetReward(
      id: 'heart',
      name: 'Heart',
      description: 'A little love for a cared-for pal.',
      type: PetRewardType.accessory,
      requiredLevel: 2,
      emoji: '💖',
    ),
    PetReward(
      id: 'play_ball',
      name: 'Play Ball',
      description: 'For pets who make playtime count.',
      type: PetRewardType.accessory,
      requiredLevel: 3,
      emoji: '🎾',
    ),
    PetReward(
      id: 'sparkles',
      name: 'Sparkles',
      description: 'Celebrate a glowing care routine.',
      type: PetRewardType.accessory,
      requiredLevel: 5,
      emoji: '✨',
    ),
    PetReward(
      id: 'crown',
      name: 'Care Crown',
      description: 'A crown earned through committed care.',
      type: PetRewardType.accessory,
      requiredLevel: 8,
      emoji: '👑',
    ),
  ];

  static List<PetReward> get allRewards => [
    ...badges,
    ...frames,
    ...accessories,
  ];
}
