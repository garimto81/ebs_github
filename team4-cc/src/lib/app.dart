// Root widget for ebs_cc.
//
// Determines startup screen: AT-00 Login → AT-01 Main (BS-05-00 §화면 카탈로그).
// Routes based on AuthState:
//   unauthenticated/error → AT-00 Login
//   authenticating        → Loading spinner
//   authenticated         → AT-01 Main
//
// Named routes for screen navigation (P4-3):
//   /             → auth-gated redirect
//   /login        → AT-00 Login
//   /main         → AT-01 Main (default)
//   /main/stats   → AT-04 Statistics
//   /main/rfid    → AT-05 RFID Register
//
// Modals (shown as Dialog, not route):
//   settings      → AT-06 Game Settings Modal
//   player-edit   → AT-07 Player Edit Modal

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_provider.dart';
import 'features/command_center/screens/at_00_login_screen.dart';
import 'features/command_center/screens/at_01_main_screen.dart';
import 'features/command_center/screens/at_04_statistics_screen.dart';
import 'features/command_center/screens/at_05_rfid_register_screen.dart';
import 'features/command_center/screens/at_06_game_settings_modal.dart';
import 'features/command_center/screens/at_07_player_edit_modal.dart';

// ---------------------------------------------------------------------------
// Route names
// ---------------------------------------------------------------------------

class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const main = '/main';
  static const stats = '/main/stats';
  static const rfid = '/main/rfid';

  // Modal identifiers (not actual routes)
  static const settingsModal = 'settings';
  static const playerEditModal = 'player-edit';
}

// ---------------------------------------------------------------------------
// App Widget
// ---------------------------------------------------------------------------

class EbsCcApp extends ConsumerWidget {
  const EbsCcApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'EBS CC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      initialRoute: AppRoutes.main,
      onGenerateRoute: (settings) =>
          _generateRoute(settings, authState),
    );
  }

  Route<dynamic>? _generateRoute(
    RouteSettings settings,
    AuthState authState,
  ) {
    // Auth guard: redirect to login if not authenticated
    final isAuthenticated =
        authState.status == AuthStatus.authenticated;
    final isAuthenticating =
        authState.status == AuthStatus.authenticating;

    if (!isAuthenticated && !isAuthenticating) {
      return MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.login),
        builder: (_) => const At00LoginScreen(),
      );
    }

    if (isAuthenticating) {
      return MaterialPageRoute<void>(
        builder: (_) => const _LoadingScreen(),
      );
    }

    // Authenticated routes
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const At00LoginScreen(),
        );

      case AppRoutes.main:
      case '/':
        return MaterialPageRoute<void>(
          settings: const RouteSettings(name: AppRoutes.main),
          builder: (_) => const At01MainScreen(),
        );

      case AppRoutes.stats:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const At04StatisticsScreen(),
        );

      case AppRoutes.rfid:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const At05RfidRegisterScreen(),
        );

      default:
        // Unknown route → main
        return MaterialPageRoute<void>(
          settings: const RouteSettings(name: AppRoutes.main),
          builder: (_) => const At01MainScreen(),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Navigation helper (static, usable from any widget)
// ---------------------------------------------------------------------------

class AppNavigator {
  AppNavigator._();

  /// Push a named route.
  static Future<T?> pushNamed<T>(BuildContext context, String routeName) {
    return Navigator.of(context).pushNamed<T>(routeName);
  }

  /// Replace current route with a named route.
  static Future<T?> replaceNamed<T>(BuildContext context, String routeName) {
    return Navigator.of(context)
        .pushReplacementNamed<T, void>(routeName);
  }

  /// Pop back to main screen.
  static void popToMain(BuildContext context) {
    Navigator.of(context).popUntil(
      (route) => route.settings.name == AppRoutes.main || route.isFirst,
    );
  }

  /// Show Game Settings modal (AT-06).
  static Future<void> showSettingsModal(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const At06GameSettingsModal(),
    );
  }

  /// Show Player Edit modal (AT-07).
  ///
  /// [seatNo] is 1-based seat number.
  static Future<void> showPlayerEditModal(
    BuildContext context, {
    required int seatNo,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => At07PlayerEditModal(seatNo: seatNo),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading screen
// ---------------------------------------------------------------------------

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Authenticating...'),
          ],
        ),
      ),
    );
  }
}
