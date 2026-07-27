class UserProfile {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final String? phoneNumber;
  final String? zipCode;
  final bool notificationsEnabled;
  final bool hasSeenPricing;
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
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
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
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
