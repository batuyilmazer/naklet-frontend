import 'dart:typed_data';

import 'package:mime/mime.dart';

import '../../../core/errors/errors.dart';
import '../models/selected_document_file.dart';

/// File-level validation rules for driver documents.
class DocumentFileValidator {
  const DocumentFileValidator({this.maxSizeBytes = defaultMaxSizeBytes});

  static const int defaultMaxSizeBytes = 10 * 1024 * 1024;

  static const Set<String> _allowedMimeTypes = {
    'image/jpeg',
    'image/png',
    'application/pdf',
  };

  static const Set<String> _allowedExtensions = {'jpg', 'jpeg', 'png', 'pdf'};

  final int maxSizeBytes;

  Failure? validate(SelectedDocumentFile file) {
    if (file.sizeBytes <= 0 || file.bytes.isEmpty) {
      return const ValidationFailure(message: 'Dosya boş olamaz.');
    }

    if (file.sizeBytes > maxSizeBytes) {
      final maxMb = (maxSizeBytes / (1024 * 1024)).round();
      return ValidationFailure(
        message: 'Dosya boyutu en fazla $maxMb MB olabilir.',
      );
    }

    final extension = _fileExtension(file.name);
    final normalizedMimeType = _normalizeMimeType(file.mimeType);
    final isAllowedMime =
        normalizedMimeType != null &&
        _allowedMimeTypes.contains(normalizedMimeType);
    final isAllowedExtension = _allowedExtensions.contains(extension);

    if (!isAllowedMime && !isAllowedExtension) {
      return const ValidationFailure(
        message: 'Sadece JPG, PNG veya PDF dosyası yükleyebilirsiniz.',
      );
    }

    return null;
  }

  /// Resolves a stable MIME type for upload payloads.
  String resolveMimeType({
    required String fileName,
    required Uint8List bytes,
    String? providedMimeType,
  }) {
    final normalizedProvided = _normalizeMimeType(providedMimeType);
    if (normalizedProvided != null) return normalizedProvided;

    final detected = lookupMimeType(fileName, headerBytes: bytes);
    final normalizedDetected = _normalizeMimeType(detected);
    if (normalizedDetected != null) return normalizedDetected;

    final ext = _fileExtension(fileName);
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }

  String _fileExtension(String fileName) {
    final normalized = fileName.toLowerCase().trim();
    final index = normalized.lastIndexOf('.');
    if (index < 0 || index == normalized.length - 1) return '';
    return normalized.substring(index + 1);
  }

  String? _normalizeMimeType(String? mimeType) {
    if (mimeType == null || mimeType.trim().isEmpty) return null;
    final normalized = mimeType.toLowerCase().trim();
    return switch (normalized) {
      'image/jpg' => 'image/jpeg',
      'application/x-pdf' => 'application/pdf',
      _ => normalized,
    };
  }
}
