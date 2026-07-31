import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/screens/home/home_backdrop.dart';
import 'package:pawpal/utils/theme.dart';

void main() {
  testWidgets('home backdrop renders its pattern in light and dark themes', (
    tester,
  ) async {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: HomeBackdrop(child: Text('Dashboard content')),
          ),
        ),
      );

      expect(find.text('Dashboard content'), findsOneWidget);
      expect(find.byKey(const Key('home-background-pattern')), findsOneWidget);
    }
  });
}
