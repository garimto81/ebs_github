# TEST-07: 앱 QA 전략 및 구현 가이드 (통합 요약)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Lobby, CC, Graphic Editor QA 전략 + 구현 체크리스트 |

---

> **앱별 상세 문서**가 별도 존재한다. 이 문서는 통합 요약이다.
>
> | 앱 | 상세 문서 |
> |---|----------|
> | Lobby | `docs/qa/lobby/QA-LOBBY-01-strategy.md` |
> | Command Center | `docs/qa/commandcenter/QA-CC-01-strategy.md` |
> | Graphic Editor | `docs/qa/graphic-editor/QA-GE-01-strategy.md` |

## 개요

TEST-06 감사 결과를 기반으로 3개 앱의 QA 전략을 정의한다. 각 앱별로 **구체적 테스트 항목**, **우선순위**, **구현 가이드**를 포함한다.

> 게임 엔진 QA는 별도 범위이므로 이 문서에서 제외한다.
> 물리 하드웨어(RFID 안테나, ST25R3911B, ESP32) 테스트는 제외한다 (BS-00 §9).

---

## 전략 원칙

### 1. Invariant-First

게임 엔진 감사에서 **칩 보존 invariant 1줄이 6개 버그를 잡았다**. 앱 테스트에도 동일 원칙을 적용한다:

| 앱 | Invariant | 검증 방법 |
|---|----------|----------|
| **Lobby** | 세션 계층 일관성 | series 선택 시 event/flight/table 반드시 null |
| **CC** | 등록 카드 ≤ 52장 | registeredCards.length 항상 0~52 |
| **CC** | 커뮤니티 카드 ≤ 5장 | communityCards.length 항상 0~5 |
| **Graphic Editor** | Element 수 보존 | add/remove 후 elements.length 정합성 |

### 2. 테스트 피라미드 (TEST-01 준수)

```
          ┌───────────┐
          │   E2E     │  10%  Playwright (GE) / Flutter Integration (Lobby, CC)
          ├───────────┤
          │  Widget / │  20%  상태 변경 + UI 반영 검증
          │Integration│
          ├───────────┤
          │   Unit    │  70%  비즈니스 로직, API, 파서
          └───────────┘
```

### 3. 우선순위 기준

| 우선순위 | 기준 | 예시 |
|:-------:|------|------|
| **P0** | 데이터 무결성 / 상태 전환 오류 | 세션 clearing, phase transition |
| **P1** | 사용자 워크플로우 차단 | 로그인, 테이블 열기, 카드 등록 |
| **P2** | UI 정합성 | 정렬, 필터링, 색상 매핑 |
| **P3** | Edge case | 빈 목록, null 값, 네트워크 타임아웃 |

---

## Lobby QA 전략

### 사전 작업

```bash
cd /c/claude/ebs_lobby_web
flutter pub add --dev mocktail   # mock 프레임워크 추가
```

### Unit 테스트 (P0 — 최우선)

| # | 대상 | 파일 | 테스트 항목 | 우선순위 |
|---|------|------|-----------|:-------:|
| L-U01 | SessionService | `test/services/session_service_test.dart` | `clearBelow('series')` → event/flight/table null | P0 |
| L-U02 | SessionService | 상동 | `clearBelow('event')` → flight/table null, series 유지 | P0 |
| L-U03 | SessionService | 상동 | `saveContext()` → `restore()` 왕복 검증 | P0 |
| L-U04 | JSON Parsers | `test/services/json_parsers_test.dart` | null 필드 처리, 타입 변환, DateTime 파싱 | P1 |
| L-U05 | API Client | `test/services/api_client_test.dart` | 200 성공, 404 미발견, 409 TransitionBlocked, 5xx 에러 | P0 |
| L-U06 | Event Filtering | `test/logic/event_filter_test.dart` | 탭별 필터(All, Created, Running, Completed 등) | P1 |
| L-U07 | Table Sorting | `test/logic/table_sort_test.dart` | Feature 우선, 번호 순 정렬 | P2 |

### Widget 테스트 (P1)

| # | 대상 | 테스트 항목 | 우선순위 |
|---|------|-----------|:-------:|
| L-W01 | LoginScreen | 이메일/비밀번호 입력 → 로그인 버튼 클릭 → provider 호출 | P1 |
| L-W02 | LoginScreen | 로그인 실패 → 에러 메시지 표시 | P1 |
| L-W03 | SessionRestoreDialog | "Continue" 클릭 → 콜백 호출 | P1 |
| L-W04 | EventListScreen | 탭 클릭 → 필터링된 목록 렌더링 | P1 |
| L-W05 | TableManagementScreen | Feature 테이블 상단, 좌석 색상 매핑 | P2 |
| L-W06 | Breadcrumb | 칩 클릭 → 해당 레벨로 네비게이션 | P2 |

### E2E 테스트 (P2)

| # | 시나리오 | 검증 |
|---|---------|------|
| L-E01 | 로그인 → 시리즈 선택 → 이벤트 목록 | 화면 전환, 데이터 로딩 |
| L-E02 | 이벤트 선택 → 테이블 관리 → CC 잠금 상태 | 좌석 렌더링, 상태 표시 |
| L-E03 | 세션 복원 플로우 | 기존 세션 감지 → 복원 다이얼로그 → 이전 위치 복원 |

### 커버리지 목표

| 계층 | Phase 1 목표 | 최종 목표 |
|------|:----------:|:--------:|
| Unit | ≥60% | ≥80% |
| Widget | 핵심 5개 화면 | 전체 화면 |
| E2E | 3 시나리오 | TEST-02 전체 |

---

## Command Center QA 전략

### 사전 작업

```bash
cd /c/claude/ebs_app
flutter pub add --dev mocktail   # mock 프레임워크 추가
```

### Unit 테스트 (P0)

| # | 대상 | 파일 | 테스트 항목 | 우선순위 |
|---|------|------|-----------|:-------:|
| C-U01 | CcApiClient | `test/services/api_client_test.dart` | `getTable()` 성공/404/5xx | P0 |
| C-U02 | CcApiClient | 상동 | `getSeats()` JSON 파싱 | P0 |
| C-U03 | CcApiClient | 상동 | `transitionTable()` 성공/409 conflict | P0 |
| C-U04 | CcApiClient | 상동 | `markDeckRegistered()` 성공/실패 | P0 |
| C-U05 | GameSession model | `test/models/game_session_test.dart` | `deckComplete` (51장=false, 52장=true) | P1 |
| C-U06 | PlayingCard | `test/models/card_test.dart` | `shortLabel` 52종 전부 검증 | P2 |

### Integration 테스트 — loadTable 경로 (P0)

`debugSetState`를 제거하고 **mock API를 통한 실제 경로** 테스트:

| # | 대상 | 테스트 항목 | 우선순위 |
|---|------|-----------|:-------:|
| C-I01 | loadTable 성공 (미등록) | API 성공 → phase=deckRegistration | P0 |
| C-I02 | loadTable 성공 (등록완료) | API 성공 + deckRegistered=true → phase=live | P0 |
| C-I03 | loadTable 실패 (404) | API 404 → errorMessage 설정 | P0 |
| C-I04 | loadTable 실패 (네트워크) | 네트워크 오류 → '서버 연결 실패' | P0 |
| C-I05 | enterLive API 호출 | markDeckRegistered + transitionTable 호출 검증 | P1 |
| C-I06 | enterLive API 실패 | API 예외 → 에러 처리 | P1 |
| C-I07 | RFID 스캔 (loading phase) | loading 상태에서 카드 무시 | P1 |
| C-I08 | RFID 스캔 (커뮤니티 5장 초과) | 6번째 카드 무시 | P1 |

### Widget 테스트 (P1)

| # | 대상 | 테스트 항목 | 우선순위 |
|---|------|-----------|:-------:|
| C-W01 | DeckRegistrationScreen | 진행바 값 = registeredCards.length/52 | P1 |
| C-W02 | DeckRegistrationScreen | 52장 완료 시 "Enter Live" 버튼 활성화 | P1 |
| C-W03 | CommandCenterScreen | street 라벨 변경 (preflop→flop→...) | P1 |
| C-W04 | CommandCenterScreen | 커뮤니티 카드 표시 (0~5장) | P2 |
| C-W05 | DeckGrid | 등록된 카드 = 녹색, 미등록 = 회색 | P2 |

### E2E 테스트 (P2)

| # | 시나리오 | 검증 |
|---|---------|------|
| C-E01 | 앱 시작 → 테이블 로딩 → 덱 등록 | phase 전환, 진행바 |
| C-E02 | 52장 등록 → Enter Live → 핸드 진행 | street 전환, 커뮤니티 카드 |
| C-E03 | 서버 미연결 → 에러 표시 → 재시도 | 에러 복구 |

### 커버리지 목표

| 계층 | Phase 1 목표 | 최종 목표 |
|------|:----------:|:--------:|
| Unit | ≥60% | ≥80% |
| Integration | loadTable 4경로 | 전체 상태 전환 |
| E2E | 3 시나리오 | TEST-02 전체 |

---

## Graphic Editor QA 전략

### 사전 작업

행동 명세(BS)가 없으므로 **역설계 문서** 및 기존 컴포넌트 분석을 기준으로 테스트 항목을 정의한다.

```bash
cd /c/claude/ebs_ui/ebs-skin-editor
npm install   # Playwright 이미 설치됨
```

### Unit 테스트 (P0)

| # | 대상 | 파일 | 테스트 항목 | 우선순위 |
|---|------|------|-----------|:-------:|
| G-U01 | useGfxStore | `tests/stores/useGfxStore.spec.ts` | addElement → elements 증가 | P0 |
| G-U02 | useGfxStore | 상동 | removeElement → elements 감소, 선택 해제 | P0 |
| G-U03 | useGfxStore | 상동 | updateElement → 속성 변경 반영 | P0 |
| G-U04 | useGfxStore | 상동 | selectElement → selectedId 변경 | P1 |
| G-U05 | useGfxStore | 상동 | undo/redo 스택 검증 | P1 |
| G-U06 | 색상 계산 | `tests/utils/color_test.spec.ts` | RGB↔HEX 변환, HUE 회전 | P2 |

### Component 테스트 — Interaction 추가 (P1)

기존 16개 spec은 렌더링만 검증. **사용자 interaction 테스트** 추가:

| # | 컴포넌트 | 테스트 항목 | 우선순위 |
|---|---------|-----------|:-------:|
| G-C01 | EbsColorPicker | 색상 입력 → store 업데이트 | P1 |
| G-C02 | EbsNumberInput | 값 변경 → store 반영 + min/max 클램핑 | P1 |
| G-C03 | EbsSlider | 드래그 → 값 변경 → store 반영 | P1 |
| G-C04 | TransformPanel | X/Y/W/H 변경 → 선택 요소 위치/크기 변경 | P0 |
| G-C05 | TextPanel | 폰트/사이즈 변경 → 선택 텍스트 요소 업데이트 | P1 |
| G-C06 | AdjustColoursPanel | 색상 교체 규칙 추가/삭제 | P1 |
| G-C07 | EbsActionBar | 버튼 클릭 → 해당 액션 실행 (add, delete, duplicate) | P0 |
| G-C08 | GfxEditorDialog | 열기/닫기 + 확인 콜백 | P2 |

### E2E 테스트 — Playwright (P2)

Playwright가 이미 설치되어 있으므로 바로 작성 가능:

| # | 시나리오 | 검증 |
|---|---------|------|
| G-E01 | 앱 로드 → 요소 추가 → 속성 편집 → 저장 | 기본 워크플로우 |
| G-E02 | 텍스트 요소 추가 → 폰트 변경 → 색상 변경 | 텍스트 편집 |
| G-E03 | 다수 요소 → 선택 → 삭제 → Undo | 실행 취소 |

### 커버리지 목표

| 계층 | Phase 1 목표 | 최종 목표 |
|------|:----------:|:--------:|
| Unit (store) | ≥70% | ≥90% |
| Component | interaction 8건 | 전체 컴포넌트 |
| E2E | 3 시나리오 | 전체 워크플로우 |

---

## 구현 순서

### Phase 1: 인프라 + P0 (1~2 세션)

```
1. Lobby: mocktail 설치 → SessionService unit 테스트 (L-U01~03)
2. CC: mocktail 설치 → CcApiClient unit 테스트 (C-U01~04)
3. CC: loadTable integration 테스트 (C-I01~04) — debugSetState 제거
4. GE: useGfxStore interaction 테스트 (G-U01~04)
```

### Phase 2: P1 Widget/Component (1~2 세션)

```
5. Lobby: API Client + JSON 파서 unit (L-U04~05)
6. Lobby: LoginScreen + EventList widget (L-W01~04)
7. CC: DeckRegistration + CommandCenter widget (C-W01~05)
8. GE: Component interaction 테스트 (G-C01~08)
```

### Phase 3: P2 E2E + CI/CD (1~2 세션)

```
9. Lobby: E2E 3 시나리오 (L-E01~03)
10. CC: E2E 3 시나리오 (C-E01~03)
11. GE: Playwright E2E 3 시나리오 (G-E01~03)
12. GitHub Actions CI/CD 파이프라인
```

---

## CI/CD 파이프라인 (목표)

```
push / PR
  ├─ [Job 1] Lobby (Flutter Web)
  │    ├─ flutter test --coverage
  │    └─ coverage check (≥60%)
  ├─ [Job 2] CC (Flutter Desktop)
  │    ├─ flutter test --coverage
  │    └─ coverage check (≥60%)
  ├─ [Job 3] Graphic Editor (Vue3)
  │    ├─ npm run test -- --coverage
  │    └─ coverage check (≥70%)
  └─ [Job 4] E2E (PR merge → main only)
       ├─ Playwright (GE)
       └─ Flutter integration (Lobby, CC)
```

---

## 검증 기준 (Definition of Done)

| 항목 | 기준 |
|------|------|
| P0 테스트 전부 PASS | `flutter test` / `npm run test` 녹색 |
| 칩/상태 invariant 포함 | 각 앱의 invariant가 자동 검증에 포함 |
| mock으로 에러 경로 테스트 | API 404/409/5xx 시나리오 포함 |
| debugSetState 제거 (CC) | 실제 코드 경로로 테스트 |
| CI/CD 파이프라인 녹색 | GitHub Actions에서 자동 실행 |
