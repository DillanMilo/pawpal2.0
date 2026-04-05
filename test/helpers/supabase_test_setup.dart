import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initializes Supabase with dummy values for testing.
/// Call this in setUpAll() for tests that instantiate providers
/// which depend on SupabaseService.
Future<void> initializeSupabaseForTesting() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  try {
    // Only initialize once across all tests
    Supabase.instance;
  } catch (_) {
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJ0ZXN0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDAwMDAwMDAsImV4cCI6MjAwMDAwMDAwMH0.test',
    );
  }
}
