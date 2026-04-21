// S-11 Lobby Hand History — flutter_driver skeleton (UI layer).
//
// 실행 컨텍스트:
//   - 이 파일은 team1 Lobby Flutter Desktop 앱 위에서 실행됨
//   - 위치(권장): team1-frontend/integration_test/s11_lobby_test.dart (team1 ownership)
//   - 현재 위치(docs/.../automation/s11/flutter_driver/)는 **template** — team1 이 PR 로 복제/확장
//
// 실행 방법 (team1-frontend/ 에서):
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/s11_lobby_test.dart \
//     --dart-define=BACKEND_HTTP_URL=http://localhost:8000 \
//     --dart-define=S11_ADMIN_USER=admin_s11 \
//     --dart-define=S11_ADMIN_PW=admin_s11_pw
//
// API/WS 계약 검증은 동급 `../playwright/` 가 담당. 이 파일은 **UI 동작**만 검증:
//   - 사이드바 [Hand History] 네비게이션
//   - 필터 입력 (event/table/date)
//   - Hand Row 클릭 → Detail 화면 전이
//   - WS 수신 후 Browser 첫 행 DOM 갱신 (50ms × 5회 polling)
//   - RBAC 별 UI 차이 (Admin vs Operator vs Viewer)
//
// decision_owner: team1 (Lobby UI). team4 가 E2E 명세(Integration_Test_Plan §S-11) 를 제공.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const String kAdminUser =
    String.fromEnvironment('S11_ADMIN_USER', defaultValue: 'admin_s11');
const String kAdminPw =
    String.fromEnvironment('S11_ADMIN_PW', defaultValue: 'admin_s11_pw');
const String kOperatorUser =
    String.fromEnvironment('S11_OPERATOR_USER', defaultValue: 'operator_t1');
const String kOperatorPw =
    String.fromEnvironment('S11_OPERATOR_PW', defaultValue: 'operator_t1_pw');
const String kViewerUser =
    String.fromEnvironment('S11_VIEWER_USER', defaultValue: 'viewer_s11');
const String kViewerPw =
    String.fromEnvironment('S11_VIEWER_PW', defaultValue: 'viewer_s11_pw');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('S-11 Lobby Hand History — UI driver', () {
    testWidgets('step 1: Admin navigates to Hand History via sidebar',
        (tester) async {
      // TODO(team1): import Lobby main() and pumpWidget
      // await tester.pumpWidget(const LobbyApp());
      // await _loginAs(tester, kAdminUser, kAdminPw);
      // await tester.tap(find.byKey(const Key('sidebar.handHistory')));
      // await tester.pumpAndSettle();
      // expect(find.byKey(const Key('handBrowser.root')), findsOneWidget);
      markTestSkipped('team1 Lobby app bootstrap pending (ownership: team1)');
    });

    testWidgets('step 2: Admin applies filter event=1 table=1 today',
        (tester) async {
      // TODO(team1):
      // await tester.enterText(find.byKey(const Key('filter.eventId')), '1');
      // await tester.enterText(find.byKey(const Key('filter.tableId')), '1');
      // await tester.tap(find.byKey(const Key('filter.apply')));
      // await tester.pumpAndSettle();
      // expect(find.byKey(const Key('handBrowser.row')), findsWidgets);
      markTestSkipped('team1 widget keys pending');
    });

    testWidgets('step 3: Admin opens hand detail, all hole cards visible',
        (tester) async {
      // TODO(team1):
      // await tester.tap(find.byKey(const Key('handBrowser.row.101')));
      // await tester.pumpAndSettle();
      // expect(find.byKey(const Key('handDetail.timeline')), findsOneWidget);
      // expect(find.byKey(const Key('handDetail.seatGrid')), findsOneWidget);
      // // hole_card cell should NOT contain '★'
      // expect(find.textContaining('★'), findsNothing);
      markTestSkipped('team1 widget keys pending');
    });

    testWidgets('step 4: HandStarted WS event prepends first browser row',
        (tester) async {
      // TODO(team1): inject a test WebSocket mock or hit real BO and poll 50ms x 5
      // final firstRowBefore = find.byKey(const Key('handBrowser.row.first'));
      // final beforeId = _extractHandId(tester, firstRowBefore);
      // await _triggerHandStartedViaApi(); // helper hits CC mock endpoint
      // for (var i = 0; i < 5; i++) {
      //   await tester.pump(const Duration(milliseconds: 50));
      // }
      // final afterId = _extractHandId(tester, firstRowBefore);
      // expect(afterId, isNot(beforeId));
      markTestSkipped('WS mock path pending (team1/team2 coordination)');
    });

    testWidgets('step 8: Viewer sees ★ masked hole cards', (tester) async {
      // TODO(team1):
      // await _logout(tester);
      // await _loginAs(tester, kViewerUser, kViewerPw);
      // await _openHandDetail(tester, handId: 101);
      // expect(find.text('★'), findsWidgets);
      markTestSkipped('team1 widget keys pending');
    });

    testWidgets('step 10: yesterday filter shows 당일 한정 banner', (tester) async {
      // TODO(team1):
      // await _setFilterDate(tester, DateTime.now().subtract(const Duration(days: 1)));
      // await tester.pumpAndSettle();
      // expect(find.textContaining('당일 한정'), findsOneWidget);
      markTestSkipped('team1 banner widget key pending');
    });
  });
}

// ---------------------------------------------------------------------------
// Helper stubs — team1 이 실제 구현 시 채울 것
// ---------------------------------------------------------------------------

Future<void> _loginAs(WidgetTester tester, String user, String pw) async {
  // TODO(team1)
  throw UnimplementedError('login helper not wired');
}

Future<void> _logout(WidgetTester tester) async {
  throw UnimplementedError('logout helper not wired');
}

Future<void> _openHandDetail(WidgetTester tester, {required int handId}) async {
  throw UnimplementedError('openHandDetail helper not wired');
}

Future<void> _setFilterDate(WidgetTester tester, DateTime d) async {
  throw UnimplementedError('setFilterDate helper not wired');
}
