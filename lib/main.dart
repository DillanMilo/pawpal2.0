import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/pet_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/subscription_provider.dart';
import 'utils/theme.dart';
import 'utils/router.dart';
import 'utils/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();

  // Show user-friendly error widget instead of red screen in release mode
  if (kReleaseMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return const Material(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    };
  }

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize Notifications
  await NotificationService().initialize();

  runApp(const PawPalApp());
}

class PawPalApp extends StatelessWidget {
  const PawPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PetProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider<AuthProvider, SubscriptionProvider>(
          create: (_) => SubscriptionProvider(),
          update: (_, auth, subscription) {
            final value = subscription ?? SubscriptionProvider();
            value.updateUser(
              auth.isAuthenticated ? auth.userProfile?.id : null,
            );
            return value;
          },
        ),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, _) {
          return MaterialApp.router(
            title: 'PawPal',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            builder: (context, child) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              SystemChrome.setSystemUIOverlayStyle(
                SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: isDark
                      ? Brightness.light
                      : Brightness.dark,
                  systemNavigationBarColor: isDark
                      ? AppTheme.darkBackground
                      : Colors.white,
                  systemNavigationBarIconBrightness: isDark
                      ? Brightness.light
                      : Brightness.dark,
                ),
              );
              return child ?? const SizedBox.shrink();
            },
            routerConfig: AppRouter.router(authProvider),
          );
        },
      ),
    );
  }
}
