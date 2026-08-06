import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/models/pet.dart';
import 'package:pawpal/providers/activity_provider.dart';
import 'package:pawpal/providers/pet_provider.dart';
import 'package:pawpal/screens/activity/log_activity_screen.dart';
import 'package:provider/provider.dart';

import '../helpers/supabase_test_setup.dart';

class _SinglePetProvider extends PetProvider {
  _SinglePetProvider(this.pet);

  final Pet pet;

  @override
  List<Pet> get pets => [pet];

  @override
  Pet get selectedPet => pet;
}

void main() {
  setUpAll(initializeSupabaseForTesting);

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

  Future<void> pumpActivity(WidgetTester tester, String type) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PetProvider>.value(
            value: _SinglePetProvider(pet),
          ),
          ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ],
        child: MaterialApp(
          home: LogActivityScreen(initialType: type, pet: pet),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Play makes logging without a duration obvious', (tester) async {
    await pumpActivity(tester, 'Play');

    await tester.scrollUntilVisible(
      find.byKey(const Key('play-no-duration-help')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.byKey(const Key('play-no-duration-help')), findsOneWidget);
    final noDuration = tester.widget<ChoiceChip>(
      find.byKey(const Key('duration-none')),
    );
    expect(noDuration.selected, isTrue);
    expect(find.byKey(const Key('manual-duration-minutes')), findsNothing);
  });
}
