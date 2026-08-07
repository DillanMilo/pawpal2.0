import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pawpal/models/pet.dart';
import 'package:pawpal/models/user_profile.dart';
import 'package:pawpal/providers/activity_provider.dart';
import 'package:pawpal/providers/auth_provider.dart';
import 'package:pawpal/providers/pet_provider.dart';
import 'package:pawpal/screens/home/home_screen.dart';
import 'package:pawpal/screens/pets/pet_detail_screen.dart';
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

  @override
  Future<void> loadPets({bool forceRefresh = false}) async {}

  @override
  Future<Pet?> getPet(String petId) async => petId == bean.id ? bean : null;
}

class _QuietActivityProvider extends ActivityProvider {
  @override
  Future<void> loadActivities(
    String petId, {
    int? limit,
    bool forceRefresh = false,
  }) async {}

  @override
  Future<void> loadStats({bool forceRefresh = false}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeSupabaseForTesting);

  final now = DateTime(2026, 8, 5);
  final bean = Pet(
    id: 'pet-bean',
    userId: 'owner',
    name: 'Bean',
    species: 'Cat',
    gender: 'Unknown',
    createdAt: now,
    updatedAt: now,
  );

  testWidgets('tapping a home pet card opens that pet profile', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/pet/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Profile ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: FakeAuthProvider()),
          ChangeNotifierProvider<PetProvider>.value(
            value: _PetProviderWithBean(bean),
          ),
          ChangeNotifierProvider<ActivityProvider>.value(
            value: _QuietActivityProvider(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.byKey(const Key('home-pet-card-pet-bean')));
    await tester.pumpAndSettle();

    expect(find.text('Profile pet-bean'), findsOneWidget);
  });

  testWidgets('profile rewards has a back button and a dark progression card', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: FakeAuthProvider()),
          ChangeNotifierProvider<PetProvider>.value(
            value: _PetProviderWithBean(bean),
          ),
          ChangeNotifierProvider<ActivityProvider>.value(
            value: _QuietActivityProvider(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: PetDetailScreen(petId: bean.id),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    final card = tester.widget<Container>(
      find.byKey(const Key('pet-progression-card')),
    );
    final decoration = card.decoration! as BoxDecoration;
    expect(decoration.gradient, AppTheme.darkProgressionGradient);

    final title = tester.widget<Text>(find.text("Bean's PawPoints"));
    for (final background in AppTheme.darkProgressionGradient.colors) {
      expect(
        AppTheme.contrastRatio(title.style!.color!, background),
        greaterThanOrEqualTo(4.5),
      );
    }

    final chooseRewards = find.text('Choose profile rewards');
    await tester.drag(find.byType(ListView).first, const Offset(0, -360));
    await tester.pump(const Duration(milliseconds: 300));
    expect(chooseRewards, findsOneWidget);
    await tester.tap(chooseRewards);
    await tester.pump(const Duration(milliseconds: 500));

    final backButton = find.byKey(const Key('close-profile-rewards'));
    expect(backButton, findsOneWidget);
    tester.widget<IconButton>(backButton).onPressed!();
    await tester.pump(const Duration(milliseconds: 500));
    expect(backButton, findsNothing);
  });

  testWidgets('pet profile explains care, health, and the shareable ID once', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final profile = UserProfile(
      id: 'owner',
      email: 'owner@example.com',
      onboardingCompletedAt: now,
      appTourCompletedAt: now,
      quickActionsTourCompletedAt: now,
      petProfileTourCompletedAt: null,
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(
            value: FakeAuthProvider(
              status: AuthStatus.authenticated,
              userProfile: profile,
            ),
          ),
          ChangeNotifierProvider<PetProvider>.value(
            value: _PetProviderWithBean(bean),
          ),
          ChangeNotifierProvider<ActivityProvider>.value(
            value: _QuietActivityProvider(),
          ),
        ],
        child: MaterialApp(home: PetDetailScreen(petId: bean.id)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Their care hub'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Health at a glance'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('A shareable Pet Passport'), findsOneWidget);

    await tester.tap(find.text('Finish'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('A shareable Pet Passport'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
