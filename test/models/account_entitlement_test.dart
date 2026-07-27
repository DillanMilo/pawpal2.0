import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/models/account_entitlement.dart';

void main() {
  group('AccountEntitlement', () {
    test('grants Plus during an active PawPal trial', () {
      final now = DateTime(2026, 7, 20, 12);
      final entitlement = AccountEntitlement.fromJson({
        'user_id': 'user-1',
        'tier': 'plus',
        'status': 'trialing',
        'source': 'pawpal_trial',
        'trial_started_at': now
            .subtract(const Duration(days: 1))
            .toUtc()
            .toIso8601String(),
        'trial_ends_at': now
            .add(const Duration(days: 13))
            .toUtc()
            .toIso8601String(),
      });

      expect(entitlement.hasPlusAccessAt(now), isTrue);
      expect(entitlement.isTrial, isTrue);
    });

    test('expires trial access using the server timestamp', () {
      final now = DateTime(2026, 7, 20, 12);
      final entitlement = AccountEntitlement.fromJson({
        'user_id': 'user-1',
        'tier': 'plus',
        'status': 'trialing',
        'source': 'pawpal_trial',
        'trial_ends_at': now
            .subtract(const Duration(seconds: 1))
            .toUtc()
            .toIso8601String(),
      });

      expect(entitlement.hasPlusAccessAt(now), isFalse);
    });

    test('keeps canceled subscriptions active through the paid period', () {
      final now = DateTime(2026, 7, 20, 12);
      final entitlement = AccountEntitlement.fromJson({
        'user_id': 'user-1',
        'tier': 'plus',
        'status': 'canceled',
        'source': 'app_store',
        'current_period_ends_at': now
            .add(const Duration(days: 20))
            .toUtc()
            .toIso8601String(),
        'will_renew': false,
      });

      expect(entitlement.hasPlusAccessAt(now), isTrue);
      expect(entitlement.willRenew, isFalse);
    });

    test('does not grant access for an expired paid period', () {
      final now = DateTime(2026, 7, 20, 12);
      final entitlement = AccountEntitlement.fromJson({
        'user_id': 'user-1',
        'tier': 'plus',
        'status': 'expired',
        'source': 'stripe',
        'current_period_ends_at': now
            .subtract(const Duration(days: 1))
            .toUtc()
            .toIso8601String(),
      });

      expect(entitlement.hasPlusAccessAt(now), isFalse);
    });
  });
}
