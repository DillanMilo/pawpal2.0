// PawPal Smoke Test
//
// Note: The full PawPalApp requires Supabase initialization which is not
// available in the test environment. This smoke test verifies that the
// individual screens can be instantiated when wrapped with test providers.

import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/screens/auth/login_screen.dart';
import 'package:pawpal/screens/auth/register_screen.dart';
import 'helpers/test_helpers.dart';

void main() {
  testWidgets('LoginScreen can be instantiated and rendered', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWidget(const LoginScreen()));
    await tester.pumpAndSettle();
    expect(
      find.text('Track your pet\'s care,\nhealth, and daily routine'),
      findsOneWidget,
    );
  });

  testWidgets('RegisterScreen can be instantiated and rendered', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWidget(const RegisterScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsAtLeastNWidgets(1));
  });
}
