import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/utils/constants.dart';

void main() {
  group('Activity points configuration', () {
    test('every activity type has a corresponding point value', () {
      for (final type in AppConstants.activityTypes) {
        expect(
          AppConstants.activityPoints.containsKey(type),
          true,
          reason: 'Activity type "$type" is missing from activityPoints',
        );
      }
    });

    test('all point values are positive', () {
      for (final entry in AppConstants.activityPoints.entries) {
        expect(
          entry.value,
          greaterThan(0),
          reason:
              'Activity "${entry.key}" has non-positive points: ${entry.value}',
        );
      }
    });

    test('activityPoints has no extra keys beyond activityTypes', () {
      for (final key in AppConstants.activityPoints.keys) {
        expect(
          AppConstants.activityTypes.contains(key),
          true,
          reason:
              'activityPoints contains "$key" which is not in activityTypes',
        );
      }
    });
  });

  group('Badge thresholds configuration', () {
    test('all badge thresholds are positive integers', () {
      for (final entry in AppConstants.badgeThresholds.entries) {
        expect(
          entry.value,
          greaterThan(0),
          reason:
              'Badge "${entry.key}" has non-positive threshold: ${entry.value}',
        );
        expect(
          entry.value,
          isA<int>(),
          reason: 'Badge "${entry.key}" threshold is not an int',
        );
      }
    });

    test('badge thresholds map is not empty', () {
      expect(AppConstants.badgeThresholds, isNotEmpty);
    });
  });

  group('Pet species configuration', () {
    test('species list is not empty', () {
      expect(AppConstants.petSpecies, isNotEmpty);
    });

    test('species list contains common pets', () {
      expect(AppConstants.petSpecies, contains('Dog'));
      expect(AppConstants.petSpecies, contains('Cat'));
    });

    test('species list has no duplicates', () {
      final uniqueSpecies = AppConstants.petSpecies.toSet();
      expect(uniqueSpecies.length, AppConstants.petSpecies.length);
    });
  });

  group('Reminder types configuration', () {
    test('reminder types list is not empty', () {
      expect(AppConstants.reminderTypes, isNotEmpty);
    });

    test('reminder types has no duplicates', () {
      final unique = AppConstants.reminderTypes.toSet();
      expect(unique.length, AppConstants.reminderTypes.length);
    });

    test('preventive-care presets map to supported reminder types', () {
      expect(AppConstants.preventiveCareReminderPresets, isNotEmpty);
      for (final preset in AppConstants.preventiveCareReminderPresets.entries) {
        expect(AppConstants.reminderTypes, contains(preset.key));
        expect(preset.value.trim(), isNotEmpty);
      }
    });

    test('includes beta-requested preventive-care reminder types', () {
      expect(AppConstants.reminderTypes, contains('Tick & Flea'));
      expect(AppConstants.reminderTypes, contains('Vaccination'));
      expect(AppConstants.reminderTypes, contains('Medication Refill'));
      expect(AppConstants.reminderTypes, contains('Medication Expiration'));
      expect(AppConstants.reminderTypes, contains('Deworming'));
    });
  });

  group('Appointment types configuration', () {
    test('appointment types list is not empty', () {
      expect(AppConstants.appointmentTypes, isNotEmpty);
    });

    test('appointment types has no duplicates', () {
      final unique = AppConstants.appointmentTypes.toSet();
      expect(unique.length, AppConstants.appointmentTypes.length);
    });
  });

  group('Storage bucket constants', () {
    test('bucket names are non-empty strings', () {
      expect(AppConstants.petPhotosBucket, isNotEmpty);
      expect(AppConstants.medicalDocsBucket, isNotEmpty);
      expect(AppConstants.activityPhotosBucket, isNotEmpty);
      expect(AppConstants.profilePhotosBucket, isNotEmpty);
    });

    test('bucket names are unique', () {
      final buckets = {
        AppConstants.petPhotosBucket,
        AppConstants.medicalDocsBucket,
        AppConstants.activityPhotosBucket,
        AppConstants.profilePhotosBucket,
      };
      expect(buckets.length, 4);
    });
  });
}
