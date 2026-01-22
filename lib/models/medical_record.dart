enum MedicalRecordType {
  medication,
  vaccination,
  allergy,
  condition,
  vetVisit,
  groomingVisit,
  surgery,
  labResult,
}

class MedicalRecord {
  final String id;
  final String petId;
  final MedicalRecordType type;
  final String title;
  final String? description;
  final DateTime date;
  final DateTime? endDate;
  final DateTime? nextDueDate;
  final String? provider;
  final String? dosage;
  final String? frequency;
  final String? documentUrl;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicalRecord({
    required this.id,
    required this.petId,
    required this.type,
    required this.title,
    this.description,
    required this.date,
    this.endDate,
    this.nextDueDate,
    this.provider,
    this.dosage,
    this.frequency,
    this.documentUrl,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive {
    if (type == MedicalRecordType.medication) {
      if (endDate == null) return true;
      return DateTime.now().isBefore(endDate!);
    }
    return true;
  }

  bool get isDue {
    if (nextDueDate == null) return false;
    return DateTime.now().isAfter(nextDueDate!);
  }

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      type: MedicalRecordType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MedicalRecordType.condition,
      ),
      title: json['title'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      nextDueDate: json['next_due_date'] != null
          ? DateTime.parse(json['next_due_date'] as String)
          : null,
      provider: json['provider'] as String?,
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      documentUrl: json['document_url'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'type': type.name,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'next_due_date': nextDueDate?.toIso8601String(),
      'provider': provider,
      'dosage': dosage,
      'frequency': frequency,
      'document_url': documentUrl,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MedicalRecord copyWith({
    String? id,
    String? petId,
    MedicalRecordType? type,
    String? title,
    String? description,
    DateTime? date,
    DateTime? endDate,
    DateTime? nextDueDate,
    String? provider,
    String? dosage,
    String? frequency,
    String? documentUrl,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicalRecord(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      provider: provider ?? this.provider,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      documentUrl: documentUrl ?? this.documentUrl,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
