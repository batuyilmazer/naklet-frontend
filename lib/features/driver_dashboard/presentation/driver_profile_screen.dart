import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/presentation/auth_notifier.dart';
import '../../../routing/route_paths.dart';
import '../../../core/models/driver/driver.dart';
import '../../../theme/extensions/theme_context_extensions.dart';
import '../../../ui/atoms/app_text.dart';
import '../../../ui/cat_theme/cat_theme.dart';
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_driver == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pati Kimlik')),
        body: Center(
          child: AppText.bodySmall(
            'Profil yuklenemedi',
            color: colors.textSecondary,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pati Kimlik'),
        actions: [
          IconButton(
            onPressed: () {
              final authNotifier = Provider.of<AuthNotifier>(
                context,
                listen: false,
              );
              authNotifier.logout();
              context.go(AppRoutes.landing);
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Kulubeden cik',
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
              child: Icon(Icons.pets, size: 48, color: colors.primary),
            ),
            SizedBox(height: spacing.s16),
            Text(
              'Mahalledeki Kedi Kimligin',
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
                      Icons.pets_outlined,
                      'Pati adi',
                      _driver!.firstName ?? '—',
                    ),
                    Divider(height: spacing.s24),
                    _profileRow(
                      context,
                      Icons.person,
                      'Mahalle lakabi',
                      _driver!.lastName ?? '—',
                    ),
                    Divider(height: spacing.s24),
                    _profileRow(
                      context,
                      Icons.phone_outlined,
                      'Miyav hatti',
                      _driver!.phoneNumber ?? '—',
                    ),
                    Divider(height: spacing.s24),
                    _profileRow(
                      context,
                      Icons.badge_outlined,
                      'Koloni durumu',
                      _driver!.status.label,
                    ),
                    if (_driver!.rejectionReason != null) ...[
                      Divider(height: spacing.s24),
                      _profileRow(
                        context,
                        Icons.info_outline,
                        'Yaramazlik notu',
                        _driver!.rejectionReason!,
                      ),
                    ],
                    Divider(height: spacing.s24),
                    _profileRow(
                      context,
                      Icons.pets,
                      'Pati profili sayisi',
                      '${_driver!.vehicles.length}',
                    ),
                    if (_driver!.vehicles.isNotEmpty) ...[
                      Divider(height: spacing.s24),
                      _profileRow(
                        context,
                        Icons.auto_awesome,
                        'En populer profil',
                        CatThemeCopy.vehicleProfile(
                          _driver!.vehicles.first,
                          humanName: CatThemeCopy.humanDisplayName(
                            _driver!.firstName,
                            _driver!.lastName,
                          ),
                        ).nickname,
                      ),
                    ],
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
