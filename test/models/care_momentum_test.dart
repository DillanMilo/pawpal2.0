import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/models/care_momentum.dart';
import 'package:pawpal/models/pet_progression.dart';

void main() {
  group('CareMomentum', () {
    final now = DateTime(2026, 7, 31, 12);

    test('counts unique care days in the rolling seven-day window', () {
      final momentum = CareMomentum.fromTimestamps([
        DateTime(2026, 7, 31, 8),
        DateTime(2026, 7, 31, 18),
        DateTime(2026, 7, 29, 9),
        DateTime(2026, 7, 25, 10),
        DateTime(2026, 7, 24, 10),
      ], now: now);

      expect(momentum.activeDays, 3);
      expect(momentum.windowDays, 7);
      expect(momentum.label, 'Building');
      expect(momentum.progress, closeTo(3 / 7, 0.0001));
    });

    test('declines with time while the permanent level does not decay', () {
      final timestamps = [
        DateTime(2026, 7, 31, 8),
        DateTime(2026, 7, 30, 8),
        DateTime(2026, 7, 29, 8),
        DateTime(2026, 7, 28, 8),
      ];
      const lifetimePoints = 380;
      const progression = PetProgression(lifetimePoints);

      final current = CareMomentum.fromTimestamps(timestamps, now: now);
      final later = CareMomentum.fromTimestamps(
        timestamps,
        now: now.add(const Duration(days: 8)),
      );

      expect(current.activeDays, 4);
      expect(current.label, 'Strong');
      expect(later.activeDays, 0);
      expect(later.label, 'Resting');
      expect(progression.level, 5);
      expect(const PetProgression(lifetimePoints).level, progression.level);
    });
  });
}
