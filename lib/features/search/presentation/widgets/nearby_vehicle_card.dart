import 'package:flutter/material.dart';

import '../../../../core/models/driver/vehicle_type.dart';
import '../../../../core/models/search/nearby_vehicle.dart';
import '../../../../theme/extensions/theme_context_extensions.dart';
import '../../../../ui/atoms/app_text.dart';

/// Compact card widget displaying a nearby vehicle in search results.
///
/// Shows driver name, vehicle type, plate number, capacity, and distance.
/// Taps navigate to vehicle detail screen.
class NearbyVehicleCard extends StatelessWidget {
  const NearbyVehicleCard({
    super.key,
    required this.vehicle,
    required this.onTap,
  });

  final NearbyVehicle vehicle;
  final VoidCallback onTap;

  IconData _vehicleIcon(VehicleType type) => switch (type) {
    VehicleType.kamyonet => Icons.local_shipping,
    VehicleType.panelvan => Icons.airport_shuttle,
    VehicleType.kamyon => Icons.fire_truck,
    VehicleType.tir => Icons.rv_hookup,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final radius = context.appRadius;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius.card),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius.card),
        child: Padding(
          padding: EdgeInsets.all(spacing.s16),
          child: Row(
            children: [
              // Vehicle type icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _vehicleIcon(vehicle.type),
                  color: colors.primary,
                  size: 28,
                ),
              ),
              SizedBox(width: spacing.s12),
              // Vehicle info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bodySmall(
                      vehicle.driver.fullName,
                      color: colors.textPrimary,
                    ),
                    SizedBox(height: spacing.s4),
                    Row(
                      children: [
                        _infoChip(
                          context,
                          vehicle.type.label,
                          Icons.local_shipping_outlined,
                        ),
                        SizedBox(width: spacing.s8),
                        _infoChip(
                          context,
                          '${vehicle.capacityKg} kg',
                          Icons.scale_outlined,
                        ),
                      ],
                    ),
                    SizedBox(height: spacing.s4),
                    AppText.caption(
                      vehicle.plateNumber,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
              // Distance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.s8,
                      vertical: spacing.s4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AppText.caption(
                      vehicle.formattedDistance,
                      color: colors.primary,
                    ),
                  ),
                  SizedBox(height: spacing.s4),
                  Icon(
                    Icons.chevron_right,
                    color: colors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(BuildContext context, String label, IconData icon) {
    final colors = context.appColors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.textSecondary),
        const SizedBox(width: 4),
        AppText.caption(label, color: colors.textSecondary),
      ],
    );
  }
}
