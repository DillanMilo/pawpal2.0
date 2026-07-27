import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/screens/auth/register_screen.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('RegisterScreen', () {
    testWidgets('renders all form fields and free signup button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Sign Up Free'), findsOneWidget);
    });

    testWidgets('password mismatch shows error', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      // Fill in all fields with mismatched passwords
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        'John Doe',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'john@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'different123',
      );

      // Tap Create Account
      // Use the ElevatedButton finder to be precise
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('short password shows validation error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      // Fill in fields with a short password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        'John Doe',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'john@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'short',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'short',
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 8 characters'),
        findsOneWidget,
      );
    });

    testWidgets('empty fields show validation errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      // Tap Create Account without filling anything
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
    });
  });
}
