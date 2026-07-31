import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'supabase_service.dart';
import '../models/user_profile.dart';
import '../utils/constants.dart';
import '../utils/image_upload.dart';

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
      queryParams: const {'prompt': 'select_account'},
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
    data['updated_at'] = DateTime.now().toUtc().toIso8601String();

    final response = await _client
        .from('users')
        .update(data)
        .eq('id', profile.id)
        .select()
        .single();

    return UserProfile.fromJson(response);
  }

  Future<UserProfile> saveOnboardingProgress({
    required String userId,
    required int step,
    required Map<String, dynamic> draft,
    String? preferredName,
  }) async {
    final data = <String, dynamic>{
      'onboarding_step': step,
      'onboarding_draft': draft,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (preferredName != null) data['name'] = preferredName;
    final response = await _client
        .from('users')
        .update(data)
        .eq('id', userId)
        .select()
        .single();
    return UserProfile.fromJson(response);
  }

  Future<UserProfile> completeOnboarding({
    required String userId,
    required String preferredName,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final response = await _client
        .from('users')
        .update({
          'name': preferredName,
          'onboarding_step': 2,
          'onboarding_draft': <String, dynamic>{},
          'onboarding_completed_at': now,
          'app_tour_step': 0,
          'updated_at': now,
        })
        .eq('id', userId)
        .select()
        .single();
    return UserProfile.fromJson(response);
  }

  Future<UserProfile> saveAppTourStep(String userId, int step) async {
    final response = await _client
        .from('users')
        .update({
          'app_tour_step': step,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', userId)
        .select()
        .single();
    return UserProfile.fromJson(response);
  }

  Future<UserProfile> completeAppTour(String userId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final response = await _client
        .from('users')
        .update({'app_tour_completed_at': now, 'updated_at': now})
        .eq('id', userId)
        .select()
        .single();
    return UserProfile.fromJson(response);
  }

  // Upload a profile photo and return the public URL.
  Future<String> uploadProfilePhoto(XFile photo, {String? previousUrl}) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final bytes = await photo.readAsBytes();
    final imageType = resolveImageUploadType(
      bytes: bytes,
      mimeType: _safeMimeType(photo),
      fileName: _safeFileName(photo),
    );
    final path = '$userId/${_uuid.v4()}.${imageType.extension}';

    await _client.storage
        .from(AppConstants.profilePhotosBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: imageType.contentType,
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
    final now = DateTime.now().toUtc().toIso8601String();
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

  String? _safeMimeType(XFile photo) {
    try {
      return photo.mimeType;
    } catch (_) {
      return null;
    }
  }

  String? _safeFileName(XFile photo) {
    try {
      final name = photo.name;
      return name.isEmpty ? null : name;
    } catch (_) {
      return null;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    if (SupabaseService.currentUserId == null) return;

    await _client.functions.invoke('delete-account');
    await signOut();
  }
}
