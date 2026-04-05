import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/models/medical_record.dart';

void main() {
  final now = DateTime(2025, 6, 15, 10, 30);

  Map<String, dynamic> _fullJson() => {
        'id': 'rec-123',
        'pet_id': 'pet-456',
        'type': 'vaccination',
        'title': 'Rabies Vaccine',
        'description': 'Annual rabies shot',
        'date': DateTime(2025, 1, 15).toIso8601String(),
        'end_date': DateTime(2026, 1, 15).toIso8601String(),
        'next_due_date': DateTime(2026, 1, 15).toIso8601String(),
        'provider': 'Dr. Smith',
        'dosage': '1ml',
        'frequency': 'annually',
        'document_url': 'https://example.com/doc.pdf',
        'metadata': {'batch_number': 'ABC123'},
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

  Map<String, dynamic> _minimalJson() => {
        'id': 'rec-123',
        'pet_id': 'pet-456',
        'type': 'vaccination',
        'title': 'Rabies Vaccine',
        'date': DateTime(2025, 1, 15).toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

  group('MedicalRecord.fromJson', () {
    test('parses all fields from complete JSON', () {
      final record = MedicalRecord.fromJson(_fullJson());

      expect(record.id, 'rec-123');
      expect(record.petId, 'pet-456');
      expect(record.type, MedicalRecordType.vaccination);
      expect(record.title, 'Rabies Vaccine');
      expect(record.description, 'Annual rabies shot');
      expect(record.date, DateTime(2025, 1, 15));
      expect(record.endDate, DateTime(2026, 1, 15));
      expect(record.nextDueDate, DateTime(2026, 1, 15));
      expect(record.provider, 'Dr. Smith');
      expect(record.dosage, '1ml');
      expect(record.frequency, 'annually');
      expect(record.documentUrl, 'https://example.com/doc.pdf');
      expect(record.metadata, {'batch_number': 'ABC123'});
    });

    test('handles missing optional fields', () {
      final record = MedicalRecord.fromJson(_minimalJson());

      expect(record.description, isNull);
      expect(record.endDate, isNull);
      expect(record.nextDueDate, isNull);
      expect(record.provider, isNull);
      expect(record.dosage, isNull);
      expect(record.frequency, isNull);
      expect(record.documentUrl, isNull);
      expect(record.metadata, isNull);
    });

    test('falls back to condition type for unknown type string', () {
      final json = _minimalJson();
      json['type'] = 'unknownType';
      final record = MedicalRecord.fromJson(json);

      expect(record.type, MedicalRecordType.condition);
    });

    test('parses each MedicalRecordType correctly', () {
      for (final type in MedicalRecordType.values) {
        final json = _minimalJson();
        json['type'] = type.name;
        final record = MedicalRecord.fromJson(json);
        expect(record.type, type);
      }
    });
  });

  group('MedicalRecord.toJson', () {
    test('produces expected map', () {
      final record = MedicalRecord.fromJson(_fullJson());
      final json = record.toJson();

      expect(json['id'], 'rec-123');
      expect(json['pet_id'], 'pet-456');
      expect(json['type'], 'vaccination');
      expect(json['title'], 'Rabies Vaccine');
      expect(json['description'], 'Annual rabies shot');
      expect(json['provider'], 'Dr. Smith');
      expect(json['dosage'], '1ml');
      expect(json['date'], isA<String>());
    });

    test('null optional fields serialize as null', () {
      final record = MedicalRecord.fromJson(_minimalJson());
      final json = record.toJson();

      expect(json['description'], isNull);
      expect(json['end_date'], isNull);
      expect(json['next_due_date'], isNull);
      expect(json['provider'], isNull);
      expect(json['dosage'], isNull);
      expect(json['document_url'], isNull);
    });
  });

  group('MedicalRecord round-trip', () {
    test('fromJson -> toJson -> fromJson preserves data', () {
      final original = MedicalRecord.fromJson(_fullJson());
      final roundTripped = MedicalRecord.fromJson(original.toJson());

      expect(roundTripped.id, original.id);
      expect(roundTripped.type, original.type);
      expect(roundTripped.title, original.title);
      expect(roundTripped.dosage, original.dosage);
      expect(roundTripped.date, original.date);
    });
  });

  group('MedicalRecord.copyWith', () {
    test('overrides specified fields', () {
      final record = MedicalRecord.fromJson(_fullJson());
      final updated = record.copyWith(
        title: 'Updated Title',
        dosage: '2ml',
      );

      expect(updated.title, 'Updated Title');
      expect(updated.dosage, '2ml');
      expect(updated.id, record.id);
      expect(updated.type, record.type);
    });
  });

  group('MedicalRecord computed properties', () {
    test('isActive returns true for medication with no end date', () {
      final json = _minimalJson();
      json['type'] = 'medication';
      final record = MedicalRecord.fromJson(json);
      expect(record.isActive, true);
    });

    test('isActive returns false for medication with past end date', () {
      final json = _minimalJson();
      json['type'] = 'medication';
      json['end_date'] = DateTime(2020, 1, 1).toIso8601String();
      final record = MedicalRecord.fromJson(json);
      expect(record.isActive, false);
    });

    test('isDue returns false when nextDueDate is null', () {
      final record = MedicalRecord.fromJson(_minimalJson());
      expect(record.isDue, false);
    });

    test('isDue returns true when nextDueDate is in the past', () {
      final json = _fullJson();
      json['next_due_date'] = DateTime(2020, 1, 1).toIso8601String();
      final record = MedicalRecord.fromJson(json);
      expect(record.isDue, true);
    });
  });
}
