import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/models/pet.dart';
import 'package:pawpal/widgets/pet_progression_avatar.dart';

void main() {
  testWidgets('pet photo frame always fills the requested square', (
    tester,
  ) async {
    final now = DateTime(2026, 8, 5);
    final pet = Pet(
      id: 'pet-1',
      userId: 'user-1',
      name: 'Dobey',
      species: 'Dog',
      gender: 'Unknown',
      createdAt: now,
      updatedAt: now,
    );
    const avatarKey = ValueKey('pet-avatar');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PetProgressionAvatar(
              key: avatarKey,
              pet: pet,
              points: 0,
              size: 140,
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(avatarKey)), const Size.square(140));

    final fill = tester.widget<Positioned>(
      find.descendant(
        of: find.byKey(avatarKey),
        matching: find.byType(Positioned),
      ),
    );
    expect(fill.left, 0);
    expect(fill.top, 0);
    expect(fill.right, 0);
    expect(fill.bottom, 0);

    final photoBounds = tester.getSize(
      find.descendant(
        of: find.byKey(avatarKey),
        matching: find.byType(ClipOval),
      ),
    );
    expect(photoBounds.width, closeTo(photoBounds.height, 0.01));
    expect(photoBounds.width, greaterThan(120));
  });
}
