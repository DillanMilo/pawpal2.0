import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/pets/pet_list_screen.dart';
import '../screens/pets/pet_detail_screen.dart';
import '../screens/pets/add_pet_screen.dart';
import '../screens/pets/edit_pet_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/discover/discover_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/main_shell.dart';
import '../screens/activity/log_activity_screen.dart';
import '../screens/reminders/reminders_screen.dart';
import '../screens/medical/medical_records_screen.dart';
import '../screens/medical/add_medical_record_screen.dart';
import '../screens/pets/pet_passport_screen.dart';
import '../screens/pets/pet_passport_scanner_screen.dart';
import '../screens/activity/activity_history_screen.dart';
import '../screens/quick_actions/quick_actions_screen.dart';
import '../screens/quick_actions/add_medication_screen.dart';
import '../screens/quick_actions/add_vet_visit_screen.dart';
import '../screens/quick_actions/add_grooming_screen.dart';
import '../screens/services/services_screen.dart';
import '../screens/services/business_listing_screen.dart';
import '../screens/subscription/pricing_screen.dart';
import '../screens/legal/legal_screens.dart';
import '../services/places_service.dart';
import '../models/subscription_feature.dart';
import '../widgets/premium_feature_gate.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  /// Cached router instance, accessible for notification navigation.
  static GoRouter? _instance;
  static GoRouter? get instance => _instance;

  static GoRouter router(AuthProvider authProvider) {
    if (_instance != null) return _instance!;
    _instance = _createRouter(authProvider);
    return _instance!;
  }

  static GoRouter _createRouter(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isResolvingAuth =
            authProvider.status == AuthStatus.initial ||
            authProvider.status == AuthStatus.loading;
        final isAuthRoute =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/forgot-password';
        final isSplash = state.matchedLocation == '/splash';
        final isAuthCallback = state.matchedLocation == '/auth/callback';
        final isPricingOnboarding = state.matchedLocation == '/welcome';
        final isLegalRoute =
            state.matchedLocation == '/privacy' ||
            state.matchedLocation == '/terms' ||
            state.matchedLocation == '/support';

        // Keep OAuth callbacks stable while Supabase recovers the session.
        if (isAuthCallback) {
          if (isResolvingAuth) return null;
          return isAuthenticated ? '/home' : '/login';
        }

        // Redirect to login if not authenticated.
        if (!isAuthenticated &&
            !isAuthRoute &&
            !isLegalRoute &&
            !isSplash &&
            !isResolvingAuth) {
          return '/login';
        }

        // New accounts see transparent pricing and their no-card trial end date
        // before entering the main app. The flag is persisted in Supabase.
        if (isAuthenticated &&
            authProvider.userProfile?.hasSeenPricing == false &&
            !isPricingOnboarding &&
            !isLegalRoute) {
          return '/welcome';
        }

        if (isAuthenticated &&
            authProvider.userProfile?.hasSeenPricing == true &&
            isPricingOnboarding) {
          return '/home';
        }

        // Redirect to home if authenticated and on auth route
        if (isAuthenticated && isAuthRoute) {
          return '/home';
        }

        // Redirect from splash once loaded
        if (isSplash && !isResolvingAuth) {
          return isAuthenticated ? '/home' : '/login';
        }

        return null;
      },
      onException: (context, state, router) {
        // A cached provider tab can still return a legacy fragment callback.
        // Supabase should recover that session instead of showing a false 404.
        router.go(
          isOAuthCallbackUri(state.uri) ? '/auth/callback' : '/not-found',
        );
      },
      routes: [
        // Error / not found route
        GoRoute(
          path: '/not-found',
          builder: (context, state) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Page not found',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Splash screen
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // Auth routes
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/auth/callback',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/privacy',
          builder: (context, state) => const PrivacyPolicyScreen(),
        ),
        GoRoute(
          path: '/terms',
          builder: (context, state) => const TermsOfServiceScreen(),
        ),
        GoRoute(
          path: '/support',
          builder: (context, state) => const SupportScreen(),
        ),
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const PricingScreen(isOnboarding: true),
        ),
        GoRoute(
          path: '/pricing',
          builder: (context, state) => const PricingScreen(),
        ),

        // Main app shell with bottom navigation
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: HomeScreen()),
            ),
            GoRoute(
              path: '/services',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ServicesScreen()),
            ),
            GoRoute(
              path: '/pets',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: PetListScreen()),
            ),
            GoRoute(
              path: '/calendar',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: CalendarScreen()),
            ),
            GoRoute(
              path: '/discover',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: DiscoverScreen()),
            ),
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ProfileScreen()),
            ),
          ],
        ),

        // Services business listing (outside shell for full-screen)
        GoRoute(
          path: '/services/listing',
          builder: (context, state) {
            final serviceType = state.extra as ServiceType;
            return BusinessListingScreen(serviceType: serviceType);
          },
        ),

        // Pet routes (outside shell for full-screen)
        GoRoute(
          path: '/pet/:id',
          builder: (context, state) {
            final petId = state.pathParameters['id']!;
            return PetDetailScreen(petId: petId);
          },
        ),
        GoRoute(
          path: '/add-pet',
          builder: (context, state) => const AddPetScreen(),
        ),
        GoRoute(
          path: '/edit-pet/:id',
          builder: (context, state) {
            final petId = state.pathParameters['id']!;
            return EditPetScreen(petId: petId);
          },
        ),

        // Quick actions menu
        GoRoute(
          path: '/quick-actions',
          builder: (context, state) => const QuickActionsScreen(),
        ),

        // Quick action sub-screens
        GoRoute(
          path: '/add-medication',
          builder: (context, state) => const AddMedicationScreen(),
        ),
        GoRoute(
          path: '/add-vet-visit',
          builder: (context, state) => const AddVetVisitScreen(),
        ),
        GoRoute(
          path: '/add-grooming',
          builder: (context, state) => const AddGroomingScreen(),
        ),

        // Activity logging
        GoRoute(
          path: '/log-activity',
          builder: (context, state) {
            final extra = state.extra;
            return LogActivityScreen(
              initialType: extra is String ? extra : null,
            );
          },
        ),

        // Activity history
        GoRoute(
          path: '/activity-history',
          builder: (context, state) => const PremiumFeatureGate(
            feature: SubscriptionFeature.activityInsights,
            child: ActivityHistoryScreen(),
          ),
        ),
        GoRoute(
          path: '/pet/:id/activity-history',
          builder: (context, state) {
            final petId = state.pathParameters['id']!;
            return PremiumFeatureGate(
              feature: SubscriptionFeature.activityInsights,
              child: ActivityHistoryScreen(petId: petId),
            );
          },
        ),

        // Reminders
        GoRoute(
          path: '/reminders',
          builder: (context, state) => const RemindersScreen(),
        ),

        // Medical records
        GoRoute(
          path: '/pet/:id/medical',
          builder: (context, state) {
            final petId = state.pathParameters['id']!;
            return MedicalRecordsScreen(petId: petId);
          },
        ),
        GoRoute(
          path: '/pet/:id/medical/add',
          builder: (context, state) {
            final petId = state.pathParameters['id']!;
            return AddMedicalRecordScreen(petId: petId);
          },
        ),

        // Pet Passport
        GoRoute(
          path: '/pet/:id/passport',
          builder: (context, state) {
            final petId = state.pathParameters['id']!;
            return PremiumFeatureGate(
              feature: SubscriptionFeature.passportSharing,
              child: PetPassportScreen(petId: petId),
            );
          },
        ),
        GoRoute(
          path: '/scan-passport',
          builder: (context, state) => const PremiumFeatureGate(
            feature: SubscriptionFeature.passportSharing,
            child: PetPassportScannerScreen(),
          ),
        ),
      ],
    );
  }

  static bool isOAuthCallbackUri(Uri uri) {
    if (uri.path == '/auth/callback') return true;

    final callbackValues = <String>[
      uri.toString(),
      uri.fragment,
      uri.path,
    ].join('&');

    return callbackValues.contains('code=') ||
        callbackValues.contains('access_token=') ||
        callbackValues.contains('refresh_token=') ||
        callbackValues.contains('error_description=');
  }
}
