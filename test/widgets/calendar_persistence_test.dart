import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/models/appointment.dart';
import 'package:pawpal/models/pet.dart';
import 'package:pawpal/screens/calendar/calendar_screen.dart';
import 'package:pawpal/services/appointment_service.dart';
import 'package:pawpal/services/pet_service.dart';

import '../helpers/supabase_test_setup.dart';

class _RecordingAppointmentService extends AppointmentService {
  final List<Appointment> appointments = [];

  @override
  Future<List<Appointment>> getAppointments() async => appointments;

  @override
  Future<Appointment> createAppointment(Appointment appointment) async {
    final saved = appointment.copyWith(id: 'appointment-1', userId: 'user-1');
    appointments.add(saved);
    return saved;
  }
}

class _SinglePetService extends PetService {
  _SinglePetService(this.pet);

  final Pet pet;

  @override
  Future<List<Pet>> getPets() async => [pet];
}

void main() {
  setUpAll(initializeSupabaseForTesting);

  testWidgets('calendar appointment form saves and reloads the entry', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.now();
    final pet = Pet(
      id: 'pet-1',
      userId: 'user-1',
      name: 'Bean',
      species: 'Cat',
      gender: 'Unknown',
      createdAt: now,
      updatedAt: now,
    );
    final appointmentService = _RecordingAppointmentService();

    await tester.pumpWidget(
      MaterialApp(
        home: CalendarScreen(
          appointmentService: appointmentService,
          petService: _SinglePetService(pet),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add appointment').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Annual checkup');
    await tester.tap(find.text('Save Appointment'));
    await tester.pumpAndSettle();

    expect(appointmentService.appointments, hasLength(1));
    expect(appointmentService.appointments.single.title, 'Annual checkup');
    expect(appointmentService.appointments.single.type, 'Vet');
    expect(find.text('Annual checkup'), findsOneWidget);
  });
}
