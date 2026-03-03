import 'document_upload_state.dart';

/// Outcome of a document upload attempt.
class DocumentUploadResult {
  const DocumentUploadResult({
    required this.succeededDocuments,
    required this.failedDocuments,
    this.licenseKey,
    this.registrationKey,
  });

  final Set<DriverDocumentType> succeededDocuments;
  final Map<DriverDocumentType, String> failedDocuments;
  final String? licenseKey;
  final String? registrationKey;

  bool get isCompleteSuccess =>
      succeededDocuments.isNotEmpty && failedDocuments.isEmpty;

  bool get isPartialSuccess =>
      succeededDocuments.isNotEmpty && failedDocuments.isNotEmpty;
}
