import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/models/user_profile.dart';

void main() {
  Map<String, dynamic> profileJson() => {
    'id': 'user-1',
    'email': 'sam@example.com',
    'name': 'Sam',
    'has_seen_pricing': true,
    'created_at': '2026-07-31T12:00:00Z',
    'updated_at': '2026-07-31T12:00:00Z',
  };

  group('first-run profile state', () {
    test('older schema safely bypasses onboarding and tour', () {
      final profile = UserProfile.fromJson(profileJson());

      expect(profile.supportsFirstRun, isFalse);
      expect(profile.needsOnboarding, isFalse);
      expect(profile.needsAppTour, isFalse);
      expect(profile.needsQuickActionsTour, isFalse);
      expect(profile.needsPetProfileTour, isFalse);
      expect(profile.toJson(), isNot(contains('onboarding_step')));
    });

    test('new account enters onboarding and restores its draft', () {
      final json = profileJson()
        ..addAll({
          'onboarding_step': 1,
          'onboarding_draft': {
            'owner_name': 'Sam',
            'pet_id': 'pet-stable-id',
            'pet_name': 'Milo',
            'species': 'Dog',
          },
          'onboarding_completed_at': null,
          'app_tour_step': 0,
          'app_tour_completed_at': null,
          'quick_actions_tour_completed_at': null,
          'pet_profile_tour_completed_at': null,
        });

      final profile = UserProfile.fromJson(json);

      expect(profile.needsOnboarding, isTrue);
      expect(profile.onboardingStep, 1);
      expect(profile.onboardingDraft['pet_id'], 'pet-stable-id');
      expect(profile.needsAppTour, isFalse);
      expect(profile.needsQuickActionsTour, isTrue);
      expect(profile.needsPetProfileTour, isTrue);
    });

    test('completed setup starts resumable tour only once', () {
      final json = profileJson()
        ..addAll({
          'onboarding_step': 2,
          'onboarding_draft': <String, dynamic>{},
          'onboarding_completed_at': '2026-07-31T12:10:00Z',
          'app_tour_step': 3,
          'app_tour_completed_at': null,
        });

      final profile = UserProfile.fromJson(json);

      expect(profile.needsOnboarding, isFalse);
      expect(profile.needsAppTour, isTrue);
      expect(profile.appTourStep, 3);

      final completed = UserProfile.fromJson({
        ...json,
        'app_tour_completed_at': '2026-07-31T12:15:00Z',
      });
      expect(completed.needsAppTour, isFalse);
    });

    test('contextual tours are independently completed', () {
      final json = profileJson()
        ..addAll({
          'onboarding_completed_at': '2026-07-31T12:10:00Z',
          'app_tour_completed_at': '2026-07-31T12:15:00Z',
          'quick_actions_tour_completed_at': '2026-07-31T12:20:00Z',
          'pet_profile_tour_completed_at': null,
        });

      final profile = UserProfile.fromJson(json);

      expect(profile.needsQuickActionsTour, isFalse);
      expect(profile.needsPetProfileTour, isTrue);
    });
  });
}
