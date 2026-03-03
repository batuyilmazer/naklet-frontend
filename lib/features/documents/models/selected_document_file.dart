import 'dart:typed_data';

/// Source of selected document file.
enum DocumentFileSource { picker, camera }

/// Normalized document file model used by the upload flow.
class SelectedDocumentFile {
  const SelectedDocumentFile({
    required this.name,
    required this.sizeBytes,
    required this.mimeType,
    required this.bytes,
    required this.source,
  });

  final String name;
  final int sizeBytes;
  final String mimeType;
  final Uint8List bytes;
  final DocumentFileSource source;
}
