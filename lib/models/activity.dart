class Activity {
  final String id;
  final String petId;
  final String userId;
  final String type;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final double? distance;
  final String? notes;
  final List<String>? photoUrls;
  final int points;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  Activity({
    required this.id,
    required this.petId,
    required this.userId,
    required this.type,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    this.distance,
    this.notes,
    this.photoUrls,
    required this.points,
    this.metadata,
    required this.createdAt,
  });

  int get calculatedDuration {
    if (durationMinutes != null) return durationMinutes!;
    if (endTime != null) {
      return endTime!.difference(startTime).inMinutes;
    }
    return 0;
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String).toLocal()
          : null,
      durationMinutes: json['duration_minutes'] as int?,
      distance: (json['distance'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      photoUrls: (json['photo_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      points: json['points'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'user_id': userId,
      'type': type,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime?.toUtc().toIso8601String(),
      'duration_minutes': durationMinutes,
      'distance': distance,
      'notes': notes,
      'photo_urls': photoUrls,
      'points': points,
      'metadata': metadata,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  Activity copyWith({
    String? id,
    String? petId,
    String? userId,
    String? type,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    double? distance,
    String? notes,
    List<String>? photoUrls,
    int? points,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return Activity(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      distance: distance ?? this.distance,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      points: points ?? this.points,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
