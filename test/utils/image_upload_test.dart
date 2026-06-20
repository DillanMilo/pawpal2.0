import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpal/utils/image_upload.dart';

void main() {
  group('resolveImageUploadType', () {
    test('detects jpeg from bytes before filename', () {
      final type = resolveImageUploadType(
        bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0x00]),
        fileName: 'photo.png',
      );

      expect(type.extension, 'jpeg');
      expect(type.contentType, 'image/jpeg');
    });

    test('detects png from bytes', () {
      final type = resolveImageUploadType(
        bytes: Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
        ]),
      );

      expect(type.extension, 'png');
      expect(type.contentType, 'image/png');
    });

    test('uses mime type when bytes do not identify the image', () {
      final type = resolveImageUploadType(
        bytes: Uint8List.fromList([0x00, 0x01]),
        mimeType: 'image/webp',
      );

      expect(type.extension, 'webp');
      expect(type.contentType, 'image/webp');
    });

    test('rejects unsupported images without needing a path', () {
      expect(
        () => resolveImageUploadType(
          bytes: Uint8List.fromList([0x00, 0x01]),
          mimeType: 'image/heic',
          fileName: '',
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
