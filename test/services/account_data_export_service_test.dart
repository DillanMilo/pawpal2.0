import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/services/account_data_export_service.dart';

void main() {
  group('AccountDataExportService', () {
    test('creates a readable zip with JSON and original files', () {
      final bytes = AccountDataExportService.encodeArchive(
        data: {
          'format': 'pawpal-account-export',
          'tables': {
            'pets': [
              {'id': 'pet-1', 'name': 'Milo'},
            ],
          },
        },
        files: [
          AccountDataExportFile(
            archivePath: 'files/medical-documents/pet-1/vaccine.pdf',
            bytes: Uint8List.fromList([1, 2, 3, 4]),
          ),
        ],
      );

      final archive = ZipDecoder().decodeBytes(bytes);
      final names = archive.files.map((file) => file.name).toSet();
      expect(names, contains('data/pawpal-account-data.json'));
      expect(names, contains('README.txt'));
      expect(names, contains('files/medical-documents/pet-1/vaccine.pdf'));

      final dataFile = archive.files.singleWhere(
        (file) => file.name == 'data/pawpal-account-data.json',
      );
      final data = jsonDecode(utf8.decode(dataFile.content as List<int>));
      expect(data['format'], 'pawpal-account-export');
      expect(data['tables']['pets'][0]['name'], 'Milo');
    });

    test('extracts paths from public and private storage values', () {
      expect(
        AccountDataExportService.storagePathFromValue(
          'pet-photos',
          'https://project.supabase.co/storage/v1/object/public/'
              'pet-photos/pet-1/profile/photo.jpeg',
        ),
        'pet-1/profile/photo.jpeg',
      );
      expect(
        AccountDataExportService.storagePathFromValue(
          'medical-documents',
          'pet-1/document.pdf',
        ),
        'pet-1/document.pdf',
      );
      expect(
        AccountDataExportService.storagePathFromValue(
          'profile-photos',
          'https://accounts.google.com/avatar.png',
        ),
        isNull,
      );
    });

    test('removes traversal and unsafe characters from archive paths', () {
      expect(
        AccountDataExportService.safeArchivePath(
          '../files/medical documents/pet 1/report?.pdf',
        ),
        'files/medical_documents/pet_1/report_.pdf',
      );
    });
  });
}
