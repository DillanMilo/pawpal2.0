import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/models/pet.dart';
import 'package:pawpal/providers/activity_provider.dart';
import 'package:pawpal/providers/auth_provider.dart';
import 'package:pawpal/providers/pet_provider.dart';
import 'package:pawpal/screens/activity/log_activity_screen.dart';
import 'package:pawpal/screens/auth/login_screen.dart';
import 'package:pawpal/screens/auth/register_screen.dart';
import 'package:pawpal/utils/theme.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_auth_provider.dart';
import '../helpers/supabase_test_setup.dart';

class _PetProviderWithBean extends PetProvider {
  _PetProviderWithBean(this.bean);

  final Pet bean;

  @override
  List<Pet> get pets => [bean];

  @override
  Pet get selectedPet => bean;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeSupabaseForTesting();
    dotenv.testLoad(
      fileInput: '''
APP_ENABLE_GOOGLE_AUTH=true
APP_ENABLE_APPLE_AUTH=true
''',
    );
  });

  final now = DateTime(2026, 7, 31);
  final bean = Pet(
    id: 'pet-bean',
    userId: 'owner',
    name: 'Bean',
    species: 'Dog',
    gender: 'Unknown',
    createdAt: now,
    updatedAt: now,
  );

  group('PawPal semantic contrast', () {
    // Empty-state hero glyphs, celebration particles, and photo overlays are
    // intentionally decorative; adjacent semantic text carries their meaning.
    test('normal semantic text meets 4.5:1 on its theme surfaces', () {
      const lightSurfaces = [
        AppTheme.backgroundColor,
        AppTheme.surfaceColor,
        AppTheme.cardColor,
      ];
      const lightText = [
        AppTheme.textPrimary,
        AppTheme.textSecondary,
        AppTheme.textLight,
      ];
      const darkSurfaces = [
        AppTheme.darkBackground,
        AppTheme.darkSurface,
        AppTheme.darkCard,
      ];
      const darkText = [
        AppTheme.darkTextPrimary,
        AppTheme.darkTextSecondary,
        AppTheme.darkTextLight,
      ];

      for (final surface in lightSurfaces) {
        for (final foreground in lightText) {
          expect(
            AppTheme.contrastRatio(foreground, surface),
            greaterThanOrEqualTo(4.5),
            reason: '$foreground should be readable on $surface',
          );
        }
      }
      for (final surface in darkSurfaces) {
        for (final foreground in darkText) {
          expect(
            AppTheme.contrastRatio(foreground, surface),
            greaterThanOrEqualTo(4.5),
            reason: '$foreground should be readable on $surface',
          );
        }
      }
    });

    test('activity and action colors choose a 4.5:1 foreground', () {
      final coloredSurfaces = <Color>{
        ...AppTheme.activityColors.values,
        AppTheme.primaryColor,
        AppTheme.actionBlue,
        AppTheme.actionBlueDark,
        AppTheme.accentPeach,
        AppTheme.warningColor,
        AppTheme.errorSnackBackground,
        AppTheme.successSnackBackground,
      };

      for (final surface in coloredSurfaces) {
        expect(
          AppTheme.contrastRatio(AppTheme.foregroundOn(surface), surface),
          greaterThanOrEqualTo(4.5),
          reason: 'selected content should be readable on $surface',
        );
      }
      expect(
        AppTheme.contrastRatio(Colors.white, AppTheme.errorSnackBackground),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        AppTheme.contrastRatio(Colors.white, AppTheme.successSnackBackground),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  for (final isDark in [false, true]) {
    final themeName = isDark ? 'dark' : 'light';
    testWidgets('Log Activity uses readable $themeName activity states', (
      tester,
    ) async {
      final theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PetProvider>.value(
              value: _PetProviderWithBean(bean),
            ),
            ChangeNotifierProvider(create: (_) => ActivityProvider()),
          ],
          child: MaterialApp(
            theme: theme,
            home: LogActivityScreen(initialType: 'Play', pet: bean),
          ),
        ),
      );
      await tester.pump();

      final screenContext = tester.element(find.byType(LogActivityScreen));
      final expectedInactive = AppTheme.primaryText(screenContext);
      for (final label in const [
        'Walk',
        'Train',
        'Feed',
        'Groom',
        'Vet Visit',
        'Social',
        'Rest',
      ]) {
        final finder = find.text(label);
        final text = tester.widget<Text>(finder);
        final color = DefaultTextStyle.of(
          tester.element(finder),
        ).style.merge(text.style).color;
        expect(color, expectedInactive);
      }

      final playFinder = find.text('Play');
      final play = tester.widget<Text>(playFinder);
      final playColor = DefaultTextStyle.of(
        tester.element(playFinder),
      ).style.merge(play.style).color;
      expect(
        playColor,
        AppTheme.foregroundOn(AppTheme.activityColors['Play']!),
      );
      expect(
        AppTheme.contrastRatio(playColor!, AppTheme.activityColors['Play']!),
        greaterThanOrEqualTo(4.5),
      );

      final pointsFinder = find.text("PawPoints you'll earn");
      await tester.scrollUntilVisible(
        pointsFinder,
        320,
        scrollable: find.byType(Scrollable).first,
      );
      final pointsLabel = tester.widget<Text>(pointsFinder);
      expect(pointsLabel.style?.color, AppTheme.secondaryText(screenContext));
      expect(
        find.widgetWithText(ElevatedButton, 'Log Activity'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'auth surfaces render without contrast regressions in $themeName',
      (tester) async {
        final theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
        for (final screen in const [LoginScreen(), RegisterScreen()]) {
          await tester.pumpWidget(
            ChangeNotifierProvider<AuthProvider>.value(
              value: FakeAuthProvider(),
              child: MaterialApp(theme: theme, home: screen),
            ),
          );
          await tester.pump();

          expect(find.byType(Scaffold), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
