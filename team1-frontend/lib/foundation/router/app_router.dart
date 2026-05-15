import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_provider.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/graphic_editor/screens/ge_detail_screen.dart';
import '../../features/graphic_editor/screens/ge_hub_screen.dart';
import '../../features/lobby/screens/lobby_events_screen.dart';
import '../../features/lobby/screens/lobby_flights_screen.dart';
import '../../features/lobby/screens/lobby_players_screen.dart';
import '../../features/lobby/screens/lobby_tables_screen.dart';
import '../../features/lobby/screens/series_screen.dart';
import '../../features/lobby/screens/table_detail_screen.dart';
import '../../features/hand_history/screens/hand_detail_screen.dart';
import '../../features/hand_history/screens/hand_history_screen.dart';
import '../../features/lobby/widgets/lobby_shell.dart';
import '../../features/players/screens/players_screen.dart';
import '../../features/staff/screens/staff_list_screen.dart';
import '../../features/settings/screens/settings_layout.dart';
import '../observability/logger.dart';
import '../observability/logger_provider.dart';

/// auth state 변화를 GoRouter 에 통지하는 ChangeNotifier 어댑터.
/// `routerProvider` 가 `ref.listen(authProvider)` 로 이 notifier 를 갱신하면,
/// GoRouter 가 자동으로 redirect 콜백을 재평가한다.
class _AuthChangeNotifier extends ChangeNotifier {
  AuthStatus _last;
  _AuthChangeNotifier(this._last);

  void update(AuthStatus next) {
    if (_last == next) return;
    _last = next;
    notifyListeners();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthChangeNotifier(ref.read(authProvider).status);
  ref.listen<AuthState>(authProvider, (_, next) => notifier.update(next.status));
  ref.onDispose(notifier.dispose);

  final logger = ref.watch(appLoggerProvider);

  return GoRouter(
    initialLocation: '/lobby',
    refreshListenable: notifier,
    observers: [_NavigationLogger(logger)],
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final isAuth = auth.status == AuthStatus.authenticated;
      final loc = state.matchedLocation;
      final isLoginRoute = loc == '/login' || loc == '/forgot-password';
      if (!isAuth && !isLoginRoute) {
        final encoded = Uri.encodeComponent(loc);
        return '/login?redirect=$encoded';
      }
      if (isAuth && isLoginRoute) return '/lobby';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      // ── 2026-05-06 Phase 1: Sidebar 통합 — 모든 라우트가 LobbyShell 공통 chrome 사용 ──
      ShellRoute(
        builder: (_, __, child) => LobbyShell(child: child),
        routes: [
          // /lobby → Series 목록 (정본 명세 정합, iter 1).
          GoRoute(
            path: '/lobby',
            redirect: (_, __) => '/lobby/series',
          ),
          // ── Drilldown ──
          // NoTransitionPage: HTML 웹처럼 즉시 전환 (platform 슬라이드/페이드 제거).
          // ShellRoute 내부이므로 LobbyShell chrome은 그대로 유지 — content 영역만 교체.
          GoRoute(
            path: '/lobby/series',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SeriesScreen(),
            ),
          ),
          GoRoute(
            path: '/lobby/events/:seriesId',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: LobbyEventsScreen(
                seriesId: int.parse(state.pathParameters['seriesId']!),
              ),
            ),
          ),
          GoRoute(
            path: '/lobby/flights/:eventId',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: LobbyFlightsScreen(
                eventId: int.parse(state.pathParameters['eventId']!),
              ),
            ),
          ),
          GoRoute(
            path: '/lobby/flight/:flightId/tables',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: LobbyTablesScreen(
                flightId: int.parse(state.pathParameters['flightId']!),
              ),
            ),
          ),
          GoRoute(
            path: '/lobby/flight/:flightId/players',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: LobbyPlayersScreen(
                flightId: int.parse(state.pathParameters['flightId']!),
              ),
            ),
          ),
          GoRoute(
            path: '/tables/:tableId',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: TableDetailScreen(
                tableId: int.parse(state.pathParameters['tableId']!),
              ),
            ),
          ),
          // ── Tools (top-level meta) ──
          GoRoute(
            path: '/players',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const PlayersScreen(),
            ),
          ),
          GoRoute(
            path: '/staff',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const StaffListScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            redirect: (_, __) => '/settings/outputs',
          ),
          GoRoute(
            path: '/settings/:section',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: SettingsLayout(
                section: state.pathParameters['section'] ?? 'outputs',
              ),
            ),
          ),
          GoRoute(
            path: '/graphic-editor',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const GeHubScreen(),
            ),
          ),
          GoRoute(
            path: '/graphic-editor/:skinId',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: GeDetailScreen(
                skinId: state.pathParameters['skinId']!,
              ),
            ),
          ),
          // ── Hand History (Cycle 21 W3 — Reports 폐기 후 독립 격상) ──
          // SSOT: docs/2. Development/2.1 Frontend/Lobby/Hand_History.md
          //       docs/2. Development/2.2 Backend/APIs/Players_HandHistory_API.md
          GoRoute(
            path: '/hand-history',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const HandHistoryScreen(),
            ),
          ),
          GoRoute(
            path: '/hand-history/:id',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: HandDetailScreen(
                handId: int.parse(state.pathParameters['id']!),
              ),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) {
      logger.warning('Router 404', context: {
        'location': state.matchedLocation,
        'uri': state.uri.toString(),
      });
      return const _PlaceholderScreen(title: '404 Not Found');
    },
    debugLogDiagnostics: kDebugMode,
  );
});

class _NavigationLogger extends NavigatorObserver {
  _NavigationLogger(this._logger);
  final AppLogger _logger;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logger.breadcrumb('navigation', 'push', data: {
      'to': route.settings.name,
      'from': previousRoute?.settings.name,
    });
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logger.breadcrumb('navigation', 'pop', data: {
      'from': route.settings.name,
      'to': previousRoute?.settings.name,
    });
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _logger.breadcrumb('navigation', 'replace', data: {
      'from': oldRoute?.settings.name,
      'to': newRoute?.settings.name,
    });
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
