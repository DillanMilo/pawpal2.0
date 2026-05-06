import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/activity.dart';
import '../../models/pet.dart';
import '../../providers/activity_provider.dart';
import '../../providers/pet_provider.dart';
import '../../utils/constants.dart';
import '../../utils/activity_scoring.dart';
import '../../utils/theme.dart';

class LogActivityScreen extends StatefulWidget {
  final String? initialType;
  final Pet? pet;

  const LogActivityScreen({super.key, this.initialType, this.pet});

  @override
  State<LogActivityScreen> createState() => _LogActivityScreenState();
}

class _LogActivityScreenState extends State<LogActivityScreen> {
  final _notesController = TextEditingController();

  late String _selectedType;
  Pet? _selectedPet;
  bool _useTimer = false;
  DateTime? _startTime;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  int? _manualDuration;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? 'Walk';
    _selectedPet = widget.pet;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _useTimer = true;
      _startTime = DateTime.now();
      _elapsed = Duration.zero;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
    final now = DateTime.now();
    final startTime = _startTime ?? now;
    final duration = _useTimer
        ? (_elapsed.inSeconds / 60).ceil()
        : (_manualDuration ?? 0);

    final earnedPoints = ActivityScoring.calculatePoints(
      _selectedType,
      durationMinutes: duration,
    );

    final activity = Activity(
      id: '',
      petId: _selectedPet!.id,
      userId: '',
      type: _selectedType,
      startTime: startTime,
      endTime: now,
      durationMinutes: duration > 0 ? duration : null,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      points: earnedPoints,
      createdAt: now,
    );

    final success = await activityProvider.logActivity(activity);

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+$earnedPoints points earned!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(activityProvider.error ?? 'Failed to log activity'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();

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
              return FilterChip(
                selected: isSelected,
                label: Text(type),
                avatar: Icon(
                  _getActivityIcon(type),
                  size: 18,
                  color: isSelected ? Colors.white : color,
                ),
                selectedColor: color,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
                onSelected: (selected) {
                  setState(() => _selectedType = type);
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
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: petProvider.pets.map((pet) {
                final isSelected = pet.id == _selectedPet?.id;
                return FilterChip(
                  selected: isSelected,
                  label: Text(pet.name),
                  avatar: const Icon(Icons.pets, size: 18),
                  selectedColor: AppTheme.primaryColor,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                  ),
                  onSelected: (selected) {
                    setState(() => _selectedPet = pet);
                  },
                );
              }).toList(),
            ),
          const SizedBox(height: 24),

          // Duration section
          const Text(
            'Duration',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),

          // Timer card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_useTimer && _startTime != null) ...[
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
                  ] else ...[
                    // Start timer or manual entry
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final startTimerButton = OutlinedButton.icon(
                          onPressed: _startTimer,
                          icon: const Icon(Icons.timer),
                          label: const Text('Start Timer'),
                        );
                        final minutesField = TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Minutes',
                            isDense: true,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _manualDuration = int.tryParse(value);
                            });
                          },
                        );

                        if (constraints.maxWidth < 360) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              startTimerButton,
                              const SizedBox(height: 12),
                              const Center(child: Text('or')),
                              const SizedBox(height: 12),
                              minutesField,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: startTimerButton),
                            const SizedBox(width: 12),
                            const Text('or'),
                            const SizedBox(width: 12),
                            Expanded(child: minutesField),
                          ],
                        );
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
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
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
                        const Text(
                          'Points you\'ll earn',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        Text(
                          '+$_previewPoints points',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _pointsExplanation,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
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
              foregroundColor: Colors.white,
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

  int get _previewDuration {
    if (_useTimer) return (_elapsed.inSeconds / 60).ceil();
    return _manualDuration ?? 0;
  }

  int get _previewPoints => ActivityScoring.calculatePoints(
    _selectedType,
    durationMinutes: _previewDuration,
  );

  String get _pointsExplanation {
    final bonus =
        ActivityScoring.durationBonusPerTenMinutes[_selectedType] ?? 0;
    final cap = ActivityScoring.maxPointsPerActivity[_selectedType];
    if (bonus == 0 || cap == null) {
      return 'Care task reward';
    }
    return '+$bonus per 10 min, capped at $cap';
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
