import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/pet.dart';
import '../../providers/pet_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/pet_image_pickers.dart';
import '../../widgets/pet_date_picker.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _colorController = TextEditingController();
  final _microchipController = TextEditingController();

  String _species = 'Dog';
  String _gender = 'Male';
  DateTime? _dateOfBirth;
  DateTime? _adoptionDate;
  bool _spayedNeutered = false;
  XFile? _photoFile;
  XFile? _coverPhotoFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _colorController.dispose();
    _microchipController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool cover}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: cover ? 1400 : 800,
      maxHeight: cover ? 800 : 800,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        if (cover) {
          _coverPhotoFile = pickedFile;
        } else {
          _photoFile = pickedFile;
        }
      });
    }
  }

  Future<void> _selectDate(bool isDateOfBirth) async {
    final result = await showPetDatePicker(
      context: context,
      title: isDateOfBirth ? 'Date of Birth' : 'Adoption Date',
      selectedDate: isDateOfBirth ? _dateOfBirth : _adoptionDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );

    if (!mounted || result == null) return;

    setState(() {
      if (isDateOfBirth) {
        _dateOfBirth = result.date;
      } else {
        _adoptionDate = result.date;
      }
    });
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final petProvider = context.read<PetProvider>();
    final now = DateTime.now();

    final pet = Pet(
      id: '',
      userId: '',
      name: _nameController.text.trim(),
      species: _species,
      breed: _breedController.text.trim().isEmpty
          ? null
          : _breedController.text.trim(),
      dateOfBirth: _dateOfBirth,
      gender: _gender,
      weight: _weightController.text.isEmpty
          ? null
          : double.tryParse(_weightController.text),
      colorMarkings: _colorController.text.trim().isEmpty
          ? null
          : _colorController.text.trim(),
      microchipNumber: _microchipController.text.trim().isEmpty
          ? null
          : _microchipController.text.trim(),
      spayedNeutered: _spayedNeutered,
      adoptionDate: _adoptionDate,
      createdAt: now,
      updatedAt: now,
    );

    final success = await petProvider.createPet(
      pet,
      photoFile: _photoFile,
      coverPhotoFile: _coverPhotoFile,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${pet.name} has been added!')));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(petProvider.error ?? 'Failed to add pet'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Pet')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PetCoverPhotoPicker(
              selectedPhoto: _coverPhotoFile,
              existingPhotoUrl: null,
              onTap: () => _pickImage(cover: true),
            ),
            const SizedBox(height: 18),
            PetAvatarPhotoPicker(
              selectedPhoto: _photoFile,
              existingPhotoUrl: null,
              onTap: () => _pickImage(cover: false),
            ),
            const SizedBox(height: 24),

            // Name
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Pet Name *',
                prefixIcon: Icon(Icons.pets),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your pet\'s name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Species dropdown
            DropdownButtonFormField<String>(
              initialValue: _species,
              decoration: const InputDecoration(
                labelText: 'Species *',
                prefixIcon: Icon(Icons.category),
              ),
              items: AppConstants.petSpecies.map((species) {
                return DropdownMenuItem(value: species, child: Text(species));
              }).toList(),
              onChanged: (value) {
                setState(() => _species = value!);
              },
            ),
            const SizedBox(height: 16),

            // Breed
            TextFormField(
              controller: _breedController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Breed',
                prefixIcon: Icon(Icons.pets),
              ),
            ),
            const SizedBox(height: 16),

            // Gender
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(
                labelText: 'Gender *',
                prefixIcon: Icon(Icons.wc),
              ),
              items: ['Male', 'Female', 'Unknown'].map((gender) {
                return DropdownMenuItem(value: gender, child: Text(gender));
              }).toList(),
              onChanged: (value) {
                setState(() => _gender = value!);
              },
            ),
            const SizedBox(height: 16),

            PetDateField(
              labelText: 'Date of Birth',
              emptyText: 'Select date',
              icon: Icons.cake,
              selectedDate: _dateOfBirth,
              onTap: () => _selectDate(true),
              onClear: _dateOfBirth == null
                  ? null
                  : () => setState(() => _dateOfBirth = null),
            ),
            const SizedBox(height: 16),

            // Weight
            TextFormField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                prefixIcon: Icon(Icons.monitor_weight),
              ),
            ),
            const SizedBox(height: 16),

            // Color/Markings
            TextFormField(
              controller: _colorController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Color/Markings',
                prefixIcon: Icon(Icons.palette),
              ),
            ),
            const SizedBox(height: 16),

            // Microchip
            TextFormField(
              controller: _microchipController,
              decoration: const InputDecoration(
                labelText: 'Microchip Number',
                prefixIcon: Icon(Icons.memory),
              ),
            ),
            const SizedBox(height: 16),

            // Spayed/Neutered switch
            SwitchListTile(
              title: const Text('Spayed/Neutered'),
              value: _spayedNeutered,
              onChanged: (value) {
                setState(() => _spayedNeutered = value);
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            const SizedBox(height: 8),

            PetDateField(
              labelText: 'Adoption Date',
              emptyText: 'Select date',
              icon: Icons.home,
              selectedDate: _adoptionDate,
              onTap: () => _selectDate(false),
              onClear: _adoptionDate == null
                  ? null
                  : () => setState(() => _adoptionDate = null),
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _savePet,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Add Pet'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
