import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/models/medical_record.dart';
import 'package:pawpal/models/pet.dart';
import 'package:pawpal/providers/pet_provider.dart';
import 'package:pawpal/screens/quick_actions/add_grooming_screen.dart';
import 'package:pawpal/services/medical_service.dart';
import 'package:provider/provider.dart';

import '../helpers/supabase_test_setup.dart';

class _PetProviderWithPet extends PetProvider {
  _PetProviderWithPet(this.pet);

  final Pet pet;

  @override
  List<Pet> get pets => [pet];

  @override
  Pet get selectedPet => pet;
}

class _RecordingMedicalService extends MedicalService {
  MedicalRecord? saved;

  @override
  Future<MedicalRecord> createMedicalRecord(MedicalRecord record) async {
    saved = record;
    return record.copyWith(id: 'saved-record');
  }
}

void main() {
  setUpAll(initializeSupabaseForTesting);

  testWidgets('grooming defaults to home and saves activity-specific data', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime(2026, 8, 5);
    final pet = Pet(
      id: 'pet-1',
      userId: 'user-1',
      name: 'Bean',
      species: 'Cat',
      gender: 'Unknown',
      createdAt: now,
      updatedAt: now,
    );
    final service = _RecordingMedicalService();

    await tester.pumpWidget(
      ChangeNotifierProvider<PetProvider>.value(
        value: _PetProviderWithPet(pet),
        child: MaterialApp(home: AddGroomingScreen(medicalService: service)),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('grooming-location')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('grooming-location')), findsOneWidget);
    expect(find.text('At home'), findsOneWidget);
    expect(find.text('Groomer or salon name (optional)'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Save Grooming'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save Grooming'));
    await tester.pump();

    expect(service.saved, isNotNull);
    expect(service.saved!.petId, 'pet-1');
    expect(service.saved!.type, MedicalRecordType.groomingVisit);
    expect(service.saved!.provider, 'Home');
    expect(service.saved!.metadata!['location'], 'home');
    expect(service.saved!.metadata!['services'], contains('Bath'));
  });
}
