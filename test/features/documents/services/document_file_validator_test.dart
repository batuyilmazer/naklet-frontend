import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_frontend_boilerplate/features/documents/models/selected_document_file.dart';
import 'package:flutter_frontend_boilerplate/features/documents/services/document_file_validator.dart';

void main() {
  group('DocumentFileValidator', () {
    const validator = DocumentFileValidator();

    test('accepts valid JPG file', () {
      final file = SelectedDocumentFile(
        name: 'ehliyet.jpg',
        sizeBytes: 1024,
        mimeType: 'image/jpeg',
        bytes: Uint8List.fromList([1, 2, 3]),
        source: DocumentFileSource.picker,
      );

      final failure = validator.validate(file);
      expect(failure, isNull);
    });

    test('accepts valid PDF file', () {
      final file = SelectedDocumentFile(
        name: 'ruhsat.pdf',
        sizeBytes: 2048,
        mimeType: 'application/pdf',
        bytes: Uint8List.fromList([37, 80, 68, 70]),
        source: DocumentFileSource.picker,
      );

      final failure = validator.validate(file);
      expect(failure, isNull);
    });

    test('rejects unsupported file type', () {
      final file = SelectedDocumentFile(
        name: 'script.exe',
        sizeBytes: 1024,
        mimeType: 'application/octet-stream',
        bytes: Uint8List.fromList([1, 2, 3]),
        source: DocumentFileSource.picker,
      );

      final failure = validator.validate(file);
      expect(failure, isNotNull);
      expect(failure!.message, contains('Sadece JPG, PNG veya PDF dosyası'));
    });

    test('rejects file when size limit exceeded', () {
      const maxSizeBytes = 1024;
      const strictValidator = DocumentFileValidator(maxSizeBytes: maxSizeBytes);
      final file = SelectedDocumentFile(
        name: 'buyuk-dosya.pdf',
        sizeBytes: maxSizeBytes + 1,
        mimeType: 'application/pdf',
        bytes: Uint8List.fromList(List<int>.filled(maxSizeBytes + 1, 1)),
        source: DocumentFileSource.picker,
      );

      final failure = strictValidator.validate(file);
      expect(failure, isNotNull);
      expect(failure!.message, contains('Dosya boyutu en fazla'));
    });
  });
}
