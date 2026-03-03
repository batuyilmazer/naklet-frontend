/// Vehicle type enum aligned with backend schema.
enum VehicleType {
  KAMYONET,
  PANELVAN,
  KAMYON,
  TIR;

  /// Display-friendly Turkish label.
  String get label => switch (this) {
    KAMYONET => 'Kamyonet',
    PANELVAN => 'Panelvan',
    KAMYON => 'Kamyon',
    TIR => 'TIR',
  };

  /// Parse from backend string value.
  static VehicleType fromString(String value) {
    return VehicleType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VehicleType.KAMYONET,
    );
  }
}
