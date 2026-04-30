import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/pet.dart';
import '../../providers/pet_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

class EditPetScreen extends StatefulWidget {
  final String petId;

  const EditPetScreen({super.key, required this.petId});

  @override
  State<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends State<EditPetScreen> {
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
  File? _newPhotoFile;
  String? _existingPhotoUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  Pet? _pet;

  @override
  void initState() {
    super.initState();
    _loadPet();
  }

  Future<void> _loadPet() async {
    final petProvider = context.read<PetProvider>();
    final pet = await petProvider.getPet(widget.petId);

    if (pet != null) {
      setState(() {
        _pet = pet;
        _nameController.text = pet.name;
        _breedController.text = pet.breed ?? '';
        _weightController.text = pet.weight?.toString() ?? '';
        _colorController.text = pet.colorMarkings ?? '';
        _microchipController.text = pet.microchipNumber ?? '';
        _species = pet.species;
        _gender = pet.gender;
        _dateOfBirth = pet.dateOfBirth;
        _adoptionDate = pet.adoptionDate;
        _spayedNeutered = pet.spayedNeutered;
        _existingPhotoUrl = pet.photoUrl;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _colorController.dispose();
    _microchipController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _newPhotoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(bool isDateOfBirth) async {
    final initialDate = isDateOfBirth
        ? (_dateOfBirth ?? DateTime.now())
        : (_adoptionDate ?? DateTime.now());

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        if (isDateOfBirth) {
          _dateOfBirth = pickedDate;
        } else {
          _adoptionDate = pickedDate;
        }
      });
    }
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate() || _pet == null) return;

    setState(() => _isSaving = true);

    final petProvider = context.read<PetProvider>();

    final updatedPet = _pet!.copyWith(
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
      updatedAt: DateTime.now(),
    );

    final success = await petProvider.updatePet(
      updatedPet,
      photoFile: _newPhotoFile,
    );

    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${updatedPet.name} has been updated!')),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(petProvider.error ?? 'Failed to update pet'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Pet')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_pet == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Pet')),
        body: const Center(child: Text('Pet not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Edit ${_pet!.name}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo picker
            Center(
              child: Semantics(
                label: 'Change pet photo',
                button: true,
                child: InkWell(
                  onTap: _pickImage,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.dividerColor,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: _newPhotoFile != null
                          ? Image.file(_newPhotoFile!, fit: BoxFit.cover)
                          : _existingPhotoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: _existingPhotoUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Icon(
                                Icons.pets,
                                size: 40,
                                color: AppTheme.textLight,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 32,
                                  color: AppTheme.textLight,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Add Photo',
                                  style: TextStyle(
                                    color: AppTheme.textLight,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
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

            // Date of Birth
            InkWell(
              onTap: () => _selectDate(true),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  prefixIcon: Icon(Icons.cake),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _dateOfBirth != null
                      ? DateFormat('MMMM d, y').format(_dateOfBirth!)
                      : 'Select date',
                  style: TextStyle(
                    color: _dateOfBirth != null
                        ? AppTheme.textPrimary
                        : AppTheme.textLight,
                  ),
                ),
              ),
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

            // Adoption date
            InkWell(
              onTap: () => _selectDate(false),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Adoption Date',
                  prefixIcon: Icon(Icons.home),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _adoptionDate != null
                      ? DateFormat('MMMM d, y').format(_adoptionDate!)
                      : 'Select date',
                  style: TextStyle(
                    color: _adoptionDate != null
                        ? AppTheme.textPrimary
                        : AppTheme.textLight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _isSaving ? null : _savePet,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save Changes'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
