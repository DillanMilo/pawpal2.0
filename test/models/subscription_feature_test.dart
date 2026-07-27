import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/models/subscription_feature.dart';

void main() {
  group('SubscriptionCatalog', () {
    test('defines every premium feature exactly once', () {
      final features = SubscriptionCatalog.premiumFeatures
          .map((entry) => entry.feature)
          .toList();

      expect(features.toSet().length, SubscriptionFeature.values.length);
      expect(features.toSet(), containsAll(SubscriptionFeature.values));
    });

    test('keeps Base useful without claiming premium-only capabilities', () {
      expect(SubscriptionCatalog.baseHighlights, contains('One pet profile'));
      expect(
        SubscriptionCatalog.baseHighlights,
        contains('Appointments and calendar'),
      );
      expect(
        SubscriptionCatalog.baseHighlights.join(' ').toLowerCase(),
        isNot(contains('unlimited')),
      );
    });

    test('publishes customer-facing copy for each premium gate', () {
      for (final feature in SubscriptionFeature.values) {
        final definition = SubscriptionCatalog.definition(feature);
        expect(definition.title, isNotEmpty);
        expect(definition.description, isNotEmpty);
      }
    });
  });
}
