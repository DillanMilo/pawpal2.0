import 'dart:typed_data';

class ImageUploadType {
  final String extension;
  final String contentType;

  const ImageUploadType._(this.extension, this.contentType);

  static const jpeg = ImageUploadType._('jpeg', 'image/jpeg');
  static const png = ImageUploadType._('png', 'image/png');
  static const webp = ImageUploadType._('webp', 'image/webp');
}

ImageUploadType resolveImageUploadType({
  required Uint8List bytes,
  String? mimeType,
  String? fileName,
}) {
  final detectedFromBytes = _typeFromBytes(bytes);
  if (detectedFromBytes != null) return detectedFromBytes;

  final detectedFromMimeType = _typeFromMimeType(mimeType);
  if (detectedFromMimeType != null) return detectedFromMimeType;

  final detectedFromFileName = _typeFromFileName(fileName);
  if (detectedFromFileName != null) return detectedFromFileName;

  throw UnsupportedError(
    'Unsupported image type. Please choose a JPEG, PNG, or WebP image.',
  );
}

ImageUploadType? _typeFromBytes(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return ImageUploadType.jpeg;
  }

  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A) {
    return ImageUploadType.png;
  }

  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return ImageUploadType.webp;
  }

  return null;
}

ImageUploadType? _typeFromMimeType(String? mimeType) {
  switch (mimeType?.toLowerCase()) {
    case 'image/jpeg':
    case 'image/jpg':
      return ImageUploadType.jpeg;
    case 'image/png':
      return ImageUploadType.png;
    case 'image/webp':
      return ImageUploadType.webp;
    default:
      return null;
  }
}

ImageUploadType? _typeFromFileName(String? fileName) {
  final trimmed = fileName?.trim();
  if (trimmed == null || trimmed.isEmpty || !trimmed.contains('.')) {
    return null;
  }

  switch (trimmed.split('.').last.toLowerCase()) {
    case 'jpg':
    case 'jpeg':
      return ImageUploadType.jpeg;
    case 'png':
      return ImageUploadType.png;
    case 'webp':
      return ImageUploadType.webp;
    default:
      return null;
  }
}
