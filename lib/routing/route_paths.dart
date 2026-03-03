/// Centralized route paths for the entire application.
///
/// All route paths should be defined here to ensure consistency
/// and prevent typos. Use these constants throughout the app
/// instead of hardcoded strings.
class AppRoutes {
  AppRoutes._();

  // Auth routes
  static const login = '/login';
  static const register = '/register';

  // Driver registration (public — from login screen)
  static const driverRegister = '/driver-register';

  // Search routes (public — accessible by guests and authenticated users)
  static const search = '/';
  static const vehicleDetail = '/vehicle-detail';

  // Driver dashboard routes (authenticated only)
  static const driverDashboard = '/dashboard';
  static const addVehicle = '/dashboard/add-vehicle';
  static const driverProfile = '/profile';

  // Document upload (authenticated only)
  static const documentUpload = '/dashboard/documents';

  // Legacy compatibility
  static const home = '/';
  static const profile = '/profile';
  static const components = '/components';
}
