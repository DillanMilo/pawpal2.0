import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../utils/auth_error_message.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserProfile? _userProfile;
  String? _error;
  StreamSubscription<AuthState>? _authSub;

  AuthStatus get status => _status;
  UserProfile? get userProfile => _userProfile;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider() {
    _init();
  }

  void _init() {
    // Listen to auth state changes
    _authSub = SupabaseService.authStateChanges.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _loadUserProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        _userProfile = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    });

    // Check initial auth state
    if (SupabaseService.isAuthenticated) {
      _loadUserProfile();
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<bool> _loadUserProfile() async {
    try {
      _userProfile = await _authService.ensureCurrentUserProfile();
      if (_userProfile == null) {
        _error = authUnexpectedErrorMessage;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      _status = AuthStatus.authenticated;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _userProfile = null;
      _error = authErrorMessage(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      await _authService.signUp(email: email, password: password, name: name);

      return await _loadUserProfile();
    } catch (e) {
      _error = authErrorMessage(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      await _authService.signIn(email: email, password: password);

      return await _loadUserProfile();
    } catch (e) {
      _error = authErrorMessage(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      final success = await _authService.signInWithGoogle();
      if (!success) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = authErrorMessage(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      final success = await _authService.signInWithApple();
      if (!success) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = authErrorMessage(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _userProfile = null;
      _status = AuthStatus.unauthenticated;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _error = authErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(UserProfile profile) async {
    try {
      _userProfile = await _authService.updateUserProfile(profile);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfileDetails({
    required String name,
    String? phoneNumber,
    String? zipCode,
    XFile? photo,
  }) async {
    final currentProfile = _userProfile;
    if (currentProfile == null) {
      _error = 'No user profile loaded';
      notifyListeners();
      return false;
    }

    try {
      String? photoUrl = currentProfile.photoUrl;
      if (photo != null) {
        photoUrl = await _authService.uploadProfilePhoto(
          photo,
          previousUrl: currentProfile.photoUrl,
        );
      }

      final updatedProfile = UserProfile(
        id: currentProfile.id,
        email: currentProfile.email,
        name: name.trim().isEmpty ? null : name.trim(),
        photoUrl: photoUrl,
        phoneNumber: phoneNumber?.trim().isEmpty == true
            ? null
            : phoneNumber?.trim(),
        zipCode: zipCode?.trim().isEmpty == true ? null : zipCode?.trim(),
        notificationsEnabled: currentProfile.notificationsEnabled,
        hasSeenPricing: currentProfile.hasSeenPricing,
        createdAt: currentProfile.createdAt,
        updatedAt: DateTime.now(),
      );

      _userProfile = await _authService.updateUserProfile(updatedProfile);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateNotificationPreference(bool enabled) async {
    final currentProfile = _userProfile;
    if (currentProfile == null) return false;

    try {
      _userProfile = await _authService.updateUserProfile(
        currentProfile.copyWith(notificationsEnabled: enabled),
      );
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completePricingOnboarding() async {
    final currentProfile = _userProfile;
    if (currentProfile == null) return false;

    try {
      _userProfile = await _authService.updateUserProfile(
        currentProfile.copyWith(hasSeenPricing: true),
      );
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveOnboardingProgress({
    required int step,
    required Map<String, dynamic> draft,
    String? preferredName,
  }) async {
    final currentProfile = _userProfile;
    if (currentProfile == null) return false;
    try {
      _userProfile = await _authService.saveOnboardingProgress(
        userId: currentProfile.id,
        step: step,
        draft: draft,
        preferredName: preferredName,
      );
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeFirstRunOnboarding(String preferredName) async {
    final currentProfile = _userProfile;
    if (currentProfile == null) return false;
    try {
      _userProfile = await _authService.completeOnboarding(
        userId: currentProfile.id,
        preferredName: preferredName,
      );
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveAppTourStep(int step) async {
    final currentProfile = _userProfile;
    if (currentProfile == null) return false;
    try {
      _userProfile = await _authService.saveAppTourStep(
        currentProfile.id,
        step,
      );
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeAppTour() async {
    final currentProfile = _userProfile;
    if (currentProfile == null) return false;
    try {
      _userProfile = await _authService.completeAppTour(currentProfile.id);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeQuickActionsTour() async {
    final currentProfile = _userProfile;
    if (currentProfile == null) return false;
    try {
      _userProfile = await _authService.completeQuickActionsTour(
        currentProfile.id,
      );
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completePetProfileTour() async {
    final currentProfile = _userProfile;
    if (currentProfile == null) return false;
    try {
      _userProfile = await _authService.completePetProfileTour(
        currentProfile.id,
      );
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetContextualTours() async {
    final currentProfile = _userProfile;
    if (currentProfile == null) return false;
    try {
      _userProfile = await _authService.resetContextualTours(currentProfile.id);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _error = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      await _authService.deleteAccount();
      _userProfile = null;
      _status = AuthStatus.unauthenticated;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
