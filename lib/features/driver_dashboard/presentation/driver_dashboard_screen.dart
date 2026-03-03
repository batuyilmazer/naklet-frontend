import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/driver/driver.dart';
import '../../../core/models/driver/driver_status.dart';
import '../../../core/models/driver/vehicle.dart';
import '../../../theme/extensions/theme_context_extensions.dart';
import '../../../ui/atoms/app_button.dart';
import '../../../ui/atoms/app_text.dart';
import '../../../features/auth/presentation/auth_notifier.dart';
import '../../../routing/route_paths.dart';
import '../data/driver_dashboard_repository.dart';
import 'package:go_router/go_router.dart';

/// Driver dashboard screen showing approval status, vehicle list, and controls.
class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final _repository = DriverDashboardRepository();
  Driver? _driver;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final driver = await _repository.getDriverProfile();
      if (mounted) {
        setState(() {
          _driver = driver;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Profil bilgileri yüklenemedi.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleVehicleActive(Vehicle vehicle) async {
    try {
      await _repository.toggleVehicleActive(
        vehicleId: vehicle.id,
        isActive: !vehicle.isActive,
      );
      await _loadDriverData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Araç durumu güncellenemedi')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pano'),
        actions: [
          IconButton(
            onPressed: () {
              final authNotifier = Provider.of<AuthNotifier>(
                context,
                listen: false,
              );
              authNotifier.logout();
              context.go(AppRoutes.login);
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış',
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colors.error),
                  SizedBox(height: spacing.s16),
                  AppText.bodySmall(_error!, color: colors.textSecondary),
                  SizedBox(height: spacing.s16),
                  TextButton.icon(
                    onPressed: _loadDriverData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDriverData,
              child: ListView(
                padding: EdgeInsets.all(spacing.s16),
                children: [
                  // Approval status card
                  _buildStatusCard(context),
                  SizedBox(height: spacing.s16),
                  // Vehicle list header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.bodySmall(
                        'Araçlarım',
                        color: colors.textPrimary,
                      ),
                      TextButton.icon(
                        onPressed: () => context.push(AppRoutes.addVehicle),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Yeni Araç'),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.s8),
                  // Vehicle list
                  if (_driver!.vehicles.isEmpty)
                    _buildEmptyVehicles(context)
                  else
                    for (final vehicle in _driver!.vehicles) ...[
                      _buildVehicleItem(context, vehicle),
                      SizedBox(height: spacing.s8),
                    ],
                  SizedBox(height: spacing.s16),
                  // Documents button
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.documentUpload),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Belgelerimi Yükle'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: spacing.s16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final radius = context.appRadius;
    final status = _driver?.status ?? DriverStatus.PENDING;

    final (Color bgColor, Color textColor, IconData icon, String message) =
        switch (status) {
      DriverStatus.PENDING => (
          Colors.orange.withValues(alpha: 0.1),
          Colors.orange,
          Icons.hourglass_top,
          'Profiliniz inceleniyor. Admin onayı bekleniyor.',
        ),
      DriverStatus.APPROVED => (
          Colors.green.withValues(alpha: 0.1),
          Colors.green,
          Icons.check_circle,
          'Profiliniz onaylı! Arama sonuçlarında görünüyorsunuz.',
        ),
      DriverStatus.REJECTED => (
          colors.error.withValues(alpha: 0.1),
          colors.error,
          Icons.cancel,
          'Profiliniz reddedildi. Belgelerinizi kontrol edin.',
        ),
    };

    return Card(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius.card),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.s16),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 28),
            SizedBox(width: spacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.caption(
                    'Onay Durumu: ${status.label}',
                    color: textColor,
                  ),
                  SizedBox(height: spacing.s4),
                  AppText.bodySmall(message, color: textColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleItem(BuildContext context, Vehicle vehicle) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final radius = context.appRadius;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius.card),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.s16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.local_shipping,
                color: colors.primary,
                size: 24,
              ),
            ),
            SizedBox(width: spacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodySmall(
                    '${vehicle.type.label} — ${vehicle.plateNumber}',
                    color: colors.textPrimary,
                  ),
                  SizedBox(height: spacing.s4),
                  AppText.caption(
                    '${vehicle.capacityKg} kg',
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
            Switch(
              value: vehicle.isActive,
              onChanged: (_) => _toggleVehicleActive(vehicle),
              activeThumbColor: colors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyVehicles(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(spacing.s24),
        child: Column(
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 48,
              color: colors.textSecondary,
            ),
            SizedBox(height: spacing.s12),
            AppText.bodySmall(
              'Henüz araç eklemediniz.',
              color: colors.textSecondary,
            ),
            SizedBox(height: spacing.s12),
            AppButton(
              label: 'Araç Ekle',
              onPressed: () => context.push(AppRoutes.addVehicle),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
