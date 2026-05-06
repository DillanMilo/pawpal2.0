import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'supabase_service.dart';
import '../models/user_profile.dart';
import '../utils/constants.dart';

class AuthService {
  final _client = SupabaseService.client;
  final _uuid = const Uuid();

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
      redirectTo: _oauthRedirectUrl,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
    return response;
  }

  // Sign in with Apple
  Future<bool> signInWithApple() async {
    final response = await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: _oauthRedirectUrl,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
    return response;
  }

  String get _oauthRedirectUrl {
    if (kIsWeb) {
      return Uri(
        scheme: Uri.base.scheme,
        host: Uri.base.host,
        port: Uri.base.hasPort ? Uri.base.port : null,
        path: '/auth/callback',
      ).toString();
    }

    return 'com.creativecurrents.pawpal://login-callback/';
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
    return await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // Re-authenticate with the current password, then update to a new password.
  Future<UserResponse> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = SupabaseService.currentUser?.email;
    if (email == null) {
      throw const AuthException('No signed-in email account found.');
    }

    await _client.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );
    return updatePassword(newPassword);
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

  // Ensure the profile exists for accounts created before the DB trigger was present.
  Future<UserProfile?> ensureCurrentUserProfile() async {
    final user = SupabaseService.currentUser;
    if (user == null || user.email == null) return null;

    final existing = await getCurrentUserProfile();
    if (existing != null) return existing;

    final metadataName = user.userMetadata?['name'] as String?;
    await _upsertUserProfile(user.id, user.email!, metadataName);
    return getCurrentUserProfile();
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

  // Upload a profile photo and return the public URL.
  Future<String> uploadProfilePhoto(XFile photo, {String? previousUrl}) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final extension = _extensionFor(
      photo.name.isNotEmpty ? photo.name : photo.path,
    );
    final path = '$userId/${_uuid.v4()}.$extension';
    final bytes = await photo.readAsBytes();

    await _client.storage
        .from(AppConstants.profilePhotosBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _contentTypeFor(extension),
            upsert: false,
          ),
        );

    if (previousUrl != null && previousUrl.isNotEmpty) {
      await _deleteProfilePhoto(previousUrl);
    }

    return _client.storage
        .from(AppConstants.profilePhotosBucket)
        .getPublicUrl(path);
  }

  // Create or repair user profile (internal)
  Future<void> _upsertUserProfile(
    String userId,
    String email,
    String? name,
  ) async {
    final now = DateTime.now().toIso8601String();
    await _client.from('users').upsert({
      'id': userId,
      'email': email,
      'name': name,
      'notifications_enabled': true,
      'updated_at': now,
    }, onConflict: 'id');
  }

  Future<void> _deleteProfilePhoto(String url) async {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(
        AppConstants.profilePhotosBucket,
      );
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final path = pathSegments.sublist(bucketIndex + 1).join('/');
        await _client.storage.from(AppConstants.profilePhotosBucket).remove([
          path,
        ]);
      }
    } catch (_) {
      // Profile updates should not fail because cleanup of an old image failed.
    }
  }

  String _extensionFor(String fileName) {
    final rawExtension = fileName.split('.').last.toLowerCase();
    if (rawExtension == 'jpg' ||
        rawExtension == 'jpeg' ||
        rawExtension == 'png' ||
        rawExtension == 'webp') {
      return rawExtension == 'jpg' ? 'jpeg' : rawExtension;
    }
    return 'jpeg';
  }

  String _contentTypeFor(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
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
