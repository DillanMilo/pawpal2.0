import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/providers/pet_provider.dart';
import 'package:pawpal/models/pet.dart';
import '../helpers/supabase_test_setup.dart';

void main() {
  late PetProvider provider;

  setUpAll(() async {
    await initializeSupabaseForTesting();
  });

  setUp(() {
    provider = PetProvider();
  });

  group('PetProvider initial state', () {
    test('pets list is empty', () {
      expect(provider.pets, isEmpty);
    });

    test('selectedPet is null', () {
      expect(provider.selectedPet, isNull);
    });

    test('isLoading is false', () {
      expect(provider.isLoading, isFalse);
    });

    test('error is null', () {
      expect(provider.error, isNull);
    });

    test('hasPets is false', () {
      expect(provider.hasPets, isFalse);
    });
  });

  group('selectPet', () {
    test('sets the selected pet', () {
      final pet = Pet(
        id: 'pet-1',
        userId: 'user-1',
        name: 'Buddy',
        species: 'Dog',
        gender: 'Male',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      provider.selectPet(pet);

      expect(provider.selectedPet, equals(pet));
      expect(provider.selectedPet!.name, equals('Buddy'));
    });

    test('updates when called with a different pet', () {
      final pet1 = Pet(
        id: 'pet-1',
        userId: 'user-1',
        name: 'Buddy',
        species: 'Dog',
        gender: 'Male',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final pet2 = Pet(
        id: 'pet-2',
        userId: 'user-1',
        name: 'Luna',
        species: 'Cat',
        gender: 'Female',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      provider.selectPet(pet1);
      expect(provider.selectedPet!.name, equals('Buddy'));

      provider.selectPet(pet2);
      expect(provider.selectedPet!.name, equals('Luna'));
      expect(provider.selectedPet!.id, equals('pet-2'));
    });

    test('notifies listeners', () {
      final pet = Pet(
        id: 'pet-1',
        userId: 'user-1',
        name: 'Buddy',
        species: 'Dog',
        gender: 'Male',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      var notified = false;
      provider.addListener(() => notified = true);

      provider.selectPet(pet);

      expect(notified, isTrue);
    });
  });

  group('clearError', () {
    test('notifies listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.clearError();

      expect(notified, isTrue);
      expect(provider.error, isNull);
    });
  });

  group('reset', () {
    test('clears all state back to initial values', () {
      final pet = Pet(
        id: 'pet-1',
        userId: 'user-1',
        name: 'Buddy',
        species: 'Dog',
        gender: 'Male',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      // Set some state first
      provider.selectPet(pet);
      expect(provider.selectedPet, isNotNull);

      // Reset
      provider.reset();

      expect(provider.pets, isEmpty);
      expect(provider.selectedPet, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.hasPets, isFalse);
    });

    test('notifies listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.reset();

      expect(notified, isTrue);
    });
  });
}
