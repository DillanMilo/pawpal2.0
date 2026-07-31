import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/screens/auth/login_screen.dart';
import 'package:pawpal/screens/auth/register_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  const screenSize = Size(390, 844);
  const safeBottom = 34.0;

  setUpAll(() {
    dotenv.testLoad(
      fileInput: '''
APP_ENABLE_GOOGLE_AUTH=true
APP_ENABLE_APPLE_AUTH=true
''',
    );
  });

  Widget iphoneViewport(Widget child) => MediaQuery(
    data: const MediaQueryData(
      size: screenSize,
      padding: EdgeInsets.only(top: 47, bottom: safeBottom),
    ),
    child: child,
  );

  Future<void> pumpAtIphoneSize(WidgetTester tester, Widget child) async {
    await tester.binding.setSurfaceSize(screenSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(createTestWidget(iphoneViewport(child)));
    await tester.pumpAndSettle();
  }

  double outerScrollExtent(WidgetTester tester) {
    final scrollable = find.descendant(
      of: find.byType(SingleChildScrollView),
      matching: find.byType(Scrollable),
    );
    return tester
        .state<ScrollableState>(scrollable.first)
        .position
        .maxScrollExtent;
  }

  testWidgets('sign in fits a standard iPhone safe area without scrolling', (
    tester,
  ) async {
    await pumpAtIphoneSize(tester, const LoginScreen());

    expect(outerScrollExtent(tester), 0);
    expect(find.text('Log In'), findsOneWidget);
    expect(
      tester.getBottomRight(find.text('Support')).dy,
      lessThanOrEqualTo(screenSize.height - safeBottom),
    );
  });

  testWidgets('sign up and PawPoints teaser fit without scrolling', (
    tester,
  ) async {
    await pumpAtIphoneSize(tester, const RegisterScreen());

    expect(outerScrollExtent(tester), 0);
    expect(find.textContaining('Care earns PawPoints'), findsOneWidget);
    expect(find.text('Sign Up Free'), findsOneWidget);
    expect(
      tester.getBottomRight(find.text('Sign In')).dy,
      lessThanOrEqualTo(screenSize.height - safeBottom),
    );
  });
}
