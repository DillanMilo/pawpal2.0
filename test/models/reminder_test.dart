import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/models/reminder.dart';

void main() {
  final now = DateTime(2025, 6, 15, 10, 30);

  Map<String, dynamic> fullJson() => {
    'id': 'rem-123',
    'user_id': 'user-456',
    'pet_id': 'pet-789',
    'type': 'Medication',
    'title': 'Give heartworm pill',
    'description': 'Monthly heartworm prevention',
    'due_date': now.toIso8601String(),
    'is_completed': false,
    'is_recurring': true,
    'recurring_pattern': 'monthly',
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  };

  Map<String, dynamic> minimalJson() => {
    'id': 'rem-123',
    'user_id': 'user-456',
    'type': 'Medication',
    'title': 'Give heartworm pill',
    'due_date': now.toIso8601String(),
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  };

  group('Reminder.fromJson', () {
    test('parses all fields from complete JSON', () {
      final reminder = Reminder.fromJson(fullJson());

      expect(reminder.id, 'rem-123');
      expect(reminder.userId, 'user-456');
      expect(reminder.petId, 'pet-789');
      expect(reminder.type, 'Medication');
      expect(reminder.title, 'Give heartworm pill');
      expect(reminder.description, 'Monthly heartworm prevention');
      expect(reminder.dueDate, now);
      expect(reminder.isCompleted, false);
      expect(reminder.isRecurring, true);
      expect(reminder.recurringPattern, 'monthly');
    });

    test('handles missing optional fields', () {
      final reminder = Reminder.fromJson(minimalJson());

      expect(reminder.petId, isNull);
      expect(reminder.description, isNull);
      expect(reminder.isCompleted, false);
      expect(reminder.isRecurring, false);
      expect(reminder.recurringPattern, isNull);
    });

    test('defaults booleans to false when missing', () {
      final json = minimalJson();
      final reminder = Reminder.fromJson(json);
      expect(reminder.isCompleted, false);
      expect(reminder.isRecurring, false);
    });
  });

  group('Reminder.toJson', () {
    test('produces expected map with all fields', () {
      final reminder = Reminder.fromJson(fullJson());
      final json = reminder.toJson();

      expect(json['id'], 'rem-123');
      expect(json['user_id'], 'user-456');
      expect(json['pet_id'], 'pet-789');
      expect(json['type'], 'Medication');
      expect(json['title'], 'Give heartworm pill');
      expect(json['description'], 'Monthly heartworm prevention');
      expect(json['is_completed'], false);
      expect(json['is_recurring'], true);
      expect(json['recurring_pattern'], 'monthly');
      expect(json['due_date'], isA<String>());
    });

    test('null optional fields serialize as null', () {
      final reminder = Reminder.fromJson(minimalJson());
      final json = reminder.toJson();

      expect(json['pet_id'], isNull);
      expect(json['description'], isNull);
      expect(json['recurring_pattern'], isNull);
    });
  });

  group('Reminder round-trip', () {
    test('fromJson -> toJson -> fromJson preserves data', () {
      final original = Reminder.fromJson(fullJson());
      final roundTripped = Reminder.fromJson(original.toJson());

      expect(roundTripped.id, original.id);
      expect(roundTripped.title, original.title);
      expect(roundTripped.type, original.type);
      expect(roundTripped.isRecurring, original.isRecurring);
      expect(roundTripped.recurringPattern, original.recurringPattern);
      expect(roundTripped.dueDate, original.dueDate);
    });
  });

  group('Reminder.copyWith', () {
    test('overrides specified fields', () {
      final reminder = Reminder.fromJson(fullJson());
      final updated = reminder.copyWith(
        title: 'Updated Title',
        isCompleted: true,
      );

      expect(updated.title, 'Updated Title');
      expect(updated.isCompleted, true);
      expect(updated.id, reminder.id);
      expect(updated.type, reminder.type);
      expect(updated.isRecurring, reminder.isRecurring);
    });
  });

  group('Reminder computed properties', () {
    test('isDue returns true for past uncompleted reminder', () {
      final json = fullJson();
      json['due_date'] = DateTime(2020, 1, 1).toIso8601String();
      json['is_completed'] = false;
      final reminder = Reminder.fromJson(json);
      expect(reminder.isDue, true);
    });

    test('isDue returns false for completed reminder', () {
      final json = fullJson();
      json['due_date'] = DateTime(2020, 1, 1).toIso8601String();
      json['is_completed'] = true;
      final reminder = Reminder.fromJson(json);
      expect(reminder.isDue, false);
    });

    test('isDueToday returns true for today uncompleted reminder', () {
      final today = DateTime.now();
      final json = fullJson();
      json['due_date'] = DateTime(
        today.year,
        today.month,
        today.day,
        14,
        0,
      ).toIso8601String();
      json['is_completed'] = false;
      final reminder = Reminder.fromJson(json);
      expect(reminder.isDueToday, true);
    });

    test('isDueToday returns false for completed reminder', () {
      final today = DateTime.now();
      final json = fullJson();
      json['due_date'] = DateTime(
        today.year,
        today.month,
        today.day,
        14,
        0,
      ).toIso8601String();
      json['is_completed'] = true;
      final reminder = Reminder.fromJson(json);
      expect(reminder.isDueToday, false);
    });

    test('isUpcoming returns true for near-future uncompleted reminder', () {
      final json = fullJson();
      json['due_date'] = DateTime.now()
          .add(const Duration(days: 3))
          .toIso8601String();
      json['is_completed'] = false;
      final reminder = Reminder.fromJson(json);
      expect(reminder.isUpcoming, true);
    });

    test('isUpcoming returns false for far-future reminder', () {
      final json = fullJson();
      json['due_date'] = DateTime.now()
          .add(const Duration(days: 30))
          .toIso8601String();
      json['is_completed'] = false;
      final reminder = Reminder.fromJson(json);
      expect(reminder.isUpcoming, false);
    });
  });
}
