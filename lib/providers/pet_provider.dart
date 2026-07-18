import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';
import '../utils/connectivity.dart';

class PetProvider with ChangeNotifier {
  final PetService _petService = PetService();

  static const _cacheThreshold = Duration(minutes: 5);
  DateTime? _lastFetched;
  bool _isFetching = false;

  List<Pet> _pets = [];
  Pet? _selectedPet;
  bool _isLoading = false;
  String? _error;

  List<Pet> get pets => _pets;
  Pet? get selectedPet => _selectedPet;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasPets => _pets.isNotEmpty;

  Future<void> loadPets({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _lastFetched != null &&
        DateTime.now().difference(_lastFetched!) < _cacheThreshold) {
      return;
    }
    if (_isFetching) return;

    final isOnline = await ConnectivityHelper.instance.hasInternetConnection();

    if (!isOnline) {
      // If we have cached data, just use it silently
      if (_pets.isNotEmpty) return;
      // No cached data and offline
      _error = 'No internet connection. Please try again later.';
      notifyListeners();
      return;
    }

    try {
      _isFetching = true;
      _isLoading = true;
      _error = null;
      notifyListeners();

      _pets = await _petService.getPets();
      _lastFetched = DateTime.now();

      // Auto-select first pet if none selected
      if (_selectedPet == null && _pets.isNotEmpty) {
        _selectedPet = _pets.first;
      }

      // Update selected pet if it's in the list
      if (_selectedPet != null) {
        final updatedPet = _pets
            .where((p) => p.id == _selectedPet!.id)
            .firstOrNull;
        _selectedPet = updatedPet ?? (_pets.isNotEmpty ? _pets.first : null);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isFetching = false;
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

  Future<bool> createPet(
    Pet pet, {
    XFile? photoFile,
    XFile? coverPhotoFile,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final nextDisplayOrder = _pets.isEmpty
          ? 0
          : _pets
                    .map((pet) => pet.displayOrder)
                    .reduce(
                      (value, element) => value > element ? value : element,
                    ) +
                1;
      Pet newPet = await _petService.createPet(
        pet.copyWith(displayOrder: nextDisplayOrder),
      );

      // Upload photo if provided
      if (photoFile != null) {
        final photoUrl = await _petService.uploadPhoto(newPet.id, photoFile);
        newPet = newPet.copyWith(photoUrl: photoUrl);
      }
      if (coverPhotoFile != null) {
        final coverPhotoUrl = await _petService.uploadPhoto(
          newPet.id,
          coverPhotoFile,
          type: PetPhotoType.cover,
        );
        newPet = newPet.copyWith(coverPhotoUrl: coverPhotoUrl);
      }
      if (photoFile != null || coverPhotoFile != null) {
        newPet = await _petService.updatePet(newPet);
      }

      _lastFetched = null;
      _pets.add(newPet);
      _pets.sort(_comparePetsByDisplayOrder);

      // Auto-select if first pet
      _selectedPet ??= newPet;

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePet(
    Pet pet, {
    XFile? photoFile,
    XFile? coverPhotoFile,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      Pet updatedPet = pet;

      // Upload new photo if provided
      if (photoFile != null) {
        final photoUrl = await _petService.uploadPhoto(
          pet.id,
          photoFile,
          previousUrl: pet.photoUrl,
        );
        updatedPet = pet.copyWith(photoUrl: photoUrl);
      }
      if (coverPhotoFile != null) {
        final coverPhotoUrl = await _petService.uploadPhoto(
          pet.id,
          coverPhotoFile,
          type: PetPhotoType.cover,
          previousUrl: pet.coverPhotoUrl,
        );
        updatedPet = updatedPet.copyWith(coverPhotoUrl: coverPhotoUrl);
      }

      updatedPet = await _petService.updatePet(updatedPet);
      _lastFetched = null;

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

  Future<bool> reorderPets(int oldIndex, int newIndex) async {
    if (oldIndex < 0 ||
        oldIndex >= _pets.length ||
        newIndex < 0 ||
        newIndex >= _pets.length ||
        oldIndex == newIndex) {
      return true;
    }

    final previousPets = List<Pet>.from(_pets);
    final previousSelectedId = _selectedPet?.id;

    final movedPet = _pets.removeAt(oldIndex);
    _pets.insert(newIndex, movedPet);
    _pets = [
      for (var index = 0; index < _pets.length; index++)
        _pets[index].copyWith(displayOrder: index),
    ];
    _selectedPet = _pets.isNotEmpty ? _pets.first : null;
    _lastFetched = null;
    notifyListeners();

    try {
      await _petService.updatePetDisplayOrders(_pets);
      return true;
    } catch (e) {
      _pets = previousPets;
      _selectedPet = previousPets
          .where((pet) => pet.id == previousSelectedId)
          .firstOrNull;
      _selectedPet ??= previousPets.isNotEmpty ? previousPets.first : null;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePet(String petId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _petService.deletePet(petId);
      _lastFetched = null;

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
    _lastFetched = null;
    notifyListeners();
  }

  int _comparePetsByDisplayOrder(Pet a, Pet b) {
    final orderComparison = a.displayOrder.compareTo(b.displayOrder);
    if (orderComparison != 0) return orderComparison;
    return a.createdAt.compareTo(b.createdAt);
  }
}
