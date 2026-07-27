import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';
import 'supabase_service.dart';

class AccountDataExportResult {
  final Uint8List bytes;
  final String fileName;
  final int recordCount;
  final int attachmentCount;

  const AccountDataExportResult({
    required this.bytes,
    required this.fileName,
    required this.recordCount,
    required this.attachmentCount,
  });
}

class AccountDataExportFile {
  final String archivePath;
  final Uint8List bytes;

  const AccountDataExportFile({required this.archivePath, required this.bytes});
}

class AccountDataExportService {
  final SupabaseClient _client;

  AccountDataExportService({SupabaseClient? client})
    : _client = client ?? SupabaseService.client;

  Future<AccountDataExportResult> createExport() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to export account data.');
    }

    final account = Map<String, dynamic>.from(
      await _client.from('users').select().eq('id', user.id).single(),
    );
    final pets = await _fetchUserRows('pets', user.id);
    final petIds = pets.map((pet) => pet['id'] as String).toList();

    final medicalRecords = petIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _fetchPetRows('medical_records', petIds);
    final activities = await _fetchUserRows('activities', user.id);
    final appointments = await _fetchUserRows('appointments', user.id);
    final reminders = await _fetchUserRows('reminders', user.id);
    final achievements = await _fetchUserRows('achievements', user.id);
    final favoriteProviders = await _fetchUserRows(
      'favorite_providers',
      user.id,
    );

    Map<String, dynamic>? entitlement;
    try {
      final response = await _client
          .from('account_entitlements')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (response != null) entitlement = Map<String, dynamic>.from(response);
    } on PostgrestException catch (error) {
      // Older PawPal projects may not have the subscription migration yet.
      // A missing optional entitlement table must not block data portability.
      if (error.code != '42P01' && error.code != 'PGRST205') rethrow;
    }

    final references = _collectStorageReferences(
      account: account,
      pets: pets,
      medicalRecords: medicalRecords,
      activities: activities,
    );
    final files = <AccountDataExportFile>[];
    final attachmentManifest = <Map<String, dynamic>>[];

    for (final reference in references.values) {
      try {
        final bytes = await _client.storage
            .from(reference.bucket)
            .download(reference.storagePath);
        files.add(
          AccountDataExportFile(
            archivePath: reference.archivePath,
            bytes: bytes,
          ),
        );
        attachmentManifest.add(reference.toJson(status: 'included'));
      } catch (error) {
        if (reference.required) {
          throw StateError(
            'A medical document could not be included in the export: '
            '${reference.storagePath}. Please try again or contact support.',
          );
        }
        attachmentManifest.add(
          reference.toJson(status: 'unavailable', error: '$error'),
        );
      }
    }

    final tables = <String, dynamic>{
      'account': account,
      'pets': pets,
      'medical_records': medicalRecords,
      'activities': activities,
      'appointments': appointments,
      'reminders': reminders,
      'achievements': achievements,
      'favorite_providers': favoriteProviders,
      'account_entitlement': entitlement,
    };
    final exportedAt = DateTime.now().toUtc();
    final data = <String, dynamic>{
      'format': 'pawpal-account-export',
      'schema_version': 1,
      'exported_at': exportedAt.toIso8601String(),
      'user_id': user.id,
      'tables': tables,
      'attachments': attachmentManifest,
    };

    final bytes = encodeArchive(data: data, files: files);
    final date = exportedAt.toIso8601String().split('T').first;
    final recordCount = tables.values.fold<int>(0, (total, value) {
      if (value is List) return total + value.length;
      return value == null ? total : total + 1;
    });

    return AccountDataExportResult(
      bytes: bytes,
      fileName: 'pawpal-account-export-$date.zip',
      recordCount: recordCount,
      attachmentCount: files.length,
    );
  }

  @visibleForTesting
  static Uint8List encodeArchive({
    required Map<String, dynamic> data,
    List<AccountDataExportFile> files = const [],
  }) {
    final archive = Archive();
    final jsonBytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(data)),
    );
    archive.addFile(
      ArchiveFile('data/pawpal-account-data.json', jsonBytes.length, jsonBytes),
    );

    final readmeBytes = Uint8List.fromList(
      utf8.encode(
        'PawPal account data export\n\n'
        'The data folder contains your account information as JSON.\n'
        'The files folder contains available original uploads. Medical '
        'documents are required; optional photos that could not be fetched '
        'are listed as unavailable in the JSON attachment manifest.\n',
      ),
    );
    archive.addFile(ArchiveFile('README.txt', readmeBytes.length, readmeBytes));

    for (final file in files) {
      final safePath = safeArchivePath(file.archivePath);
      archive.addFile(ArchiveFile(safePath, file.bytes.length, file.bytes));
    }

    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }

  @visibleForTesting
  static String safeArchivePath(String value) {
    final parts = value
        .replaceAll('\\', '/')
        .split('/')
        .where((part) => part.isNotEmpty && part != '.' && part != '..')
        .map((part) => part.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_'))
        .toList();
    if (parts.isEmpty) return 'files/unnamed';
    return parts.join('/');
  }

  static List<Map<String, dynamic>> _mapRows(dynamic response) =>
      (response as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();

  Future<List<Map<String, dynamic>>> _fetchUserRows(
    String table,
    String userId,
  ) async {
    const pageSize = 500;
    final rows = <Map<String, dynamic>>[];
    for (var from = 0; ; from += pageSize) {
      final page = _mapRows(
        await _client
            .from(table)
            .select()
            .eq('user_id', userId)
            .order('id')
            .range(from, from + pageSize - 1),
      );
      rows.addAll(page);
      if (page.length < pageSize) return rows;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPetRows(
    String table,
    List<String> petIds,
  ) async {
    const pageSize = 500;
    final rows = <Map<String, dynamic>>[];
    for (var from = 0; ; from += pageSize) {
      final page = _mapRows(
        await _client
            .from(table)
            .select()
            .inFilter('pet_id', petIds)
            .order('id')
            .range(from, from + pageSize - 1),
      );
      rows.addAll(page);
      if (page.length < pageSize) return rows;
    }
  }

  static Map<String, _StorageReference> _collectStorageReferences({
    required Map<String, dynamic> account,
    required List<Map<String, dynamic>> pets,
    required List<Map<String, dynamic>> medicalRecords,
    required List<Map<String, dynamic>> activities,
  }) {
    final references = <String, _StorageReference>{};

    void addFromValue({
      required String bucket,
      required Object? value,
      required String category,
      bool required = false,
    }) {
      if (value is! String || value.trim().isEmpty) return;
      final path = storagePathFromValue(bucket, value);
      if (path == null || path.isEmpty) return;
      final key = '$bucket/$path';
      references.putIfAbsent(
        key,
        () => _StorageReference(
          bucket: bucket,
          storagePath: path,
          archivePath: 'files/$category/$path',
          required: required,
        ),
      );
    }

    addFromValue(
      bucket: AppConstants.profilePhotosBucket,
      value: account['photo_url'],
      category: 'profile-photos',
    );
    for (final pet in pets) {
      addFromValue(
        bucket: AppConstants.petPhotosBucket,
        value: pet['photo_url'],
        category: 'pet-photos',
      );
      addFromValue(
        bucket: AppConstants.petPhotosBucket,
        value: pet['cover_photo_url'],
        category: 'pet-photos',
      );
    }
    for (final record in medicalRecords) {
      addFromValue(
        bucket: AppConstants.medicalDocsBucket,
        value: record['document_url'],
        category: 'medical-documents',
        required: true,
      );
    }
    for (final activity in activities) {
      final values = activity['photo_urls'];
      if (values is! List) continue;
      for (final value in values) {
        addFromValue(
          bucket: AppConstants.activityPhotosBucket,
          value: value,
          category: 'activity-photos',
        );
      }
    }
    return references;
  }

  @visibleForTesting
  static String? storagePathFromValue(String bucket, String value) {
    final uri = Uri.tryParse(value);
    final segments = uri?.pathSegments ?? const <String>[];
    final bucketIndex = segments.indexOf(bucket);
    if (bucketIndex >= 0 && bucketIndex < segments.length - 1) {
      return Uri.decodeComponent(segments.sublist(bucketIndex + 1).join('/'));
    }

    // Raw storage paths are used for private medical documents. Do not treat
    // unrelated external URLs (for example an OAuth avatar) as bucket paths.
    if (uri != null && uri.hasScheme) return null;
    return value.replaceFirst(RegExp(r'^/+'), '');
  }
}

class _StorageReference {
  final String bucket;
  final String storagePath;
  final String archivePath;
  final bool required;

  const _StorageReference({
    required this.bucket,
    required this.storagePath,
    required this.archivePath,
    required this.required,
  });

  Map<String, dynamic> toJson({required String status, String? error}) => {
    'bucket': bucket,
    'storage_path': storagePath,
    'archive_path': AccountDataExportService.safeArchivePath(archivePath),
    'status': status,
    if (error != null) 'error': error,
  };
}
