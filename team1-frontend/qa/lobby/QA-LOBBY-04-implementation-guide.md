# QA-LOBBY-04: Lobby 구현 Gap 해소 지시서 (화면 0-4)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | BS-02 기반 Gap 분석 → 구현 지시서 |
| 2026-04-10 | critic revision | DEPRECATED 배너 추가 (Flutter Dart 기반, Quasar 전환으로 폐기) |

> **⚠️ DEPRECATED — 참조용 아카이브**
> 본 문서는 **Flutter Dart 기반** 으로 작성되었습니다 (`ebs_lobby_web/`, Flutter 프로젝트).
> Team 1 의 기술 스택이 **Quasar Framework (Vue 3) + TypeScript** 로 확정(2026-04-10) 됨에 따라,
> 본 문서의 구현 스니펫은 **역사적 참조용** 으로만 사용합니다. Dart → TypeScript, Flutter 위젯 → Vue 컴포넌트로 직접 치환되지 않으므로 신규 작업에 그대로 사용하면 안 됩니다.
> BS-02 Gap 분석 자체(기능 수준의 누락 항목 목록)는 여전히 유효합니다 — 이 부분만 참고하세요.
> 신규 작업은 `QA-LOBBY-06+` 시리즈(Quasar 전환 후 신규 작성 예정)를 따릅니다.

---

## 개요

BS-02 행동 명세와 실제 구현을 대조한 결과, Login ~ Tables (화면 0-4) 범위에서 발견된 Gap을 해소하기 위한 구현 지시서.

> 레포: `/ebs_lobby_web/`
> 행동 명세: `contracts/specs/BS-02-lobby/BS-02-lobby.md`
> 체크리스트: `docs/qa/lobby/QA-LOBBY-02-checklist.md`

---

## 다른 세션 시작 시 컨텍스트 로딩

```
다음 문서를 순서대로 읽고 구현 작업을 진행해:
1. docs/qa/lobby/QA-LOBBY-04-implementation-guide.md  ← 이 문서 (구현 지시서)
2. docs/qa/lobby/QA-LOBBY-02-checklist.md              ← BS-02 체크리스트
3. contracts/specs/BS-02-lobby/BS-02-lobby.md       ← 행동 명세 원본
레포: /ebs_lobby_web/
```

---

## 구현 우선순위 요약

| 우선순위 | 항목 | 예상 규모 |
|:--------:|------|:--------:|
| CRITICAL | Session localStorage 영속화 | ~30줄 |
| CRITICAL | Auth Token 영속화 | ~30줄 |
| CRITICAL | WebSocket 이벤트 파싱 + UI 연결 | ~80줄 |
| HIGH | Login 에러 메시지 분기 | ~20줄 |
| HIGH | RBAC 가드 메서드 + 화면 적용 | ~60줄 |
| HIGH | Tables 상태/타입 필터 | ~50줄 |
| HIGH | Flight CRUD (신규 다이얼로그) | ~150줄 |
| HIGH | Blind Structure 저장 누락 수정 | ~15줄 |
| HIGH | CC 진입 비밀번호 다이얼로그 | ~60줄 |
| MEDIUM | Forgot Password 링크 | ~30줄 |
| MEDIUM | Series 필터 (Outdated/Bookmarks) | ~40줄 |
| MEDIUM | Mix Preset → allowedGames 매핑 | ~15줄 |
| MEDIUM | Tables Operator/Hand# 표시 | ~20줄 |
| MEDIUM | Degradation Banner 다중 유형 | ~30줄 |

---

## 화면 0 — Login

### GAP-L01: 로그인 실패 에러 메시지 (HIGH)

**파일**: `lib/screens/login_screen.dart`
**현재**: line 81-85 — generic catch-all, 에러 메시지 `'로그인 실패: $e'`
**문제**: 백엔드 미연결 시 아무 반응 없거나 기술적 에러만 표시
**BS 요구**: LB-00-04, LB-13-01~10

**구현**:
```dart
// line 81-85 수정
} on SocketException {
  setState(() => _error = '서버에 연결할 수 없습니다. 네트워크를 확인하세요.');
} on TimeoutException {
  setState(() => _error = '서버 응답 시간 초과. 잠시 후 다시 시도하세요.');
} on HttpException catch (e) {
  if (e.message.contains('401')) {
    setState(() => _error = '이메일 또는 비밀번호가 올바르지 않습니다.');
  } else {
    setState(() => _error = '로그인 실패: ${e.message}');
  }
} catch (e) {
  setState(() => _error = '알 수 없는 오류: $e');
}
```

**Playwright 검증**: `00-login.png` → 에러 메시지 영역 확인

---

### GAP-L02: Forgot Password 링크 (MEDIUM)

**파일**: `lib/screens/login_screen.dart`
**현재**: line 134 — 비밀번호 필드 아래에 링크 없음
**BS 요구**: LB-00-02 (BS 목업에 "Forgot your Password?" 링크 존재)

**구현**: line 134 뒤에 추가
```dart
Align(
  alignment: Alignment.centerRight,
  child: TextButton(
    onPressed: () => _showForgotPasswordDialog(),
    child: const Text('Forgot your Password?'),
  ),
),
```

---

## 화면 1 — Series

### GAP-L03: RBAC 가드 메서드 (HIGH)

**파일**: `lib/providers/auth_provider.dart`
**현재**: line 23-32 — Role 저장만, 검증 없음
**BS 요구**: LB-19-01~06

**구현**: AuthState에 가드 메서드 추가
```dart
bool get isAdmin => role == Role.admin;
bool get canCreate => role == Role.admin;
bool get canEdit => role == Role.admin;
bool get canDelete => role == Role.admin;
bool get canEnterCC => role != Role.viewer;
```

**화면 적용**: 각 화면의 FAB, 편집/삭제 버튼을 `auth.canCreate` 조건으로 감싸기
```dart
// series_lobby_screen.dart — FAB 조건부 표시
if (auth.isAdmin) FloatingActionButton.extended(...)
```

동일 패턴을 `event_list_screen.dart`, `table_management_screen.dart`에도 적용

---

### GAP-L04: Series 필터 (Outdated/Bookmarks) (MEDIUM)

**파일**: `lib/screens/series_lobby_screen.dart`
**현재**: line 117-130 — 검색만 존재
**BS 요구**: LB-01-06

**구현**: 검색 바 위에 FilterChip 행 추가
```dart
Row(children: [
  FilterChip(label: Text('Hide Outdated'), selected: _hideOutdated, onSelected: ...),
  SizedBox(width: 8),
  FilterChip(label: Text('Bookmarks Only'), selected: _bookmarksOnly, onSelected: ...),
])
```

`_groupByMonth()` 필터링에 조건 추가:
```dart
if (_hideOutdated) filtered = filtered.where((s) => s.endDate.isAfter(DateTime.now()));
```

---

## 화면 2 — Events

### GAP-L05: Blind Structure 저장 누락 (HIGH)

**파일**: `lib/dialogs/event_form_dialog.dart`
**현재**: line 245-309 — `_blindLevels` 수집하지만 line 79-96의 `data` map에 포함하지 않음
**문제**: Event 생성 시 Blind Structure가 저장되지 않음

**구현**: line 95 부근에 추가
```dart
data['blindStructure'] = _blindLevels.map((l) => {
  'level': l.level,
  'smallBlind': l.sb,
  'bigBlind': l.bb,
  'ante': l.ante,
  'duration': l.duration,
}).toList();
```

---

### GAP-L06: Mix Preset → allowedGames 매핑 (MEDIUM)

**파일**: `lib/dialogs/event_form_dialog.dart`
**현재**: line 95 — `allowedGames` 빈 배열
**BS 요구**: LB-02-23~35

**구현**: 프리셋 선택 시 자동 매핑
```dart
if (_gameMode == GameMode.fixedRotation && _mixPreset != null) {
  data['allowedGames'] = _mixPreset!.games;
  data['rotationOrder'] = _mixPreset!.order;
  data['rotationTrigger'] = 'hands';
  data['handsPerRotation'] = _handsPerRotation;
}
```

---

## 화면 3 — Flights

### GAP-L07: Flight CRUD (HIGH)

**신규 파일**: `lib/dialogs/flight_form_dialog.dart`
**현재**: 파일 없음. `flight_list_screen.dart`는 읽기 전용
**BS 요구**: LB-02-17, LB-03-04

**구현**: `event_form_dialog.dart` 구조를 참고하여 신규 생성

필드:
- Flight Name (required, 1~50 chars, Event 내 unique)
- Date (required, Event 기간 내)
- Starting Stack (default 60000, 1~10,000,000)
- Starting Blind Level (default 1, 1~50)

`flight_list_screen.dart`에 추가:
```dart
// FAB 추가
floatingActionButton: FloatingActionButton.extended(
  onPressed: () => _showCreateFlightDialog(),
  icon: const Icon(Icons.add),
  label: const Text('New Flight'),
),
```

API: `api.createFlight(eventId, data)` 호출 (ApiClient에 메서드 추가 필요)

---

## 화면 4 — Tables

### GAP-L08: 상태/타입 필터 (HIGH)

**파일**: `lib/screens/table_management_screen.dart`
**현재**: line 196 아래 — 필터 UI 없음
**BS 요구**: LB-04-06~08

**구현**: Breadcrumb 아래에 필터 행 추가
```dart
// 상태 변수 추가
TableStatus? _statusFilter;
TableType? _typeFilter;

// 필터 UI
Row(children: [
  SegmentedButton<TableStatus?>(
    segments: [
      ButtonSegment(value: null, label: Text('All')),
      ButtonSegment(value: TableStatus.empty, label: Text('Empty')),
      ButtonSegment(value: TableStatus.setup, label: Text('Setup')),
      ButtonSegment(value: TableStatus.live, label: Text('Live')),
      ButtonSegment(value: TableStatus.completed, label: Text('Completed')),
    ],
    selected: {_statusFilter},
    onSelectionChanged: (v) => setState(() => _statusFilter = v.first),
  ),
  SizedBox(width: 16),
  SegmentedButton<TableType?>(
    segments: [
      ButtonSegment(value: null, label: Text('All')),
      ButtonSegment(value: TableType.feature, label: Text('Feature')),
      ButtonSegment(value: TableType.general, label: Text('General')),
    ],
    selected: {_typeFilter},
    onSelectionChanged: (v) => setState(() => _typeFilter = v.first),
  ),
])
```

`_sortedTables` getter에 필터 적용:
```dart
var filtered = List<PokerTable>.from(_tables!);
if (_statusFilter != null) filtered = filtered.where((t) => t.status == _statusFilter).toList();
if (_typeFilter != null) filtered = filtered.where((t) => t.type == _typeFilter).toList();
```

---

### GAP-L09: CC 진입 비밀번호 (HIGH)

**신규 파일**: `lib/dialogs/password_dialog.dart`
**현재**: line 453-468 — 비밀번호 없이 바로 커맨드 복사
**BS 요구**: LB-07-01~04

**구현**: 비밀번호 다이얼로그 → 확인 후 CC 커맨드 표시
```dart
// password_dialog.dart
class PasswordDialog extends StatefulWidget { ... }
// TextField + "Confirm" 버튼
// 성공 → Navigator.pop(context, true)
// 실패 → "비밀번호가 올바르지 않습니다" 에러

// table_management_screen.dart line 453 수정
onPressed: () async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => PasswordDialog(tableId: t.tableId),
  );
  if (ok == true) _showCcCommand(t);
},
```

---

### GAP-L10: LIVE 테이블 Operator/Hand# 표시 (MEDIUM)

**파일**: `lib/screens/table_management_screen.dart`
**현재**: 테이블 카드에 Operator/Hand# 미표시
**BS 요구**: LB-06-17

**구현**: 테이블 카드 subtitle에 조건부 추가
```dart
if (t.status == 'live') ...[
  Text('Operator: ${t.operatorName ?? "—"}'),
  Text('Hand #${t.handCount ?? 0}'),
]
```

> PokerTable 모델에 `operatorName`, `handCount` 필드 추가 필요

---

## 서비스 계층

### GAP-L11: Session localStorage 영속화 (CRITICAL)

**파일**: `lib/services/session_service.dart`
**현재**: line 27-101 — 인메모리만. 브라우저 새로고침 시 손실
**BS 요구**: LB-08-01~06

**구현**: `saveContext()` 호출마다 localStorage 저장
```dart
import 'dart:html' show window;
import 'dart:convert';

void saveContext(...) {
  // 기존 인메모리 저장 유지
  _seriesId = seriesId; ...

  // localStorage 추가
  window.localStorage['ebs_session'] = jsonEncode({
    'seriesId': _seriesId, 'seriesName': _seriesName,
    'eventId': _eventId, 'eventName': _eventName,
    'flightId': _flightId, 'flightName': _flightName,
    'tableId': _tableId, 'tableName': _tableName,
  });
}

SessionContext? restore() {
  // localStorage에서 복원 시도
  final stored = window.localStorage['ebs_session'];
  if (stored != null) {
    final m = jsonDecode(stored) as Map<String, dynamic>;
    _seriesId = m['seriesId']; ...
  }
  // 기존 인메모리 반환 로직
}
```

---

### GAP-L12: Auth Token 영속화 (CRITICAL)

**파일**: `lib/providers/auth_provider.dart`
**현재**: line 23-32 — 토큰 인메모리만. 새로고침 시 재로그인 필요
**BS 요구**: LB-08-05

**구현**:
```dart
// 로그인 성공 시
state = AuthState(token: token, role: role);
window.localStorage['ebs_token'] = token;

// 앱 초기화 시 (main.dart 또는 별도 init)
final savedToken = window.localStorage['ebs_token'];
if (savedToken != null) { /* validate token → restore auth state */ }

// 로그아웃 시
window.localStorage.remove('ebs_token');
window.localStorage.remove('ebs_session');
```

---

### GAP-L13: WebSocket 이벤트 파싱 + UI 연결 (CRITICAL)

**파일**: `lib/services/ws_client.dart`, `lib/providers/api_provider.dart`
**현재**: WsClient 존재하나 이벤트 파싱 없음. `wsConnectionProvider`가 항상 `true`
**BS 요구**: LB-06-09~15

**구현**:

ws_client.dart — 이벤트 파싱 추가:
```dart
void _onMessage(dynamic data) {
  final msg = jsonDecode(data as String) as Map<String, dynamic>;
  final type = msg['type'] as String;
  switch (type) {
    case 'table.status.changed':
      _eventController.add(TableStatusEvent.fromJson(msg));
    case 'table.seat.updated':
      _eventController.add(SeatUpdateEvent.fromJson(msg));
    case 'hand.completed':
      _eventController.add(HandCompletedEvent.fromJson(msg));
  }
}
```

api_provider.dart — connection 상태 연결:
```dart
// wsConnectionProvider가 WsClient 실제 상태를 반영하도록 수정
final wsConnectionProvider = StateProvider<bool>((ref) {
  final ws = ref.watch(wsClientProvider);
  return ws.isConnected;  // WsClient에 isConnected getter 추가
});
```

table_management_screen.dart — 실시간 업데이트:
```dart
@override
void initState() {
  super.initState();
  _wsSubscription = wsClient.events.listen((event) {
    if (event is TableStatusEvent) _loadTables();  // 테이블 재로딩
  });
}
```

---

### GAP-L14: Degradation Banner 다중 유형 (MEDIUM)

**파일**: `lib/widgets/degradation_banner.dart`
**현재**: "Server unavailable" 하나만
**BS 요구**: LB-13-01~16

**구현**: 배너 유형 분기
```dart
enum DegradationType { dbDisconnected, apiDisconnected, wsDisconnected, networkDown }

// 유형별 메시지/색상
switch (type) {
  case DegradationType.dbDisconnected:
    return ('데이터베이스 연결 끊김. 자동 재연결 시도 중...', Colors.red);
  case DegradationType.apiDisconnected:
    return ('API 연결 끊김. 로컬 캐시로 동작 중', Colors.orange);
  case DegradationType.wsDisconnected:
    return ('실시간 업데이트 중단. 수동 새로고침 필요', Colors.yellow);
  case DegradationType.networkDown:
    return ('네트워크 끊김', Colors.red);
}
```

---

## 구현 순서 (권장)

```
Phase 1: 기반 (CRITICAL) — 먼저 완료
  GAP-L11  Session localStorage
  GAP-L12  Auth Token 영속화
  GAP-L01  Login 에러 메시지
  GAP-L03  RBAC 가드 메서드

Phase 2: 핵심 기능 (HIGH)
  GAP-L05  Blind Structure 저장
  GAP-L07  Flight CRUD 다이얼로그
  GAP-L08  Tables 상태/타입 필터
  GAP-L09  CC 비밀번호 다이얼로그

Phase 3: 통합 (CRITICAL + HIGH)
  GAP-L13  WebSocket 이벤트 파싱 + UI 연결

Phase 4: 개선 (MEDIUM)
  GAP-L02  Forgot Password
  GAP-L04  Series 필터
  GAP-L06  Mix Preset 매핑
  GAP-L10  Operator/Hand# 표시
  GAP-L14  Degradation Banner
```

---

## 검증 방법

각 Gap 해소 후:
1. `flutter test` — 기존 테스트 깨짐 없음 확인
2. `flutter build web` — 빌드 성공 확인
3. Playwright 캡처 — `docs/qa/lobby/screenshots/` 에 저장
4. `QA-LOBBY-02-checklist.md` 해당 항목 구현 열 ✅ 업데이트

---

## 신규 파일 목록

| 파일 | 용도 |
|------|------|
| `lib/dialogs/flight_form_dialog.dart` | Flight CRUD 다이얼로그 (GAP-L07) |
| `lib/dialogs/password_dialog.dart` | CC 진입 비밀번호 (GAP-L09) |

---

## 참조

- 체크리스트: `docs/qa/lobby/QA-LOBBY-02-checklist.md`
- 행동 명세: `contracts/specs/BS-02-lobby/BS-02-lobby.md`
- Playwright 캡처: `docs/qa/lobby/screenshots/`
- BS 목업: `contracts/specs/BS-02-lobby/visual/screenshots/`
