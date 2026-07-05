import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/services/notification_service.dart';

void main() {
  group('NotificationService.stableNotificationId', () {
    test('is deterministic for the same key', () {
      const key = 'b4b5c04f-8a9e-4a41-a4f4-1a7c1f6f2b6e';
      expect(
        NotificationService.stableNotificationId(key),
        NotificationService.stableNotificationId(key),
      );
    });

    test('differs between a reminder and its _due companion', () {
      const key = 'b4b5c04f-8a9e-4a41-a4f4-1a7c1f6f2b6e';
      expect(
        NotificationService.stableNotificationId(key),
        isNot(NotificationService.stableNotificationId('${key}_due')),
      );
    });

    test('fits in a signed 32-bit int and is non-negative', () {
      for (final key in ['', 'a', 'reminder-id', '🐾' * 50]) {
        final id = NotificationService.stableNotificationId(key);
        expect(id, greaterThanOrEqualTo(0));
        expect(id, lessThanOrEqualTo(0x7FFFFFFF));
      }
    });
  });
}
