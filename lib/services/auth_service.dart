import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/user_profile.dart';

class AuthService {
  final _client = SupabaseService.client;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );

    if (response.user != null) {
      // Create user profile
      await _createUserProfile(response.user!.id, email, name);
    }

    return response;
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    final response = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.pawpal://login-callback/',
    );
    return response;
  }

  // Sign in with Apple
  Future<bool> signInWithApple() async {
    final response = await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.pawpal://login-callback/',
    );
    return response;
  }

  // Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // Update password
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return null;

    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  // Update user profile
  Future<UserProfile> updateUserProfile(UserProfile profile) async {
    final data = profile.toJson();
    data['updated_at'] = DateTime.now().toIso8601String();

    final response = await _client
        .from('users')
        .update(data)
        .eq('id', profile.id)
        .select()
        .single();

    return UserProfile.fromJson(response);
  }

  // Create user profile (internal)
  Future<void> _createUserProfile(
    String userId,
    String email,
    String? name,
  ) async {
    final now = DateTime.now().toIso8601String();
    await _client.from('users').insert({
      'id': userId,
      'email': email,
      'name': name,
      'notifications_enabled': true,
      'created_at': now,
      'updated_at': now,
    });
  }

  // Delete account
  Future<void> deleteAccount() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    // Delete user data (cascades will handle related data)
    await _client.from('users').delete().eq('id', userId);
    await signOut();
  }
}
