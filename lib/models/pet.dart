class Pet {
  static const Object _unset = Object();

  final String id;
  final String userId;
  final String name;
  final String species;
  final String? breed;
  final DateTime? dateOfBirth;
  final String gender;
  final String? photoUrl;
  final String? coverPhotoUrl;
  final double? weight;
  final String? colorMarkings;
  final String? microchipNumber;
  final bool spayedNeutered;
  final DateTime? adoptionDate;
  final int displayOrder;
  final String profileFrameId;
  final String profileAccessoryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Pet({
    required this.id,
    required this.userId,
    required this.name,
    required this.species,
    this.breed,
    this.dateOfBirth,
    required this.gender,
    this.photoUrl,
    this.coverPhotoUrl,
    this.weight,
    this.colorMarkings,
    this.microchipNumber,
    this.spayedNeutered = false,
    this.adoptionDate,
    this.displayOrder = 0,
    this.profileFrameId = 'classic',
    this.profileAccessoryId = 'none',
    required this.createdAt,
    required this.updatedAt,
  });

  int? get ageInYears {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int years = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      years--;
    }
    return years;
  }

  String get ageDisplay {
    if (dateOfBirth == null) return 'Unknown';
    final years = ageInYears ?? 0;
    if (years == 0) {
      final months = DateTime.now().difference(dateOfBirth!).inDays ~/ 30;
      return '$months months';
    }
    return '$years ${years == 1 ? 'year' : 'years'}';
  }

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      species: json['species'] as String,
      breed: json['breed'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      gender: json['gender'] as String,
      photoUrl: json['photo_url'] as String?,
      coverPhotoUrl: json['cover_photo_url'] as String?,
      weight: (json['weight'] as num?)?.toDouble(),
      colorMarkings: json['color_markings'] as String?,
      microchipNumber: json['microchip_number'] as String?,
      spayedNeutered: json['spayed_neutered'] as bool? ?? false,
      adoptionDate: json['adoption_date'] != null
          ? DateTime.parse(json['adoption_date'] as String)
          : null,
      displayOrder: json['display_order'] as int? ?? 0,
      profileFrameId: json['profile_frame_id'] as String? ?? 'classic',
      profileAccessoryId: json['profile_accessory_id'] as String? ?? 'none',
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  // DATE columns must stay calendar dates; converting to UTC could shift
  // them to the previous day for users east of Greenwich.
  static String? _dateOnly(DateTime? value) =>
      value?.toIso8601String().split('T').first;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'species': species,
      'breed': breed,
      'date_of_birth': _dateOnly(dateOfBirth),
      'gender': gender,
      'photo_url': photoUrl,
      'cover_photo_url': coverPhotoUrl,
      'weight': weight,
      'color_markings': colorMarkings,
      'microchip_number': microchipNumber,
      'spayed_neutered': spayedNeutered,
      'adoption_date': _dateOnly(adoptionDate),
      'display_order': displayOrder,
      'profile_frame_id': profileFrameId,
      'profile_accessory_id': profileAccessoryId,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  Pet copyWith({
    String? id,
    String? userId,
    String? name,
    String? species,
    Object? breed = _unset,
    Object? dateOfBirth = _unset,
    String? gender,
    Object? photoUrl = _unset,
    Object? coverPhotoUrl = _unset,
    Object? weight = _unset,
    Object? colorMarkings = _unset,
    Object? microchipNumber = _unset,
    bool? spayedNeutered,
    Object? adoptionDate = _unset,
    int? displayOrder,
    String? profileFrameId,
    String? profileAccessoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: identical(breed, _unset) ? this.breed : breed as String?,
      dateOfBirth: identical(dateOfBirth, _unset)
          ? this.dateOfBirth
          : dateOfBirth as DateTime?,
      gender: gender ?? this.gender,
      photoUrl: identical(photoUrl, _unset)
          ? this.photoUrl
          : photoUrl as String?,
      coverPhotoUrl: identical(coverPhotoUrl, _unset)
          ? this.coverPhotoUrl
          : coverPhotoUrl as String?,
      weight: identical(weight, _unset) ? this.weight : weight as double?,
      colorMarkings: identical(colorMarkings, _unset)
          ? this.colorMarkings
          : colorMarkings as String?,
      microchipNumber: identical(microchipNumber, _unset)
          ? this.microchipNumber
          : microchipNumber as String?,
      spayedNeutered: spayedNeutered ?? this.spayedNeutered,
      adoptionDate: identical(adoptionDate, _unset)
          ? this.adoptionDate
          : adoptionDate as DateTime?,
      displayOrder: displayOrder ?? this.displayOrder,
      profileFrameId: profileFrameId ?? this.profileFrameId,
      profileAccessoryId: profileAccessoryId ?? this.profileAccessoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
