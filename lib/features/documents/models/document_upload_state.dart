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
      DocumentUploadState.idle => 'Henüz seçilmedi',
      DocumentUploadState.selected => 'Dosya seçildi',
      DocumentUploadState.uploadingInit => 'Hazırlanıyor',
      DocumentUploadState.uploadingBinary => 'Yükleniyor',
      DocumentUploadState.confirming => 'Onaylanıyor',
      DocumentUploadState.success => 'Tamamlandı',
      DocumentUploadState.failed => 'Hata',
    };
  }
}
