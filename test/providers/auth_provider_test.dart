import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/providers/auth_provider.dart';

/// AuthProvider cannot be instantiated without Supabase initialized
/// because its constructor calls _init() which accesses SupabaseService.
/// These tests cover the AuthStatus enum and document expected behavior.
/// For full AuthProvider tests, use integration tests with Supabase running.

void main() {
  group('AuthStatus enum', () {
    test('has all expected values', () {
      expect(AuthStatus.values, containsAll([
        AuthStatus.initial,
        AuthStatus.authenticated,
        AuthStatus.unauthenticated,
        AuthStatus.loading,
      ]));
    });

    test('has exactly 4 values', () {
      expect(AuthStatus.values.length, equals(4));
    });

    test('initial is the first value', () {
      expect(AuthStatus.values.first, equals(AuthStatus.initial));
    });
  });
}
