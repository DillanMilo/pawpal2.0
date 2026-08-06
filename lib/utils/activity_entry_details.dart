class ActivityEntryDetails {
  const ActivityEntryDetails({
    this.walkRoute,
    this.playStyle,
    this.trainingSkill,
    this.trainingOutcome,
    this.mealType,
    this.foodAmount,
    this.groomingLocation,
    this.groomingServices = const <String>{},
    this.vetReason,
    this.vetClinic,
    this.socialCompanion,
    this.socialSetting,
    this.restQuality,
    this.restLocation,
  });

  final String? walkRoute;
  final String? playStyle;
  final String? trainingSkill;
  final String? trainingOutcome;
  final String? mealType;
  final String? foodAmount;
  final String? groomingLocation;
  final Set<String> groomingServices;
  final String? vetReason;
  final String? vetClinic;
  final String? socialCompanion;
  final String? socialSetting;
  final String? restQuality;
  final String? restLocation;

  Map<String, dynamic>? metadataFor(String type) {
    final metadata = <String, dynamic>{};
    void addText(String key, String? value) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) metadata[key] = trimmed;
    }

    switch (type) {
      case 'Walk':
        addText('route', walkRoute);
        break;
      case 'Play':
        addText('play_style', playStyle);
        break;
      case 'Train':
        addText('skill', trainingSkill);
        addText('outcome', trainingOutcome);
        break;
      case 'Feed':
        addText('meal_type', mealType);
        addText('amount', foodAmount);
        break;
      case 'Groom':
        addText('location', groomingLocation);
        if (groomingServices.isNotEmpty) {
          metadata['services'] = groomingServices.toList()..sort();
        }
        break;
      case 'Vet Visit':
        addText('reason', vetReason);
        addText('clinic', vetClinic);
        break;
      case 'Social':
        addText('companion', socialCompanion);
        addText('setting', socialSetting);
        break;
      case 'Rest':
        addText('quality', restQuality);
        addText('location', restLocation);
        break;
    }

    return metadata.isEmpty ? null : metadata;
  }
}
