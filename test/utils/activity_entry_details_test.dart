import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/utils/activity_entry_details.dart';

void main() {
  test('each activity stores only details relevant to that activity', () {
    const details = ActivityEntryDetails(
      walkRoute: 'River trail',
      playStyle: 'Fetch',
      trainingSkill: 'Stay',
      trainingOutcome: 'Improved',
      mealType: 'Meal',
      foodAmount: 'One cup',
      groomingLocation: 'Home',
      groomingServices: {'Nails', 'Bath'},
      vetReason: 'Annual checkup',
      vetClinic: 'Paw Clinic',
      socialCompanion: 'Milo',
      socialSetting: 'Park',
      restQuality: 'Nap',
      restLocation: 'Sofa',
    );

    expect(details.metadataFor('Walk'), {'route': 'River trail'});
    expect(details.metadataFor('Play'), {'play_style': 'Fetch'});
    expect(details.metadataFor('Train'), {
      'skill': 'Stay',
      'outcome': 'Improved',
    });
    expect(details.metadataFor('Feed'), {
      'meal_type': 'Meal',
      'amount': 'One cup',
    });
    expect(details.metadataFor('Groom'), {
      'location': 'Home',
      'services': ['Bath', 'Nails'],
    });
    expect(details.metadataFor('Vet Visit'), {
      'reason': 'Annual checkup',
      'clinic': 'Paw Clinic',
    });
    expect(details.metadataFor('Social'), {
      'companion': 'Milo',
      'setting': 'Park',
    });
    expect(details.metadataFor('Rest'), {'quality': 'Nap', 'location': 'Sofa'});
  });

  test('blank optional values are not persisted', () {
    const details = ActivityEntryDetails(walkRoute: '   ');
    expect(details.metadataFor('Walk'), isNull);
  });
}
