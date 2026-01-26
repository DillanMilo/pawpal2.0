class AppConstants {
  // Supabase Configuration
  static const String supabaseUrl = 'https://esrxaniydzgzxxxwzqca.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVzcnhhbml5ZHpnenh4eHd6cWNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkxMDI1MzYsImV4cCI6MjA4NDY3ODUzNn0.3m4ZCG6GFnWcMngc9AcvWkntbHBe8xI4lgjT5oDyc0s';

  // Google Places API Configuration
  static const String googlePlacesApiKey = 'AIzaSyCBwMxlKn2RNctCLVm1A7W-rUa0ZvsFRFg';

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
