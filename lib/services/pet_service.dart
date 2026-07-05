import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'supabase_service.dart';
import '../models/pet.dart';
import '../utils/constants.dart';
import '../utils/image_upload.dart';

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
    final response = await _client
        .from('pets')
        .select()
        .eq('id', petId)
        .maybeSingle();

    if (response == null) return null;
    return Pet.fromJson(response);
  }

  // Create a new pet
  Future<Pet> createPet(Pet pet) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final now = DateTime.now().toUtc().toIso8601String();
    final data = pet.toJson();
    data['id'] = _uuid.v4();
    data['user_id'] = userId;
    data['created_at'] = now;
    data['updated_at'] = now;

    final response = await _client.from('pets').insert(data).select().single();

    return Pet.fromJson(response);
  }

  // Update a pet
  Future<Pet> updatePet(Pet pet) async {
    final data = pet.toJson();
    data['updated_at'] = DateTime.now().toUtc().toIso8601String();

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
  Future<String> uploadPhoto(String petId, XFile photo) async {
    final bytes = await photo.readAsBytes();
    final imageType = resolveImageUploadType(
      bytes: bytes,
      mimeType: _safeMimeType(photo),
      fileName: _safeFileName(photo),
    );
    final path = '$petId/${_uuid.v4()}.${imageType.extension}';

    await _client.storage
        .from(AppConstants.petPhotosBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: imageType.contentType,
            upsert: false,
          ),
        );

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

  String? _safeMimeType(XFile photo) {
    try {
      return photo.mimeType;
    } catch (_) {
      return null;
    }
  }

  String? _safeFileName(XFile photo) {
    try {
      final name = photo.name;
      return name.isEmpty ? null : name;
    } catch (_) {
      return null;
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
