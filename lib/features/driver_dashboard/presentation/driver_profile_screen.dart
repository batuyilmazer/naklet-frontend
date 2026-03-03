import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/presentation/auth_notifier.dart';
import '../../../routing/route_paths.dart';
import '../../../core/models/driver/driver.dart';
import '../../../theme/extensions/theme_context_extensions.dart';
import '../../../ui/atoms/app_text.dart';
import '../data/driver_dashboard_repository.dart';

/// Driver profile viewing screen.
///
/// Shows driver's personal information (read-only for now).
class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final _repository = DriverDashboardRepository();
  Driver? _driver;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final radius = context.appRadius;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_driver == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: AppText.bodySmall(
            'Profil yüklenemedi',
            color: colors.textSecondary,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.s16),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 48,
              backgroundColor: colors.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.person,
                size: 48,
                color: colors.primary,
              ),
            ),
            SizedBox(height: spacing.s16),
            Text(
              'Sürücü Profili',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
            ),
            SizedBox(height: spacing.s4),
            AppText.bodySmall(
              _driver!.status.label,
              color: _driver!.isApproved ? Colors.green : Colors.orange,
            ),
            SizedBox(height: spacing.s24),
            // Profile details
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius.card),
              ),
              child: Padding(
                padding: EdgeInsets.all(spacing.s16),
                child: Column(
                  children: [
                    _profileRow(
                      context,
                      Icons.person_outline,
                      'Ad',
                      _driver!.firstName ?? '—',
                    ),
                    Divider(height: spacing.s24),
                    _profileRow(
                      context,
                      Icons.person,
                      'Soyad',
                      _driver!.lastName ?? '—',
                    ),
                    Divider(height: spacing.s24),
                    _profileRow(
                      context,
                      Icons.phone_outlined,
                      'Telefon',
                      _driver!.phoneNumber ?? '—',
                    ),
                    Divider(height: spacing.s24),
                    _profileRow(
                      context,
                      Icons.badge_outlined,
                      'Durum',
                      _driver!.status.label,
                    ),
                    if (_driver!.rejectionReason != null) ...[
                      Divider(height: spacing.s24),
                      _profileRow(
                        context,
                        Icons.info_outline,
                        'Red Sebebi',
                        _driver!.rejectionReason!,
                      ),
                    ],
                    Divider(height: spacing.s24),
                    _profileRow(
                      context,
                      Icons.local_shipping,
                      'Araç Sayısı',
                      '${_driver!.vehicles.length}',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final colors = context.appColors;
    final spacing = context.appSpacing;

    return Row(
      children: [
        Icon(icon, size: 20, color: colors.primary),
        SizedBox(width: spacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.caption(label, color: colors.textSecondary),
              SizedBox(height: spacing.s4),
              AppText.bodySmall(value, color: colors.textPrimary),
            ],
          ),
        ),
      ],
    );
  }
}
