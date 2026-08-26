import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/providers/subscription_provider.dart';
import 'package:pawpal/screens/reminders/reminders_screen.dart';
import 'package:pawpal/screens/services/services_screen.dart';
import 'package:provider/provider.dart';

import '../helpers/supabase_test_setup.dart';

void main() {
  setUpAll(initializeSupabaseForTesting);

  testWidgets('services includes boarding and daycare discovery', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ServicesScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Boarding & Daycare'), findsOneWidget);
    expect(find.text('Kennels, pet hotels & daytime care'), findsOneWidget);
  });

  testWidgets('preventive-care presets fill the existing reminder form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SubscriptionProvider(),
        child: const MaterialApp(home: RemindersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add reminder').first);
    await tester.pumpAndSettle();

    expect(find.text('Quick care presets'), findsOneWidget);
    expect(find.text('Tick & flea prevention'), findsOneWidget);
    expect(find.text('Vaccination or booster'), findsOneWidget);
    expect(find.text('Medication refill'), findsOneWidget);
    expect(find.text('Medication expiration'), findsOneWidget);
    expect(find.text('Deworming'), findsOneWidget);

    await tester.tap(find.text('Medication refill'));
    await tester.pump();

    final title = tester.widget<TextField>(find.byType(TextField).first);
    expect(title.controller?.text, 'Medication refill');
    final type = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>).first,
    );
    expect(type.initialValue, 'Medication Refill');
    expect(tester.takeException(), isNull);
  });
}
