import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/models/appointment.dart';

void main() {
  final now = DateTime(2025, 6, 15, 10, 30);

  Map<String, dynamic> fullJson() => {
    'id': 'apt-123',
    'user_id': 'user-456',
    'pet_id': 'pet-789',
    'type': 'Vet',
    'title': 'Annual Checkup',
    'date_time': now.toIso8601String(),
    'provider': 'Dr. Smith',
    'provider_address': '123 Main St',
    'notes': 'Bring vaccination records',
    'reminder_minutes_before': 60,
    'is_completed': false,
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  };

  Map<String, dynamic> minimalJson() => {
    'id': 'apt-123',
    'user_id': 'user-456',
    'type': 'Vet',
    'title': 'Annual Checkup',
    'date_time': now.toIso8601String(),
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  };

  group('Appointment.fromJson', () {
    test('parses all fields from complete JSON', () {
      final apt = Appointment.fromJson(fullJson());

      expect(apt.id, 'apt-123');
      expect(apt.userId, 'user-456');
      expect(apt.petId, 'pet-789');
      expect(apt.type, 'Vet');
      expect(apt.title, 'Annual Checkup');
      expect(apt.dateTime, now);
      expect(apt.provider, 'Dr. Smith');
      expect(apt.providerAddress, '123 Main St');
      expect(apt.notes, 'Bring vaccination records');
      expect(apt.reminderMinutesBefore, 60);
      expect(apt.isCompleted, false);
    });

    test('handles missing optional fields', () {
      final apt = Appointment.fromJson(minimalJson());

      expect(apt.petId, isNull);
      expect(apt.provider, isNull);
      expect(apt.providerAddress, isNull);
      expect(apt.notes, isNull);
      expect(apt.reminderMinutesBefore, isNull);
      expect(apt.isCompleted, false);
    });

    test('defaults isCompleted to false when missing', () {
      final json = minimalJson();
      final apt = Appointment.fromJson(json);
      expect(apt.isCompleted, false);
    });
  });

  group('Appointment.toJson', () {
    test('produces expected map with all fields', () {
      final apt = Appointment.fromJson(fullJson());
      final json = apt.toJson();

      expect(json['id'], 'apt-123');
      expect(json['user_id'], 'user-456');
      expect(json['pet_id'], 'pet-789');
      expect(json['type'], 'Vet');
      expect(json['title'], 'Annual Checkup');
      expect(json['provider'], 'Dr. Smith');
      expect(json['reminder_minutes_before'], 60);
      expect(json['is_completed'], false);
      expect(json['date_time'], isA<String>());
    });

    test('null optional fields serialize as null', () {
      final apt = Appointment.fromJson(minimalJson());
      final json = apt.toJson();

      expect(json['pet_id'], isNull);
      expect(json['provider'], isNull);
      expect(json['provider_address'], isNull);
      expect(json['notes'], isNull);
      expect(json['reminder_minutes_before'], isNull);
    });
  });

  group('Appointment round-trip', () {
    test('fromJson -> toJson -> fromJson preserves data', () {
      final original = Appointment.fromJson(fullJson());
      final roundTripped = Appointment.fromJson(original.toJson());

      expect(roundTripped.id, original.id);
      expect(roundTripped.title, original.title);
      expect(roundTripped.type, original.type);
      expect(roundTripped.provider, original.provider);
      expect(roundTripped.dateTime, original.dateTime);
      expect(roundTripped.isCompleted, original.isCompleted);
    });
  });

  group('Appointment.copyWith', () {
    test('overrides specified fields', () {
      final apt = Appointment.fromJson(fullJson());
      final updated = apt.copyWith(title: 'Dental Cleaning', isCompleted: true);

      expect(updated.title, 'Dental Cleaning');
      expect(updated.isCompleted, true);
      expect(updated.id, apt.id);
      expect(updated.provider, apt.provider);
    });
  });

  group('Appointment computed properties', () {
    test('isPast returns true for past date', () {
      final json = fullJson();
      json['date_time'] = DateTime(2020, 1, 1).toIso8601String();
      final apt = Appointment.fromJson(json);
      expect(apt.isPast, true);
    });

    test('isPast returns false for future date', () {
      final json = fullJson();
      json['date_time'] = DateTime(2099, 1, 1).toIso8601String();
      final apt = Appointment.fromJson(json);
      expect(apt.isPast, false);
    });

    test('isToday returns true for today', () {
      final today = DateTime.now();
      final json = fullJson();
      json['date_time'] = DateTime(
        today.year,
        today.month,
        today.day,
        14,
        0,
      ).toIso8601String();
      final apt = Appointment.fromJson(json);
      expect(apt.isToday, true);
    });

    test('isUpcoming returns true for future non-today date', () {
      final json = fullJson();
      json['date_time'] = DateTime(2099, 1, 1).toIso8601String();
      final apt = Appointment.fromJson(json);
      expect(apt.isUpcoming, true);
    });
  });
}
