import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_provider.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/audit_log/screens/audit_log_screen.dart';
import '../../features/hand_history/screens/hand_history_screen.dart';
import '../../features/players/screens/player_detail_screen.dart';
import '../../features/players/screens/player_list_screen.dart';
import '../../features/graphic_editor/screens/ge_detail_screen.dart';
import '../../features/graphic_editor/screens/ge_hub_screen.dart';
import '../../features/lobby/screens/event_list_screen.dart';
import '../../features/lobby/screens/series_list_screen.dart';
import '../../features/lobby/screens/table_detail_screen.dart';
import '../../features/lobby/screens/table_list_screen.dart';
import '../../features/staff/screens/staff_list_screen.dart';
import '../../features/settings/screens/settings_layout.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/series',
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final isAuth = auth.status == AuthStatus.authenticated;
      final isLoginRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/forgot-password';
      if (!isAuth && !isLoginRoute) {
        return '/login?redirect=${state.matchedLocation}';
      }
      if (isAuth && isLoginRoute) return '/series';
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
            path: '/series',
            builder: (context, state) => const SeriesListScreen(),
          ),
          GoRoute(
            path: '/series/:seriesId/events',
            builder: (context, state) => EventListScreen(
              seriesId: int.parse(state.pathParameters['seriesId']!),
            ),
          ),
          GoRoute(
            path: '/events/:eventId/tables',
            builder: (context, state) {
              final dayParam = state.uri.queryParameters['day'];
              return TableListScreen(
                eventId: int.parse(state.pathParameters['eventId']!),
                initialDay: dayParam != null ? int.tryParse(dayParam) : null,
              );
            },
          ),
          GoRoute(
            path: '/tables/:tableId',
            builder: (context, state) => TableDetailScreen(
              tableId: int.parse(state.pathParameters['tableId']!),
            ),
          ),
          GoRoute(
            path: '/players',
            builder: (context, state) =>
                const PlayerListScreen(),
          ),
          GoRoute(
            path: '/players/:playerId',
            builder: (context, state) => PlayerDetailScreen(
              playerId: state.pathParameters['playerId']!,
            ),
          ),
          GoRoute(
            path: '/staff',
            builder: (context, state) =>
                const StaffListScreen(),
          ),
          GoRoute(
            path: '/hand-history',
            builder: (context, state) => const HandHistoryScreen(),
          ),
          GoRoute(
            path: '/settings',
            redirect: (context, state) => '/settings/outputs',
          ),
          GoRoute(
            path: '/settings/:section',
            builder: (context, state) => SettingsLayout(
              section: state.pathParameters['section'] ?? 'outputs',
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
            path: '/audit-logs',
            builder: (context, state) => const AuditLogScreen(),
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
                icon: Icon(Icons.emoji_events),
                label: Text('Series'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Players'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.badge),
                label: Text('Staff'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history),
                label: Text('Hands'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.brush),
                label: Text('GFX Editor'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long),
                label: Text('Audit'),
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
    if (location.startsWith('/series') ||
        location.startsWith('/events') ||
        location.startsWith('/tables')) {
      return 0;
    }
    if (location.startsWith('/players')) return 1;
    if (location.startsWith('/staff')) return 2;
    if (location.startsWith('/hand-history')) return 3;
    if (location.startsWith('/settings')) return 4;
    if (location.startsWith('/graphic-editor')) return 5;
    if (location.startsWith('/audit')) return 6;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    const routes = [
      '/series',
      '/players',
      '/staff',
      '/hand-history',
      '/settings',
      '/graphic-editor',
      '/audit-logs',
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
