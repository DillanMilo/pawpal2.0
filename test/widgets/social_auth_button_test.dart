import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/widgets/social_auth_button.dart';

void main() {
  testWidgets('renders branded Google and Apple actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SocialAuthButton(
                provider: SocialAuthProvider.google,
                onPressed: () {},
              ),
              SocialAuthButton(
                provider: SocialAuthProvider.apple,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.byIcon(Icons.apple), findsOneWidget);
    expect(find.bySemanticsLabel('Google'), findsOneWidget);
  });
}
