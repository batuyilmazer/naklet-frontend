/// Document types used by the driver documents API.
enum DriverDocumentType { license, registration }

/// Upload lifecycle state for each document.
enum DocumentUploadState {
  idle,
  selected,
  uploadingInit,
  uploadingBinary,
  confirming,
  success,
  failed,
}

extension DocumentUploadStateX on DocumentUploadState {
  String get label {
    return switch (this) {
      DocumentUploadState.idle => 'Henuz pati izi yok',
      DocumentUploadState.selected => 'Kanit secildi',
      DocumentUploadState.uploadingInit => 'Rozet hazirlaniyor',
      DocumentUploadState.uploadingBinary => 'Miriltili yukleme suruyor',
      DocumentUploadState.confirming => 'Mahalleye duyuruluyor',
      DocumentUploadState.success => 'Rozet tamam',
      DocumentUploadState.failed => 'Hata',
    };
  }
}
