/// Driver approval status enum aligned with backend schema.
enum DriverStatus {
  pending,
  approved,
  rejected;

  /// Display-friendly Turkish label.
  String get label => switch (this) {
    pending => 'Onay Bekliyor',
    approved => 'Onaylandı',
    rejected => 'Reddedildi',
  };

  /// Parse from backend string value.
  static DriverStatus fromString(String value) {
    return DriverStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => DriverStatus.pending,
    );
  }
}
