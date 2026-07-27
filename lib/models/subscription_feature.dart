enum SubscriptionFeature {
  additionalPets,
  unlimitedMedicalRecords,
  unlimitedReminders,
  recurringReminders,
  medicalDocumentStorage,
  activityInsights,
  passportSharing,
}

class SubscriptionFeatureDefinition {
  final SubscriptionFeature feature;
  final String title;
  final String description;

  const SubscriptionFeatureDefinition({
    required this.feature,
    required this.title,
    required this.description,
  });
}

class SubscriptionCatalog {
  const SubscriptionCatalog._();

  static const baseHighlights = <String>[
    'One pet profile',
    '20 medical records',
    '5 active one-time reminders',
    'Appointments and calendar',
    'Activity logging and recent dashboard',
    'Pet profile and provider discovery',
  ];

  static const premiumFeatures = <SubscriptionFeatureDefinition>[
    SubscriptionFeatureDefinition(
      feature: SubscriptionFeature.additionalPets,
      title: 'Unlimited pet profiles',
      description: 'Keep every pet and their care history in one account.',
    ),
    SubscriptionFeatureDefinition(
      feature: SubscriptionFeature.unlimitedMedicalRecords,
      title: 'Unlimited medical records',
      description: 'Build a complete health timeline without record limits.',
    ),
    SubscriptionFeatureDefinition(
      feature: SubscriptionFeature.unlimitedReminders,
      title: 'Unlimited reminders',
      description: 'Track every medication, appointment, and care task.',
    ),
    SubscriptionFeatureDefinition(
      feature: SubscriptionFeature.recurringReminders,
      title: 'Recurring care reminders',
      description: 'Repeat daily, weekly, or monthly care automatically.',
    ),
    SubscriptionFeatureDefinition(
      feature: SubscriptionFeature.medicalDocumentStorage,
      title: 'Medical document storage',
      description: 'Attach vaccination cards, prescriptions, and results.',
    ),
    SubscriptionFeatureDefinition(
      feature: SubscriptionFeature.activityInsights,
      title: 'Full activity history and insights',
      description: 'See complete history, totals, filters, and care patterns.',
    ),
    SubscriptionFeatureDefinition(
      feature: SubscriptionFeature.passportSharing,
      title: 'Pet Passport sharing and QR',
      description: 'Create, share, and scan portable pet information.',
    ),
  ];

  static SubscriptionFeatureDefinition definition(
    SubscriptionFeature feature,
  ) => premiumFeatures.firstWhere((entry) => entry.feature == feature);
}
