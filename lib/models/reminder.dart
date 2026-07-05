class Reminder {
  final String id;
  final String userId;
  final String? petId;
  final String type;
  final String title;
  final String? description;
  final DateTime dueDate;
  final bool isCompleted;
  final bool isRecurring;
  final String? recurringPattern; // daily, weekly, monthly
  final DateTime createdAt;
  final DateTime updatedAt;

  Reminder({
    required this.id,
    required this.userId,
    this.petId,
    required this.type,
    required this.title,
    this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.isRecurring = false,
    this.recurringPattern,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDue => dueDate.isBefore(DateTime.now()) && !isCompleted;
  bool get isDueToday {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day &&
        !isCompleted;
  }

  bool get isUpcoming =>
      dueDate.isAfter(DateTime.now()) &&
      dueDate.difference(DateTime.now()).inDays <= 7 &&
      !isCompleted;

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      petId: json['pet_id'] as String?,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: DateTime.parse(json['due_date'] as String).toLocal(),
      isCompleted: json['is_completed'] as bool? ?? false,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurringPattern: json['recurring_pattern'] as String?,
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
      'description': description,
      'due_date': dueDate.toUtc().toIso8601String(),
      'is_completed': isCompleted,
      'is_recurring': isRecurring,
      'recurring_pattern': recurringPattern,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  Reminder copyWith({
    String? id,
    String? userId,
    String? petId,
    String? type,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    bool? isRecurring,
    String? recurringPattern,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
