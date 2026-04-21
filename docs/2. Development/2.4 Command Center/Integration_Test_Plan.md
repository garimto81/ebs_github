---
title: Integration Test Plan
owner: team4
tier: internal
last-updated: 2026-04-15
---

# TEST-PLAN: team4-cc 통합 테스트 계획

> **통합 노트 (2026-04-14)**: TEST-01~07 (총 2,033줄, 7개 문서) 를 본 통합본 1개로 정리. 원본은 `C:/claude/ebs-archive-backup/07-archive/team4-cc-cleanup-20260414/testing/` 보존.

## Edit History

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | TEST-01~05 신규 | 테스트 계획·E2E·픽스처·Mock·QA체크 |
| 2026-04-09 | TEST-06,07 신규 | 앱 감사·QA 전략 |
| 2026-04-14 | 통합 | 7개 문서 → 1개 합본, 원본은 외부 백업 |
| 2026-04-21 | Hand History E2E 추가 | §2 E2E 시나리오 끝에 시나리오 11 (Lobby Hand History 실시간 갱신 + RBAC 마스킹 + API 필터) 추가. SG-016 revised 후속 (Migration Plan Phase 4) |

## 목차

- §1 테스트 계획서 (피라미드/도구/커버리지/CI/Mock)
- §2 E2E 시나리오 (방송 하루 순서 10개)
- §3 Game Engine Fixtures (Hold'em 32 케이스)
- §4 Mock 데이터 (WSOP LIVE, RFID, Player, Config)
- §5 QA 체크리스트 (수동 QA 56 항목 / 7 카테고리)
- §6 앱 테스트 품질 감사 (Lobby/CC/GE)
- §7 앱 QA 전략 + 구현 체크리스트

---


# §1 — TEST-01-test-plan


| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 테스트 피라미드, 앱별 도구, 커버리지, CI/CD, Mock 전략 |

---

### 개요

EBS 소프트웨어 QA 테스트 전략을 정의한다. 물리 하드웨어(RFID 안테나, ST25R3911B, ESP32)는 테스트 범위에서 제외하며, 모든 RFID 관련 테스트는 `MockRfidReader`를 통한 소프트웨어 에뮬레이션으로 수행한다.

> 참조: Mock 모드 정의 — BS-00 §9, RFID HAL 인터페이스 — API-03

---

### 1. 테스트 피라미드

```
          ┌───────────┐
          │   E2E     │  10%
          │ (Browser) │
          ├───────────┤
          │  Widget / │  20%
          │Integration│
          ├───────────┤
          │           │
          │   Unit    │  70%
          │           │
          └───────────┘
```

| 계층 | 비율 | 목적 | 실행 시간 |
|------|:----:|------|:--------:|
| **Unit** | 70% | 개별 함수/클래스 단위 검증 | <1초/테스트 |
| **Widget/Integration** | 20% | UI 위젯 렌더링 + 서비스 간 연동 | <5초/테스트 |
| **E2E** | 10% | 방송 하루 전체 시나리오 재현 | <60초/시나리오 |

#### 계층별 테스트 대상

| 계층 | Game Engine | CC | BO | Lobby |
|------|:-----------:|:--:|:--:|:-----:|
| **Unit** | HandFSM, 베팅 검증, 팟 계산, 핸드 평가, Equity | 위젯 상태 로직 | API endpoint, DB 쿼리 | 컴포넌트 로직 |
| **Widget/Integration** | — | CC UI + MockRfidReader 연동 | API + DB 통합 | 페이지 렌더링 |
| **E2E** | — | CC → BO → Overlay 전체 흐름 | — | Lobby → BO → CC 전체 흐름 |

---

### 2. 앱별 테스트 도구

#### 2.1 Game Engine (순수 Dart 패키지)

| 항목 | 값 |
|------|:--|
| **프레임워크** | `dart test` (package:test) |
| **러너** | `dart test --reporter=expanded` |
| **Mocking** | `package:mocktail` |
| **커버리지** | `dart test --coverage` → `lcov` |
| **대상** | HandFSM 상태 전이, 베팅 유효성, 팟 분배, 핸드 평가, Equity 계산 |

#### 2.2 Command Center (Flutter 앱)

| 항목 | 값 |
|------|:--|
| **프레임워크** | `flutter test` (Unit + Widget) |
| **Widget 테스트** | `testWidgets()` + `WidgetTester` |
| **Mocking** | `package:mocktail` + `MockRfidReader` |
| **Golden 테스트** | `matchesGoldenFile()` (Overlay 스냅샷) |
| **Integration** | `flutter test integration_test/` |
| **대상** | CC UI 상호작용, RFID Mock 연동, Overlay 렌더링 |

#### 2.3 Back Office (Python FastAPI)

| 항목 | 값 |
|------|:--|
| **프레임워크** | `pytest` |
| **HTTP 클라이언트** | `httpx.AsyncClient` (TestClient) |
| **DB** | SQLite in-memory (테스트용) |
| **Mocking** | `unittest.mock` + `pytest-mock` |
| **커버리지** | `pytest --cov=src --cov-report=html` |
| **대상** | REST API, WebSocket, DB CRUD, 인증, 동기화 |

#### 2.4 Lobby (Flutter Desktop 앱)

| 항목 | 값 |
|------|:--|
| **Unit/Widget** | `flutter_test` + `mocktail` |
| **Integration** | `integration_test` (flutter_driver 후속) |
| **Mocking** | `http_mock_adapter` (Dio) — BO REST API Mock / `mockito` 로 provider override |
| **커버리지** | `vitest --coverage` |
| **대상** | Lobby UI, 테이블 관리, Settings, Auth |

---

### 3. 커버리지 목표

| 앱 | 목표 | 측정 도구 | 비고 |
|----|:----:|----------|------|
| **Game Engine** | ≥90% | `dart test --coverage` | 핵심 비즈니스 로직 — 최고 커버리지 |
| **Back Office** | ≥80% | `pytest --cov` | API + DB 계층 |
| **Command Center** | ≥70% | `flutter test --coverage` | UI 위젯 포함, Golden 테스트 병행 |
| **Lobby** | ≥70% | `vitest --coverage` | 컴포넌트 + 페이지 |

#### 커버리지 제외 대상

| 제외 대상 | 이유 |
|----------|------|
| `RealRfidReader` | 물리 하드웨어 의존 — Mock HAL로 대체 |
| UI 애니메이션 코드 | Rive 애니메이션은 시각적 검증 (Golden 테스트) |
| 3rd party 라이브러리 래퍼 | 외부 라이브러리 내부 코드 미포함 |

---

### 4. CI/CD 연동 — GitHub Actions

#### 4.1 파이프라인 구조

```
push / PR
  ├─ [Job 1] Game Engine
  │    ├─ dart test --coverage
  │    └─ coverage check (≥90%)
  ├─ [Job 2] CC (Flutter)
  │    ├─ flutter test --coverage
  │    └─ coverage check (≥70%)
  ├─ [Job 3] BO (Python)
  │    ├─ pytest --cov
  │    └─ coverage check (≥80%)
  ├─ [Job 4] Lobby (Web)
  │    ├─ vitest --coverage
  │    └─ coverage check (≥70%)
  └─ [Job 5] E2E (PR merge 시만)
       └─ playwright (Lobby E2E)
```

#### 4.2 트리거 조건

| 이벤트 | Job 1~4 | Job 5 (E2E) |
|--------|:-------:|:-----------:|
| Push to feature branch | 실행 | 미실행 |
| PR to main | 실행 | 실행 |
| Merge to main | 실행 | 실행 |

#### 4.3 실패 시 처리

| 조건 | 처리 |
|------|------|
| Unit/Widget 테스트 실패 | PR merge 차단 |
| 커버리지 목표 미달 | PR merge 차단 + 커버리지 리포트 코멘트 |
| E2E 실패 | PR merge 차단 + 스크린샷 아티팩트 저장 |

---

### 5. Mock 전략

#### 5.1 RFID — MockRfidReader

| 항목 | 방식 |
|------|------|
| **구현체** | `MockRfidReader` (API-03 §6) |
| **DI 교체** | Riverpod `ProviderScope(overrides: [...])` |
| **이벤트 합성** | `injectCard()`, `injectRemoval()`, `injectError()` |
| **시나리오 재생** | YAML 시나리오 파일 로드 (`loadScenario()`) |
| **결정적 타이밍** | delay_ms 지정, 동일 입력 = 동일 출력 보장 |

> 참조: Mock HAL 테스트 케이스 31개 — API-03 §8

#### 5.2 WSOP LIVE — JSON Fixtures

| 항목 | 방식 |
|------|------|
| **데이터 소스** | `test/fixtures/wsop-live/` 디렉토리의 JSON 파일 |
| **내용** | Competition, Series, Event, Flight, Player, BlindStructure |
| **로드 방식** | BO 테스트: 파일 직접 로드 / Lobby 테스트: MSW 응답 Mock |

> 참조: Mock 데이터 상세 — TEST-04-mock-data.md

#### 5.3 Back Office — In-Memory DB

| 항목 | 방식 |
|------|------|
| **DB** | SQLite `:memory:` (테스트별 격리) |
| **마이그레이션** | 테스트 시작 시 자동 스키마 생성 |
| **Seed 데이터** | `conftest.py`에서 공통 fixture 로드 |
| **격리** | 각 테스트 함수별 독립 트랜잭션 → rollback |

#### 5.4 WebSocket — Mock Event Stream

| 항목 | 방식 |
|------|------|
| **CC 테스트** | `MockWebSocketChannel` — BO 이벤트 에뮬레이션 |
| **Lobby 테스트** | MSW WebSocket handler — BO 이벤트 에뮬레이션 |
| **이벤트 타입** | BS-06-00-triggers.md §2.4 BO 소스 이벤트 전체 |

---

### 6. 테스트 명명 규칙

#### 6.1 파일명

| 앱 | 패턴 | 예시 |
|----|------|------|
| Game Engine | `test/{module}_test.dart` | `test/hand_fsm_test.dart` |
| CC | `test/{widget}_test.dart` | `test/action_panel_test.dart` |
| BO | `tests/test_{module}.py` | `tests/test_hand_api.py` |
| Lobby | `__tests__/{component}.test.ts` | `__tests__/TableList.test.ts` |

#### 6.2 테스트 이름

```
{상황}_{입력}_{기대결과}
```

예시:
- `preFlopBetting_foldAction_playerStatusFolded`
- `allInWithSidePot_threePlayersAllIn_twoSidePotsCreated`
- `mockRfid_injectCard_cardDetectedEventEmitted`

---

### 7. 테스트 데이터 관리

| 유형 | 저장 위치 | 형식 |
|------|----------|------|
| WSOP LIVE fixtures | `test/fixtures/wsop-live/` | JSON |
| RFID 시나리오 | `test/fixtures/rfid-scenarios/` | YAML |
| Player 샘플 | `test/fixtures/players/` | JSON |
| Settings 프리셋 | `test/fixtures/config/` | JSON |
| Golden 이미지 | `test/goldens/` | PNG |

> 참조: Mock 데이터 상세 — TEST-04-mock-data.md

---

### 비활성 조건

- 물리 RFID 하드웨어 테스트: 항상 비활성 (Mock HAL만 사용)
- E2E 테스트: feature branch push 시 비활성 (PR/merge 시만 실행)
- Golden 테스트 업데이트: `--update-goldens` 플래그로만 허용

---

### 영향 받는 요소

| 요소 | 관계 |
|------|------|
| TEST-02 E2E Scenarios | 이 계획서의 E2E 계층 상세 시나리오 |
| TEST-03 Game Engine Fixtures | 이 계획서의 Unit 계층 테스트 케이스 |
| TEST-04 Mock Data | 이 계획서의 Mock 전략 데이터 상세 |
| TEST-05 QA Checklist | 이 계획서의 수동 검증 보완 |
| API-03 RFID HAL | MockRfidReader 인터페이스 계약 |
| BS-06-00 Triggers | Mock 합성 규칙, 시나리오 스크립트 형식 |

---

# §2 — TEST-02-e2e-scenarios


| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 방송 하루 순서 기반 10개 E2E 시나리오 |
| 2026-04-21 | S-11 추가 | Lobby Hand History 시나리오 (실시간 갱신 + RBAC 마스킹 + API 필터). SG-016 revised, Migration Plan Phase 4 |
| 2026-04-21 | S-11 자동화 스캐폴드 | Playwright (API/WS/RBAC) + flutter_driver skeleton (Lobby UI) 추가. `Integration_Test_Plan/automation/s11/` — decision_owner: team4, notify: team1 (UI wiring), team2 (seeder INSERT) |

---

### 개요

EBS 방송 하루의 전체 워크플로우를 11개 E2E 시나리오로 정의한다. 각 시나리오는 실제 운영 순서를 따르며, 모든 RFID 동작은 `MockRfidReader`로 수행한다.

> 참조: HandFSM — BS-06-01, 트리거 경계 — BS-06-00, Mock HAL — API-03 §6

---

### 시나리오 흐름 개요

```
S-01 로그인
  → S-02 대회 생성
    → S-03 테이블+플레이어
      → S-04 Settings
        → S-05 CC Launch+덱등록
          → S-06 핸드 1판
            → S-07 All-In+Side Pot
              → S-08 Undo+Miss Deal
                → S-09 Mix 게임 전환
                  → S-10 핸드 종료+통계
                    → S-11 Lobby Hand History 조회+필터+RBAC
```

---

### S-01: Admin 로그인 → Lobby 진입

#### 전제조건
- BO 서버 실행 중
- Lobby Flutter Desktop 앱 실행 가능
- Admin 계정 존재 (`admin@ebs.local` / password)

#### 단계

| # | 행위자 | 액션 | 기대 결과 |
|:-:|--------|------|----------|
| 1 | Admin | Lobby URL 접속 | 로그인 화면 표시 |
| 2 | Admin | Admin 계정으로 로그인 | JWT 토큰 발급, Lobby 메인 화면 진입 |
| 3 | 시스템 | RBAC 권한 확인 | Admin 역할 — 모든 메뉴 접근 가능 |
| 4 | Admin | 대시보드 확인 | 테이블 목록 (비어있음), 시스템 상태 표시 |

#### 검증 포인트
- JWT 토큰이 응답 헤더/쿠키에 포함됨
- Admin 역할에서 Settings, Table 생성, CC Launch 메뉴 모두 활성
- Operator 계정 로그인 시 할당된 테이블만 표시 (음성 테스트)

---

### S-02: Series/Event/Flight 생성 (수동)

#### 전제조건
- S-01 완료 (Admin 로그인 상태)

#### 단계

| # | 행위자 | 액션 | 기대 결과 |
|:-:|--------|------|----------|
| 1 | Admin | Series 생성 ("2026 WSOP") | Series 목록에 표시 |
| 2 | Admin | Event 생성 ("Event #1: $10K NL Hold'em") | Event 목록에 표시, Series에 연결 |
| 3 | Admin | Flight 생성 ("Day 1A") | Flight 목록에 표시, Event에 연결 |
| 4 | 시스템 | BO DB 저장 확인 | Competition → Series → Event → Flight 계층 구조 정합 |

#### 검증 포인트
- 계층 관계: Competition → Series → Event → Flight 정상 연결
- 필수 필드 누락 시 유효성 검증 에러 표시
- 중복 이름 허용 (같은 Event 내 Flight 이름은 고유)

---

### S-03: Table 생성 + Player 등록 + 좌석 배치

#### 전제조건
- S-02 완료 (Flight 존재)

#### 단계

| # | 행위자 | 액션 | 기대 결과 |
|:-:|--------|------|----------|
| 1 | Admin | Table 생성 ("Table 1 — Feature Table") | Table 상태 = EMPTY |
| 2 | Admin | Flight에 Table 할당 | Table이 Flight 하위에 표시 |
| 3 | Admin | Player 6명 등록 (이름, 국적, 프로필) | Player DB에 6명 저장 |
| 4 | Admin | 6명 좌석 배치 (Seat 0, 1, 3, 5, 7, 9) | Seat 상태: 6개 OCCUPIED, 4개 VACANT |
| 5 | 시스템 | Table 상태 전이 확인 | Table 상태 = SETUP |

#### 검증 포인트
- Seat 번호 범위: 0~9 (10석)
- 동일 좌석에 2명 배치 시도 → 에러
- Player 이동(SeatMove): Seat 3 → Seat 4 정상 작동
- Table 상태가 EMPTY → SETUP으로 전이

---

### S-04: Settings 설정 (Output/Overlay/Game/Statistics)

#### 전제조건
- S-03 완료 (Table + Player 설정 완료)

#### 단계

| # | 행위자 | 액션 | 기대 결과 |
|:-:|--------|------|----------|
| 1 | Admin | Output 설정 — NDI 출력, 1080p, Security Delay 10초 | OutputPreset 저장 |
| 2 | Admin | Overlay 설정 — Skin 선택, 카드 스타일 | Skin 적용 확인 |
| 3 | Admin | Game 설정 — NL Hold'em, BB=100, SB=50, Ante=0 | BlindStructure 저장 |
| 4 | Admin | Statistics 설정 — VPIP/PfR/WTSD 표시 ON | 통계 표시 옵션 저장 |
| 5 | 시스템 | BO DB 확인 | 4개 Settings 영역 모두 저장됨 |

#### 검증 포인트
- Settings 변경 시 `ConfigChanged` WebSocket 이벤트 발행 확인
- 잘못된 값 (BB < SB, 해상도 0×0) 입력 시 유효성 에러
- Settings 프리셋 저장/로드 작동

---

### S-05: CC Launch → 덱 등록 (Mock 자동)

#### 전제조건
- S-04 완료 (Settings 설정 완료)
- RFID 모드 = Mock

#### 단계

| # | 행위자 | 액션 | 기대 결과 |
|:-:|--------|------|----------|
| 1 | Admin | CC Launch 버튼 클릭 | CC 앱 실행, BO WebSocket 연결 |
| 2 | 시스템 | WebSocket 연결 확인 | `OperatorConnected` 이벤트, Lobby 모니터링 갱신 |
| 3 | 시스템 | MockRfidReader 초기화 | status = ready, AntennaStatusChanged(connected) |
| 4 | 운영자 | "자동 등록" 버튼 클릭 | `autoRegisterDeck()` 호출 |
| 5 | 시스템 | Mock 덱 등록 완료 | DeckRegistered 이벤트, 52장 매핑, Deck 상태 = REGISTERED |
| 6 | 시스템 | Table 상태 전이 | Table 상태 = LIVE |

#### 검증 포인트
- Mock 모드: 덱 등록 즉시 완료 (0ms)
- 52장 cardMap 정합: suit 0~3 × rank 0~12 = 52장
- CC UI에 Deck 상태 "REGISTERED" 표시
- Lobby 모니터링에 Table 상태 "LIVE" 반영

---

### S-06: Hold'em 핸드 1판 전체 진행 (Pre-Flop → Showdown)

#### 전제조건
- S-05 완료 (CC LIVE, 덱 등록, 6명 착석)
- 게임: NL Hold'em, BB=100, SB=50

#### 단계

| # | 행위자 | 액션 | 기대 결과 |
|:-:|--------|------|----------|
| 1 | 운영자 | NEW HAND 버튼 | HandFSM: IDLE → SETUP_HAND, BlindsPosted |
| 2 | 시스템 | SB/BB 자동 수집 | SB(50) + BB(100) 팟 추가, 스택 차감 |
| 3 | 운영자 | Mock 홀카드 입력 (6명 × 2장 = 12장) | CardDetected × 12, HandFSM → PRE_FLOP |
| 4 | 운영자 | UTG Fold | player.status = folded, action_on 이동 |
| 5 | 운영자 | MP Call(100) | biggest_bet_amt 유지, 스택 차감 |
| 6 | 운영자 | CO Raise(300) | biggest_bet_amt = 300, min_raise_amt 갱신 |
| 7 | 운영자 | BTN Fold, SB Fold, BB Call(300) | 3명 폴드, BB 콜 |
| 8 | 운영자 | MP Call(300) | PRE_FLOP 베팅 완료 |
| 9 | 시스템 | BettingRoundComplete | HandFSM → FLOP 대기 |
| 10 | 운영자 | Mock 보드 카드 3장 입력 | CardDetected × 3, board_cards = 3, HandFSM → FLOP |
| 11 | 운영자 | BB Check, MP Bet(400), CO Raise(1000), BB Fold, MP Call(1000) | FLOP 베팅 완료 |
| 12 | 운영자 | Mock Turn 카드 1장 입력 | board_cards = 4, HandFSM → TURN |
| 13 | 운영자 | MP Check, CO Bet(2000), MP Call(2000) | TURN 베팅 완료 |
| 14 | 운영자 | Mock River 카드 1장 입력 | board_cards = 5, HandFSM → RIVER |
| 15 | 운영자 | MP Check, CO Check | RIVER 베팅 완료, final_betting_round = true |
| 16 | 시스템 | ShowdownStarted → WinnerDetermined | 핸드 평가, 우승자 결정 |
| 17 | 시스템 | HandCompleted | 팟 분배, 통계 업데이트, HandFSM → HAND_COMPLETE |

#### 검증 포인트
- 각 상태 전이마다 HandFSM game_phase 값 정확
- 팟 금액 누적 정합: SB(50) + BB(100) + 베팅 합계
- Overlay에 보드 카드, 플레이어 카드, 팟 금액 표시
- Hand History에 모든 액션 기록됨

---

### S-07: 특수 상황 — All-In → Side Pot → Showdown

#### 전제조건
- S-06 완료 후 다음 핸드 시작
- 3명 남음: P1(stack=1000), P2(stack=3000), P3(stack=5000)

#### 단계

| # | 행위자 | 액션 | 기대 결과 |
|:-:|--------|------|----------|
| 1 | 운영자 | NEW HAND, 홀카드 딜 | SETUP_HAND → PRE_FLOP |
| 2 | 운영자 | P1 All-In(1000) | SidePotCreated, P1.status = allin |
| 3 | 운영자 | P2 All-In(3000) | 두 번째 SidePotCreated, P2.status = allin |
| 4 | 운영자 | P3 Call(3000) | PRE_FLOP 완료 |
| 5 | 시스템 | AllInRunout | 남은 보드 자동 공개 필요 |
| 6 | 운영자 | Mock 보드 5장 순차 입력 | board_cards = 5, SHOWDOWN 진입 |
| 7 | 시스템 | WinnerDetermined | 팟별 승자 결정 |
| 8 | 시스템 | HandCompleted | 팟 분배 완료 |

#### 검증 포인트
- **Main Pot**: 1000 × 3 = 3000 (P1, P2, P3 참여)
- **Side Pot 1**: (3000 - 1000) × 2 = 4000 (P2, P3 참여)
- **Side Pot 2**: 5000 - 3000 = 2000 (P3만, 반환)
- 각 Pot별 독립 승자 결정
- P1 승리 시 Main Pot만 수령, Side Pot은 P2/P3 중 승자

---

### S-08: Undo 5단계 + Miss Deal 복구

#### 전제조건
- 핸드 진행 중 (PRE_FLOP 이후)

#### 단계

| # | 행위자 | 액션 | 기대 결과 |
|:-:|--------|------|----------|
| 1 | 운영자 | P1 Bet(200) | 정상 처리 |
| 2 | 운영자 | P2 Raise(500) | 정상 처리 |
| 3 | 운영자 | P3 Call(500) | 정상 처리 |
| 4 | 운영자 | UNDO 1회 | P3 Call 되돌림, action_on = P3 |
| 5 | 운영자 | UNDO 2회 | P2 Raise 되돌림, action_on = P2 |
| 6 | 운영자 | UNDO 3회 | P1 Bet 되돌림, action_on = P1 |
| 7 | 운영자 | P1 Bet(300) — 다른 금액으로 재입력 | 정상 처리 |
| 8 | 운영자 | Miss Deal 선언 | HandFSM → IDLE, 스택 복구 |
| 9 | 시스템 | 팟 복원 확인 | 모든 플레이어 스택 = 핸드 시작 시점 |

#### 검증 포인트
- UNDO 최대 5단계 제한 — 6번째 UNDO 시도 시 거부
- UNDO 후 action_on 정확히 복원
- UNDO 후 biggest_bet_amt 정확히 복원
- Miss Deal 후 IDLE 상태, 모든 칩 원복

---

### S-09: Mix 게임 전환 (종목 변경)

#### 전제조건
- Event 설정: Mix 게임 (HORSE — Hold'em, Omaha, Razz, Stud, Eight-or-Better)
- 현재 Hold'em 핸드 완료 상태

#### 단계

| # | 행위자 | 액션 | 기대 결과 |
|:-:|--------|------|----------|
| 1 | 시스템 | 8핸드 완료 감지 | 게임 종목 전환 알림 |
| 2 | 운영자 | 다음 종목 확인 (Omaha) | CC UI에 "Omaha Hi-Lo" 표시 |
| 3 | 시스템 | `GameChanged` 이벤트 | BO → Lobby 모니터링 갱신 |
| 4 | 운영자 | Omaha 핸드 시작 | 홀카드 4장 (Hold'em은 2장), 게임 규칙 변경 적용 |

#### 검증 포인트
- 종목 전환 시 블라인드 구조 자동 변경 (FL → NL 등)
- Overlay 게임명 표시 갱신
- Lobby 모니터링 종목 표시 갱신
- 이전 종목 통계와 현재 종목 통계 분리 기록

---

### S-10: 핸드 종료 → Hand History 확인 → 통계 검증

#### 전제조건
- S-06~S-09 시나리오 실행 완료 (복수 핸드 진행됨)

#### 단계

| # | 행위자 | 액션 | 기대 결과 |
|:-:|--------|------|----------|
| 1 | 운영자 | 마지막 핸드 HAND_COMPLETE 확인 | HandFSM 상태 정확 |
| 2 | Admin | Lobby에서 Hand History 조회 | 진행된 모든 핸드 목록 표시 |
| 3 | Admin | 특정 핸드 상세 보기 | 모든 액션, 카드, 팟, 승자 기록 확인 |
| 4 | Admin | 플레이어 통계 확인 | VPIP, PfR, WTSD, Aggression 수치 |
| 5 | 운영자 | Table Pause | Table 상태 = PAUSED |
| 6 | 운영자 | Table Close | Table 상태 = CLOSED |
| 7 | 시스템 | WebSocket 해제 확인 | `OperatorDisconnected` 이벤트 |

#### 검증 포인트
- Hand History: 핸드 번호, 시작/종료 시간, 모든 액션 순서
- 통계 정합성:
  - VPIP = (자발적 팟 참여 핸드 수 / 전체 핸드 수) × 100%
  - PfR = (프리플롭 레이즈 핸드 수 / 전체 핸드 수) × 100%
- Table 상태 전이: LIVE → PAUSED → CLOSED
- Close 후 CC 앱에서 새 핸드 시작 불가

---

### 비활성 조건

- 물리 RFID 장비 연결 시나리오: 항상 비활성 (Mock만)
- 네트워크 장애 시나리오: 이 문서 범위 외 (별도 장애 테스트 계획 필요)

---

### 영향 받는 요소

| 요소 | 관계 |
|------|------|
| TEST-01 Test Plan | E2E 계층 10% 비율의 시나리오 상세 |
| TEST-04 Mock Data | 시나리오에서 사용하는 Mock 데이터 정의 |
| BS-06-01 Lifecycle | HandFSM 상태 전이 검증 기준 |
| BS-06-02 Betting | 베팅 유효성 검증 기준 |
| API-03 RFID HAL | MockRfidReader 이벤트 합성 규칙 |

---

### S-11: Lobby Hand History 조회 + 필터 + RBAC (2026-04-21)

#### 전제조건
- S-10 까지 완료 (당일 핸드 N개 DB 저장됨)
- Admin / Operator(table_id=1 할당) / Viewer 3 계정 준비

#### 단계

| # | 동작 | 기대 결과 |
|:-:|------|----------|
| 1 | Admin 사이드바 [Hand History] 클릭 | Hand Browser 열림. 당일 모든 Event 의 핸드 N개 표시 |
| 2 | Admin 필터 `event_id=1, table_id=1, date_from=오늘 00:00` | API: `GET /api/v1/hands?event_id=1&table_id=1&date_from=...` 호출. 응답 200, 매칭 핸드만 표시 |
| 3 | Admin 핸드 #1 클릭 → Hand Detail | API: `/hands/1`, `/hands/1/actions`, `/hands/1/players` 3 호출. timeline + Seat Grid + 모든 hole card 공개 |
| 4 | Admin Detail 화면 유지 중 CC 가 새 핸드 시작 | WS `HandStarted` 수신 → Browser 행 prepend, Detail 은 변화 없음 (다른 hand_id) |
| 5 | Admin Hand #1 Detail 중 CC 가 ActionPerformed 송신 (다른 hand) | Detail 변화 없음 (해당 hand_id 만 stream) |
| 6 | Operator 로 재로그인, Hand Browser 진입 | table_id=1 핸드만 표시. table_id=2 미표시 |
| 7 | Operator URL `event_id=1&table_id=2` 직접 호출 | 빈 결과 (403 아님 — 정보 노출 회피) |
| 8 | Viewer 로 재로그인, Hand Detail 진입 | Seat Grid 의 모든 hole card 가 `★` 마스킹. Action timeline / pot / winner 는 정상 표시 |
| 9 | Player Hand Stats 진입 | Admin 전체 player, Operator 본인 테이블 player, Viewer 전체 (읽기) |
| 10 | 어제 날짜 필터 (`date_from=어제, date_to=어제`) | 당일 한정 정책 — 응답은 200 빈 결과 + UI 배너 "당일 한정" |

#### 검증 포인트

| 항목 | 검증 방법 |
|------|----------|
| WS 실시간 갱신 | Browser 목록의 첫 행이 새 hand_id 로 변경됨을 확인 (DOM polling 50ms × 5회) |
| RBAC hole card | Viewer 응답 JSON `hole_card_1=="★"` |
| 필터 정확성 | API 호출 query string 캡처 후 응답 row 의 event_id/table_id 일치 |
| 페이지네이션 | `?page=2&page_size=20` 호출 후 첫 페이지와 hand_id 비중복 확인 |
| Operator 권한 | 미할당 테이블 요청 시 빈 결과 + 403 발생 X |

#### 회귀 방지

S-10 의 통계 계산이 본 화면 Player Hand Stats 와 동일 값임을 확인 (team3 engine 단일 source 검증).

#### 참조

- `docs/2. Development/2.1 Frontend/Lobby/Hand_History.md` (소비자 SSOT)
- `docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md §5.10.1` (필터 스펙)
- `docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md §3.3.3 Lobby Hand History 소비자`
- `docs/2. Development/2.4 Command Center/Overlay/Layer_Boundary.md §1.4` (Overlay 비대상 명시)
- **자동화 스캐폴드**: `docs/2. Development/2.4 Command Center/Integration_Test_Plan/automation/s11/` (Playwright API/WS + flutter_driver skeleton + runner)

---

# §3 — TEST-03-game-engine-fixtures


| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | Hold'em 대표 테스트 케이스 32개 (10개 카테고리) |

---

### 개요

Game Engine(순수 Dart 패키지)의 Hold'em 테스트 케이스를 정의한다. 각 케이스는 **입력(players, cards, actions)**과 **기대 출력(game_phase, pots, winners)**을 명시하며, 결정론적 재현이 가능하다.

> 참조: HandFSM — BS-06-01, 베팅 액션 — BS-06-02, Mock 합성 — BS-06-00 §4

#### 표기법

| 표기 | 의미 |
|------|------|
| `As` | Ace of Spades |
| `Kh` | King of Hearts |
| `Td` | Ten of Diamonds |
| `9c` | Nine of Clubs |
| suit: 0=Spade, 1=Heart, 2=Diamond, 3=Club | rank: 0=Two ~ 12=Ace |

---

### 카테고리 1: 기본 흐름 (Pre-Flop → Showdown)

#### TC-01: 6인 정상 핸드 — Showdown 도달

| 항목 | 값 |
|------|:--|
| **Players** | P0~P5, stack=10000 각각, BB=100, SB=50, Dealer=P0 |
| **Hole Cards** | P0: `As Ks`, P1: `Qh Jh`, P2: `Td 9d`, P3: `8c 7c`, P4: `6s 5s`, P5: `4h 3h` |
| **Board** | `Ah 7d 2c Ts 3s` |
| **Actions** | PRE_FLOP: P3 Call, P4 Fold, P5 Fold, P0 Raise(300), P1 Call, P2 Fold, P3 Call → FLOP: P1 Check, P3 Check, P0 Bet(500), P1 Call, P3 Fold → TURN: P1 Check, P0 Bet(1000), P1 Call → RIVER: P1 Check, P0 Check |
| **기대 결과** | game_phase = SHOWDOWN → HAND_COMPLETE, winner = P0 (Pair of Aces, K kicker), pot = 4550 |

#### TC-02: 2인 Heads-Up 정상 핸드

| 항목 | 값 |
|------|:--|
| **Players** | P0, P1, stack=5000, BB=100, SB=50, Dealer=P0 (Heads-up: Dealer=SB) |
| **Hole Cards** | P0: `Kd Qd`, P1: `Jc Tc` |
| **Board** | `9h 8s 2d Kc 4h` |
| **Actions** | PRE_FLOP: P0 Call, P1 Check → FLOP: P1 Bet(200), P0 Call → TURN: P1 Check, P0 Bet(500), P1 Call → RIVER: P1 Check, P0 Check |
| **기대 결과** | winner = P0 (Pair of Kings), pot = 1550 |

#### TC-03: 3인 핸드 — River에서 최종 결정

| 항목 | 값 |
|------|:--|
| **Players** | P0~P2, stack=8000, BB=200, SB=100 |
| **Hole Cards** | P0: `Ah Kh`, P1: `Qs Qd`, P2: `Jd Td` |
| **Board** | `Qh Th 5c 3s 2h` |
| **Actions** | PRE_FLOP: 전원 Call → FLOP~RIVER: 전원 Check |
| **기대 결과** | winner = P0 (Flush, Ace-high Hearts), pot = 600 |

#### TC-04: 4인 핸드 — Flop에서 3명 폴드

| 항목 | 값 |
|------|:--|
| **Players** | P0~P3, stack=10000, BB=100, SB=50 |
| **Hole Cards** | P0: `7s 2d`, P1: `As Kd`, P2: `9c 8c`, P3: `Jh Th` |
| **Board** | `Ac 5d 3h` (Flop만) |
| **Actions** | PRE_FLOP: 전원 Call → FLOP: P1 Bet(300), P2 Fold, P3 Fold, P0 Fold |
| **기대 결과** | winner = P1 (All Fold at FLOP), game_phase = HAND_COMPLETE, pot = 700 |

#### TC-05: 최대 10인 핸드 — PRE_FLOP 다수 폴드 후 2인 진행

| 항목 | 값 |
|------|:--|
| **Players** | P0~P9, stack=10000, BB=100, SB=50 |
| **Hole Cards** | P0: `As Ad`, P9: `Ks Kd`, 나머지 임의 |
| **Board** | `7c 4d 2s Jh 8c` |
| **Actions** | PRE_FLOP: P2~P8 Fold, P9 Raise(300), P0 Call, P1 Fold → FLOP~RIVER: P0 Check, P9 Check (전 라운드) |
| **기대 결과** | winner = P0 (Pair of Aces), pot = 750 |

---

### 카테고리 2: 베팅 — NL Bet/Raise/All-In 금액 계산

#### TC-06: NL 최소 레이즈 계산

| 항목 | 값 |
|------|:--|
| **Setup** | 3인, BB=100, P1 Bet(200) |
| **테스트** | P2 Raise 시 최소 금액 |
| **기대 결과** | min_raise = 200 + (200 - 0) = 400. P2 Raise(300) → REJECTED, P2 Raise(400) → ACCEPTED |

#### TC-07: NL 연속 레이즈 — min_raise 추적

| 항목 | 값 |
|------|:--|
| **Setup** | 4인, BB=100. P1 Bet(200), P2 Raise(500) |
| **테스트** | P3 Raise 시 최소 금액 |
| **기대 결과** | last_raise_increment = 500 - 200 = 300, min_raise = 500 + 300 = 800 |

#### TC-08: Short All-In Call 처리

| 항목 | 값 |
|------|:--|
| **Setup** | 3인. P1(stack=500) Bet(500) All-In, P2(stack=300) Call |
| **테스트** | P2 Call 금액 |
| **기대 결과** | P2 Call = 300 (short call), P2.status = allin, side pot 분리 |

#### TC-09: PL 최대 베팅 계산

| 항목 | 값 |
|------|:--|
| **Setup** | 3인, PL, pot=600, biggest_bet=200, P1.current_bet=0 |
| **테스트** | P1 Raise 최대 금액 |
| **기대 결과** | max_raise = pot(600) + call(200) + call(200) = 1000. P1 Raise(1001) → REJECTED |

#### TC-10: FL 레이즈 Cap 도달

| 항목 | 값 |
|------|:--|
| **Setup** | 3인, FL, low_limit=100, raise_cap=4 |
| **Actions** | P0 Bet(100), P1 Raise(200), P2 Raise(300), P0 Raise(400) — 4번째 레이즈 |
| **기대 결과** | P1 Raise 시도 → REJECTED ("Cap reached"), P1은 Call/Fold만 가능 |

---

### 카테고리 3: 블라인드 — 7종 Ante 유형별 수집

#### TC-11: 기본 SB/BB (Ante 없음)

| 항목 | 값 |
|------|:--|
| **Setup** | 6인, SB=50, BB=100, Ante=0 |
| **기대 결과** | SETUP_HAND 진입 시: P1(SB) 스택 -50, P2(BB) 스택 -100, pot=150 |

#### TC-12: SB/BB + Big Blind Ante (BBA)

| 항목 | 값 |
|------|:--|
| **Setup** | 6인, SB=50, BB=100, BBA=100 (BB가 Ante도 납부) |
| **기대 결과** | P1(SB) -50, P2(BB) -200, pot=250. BB check option: biggest_bet = 100 (BBA는 Dead money) |

#### TC-13: Straddle 포함 블라인드

| 항목 | 값 |
|------|:--|
| **Setup** | 6인, SB=50, BB=100, Straddle=200 (UTG) |
| **기대 결과** | P1(SB) -50, P2(BB) -100, P3(UTG/Straddle) -200, pot=350. 액션 순서: P4 → P5 → P0 → P1 → P2 → P3 (Straddle가 마지막) |

---

### 카테고리 4: 사이드 팟 분배

#### TC-14: 2개 사이드 팟 — 3인 All-In

| 항목 | 값 |
|------|:--|
| **Players** | P0(stack=1000), P1(stack=3000), P2(stack=5000) |
| **Actions** | P0 All-In(1000), P1 All-In(3000), P2 Call(3000) |
| **Board** | `As Kd Qc Jh Ts` |
| **Hole Cards** | P0: `Ah Ad` (Pair of Aces), P1: `Ks Kh` (Pair of Kings), P2: `7c 2d` (High card) |
| **기대 결과** | Main Pot=3000 → P0 승. Side Pot 1=4000 → P1 승. P2 나머지 2000 반환 |

#### TC-15: 동일 핸드 — 팟 균등 분할 (Chop)

| 항목 | 값 |
|------|:--|
| **Players** | P0(stack=2000), P1(stack=2000) |
| **Actions** | 전원 All-In |
| **Board** | `As Kd Qc Jh Ts` (Board Straight) |
| **Hole Cards** | P0: `2c 3c`, P1: `4d 5d` (둘 다 Board Straight) |
| **기대 결과** | Pot=4000 → 균등 분할 P0=2000, P1=2000 |

#### TC-16: 3개 사이드 팟 — 4인 All-In

| 항목 | 값 |
|------|:--|
| **Players** | P0(500), P1(1500), P2(3000), P3(5000) |
| **Actions** | 전원 All-In |
| **Board** | `Td 9h 5c 2s Kd` |
| **Hole Cards** | P0: `Kh Ks`, P1: `Qd Qc`, P2: `Jd Js`, P3: `8c 7c` |
| **기대 결과** | Main(2000)→P0. Side1(3000)→P1. Side2(3000)→P2. P3 나머지 2000 반환 |

---

### 카테고리 5: 핸드 평가

#### TC-17: Royal Flush 승리

| 항목 | 값 |
|------|:--|
| **Hole Cards** | P0: `As Ks`, P1: `Qd Qc` |
| **Board** | `Qs Js Ts 5h 2d` |
| **기대 결과** | P0 = Royal Flush (A-K-Q-J-T Spades), P1 = Three Queens. winner = P0 |

#### TC-18: Full House vs Full House — Kicker 비교

| 항목 | 값 |
|------|:--|
| **Hole Cards** | P0: `Kh Kd`, P1: `Qh Qd` |
| **Board** | `Kc Qs 7c 7h 2d` |
| **기대 결과** | P0 = Full House (K-K-K-7-7), P1 = Full House (Q-Q-Q-7-7). winner = P0 |

#### TC-19: Straight vs Flush — Flush 승리

| 항목 | 값 |
|------|:--|
| **Hole Cards** | P0: `9h 8h`, P1: `Jd Td` |
| **Board** | `7h 6h 5d Kh 2c` |
| **기대 결과** | P0 = Flush (K-9-8-7-6 Hearts), P1 = Straight (J-T-9-8-7, 아니요 — 8이 없음). 재확인: P1 = J-high. winner = P0 |

#### TC-20: Two Pair vs Two Pair — 5번째 카드(Kicker) 결정

| 항목 | 값 |
|------|:--|
| **Hole Cards** | P0: `Ah 9c`, P1: `As 8d` |
| **Board** | `Kd 9h 8c 5s 2d` |
| **기대 결과** | P0 = Two Pair (A-A, 9-9, K kicker — 아니요: A-9-9-K), 재확인: P0 = A-9 pair with K kicker, P1 = A-8 pair with K kicker. P0 = (9s > 8s). winner = P0 |

#### TC-21: Hi-Lo Split (Omaha Hi-Lo 시 참조용)

| 항목 | 값 |
|------|:--|
| **Hole Cards** | P0: `As 2d`, P1: `Kh Kd` |
| **Board** | `3c 4h 5s Jd 9c` |
| **기대 결과** | Hi: P1 (Pair of Kings). Lo: P0 (5-4-3-2-A wheel). Pot 50/50 분할 |

---

### 카테고리 6: All Fold — 전원 폴드 → 우승자

#### TC-22: PRE_FLOP All Fold (BB 승리)

| 항목 | 값 |
|------|:--|
| **Setup** | 6인, BB=100. PRE_FLOP: UTG~BTN 전원 Fold, SB Fold |
| **기대 결과** | winner = BB (마지막 생존자), pot = 150 (SB+BB), game_phase → HAND_COMPLETE 직행. Showdown 없음, 카드 미공개 |

#### TC-23: FLOP All Fold (Bet 후 전원 폴드)

| 항목 | 값 |
|------|:--|
| **Setup** | 3인, pot=300 (PRE_FLOP 후). FLOP: P0 Bet(500), P1 Fold, P2 Fold |
| **기대 결과** | winner = P0, pot = 800, game_phase → HAND_COMPLETE 직행 |

---

### 카테고리 7: Bomb Pot

#### TC-24: Bomb Pot — PRE_FLOP 스킵

| 항목 | 값 |
|------|:--|
| **Setup** | 6인, bomb_pot_amount=500, stack=10000 각각 |
| **기대 결과** | SETUP_HAND: 전원 -500, pot=3000. PRE_FLOP 스킵. game_phase → FLOP 직행. 이후 정상 FLOP 베팅 |

#### TC-25: Bomb Pot — Short Stack 처리

| 항목 | 값 |
|------|:--|
| **Setup** | 6인, bomb_pot_amount=500, P3(stack=200) |
| **기대 결과** | P3은 200만 납부 (short contribution), 나머지 5명 500 납부. pot=2700. P3 기여분으로 side pot 분리 가능 |

---

### 카테고리 8: Run It Twice

#### TC-26: Run It Twice — 2회 보드 전개

| 항목 | 값 |
|------|:--|
| **Setup** | 2인 All-In at FLOP. Board = `Kd 7h 3c`. run_it_times=2 |
| **Hole Cards** | P0: `As Ad`, P1: `Ks Qs` |
| **Run 1 Board** | `Kd 7h 3c 2s 5d` → P0 승 (Pair of Aces) |
| **Run 2 Board** | `Kd 7h 3c Kh Qd` → P1 승 (Three Kings) |
| **기대 결과** | Pot 50/50 분할. game_phase: SHOWDOWN → RUN_IT_MULTIPLE → HAND_COMPLETE |

#### TC-27: Run It Twice — 동일 승자

| 항목 | 값 |
|------|:--|
| **Setup** | 2인 All-In at FLOP. run_it_times=2 |
| **Hole Cards** | P0: `As Ah`, P1: `2d 3c` |
| **Run 1, 2 Board** | 둘 다 P0 승 |
| **기대 결과** | P0가 전체 Pot 수령 (50% + 50% = 100%) |

---

### 카테고리 9: Undo

#### TC-28: Undo 1단계 — 마지막 액션 되돌리기

| 항목 | 값 |
|------|:--|
| **Setup** | PRE_FLOP, P1 Bet(200), P2 Call(200), P3 Raise(500) |
| **Action** | UNDO |
| **기대 결과** | P3 Raise 되돌림. P3 스택 +500 복원. action_on = P3. biggest_bet_amt = 200 |

#### TC-29: Undo 5단계 최대 + 6번째 거부

| 항목 | 값 |
|------|:--|
| **Setup** | 5개 액션 진행 후 |
| **Action** | UNDO × 5 → 성공, UNDO × 6 → REJECTED |
| **기대 결과** | 5번째까지 정상 복원. 6번째 시도 시 "Undo limit reached" 에러 |

---

### 카테고리 10: Edge Cases

#### TC-30: Heads-Up — 딜러/SB 동일

| 항목 | 값 |
|------|:--|
| **Setup** | 2인 (P0=Dealer/SB, P1=BB), BB=100, SB=50 |
| **기대 결과** | P0(SB) 먼저 액션 (PRE_FLOP). FLOP부터 P1(BB) 먼저 액션. Heads-up 레이즈 cap 미적용 |

#### TC-31: Straddle — 액션 순서 변경

| 항목 | 값 |
|------|:--|
| **Setup** | 6인, SB=P1, BB=P2, Straddle=P3(200) |
| **기대 결과** | PRE_FLOP 액션 순서: P4 → P5 → P0 → P1 → P2 → P3. P3(Straddle)가 마지막 액션, Check option 활성 |

#### TC-32: 칩 합의 (Chop Agreement) — ConfirmChop

| 항목 | 값 |
|------|:--|
| **Setup** | SHOWDOWN 직전, 2인 All-In, 운영자가 ConfirmChop 선택 |
| **Actions** | ConfirmChop(P0=6000, P1=4000) |
| **기대 결과** | Pot 분배: P0=6000, P1=4000 (합의 금액). 핸드 평가 미실행. game_phase → HAND_COMPLETE |

---

### 비활성 조건

- 물리 RFID 카드 감지: 테스트 범위 외 (Mock injectCard만)
- Omaha, Stud, Razz 전용 테스트: 이 문서 범위 외 (별도 문서 필요)

---

### 영향 받는 요소

| 요소 | 관계 |
|------|------|
| TEST-01 Test Plan | Unit 테스트 70% 계층의 구체적 케이스 |
| TEST-04 Mock Data | 테스트 입력값의 Mock 데이터 참조 |
| BS-06-01 Lifecycle | HandFSM 상태 전이 검증 기준 |
| BS-06-02 Betting | 베팅 유효성/금액 계산 검증 기준 |

---

# §4 — TEST-04-mock-data


| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | WSOP LIVE, RFID, Player, Config Mock 데이터 정의 |

---

### 개요

테스트에서 사용하는 모든 Mock 데이터의 구조와 샘플을 정의한다. 실제 외부 서비스(WSOP LIVE API, RFID 하드웨어)를 대체하며, 결정론적 테스트 재현을 보장한다.

> 참조: Mock 모드 — BS-00 §9, RFID HAL — API-03 §6, 시나리오 스크립트 — BS-06-00 §4.3

---

### 1. Mock WSOP LIVE 응답 — JSON Fixtures

#### 1.1 Competition

```json
{
  "competition_id": "COMP-001",
  "name": "WSOP",
  "year": 2026,
  "status": "active"
}
```

#### 1.2 Series

```json
{
  "series_id": "SER-2026-001",
  "competition_id": "COMP-001",
  "name": "2026 World Series of Poker",
  "start_date": "2026-05-27",
  "end_date": "2026-07-16",
  "venue": "Las Vegas Convention Center",
  "status": "active"
}
```

#### 1.3 Event

```json
{
  "event_id": "EVT-001",
  "series_id": "SER-2026-001",
  "event_number": 1,
  "name": "Event #1: $10,000 No-Limit Hold'em",
  "game_type": "NL_HOLDEM",
  "buy_in": 10000,
  "start_date": "2026-05-27",
  "status": "running",
  "total_entries": 1200
}
```

#### 1.4 Flight

```json
{
  "flight_id": "FLT-001",
  "event_id": "EVT-001",
  "name": "Day 1A",
  "start_time": "2026-05-27T12:00:00Z",
  "status": "running",
  "tables_count": 120,
  "players_remaining": 800
}
```

#### 1.5 Player (단일)

```json
{
  "player_id": "PLR-001",
  "first_name": "John",
  "last_name": "Doe",
  "nationality": "US",
  "city": "Las Vegas",
  "profile_image_url": null,
  "wsop_bracelets": 3,
  "total_earnings": 5000000
}
```

#### 1.6 BlindStructure

```json
{
  "structure_id": "BS-NL-001",
  "name": "NL Hold'em Standard",
  "levels": [
    { "level": 1, "sb": 50, "bb": 100, "ante": 0, "duration_min": 60 },
    { "level": 2, "sb": 100, "bb": 200, "ante": 0, "duration_min": 60 },
    { "level": 3, "sb": 150, "bb": 300, "ante": 50, "duration_min": 60 },
    { "level": 4, "sb": 200, "bb": 400, "ante": 50, "duration_min": 60 },
    { "level": 5, "sb": 300, "bb": 600, "ante": 100, "duration_min": 60 }
  ]
}
```

---

### 2. Mock RFID 이벤트 스트림 — YAML 시나리오

#### 2.1 Basic: 정상 핸드 (2인 Heads-Up)

```yaml
scenario: "basic-headsup"
description: "2인 Heads-Up, Pre-Flop → Showdown 정상 진행"
game_type: NL_HOLDEM
players:
  - { seat: 0, name: "P0", stack: 10000 }
  - { seat: 1, name: "P1", stack: 10000 }
blind: { sb: 50, bb: 100 }

events:
  - type: DeckRegistered
    delay_ms: 0

  # P0 홀카드
  - type: CardDetected
    delay_ms: 100
    payload: { antenna_id: 0, suit: 0, rank: 12 }  # As
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 0, suit: 1, rank: 12 }  # Ah

  # P1 홀카드
  - type: CardDetected
    delay_ms: 100
    payload: { antenna_id: 2, suit: 0, rank: 11 }  # Ks
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 2, suit: 1, rank: 11 }  # Kh

  # Flop
  - type: CardDetected
    delay_ms: 500
    payload: { antenna_id: 20, suit: 2, rank: 10 }  # Qd
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 21, suit: 3, rank: 5 }   # 7c
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 22, suit: 2, rank: 1 }   # 3d

  # Turn
  - type: CardDetected
    delay_ms: 300
    payload: { antenna_id: 23, suit: 0, rank: 8 }   # Ts

  # River
  - type: CardDetected
    delay_ms: 300
    payload: { antenna_id: 23, suit: 3, rank: 0 }   # 2c
```

#### 2.2 Side Pot: 3인 All-In (스택 차이)

```yaml
scenario: "side-pot-three-players"
description: "3인 All-In, 스택 차이로 Side Pot 2개 생성"
game_type: NL_HOLDEM
players:
  - { seat: 0, name: "P0", stack: 1000 }
  - { seat: 1, name: "P1", stack: 3000 }
  - { seat: 2, name: "P2", stack: 5000 }
blind: { sb: 50, bb: 100 }

events:
  - type: DeckRegistered
    delay_ms: 0

  # P0 홀카드
  - type: CardDetected
    delay_ms: 100
    payload: { antenna_id: 0, suit: 0, rank: 12 }  # As
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 0, suit: 2, rank: 12 }  # Ad

  # P1 홀카드
  - type: CardDetected
    delay_ms: 100
    payload: { antenna_id: 2, suit: 1, rank: 11 }  # Kh
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 2, suit: 0, rank: 11 }  # Ks

  # P2 홀카드
  - type: CardDetected
    delay_ms: 100
    payload: { antenna_id: 4, suit: 1, rank: 10 }  # Qh
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 4, suit: 2, rank: 10 }  # Qd

  # Board 5장 (All-In Runout)
  - type: CardDetected
    delay_ms: 500
    payload: { antenna_id: 20, suit: 3, rank: 5 }   # 7c
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 21, suit: 2, rank: 3 }   # 5d
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 22, suit: 1, rank: 1 }   # 3h
  - type: CardDetected
    delay_ms: 300
    payload: { antenna_id: 23, suit: 0, rank: 7 }   # 9s
  - type: CardDetected
    delay_ms: 300
    payload: { antenna_id: 23, suit: 3, rank: 0 }   # 2c
```

#### 2.3 All-In at Flop: 2인 All-In + Run It Twice

```yaml
scenario: "all-in-run-it-twice"
description: "2인 Flop All-In, Run It Twice 진행"
game_type: NL_HOLDEM
players:
  - { seat: 0, name: "P0", stack: 5000 }
  - { seat: 1, name: "P1", stack: 5000 }
blind: { sb: 50, bb: 100 }
run_it_times: 2

events:
  - type: DeckRegistered
    delay_ms: 0

  # P0 홀카드
  - type: CardDetected
    delay_ms: 100
    payload: { antenna_id: 0, suit: 0, rank: 12 }  # As
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 0, suit: 1, rank: 12 }  # Ah

  # P1 홀카드
  - type: CardDetected
    delay_ms: 100
    payload: { antenna_id: 2, suit: 0, rank: 11 }  # Ks
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 2, suit: 1, rank: 11 }  # Kh

  # Flop
  - type: CardDetected
    delay_ms: 500
    payload: { antenna_id: 20, suit: 2, rank: 11 }  # Kd
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 21, suit: 3, rank: 5 }   # 7c
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 22, suit: 2, rank: 1 }   # 3d

  # Run 1: Turn + River
  - type: CardDetected
    delay_ms: 300
    payload: { antenna_id: 23, suit: 0, rank: 0 }   # 2s
  - type: CardDetected
    delay_ms: 300
    payload: { antenna_id: 23, suit: 3, rank: 4 }   # 6c

  # Run 2: Turn + River
  - type: CardDetected
    delay_ms: 300
    payload: { antenna_id: 23, suit: 0, rank: 10 }  # Qs
  - type: CardDetected
    delay_ms: 300
    payload: { antenna_id: 23, suit: 1, rank: 8 }   # Th
```

---

### 3. Mock Player DB — 10명 샘플

| player_id | first_name | last_name | nationality | stack | wsop_bracelets |
|-----------|-----------|-----------|:-----------:|:-----:|:--------------:|
| PLR-001 | John | Doe | US | 10000 | 3 |
| PLR-002 | Jane | Smith | UK | 10000 | 1 |
| PLR-003 | Hiroshi | Tanaka | JP | 10000 | 0 |
| PLR-004 | Maria | Garcia | ES | 10000 | 2 |
| PLR-005 | Wei | Chen | CN | 10000 | 0 |
| PLR-006 | Pierre | Dubois | FR | 10000 | 1 |
| PLR-007 | Alex | Mueller | DE | 10000 | 0 |
| PLR-008 | Seo-Yun | Kim | KR | 10000 | 0 |
| PLR-009 | Lucas | Silva | BR | 10000 | 1 |
| PLR-010 | Emma | Johnson | CA | 10000 | 4 |

```json
[
  { "player_id": "PLR-001", "first_name": "John", "last_name": "Doe", "nationality": "US", "city": "Las Vegas", "wsop_bracelets": 3, "total_earnings": 5000000 },
  { "player_id": "PLR-002", "first_name": "Jane", "last_name": "Smith", "nationality": "UK", "city": "London", "wsop_bracelets": 1, "total_earnings": 1200000 },
  { "player_id": "PLR-003", "first_name": "Hiroshi", "last_name": "Tanaka", "nationality": "JP", "city": "Tokyo", "wsop_bracelets": 0, "total_earnings": 300000 },
  { "player_id": "PLR-004", "first_name": "Maria", "last_name": "Garcia", "nationality": "ES", "city": "Madrid", "wsop_bracelets": 2, "total_earnings": 2800000 },
  { "player_id": "PLR-005", "first_name": "Wei", "last_name": "Chen", "nationality": "CN", "city": "Beijing", "wsop_bracelets": 0, "total_earnings": 150000 },
  { "player_id": "PLR-006", "first_name": "Pierre", "last_name": "Dubois", "nationality": "FR", "city": "Paris", "wsop_bracelets": 1, "total_earnings": 900000 },
  { "player_id": "PLR-007", "first_name": "Alex", "last_name": "Mueller", "nationality": "DE", "city": "Berlin", "wsop_bracelets": 0, "total_earnings": 450000 },
  { "player_id": "PLR-008", "first_name": "Seo-Yun", "last_name": "Kim", "nationality": "KR", "city": "Seoul", "wsop_bracelets": 0, "total_earnings": 200000 },
  { "player_id": "PLR-009", "first_name": "Lucas", "last_name": "Silva", "nationality": "BR", "city": "Sao Paulo", "wsop_bracelets": 1, "total_earnings": 750000 },
  { "player_id": "PLR-010", "first_name": "Emma", "last_name": "Johnson", "nationality": "CA", "city": "Toronto", "wsop_bracelets": 4, "total_earnings": 8000000 }
]
```

---

### 4. Mock Config — 기본 Settings 프리셋

#### 4.1 Output 프리셋

```json
{
  "output_preset_id": "OUT-DEFAULT",
  "name": "Default 1080p NDI",
  "resolution": { "width": 1920, "height": 1080 },
  "output_type": "NDI",
  "security_delay_sec": 10,
  "chroma_key": false,
  "fps": 60
}
```

#### 4.2 Overlay 프리셋

```json
{
  "overlay_preset_id": "OVL-DEFAULT",
  "name": "WSOP Standard",
  "skin_id": "SKIN-WSOP-2026",
  "card_style": "four_color",
  "show_equity": true,
  "show_pot_odds": false,
  "animation_speed_ms": 300
}
```

#### 4.3 Game 프리셋

```json
{
  "game_preset_id": "GAME-NL-HOLDEM",
  "name": "NL Hold'em Standard",
  "game_type": "NL_HOLDEM",
  "bet_structure": "NL",
  "blind_structure_id": "BS-NL-001",
  "current_level": 1,
  "ante_type": "none",
  "bomb_pot_enabled": false,
  "straddle_allowed": false,
  "run_it_twice_allowed": true,
  "max_seats": 10
}
```

#### 4.4 Statistics 프리셋

```json
{
  "stats_preset_id": "STAT-DEFAULT",
  "name": "Standard Display",
  "show_vpip": true,
  "show_pfr": true,
  "show_wtsd": true,
  "show_aggression": true,
  "show_hands_played": true,
  "show_win_rate": false
}
```

#### 4.5 System Config (BO 글로벌)

```json
{
  "config_id": "SYS-DEFAULT",
  "rfid_mode": "mock",
  "log_level": "info",
  "auto_save_interval_sec": 30,
  "websocket_heartbeat_sec": 15,
  "max_undo_depth": 5,
  "hand_history_retention_days": 365
}
```

---

### 비활성 조건

- Real RFID 하드웨어 데이터: 항상 비활성 (Mock 데이터만)
- 외부 WSOP LIVE API 호출: 항상 비활성 (JSON fixture만)

---

### 영향 받는 요소

| 요소 | 관계 |
|------|------|
| TEST-01 Test Plan | Mock 전략의 데이터 상세 |
| TEST-02 E2E Scenarios | 시나리오에서 참조하는 Mock 데이터 |
| TEST-03 Game Engine Fixtures | 테스트 입력값의 데이터 소스 |
| BS-06-00 Triggers §4.3 | YAML 시나리오 형식 정의 |
| API-03 RFID HAL §6.4 | 시나리오 파일 형식 참조 |

---

# §5 — TEST-05-qa-checklist


| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 소프트웨어 수동 QA 체크리스트 56항목 (7개 카테고리) |

---

### 개요

EBS 소프트웨어 수동 QA 체크리스트. **물리 하드웨어 테스트는 제외** — 모든 RFID 항목은 MockRfidReader로만 검증한다.

> 참조: Mock 모드 — BS-00 §9, RFID HAL — API-03, E2E 시나리오 — TEST-02

#### 사용 방법

각 항목의 Pass/Fail을 기록한다. Fail 항목은 이슈 트래커에 등록한다.

---

### 1. Auth (5항목)

| # | 테스트 항목 | 테스트 조건 | 기대 결과 | Pass/Fail |
|:-:|-----------|-----------|----------|:---------:|
| A-01 | Admin 로그인 성공 | 유효한 Admin 계정으로 Lobby 로그인 | JWT 발급, Lobby 메인 화면 진입, 모든 메뉴 접근 가능 | |
| A-02 | Operator 로그인 + 권한 제한 | Operator 계정으로 로그인 | 할당된 테이블만 표시, Settings 수정 불가 | |
| A-03 | 잘못된 비밀번호 | 유효 계정 + 잘못된 비밀번호 | 로그인 실패, "Invalid credentials" 에러 표시 | |
| A-04 | 세션 만료 | JWT 만료 후 API 호출 | 401 응답, 로그인 페이지로 리다이렉트 | |
| A-05 | Viewer 읽기 전용 | Viewer 계정으로 로그인 | 모든 데이터 조회 가능, 생성/수정/삭제 불가 | |

---

### 2. Lobby (10항목)

| # | 테스트 항목 | 테스트 조건 | 기대 결과 | Pass/Fail |
|:-:|-----------|-----------|----------|:---------:|
| L-01 | Series 생성 | 이름, 기간 입력 후 생성 | Series 목록에 표시, DB 저장 확인 | |
| L-02 | Event 생성 | Series 하위에 Event 생성 | 계층 구조 정상, game_type 설정 | |
| L-03 | Flight 생성 | Event 하위에 Flight 생성 | 시작 시간, 상태 설정 정상 | |
| L-04 | Table 생성 + Flight 할당 | Table 생성 후 Flight에 할당 | Table 상태 = EMPTY, Flight 하위 표시 | |
| L-05 | Player 등록 (수동) | 이름, 국적 입력 후 등록 | Player DB 저장, 검색 가능 | |
| L-06 | 좌석 배치 (SeatAssign) | Player를 특정 Seat에 배치 | Seat 상태 = OCCUPIED, Table 상태 → SETUP | |
| L-07 | 좌석 이동 (SeatMove) | Player를 다른 Seat으로 이동 | 원래 Seat = VACANT, 새 Seat = OCCUPIED | |
| L-08 | 중복 좌석 배치 거부 | 이미 OCCUPIED인 Seat에 다른 Player 배치 | 에러 표시, 배치 거부 | |
| L-09 | 필수 필드 유효성 | Event 생성 시 이름 미입력 | 유효성 에러 표시, 저장 거부 | |
| L-10 | 테이블 모니터링 대시보드 | CC 연결 후 Lobby 대시보드 확인 | 테이블 상태(LIVE), 현재 핸드 번호, RFID 상태 실시간 갱신 | |

---

### 3. Command Center (15항목)

| # | 테스트 항목 | 테스트 조건 | 기대 결과 | Pass/Fail |
|:-:|-----------|-----------|----------|:---------:|
| C-01 | CC Launch + WebSocket 연결 | Lobby에서 CC Launch | CC 앱 실행, BO WebSocket 연결, `OperatorConnected` 이벤트 | |
| C-02 | NEW HAND 시작 | IDLE 상태 + precondition 충족 | HandFSM → SETUP_HAND, 블라인드 자동 수집 | |
| C-03 | NEW HAND 전제조건 미충족 | pl_dealer == -1 (딜러 미지정) | StartHand 거부, 에러 메시지 표시 | |
| C-04 | 홀카드 딜 (Mock 수동 입력) | Mock 모드에서 각 플레이어 카드 2장 입력 | CardDetected 이벤트 합성, HandFSM → PRE_FLOP | |
| C-05 | Fold 액션 | 활성 플레이어에서 FOLD 버튼 | player.status = folded, action_on 다음 이동 | |
| C-06 | Check 액션 (유효) | biggest_bet == current_bet 상태에서 CHECK | action_on 다음 이동, 베팅액 불변 | |
| C-07 | Check 액션 (거부) | biggest_bet > current_bet 상태에서 CHECK | "베팅이 있습니다" 경고, 액션 거부 | |
| C-08 | Bet/Raise 금액 입력 | NL에서 금액 직접 입력 후 확인 | 금액 유효성 검증 통과, biggest_bet_amt 갱신 | |
| C-09 | 최소 레이즈 미달 거부 | NL에서 min_raise 미만 금액 입력 | "최소 레이즈 금액은 X" 에러, 재입력 요청 | |
| C-10 | All-In 처리 | 스택 전액 베팅 | player.status = allin, SidePotCreated (해당 시) | |
| C-11 | 보드 카드 입력 (Flop 3장) | Mock 모드에서 보드 카드 3장 입력 | CardDetected × 3, board_cards = 3, HandFSM → FLOP | |
| C-12 | UNDO 1단계 | 마지막 액션 후 UNDO | 이전 상태 복원, action_on/biggest_bet 복원 | |
| C-13 | UNDO 6단계 거부 | 5단계 UNDO 후 추가 시도 | "Undo limit reached" 에러 | |
| C-14 | Miss Deal | 핸드 중 Miss Deal 선언 | HandFSM → IDLE, 스택 복구, 팟 반환 | |
| C-15 | Bomb Pot 모드 | Bomb Pot 설정 후 NEW HAND | 전원 고정액 납부, PRE_FLOP 스킵, FLOP 직행 | |

---

### 4. Settings (8항목)

| # | 테스트 항목 | 테스트 조건 | 기대 결과 | Pass/Fail |
|:-:|-----------|-----------|----------|:---------:|
| S-01 | Output 설정 저장 | NDI, 1080p, Security Delay 10초 | OutputPreset DB 저장 확인 | |
| S-02 | Overlay 설정 변경 | Skin 변경, card_style 변경 | `ConfigChanged` WebSocket 이벤트 발행, CC 반영 | |
| S-03 | Game 설정 변경 | NL Hold'em → PL Omaha 변경 | bet_structure, game_type 변경 적용 | |
| S-04 | BlindStructure 레벨 변경 | 레벨 1 → 레벨 2 수동 변경 | `BlindStructureChanged` 이벤트, CC에 새 SB/BB 표시 | |
| S-05 | Statistics 옵션 ON/OFF | VPIP 표시 OFF | Overlay에서 VPIP 숨김 | |
| S-06 | 잘못된 값 거부 | BB=0 또는 해상도 0×0 입력 | 유효성 에러 표시, 저장 거부 | |
| S-07 | 설정 프리셋 저장/로드 | 현재 설정을 프리셋으로 저장 후 다른 설정 적용 후 프리셋 로드 | 원래 설정 복원 | |
| S-08 | 핸드 중 설정 변경 지연 | 핸드 진행 중 Config 변경 | 핸드 완료 후 적용 (즉시 적용 안 됨) | |

---

### 5. Overlay (8항목)

| # | 테스트 항목 | 테스트 조건 | 기대 결과 | Pass/Fail |
|:-:|-----------|-----------|----------|:---------:|
| O-01 | 홀카드 표시 | 홀카드 딜 후 Overlay 확인 | 각 플레이어 위치에 2장 카드 표시 | |
| O-02 | 보드 카드 표시 | Flop/Turn/River 공개 | 보드 영역에 카드 순차 표시 | |
| O-03 | 팟 금액 표시 | 베팅 발생 시 | 팟 금액 실시간 갱신 | |
| O-04 | 플레이어 스택 표시 | 베팅/승리 후 | 스택 금액 실시간 갱신 | |
| O-05 | Equity 표시 | 홀카드 공개 후 | 각 플레이어 승률(%) 표시 | |
| O-06 | 폴드 플레이어 표시 | FOLD 액션 후 | 해당 플레이어 카드 회색 처리 또는 숨김 | |
| O-07 | 승자 하이라이트 | HAND_COMPLETE 진입 | 승자 플레이어 + 승리 핸드 하이라이트 | |
| O-08 | Security Delay 적용 | Security Delay=10초 설정 | Overlay 출력이 실제 게임보다 10초 지연 | |

---

### 6. RFID Mock (5항목)

| # | 테스트 항목 | 테스트 조건 | 기대 결과 | Pass/Fail |
|:-:|-----------|-----------|----------|:---------:|
| R-01 | MockRfidReader 초기화 | CC 시작 시 Mock 모드 | status = ready, AntennaStatusChanged(connected) | |
| R-02 | 자동 덱 등록 | "자동 등록" 버튼 클릭 | 52장 매핑 즉시 완료, DeckRegistered 이벤트 | |
| R-03 | 수동 카드 입력 → CardDetected | CC에서 suit/rank 선택 후 카드 입력 | CardDetected 이벤트 합성, uid="MOCK-{suit}{rank}", confidence=1.0 | |
| R-04 | 에러 주입 (테스트용) | injectError(connectionLost) 호출 | ReaderError 이벤트 발행, CC에 에러 표시 | |
| R-05 | YAML 시나리오 재생 | loadScenario("basic-headsup.yaml") | 사전 정의된 이벤트 순서대로 발행, 결정적 타이밍 |  |

---

### 7. Data Sync (5항목)

| # | 테스트 항목 | 테스트 조건 | 기대 결과 | Pass/Fail |
|:-:|-----------|-----------|----------|:---------:|
| D-01 | CC → BO 핸드 기록 동기화 | 핸드 완료 후 | HandStarted/HandEnded 이벤트 → BO DB에 Hand History 저장 | |
| D-02 | Lobby → BO → CC 설정 전달 | Lobby에서 Settings 변경 | ConfigChanged 이벤트 → CC에서 새 설정 적용 | |
| D-03 | 플레이어 정보 동기화 | Lobby에서 Player 이름 수정 | PlayerUpdated 이벤트 → CC 표시 갱신, Overlay 갱신 | |
| D-04 | WebSocket 재연결 | CC WebSocket 끊김 후 재연결 | OperatorDisconnected → 자동 재연결 시도 → OperatorConnected | |
| D-05 | 통계 업데이트 동기화 | 핸드 종료 후 | StatisticsUpdated → Lobby에서 플레이어 통계 조회 시 최신값 반영 | |

---

### 합계

| 카테고리 | 항목 수 |
|---------|:------:|
| Auth | 5 |
| Lobby | 10 |
| Command Center | 15 |
| Settings | 8 |
| Overlay | 8 |
| RFID Mock | 5 |
| Data Sync | 5 |
| **합계** | **56** |

---

### 비활성 조건

- 물리 RFID 하드웨어 테스트: 항상 비활성 (6. RFID Mock 카테고리는 소프트웨어 Mock만)
- 네트워크 인프라 테스트: 범위 외
- 성능/부하 테스트: 범위 외 (별도 계획 필요)

---

### 영향 받는 요소

| 요소 | 관계 |
|------|------|
| TEST-01 Test Plan | 수동 QA로 자동화 테스트 보완 |
| TEST-02 E2E Scenarios | E2E 시나리오의 수동 검증 버전 |
| BS-00 Definitions | 상태값, FSM 정의 기준 |
| BS-06-00 Triggers | 트리거 경계, Mock 합성 규칙 |
| API-03 RFID HAL | MockRfidReader 테스트 기준 |

---

# §6 — TEST-06-app-test-audit


| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Lobby, CC, Graphic Editor 테스트 품질 감사 |

---

> **Note (docs v10)**: 과거 `docs/qa/{lobby,commandcenter,graphic-editor}/QA-*-00-audit.md` 로 분리되어 있던 앱별 감사 문서는 v10 이주에서 폐지되었다. 현재는 각 팀의 `Integration_Test_Plan.md` 가 해당 앱의 QA 단일 진입점이다.

### 개요

3개 앱(Lobby, Command Center, Graphic Editor)의 기존 테스트를 감사하여 **실제 검증 수준**을 평가한다. "PASS" 여부가 아니라 "무엇을 검증하는가"를 기준으로 분석한다.

> 게임 엔진 QA는 별도 범위이므로 이 문서에서 제외한다.

---

### 감사 요약

| 앱 | 프레임워크 | 레포 | 테스트 수 | 품질 점수 | 핵심 문제 |
|---|-----------|------|:--------:|:--------:|----------|
| **Lobby** | Flutter Web | `/ebs_lobby_web/` | 7 widget | **2/10** | unit 0건, 로직 검증 0건 |
| **Command Center** | Flutter Desktop | `/ebs_app/` | 10 unit/widget | **3/10** | debugSetState로 실제 경로 우회 |
| **Graphic Editor** | Vue3+Quasar | `/ebs_ui/ebs-skin-editor/` | 16 spec | **3/10** | mount+text만, interaction 0건 |

#### 공통 안티패턴

| 안티패턴 | 설명 | 해당 앱 |
|---------|------|---------|
| **렌더 테스트 함정** | 컴포넌트 마운트 + 텍스트 존재 확인만 | 3개 전부 |
| **로직 미검증** | 비즈니스 로직(필터링, 상태전환, 계산)이 assert 대상이 아님 | 3개 전부 |
| **E2E 0건** | 사용자 워크플로우 재현 테스트 없음 | 3개 전부 |
| **에러 경로 미테스트** | API 실패, 네트워크 오류, 유효성 검증 실패 등 | 3개 전부 |
| **CI/CD 없음** | PR/push 시 자동 테스트 미실행 | 3개 전부 |

---

### 1. Lobby (`/ebs_lobby_web/`)

#### 테스트 파일 목록

| 파일 | 테스트 수 | 검증 내용 |
|------|:--------:|----------|
| `breadcrumb_test.dart` | 2 | 텍스트 렌더링만. 네비게이션 클릭 미테스트 |
| `cc_lock_test.dart` | 1 | 아이콘 존재만 (`findsWidgets`). 상태별 분기 미테스트 |
| `event_list_test.dart` | 1 | 탭 이름 렌더링만. 필터링 로직 미테스트 |
| `series_screen_test.dart` | 1 | 시리즈 카드 텍스트만. 검색/월별 그룹핑 미테스트 |
| `session_restore_test.dart` | 2 | 다이얼로그 텍스트만. 버튼 클릭 콜백 미테스트 |
| `table_management_test.dart` | 1 | 아이콘 1개 확인만. 정렬/좌석/상태 전환 미테스트 |
| `widget_test.dart` | 1 | 로그인 폼 필드 존재만. 로그인 플로우 미테스트 |

#### CRITICAL 미테스트 영역

| 영역 | 소스 위치 | 위험도 |
|------|----------|:------:|
| **세션 계층 clearing** | `session_service.dart` `clearBelow()` | CRITICAL |
| **이벤트 상태 필터링** | `event_list_screen.dart` `_filtered()` | CRITICAL |
| **테이블 정렬** (Feature 우선) | `table_management_screen.dart` `_sortedTables` | HIGH |
| **로그인 → 세션 복원 플로우** | `login_screen.dart` lines 44-76 | CRITICAL |
| **API 에러 핸들링** (409 TransitionBlocked) | `api_client.dart` | CRITICAL |
| **JSON 파서** (null 처리, 타입 변환) | `json_parsers.dart` | HIGH |
| **좌석 렌더링** (색상 매핑) | `table_management_screen.dart` | MEDIUM |

#### Mock 인프라 문제

- `mock_api_client.dart` — 에러 시뮬레이션 불가, `assignSeat()` 빈 구현
- mockito/mocktail 미설치 — 고급 mock 패턴 사용 불가
- 비동기 에러 테스트 불가능

---

### 2. Command Center (`/ebs_app/`)

#### 테스트 파일 목록

| 파일 | 테스트 수 | 검증 내용 |
|------|:--------:|----------|
| `fake_rfid_reader_test.dart` | 3 | stream inject, deck 52장, playScenario. **품질 양호** |
| `game_session_test.dart` | 5 | 초기 상태(tautological), copyWith(tautological), RFID 중복제거, enterLive, advanceStreet |
| `widget_test.dart` | 2 | 로딩 텍스트, 서버 미연결 에러. **실제 서버 상태에 의존** |

#### 안티패턴 상세

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

#### CRITICAL 미테스트 영역

| 영역 | 소스 위치 | 위험도 |
|------|----------|:------:|
| **CcApiClient 전체** | `services/api_client.dart` (7개 메서드) | CRITICAL |
| **loadTable() 상태 전환** | `game_session_provider.dart` lines 40-71 | CRITICAL |
| **enterLive() API 호출** | `game_session_provider.dart` lines 85-105 | HIGH |
| **DeckRegistrationScreen** | `screens/deck_registration_screen.dart` | HIGH |
| **CommandCenterScreen** | `screens/command_center_screen.dart` | HIGH |
| **OverlayScreen** | `screens/overlay_screen.dart` | MEDIUM |
| **PlayingCard.shortLabel** | `models/card.dart` 52종 매핑 | MEDIUM |

#### 의존성 문제

- `pubspec.yaml`에 **mockito/mocktail 없음** — CcApiClient mock 불가
- 테스트 인프라 추가 필수: `mocktail` + `http_mock_adapter` 또는 유사

---

### 3. Graphic Editor (`/ebs_ui/ebs-skin-editor/`)

#### 테스트 파일 목록

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

#### 공통 패턴

```typescript
// 16개 파일 전부 이 패턴
it('renders XYZ section', () => {
  const wrapper = mountQ(Component);
  expect(wrapper.text()).toContain('Label Text');
});
```

#### CRITICAL 미테스트 영역

| 영역 | 위험도 |
|------|:------:|
| **사용자 interaction** (클릭, 드래그, 입력) | CRITICAL |
| **Pinia store 상태 변경** 후 UI 반영 | CRITICAL |
| **Canvas 렌더링 로직** | HIGH |
| **색상 변환 계산** (HUE, RGB) | HIGH |
| **Undo/Redo** 스택 | HIGH |
| **Import/Export** 기능 | MEDIUM |
| **키보드 단축키** | MEDIUM |

#### 긍정 요소

- **Playwright 1.58.2 설치됨** — E2E 인프라 준비 상태
- **Vitest 3.0.9 + @vue/test-utils** — 프레임워크 최신
- **mountQ 헬퍼** 공유 — Quasar+Pinia 설정 재사용

---

### 게임 엔진 시나리오 테스트 강화 (참고)

이 세션에서 수행한 게임 엔진 시나리오 테스트 강화는 앱 QA의 참고 사례로 기록한다.

#### 수행 내용

- `scenario_runner_test.dart`에 **칩 보존 invariant** 자동 검증 추가
- 15개 YAML 시나리오에 `stacks`, `pot_total`, `community_count`, `seat_statuses` assertions 추가
- **6개 시나리오의 `pot_awarded` 산술 오류 발견 및 수정**

#### 발견된 버그

| 시나리오 | 문제 | delta |
|---------|------|:-----:|
| 01 nlh-basic-showdown | award 320→305 | +15 |
| 06 shortdeck-flush | award 310→300 | +10 |
| 11 courchevel-preflop | award 80→100 | -20 |
| 13 heads-up-blinds | award 60→90 | -30 |
| 14 minraise-tracking | award 580→590 | -10 |
| 15 allin-less-than-call | award {75,70}→{75,50} | +20 |

#### 교훈

1. **Invariant 검증**이 가장 효과적 — 칩 보존 1줄로 6개 버그 포착
2. **"PASS" ≠ "검증됨"** — `expect(state, isNotNull)`은 검증이 아님
3. **Capture-then-verify** 패턴 — 엔진 산출값 캡처 → 수동 검증 → golden value 설정

> 이 패턴을 앱 테스트에도 적용할 것을 권장한다.

---

### 결론

3개 앱 모두 **"렌더 테스트 함정"** 상태이다. 컴포넌트가 크래시 없이 마운트되는지만 확인하며, 비즈니스 로직·상태 전환·에러 처리를 검증하지 않는다.

#### 다음 단계

- **TEST-07**: 앱별 QA 전략 및 구현 가이드
- 구현은 별도 세션에서 앱별로 진행

---

# §7 — TEST-07-app-qa-strategy


| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Lobby, CC, Graphic Editor QA 전략 + 구현 체크리스트 |

---

> **Note (docs v10)**: 과거 `docs/qa/{lobby,commandcenter,graphic-editor}/QA-*-01-strategy.md` 는 v10 이주에서 폐지. 현재 앱별 QA 전략은 각 팀 `Integration_Test_Plan.md` 의 해당 섹션으로 통합됨.

### 개요

각 앱별로 **구체적 테스트 항목**, **우선순위**, **구현 가이드**를 포함한다.

> 게임 엔진 QA는 별도 범위이므로 이 문서에서 제외한다.
> 물리 하드웨어(RFID 안테나, ST25R3911B, ESP32) 테스트는 제외한다 (BS-00 §9).

---

### 전략 원칙

#### 1. Invariant-First

게임 엔진 감사에서 **칩 보존 invariant 1줄이 6개 버그를 잡았다**. 앱 테스트에도 동일 원칙을 적용한다:

| 앱 | Invariant | 검증 방법 |
|---|----------|----------|
| **Lobby** | 세션 계층 일관성 | series 선택 시 event/flight/table 반드시 null |
| **CC** | 등록 카드 ≤ 52장 | registeredCards.length 항상 0~52 |
| **CC** | 커뮤니티 카드 ≤ 5장 | communityCards.length 항상 0~5 |
| **Graphic Editor** | Element 수 보존 | add/remove 후 elements.length 정합성 |

#### 2. 테스트 피라미드 (TEST-01 준수)

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

#### 3. 우선순위 기준

| 우선순위 | 기준 | 예시 |
|:-------:|------|------|
| **P0** | 데이터 무결성 / 상태 전환 오류 | 세션 clearing, phase transition |
| **P1** | 사용자 워크플로우 차단 | 로그인, 테이블 열기, 카드 등록 |
| **P2** | UI 정합성 | 정렬, 필터링, 색상 매핑 |
| **P3** | Edge case | 빈 목록, null 값, 네트워크 타임아웃 |

---

### Lobby QA 전략

#### 사전 작업

```bash
cd /c/claude/ebs_lobby_web
flutter pub add --dev mocktail   # mock 프레임워크 추가
```

#### Unit 테스트 (P0 — 최우선)

| # | 대상 | 파일 | 테스트 항목 | 우선순위 |
|---|------|------|-----------|:-------:|
| L-U01 | SessionService | `test/services/session_service_test.dart` | `clearBelow('series')` → event/flight/table null | P0 |
| L-U02 | SessionService | 상동 | `clearBelow('event')` → flight/table null, series 유지 | P0 |
| L-U03 | SessionService | 상동 | `saveContext()` → `restore()` 왕복 검증 | P0 |
| L-U04 | JSON Parsers | `test/services/json_parsers_test.dart` | null 필드 처리, 타입 변환, DateTime 파싱 | P1 |
| L-U05 | API Client | `test/services/api_client_test.dart` | 200 성공, 404 미발견, 409 TransitionBlocked, 5xx 에러 | P0 |
| L-U06 | Event Filtering | `test/logic/event_filter_test.dart` | 탭별 필터(All, Created, Running, Completed 등) | P1 |
| L-U07 | Table Sorting | `test/logic/table_sort_test.dart` | Feature 우선, 번호 순 정렬 | P2 |

#### Widget 테스트 (P1)

| # | 대상 | 테스트 항목 | 우선순위 |
|---|------|-----------|:-------:|
| L-W01 | LoginScreen | 이메일/비밀번호 입력 → 로그인 버튼 클릭 → provider 호출 | P1 |
| L-W02 | LoginScreen | 로그인 실패 → 에러 메시지 표시 | P1 |
| L-W03 | SessionRestoreDialog | "Continue" 클릭 → 콜백 호출 | P1 |
| L-W04 | EventListScreen | 탭 클릭 → 필터링된 목록 렌더링 | P1 |
| L-W05 | TableManagementScreen | Feature 테이블 상단, 좌석 색상 매핑 | P2 |
| L-W06 | Breadcrumb | 칩 클릭 → 해당 레벨로 네비게이션 | P2 |

#### E2E 테스트 (P2)

| # | 시나리오 | 검증 |
|---|---------|------|
| L-E01 | 로그인 → 시리즈 선택 → 이벤트 목록 | 화면 전환, 데이터 로딩 |
| L-E02 | 이벤트 선택 → 테이블 관리 → CC 잠금 상태 | 좌석 렌더링, 상태 표시 |
| L-E03 | 세션 복원 플로우 | 기존 세션 감지 → 복원 다이얼로그 → 이전 위치 복원 |

#### 커버리지 목표

| 계층 | Phase 1 목표 | 최종 목표 |
|------|:----------:|:--------:|
| Unit | ≥60% | ≥80% |
| Widget | 핵심 5개 화면 | 전체 화면 |
| E2E | 3 시나리오 | TEST-02 전체 |

---

### Command Center QA 전략

#### 사전 작업

```bash
cd /c/claude/ebs_app
flutter pub add --dev mocktail   # mock 프레임워크 추가
```

#### Unit 테스트 (P0)

| # | 대상 | 파일 | 테스트 항목 | 우선순위 |
|---|------|------|-----------|:-------:|
| C-U01 | CcApiClient | `test/services/api_client_test.dart` | `getTable()` 성공/404/5xx | P0 |
| C-U02 | CcApiClient | 상동 | `getSeats()` JSON 파싱 | P0 |
| C-U03 | CcApiClient | 상동 | `transitionTable()` 성공/409 conflict | P0 |
| C-U04 | CcApiClient | 상동 | `markDeckRegistered()` 성공/실패 | P0 |
| C-U05 | GameSession model | `test/models/game_session_test.dart` | `deckComplete` (51장=false, 52장=true) | P1 |
| C-U06 | PlayingCard | `test/models/card_test.dart` | `shortLabel` 52종 전부 검증 | P2 |

#### Integration 테스트 — loadTable 경로 (P0)

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

#### Widget 테스트 (P1)

| # | 대상 | 테스트 항목 | 우선순위 |
|---|------|-----------|:-------:|
| C-W01 | DeckRegistrationScreen | 진행바 값 = registeredCards.length/52 | P1 |
| C-W02 | DeckRegistrationScreen | 52장 완료 시 "Enter Live" 버튼 활성화 | P1 |
| C-W03 | CommandCenterScreen | street 라벨 변경 (preflop→flop→...) | P1 |
| C-W04 | CommandCenterScreen | 커뮤니티 카드 표시 (0~5장) | P2 |
| C-W05 | DeckGrid | 등록된 카드 = 녹색, 미등록 = 회색 | P2 |

#### E2E 테스트 (P2)

| # | 시나리오 | 검증 |
|---|---------|------|
| C-E01 | 앱 시작 → 테이블 로딩 → 덱 등록 | phase 전환, 진행바 |
| C-E02 | 52장 등록 → Enter Live → 핸드 진행 | street 전환, 커뮤니티 카드 |
| C-E03 | 서버 미연결 → 에러 표시 → 재시도 | 에러 복구 |

#### 커버리지 목표

| 계층 | Phase 1 목표 | 최종 목표 |
|------|:----------:|:--------:|
| Unit | ≥60% | ≥80% |
| Integration | loadTable 4경로 | 전체 상태 전환 |
| E2E | 3 시나리오 | TEST-02 전체 |

---

### Graphic Editor QA 전략

#### 사전 작업

행동 명세(BS)가 없으므로 **역설계 문서** 및 기존 컴포넌트 분석을 기준으로 테스트 항목을 정의한다.

```bash
cd /c/claude/ebs_ui/ebs-skin-editor
npm install   # Playwright 이미 설치됨
```

#### Unit 테스트 (P0)

| # | 대상 | 파일 | 테스트 항목 | 우선순위 |
|---|------|------|-----------|:-------:|
| G-U01 | useGfxStore | `tests/stores/useGfxStore.spec.ts` | addElement → elements 증가 | P0 |
| G-U02 | useGfxStore | 상동 | removeElement → elements 감소, 선택 해제 | P0 |
| G-U03 | useGfxStore | 상동 | updateElement → 속성 변경 반영 | P0 |
| G-U04 | useGfxStore | 상동 | selectElement → selectedId 변경 | P1 |
| G-U05 | useGfxStore | 상동 | undo/redo 스택 검증 | P1 |
| G-U06 | 색상 계산 | `tests/utils/color_test.spec.ts` | RGB↔HEX 변환, HUE 회전 | P2 |

#### Component 테스트 — Interaction 추가 (P1)

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

#### E2E 테스트 — Playwright (P2)

Playwright가 이미 설치되어 있으므로 바로 작성 가능:

| # | 시나리오 | 검증 |
|---|---------|------|
| G-E01 | 앱 로드 → 요소 추가 → 속성 편집 → 저장 | 기본 워크플로우 |
| G-E02 | 텍스트 요소 추가 → 폰트 변경 → 색상 변경 | 텍스트 편집 |
| G-E03 | 다수 요소 → 선택 → 삭제 → Undo | 실행 취소 |

#### 커버리지 목표

| 계층 | Phase 1 목표 | 최종 목표 |
|------|:----------:|:--------:|
| Unit (store) | ≥70% | ≥90% |
| Component | interaction 8건 | 전체 컴포넌트 |
| E2E | 3 시나리오 | 전체 워크플로우 |

---

### 구현 순서

#### Phase 1: 인프라 + P0 (1~2 세션)

```
1. Lobby: mocktail 설치 → SessionService unit 테스트 (L-U01~03)
2. CC: mocktail 설치 → CcApiClient unit 테스트 (C-U01~04)
3. CC: loadTable integration 테스트 (C-I01~04) — debugSetState 제거
4. GE: useGfxStore interaction 테스트 (G-U01~04)
```

#### Phase 2: P1 Widget/Component (1~2 세션)

```
5. Lobby: API Client + JSON 파서 unit (L-U04~05)
6. Lobby: LoginScreen + EventList widget (L-W01~04)
7. CC: DeckRegistration + CommandCenter widget (C-W01~05)
8. GE: Component interaction 테스트 (G-C01~08)
```

#### Phase 3: P2 E2E + CI/CD (1~2 세션)

```
9. Lobby: E2E 3 시나리오 (L-E01~03)
10. CC: E2E 3 시나리오 (C-E01~03)
11. GE: Playwright E2E 3 시나리오 (G-E01~03)
12. GitHub Actions CI/CD 파이프라인
```

---

### CI/CD 파이프라인 (목표)

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

### 검증 기준 (Definition of Done)

| 항목 | 기준 |
|------|------|
| P0 테스트 전부 PASS | `flutter test` / `npm run test` 녹색 |
| 칩/상태 invariant 포함 | 각 앱의 invariant가 자동 검증에 포함 |
| mock으로 에러 경로 테스트 | API 404/409/5xx 시나리오 포함 |
| debugSetState 제거 (CC) | 실제 코드 경로로 테스트 |
| CI/CD 파이프라인 녹색 | GitHub Actions에서 자동 실행 |

---
