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

class AddGroomingScreen extends StatefulWidget {
  const AddGroomingScreen({super.key});

  @override
  State<AddGroomingScreen> createState() => _AddGroomingScreenState();
}

class _AddGroomingScreenState extends State<AddGroomingScreen> {
  final _notesController = TextEditingController();
  final _groomerController = TextEditingController();
  final _costController = TextEditingController();

  final MedicalService _medicalService = MedicalService();

  Pet? _selectedPet;
  DateTime _groomingDate = DateTime.now();
  DateTime? _nextAppointment;
  final Set<String> _selectedServices = {'Bath'};
  bool _isLoading = false;

  final List<Map<String, dynamic>> _groomingServices = [
    {'name': 'Bath'},
    {'name': 'Haircut'},
    {'name': 'Nail Trim'},
    {'name': 'Ear Cleaning'},
    {'name': 'Teeth Brushing'},
    {'name': 'Deshedding'},
    {'name': 'Flea Treatment'},
    {'name': 'Full Groom'},
  ];

  @override
  void dispose() {
    _notesController.dispose();
    _groomerController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isGroomingDate) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isGroomingDate
          ? _groomingDate
          : (_nextAppointment ?? DateTime.now().add(const Duration(days: 30))),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        if (isGroomingDate) {
          _groomingDate = pickedDate;
        } else {
          _nextAppointment = pickedDate;
        }
      });
    }
  }

  Future<void> _saveGrooming() async {
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

    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one service'),
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
      final servicesTitle = _selectedServices.length == 1
          ? _selectedServices.first
          : '${_selectedServices.length} services';

      final record = MedicalRecord(
        id: '',
        petId: _selectedPet!.id,
        type: MedicalRecordType.groomingVisit,
        title: servicesTitle,
        description: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        date: _groomingDate,
        nextDueDate: _nextAppointment,
        provider: _groomerController.text.trim().isEmpty
            ? null
            : _groomerController.text.trim(),
        metadata: {
          'services': _selectedServices.toList(),
          'cost': _costController.text.trim(),
        },
        createdAt: now,
        updatedAt: now,
      );

      await _medicalService.createMedicalRecord(record);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Grooming session saved!'),
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
          'Add Grooming',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header icon
          ActivityIcon(
            type: 'Groom',
            size: 40,
            showBorder: false,
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),

          // Pet selector
          _buildSectionLabel('Select Pet'),
          const SizedBox(height: 12),
          _buildPetSelector(petProvider),
          const SizedBox(height: 24),

          // Services
          _buildSectionLabel('Services'),
          const SizedBox(height: 12),
          _buildServicesGrid(),
          const SizedBox(height: 24),

          // Date
          _buildSectionLabel('Date'),
          const SizedBox(height: 12),
          _buildResponsivePair(
            left: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Grooming Date',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                _buildDatePicker(_groomingDate, () => _selectDate(true)),
              ],
            ),
            right: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next Appointment',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                _buildDatePicker(
                  _nextAppointment,
                  () => _selectDate(false),
                  isOptional: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Groomer
          _buildSectionLabel('Groomer / Salon (Optional)'),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _groomerController,
            hint: 'Where did you go?',
            icon: Icons.store_rounded,
          ),
          const SizedBox(height: 24),

          // Cost
          _buildSectionLabel('Cost (Optional)'),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _costController,
            hint: '\$0.00',
            icon: Icons.attach_money_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),

          // Notes
          _buildSectionLabel('Notes (Optional)'),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _notesController,
            hint: 'Any details about the grooming session...',
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),
          const SizedBox(height: 32),

          // Save button
          Semantics(
            button: true,
            label: 'Save Grooming',
            child: InkWell(
              onTap: _isLoading ? null : _saveGrooming,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: AppTheme.actionBlueGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.coloredShadow(AppTheme.actionBlue),
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
                          'Save Grooming',
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

  Widget _buildServicesGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _groomingServices.map((service) {
        final isSelected = _selectedServices.contains(service['name']);
        return Semantics(
          label: '${service['name']} service',
          selected: isSelected,
          button: true,
          child: InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedServices.remove(service['name']);
                } else {
                  _selectedServices.add(service['name']);
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accentPeach : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppTheme.accentPeach : Colors.black,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ActivityIcon(
                    type: service['name'],
                    size: 16,
                    showBorder: false,
                    isActive: isSelected,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    service['name'],
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
    TextInputType? keyboardType,
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
        keyboardType: keyboardType,
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
          : (isOptional ? 'Next appointment: Not set' : 'Select date'),
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
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  date != null
                      ? DateFormat('MMM d, y').format(date)
                      : (isOptional ? 'Not set' : 'Select'),
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
