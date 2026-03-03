import 'package:go_router/go_router.dart';

import '../../features/search/presentation/search_screen.dart';
import '../../features/search/presentation/vehicle_detail_screen.dart';
import '../../core/models/search/nearby_vehicle.dart';
import '../route_paths.dart';

/// Route definitions for the search feature (public routes).
class SearchRoutes {
  static List<RouteBase> get routes => [
    GoRoute(
      path: AppRoutes.search,
      name: 'search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: AppRoutes.vehicleDetail,
      name: 'vehicleDetail',
      builder: (context, state) {
        final vehicle = state.extra as NearbyVehicle;
        return VehicleDetailScreen(vehicle: vehicle);
      },
    ),
  ];
}
