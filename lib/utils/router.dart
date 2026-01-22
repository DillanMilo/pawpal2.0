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
import '../screens/activity/activity_history_screen.dart';
import '../screens/quick_actions/quick_actions_screen.dart';
import '../screens/quick_actions/add_medication_screen.dart';
import '../screens/quick_actions/add_vet_visit_screen.dart';
import '../screens/quick_actions/add_grooming_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoading = authProvider.status == AuthStatus.initial;
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/forgot-password';
        final isSplash = state.matchedLocation == '/splash';

        // Show splash while loading
        if (isLoading && !isSplash) {
          return '/splash';
        }

        // Redirect to login if not authenticated
        if (!isAuthenticated && !isAuthRoute && !isSplash && !isLoading) {
          return '/login';
        }

        // Redirect to home if authenticated and on auth route
        if (isAuthenticated && isAuthRoute) {
          return '/home';
        }

        // Redirect from splash once loaded
        if (isSplash && !isLoading) {
          return isAuthenticated ? '/home' : '/login';
        }

        return null;
      },
      routes: [
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

        // Main app shell with bottom navigation
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomeScreen(),
              ),
            ),
            GoRoute(
              path: '/pets',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: PetListScreen(),
              ),
            ),
            GoRoute(
              path: '/calendar',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: CalendarScreen(),
              ),
            ),
            GoRoute(
              path: '/discover',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: DiscoverScreen(),
              ),
            ),
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ProfileScreen(),
              ),
            ),
          ],
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
          builder: (context, state) => const LogActivityScreen(),
        ),

        // Activity history
        GoRoute(
          path: '/activity-history',
          builder: (context, state) => const ActivityHistoryScreen(),
        ),
        GoRoute(
          path: '/pet/:id/activity-history',
          builder: (context, state) {
            final petId = state.pathParameters['id']!;
            return ActivityHistoryScreen(petId: petId);
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
            return PetPassportScreen(petId: petId);
          },
        ),
      ],
    );
  }
}
