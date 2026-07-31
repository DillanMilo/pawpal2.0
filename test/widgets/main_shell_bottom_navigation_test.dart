import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pawpal/providers/auth_provider.dart';
import 'package:pawpal/screens/main_shell.dart';
import 'package:pawpal/utils/theme.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_auth_provider.dart';

void main() {
  testWidgets(
    'bottom navigation paints through the safe inset while controls stay above it',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const MediaQuery(
              data: MediaQueryData(
                size: Size(390, 844),
                padding: EdgeInsets.only(bottom: 34),
              ),
              child: MainShell(
                replayTour: true,
                child: ColoredBox(color: Colors.green),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: FakeAuthProvider(),
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();

      final background = find.byKey(
        const Key('bottom-navigation-safe-background'),
      );
      expect(background, findsOneWidget);
      expect(tester.getBottomLeft(background).dy, 844);
      expect(tester.getSize(background).height, 70);

      final coloredBox = tester.widget<ColoredBox>(
        find.descendant(of: background, matching: find.byType(ColoredBox)),
      );
      expect(coloredBox.color, AppTheme.surfaceColor);

      final homeTab = find.text('Home');
      expect(homeTab, findsOneWidget);
      expect(tester.getBottomRight(homeTab).dy, lessThanOrEqualTo(810));

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
