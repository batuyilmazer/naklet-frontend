import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/search/presentation/search_screen.dart';
import '../../features/search/presentation/vehicle_detail_screen.dart';
import '../../features/driver_dashboard/presentation/driver_dashboard_screen.dart';
import '../../features/driver_dashboard/presentation/add_vehicle_screen.dart';
import '../../features/driver_dashboard/presentation/driver_profile_screen.dart';
import '../../features/documents/presentation/document_upload_screen.dart';
import '../../core/models/search/nearby_vehicle.dart';
import '../../ui/layout/main_shell.dart';
import '../route_paths.dart';

/// Route definitions for the shell-based layout (bottom navigation).
///
/// Naklet.net shell with 3 tabs:
/// - Keşfet (Search): Public — accessible by guests and drivers
/// - Pano (Dashboard): Driver only
/// - Profil (Profile): Driver only
class ShellRoutes {
  static List<RouteBase> get routes => [
    ShellRoute(
      builder: (context, state, child) =>
          MainShell(tabs: _buildShellTabs(), child: child),
      routes: [
        GoRoute(
          path: AppRoutes.search,
          name: 'home',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: AppRoutes.driverDashboard,
          name: 'dashboard',
          builder: (context, state) => const DriverDashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.driverProfile,
          name: 'profile',
          builder: (context, state) => const DriverProfileScreen(),
        ),
      ],
    ),
    // Non-shell routes (push on top of shell)
    GoRoute(
      path: AppRoutes.vehicleDetail,
      name: 'vehicleDetail',
      builder: (context, state) {
        final vehicle = state.extra as NearbyVehicle;
        return VehicleDetailScreen(vehicle: vehicle);
      },
    ),
    GoRoute(
      path: AppRoutes.addVehicle,
      name: 'addVehicle',
      builder: (context, state) => const AddVehicleScreen(),
    ),
    GoRoute(
      path: AppRoutes.documentUpload,
      name: 'documentUpload',
      builder: (context, state) => const DocumentUploadScreen(),
    ),
  ];

  static List<ShellTabConfig> _buildShellTabs() => const [
    ShellTabConfig(
      label: 'Keşfet',
      icon: Icons.search,
      path: AppRoutes.search,
    ),
    ShellTabConfig(
      label: 'Pano',
      icon: Icons.dashboard,
      path: AppRoutes.driverDashboard,
    ),
    ShellTabConfig(
      label: 'Profil',
      icon: Icons.person,
      path: AppRoutes.driverProfile,
    ),
  ];
}
