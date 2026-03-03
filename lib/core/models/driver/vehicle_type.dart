/// Vehicle type enum aligned with backend schema.
enum VehicleType {
  kamyonet,
  panelvan,
  kamyon,
  tir;

  /// Display-friendly Turkish label.
  String get label => switch (this) {
    kamyonet => 'Kamyonet',
    panelvan => 'Panelvan',
    kamyon => 'Kamyon',
    tir => 'TIR',
  };

  /// Backend-compatible UPPERCASE value for serialization.
  String get apiValue => name.toUpperCase();

  /// Parse from backend string value.
  static VehicleType fromString(String value) {
    return VehicleType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => VehicleType.kamyonet,
    );
  }
}
