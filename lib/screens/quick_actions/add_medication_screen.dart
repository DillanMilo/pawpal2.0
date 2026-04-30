import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/medical_record.dart';
import '../../models/pet.dart';
import '../../providers/pet_provider.dart';
import '../../services/medical_service.dart';
import '../../utils/theme.dart';
import '../../widgets/activity_icon.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _notesController = TextEditingController();
  final _providerController = TextEditingController();

  final MedicalService _medicalService = MedicalService();

  Pet? _selectedPet;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _notesController.dispose();
    _providerController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStartDate) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a pet'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final record = MedicalRecord(
        id: '',
        petId: _selectedPet!.id,
        type: MedicalRecordType.medication,
        title: _nameController.text.trim(),
        description: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        date: _startDate,
        endDate: _endDate,
        provider: _providerController.text.trim().isEmpty
            ? null
            : _providerController.text.trim(),
        dosage: _dosageController.text.trim().isEmpty
            ? null
            : _dosageController.text.trim(),
        frequency: _frequencyController.text.trim().isEmpty
            ? null
            : _frequencyController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );

      await _medicalService.createMedicalRecord(record);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Medication added successfully!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();

    if (_selectedPet == null && petProvider.pets.isNotEmpty) {
      _selectedPet = petProvider.selectedPet ?? petProvider.pets.first;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          tooltip: 'Go back',
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: AppTheme.thickBorder,
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        title: const Text(
          'Add Medication',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Header icon
            ActivityIcon(
              type: 'Medication',
              size: 40,
              showBorder: false,
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),

            // Pet selector
            _buildSectionLabel('Select Pet'),
            const SizedBox(height: 12),
            _buildPetSelector(petProvider),
            const SizedBox(height: 24),

            // Medication name
            _buildSectionLabel('Medication Name'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nameController,
              hint: 'e.g., Heartgard, Apoquel',
              icon: Icons.medication_rounded,
              validator: (value) => value?.isEmpty == true
                  ? 'Please enter medication name'
                  : null,
            ),
            const SizedBox(height: 24),

            // Dosage & Frequency
            _buildResponsivePair(
              left: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('Dosage'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _dosageController,
                    hint: 'e.g., 10mg',
                    icon: Icons.scale_rounded,
                  ),
                ],
              ),
              right: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('Frequency'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _frequencyController,
                    hint: 'e.g., Twice daily',
                    icon: Icons.repeat_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Date range
            _buildResponsivePair(
              left: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('Start Date'),
                  const SizedBox(height: 12),
                  _buildDatePicker(_startDate, () => _selectDate(true)),
                ],
              ),
              right: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('End Date'),
                  const SizedBox(height: 12),
                  _buildDatePicker(
                    _endDate,
                    () => _selectDate(false),
                    isOptional: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Provider
            _buildSectionLabel('Prescribed By (Optional)'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _providerController,
              hint: 'Vet clinic or doctor name',
              icon: Icons.local_hospital_rounded,
            ),
            const SizedBox(height: 24),

            // Notes
            _buildSectionLabel('Notes (Optional)'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _notesController,
              hint: 'Any additional information...',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Save button
            Semantics(
              button: true,
              label: 'Save Medication',
              child: InkWell(
                onTap: _isLoading ? null : _saveMedication,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: AppTheme.playfulGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.coloredShadow(AppTheme.primaryColor),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Save Medication',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildPetSelector(PetProvider petProvider) {
    if (petProvider.pets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: AppTheme.thickBorder,
        ),
        child: const Text(
          'No pets added yet. Add a pet first!',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: petProvider.pets.map((pet) {
        final isSelected = pet.id == _selectedPet?.id;
        return Semantics(
          label: 'Select ${pet.name}',
          selected: isSelected,
          button: true,
          child: InkWell(
            onTap: () => setState(() => _selectedPet = pet),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: AppTheme.thickBorder,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppTheme.primaryColor.withValues(alpha: 0.1),
                    backgroundImage: pet.photoUrl != null
                        ? NetworkImage(pet.photoUrl!)
                        : null,
                    child: pet.photoUrl == null
                        ? Icon(
                            Icons.pets,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.primaryColor,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    pet.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: AppTheme.thickBorder,
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textLight),
          prefixIcon: Icon(icon, color: AppTheme.primaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildResponsivePair({required Widget left, required Widget right}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(children: [left, const SizedBox(height: 16), right]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 16),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  Widget _buildDatePicker(
    DateTime? date,
    VoidCallback onTap, {
    bool isOptional = false,
  }) {
    return Semantics(
      button: true,
      label: date != null
          ? 'Selected date: ${DateFormat('MMM d, y').format(date)}'
          : (isOptional ? 'End date: Ongoing' : 'Select date'),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: AppTheme.thickBorder,
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  date != null
                      ? DateFormat('MMM d, y').format(date)
                      : (isOptional ? 'Ongoing' : 'Select'),
                  style: TextStyle(
                    color: date != null
                        ? AppTheme.textPrimary
                        : AppTheme.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
