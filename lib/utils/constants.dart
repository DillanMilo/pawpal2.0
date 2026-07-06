import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Supabase Configuration (loaded from .env)
  static String get supabaseUrl => _env('SUPABASE_URL');
  static String get supabaseAnonKey => _env('SUPABASE_ANON_KEY');

  // Optional auth providers. Keep disabled until configured in Supabase.
  static bool get enableGoogleAuth => _envBool('APP_ENABLE_GOOGLE_AUTH');
  static bool get enableAppleAuth => _envBool('APP_ENABLE_APPLE_AUTH');

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
