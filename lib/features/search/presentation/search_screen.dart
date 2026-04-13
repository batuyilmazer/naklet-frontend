import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/driver/vehicle_type.dart';
import '../../../core/models/search/nearby_vehicle.dart';
import '../../../theme/extensions/theme_context_extensions.dart';
import '../../../ui/atoms/app_text.dart';
import '../../../ui/cat_theme/cat_theme.dart';
import '../../../routing/route_paths.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/search_repository.dart';
import 'widgets/nearby_vehicle_card.dart';

/// Main search screen — home/landing page for the app.
///
/// Displays nearby vehicles based on user's GPS location.
/// Accessible by both guests and authenticated users (public route).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _repository = SearchRepository();

  List<NearbyVehicle> _vehicles = [];
  bool _isLoading = false;
  String? _error;

  // Filter state
  VehicleType? _selectedType;
  int _radius = 15000; // meters
  double? _lat;
  double? _lng;

  // Radius options in meters
  static const _radiusOptions = [5000, 10000, 15000, 20000, 50000];

  @override
  void initState() {
    super.initState();
    _requestLocationAndSearch();
  }

  Future<void> _requestLocationAndSearch() async {
    // TODO: Aşama 4'te geolocator ile gerçek konum alınacak.
    // Şimdilik İstanbul merkez koordinatları kullanılıyor.
    _lat = 41.0082;
    _lng = 28.9784;
    await _search();
  }

  Future<void> _search() async {
    if (_lat == null || _lng == null) {
      setState(
        () =>
            _error = 'Mahalleyi tarayabilmem icin konum izni vermen gerekiyor.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final vehicles = await _repository.searchNearby(
        lat: _lat!,
        lng: _lng!,
        radius: _radius,
        vehicleType: _selectedType?.apiValue,
      );
      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Mahalle taramasi sirasinda bir aksilik oldu.';
          _isLoading = false;
        });
      }
    }
  }

  void _onTypeFilterChanged(VehicleType? type) {
    setState(() {
      _selectedType = type;
    });
    _search();
  }

  void _onRadiusChanged(int radius) {
    setState(() {
      _radius = radius;
    });
    _search();
  }

  String _formatRadius(int meters) {
    return '${meters ~/ 1000} km';
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = context.watchAuthNotifier().isGuest;
    final colors = context.appColors;
    final spacing = context.appSpacing;

    return Scaffold(
      appBar: AppBar(
        leading: isGuest
            ? IconButton(
                onPressed: () => context.push(AppRoutes.driverRegister),
                icon: const Icon(Icons.pets_outlined),
                tooltip: 'Sokak kedisi profili ac',
              )
            : null,
        title: const Text(CatThemeCopy.appName),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _search,
            icon: const Icon(Icons.refresh),
            tooltip: 'Mahalleyi yeniden tara',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeroBanner(context, isGuest),
          // Filters section
          // Filters section
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.s16,
              vertical: spacing.s12,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle type chips
                AppText.caption('Pati karakteri', color: colors.textSecondary),
                SizedBox(height: spacing.s8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _typeChip(context, null, 'Hepsi'),
                      SizedBox(width: spacing.s8),
                      for (final type in VehicleType.values) ...[
                        _typeChip(context, type, type.label),
                        SizedBox(width: spacing.s8),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: spacing.s12),
                // Radius selector
                Row(
                  children: [
                    AppText.caption(
                      'Mirilti yaricapi:',
                      color: colors.textSecondary,
                    ),
                    SizedBox(width: spacing.s8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final r in _radiusOptions)
                              Padding(
                                padding: EdgeInsets.only(right: spacing.s4),
                                child: ChoiceChip(
                                  label: Text(_formatRadius(r)),
                                  selected: _radius == r,
                                  onSelected: (selected) {
                                    if (selected) _onRadiusChanged(r);
                                  },
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    color: _radius == r
                                        ? colors.onPrimary
                                        : colors.textPrimary,
                                  ),
                                  selectedColor: colors.primary,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Results
          Expanded(child: _buildContent(colors, spacing)),
        ],
      ),
    );
  }

  Widget _buildContent(dynamic colors, dynamic spacing) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(spacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 64, color: colors.textSecondary),
              SizedBox(height: spacing.s16),
              AppText.bodySmall(
                _error!,
                textAlign: TextAlign.center,
                color: colors.textSecondary,
              ),
              SizedBox(height: spacing.s16),
              TextButton.icon(
                onPressed: _requestLocationAndSearch,
                icon: const Icon(Icons.refresh),
                label: const Text('Mahalleyi yeniden tara'),
              ),
            ],
          ),
        ),
      );
    }

    if (_vehicles.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(spacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pets_outlined, size: 64, color: colors.textSecondary),
              SizedBox(height: spacing.s16),
              AppText.bodySmall(
                'Yakinlarda simdilik takilan bir sokak kedisi gorunmuyor.\nYaricapi artirip yeniden deneyin.',
                textAlign: TextAlign.center,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _search,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.s16,
          vertical: spacing.s8,
        ),
        itemCount: _vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = _vehicles[index];
          return Padding(
            padding: EdgeInsets.only(bottom: spacing.s8),
            child: NearbyVehicleCard(
              vehicle: vehicle,
              onTap: () {
                context.push(AppRoutes.vehicleDetail, extra: vehicle);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _typeChip(BuildContext context, VehicleType? type, String label) {
    final colors = context.appColors;
    final isSelected = _selectedType == type;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => _onTypeFilterChanged(selected ? type : null),
      selectedColor: colors.primary,
      labelStyle: TextStyle(
        color: isSelected ? colors.onPrimary : colors.textPrimary,
        fontSize: 13,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildHeroBanner(BuildContext context, bool isGuest) {
    final colors = context.appColors;
    final spacing = context.appSpacing;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(
        spacing.s16,
        spacing.s12,
        spacing.s16,
        spacing.s12,
      ),
      padding: EdgeInsets.all(spacing.s24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.18),
            colors.surfaceVariant,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.pets, color: colors.primary),
              ),
              SizedBox(width: spacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.caption(
                      'Mahalle radarinda',
                      color: colors.textSecondary,
                    ),
                    SizedBox(height: spacing.s4),
                    Text(
                      'Bugun kimi seveceksin?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.s16),
          AppText.bodySmall(
            'Yakin sokak kedilerini karakterlerine, uzakliklarina ve mahalle dedikodusuna gore tarayin.',
            color: colors.textSecondary,
          ),
          SizedBox(height: spacing.s16),
          Wrap(
            spacing: spacing.s8,
            runSpacing: spacing.s8,
            children: [
              _heroChip(context, Icons.favorite_border, 'Sevgi icin hazir'),
              _heroChip(
                context,
                Icons.location_on_outlined,
                'Konuma gore sirali',
              ),
              if (isGuest)
                _heroChip(
                  context,
                  Icons.add_home_outlined,
                  'Kendi kedi profilini birak',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip(BuildContext context, IconData icon, String label) {
    final colors = context.appColors;
    final spacing = context.appSpacing;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.s12,
        vertical: spacing.s8,
      ),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          SizedBox(width: spacing.s6),
          AppText.caption(label, color: colors.textPrimary),
        ],
      ),
    );
  }
}
