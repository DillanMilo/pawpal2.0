class ServiceProvider {
  final String id;
  final String? placeId; // Google Places ID
  final String name;
  final String type; // vet, groomer, pet_store
  final String address;
  final double? latitude;
  final double? longitude;
  final String? phoneNumber;
  final String? website;
  final double? rating;
  final int? reviewCount;
  final String? photoUrl;
  final Map<String, String>? openingHours;
  final List<String>? services;
  final bool isFavorite;
  final double? distance; // Calculated, not stored
  final DateTime? createdAt;

  ServiceProvider({
    required this.id,
    this.placeId,
    required this.name,
    required this.type,
    required this.address,
    this.latitude,
    this.longitude,
    this.phoneNumber,
    this.website,
    this.rating,
    this.reviewCount,
    this.photoUrl,
    this.openingHours,
    this.services,
    this.isFavorite = false,
    this.distance,
    this.createdAt,
  });

  bool get isOpen {
    if (openingHours == null) return false;
    final now = DateTime.now();
    final dayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final todayHours = openingHours![dayNames[now.weekday - 1]];
    if (todayHours == null || todayHours.toLowerCase() == 'closed') {
      return false;
    }
    // Simplified - would need proper parsing for accurate check
    return true;
  }

  String get distanceDisplay {
    if (distance == null) return '';
    if (distance! < 1) {
      return '${(distance! * 1000).round()} m';
    }
    return '${distance!.toStringAsFixed(1)} km';
  }

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['id'] as String,
      placeId: json['place_id'] as String?,
      name: json['name'] as String,
      type: json['type'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      phoneNumber: json['phone_number'] as String?,
      website: json['website'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int?,
      photoUrl: json['photo_url'] as String?,
      openingHours: (json['opening_hours'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v as String),
      ),
      services: (json['services'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isFavorite: json['is_favorite'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'place_id': placeId,
      'name': name,
      'type': type,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone_number': phoneNumber,
      'website': website,
      'rating': rating,
      'review_count': reviewCount,
      'photo_url': photoUrl,
      'opening_hours': openingHours,
      'services': services,
      'is_favorite': isFavorite,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  ServiceProvider copyWith({
    String? id,
    String? placeId,
    String? name,
    String? type,
    String? address,
    double? latitude,
    double? longitude,
    String? phoneNumber,
    String? website,
    double? rating,
    int? reviewCount,
    String? photoUrl,
    Map<String, String>? openingHours,
    List<String>? services,
    bool? isFavorite,
    double? distance,
    DateTime? createdAt,
  }) {
    return ServiceProvider(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      photoUrl: photoUrl ?? this.photoUrl,
      openingHours: openingHours ?? this.openingHours,
      services: services ?? this.services,
      isFavorite: isFavorite ?? this.isFavorite,
      distance: distance ?? this.distance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
