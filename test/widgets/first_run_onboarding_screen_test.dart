import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/models/user_profile.dart';
import 'package:pawpal/providers/auth_provider.dart';
import 'package:pawpal/providers/pet_provider.dart';
import 'package:pawpal/screens/onboarding/first_run_onboarding_screen.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_auth_provider.dart';
import '../helpers/supabase_test_setup.dart';

void main() {
  setUpAll(initializeSupabaseForTesting);

  UserProfile newProfile() {
    final now = DateTime(2026, 7, 31);
    return UserProfile(
      id: 'user-1',
      email: 'sam@example.com',
      hasSeenPricing: false,
      onboardingCompletedAt: null,
      appTourCompletedAt: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> pumpSetup(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(
            value: FakeAuthProvider(
              status: AuthStatus.authenticated,
              userProfile: newProfile(),
            ),
          ),
          ChangeNotifierProvider(create: (_) => PetProvider()),
        ],
        child: const MaterialApp(home: FirstRunOnboardingScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('collects only required details before optional fields', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpSetup(tester, const Size(390, 844));

    expect(find.text('Let’s get acquainted'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Your preferred name'),
      'Sam',
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Meet your best friend'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.enterText(find.widgetWithText(TextField, 'Pet name'), 'Milo');
    await tester.tap(find.text('Cat'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Add a personal touch'), findsOneWidget);
    expect(find.text('Birthday'), findsOneWidget);
    expect(find.text('Profile photo'), findsOneWidget);
    expect(find.text('Finish setup'), findsOneWidget);
  });

  testWidgets('renders setup without overflow on iPad landscape', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpSetup(tester, const Size(1024, 768));

    expect(find.text('Let’s get acquainted'), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
