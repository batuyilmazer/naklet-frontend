import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/presentation/auth_notifier.dart';
import 'route_paths.dart';
import 'guards/auth_guard.dart';
import 'builders/auth_routes.dart';
import 'builders/search_routes.dart';
import 'builders/driver_routes.dart';
import 'builders/shell_routes.dart';

/// Available routing modes for the application.
///
/// - [RoutingMode.plain]: Use feature routes directly (no shell layout).
/// - [RoutingMode.shell]: Host authenticated area inside a ShellRoute-based
///   layout (e.g. bottom navigation).
enum RoutingMode { plain, shell }

/// Main application router configuration.
class AppRouter {
  static GoRouter createRouter(
    BuildContext context, {
    RoutingMode mode = RoutingMode.plain,
  }) {
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);

    return GoRouter(
      initialLocation: AppRoutes.login,

      redirect: (context, state) =>
          AuthGuard.redirect(context, state, authNotifier),

      refreshListenable: authNotifier,

      routes: [
        ...AuthRoutes.routes,
        if (mode == RoutingMode.shell) ...ShellRoutes.routes,
        if (mode == RoutingMode.plain) ...[
          ...SearchRoutes.routes,
          ...DriverRoutes.routes,
        ],
      ],

      errorBuilder: (context, state) =>
          Scaffold(body: Center(child: Text('Sayfa bulunamadı: ${state.uri}'))),
    );
  }
}
