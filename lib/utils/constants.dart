import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Supabase Configuration (loaded from .env)
  static String get supabaseUrl => _env('SUPABASE_URL');
  static String get supabaseAnonKey => _env('SUPABASE_ANON_KEY');

  // Optional auth providers. Keep disabled until configured in Supabase.
  static bool get enableGoogleAuth => _envBool('APP_ENABLE_GOOGLE_AUTH');
  static bool get enableAppleAuth => _envBool('APP_ENABLE_APPLE_AUTH');

  /// Apple review requires Sign in with Apple when another third-party login
  /// is offered. Fail closed on Apple platforms if Apple auth is not ready.
  static bool get enableGoogleAuthForCurrentPlatform =>
      enableGoogleAuth && (!_isApplePlatform || enableAppleAuth);
  static bool get enableAppleAuthForCurrentPlatform => enableAppleAuth;
  static bool get _isApplePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  // Billing remains behind a release flag until all store products and the
  // RevenueCat webhook have been verified in sandbox environments.
  static bool get enableBilling => _envBool('APP_ENABLE_BILLING');
  static String get revenueCatApiKey {
    if (kIsWeb) return _env('REVENUECAT_WEB_API_KEY');
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS ||
      TargetPlatform.macOS => _env('REVENUECAT_IOS_API_KEY'),
      TargetPlatform.android => _env('REVENUECAT_ANDROID_API_KEY'),
      _ => '',
    };
  }

  static String _env(String key, [String fallback = '']) {
    try {
      return dotenv.env[key] ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  static bool _envBool(String key) =>
      _env(key, 'false').toLowerCase() == 'true';

  // App Info
  static const String appName = 'PawPal';
  static const String appVersion = '1.0.0';

  // Subscription catalog. Store/RevenueCat prices are authoritative once
  // billing is enabled; these values are the marketing fallback shown before
  // the remote offering has loaded.
  static const String plusEntitlementId = 'pawpal_plus';
  static const String plusOfferingId = 'default';
  static const String monthlyProductId = 'pawpal_plus_monthly';
  static const String annualProductId = 'pawpal_plus_annual';
  static const String monthlyDisplayPrice = r'$4.99';
  static const String annualDisplayPrice = r'$29.99';
  static const int trialDays = 14;
  static const int freePetLimit = 1;
  static const int freeActiveReminderLimit = 5;
  static const int freeMedicalRecordLimit = 20;

  // Storage Buckets
  static const String profilePhotosBucket = 'profile-photos';
  static const String petPhotosBucket = 'pet-photos';
  static const String medicalDocsBucket = 'medical-documents';
  static const String activityPhotosBucket = 'activity-photos';

  // Pet Species
  static const List<String> petSpecies = [
    'Dog',
    'Cat',
    'Bird',
    'Fish',
    'Rabbit',
    'Hamster',
    'Guinea Pig',
    'Reptile',
    'Other',
  ];

  // Activity Types
  static const List<String> activityTypes = [
    'Walk',
    'Play',
    'Train',
    'Feed',
    'Groom',
    'Vet Visit',
    'Social',
    'Rest',
  ];

  // Activity Points
  static const Map<String, int> activityPoints = {
    'Walk': 10,
    'Play': 8,
    'Train': 15,
    'Feed': 5,
    'Groom': 7,
    'Vet Visit': 20,
    'Social': 12,
    'Rest': 3,
  };

  // Badge Thresholds
  static const Map<String, int> badgeThresholds = {
    'first_walk': 1,
    'week_warrior': 7,
    'training_pro': 10,
    'social_butterfly': 5,
    'health_champion': 1, // All vaccinations up to date
    'consistent_caregiver': 30,
  };

  // Reminder Types
  static const List<String> reminderTypes = [
    'Medication',
    'Vaccination',
    'Appointment',
    'Grooming',
    'Custom',
  ];

  // Appointment Types
  static const List<String> appointmentTypes = [
    'Vet',
    'Grooming',
    'Training',
    'Other',
  ];

  // Provider Types
  static const List<String> providerTypes = [
    'Veterinarian',
    'Groomer',
    'Pet Store',
    'Pet Sitter',
  ];
}
