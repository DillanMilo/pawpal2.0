import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawpal/models/user_profile.dart';
import 'package:pawpal/providers/auth_provider.dart';

/// A fake AuthProvider that does not touch Supabase.
/// Used in widget tests to satisfy the provider dependency.
///
/// Dart allows `implements` on concrete classes. This gives us an AuthProvider
/// that the Provider widget tree accepts via `ChangeNotifierProvider<AuthProvider>`
/// without ever initializing Supabase.
class FakeAuthProvider with ChangeNotifier implements AuthProvider {
  FakeAuthProvider({
    AuthStatus status = AuthStatus.unauthenticated,
    UserProfile? userProfile,
  }) : _status = status,
       _userProfile = userProfile;

  final AuthStatus _status;
  UserProfile? _userProfile;
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
  UserProfile? get userProfile => _userProfile;

  @override
  Future<bool> signIn({required String email, required String password}) async {
    return false;
  }

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
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
  Future<bool> updateProfileDetails({
    required String name,
    String? phoneNumber,
    String? zipCode,
    XFile? photo,
  }) async => false;

  @override
  Future<bool> updateNotificationPreference(bool enabled) async => false;

  @override
  Future<bool> completePricingOnboarding() async => false;

  @override
  Future<bool> saveOnboardingProgress({
    required int step,
    required Map<String, dynamic> draft,
    String? preferredName,
  }) async {
    final profile = _userProfile;
    if (profile == null) return false;
    _userProfile = profile.copyWith(
      name: preferredName,
      onboardingStep: step,
      onboardingDraft: draft,
    );
    notifyListeners();
    return true;
  }

  @override
  Future<bool> completeFirstRunOnboarding(String preferredName) async => true;

  @override
  Future<bool> saveAppTourStep(int step) async => true;

  @override
  Future<bool> completeAppTour() async => true;

  @override
  Future<bool> completeQuickActionsTour() async {
    final profile = _userProfile;
    if (profile == null) return false;
    _userProfile = profile.copyWith(
      quickActionsTourCompletedAt: DateTime.now(),
    );
    notifyListeners();
    return true;
  }

  @override
  Future<bool> completePetProfileTour() async {
    final profile = _userProfile;
    if (profile == null) return false;
    _userProfile = profile.copyWith(petProfileTourCompletedAt: DateTime.now());
    notifyListeners();
    return true;
  }

  @override
  Future<bool> resetContextualTours() async {
    final profile = _userProfile;
    if (profile == null) return false;
    _userProfile = UserProfile.fromJson({
      ...profile.toJson(),
      'quick_actions_tour_completed_at': null,
      'pet_profile_tour_completed_at': null,
    });
    notifyListeners();
    return true;
  }

  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => false;

  @override
  Future<bool> deleteAccount() async => false;

  @override
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
