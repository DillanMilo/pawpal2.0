import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/screens/legal/legal_screens.dart';

void main() {
  testWidgets('privacy policy explains collection and account control', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));

    expect(find.text('Privacy Policy'), findsWidgets);
    expect(find.text('What PawPal collects'), findsOneWidget);
    expect(find.text('Retention and control'), findsOneWidget);
  });

  testWidgets('terms include veterinary disclaimer', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TermsOfServiceScreen()));

    expect(find.text('Terms of Service'), findsWidgets);
    expect(find.text('Not veterinary advice'), findsOneWidget);
  });

  testWidgets('support page exposes an email action', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SupportScreen()));

    expect(find.text('PawPal Support'), findsWidgets);
    expect(find.text('Email support'), findsOneWidget);
  });
}
