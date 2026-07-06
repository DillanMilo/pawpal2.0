import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/medical_record.dart';
import '../../services/medical_service.dart';
import '../../utils/theme.dart';

class AddMedicalRecordScreen extends StatefulWidget {
  final String petId;
  final MedicalRecordType? initialType;
  final MedicalRecord? existingRecord;

  const AddMedicalRecordScreen({
    super.key,
    required this.petId,
    this.initialType,
    this.existingRecord,
  });

  @override
  State<AddMedicalRecordScreen> createState() => _AddMedicalRecordScreenState();
}

class _AddMedicalRecordScreenState extends State<AddMedicalRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _providerController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();

  final MedicalService _medicalService = MedicalService();

  late MedicalRecordType _selectedType;
  DateTime _date = DateTime.now();
  DateTime? _endDate;
  DateTime? _nextDueDate;
  bool _isLoading = false;

  bool get _isEditing => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    final record = widget.existingRecord;
    if (record != null) {
      _selectedType = record.type;
      _titleController.text = record.title;
      _descriptionController.text = record.description ?? '';
      _providerController.text = record.provider ?? '';
      _dosageController.text = record.dosage ?? '';
      _frequencyController.text = record.frequency ?? '';
      _date = record.date;
      _endDate = record.endDate;
      _nextDueDate = record.nextDueDate;
    } else {
      _selectedType = widget.initialType ?? MedicalRecordType.vaccination;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _providerController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(String field) async {
    DateTime initialDate;
    switch (field) {
      case 'date':
        initialDate = _date;
        break;
      case 'endDate':
        initialDate = _endDate ?? DateTime.now();
        break;
      case 'nextDueDate':
        initialDate =
            _nextDueDate ?? DateTime.now().add(const Duration(days: 30));
        break;
      default:
        initialDate = DateTime.now();
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        switch (field) {
          case 'date':
            _date = pickedDate;
            break;
          case 'endDate':
            _endDate = pickedDate;
            break;
          case 'nextDueDate':
            _nextDueDate = pickedDate;
            break;
        }
      });
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final record = MedicalRecord(
        id: _isEditing ? widget.existingRecord!.id : '',
        petId: widget.petId,
        type: _selectedType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        date: _date,
        endDate: _endDate,
        nextDueDate: _nextDueDate,
        provider: _providerController.text.trim().isEmpty
            ? null
            : _providerController.text.trim(),
        dosage: _dosageController.text.trim().isEmpty
            ? null
            : _dosageController.text.trim(),
        frequency: _frequencyController.text.trim().isEmpty
            ? null
            : _frequencyController.text.trim(),
        documentUrl: _isEditing ? widget.existingRecord!.documentUrl : null,
        metadata: _isEditing ? widget.existingRecord!.metadata : null,
        createdAt: _isEditing ? widget.existingRecord!.createdAt : now,
        updatedAt: now,
      );

      if (_isEditing) {
        await _medicalService.updateMedicalRecord(record);
      } else {
        await _medicalService.createMedicalRecord(record);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Record updated successfully'
                  : 'Record added successfully',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Medical Record' : 'Add Medical Record'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Record type selector
            const Text(
              'Record Type',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MedicalRecordType.values.map((type) {
                final isSelected = type == _selectedType;
                return FilterChip(
                  selected: isSelected,
                  label: Text(_getTypeName(type)),
                  avatar: Icon(
                    _getTypeIcon(type),
                    size: 18,
                    color: isSelected ? Colors.white : _getTypeColor(type),
                  ),
                  selectedColor: _getTypeColor(type),
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

            // Title
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: _getTitleLabel(),
                prefixIcon: Icon(_getTypeIcon(_selectedType)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date
            InkWell(
              onTap: () => _selectDate('date'),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(DateFormat('MMMM d, y').format(_date)),
              ),
            ),
            const SizedBox(height: 16),

            // Provider
            TextFormField(
              controller: _providerController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Provider/Clinic',
                prefixIcon: Icon(Icons.local_hospital),
              ),
            ),
            const SizedBox(height: 16),

            // Conditional fields based on type
            if (_selectedType == MedicalRecordType.medication) ...[
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  prefixIcon: Icon(Icons.medication),
                  hintText: 'e.g., 10mg',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _frequencyController,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  prefixIcon: Icon(Icons.repeat),
                  hintText: 'e.g., Twice daily',
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate('endDate'),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'End Date (Optional)',
                    prefixIcon: const Icon(Icons.event_busy),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_endDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear end date',
                            onPressed: () => setState(() => _endDate = null),
                          ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                  child: Text(
                    _endDate != null
                        ? DateFormat('MMMM d, y').format(_endDate!)
                        : 'Ongoing',
                    style: TextStyle(
                      color: _endDate != null
                          ? AppTheme.textPrimary
                          : AppTheme.textLight,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_selectedType == MedicalRecordType.vaccination) ...[
              InkWell(
                onTap: () => _selectDate('nextDueDate'),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Next Due Date (Optional)',
                    prefixIcon: const Icon(Icons.event),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_nextDueDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear next due date',
                            onPressed: () =>
                                setState(() => _nextDueDate = null),
                          ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                  child: Text(
                    _nextDueDate != null
                        ? DateFormat('MMMM d, y').format(_nextDueDate!)
                        : 'Not set',
                    style: TextStyle(
                      color: _nextDueDate != null
                          ? AppTheme.textPrimary
                          : AppTheme.textLight,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Notes
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveRecord,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(_isEditing ? 'Update Record' : 'Save Record'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getTitleLabel() {
    switch (_selectedType) {
      case MedicalRecordType.vaccination:
        return 'Vaccine Name';
      case MedicalRecordType.medication:
        return 'Medication Name';
      case MedicalRecordType.allergy:
        return 'Allergy';
      case MedicalRecordType.condition:
        return 'Condition Name';
      case MedicalRecordType.vetVisit:
        return 'Visit Reason';
      case MedicalRecordType.groomingVisit:
        return 'Service Type';
      case MedicalRecordType.surgery:
        return 'Procedure Name';
      case MedicalRecordType.labResult:
        return 'Test Name';
    }
  }

  String _getTypeName(MedicalRecordType type) {
    switch (type) {
      case MedicalRecordType.vaccination:
        return 'Vaccination';
      case MedicalRecordType.medication:
        return 'Medication';
      case MedicalRecordType.allergy:
        return 'Allergy';
      case MedicalRecordType.condition:
        return 'Condition';
      case MedicalRecordType.vetVisit:
        return 'Vet Visit';
      case MedicalRecordType.groomingVisit:
        return 'Grooming';
      case MedicalRecordType.surgery:
        return 'Surgery';
      case MedicalRecordType.labResult:
        return 'Lab Result';
    }
  }

  IconData _getTypeIcon(MedicalRecordType type) {
    switch (type) {
      case MedicalRecordType.vaccination:
        return Icons.vaccines;
      case MedicalRecordType.medication:
        return Icons.medication;
      case MedicalRecordType.allergy:
        return Icons.warning_amber;
      case MedicalRecordType.condition:
        return Icons.healing;
      case MedicalRecordType.vetVisit:
        return Icons.local_hospital;
      case MedicalRecordType.groomingVisit:
        return Icons.content_cut;
      case MedicalRecordType.surgery:
        return Icons.medical_services;
      case MedicalRecordType.labResult:
        return Icons.science;
    }
  }

  Color _getTypeColor(MedicalRecordType type) {
    switch (type) {
      case MedicalRecordType.vaccination:
        return Colors.blue;
      case MedicalRecordType.medication:
        return Colors.purple;
      case MedicalRecordType.allergy:
        return Colors.orange;
      case MedicalRecordType.condition:
        return Colors.red;
      case MedicalRecordType.vetVisit:
        return Colors.teal;
      case MedicalRecordType.groomingVisit:
        return Colors.pink;
      case MedicalRecordType.surgery:
        return Colors.red;
      case MedicalRecordType.labResult:
        return Colors.green;
    }
  }
}
