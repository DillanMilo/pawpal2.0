import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/models/user_profile.dart';
import 'package:pawpal/utils/router.dart';

void main() {
  UserProfile profile({
    required bool onboardingComplete,
    required bool pricingComplete,
  }) {
    final now = DateTime(2026, 7, 31);
    return UserProfile(
      id: 'user-1',
      email: 'sam@example.com',
      hasSeenPricing: pricingComplete,
      onboardingCompletedAt: onboardingComplete ? now : null,
      appTourCompletedAt: onboardingComplete ? now : null,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('new authenticated users land in useful setup first', () {
    expect(
      AppRouter.authenticatedLandingPath(
        profile(onboardingComplete: false, pricingComplete: false),
      ),
      '/onboarding',
    );
  });

  test('pricing follows setup when it has not been acknowledged', () {
    expect(
      AppRouter.authenticatedLandingPath(
        profile(onboardingComplete: true, pricingComplete: false),
      ),
      '/welcome',
    );
  });

  test('existing and fully onboarded users land at home', () {
    expect(
      AppRouter.authenticatedLandingPath(
        profile(onboardingComplete: true, pricingComplete: true),
      ),
      '/home',
    );
  });
}
