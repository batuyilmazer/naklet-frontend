import 'package:go_router/go_router.dart';

import '../../features/driver_dashboard/presentation/driver_dashboard_screen.dart';
import '../../features/driver_dashboard/presentation/add_vehicle_screen.dart';
import '../../features/driver_dashboard/presentation/driver_profile_screen.dart';
import '../../features/documents/presentation/document_upload_screen.dart';
import '../route_paths.dart';

/// Route definitions for driver-specific features (authenticated only).
class DriverRoutes {
  static List<RouteBase> get routes => [
    GoRoute(
      path: AppRoutes.driverDashboard,
      name: 'dashboard',
      builder: (context, state) => const DriverDashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.addVehicle,
      name: 'addVehicle',
      builder: (context, state) => const AddVehicleScreen(),
    ),
    GoRoute(
      path: AppRoutes.driverProfile,
      name: 'driverProfile',
      builder: (context, state) => const DriverProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.documentUpload,
      name: 'documentUpload',
      builder: (context, state) => const DocumentUploadScreen(),
    ),
  ];
}
