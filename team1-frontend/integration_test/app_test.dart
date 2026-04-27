// integration_test/app_test.dart
//
// Phase 4 — E2E 자동화 시나리오 (Patrol + integration_test).
//
// Scenario A — Happy Path  (로그인 → 로비 → 리포트 → 로그아웃)
// Scenario B — 401 Token Refresh 자동 회복 (G-3 검증)
// Scenario C — Graceful Redirect /login?redirect=...  (G-1 follow-up)
// Scenario D — 위젯 빌드 에러 → ErrorBoundaryFallback 노출 + 다시 시도
// Scenario E — WS Lifecycle: 화면 전환 시 중복 connect 없음 (G-4 검증)
//
// 실행:
//   flutter test integration_test/app_test.dart -d chrome \
//     --dart-define=USE_MOCK=true
//
// Native automator 활성:
//   patrol test --target integration_test/app_test.dart

import 'package:ebs_lobby/data/local/mock_scenario_adapter.dart';
import 'package:ebs_lobby/data/remote/lobby_websocket_client.dart';
import 'package:ebs_lobby/data/remote/ws_provider.dart';
import 'package:ebs_lobby/features/auth/auth_provider.dart';
import 'package:ebs_lobby/features/auth/screens/login_screen.dart';
import 'package:ebs_lobby/features/lobby/screens/lobby_dashboard_screen.dart';
import 'package:ebs_lobby/features/reports/screens/reports_screen.dart';
import 'package:ebs_lobby/features/settings/screens/settings_layout.dart';
import 'package:ebs_lobby/foundation/error/async_value_widget.dart';
import 'package:ebs_lobby/foundation/error/error_boundary.dart';
import 'package:ebs_lobby/foundation/router/app_router.dart';
import 'package:ebs_lobby/models/enums/ws_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol_finders/patrol_finders.dart';

import '_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late E2EHarness harness;

  setUp(() {
    harness = E2EHarness();
  });

  tearDown(() {
    harness.reset();
  });

  // -------------------------------------------------------------------------
  // SCENARIO A — Happy Path (Golden Path)
  // -------------------------------------------------------------------------
  patrolWidgetTest('A: 로그인 → 로비 → 리포트 → 로그아웃 골든패스',
      ($) async {
    await $.pumpWidgetAndSettle(harness.buildTestApp());

    expect($(LoginScreen), findsOneWidget,
        reason: 'router 가 anonymous 상태에서 /login 으로 redirect');

    await $(const ValueKey('login-email')).enterText(TestCredentials.email);
    await $(const ValueKey('login-password'))
        .enterText(TestCredentials.password);
    await $(const ValueKey('login-submit')).tap();

    await $(LobbyDashboardScreen).waitUntilVisible();
    expect($(LobbyDashboardScreen), findsOneWidget);

    await $(const Icon(Icons.assessment)).tap();
    await $(ReportsScreen).waitUntilVisible();

    final container = _container($);
    await container.read(authProvider.notifier).logout();
    await $.pumpAndSettle();

    expect($(LoginScreen), findsOneWidget,
        reason: 'logout 후 router refreshListenable 가 redirect 트리거');
  });

  // -------------------------------------------------------------------------
  // SCENARIO B — 401 Token Refresh (G-3)
  // -------------------------------------------------------------------------
  patrolWidgetTest('B: 401 자동 refresh + 원 요청 재시도 (G-3)', ($) async {
    harness.scenario.queue(MockScenario.unauthorized(
      path: r'/Series$',
      method: 'GET',
    ));

    await $.pumpWidgetAndSettle(harness.buildTestApp());
    await _login($);
    await $(LobbyDashboardScreen).waitUntilVisible();

    expect(
      harness.hitContains('GET /Series => unauthorized'),
      isTrue,
      reason: 'AuthInterceptor 가 401 을 받아야 함',
    );

    expect($(AsyncWidgetKeys.error), findsNothing,
        reason: '재시도 성공 시 error 분기가 노출되면 안됨');
  });

  // -------------------------------------------------------------------------
  // SCENARIO C — Graceful Redirect (G-1 follow-up)
  // -------------------------------------------------------------------------
  patrolWidgetTest('C: /settings/outputs 진입 → 로그인 → 원위치 복귀',
      ($) async {
    await $.pumpWidgetAndSettle(harness.buildTestApp());

    final container = _container($);
    final router = container.read(routerProvider);

    router.go('/settings/outputs');
    await $.pumpAndSettle();

    expect($(LoginScreen), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      contains('redirect=%2Fsettings%2Foutputs'),
      reason: 'redirect 쿼리 파라미터가 URL 인코딩되어 보존되어야 함',
    );

    await _login($);
    await $(SettingsLayout).waitUntilVisible();
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      contains('/settings/outputs'),
    );
  });

  // -------------------------------------------------------------------------
  // SCENARIO D — Resiliency: ErrorBoundaryFallback 표시 + 다시 시도
  // -------------------------------------------------------------------------
  patrolWidgetTest('D: 위젯 build throw → ErrorBoundaryFallback 표시',
      ($) async {
    final details = FlutterErrorDetails(
      exception: StateError('Deliberate test failure'),
      stack: StackTrace.current,
      library: 'phase4-test',
    );

    await $.pumpWidgetAndSettle(
      MaterialApp(
        home: Scaffold(
          body: Builder(builder: (_) => errorWidgetBuilder(details)),
        ),
      ),
    );

    expect($(ErrorBoundaryKeys.root), findsOneWidget);
    expect($(ErrorBoundaryKeys.title), findsOneWidget);
    expect($(ErrorBoundaryKeys.detail), findsOneWidget);
    expect($(ErrorBoundaryKeys.reloadButton), findsOneWidget);

    await $(ErrorBoundaryKeys.reloadButton).tap();
    expect($.tester.takeException(), isNull,
        reason: '다시 시도 클릭이 추가 예외를 발생시키면 안됨');
  });

  // -------------------------------------------------------------------------
  // SCENARIO E — WS Lifecycle (G-4)
  // -------------------------------------------------------------------------
  patrolWidgetTest('E: 화면 전환 시 WS 단일 connect — 중복/leak 없음',
      ($) async {
    await $.pumpWidgetAndSettle(harness.buildTestApp());
    final container = _container($);

    await _login($);
    await $.pumpAndSettle();

    final client = container.read(lobbyWsClientProvider);
    expect(client, isA<LobbyWebSocketClient>());

    await $(const Icon(Icons.people)).tap();
    await $.pumpAndSettle();
    await $(const Icon(Icons.dashboard)).tap();
    await $.pumpAndSettle();

    final clientAfter = container.read(lobbyWsClientProvider);
    expect(identical(client, clientAfter), isTrue,
        reason: 'Provider singleton — 화면 전환마다 재생성되면 leak');

    await container.read(authProvider.notifier).logout();
    await $.pumpAndSettle();

    expect(
      client.status,
      anyOf(WsStatus.disconnected, WsStatus.error),
      reason: '로그아웃 후 wsLifecycle 가 disconnect 호출해야 함',
    );
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<void> _login(PatrolTester $) async {
  await $(const ValueKey('login-email')).enterText(TestCredentials.email);
  await $(const ValueKey('login-password')).enterText(TestCredentials.password);
  await $(const ValueKey('login-submit')).tap();
  await $.pumpAndSettle();
}

ProviderContainer _container(PatrolTester $) {
  final ctx = $.tester.element(find.byType(MaterialApp));
  return ProviderScope.containerOf(ctx);
}
