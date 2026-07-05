import 'dart:io';
import 'package:uuid/uuid.dart';
import 'supabase_service.dart';
import '../models/medical_record.dart';
import '../utils/constants.dart';

class MedicalService {
  final _client = SupabaseService.client;
  final _uuid = const Uuid();

  // Get all medical records for a pet
  Future<List<MedicalRecord>> getMedicalRecords(String petId) async {
    final response = await _client
        .from('medical_records')
        .select()
        .eq('pet_id', petId)
        .order('date', ascending: false);

    return (response as List).map((e) => MedicalRecord.fromJson(e)).toList();
  }

  // Get medical record counts by type for a set of pets.
  Future<Map<MedicalRecordType, int>> getMedicalRecordCountsByType(
    List<String> petIds,
  ) async {
    if (petIds.isEmpty) return {};

    final counts = <MedicalRecordType, int>{};

    final response = await _client
        .from('medical_records')
        .select('type')
        .inFilter('pet_id', petIds);

    for (final row in response as List) {
      final type = MedicalRecordType.values.firstWhere(
        (value) => value.name == row['type'],
        orElse: () => MedicalRecordType.condition,
      );
      counts[type] = (counts[type] ?? 0) + 1;
    }

    return counts;
  }

  // Get medical records by type
  Future<List<MedicalRecord>> getMedicalRecordsByType(
    String petId,
    MedicalRecordType type,
  ) async {
    final response = await _client
        .from('medical_records')
        .select()
        .eq('pet_id', petId)
        .eq('type', type.name)
        .order('date', ascending: false);

    return (response as List).map((e) => MedicalRecord.fromJson(e)).toList();
  }

  // Get active medications
  Future<List<MedicalRecord>> getActiveMedications(String petId) async {
    // end_date is a DATE column; compare with a local calendar date so a
    // medication ending today is still active for the user's timezone.
    final now = DateTime.now().toIso8601String().split('T').first;
    final response = await _client
        .from('medical_records')
        .select()
        .eq('pet_id', petId)
        .eq('type', MedicalRecordType.medication.name)
        .or('end_date.is.null,end_date.gt.$now')
        .order('date', ascending: false);

    return (response as List).map((e) => MedicalRecord.fromJson(e)).toList();
  }

  // Get upcoming vaccinations
  Future<List<MedicalRecord>> getUpcomingVaccinations(String petId) async {
    final response = await _client
        .from('medical_records')
        .select()
        .eq('pet_id', petId)
        .eq('type', MedicalRecordType.vaccination.name)
        .not('next_due_date', 'is', null)
        .order('next_due_date', ascending: true);

    return (response as List).map((e) => MedicalRecord.fromJson(e)).toList();
  }

  // Get allergies
  Future<List<MedicalRecord>> getAllergies(String petId) async {
    final response = await _client
        .from('medical_records')
        .select()
        .eq('pet_id', petId)
        .eq('type', MedicalRecordType.allergy.name);

    return (response as List).map((e) => MedicalRecord.fromJson(e)).toList();
  }

  // Create a medical record
  Future<MedicalRecord> createMedicalRecord(MedicalRecord record) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final data = record.toJson();
    data['id'] = _uuid.v4();
    data['created_at'] = now;
    data['updated_at'] = now;

    final response = await _client
        .from('medical_records')
        .insert(data)
        .select()
        .single();

    return MedicalRecord.fromJson(response);
  }

  // Update a medical record
  Future<MedicalRecord> updateMedicalRecord(MedicalRecord record) async {
    final data = record.toJson();
    data['updated_at'] = DateTime.now().toUtc().toIso8601String();

    final response = await _client
        .from('medical_records')
        .update(data)
        .eq('id', record.id)
        .select()
        .single();

    return MedicalRecord.fromJson(response);
  }

  // Delete a medical record
  Future<void> deleteMedicalRecord(String recordId) async {
    // Get record to check for document
    final record = await _client
        .from('medical_records')
        .select()
        .eq('id', recordId)
        .maybeSingle();

    if (record != null && record['document_url'] != null) {
      await _deleteDocument(record['document_url'] as String);
    }

    await _client.from('medical_records').delete().eq('id', recordId);
  }

  // Upload medical document
  Future<String> uploadDocument(String petId, File file) async {
    final extension = file.path.split('.').last;
    final path = '$petId/${_uuid.v4()}.$extension';

    await _client.storage
        .from(AppConstants.medicalDocsBucket)
        .upload(path, file);

    return path;
  }

  // Create a short-lived URL for viewing a private medical document.
  Future<String> createSignedDocumentUrl(String path) async {
    return await _client.storage
        .from(AppConstants.medicalDocsBucket)
        .createSignedUrl(_storagePathFromValue(path), 300);
  }

  // Delete document from storage
  Future<void> _deleteDocument(String value) async {
    try {
      final path = _storagePathFromValue(value);
      await _client.storage.from(AppConstants.medicalDocsBucket).remove([path]);
    } catch (e) {
      // Ignore deletion errors
    }
  }

  String _storagePathFromValue(String value) {
    final uri = Uri.tryParse(value);
    final pathSegments = uri?.pathSegments ?? const <String>[];
    final bucketIndex = pathSegments.indexOf(AppConstants.medicalDocsBucket);
    if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
      return pathSegments.sublist(bucketIndex + 1).join('/');
    }
    return value;
  }

  // Check if all vaccinations are up to date
  Future<bool> areVaccinationsUpToDate(String petId) async {
    final vaccinations = await getUpcomingVaccinations(petId);
    if (vaccinations.isEmpty) return true;

    final now = DateTime.now();
    return !vaccinations.any(
      (v) => v.nextDueDate != null && v.nextDueDate!.isBefore(now),
    );
  }
}
