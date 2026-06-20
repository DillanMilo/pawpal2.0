import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/widgets/pet_date_picker.dart';

void main() {
  testWidgets('pet date picker opens on narrow mobile screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: SizedBox(
                  width: 288,
                  child: PetDateField(
                    labelText: 'Date of Birth',
                    emptyText: 'Select date',
                    icon: Icons.cake,
                    selectedDate: null,
                    onTap: () {
                      showPetDatePicker(
                        context: context,
                        title: 'Date of Birth',
                        selectedDate: null,
                        firstDate: DateTime(1990),
                        lastDate: DateTime(2026, 6, 20),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Select date'));
    await tester.pumpAndSettle();

    expect(find.text('Date of Birth'), findsWidgets);
    expect(find.text('Done'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
