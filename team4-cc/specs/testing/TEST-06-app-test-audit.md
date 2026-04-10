# TEST-06: 앱 테스트 품질 감사 결과 (통합 요약)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Lobby, CC, Graphic Editor 테스트 품질 감사 |

---

> **앱별 상세 문서**가 별도 존재한다. 이 문서는 통합 요약이다.
>
> | 앱 | 상세 문서 |
> |---|----------|
> | Lobby | `docs/qa/lobby/QA-LOBBY-00-audit.md` |
> | Command Center | `docs/qa/commandcenter/QA-CC-00-audit.md` |
> | Graphic Editor | `docs/qa/graphic-editor/QA-GE-00-audit.md` |

## 개요

3개 앱(Lobby, Command Center, Graphic Editor)의 기존 테스트를 감사하여 **실제 검증 수준**을 평가한다. "PASS" 여부가 아니라 "무엇을 검증하는가"를 기준으로 분석한다.

> 게임 엔진 QA는 별도 범위이므로 이 문서에서 제외한다.

---

## 감사 요약

| 앱 | 프레임워크 | 레포 | 테스트 수 | 품질 점수 | 핵심 문제 |
|---|-----------|------|:--------:|:--------:|----------|
| **Lobby** | Flutter Web | `/ebs_lobby_web/` | 7 widget | **2/10** | unit 0건, 로직 검증 0건 |
| **Command Center** | Flutter Desktop | `/ebs_app/` | 10 unit/widget | **3/10** | debugSetState로 실제 경로 우회 |
| **Graphic Editor** | Vue3+Quasar | `/ebs_ui/ebs-skin-editor/` | 16 spec | **3/10** | mount+text만, interaction 0건 |

### 공통 안티패턴

| 안티패턴 | 설명 | 해당 앱 |
|---------|------|---------|
| **렌더 테스트 함정** | 컴포넌트 마운트 + 텍스트 존재 확인만 | 3개 전부 |
| **로직 미검증** | 비즈니스 로직(필터링, 상태전환, 계산)이 assert 대상이 아님 | 3개 전부 |
| **E2E 0건** | 사용자 워크플로우 재현 테스트 없음 | 3개 전부 |
| **에러 경로 미테스트** | API 실패, 네트워크 오류, 유효성 검증 실패 등 | 3개 전부 |
| **CI/CD 없음** | PR/push 시 자동 테스트 미실행 | 3개 전부 |

---

## 1. Lobby (`/ebs_lobby_web/`)

### 테스트 파일 목록

| 파일 | 테스트 수 | 검증 내용 |
|------|:--------:|----------|
| `breadcrumb_test.dart` | 2 | 텍스트 렌더링만. 네비게이션 클릭 미테스트 |
| `cc_lock_test.dart` | 1 | 아이콘 존재만 (`findsWidgets`). 상태별 분기 미테스트 |
| `event_list_test.dart` | 1 | 탭 이름 렌더링만. 필터링 로직 미테스트 |
| `series_screen_test.dart` | 1 | 시리즈 카드 텍스트만. 검색/월별 그룹핑 미테스트 |
| `session_restore_test.dart` | 2 | 다이얼로그 텍스트만. 버튼 클릭 콜백 미테스트 |
| `table_management_test.dart` | 1 | 아이콘 1개 확인만. 정렬/좌석/상태 전환 미테스트 |
| `widget_test.dart` | 1 | 로그인 폼 필드 존재만. 로그인 플로우 미테스트 |

### CRITICAL 미테스트 영역

| 영역 | 소스 위치 | 위험도 |
|------|----------|:------:|
| **세션 계층 clearing** | `session_service.dart` `clearBelow()` | CRITICAL |
| **이벤트 상태 필터링** | `event_list_screen.dart` `_filtered()` | CRITICAL |
| **테이블 정렬** (Feature 우선) | `table_management_screen.dart` `_sortedTables` | HIGH |
| **로그인 → 세션 복원 플로우** | `login_screen.dart` lines 44-76 | CRITICAL |
| **API 에러 핸들링** (409 TransitionBlocked) | `api_client.dart` | CRITICAL |
| **JSON 파서** (null 처리, 타입 변환) | `json_parsers.dart` | HIGH |
| **좌석 렌더링** (색상 매핑) | `table_management_screen.dart` | MEDIUM |

### Mock 인프라 문제

- `mock_api_client.dart` — 에러 시뮬레이션 불가, `assignSeat()` 빈 구현
- mockito/mocktail 미설치 — 고급 mock 패턴 사용 불가
- 비동기 에러 테스트 불가능

---

## 2. Command Center (`/ebs_app/`)

### 테스트 파일 목록

| 파일 | 테스트 수 | 검증 내용 |
|------|:--------:|----------|
| `fake_rfid_reader_test.dart` | 3 | stream inject, deck 52장, playScenario. **품질 양호** |
| `game_session_test.dart` | 5 | 초기 상태(tautological), copyWith(tautological), RFID 중복제거, enterLive, advanceStreet |
| `widget_test.dart` | 2 | 로딩 텍스트, 서버 미연결 에러. **실제 서버 상태에 의존** |

### 안티패턴 상세

**debugSetState 남용** — `game_session_test.dart`
```
ctrl.debugSetState(const GameSession(
  phase: SessionPhase.deckRegistration,
  tableId: 'table-001',
));
```
- loadTable() API 호출 → 상태 전환 경로를 **완전히 우회**
- API가 깨져도 테스트 PASS

**실제 네트워크 의존** — `widget_test.dart`
```
// localhost:8080이 꺼져있어야 테스트 PASS
expect(find.textContaining('서버 연결 실패'), findsOneWidget);
```
- 서버가 실행 중이면 테스트 FAIL

**Tautological 테스트** — `game_session_test.dart`
```
// GameSession 기본 생성자가 loading을 반환하는지 확인
// → 코드를 테스트하는 게 아니라 언어를 테스트하는 것
expect(session.phase, SessionPhase.loading);
```

### CRITICAL 미테스트 영역

| 영역 | 소스 위치 | 위험도 |
|------|----------|:------:|
| **CcApiClient 전체** | `services/api_client.dart` (7개 메서드) | CRITICAL |
| **loadTable() 상태 전환** | `game_session_provider.dart` lines 40-71 | CRITICAL |
| **enterLive() API 호출** | `game_session_provider.dart` lines 85-105 | HIGH |
| **DeckRegistrationScreen** | `screens/deck_registration_screen.dart` | HIGH |
| **CommandCenterScreen** | `screens/command_center_screen.dart` | HIGH |
| **OverlayScreen** | `screens/overlay_screen.dart` | MEDIUM |
| **PlayingCard.shortLabel** | `models/card.dart` 52종 매핑 | MEDIUM |

### 의존성 문제

- `pubspec.yaml`에 **mockito/mocktail 없음** — CcApiClient mock 불가
- 테스트 인프라 추가 필수: `mocktail` + `http_mock_adapter` 또는 유사

---

## 3. Graphic Editor (`/ebs_ui/ebs-skin-editor/`)

### 테스트 파일 목록

| 파일 | 테스트 수 | 검증 내용 |
|------|:--------:|----------|
| `AdjustColoursPanel.spec.ts` | 6 | 섹션 렌더링, RGB 라벨, 버튼 존재 |
| `AnimationPanel.spec.ts` | 4 | Duration 라벨, 타입 셀렉터 존재 |
| `EbsActionBar.spec.ts` | 5 | 버튼 아이콘 존재, 라벨 텍스트 |
| `EbsColorPicker.spec.ts` | 3 | 입력 필드 존재, 라벨 |
| `EbsGfxCanvas.spec.ts` | 3 | 캔버스 렌더링, 그리드 토글 |
| `EbsNumberInput.spec.ts` | 4 | 라벨, min/max 표시 |
| `EbsPropertyRow.spec.ts` | 2 | 라벨 + slot 렌더링 |
| `EbsSectionHeader.spec.ts` | 3 | 제목, 아이콘, collapse 버튼 |
| `EbsSelect.spec.ts` | 3 | 옵션 렌더링 |
| `EbsSlider.spec.ts` | 3 | 라벨, 값 표시 |
| `EbsToggle.spec.ts` | 3 | 라벨, 상태 표시 |
| `GfxEditorBase.spec.ts` | 4 | 패널 섹션 존재 |
| `GfxEditorDialog.spec.ts` | 3 | 다이얼로그 렌더링 |
| `TextPanel.spec.ts` | 5 | 폰트/사이즈/색상 필드 존재 |
| `TransformPanel.spec.ts` | 4 | X/Y/W/H 필드 존재 |
| `useGfxStore.spec.ts` | 5 | 초기 상태, addElement, selectElement |

### 공통 패턴

```typescript
// 16개 파일 전부 이 패턴
it('renders XYZ section', () => {
  const wrapper = mountQ(Component);
  expect(wrapper.text()).toContain('Label Text');
});
```

### CRITICAL 미테스트 영역

| 영역 | 위험도 |
|------|:------:|
| **사용자 interaction** (클릭, 드래그, 입력) | CRITICAL |
| **Pinia store 상태 변경** 후 UI 반영 | CRITICAL |
| **Canvas 렌더링 로직** | HIGH |
| **색상 변환 계산** (HUE, RGB) | HIGH |
| **Undo/Redo** 스택 | HIGH |
| **Import/Export** 기능 | MEDIUM |
| **키보드 단축키** | MEDIUM |

### 긍정 요소

- **Playwright 1.58.2 설치됨** — E2E 인프라 준비 상태
- **Vitest 3.0.9 + @vue/test-utils** — 프레임워크 최신
- **mountQ 헬퍼** 공유 — Quasar+Pinia 설정 재사용

---

## 게임 엔진 시나리오 테스트 강화 (참고)

이 세션에서 수행한 게임 엔진 시나리오 테스트 강화는 앱 QA의 참고 사례로 기록한다.

### 수행 내용

- `scenario_runner_test.dart`에 **칩 보존 invariant** 자동 검증 추가
- 15개 YAML 시나리오에 `stacks`, `pot_total`, `community_count`, `seat_statuses` assertions 추가
- **6개 시나리오의 `pot_awarded` 산술 오류 발견 및 수정**

### 발견된 버그

| 시나리오 | 문제 | delta |
|---------|------|:-----:|
| 01 nlh-basic-showdown | award 320→305 | +15 |
| 06 shortdeck-flush | award 310→300 | +10 |
| 11 courchevel-preflop | award 80→100 | -20 |
| 13 heads-up-blinds | award 60→90 | -30 |
| 14 minraise-tracking | award 580→590 | -10 |
| 15 allin-less-than-call | award {75,70}→{75,50} | +20 |

### 교훈

1. **Invariant 검증**이 가장 효과적 — 칩 보존 1줄로 6개 버그 포착
2. **"PASS" ≠ "검증됨"** — `expect(state, isNotNull)`은 검증이 아님
3. **Capture-then-verify** 패턴 — 엔진 산출값 캡처 → 수동 검증 → golden value 설정

> 이 패턴을 앱 테스트에도 적용할 것을 권장한다.

---

## 결론

3개 앱 모두 **"렌더 테스트 함정"** 상태이다. 컴포넌트가 크래시 없이 마운트되는지만 확인하며, 비즈니스 로직·상태 전환·에러 처리를 검증하지 않는다.

### 다음 단계

- **TEST-07**: 앱별 QA 전략 및 구현 가이드
- 구현은 별도 세션에서 앱별로 진행
