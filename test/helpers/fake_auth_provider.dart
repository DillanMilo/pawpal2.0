import 'package:flutter/foundation.dart';
import 'package:pawpal/models/user_profile.dart';
import 'package:pawpal/providers/auth_provider.dart';

/// A fake AuthProvider that does not touch Supabase.
/// Used in widget tests to satisfy the provider dependency.
///
/// Dart allows `implements` on concrete classes. This gives us an AuthProvider
/// that the Provider widget tree accepts via `ChangeNotifierProvider<AuthProvider>`
/// without ever initializing Supabase.
class FakeAuthProvider with ChangeNotifier implements AuthProvider {
  AuthStatus _status = AuthStatus.unauthenticated;
  String? _error;

  @override
  AuthStatus get status => _status;

  @override
  String? get error => _error;

  @override
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  @override
  bool get isLoading => _status == AuthStatus.loading;

  @override
  UserProfile? get userProfile => null;

  @override
  Future<bool> signIn({required String email, required String password}) async {
    return false;
  }

  @override
  Future<bool> signUp({required String email, required String password, String? name}) async {
    return false;
  }

  @override
  Future<bool> signInWithGoogle() async => false;

  @override
  Future<bool> signInWithApple() async => false;

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> resetPassword(String email) async => false;

  @override
  Future<bool> updateProfile(UserProfile profile) async => false;

  @override
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
