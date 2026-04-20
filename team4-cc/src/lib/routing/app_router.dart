// GoRouter configuration (BS-05-00 §AT screen catalogue).
//
// Routes:
//   /splash     → SG-002 engine-probe splash (initial)
//   /login      → AT-00 Login
//   /main       → AT-01 Main (default after auth)
//   /main/stats → AT-04 Statistics
//   /main/rfid  → AT-05 RFID Register
//
// Auth redirect: unauthenticated → /login
// SG-002 redirect: engineConnection.stage == connecting → /splash
// Modals (AT-03, AT-06, AT-07) stay as showDialog (not routed).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_provider.dart';
import '../features/command_center/providers/engine_connection_provider.dart';
import '../features/command_center/screens/at_00_login_screen.dart';
import '../features/command_center/screens/at_01_main_screen.dart';
import '../features/command_center/screens/at_04_statistics_screen.dart';
import '../features/command_center/screens/at_05_rfid_register_screen.dart';
import '../features/splash/splash_screen.dart';

// ---------------------------------------------------------------------------
// Route paths
// ---------------------------------------------------------------------------

class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const main = '/main';
  static const stats = '/main/stats';
  static const rfid = '/main/rfid';
}

// ---------------------------------------------------------------------------
// Router-refresh notifier — ticks when auth or engine-connection changes so
// GoRouter re-evaluates redirect().
// ---------------------------------------------------------------------------

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
    _ref.listen<EngineConnectionState>(
        engineConnectionProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final engine = ref.read(engineConnectionProvider);

      final isAuthenticated =
          authState.status == AuthStatus.authenticated;
      final isAuthenticating =
          authState.status == AuthStatus.authenticating;
      final isOnLogin = state.matchedLocation == AppRoutes.login;
      final isOnSplash = state.matchedLocation == AppRoutes.splash;

      // SG-002: while the engine is still probing, force Splash.
      if (engine.stage == EngineConnectionStage.connecting) {
        return isOnSplash ? null : AppRoutes.splash;
      }

      // Engine probe done — leave splash.
      if (isOnSplash) {
        return isAuthenticated ? AppRoutes.main : AppRoutes.login;
      }

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
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
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
