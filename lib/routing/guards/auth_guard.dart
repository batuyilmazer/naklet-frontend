import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../route_paths.dart';

/// Authentication guard that handles route protection based on auth state.
///
/// Route categories:
/// - **Entry routes** (landing, login, register, driverRegister): Redirect to
///   home if already authenticated.
/// - **Public routes** (landing, search, vehicleDetail): Accessible by
///   everyone (guest + auth).
/// - **Protected routes** (dashboard, addVehicle, driverProfile, documents): Auth only.
class AuthGuard {
  /// Determines if a redirect is needed based on authentication state.
  static String? redirect(
    BuildContext context,
    GoRouterState state,
    AuthNotifier authNotifier,
  ) {
    final authState = authNotifier.state;
    final isLoggedIn = authNotifier.isLoggedIn;
    final currentPath = state.matchedLocation;

    final isAuthRoute = _isAuthRoute(currentPath);
    final isPublicRoute = _isPublicRoute(currentPath);

    // If still loading, don't redirect yet
    if (authState is AuthLoadingState) {
      return null;
    }

    // Public routes are accessible by everyone — no redirect needed
    if (isPublicRoute) {
      return null;
    }

    // If not logged in and trying to access protected route
    if (!isLoggedIn && !isAuthRoute) {
      return AppRoutes.landing;
    }

    // Authenticated users are redirected away from pre-auth entry routes.
    // Guest users can still access auth routes.
    if (authNotifier.isAuthenticated &&
        (isAuthRoute || currentPath == AppRoutes.landing)) {
      return AppRoutes.home;
    }

    // Guest users cannot access driver-only routes
    if (authNotifier.isGuest && _isDriverOnlyRoute(currentPath)) {
      return AppRoutes.home;
    }

    return null;
  }

  /// Auth routes — redirect away from if logged in.
  static bool _isAuthRoute(String path) {
    return path == AppRoutes.login ||
        path == AppRoutes.register ||
        path == AppRoutes.driverRegister;
  }

  /// Public routes — accessible by everyone, no auth required.
  static bool _isPublicRoute(String path) {
    return path == AppRoutes.landing ||
        path == AppRoutes.search ||
        path.startsWith(AppRoutes.vehicleDetail);
  }

  /// Driver-only routes — require authenticated (not guest) user.
  static bool _isDriverOnlyRoute(String path) {
    return path == AppRoutes.driverDashboard ||
        path == AppRoutes.addVehicle ||
        path == AppRoutes.driverProfile ||
        path == AppRoutes.documentUpload;
  }
}
