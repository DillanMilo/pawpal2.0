class UserProfile {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final String? phoneNumber;
  final String? zipCode;
  final bool notificationsEnabled;
  final bool hasSeenPricing;
  final int onboardingStep;
  final Map<String, dynamic> onboardingDraft;
  final DateTime? onboardingCompletedAt;
  final int appTourStep;
  final DateTime? appTourCompletedAt;
  final DateTime? quickActionsTourCompletedAt;
  final DateTime? petProfileTourCompletedAt;
  final bool supportsFirstRun;
  final bool supportsContextualTours;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    this.phoneNumber,
    this.zipCode,
    this.notificationsEnabled = true,
    this.hasSeenPricing = true,
    this.onboardingStep = 0,
    this.onboardingDraft = const {},
    this.onboardingCompletedAt,
    this.appTourStep = 0,
    this.appTourCompletedAt,
    this.quickActionsTourCompletedAt,
    this.petProfileTourCompletedAt,
    this.supportsFirstRun = true,
    this.supportsContextualTours = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get needsOnboarding => supportsFirstRun && onboardingCompletedAt == null;

  bool get needsAppTour =>
      supportsFirstRun &&
      onboardingCompletedAt != null &&
      appTourCompletedAt == null;

  bool get needsQuickActionsTour =>
      supportsContextualTours && quickActionsTourCompletedAt == null;

  bool get needsPetProfileTour =>
      supportsContextualTours && petProfileTourCompletedAt == null;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final supportsFirstRun = json.containsKey('onboarding_completed_at');
    final supportsContextualTours =
        json.containsKey('quick_actions_tour_completed_at') &&
        json.containsKey('pet_profile_tour_completed_at');
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      photoUrl: json['photo_url'] as String?,
      phoneNumber: json['phone_number'] as String?,
      zipCode: json['zip_code'] as String?,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      // Default true keeps older databases from trapping users in onboarding
      // before migration 011 has been applied.
      hasSeenPricing: json['has_seen_pricing'] as bool? ?? true,
      onboardingStep: json['onboarding_step'] as int? ?? 0,
      onboardingDraft: Map<String, dynamic>.from(
        json['onboarding_draft'] as Map? ?? const {},
      ),
      onboardingCompletedAt: json['onboarding_completed_at'] != null
          ? DateTime.parse(json['onboarding_completed_at'] as String).toLocal()
          : null,
      appTourStep: json['app_tour_step'] as int? ?? 0,
      appTourCompletedAt: json['app_tour_completed_at'] != null
          ? DateTime.parse(json['app_tour_completed_at'] as String).toLocal()
          : null,
      quickActionsTourCompletedAt:
          json['quick_actions_tour_completed_at'] != null
          ? DateTime.parse(
              json['quick_actions_tour_completed_at'] as String,
            ).toLocal()
          : null,
      petProfileTourCompletedAt: json['pet_profile_tour_completed_at'] != null
          ? DateTime.parse(
              json['pet_profile_tour_completed_at'] as String,
            ).toLocal()
          : null,
      supportsFirstRun: supportsFirstRun,
      supportsContextualTours: supportsContextualTours,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'email': email,
      'name': name,
      'photo_url': photoUrl,
      'phone_number': phoneNumber,
      'zip_code': zipCode,
      'notifications_enabled': notificationsEnabled,
      'has_seen_pricing': hasSeenPricing,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
    if (supportsFirstRun) {
      json.addAll({
        'onboarding_step': onboardingStep,
        'onboarding_draft': onboardingDraft,
        'onboarding_completed_at': onboardingCompletedAt
            ?.toUtc()
            .toIso8601String(),
        'app_tour_step': appTourStep,
        'app_tour_completed_at': appTourCompletedAt?.toUtc().toIso8601String(),
      });
    }
    if (supportsContextualTours) {
      json.addAll({
        'quick_actions_tour_completed_at': quickActionsTourCompletedAt
            ?.toUtc()
            .toIso8601String(),
        'pet_profile_tour_completed_at': petProfileTourCompletedAt
            ?.toUtc()
            .toIso8601String(),
      });
    }
    return json;
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    String? phoneNumber,
    String? zipCode,
    bool? notificationsEnabled,
    bool? hasSeenPricing,
    int? onboardingStep,
    Map<String, dynamic>? onboardingDraft,
    DateTime? onboardingCompletedAt,
    int? appTourStep,
    DateTime? appTourCompletedAt,
    DateTime? quickActionsTourCompletedAt,
    DateTime? petProfileTourCompletedAt,
    bool? supportsFirstRun,
    bool? supportsContextualTours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      zipCode: zipCode ?? this.zipCode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      hasSeenPricing: hasSeenPricing ?? this.hasSeenPricing,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      onboardingDraft: onboardingDraft ?? this.onboardingDraft,
      onboardingCompletedAt:
          onboardingCompletedAt ?? this.onboardingCompletedAt,
      appTourStep: appTourStep ?? this.appTourStep,
      appTourCompletedAt: appTourCompletedAt ?? this.appTourCompletedAt,
      quickActionsTourCompletedAt:
          quickActionsTourCompletedAt ?? this.quickActionsTourCompletedAt,
      petProfileTourCompletedAt:
          petProfileTourCompletedAt ?? this.petProfileTourCompletedAt,
      supportsFirstRun: supportsFirstRun ?? this.supportsFirstRun,
      supportsContextualTours:
          supportsContextualTours ?? this.supportsContextualTours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
