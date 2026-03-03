import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/driver/vehicle_type.dart';
import '../../../core/models/search/nearby_vehicle.dart';
import '../../../theme/extensions/theme_context_extensions.dart';
import '../../../ui/atoms/app_text.dart';

/// Vehicle detail screen showing full driver and vehicle information.
///
/// Displays driver profile, vehicle specs, distance info, and contact buttons.
class VehicleDetailScreen extends StatelessWidget {
  const VehicleDetailScreen({super.key, required this.vehicle});

  final NearbyVehicle vehicle;

  IconData _vehicleIcon(VehicleType type) => switch (type) {
    VehicleType.KAMYONET => Icons.local_shipping,
    VehicleType.PANELVAN => Icons.airport_shuttle,
    VehicleType.KAMYON => Icons.fire_truck,
    VehicleType.TIR => Icons.rv_hookup,
  };

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Araç Detayı'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver info card
            _buildDriverCard(context),
            SizedBox(height: spacing.s16),
            // Vehicle info card
            _buildVehicleCard(context),
            SizedBox(height: spacing.s16),
            // Distance info
            _buildDistanceCard(context),
            SizedBox(height: spacing.s24),
            // Contact buttons
            _buildContactButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final radius = context.appRadius;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius.card),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colors.primary.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.person,
                    size: 32,
                    color: colors.primary,
                  ),
                ),
                SizedBox(width: spacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.bodySmall(
                        'Sürücü',
                        color: colors.textSecondary,
                      ),
                      SizedBox(height: spacing.s4),
                      Text(
                        vehicle.driver.fullName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final radius = context.appRadius;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius.card),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _vehicleIcon(vehicle.type),
                  color: colors.primary,
                  size: 24,
                ),
                SizedBox(width: spacing.s8),
                AppText.bodySmall(
                  'Araç Bilgileri',
                  color: colors.textPrimary,
                ),
              ],
            ),
            SizedBox(height: spacing.s16),
            _detailRow(context, 'Araç Tipi', vehicle.type.label),
            SizedBox(height: spacing.s12),
            _detailRow(context, 'Plaka', vehicle.plateNumber),
            SizedBox(height: spacing.s12),
            _detailRow(context, 'Kapasite', '${vehicle.capacityKg} kg'),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceCard(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final radius = context.appRadius;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius.card),
      ),
      color: colors.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: EdgeInsets.all(spacing.s16),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: colors.primary,
              size: 24,
            ),
            SizedBox(width: spacing.s12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.caption('Mesafe', color: colors.textSecondary),
                SizedBox(height: spacing.s4),
                Text(
                  vehicle.formattedDistance,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButtons(BuildContext context) {
    final spacing = context.appSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText.bodySmall(
          'İletişim',
          color: context.appColors.textPrimary,
        ),
        SizedBox(height: spacing.s12),
        // Phone call button
        FilledButton.icon(
          onPressed: () => _makePhoneCall(context),
          icon: const Icon(Icons.phone),
          label: const Text('Ara'),
          style: FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: spacing.s16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        SizedBox(height: spacing.s12),
        // WhatsApp button
        OutlinedButton.icon(
          onPressed: () => _openWhatsApp(context),
          icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
          label: const Text(
            'WhatsApp',
            style: TextStyle(color: Color(0xFF25D366)),
          ),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: spacing.s16),
            side: const BorderSide(color: Color(0xFF25D366)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final colors = context.appColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.caption(label, color: colors.textSecondary),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
        ),
      ],
    );
  }

  Future<void> _makePhoneCall(BuildContext context) async {
    // TODO: Backend'den sürücü telefon numarası gelecek.
    // Şimdilik örnek numara kullanılıyor.
    const phone = 'tel:+905001234567';
    final uri = Uri.parse(phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arama yapılamıyor')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    // TODO: Backend'den sürücü telefon numarası gelecek.
    const whatsappUrl = 'https://wa.me/905001234567';
    final uri = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp açılamıyor')),
        );
      }
    }
  }
}
