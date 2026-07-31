class CareMomentum {
  const CareMomentum.empty()
    : activeDays = 0,
      windowDays = 7,
      lastCareAt = null;

  const CareMomentum({
    required this.activeDays,
    required this.windowDays,
    this.lastCareAt,
  });

  final int activeDays;
  final int windowDays;
  final DateTime? lastCareAt;

  double get progress => windowDays == 0 ? 0 : activeDays / windowDays;

  String get label => switch (activeDays) {
    0 => 'Resting',
    1 => 'Starting',
    2 || 3 => 'Building',
    4 || 5 => 'Strong',
    _ => 'Thriving',
  };

  static CareMomentum fromTimestamps(
    Iterable<DateTime> timestamps, {
    DateTime? now,
    int windowDays = 7,
  }) {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final firstDay = today.subtract(Duration(days: windowDays - 1));
    final activeDates = <DateTime>{};
    DateTime? lastCareAt;

    for (final timestamp in timestamps) {
      final local = timestamp.toLocal();
      if (lastCareAt == null || local.isAfter(lastCareAt)) lastCareAt = local;
      final date = DateTime(local.year, local.month, local.day);
      if (!date.isBefore(firstDay) && !date.isAfter(today)) {
        activeDates.add(date);
      }
    }

    return CareMomentum(
      activeDays: activeDates.length,
      windowDays: windowDays,
      lastCareAt: lastCareAt,
    );
  }
}
