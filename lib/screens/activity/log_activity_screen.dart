import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/activity.dart';
import '../../models/pet.dart';
import '../../models/pet_progression.dart';
import '../../providers/activity_provider.dart';
import '../../providers/pet_provider.dart';
import '../../utils/constants.dart';
import '../../utils/activity_entry_details.dart';
import '../../utils/activity_scoring.dart';
import '../../utils/theme.dart';
import '../../widgets/level_up_celebration.dart';

enum _DurationMode { none, timer, manual }

class LogActivityScreen extends StatefulWidget {
  final String? initialType;
  final Pet? pet;

  const LogActivityScreen({super.key, this.initialType, this.pet});

  @override
  State<LogActivityScreen> createState() => _LogActivityScreenState();
}

class _LogActivityScreenState extends State<LogActivityScreen> {
  final _notesController = TextEditingController();
  final _walkDistanceController = TextEditingController();
  final _walkRouteController = TextEditingController();
  final _trainingSkillController = TextEditingController();
  final _foodAmountController = TextEditingController();
  final _vetReasonController = TextEditingController();
  final _vetClinicController = TextEditingController();
  final _socialCompanionController = TextEditingController();
  final _restLocationController = TextEditingController();

  late String _selectedType;
  Pet? _selectedPet;
  _DurationMode _durationMode = _DurationMode.none;
  DateTime? _startTime;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  int? _manualDuration;
  bool _isLoading = false;
  String _playStyle = 'Fetch';
  String _trainingOutcome = 'Practiced';
  String _mealType = 'Meal';
  String _groomingLocation = 'Home';
  final Set<String> _groomingServices = {'Brush'};
  String _socialSetting = 'At home';
  String _restQuality = 'Settled';

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? 'Walk';
    _selectedPet = widget.pet;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _walkDistanceController.dispose();
    _walkRouteController.dispose();
    _trainingSkillController.dispose();
    _foodAmountController.dispose();
    _vetReasonController.dispose();
    _vetClinicController.dispose();
    _socialCompanionController.dispose();
    _restLocationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer({bool reset = false}) {
    _timer?.cancel();
    setState(() {
      _durationMode = _DurationMode.timer;
      if (reset) _elapsed = Duration.zero;
      _startTime = DateTime.now().subtract(_elapsed);
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _elapsed = DateTime.now().difference(_startTime!);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _timer = null;
    });
  }

  void _setDurationMode(_DurationMode mode) {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _durationMode = mode;
      _startTime = null;
      _elapsed = Duration.zero;
      if (mode != _DurationMode.manual) _manualDuration = null;
    });
    if (mode == _DurationMode.timer) _startTimer(reset: true);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _saveActivity() async {
    if (_selectedPet == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a pet')));
      return;
    }

    setState(() => _isLoading = true);

    final activityProvider = context.read<ActivityProvider>();
    final pet = _selectedPet!;
    final previousPoints = activityProvider.pointsForPet(pet.id);
    final now = DateTime.now();
    final duration = _selectedDuration;
    final startTime = _durationMode == _DurationMode.timer && _startTime != null
        ? _startTime!
        : duration != null
        ? now.subtract(Duration(minutes: duration))
        : now;

    final expectedPoints = ActivityScoring.calculateAward(
      _selectedType,
      durationMinutes: duration,
      earnedToday: activityProvider.totalDailyPoints,
    );

    final details = ActivityEntryDetails(
      walkRoute: _walkRouteController.text,
      playStyle: _playStyle,
      trainingSkill: _trainingSkillController.text,
      trainingOutcome: _trainingOutcome,
      mealType: _mealType,
      foodAmount: _foodAmountController.text,
      groomingLocation: _groomingLocation,
      groomingServices: _groomingServices,
      vetReason: _vetReasonController.text,
      vetClinic: _vetClinicController.text,
      socialCompanion: _socialCompanionController.text,
      socialSetting: _socialSetting,
      restQuality: _restQuality,
      restLocation: _restLocationController.text,
    );

    final activity = Activity(
      id: '',
      petId: pet.id,
      userId: '',
      type: _selectedType,
      startTime: startTime,
      endTime: duration == null ? null : now,
      durationMinutes: duration,
      distance: _selectedType == 'Walk'
          ? double.tryParse(_walkDistanceController.text.trim())
          : null,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      points: expectedPoints,
      metadata: details.metadataFor(_selectedType),
      createdAt: now,
    );

    final success = await activityProvider.logActivity(activity);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final earnedPoints = activityProvider.lastAwardedPoints ?? expectedPoints;
      final levelUp = PetProgression.levelUpBetween(
        previousPoints,
        previousPoints + earnedPoints,
      );
      if (levelUp != null) {
        await showLevelUpCelebration(
          context,
          petName: pet.name,
          transition: levelUp,
        );
        if (!mounted) return;
      }
      final dailyLimitReached =
          activityProvider.totalDailyPoints >= ActivityScoring.dailyPointsLimit;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            earnedPoints == 0
                ? 'Activity saved. ${pet.name} has reached today\'s PawPoints limit.'
                : dailyLimitReached
                ? 'Activity saved! +$earnedPoints PawPoints (daily limit reached).'
                : '+$earnedPoints PawPoints for ${pet.name}!',
          ),
          backgroundColor: AppTheme.successSnackBackground,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(activityProvider.error ?? 'Failed to log activity'),
          backgroundColor: AppTheme.errorSnackBackground,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final activityProvider = context.watch<ActivityProvider>();

    // Set selected pet if not already set
    if (_selectedPet == null && petProvider.pets.isNotEmpty) {
      _selectedPet = petProvider.selectedPet ?? petProvider.pets.first;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Log Activity')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Activity type selector
          const Text(
            'Activity Type',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.activityTypes.map((type) {
              final isSelected = type == _selectedType;
              final color =
                  AppTheme.activityColors[type] ?? AppTheme.primaryColor;
              final selectedForeground = AppTheme.foregroundOn(color);
              return FilterChip(
                selected: isSelected,
                label: Text(type),
                avatar: Icon(
                  _getActivityIcon(type),
                  size: 18,
                  color: isSelected ? selectedForeground : color,
                ),
                selectedColor: color,
                checkmarkColor: selectedForeground,
                labelStyle: TextStyle(
                  color: isSelected
                      ? selectedForeground
                      : AppTheme.primaryText(context),
                ),
                onSelected: (selected) {
                  if (!selected || type == _selectedType) return;
                  _timer?.cancel();
                  setState(() {
                    _selectedType = type;
                    _durationMode = _DurationMode.none;
                    _startTime = null;
                    _elapsed = Duration.zero;
                    _manualDuration = null;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Pet selector
          const Text(
            'Pet',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (petProvider.pets.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No pets found. Add a pet first.',
                  style: TextStyle(color: AppTheme.secondaryText(context)),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: petProvider.pets.map((pet) {
                final isSelected = pet.id == _selectedPet?.id;
                final selectedForeground = AppTheme.foregroundOn(
                  AppTheme.primaryColor,
                );
                return FilterChip(
                  selected: isSelected,
                  label: Text(pet.name),
                  avatar: const Icon(Icons.pets, size: 18),
                  selectedColor: AppTheme.primaryColor,
                  checkmarkColor: selectedForeground,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? selectedForeground
                        : AppTheme.primaryText(context),
                  ),
                  onSelected: (selected) {
                    setState(() => _selectedPet = pet);
                  },
                );
              }).toList(),
            ),
          const SizedBox(height: 24),

          _buildActivityDetails(),
          const SizedBox(height: 24),

          // Duration section
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Duration (optional)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              Text(
                'Skip anytime',
                style: TextStyle(
                  color: AppTheme.mutedText(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_selectedType == 'Play') ...[
            Container(
              key: const Key('play-no-duration-help'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.softTint(context, AppTheme.accentColor),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: AppTheme.accentColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Quick play? Choose No duration and save it right away.',
                      style: TextStyle(
                        color: AppTheme.primaryText(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                key: const Key('duration-none'),
                label: const Text('No duration'),
                avatar: const Icon(Icons.flash_on_rounded, size: 18),
                selected: _durationMode == _DurationMode.none,
                onSelected: (_) => _setDurationMode(_DurationMode.none),
              ),
              ChoiceChip(
                key: const Key('duration-timer'),
                label: const Text('Use timer'),
                avatar: const Icon(Icons.timer_rounded, size: 18),
                selected: _durationMode == _DurationMode.timer,
                onSelected: (_) => _setDurationMode(_DurationMode.timer),
              ),
              ChoiceChip(
                key: const Key('duration-manual'),
                label: const Text('Enter minutes'),
                avatar: const Icon(Icons.edit_rounded, size: 18),
                selected: _durationMode == _DurationMode.manual,
                onSelected: (_) => _setDurationMode(_DurationMode.manual),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Timer card
          if (_durationMode != _DurationMode.none)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_durationMode == _DurationMode.timer &&
                        _startTime != null) ...[
                      // Timer display
                      Text(
                        _formatDuration(_elapsed),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_timer != null)
                            ElevatedButton.icon(
                              onPressed: _stopTimer,
                              icon: const Icon(Icons.pause),
                              label: const Text('Pause'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.warningColor,
                                foregroundColor: AppTheme.foregroundOn(
                                  AppTheme.warningColor,
                                ),
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: _startTimer,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Resume'),
                            ),
                        ],
                      ),
                    ] else if (_durationMode == _DurationMode.manual) ...[
                      TextFormField(
                        key: const Key('manual-duration-minutes'),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'How many minutes?',
                          prefixIcon: Icon(Icons.schedule_rounded),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _manualDuration = int.tryParse(value);
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Notes
          TextFormField(
            controller: _notesController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              prefixIcon: Icon(Icons.notes),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),

          // Points preview
          Card(
            color: AppTheme.softTint(context, AppTheme.primaryColor),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.star, color: AppTheme.accentColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PawPoints you\'ll earn',
                          style: TextStyle(
                            color: AppTheme.secondaryText(context),
                          ),
                        ),
                        Text(
                          '+${_previewPoints(activityProvider)} PawPoints',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryAccentText(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _pointsExplanation(activityProvider),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.mutedText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Save button
          ElevatedButton(
            onPressed: _isLoading ? null : _saveActivity,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.actionBlue,
              foregroundColor: AppTheme.foregroundOn(AppTheme.actionBlue),
              elevation: 10,
              shadowColor: AppTheme.actionBlue.withValues(alpha: 0.28),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Log Activity'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActivityDetails() {
    Widget field(
      TextEditingController controller,
      String label,
      IconData icon, {
      TextInputType? keyboardType,
    }) {
      return TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      );
    }

    Widget dropdown(
      String value,
      String label,
      IconData icon,
      List<String> values,
      ValueChanged<String> onChanged,
    ) {
      return DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        items: values
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      );
    }

    final children = <Widget>[
      Text(
        '$_selectedType details (optional)',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      const SizedBox(height: 12),
    ];

    switch (_selectedType) {
      case 'Walk':
        children.addAll([
          field(
            _walkDistanceController,
            'Distance in km',
            Icons.straighten_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          field(_walkRouteController, 'Route or location', Icons.route_rounded),
        ]);
      case 'Play':
        children.add(
          dropdown(
            _playStyle,
            'Kind of play',
            Icons.sports_baseball_rounded,
            const ['Fetch', 'Tug', 'Chase', 'Enrichment', 'Other'],
            (value) => setState(() => _playStyle = value),
          ),
        );
      case 'Train':
        children.addAll([
          field(_trainingSkillController, 'Skill practiced', Icons.school),
          const SizedBox(height: 12),
          dropdown(
            _trainingOutcome,
            'How did it go?',
            Icons.trending_up_rounded,
            const ['Practiced', 'Learning', 'Improved', 'Mastered'],
            (value) => setState(() => _trainingOutcome = value),
          ),
        ]);
      case 'Feed':
        children.addAll([
          dropdown(
            _mealType,
            'What was given?',
            Icons.restaurant_rounded,
            const ['Meal', 'Treat', 'Supplement', 'Water'],
            (value) => setState(() => _mealType = value),
          ),
          const SizedBox(height: 12),
          field(
            _foodAmountController,
            'Amount or portion',
            Icons.scale_rounded,
          ),
        ]);
      case 'Groom':
        children.addAll([
          dropdown(
            _groomingLocation,
            'Where?',
            Icons.home_rounded,
            const ['Home', 'Groomer / salon'],
            (value) => setState(() => _groomingLocation = value),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const ['Brush', 'Bath', 'Nails', 'Teeth', 'Ears']
                .map(
                  (service) => FilterChip(
                    label: Text(service),
                    selected: _groomingServices.contains(service),
                    onSelected: (selected) => setState(() {
                      selected
                          ? _groomingServices.add(service)
                          : _groomingServices.remove(service);
                    }),
                  ),
                )
                .toList(),
          ),
        ]);
      case 'Vet Visit':
        children.addAll([
          field(_vetReasonController, 'Reason for visit', Icons.description),
          const SizedBox(height: 12),
          field(
            _vetClinicController,
            'Clinic or veterinarian',
            Icons.local_hospital,
          ),
        ]);
      case 'Social':
        children.addAll([
          field(
            _socialCompanionController,
            'Who did they socialize with?',
            Icons.pets,
          ),
          const SizedBox(height: 12),
          dropdown(
            _socialSetting,
            'Where?',
            Icons.place_rounded,
            const ['At home', 'Park', 'Daycare', 'Visit'],
            (value) => setState(() => _socialSetting = value),
          ),
        ]);
      case 'Rest':
        children.addAll([
          dropdown(
            _restQuality,
            'Rest quality',
            Icons.bedtime_rounded,
            const ['Settled', 'Restless', 'Deep sleep', 'Nap'],
            (value) => setState(() => _restQuality = value),
          ),
          const SizedBox(height: 12),
          field(_restLocationController, 'Resting spot', Icons.chair_rounded),
        ]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  int? get _selectedDuration {
    if (_durationMode == _DurationMode.none) return null;
    if (_durationMode == _DurationMode.timer) {
      final minutes = (_elapsed.inSeconds / 60).ceil();
      return minutes > 0 ? minutes : null;
    }
    final minutes = _manualDuration ?? 0;
    return minutes > 0 ? minutes : null;
  }

  int _previewPoints(ActivityProvider provider) =>
      ActivityScoring.calculateAward(
        _selectedType,
        durationMinutes: _selectedDuration,
        earnedToday: provider.totalDailyPoints,
      );

  String _pointsExplanation(ActivityProvider provider) {
    final earnedToday = provider.totalDailyPoints;
    final remaining = ActivityScoring.remainingDailyPoints(earnedToday);
    final bonus =
        ActivityScoring.durationBonusPerTenMinutes[_selectedType] ?? 0;
    final cap = ActivityScoring.maxPointsPerActivity[_selectedType];
    if (bonus == 0 || cap == null) {
      return 'Care task reward • $remaining points left today';
    }
    return '+$bonus per 10 min, max $cap • $remaining points left today';
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'Walk':
        return Icons.directions_walk;
      case 'Play':
        return Icons.sports_baseball;
      case 'Train':
        return Icons.school;
      case 'Feed':
        return Icons.restaurant;
      case 'Groom':
        return Icons.content_cut;
      case 'Vet Visit':
        return Icons.local_hospital;
      case 'Social':
        return Icons.groups;
      case 'Rest':
        return Icons.bedtime;
      default:
        return Icons.pets;
    }
  }
}
