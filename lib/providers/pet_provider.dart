import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';

class PetProvider with ChangeNotifier {
  final PetService _petService = PetService();

  List<Pet> _pets = [];
  Pet? _selectedPet;
  bool _isLoading = false;
  String? _error;

  List<Pet> get pets => _pets;
  Pet? get selectedPet => _selectedPet;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasPets => _pets.isNotEmpty;

  Future<void> loadPets() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _pets = await _petService.getPets();

      // Auto-select first pet if none selected
      if (_selectedPet == null && _pets.isNotEmpty) {
        _selectedPet = _pets.first;
      }

      // Update selected pet if it's in the list
      if (_selectedPet != null) {
        final updatedPet = _pets.where((p) => p.id == _selectedPet!.id).firstOrNull;
        _selectedPet = updatedPet ?? (_pets.isNotEmpty ? _pets.first : null);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Pet?> getPet(String petId) async {
    try {
      return await _petService.getPet(petId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> createPet(Pet pet, {File? photoFile}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      Pet newPet = await _petService.createPet(pet);

      // Upload photo if provided
      if (photoFile != null) {
        final photoUrl = await _petService.uploadPhoto(newPet.id, photoFile);
        newPet = newPet.copyWith(photoUrl: photoUrl);
        newPet = await _petService.updatePet(newPet);
      }

      _pets.insert(0, newPet);

      // Auto-select if first pet
      if (_selectedPet == null) {
        _selectedPet = newPet;
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePet(Pet pet, {File? photoFile}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      Pet updatedPet = pet;

      // Upload new photo if provided
      if (photoFile != null) {
        final photoUrl = await _petService.uploadPhoto(pet.id, photoFile);
        updatedPet = pet.copyWith(photoUrl: photoUrl);
      }

      updatedPet = await _petService.updatePet(updatedPet);

      // Update in list
      final index = _pets.indexWhere((p) => p.id == pet.id);
      if (index != -1) {
        _pets[index] = updatedPet;
      }

      // Update selected pet if it's the one being edited
      if (_selectedPet?.id == pet.id) {
        _selectedPet = updatedPet;
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePet(String petId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _petService.deletePet(petId);

      _pets.removeWhere((p) => p.id == petId);

      // Update selected pet if it was deleted
      if (_selectedPet?.id == petId) {
        _selectedPet = _pets.isNotEmpty ? _pets.first : null;
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectPet(Pet pet) {
    _selectedPet = pet;
    notifyListeners();
  }

  void selectPetById(String petId) {
    final pet = _pets.where((p) => p.id == petId).firstOrNull;
    if (pet != null) {
      _selectedPet = pet;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _pets = [];
    _selectedPet = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
