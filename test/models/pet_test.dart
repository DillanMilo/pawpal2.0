import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/models/pet.dart';

void main() {
  final now = DateTime(2025, 6, 15, 10, 30);
  final birthDate = DateTime(2022, 3, 10);

  Map<String, dynamic> fullJson() => {
    'id': 'pet-123',
    'user_id': 'user-456',
    'name': 'Buddy',
    'species': 'Dog',
    'breed': 'Golden Retriever',
    'date_of_birth': birthDate.toIso8601String(),
    'gender': 'Male',
    'photo_url': 'https://example.com/photo.jpg',
    'weight': 30.5,
    'color_markings': 'Golden',
    'microchip_number': 'MC-12345',
    'spayed_neutered': true,
    'adoption_date': DateTime(2022, 5, 1).toIso8601String(),
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  };

  Map<String, dynamic> minimalJson() => {
    'id': 'pet-123',
    'user_id': 'user-456',
    'name': 'Buddy',
    'species': 'Dog',
    'gender': 'Male',
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  };

  group('Pet.fromJson', () {
    test('parses all fields from complete JSON', () {
      final pet = Pet.fromJson(fullJson());

      expect(pet.id, 'pet-123');
      expect(pet.userId, 'user-456');
      expect(pet.name, 'Buddy');
      expect(pet.species, 'Dog');
      expect(pet.breed, 'Golden Retriever');
      expect(pet.dateOfBirth, birthDate);
      expect(pet.gender, 'Male');
      expect(pet.photoUrl, 'https://example.com/photo.jpg');
      expect(pet.weight, 30.5);
      expect(pet.colorMarkings, 'Golden');
      expect(pet.microchipNumber, 'MC-12345');
      expect(pet.spayedNeutered, true);
      expect(pet.adoptionDate, DateTime(2022, 5, 1));
      expect(pet.createdAt, now);
      expect(pet.updatedAt, now);
    });

    test('handles missing optional fields gracefully', () {
      final pet = Pet.fromJson(minimalJson());

      expect(pet.id, 'pet-123');
      expect(pet.name, 'Buddy');
      expect(pet.breed, isNull);
      expect(pet.dateOfBirth, isNull);
      expect(pet.photoUrl, isNull);
      expect(pet.weight, isNull);
      expect(pet.colorMarkings, isNull);
      expect(pet.microchipNumber, isNull);
      expect(pet.spayedNeutered, false);
      expect(pet.adoptionDate, isNull);
    });

    test('defaults spayedNeutered to false when missing', () {
      final json = minimalJson();
      // no spayed_neutered key at all
      final pet = Pet.fromJson(json);
      expect(pet.spayedNeutered, false);
    });
  });

  group('Pet.toJson', () {
    test('produces expected map with all fields', () {
      final pet = Pet.fromJson(fullJson());
      final json = pet.toJson();

      expect(json['id'], 'pet-123');
      expect(json['user_id'], 'user-456');
      expect(json['name'], 'Buddy');
      expect(json['species'], 'Dog');
      expect(json['breed'], 'Golden Retriever');
      expect(json['weight'], 30.5);
      expect(json['spayed_neutered'], true);
      expect(json['date_of_birth'], isA<String>());
      expect(json['created_at'], isA<String>());
    });

    test('null optional fields serialize as null', () {
      final pet = Pet.fromJson(minimalJson());
      final json = pet.toJson();

      expect(json['breed'], isNull);
      expect(json['date_of_birth'], isNull);
      expect(json['photo_url'], isNull);
      expect(json['weight'], isNull);
      expect(json['adoption_date'], isNull);
    });
  });

  group('Pet.toJson -> Pet.fromJson round-trip', () {
    test('round-trips with all fields', () {
      final original = Pet.fromJson(fullJson());
      final roundTripped = Pet.fromJson(original.toJson());

      expect(roundTripped.id, original.id);
      expect(roundTripped.name, original.name);
      expect(roundTripped.breed, original.breed);
      expect(roundTripped.weight, original.weight);
      expect(roundTripped.spayedNeutered, original.spayedNeutered);
      expect(roundTripped.dateOfBirth, original.dateOfBirth);
    });
  });

  group('Pet.copyWith', () {
    test('overrides specified fields and keeps others', () {
      final pet = Pet.fromJson(fullJson());
      final updated = pet.copyWith(name: 'Max', weight: 35.0);

      expect(updated.name, 'Max');
      expect(updated.weight, 35.0);
      // unchanged fields
      expect(updated.id, pet.id);
      expect(updated.species, pet.species);
      expect(updated.breed, pet.breed);
    });

    test('returns identical object when no args given', () {
      final pet = Pet.fromJson(fullJson());
      final copy = pet.copyWith();

      expect(copy.id, pet.id);
      expect(copy.name, pet.name);
      expect(copy.weight, pet.weight);
    });
  });

  group('Pet computed properties', () {
    test('ageInYears returns null when dateOfBirth is null', () {
      final pet = Pet.fromJson(minimalJson());
      expect(pet.ageInYears, isNull);
    });

    test('ageDisplay returns Unknown when dateOfBirth is null', () {
      final pet = Pet.fromJson(minimalJson());
      expect(pet.ageDisplay, 'Unknown');
    });
  });
}
