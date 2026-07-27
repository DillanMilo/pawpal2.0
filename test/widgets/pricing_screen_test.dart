import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/providers/auth_provider.dart';
import 'package:pawpal/providers/subscription_provider.dart';
import 'package:pawpal/screens/subscription/pricing_screen.dart';
import 'package:pawpal/utils/theme.dart';
import 'package:provider/provider.dart';
import '../helpers/fake_auth_provider.dart';

void main() {
  testWidgets('shows transparent no-card trial and both launch prices', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => FakeAuthProvider(),
          ),
          ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PricingScreen(isOnboarding: true),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Welcome to PawPal'), findsOneWidget);
    expect(find.textContaining('No payment is required'), findsOneWidget);
    expect(find.text(r'$29.99'), findsOneWidget);
    expect(find.text(r'$4.99'), findsOneWidget);
    expect(find.text('PawPal Base'), findsOneWidget);
    expect(find.text('PawPal Plus'), findsOneWidget);
    expect(find.text('Recurring care reminders'), findsOneWidget);
    expect(find.text('Continue with my free trial'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
