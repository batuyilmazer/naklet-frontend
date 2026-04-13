import '../../core/models/driver/vehicle.dart';
import '../../core/models/driver/vehicle_type.dart';
import '../../core/models/search/nearby_vehicle.dart';

class CatThemeCopy {
  const CatThemeCopy._();

  static const appName = 'PisiBul';
  static const appTagline =
      'Mahallendeki sokak kedilerini bul, sev, mamasini eksik etme.';

  static CatProfileViewData nearbyProfile(NearbyVehicle vehicle) {
    return _buildProfile(
      seed: '${vehicle.id}-${vehicle.plateNumber}-${vehicle.driver.fullName}',
      archetype: vehicle.type,
      rawAlias: vehicle.plateNumber,
      rawWeight: vehicle.capacityKg,
      humanName: vehicle.driver.fullName,
      distanceLabel: vehicle.formattedDistance,
    );
  }

  static CatProfileViewData vehicleProfile(
    Vehicle vehicle, {
    String? humanName,
  }) {
    return _buildProfile(
      seed: '${vehicle.id}-${vehicle.plateNumber}',
      archetype: vehicle.type,
      rawAlias: vehicle.plateNumber,
      rawWeight: vehicle.capacityKg,
      humanName: humanName,
    );
  }

  static String humanDisplayName(String? firstName, String? lastName) {
    final values = [
      firstName?.trim(),
      lastName?.trim(),
    ].whereType<String>().where((value) => value.isNotEmpty).toList();
    if (values.isEmpty) return 'Mahallenin gizemli kedisi';
    return values.join(' ');
  }

  static CatProfileViewData _buildProfile({
    required String seed,
    required VehicleType archetype,
    required String rawAlias,
    required int rawWeight,
    String? humanName,
    String? distanceLabel,
  }) {
    final hash = seed.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    final nicknames = [
      'Boncuk',
      'Tarcin',
      'Minnos',
      'Kopuk',
      'Karamel',
      'Zilli',
      'Pofuduk',
      'Limon',
    ];
    final colors = [
      'Tekir',
      'Gece siyahi',
      'Sut beyazi',
      'Kum sarisi',
      'Pasli turuncu',
      'Duman gri',
      'Cilli karamela',
      'Kahve benekli',
    ];
    final moods = [
      'Kapi onunde gurme bakislar atiyor.',
      'Mirlama performansi mahalle standartlarinin ustunde.',
      'Iki dakika sevgi, uc dakika artistlik istiyor.',
      'Mama sesi duyunca hizli davranir.',
      'Pencere kenarinda drama seviyesi yuksek.',
      'Sokak turnesinde herkese goz kirpiyor.',
    ];
    final nickname = nicknames[hash % nicknames.length];
    final color = colors[(hash + rawAlias.length) % colors.length];
    final age = 1 + (rawWeight % 14);
    final weight = 2.8 + ((rawWeight % 38) / 10);

    return CatProfileViewData(
      nickname: nickname,
      archetypeLabel: archetype.label,
      colorLabel: color,
      ageLabel: '$age yas',
      weightLabel: '${weight.toStringAsFixed(1)} kg',
      aliasLabel: rawAlias.trim().isEmpty ? 'Mahalle kaydi yok' : rawAlias,
      vibeLine: moods[hash % moods.length],
      humanName: humanName ?? 'Mahalle kaydi kapali',
      distanceLabel: distanceLabel,
    );
  }
}

class CatProfileViewData {
  const CatProfileViewData({
    required this.nickname,
    required this.archetypeLabel,
    required this.colorLabel,
    required this.ageLabel,
    required this.weightLabel,
    required this.aliasLabel,
    required this.vibeLine,
    required this.humanName,
    this.distanceLabel,
  });

  final String nickname;
  final String archetypeLabel;
  final String colorLabel;
  final String ageLabel;
  final String weightLabel;
  final String aliasLabel;
  final String vibeLine;
  final String humanName;
  final String? distanceLabel;
}
