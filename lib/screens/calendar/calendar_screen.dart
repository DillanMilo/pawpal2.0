import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../models/pet.dart';
import '../../services/appointment_service.dart';
import '../../services/pet_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final PetService _petService = PetService();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<Appointment> _appointments = [];
  List<Pet> _pets = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _appointmentService.getAppointments(),
        _petService.getPets(),
      ]);

      if (!mounted) return;
      setState(() {
        _appointments = results[0] as List<Appointment>;
        _pets = results[1] as List<Pet>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Unable to load appointments.';
      });
    }
  }

  List<Appointment> _appointmentsForDay(DateTime day) {
    return _appointments
        .where((appointment) => isSameDay(appointment.dateTime, day))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<void> _showAppointmentSheet({Appointment? appointment}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AppointmentSheet(
        appointment: appointment,
        pets: _pets,
        initialDate: appointment?.dateTime ?? _selectedDay,
        appointmentService: _appointmentService,
      ),
    );

    if (result == true) {
      await _loadCalendarData();
    }
  }

  Future<void> _deleteAppointment(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: Text('Delete "${appointment.title}" from your calendar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _appointmentService.deleteAppointment(appointment.id);
      await _loadCalendarData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Appointment deleted')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete appointment')),
        );
      }
    }
  }

  Future<void> _toggleCompleted(Appointment appointment) async {
    try {
      final updated = appointment.copyWith(
        isCompleted: !appointment.isCompleted,
      );
      await _appointmentService.updateAppointment(updated);
      await _loadCalendarData();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update appointment')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final selectedAppointments = _appointmentsForDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh appointments',
            onPressed: _loadCalendarData,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add appointment',
            onPressed: () => _showAppointmentSheet(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCalendarData,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 124 + bottomInset),
              children: [
                _buildCalendarCard(),
                const SizedBox(height: 16),
                _buildSelectedDayHeader(selectedAppointments.length),
                const SizedBox(height: 12),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  _buildMessageState(
                    icon: Icons.error_outline_rounded,
                    title: 'Calendar unavailable',
                    subtitle: _error!,
                    actionLabel: 'Retry',
                    onAction: _loadCalendarData,
                  )
                else if (selectedAppointments.isEmpty)
                  _buildMessageState(
                    icon: Icons.event_available_rounded,
                    title: 'No appointments',
                    subtitle: 'Tap + to schedule something for this day.',
                    actionLabel: 'Add Appointment',
                    onAction: () => _showAppointmentSheet(),
                  )
                else
                  ...selectedAppointments.map(_buildAppointmentCard),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 88 + bottomInset),
        child: FloatingActionButton(
          onPressed: () => _showAppointmentSheet(),
          tooltip: 'Add appointment',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        child: TableCalendar<Appointment>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: _appointmentsForDay,
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonShowsNext: false,
            titleTextStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
            formatButtonDecoration: BoxDecoration(
              color: AppTheme.softLavender,
              borderRadius: BorderRadius.circular(14),
            ),
            formatButtonTextStyle: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w700,
            ),
            leftChevronIcon: const Icon(
              Icons.chevron_left,
              color: AppTheme.inkColor,
            ),
            rightChevronIcon: const Icon(
              Icons.chevron_right,
              color: AppTheme.inkColor,
            ),
          ),
          calendarStyle: CalendarStyle(
            selectedDecoration: const BoxDecoration(
              color: AppTheme.inkColor,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.28),
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: AppTheme.accentLavender,
              shape: BoxShape.circle,
            ),
            outsideDaysVisible: false,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDayHeader(int count) {
    return Row(
      children: [
        Expanded(
          child: Text(
            DateFormat('EEEE, MMMM d').format(_selectedDay),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.softLavender,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final pet = appointment.petId == null
        ? null
        : _pets.where((pet) => pet.id == appointment.petId).firstOrNull;
    final isPast = appointment.dateTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showAppointmentSheet(appointment: appointment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _appointmentColor(
                    appointment.type,
                  ).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _appointmentIcon(appointment.type),
                  color: _appointmentColor(appointment.type),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            appointment.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: appointment.isCompleted
                                  ? AppTheme.textLight
                                  : AppTheme.textPrimary,
                              decoration: appointment.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (appointment.isCompleted)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.successColor,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        DateFormat('h:mm a').format(appointment.dateTime),
                        appointment.type,
                        if (pet != null) pet.name,
                      ].join(' • '),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (appointment.provider?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        appointment.provider!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textLight),
                      ),
                    ],
                    if (appointment.notes?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        appointment.notes!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Appointment actions',
                onSelected: (value) {
                  if (value == 'edit') {
                    _showAppointmentSheet(appointment: appointment);
                  }
                  if (value == 'complete') {
                    _toggleCompleted(appointment);
                  }
                  if (value == 'delete') {
                    _deleteAppointment(appointment);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'complete',
                    child: Text(
                      appointment.isCompleted
                          ? 'Mark incomplete'
                          : isPast
                          ? 'Mark complete'
                          : 'Mark complete',
                    ),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 40),
      child: Column(
        children: [
          Icon(
            icon,
            size: 56,
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add_rounded),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  IconData _appointmentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'vet':
        return Icons.local_hospital_rounded;
      case 'grooming':
        return Icons.content_cut_rounded;
      case 'training':
        return Icons.school_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  Color _appointmentColor(String type) {
    switch (type.toLowerCase()) {
      case 'vet':
        return AppTheme.errorColor;
      case 'grooming':
        return AppTheme.accentPeach;
      case 'training':
        return AppTheme.primaryColor;
      default:
        return AppTheme.secondaryColor;
    }
  }
}

class _AppointmentSheet extends StatefulWidget {
  final Appointment? appointment;
  final List<Pet> pets;
  final DateTime initialDate;
  final AppointmentService appointmentService;

  const _AppointmentSheet({
    this.appointment,
    required this.pets,
    required this.initialDate,
    required this.appointmentService,
  });

  @override
  State<_AppointmentSheet> createState() => _AppointmentSheetState();
}

class _AppointmentSheetState extends State<_AppointmentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _providerController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;
  late String _type;
  late DateTime _date;
  late TimeOfDay _time;
  String? _petId;
  int? _reminderMinutesBefore;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final appointment = widget.appointment;
    final initialDate = appointment?.dateTime ?? widget.initialDate;

    _titleController = TextEditingController(text: appointment?.title ?? '');
    _providerController = TextEditingController(
      text: appointment?.provider ?? '',
    );
    _addressController = TextEditingController(
      text: appointment?.providerAddress ?? '',
    );
    _notesController = TextEditingController(text: appointment?.notes ?? '');
    _type = appointment?.type ?? AppConstants.appointmentTypes.first;
    _date = initialDate;
    _time = TimeOfDay.fromDateTime(initialDate);
    _petId = appointment?.petId;
    _reminderMinutesBefore = appointment?.reminderMinutesBefore;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _providerController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final now = DateTime.now();
    final dateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    final existing = widget.appointment;
    final appointment = Appointment(
      id: existing?.id ?? '',
      userId: existing?.userId ?? '',
      petId: _petId,
      type: _type,
      title: _titleController.text.trim(),
      dateTime: dateTime,
      provider: _emptyToNull(_providerController.text),
      providerAddress: _emptyToNull(_addressController.text),
      notes: _emptyToNull(_notesController.text),
      reminderMinutesBefore: _reminderMinutesBefore,
      isCompleted: existing?.isCompleted ?? false,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      if (existing == null) {
        await widget.appointmentService.createAppointment(appointment);
      } else {
        await widget.appointmentService.updateAppointment(appointment);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save appointment')),
        );
      }
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final dateLabel = DateFormat('EEE, MMM d, yyyy').format(_date);
    final timeLabel = _time.format(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: viewInsets > 0 ? viewInsets : 96 + bottomPadding,
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 720),
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 18 + bottomPadding),
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.dividerColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      widget.appointment == null
                          ? 'New Appointment'
                          : 'Edit Appointment',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        prefixIcon: Icon(Icons.category_rounded),
                      ),
                      items: AppConstants.appointmentTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _type = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    if (widget.pets.isNotEmpty) ...[
                      DropdownButtonFormField<String?>(
                        initialValue: _petId,
                        decoration: const InputDecoration(
                          labelText: 'Pet',
                          prefixIcon: Icon(Icons.pets_rounded),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('No specific pet'),
                          ),
                          ...widget.pets.map(
                            (pet) => DropdownMenuItem<String?>(
                              value: pet.id,
                              child: Text(pet.name),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() => _petId = value),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectDate,
                            icon: const Icon(Icons.calendar_today_rounded),
                            label: Text(
                              dateLabel,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectTime,
                            icon: const Icon(Icons.schedule_rounded),
                            label: Text(timeLabel),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _providerController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Provider',
                        prefixIcon: Icon(Icons.business_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _addressController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        prefixIcon: Icon(Icons.location_on_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int?>(
                      initialValue: _reminderMinutesBefore,
                      decoration: const InputDecoration(
                        labelText: 'Reminder',
                        prefixIcon: Icon(Icons.notifications_rounded),
                      ),
                      items: const [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text('No reminder'),
                        ),
                        DropdownMenuItem(
                          value: 15,
                          child: Text('15 minutes before'),
                        ),
                        DropdownMenuItem(
                          value: 60,
                          child: Text('1 hour before'),
                        ),
                        DropdownMenuItem(
                          value: 1440,
                          child: Text('1 day before'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _reminderMinutesBefore = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _notesController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppTheme.backgroundColor,
                  border: Border(top: BorderSide(color: AppTheme.dividerColor)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            widget.appointment == null
                                ? 'Save Appointment'
                                : 'Update Appointment',
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
