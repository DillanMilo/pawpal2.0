import 'dart:io';
import 'package:uuid/uuid.dart';
import 'supabase_service.dart';
import '../models/pet.dart';
import '../utils/constants.dart';

class PetService {
  final _client = SupabaseService.client;
  final _uuid = const Uuid();

  // Get all pets for current user
  Future<List<Pet>> getPets() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];

    final response = await _client
        .from('pets')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Pet.fromJson(e)).toList();
  }

  // Get a single pet by ID
  Future<Pet?> getPet(String petId) async {
    final response =
        await _client.from('pets').select().eq('id', petId).maybeSingle();

    if (response == null) return null;
    return Pet.fromJson(response);
  }

  // Create a new pet
  Future<Pet> createPet(Pet pet) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final now = DateTime.now().toIso8601String();
    final data = pet.toJson();
    data['id'] = _uuid.v4();
    data['user_id'] = userId;
    data['created_at'] = now;
    data['updated_at'] = now;

    final response =
        await _client.from('pets').insert(data).select().single();

    return Pet.fromJson(response);
  }

  // Update a pet
  Future<Pet> updatePet(Pet pet) async {
    final data = pet.toJson();
    data['updated_at'] = DateTime.now().toIso8601String();

    final response = await _client
        .from('pets')
        .update(data)
        .eq('id', pet.id)
        .select()
        .single();

    return Pet.fromJson(response);
  }

  // Delete a pet
  Future<void> deletePet(String petId) async {
    // Delete pet photo from storage if exists
    final pet = await getPet(petId);
    if (pet?.photoUrl != null) {
      await _deletePhoto(pet!.photoUrl!);
    }

    await _client.from('pets').delete().eq('id', petId);
  }

  // Upload pet photo
  Future<String> uploadPhoto(String petId, File file) async {
    final extension = file.path.split('.').last;
    final path = '$petId/${_uuid.v4()}.$extension';

    await _client.storage
        .from(AppConstants.petPhotosBucket)
        .upload(path, file);

    final url = _client.storage
        .from(AppConstants.petPhotosBucket)
        .getPublicUrl(path);

    return url;
  }

  // Delete photo from storage
  Future<void> _deletePhoto(String url) async {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(AppConstants.petPhotosBucket);
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final path = pathSegments.sublist(bucketIndex + 1).join('/');
        await _client.storage.from(AppConstants.petPhotosBucket).remove([path]);
      }
    } catch (e) {
      // Ignore deletion errors
    }
  }

  // Get pet count for user
  Future<int> getPetCount() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return 0;

    final response = await _client
        .from('pets')
        .select('id')
        .eq('user_id', userId);

    return (response as List).length;
  }
}
