# EBS Lobby 12개 항목 구현 + E2E 검증

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | BO 기획 전 진행 가능한 12개 항목 일괄 구현 |

## 배경

기존 4개 레포(ebs_shared 34t, ebs_server 39t, ebs_lobby_web 3t, ebs_app 10t)가 green 상태.
BO 기획서 미확정이므로 in-memory store 유지. Mock 데이터(1 Series + 3 Events + 6 Flights + 12 Tables + 50 Players)로 E2E 동작 검증.

## 구현 범위

| # | 항목 | 레포 | 핵심 변경 |
|:-:|---|---|---|
| 1 | Enter CC → 실제 실행 | ebs_lobby_web | table_management: [Enter CC] → `window.open()` (web) 또는 SnackBar + 클립보드 커맨드 |
| 2 | WebSocket 실시간 모니터링 | ebs_server + ebs_lobby_web | server: state 변경 시 broadcast. lobby: ws_client 연결 → 테이블 카드 실시간 갱신 |
| 3 | CC Lock 매트릭스 UI | ebs_lobby_web | table detail panel: CC active일 때 LOCK/CONFIRM/FREE 필드별 잠금 표시 |
| 4 | 세션 복원 다이얼로그 | ebs_lobby_web | 로그인 후 lastSeriesId/eventId/flightId/tableId → "Continue/Change" 다이얼로그 |
| 5 | 좌석 배치 UI | ebs_lobby_web | seat_assignment_dialog: 타원 테이블 + 드래그 + [Random Seat] |
| 6 | 플레이어 등록/삭제 | ebs_lobby_web | player_add_dialog: 검색 → 선택 → Add. 삭제 확인 다이얼로그 |
| 7 | 상태 전환 전체 흐름 | ebs_server + ebs_lobby_web | 모든 transition 버튼 + blockedReason UI 표시 |
| 8 | Mix 게임 모드 | ebs_server + ebs_lobby_web | Event에 gameMode 표시 + CC에 게임 전환 정보 전달 |
| 9 | 장애 복구 배너 실동작 | ebs_lobby_web | WS disconnect → 배너 자동 표시 + 재연결 성공 시 숨김 |
| 10 | RFID 상태 시뮬레이션 | ebs_server | `PATCH /api/tables/:id` rfidStatus mock 변경 + WS broadcast |
| 11 | 테스트 보강 | 전체 | Lobby 5화면 위젯 + server handler + E2E 통합 |
| 12 | UI 폴리시 | ebs_lobby_web | Feature Table 금색 강조, 좌석 그리드 색상, 상태 뱃지 |

## 영향 파일

- `C:\claude\ebs_server\lib\handlers\*.dart` — WS broadcast 추가, RFID status 시뮬
- `C:\claude\ebs_lobby_web\lib\screens\*.dart` — 5화면 전체 보강
- `C:\claude\ebs_lobby_web\lib\dialogs\*.dart` — seat_assignment, player_add 보강
- `C:\claude\ebs_lobby_web\lib\widgets\*.dart` — degradation_banner, breadcrumb 실연결
- `C:\claude\ebs_lobby_web\lib\services\ws_client.dart` — 실시간 이벤트 수신 + UI 갱신
- `C:\claude\ebs_lobby_web\test\*.dart` — 위젯 테스트 보강
- `C:\claude\ebs_server\test\e2e_test.dart` — E2E 시나리오 확장

## 위험 요소

| 위험 | 완화 |
|---|---|
| Windows sandbox에서 소켓 바인딩 불가 | shelf handler 직접 호출 E2E (이미 검증됨) |
| WebSocket 테스트가 실서버 필요 | mock WS 또는 handler 단위 테스트 |
| 12개 항목 간 의존성 | Server(2,7,8,10) → Lobby(1,3-6,9,12) → Test(11) 순서 |

## 검증

- `dart test` (ebs_server) — 기존 39 + 신규 E2E 15+ = 54+ tests
- `flutter test` (ebs_lobby_web) — 기존 3 + 신규 10+ = 13+ tests
- `flutter test` (ebs_app) — 기존 10 유지
- `dart analyze` + `flutter analyze` — 0 issues
