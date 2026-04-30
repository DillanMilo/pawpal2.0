import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/models/activity.dart';

void main() {
  final now = DateTime(2025, 6, 15, 10, 30);

  Map<String, dynamic> fullJson() => {
    'id': 'act-123',
    'pet_id': 'pet-456',
    'user_id': 'user-789',
    'type': 'Walk',
    'start_time': now.toIso8601String(),
    'end_time': now.add(const Duration(minutes: 45)).toIso8601String(),
    'duration_minutes': 45,
    'distance': 2.5,
    'notes': 'Great walk in the park',
    'photo_urls': ['https://example.com/a.jpg', 'https://example.com/b.jpg'],
    'points': 10,
    'metadata': {'weather': 'sunny'},
    'created_at': now.toIso8601String(),
  };

  Map<String, dynamic> minimalJson() => {
    'id': 'act-123',
    'pet_id': 'pet-456',
    'user_id': 'user-789',
    'type': 'Walk',
    'start_time': now.toIso8601String(),
    'points': 10,
    'created_at': now.toIso8601String(),
  };

  group('Activity.fromJson', () {
    test('parses all fields from complete JSON', () {
      final activity = Activity.fromJson(fullJson());

      expect(activity.id, 'act-123');
      expect(activity.petId, 'pet-456');
      expect(activity.userId, 'user-789');
      expect(activity.type, 'Walk');
      expect(activity.startTime, now);
      expect(activity.endTime, now.add(const Duration(minutes: 45)));
      expect(activity.durationMinutes, 45);
      expect(activity.distance, 2.5);
      expect(activity.notes, 'Great walk in the park');
      expect(activity.photoUrls, hasLength(2));
      expect(activity.points, 10);
      expect(activity.metadata, {'weather': 'sunny'});
    });

    test('handles missing optional fields', () {
      final activity = Activity.fromJson(minimalJson());

      expect(activity.endTime, isNull);
      expect(activity.durationMinutes, isNull);
      expect(activity.distance, isNull);
      expect(activity.notes, isNull);
      expect(activity.photoUrls, isNull);
      expect(activity.metadata, isNull);
    });

    test('defaults points to 0 when missing', () {
      final json = minimalJson();
      json.remove('points');
      final activity = Activity.fromJson(json);
      expect(activity.points, 0);
    });
  });

  group('Activity.toJson', () {
    test('produces expected map', () {
      final activity = Activity.fromJson(fullJson());
      final json = activity.toJson();

      expect(json['id'], 'act-123');
      expect(json['pet_id'], 'pet-456');
      expect(json['user_id'], 'user-789');
      expect(json['type'], 'Walk');
      expect(json['points'], 10);
      expect(json['distance'], 2.5);
      expect(json['photo_urls'], hasLength(2));
      expect(json['start_time'], isA<String>());
    });

    test('null optional fields serialize as null', () {
      final activity = Activity.fromJson(minimalJson());
      final json = activity.toJson();

      expect(json['end_time'], isNull);
      expect(json['duration_minutes'], isNull);
      expect(json['distance'], isNull);
      expect(json['notes'], isNull);
      expect(json['photo_urls'], isNull);
    });
  });

  group('Activity round-trip', () {
    test('fromJson -> toJson -> fromJson preserves data', () {
      final original = Activity.fromJson(fullJson());
      final roundTripped = Activity.fromJson(original.toJson());

      expect(roundTripped.id, original.id);
      expect(roundTripped.type, original.type);
      expect(roundTripped.points, original.points);
      expect(roundTripped.distance, original.distance);
      expect(roundTripped.startTime, original.startTime);
      expect(roundTripped.endTime, original.endTime);
    });
  });

  group('Activity.copyWith', () {
    test('overrides specified fields', () {
      final activity = Activity.fromJson(fullJson());
      final updated = activity.copyWith(type: 'Play', points: 8);

      expect(updated.type, 'Play');
      expect(updated.points, 8);
      expect(updated.id, activity.id);
      expect(updated.distance, activity.distance);
    });
  });

  group('Activity.calculatedDuration', () {
    test('returns durationMinutes when set', () {
      final activity = Activity.fromJson(fullJson());
      expect(activity.calculatedDuration, 45);
    });

    test('calculates from start and end time when durationMinutes is null', () {
      final json = minimalJson();
      json['end_time'] = now.add(const Duration(minutes: 30)).toIso8601String();
      final activity = Activity.fromJson(json);

      expect(activity.durationMinutes, isNull);
      expect(activity.calculatedDuration, 30);
    });

    test('returns 0 when neither durationMinutes nor endTime is set', () {
      final activity = Activity.fromJson(minimalJson());
      expect(activity.calculatedDuration, 0);
    });
  });
}
