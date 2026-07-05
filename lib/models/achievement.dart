class Achievement {
  final String id;
  final String userId;
  final String badgeId;
  final String name;
  final String description;
  final String iconName;
  final DateTime unlockedAt;

  Achievement({
    required this.id,
    required this.userId,
    required this.badgeId,
    required this.name,
    required this.description,
    required this.iconName,
    required this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      badgeId: json['badge_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconName: json['icon_name'] as String,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'badge_id': badgeId,
      'name': name,
      'description': description,
      'icon_name': iconName,
      'unlocked_at': unlockedAt.toIso8601String(),
    };
  }
}

class Badge {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final String requirement;
  final int threshold;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.requirement,
    required this.threshold,
  });

  static List<Badge> get allBadges => [
    Badge(
      id: 'first_walk',
      name: 'First Walk',
      description: 'Complete your first walk with your pet',
      iconName: 'directions_walk',
      requirement: 'walk_count',
      threshold: 1,
    ),
    Badge(
      id: 'week_warrior',
      name: 'Week Warrior',
      description: '7-day activity streak',
      iconName: 'local_fire_department',
      requirement: 'streak_days',
      threshold: 7,
    ),
    Badge(
      id: 'training_pro',
      name: 'Training Pro',
      description: 'Complete 10 training sessions',
      iconName: 'school',
      requirement: 'training_count',
      threshold: 10,
    ),
    Badge(
      id: 'social_butterfly',
      name: 'Social Butterfly',
      description: '5 socialization events',
      iconName: 'groups',
      requirement: 'social_count',
      threshold: 5,
    ),
    Badge(
      id: 'health_champion',
      name: 'Health Champion',
      description: 'All vaccinations up to date',
      iconName: 'verified',
      requirement: 'vaccinations_complete',
      threshold: 1,
    ),
    Badge(
      id: 'consistent_caregiver',
      name: 'Consistent Caregiver',
      description: '30-day streak',
      iconName: 'emoji_events',
      requirement: 'streak_days',
      threshold: 30,
    ),
  ];
}
