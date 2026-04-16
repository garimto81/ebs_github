// GoRouter configuration (BS-05-00 §AT screen catalogue).
//
// Routes:
//   /login      → AT-00 Login
//   /main       → AT-01 Main (default after auth)
//   /main/stats → AT-04 Statistics
//   /main/rfid  → AT-05 RFID Register
//
// Auth redirect: unauthenticated → /login
// Modals (AT-03, AT-06, AT-07) stay as showDialog (not routed).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_provider.dart';
import '../features/command_center/screens/at_00_login_screen.dart';
import '../features/command_center/screens/at_01_main_screen.dart';
import '../features/command_center/screens/at_04_statistics_screen.dart';
import '../features/command_center/screens/at_05_rfid_register_screen.dart';

// ---------------------------------------------------------------------------
// Route paths
// ---------------------------------------------------------------------------

class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const main = '/main';
  static const stats = '/main/stats';
  static const rfid = '/main/rfid';
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.main,
    redirect: (context, state) {
      final isAuthenticated =
          authState.status == AuthStatus.authenticated;
      final isAuthenticating =
          authState.status == AuthStatus.authenticating;
      final isOnLogin = state.matchedLocation == AppRoutes.login;

      // Authenticating → stay on current page (loading handled in-page)
      if (isAuthenticating) return null;

      // Not authenticated → force login
      if (!isAuthenticated && !isOnLogin) return AppRoutes.login;

      // Authenticated but on login → go to main
      if (isAuthenticated && isOnLogin) return AppRoutes.main;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const At00LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.main,
        builder: (context, state) => const At01MainScreen(),
        routes: [
          GoRoute(
            path: 'stats',
            builder: (context, state) => const At04StatisticsScreen(),
          ),
          GoRoute(
            path: 'rfid',
            builder: (context, state) => const At05RfidRegisterScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const At01MainScreen(),
  );
});
