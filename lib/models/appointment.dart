class Appointment {
  final String id;
  final String userId;
  final String? petId;
  final String type;
  final String title;
  final DateTime dateTime;
  final String? provider;
  final String? providerAddress;
  final String? notes;
  final int? reminderMinutesBefore;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Appointment({
    required this.id,
    required this.userId,
    this.petId,
    required this.type,
    required this.title,
    required this.dateTime,
    this.provider,
    this.providerAddress,
    this.notes,
    this.reminderMinutesBefore,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPast => dateTime.isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  bool get isUpcoming => !isPast && !isToday;

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      petId: json['pet_id'] as String?,
      type: json['type'] as String,
      title: json['title'] as String,
      dateTime: DateTime.parse(json['date_time'] as String).toLocal(),
      provider: json['provider'] as String?,
      providerAddress: json['provider_address'] as String?,
      notes: json['notes'] as String?,
      reminderMinutesBefore: json['reminder_minutes_before'] as int?,
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'pet_id': petId,
      'type': type,
      'title': title,
      'date_time': dateTime.toUtc().toIso8601String(),
      'provider': provider,
      'provider_address': providerAddress,
      'notes': notes,
      'reminder_minutes_before': reminderMinutesBefore,
      'is_completed': isCompleted,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  Appointment copyWith({
    String? id,
    String? userId,
    String? petId,
    String? type,
    String? title,
    DateTime? dateTime,
    String? provider,
    String? providerAddress,
    String? notes,
    int? reminderMinutesBefore,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      type: type ?? this.type,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      provider: provider ?? this.provider,
      providerAddress: providerAddress ?? this.providerAddress,
      notes: notes ?? this.notes,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
