import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/medical_record.dart';
import '../../models/pet.dart';
import '../../providers/pet_provider.dart';
import '../../services/medical_service.dart';
import '../../utils/theme.dart';

class AddVetVisitScreen extends StatefulWidget {
  const AddVetVisitScreen({super.key});

  @override
  State<AddVetVisitScreen> createState() => _AddVetVisitScreenState();
}

class _AddVetVisitScreenState extends State<AddVetVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _clinicController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();

  final MedicalService _medicalService = MedicalService();

  Pet? _selectedPet;
  DateTime _visitDate = DateTime.now();
  DateTime? _followUpDate;
  String _visitType = 'Checkup';
  bool _isLoading = false;

  final List<String> _visitTypes = [
    'Checkup',
    'Vaccination',
    'Illness',
    'Injury',
    'Surgery',
    'Emergency',
    'Dental',
    'Other',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    _clinicController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isVisitDate) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isVisitDate ? _visitDate : (_followUpDate ?? DateTime.now().add(const Duration(days: 30))),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        if (isVisitDate) {
          _visitDate = pickedDate;
        } else {
          _followUpDate = pickedDate;
        }
      });
    }
  }

  Future<void> _saveVetVisit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a pet'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        type: MedicalRecordType.vetVisit,
        title: _reasonController.text.trim(),
        description: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        date: _visitDate,
        nextDueDate: _followUpDate,
        provider: _clinicController.text.trim().isEmpty ? null : _clinicController.text.trim(),
        metadata: {
          'visit_type': _visitType,
          'diagnosis': _diagnosisController.text.trim(),
        },
        createdAt: now,
        updatedAt: now,
      );

      await _medicalService.createMedicalRecord(record);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vet visit recorded successfully!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: AppTheme.thickBorder,
            ),
            child: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          ),
        ),
        title: const Text(
          'Add Vet Visit',
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🏥', style: TextStyle(fontSize: 40)),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),

            // Pet selector
            _buildSectionLabel('Select Pet'),
            const SizedBox(height: 12),
            _buildPetSelector(petProvider),
            const SizedBox(height: 24),

            // Visit type
            _buildSectionLabel('Visit Type'),
            const SizedBox(height: 12),
            _buildVisitTypeSelector(),
            const SizedBox(height: 24),

            // Reason for visit
            _buildSectionLabel('Reason for Visit'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _reasonController,
              hint: 'e.g., Annual checkup, Limping',
              icon: Icons.description_rounded,
              validator: (value) => value?.isEmpty == true ? 'Please enter reason for visit' : null,
            ),
            const SizedBox(height: 24),

            // Clinic name
            _buildSectionLabel('Vet Clinic'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _clinicController,
              hint: 'Clinic or hospital name',
              icon: Icons.local_hospital_rounded,
            ),
            const SizedBox(height: 24),

            // Date pickers
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('Visit Date'),
                      const SizedBox(height: 12),
                      _buildDatePicker(_visitDate, () => _selectDate(true)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('Follow-up'),
                      const SizedBox(height: 12),
                      _buildDatePicker(_followUpDate, () => _selectDate(false), isOptional: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Diagnosis
            _buildSectionLabel('Diagnosis (Optional)'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _diagnosisController,
              hint: 'What did the vet find?',
              icon: Icons.medical_information_rounded,
            ),
            const SizedBox(height: 24),

            // Notes
            _buildSectionLabel('Notes (Optional)'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _notesController,
              hint: 'Treatment, prescriptions, recommendations...',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Save button
            GestureDetector(
              onTap: _isLoading ? null : _saveVetVisit,
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Vet Visit',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
        return GestureDetector(
          onTap: () => setState(() => _selectedPet = pet),
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
                  backgroundColor: isSelected ? Colors.white.withOpacity(0.2) : AppTheme.primaryColor.withOpacity(0.1),
                  backgroundImage: pet.photoUrl != null ? NetworkImage(pet.photoUrl!) : null,
                  child: pet.photoUrl == null
                      ? Icon(Icons.pets, size: 16, color: isSelected ? Colors.white : AppTheme.primaryColor)
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
        );
      }).toList(),
    );
  }

  Widget _buildVisitTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _visitTypes.map((type) {
        final isSelected = type == _visitType;
        return GestureDetector(
          onTap: () => setState(() => _visitType = type),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.black,
                width: 2,
              ),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDatePicker(DateTime? date, VoidCallback onTap, {bool isOptional = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: AppTheme.thickBorder,
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                date != null ? DateFormat('MMM d, y').format(date) : (isOptional ? 'Not set' : 'Select'),
                style: TextStyle(
                  color: date != null ? AppTheme.textPrimary : AppTheme.textLight,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
