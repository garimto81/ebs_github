import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_provider.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/graphic_editor/screens/ge_detail_screen.dart';
import '../../features/graphic_editor/screens/ge_hub_screen.dart';
import '../../features/lobby/screens/lobby_dashboard_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/staff/screens/staff_list_screen.dart';
import '../../features/settings/screens/settings_layout.dart';
import '../../features/lobby/screens/table_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/lobby',
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final isAuth = auth.status == AuthStatus.authenticated;
      final isLoginRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/forgot-password';
      if (!isAuth && !isLoginRoute) {
        return '/login?redirect=${state.matchedLocation}';
      }
      if (isAuth && isLoginRoute) return '/lobby';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: '/lobby',
            builder: (context, state) => const LobbyDashboardScreen(),
          ),
          GoRoute(
            path: '/tables/:tableId',
            builder: (context, state) => TableDetailScreen(
              tableId: int.parse(state.pathParameters['tableId']!),
            ),
          ),
          GoRoute(
            path: '/staff',
            builder: (context, state) => const StaffListScreen(),
          ),
          GoRoute(
            path: '/settings',
            redirect: (context, state) => '/settings/blind-structure',
          ),
          GoRoute(
            path: '/settings/:section',
            builder: (context, state) => SettingsLayout(
              section: state.pathParameters['section'] ?? 'blind-structure',
            ),
          ),
          GoRoute(
            path: '/graphic-editor',
            builder: (context, state) => const GeHubScreen(),
          ),
          GoRoute(
            path: '/graphic-editor/:skinId',
            builder: (context, state) => GeDetailScreen(
              skinId: state.pathParameters['skinId']!,
            ),
          ),
          GoRoute(
            path: '/reports',
            redirect: (context, state) => '/reports/hands-summary',
          ),
          GoRoute(
            path: '/reports/:type',
            builder: (context, state) => ReportsScreen(
              reportType: state.pathParameters['type'] ?? 'hands-summary',
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        const _PlaceholderScreen(title: '404 Not Found'),
  );
});

class _AppShell extends StatelessWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex(
              GoRouterState.of(context).matchedLocation,
            ),
            onDestinationSelected: (index) => _navigate(context, index),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Lobby'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.badge),
                label: Text('Staff'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.brush),
                label: Text('GFX'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assessment),
                label: Text('Reports'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _selectedIndex(String location) {
    if (location.startsWith('/lobby') || location.startsWith('/tables')) {
      return 0;
    }
    if (location.startsWith('/staff')) return 1;
    if (location.startsWith('/settings')) return 2;
    if (location.startsWith('/graphic-editor')) return 3;
    if (location.startsWith('/reports')) return 4;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    const routes = [
      '/lobby',
      '/staff',
      '/settings/blind-structure',
      '/graphic-editor',
      '/reports/hands-summary',
    ];
    context.go(routes[index]);
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
