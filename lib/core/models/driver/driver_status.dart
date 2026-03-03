/// Driver approval status enum aligned with backend schema.
enum DriverStatus {
  PENDING,
  APPROVED,
  REJECTED;

  /// Display-friendly Turkish label.
  String get label => switch (this) {
    PENDING => 'Onay Bekliyor',
    APPROVED => 'Onaylandı',
    REJECTED => 'Reddedildi',
  };

  /// Parse from backend string value.
  static DriverStatus fromString(String value) {
    return DriverStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DriverStatus.PENDING,
    );
  }
}
