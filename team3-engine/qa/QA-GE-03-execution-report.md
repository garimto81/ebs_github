# QA-GE-03: Game Engine QA 실행 리포트

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Hold'em Core QA 1차 실행 결과 v1.0.0 |
| 2026-04-09 | §2 용어 정의 추가 | doc-critic 무결성 검증: KI, Hold'em, Harness, Side Pot 등 용어 비약 해소 |

---

## §1 실행 환경

| 항목 | 값 |
|------|-----|
| 프로젝트 | `C:\claude\ebs\ebs_game_engine\` |
| 브랜치 | `feat/game-engine` |
| Dart SDK | 3.11.0 |
| Harness | Docker `ebs-game-engine:h2` — `localhost:8888` |
| 실행일 | 2026-04-09 |

---

## §2 용어 정의

| 약어 | 의미 |
|------|------|
| **KI** | Known Issue — 코드 리뷰에서 발견된 알려진 버그 (번호: KI-01~14) |
| **Hold'em** | Texas Hold'em — 2장 홀카드 + 5장 커뮤니티 카드 포커 게임 |
| **Harness** | 게임 엔진을 HTTP API로 감싸는 테스트 서버 (Docker 컨테이너) |
| **Side Pot** | All-In 플레이어의 스택 차이로 분리되는 별도 팟 |
| **FSM** | Finite State Machine — 게임 진행 상태 관리 (IDLE→PRE_FLOP→FLOP→...) |
| **TC** | Test Case — QA-GE 문서에 정의된 개별 테스트 시나리오 |
| **All-In** | 보유 금액 전부를 거는 행위 |
| **Raise** | 베팅 올리기 — 상대의 베팅보다 더 큰 금액을 거는 행위 |
| **stack** | 플레이어 보유 금액 (베팅 토큰 총량) |
| **Unit test** | 단위 테스트 — 기능 하나하나를 개별적으로 검사 |
| **Integration** | 통합 테스트 — 여러 부품을 연결하여 전체 동작 검사 |
| **YAML** | 사람이 읽기 쉬운 데이터 저장 형식 (테스트 시나리오 파일) |

> 이 문서는 개발팀/QA 엔지니어 대상 기술 보고서입니다. §7 KI별 상세 분석은 소프트웨어 개발 경험이 필요합니다.

---

## §3 기존 테스트 Baseline

```
dart test → 571 Pass, 0 Fail
```

| 범주 | 파일 수 | 테스트 수 |
|------|:-------:|:--------:|
| Unit tests (core/) | 18 | ~180 |
| Phase tests (phase1~5) | 6 | ~280 |
| Scenario runner (YAML 30개) | 1 | 30 |
| Integration (harness/) | 2 | ~80 |
| **합계** | **27** | **571** |

---

## §4 QA 프로세스 Gap 발견 (CRITICAL)

### 문제

**571개 테스트 전부 Pass인데 Known Issue 11건(Critical 3건 포함)이 존재한다.**

### 원인

TC 문서(QA-GE-01~09)에 검증 항목이 정의되어 있지만, 해당 TC에 대응하는 dart test가 구현되지 않았다.

```
BS-06 기획서  ──→  QA-GE TC 문서  ──→  dart test 코드
     ✅ 존재        ✅ 존재            ❌ 연결 끊김
```

### 영향

- 기존 571개 테스트는 **정상 경로(happy path)만 커버**
- Critical edge case (Short Deck Wheel, Hi/Lo odd chip, Side Pot 연쇄)에 대한 테스트 부재
- **거짓 안전감(false confidence)**: "전부 Pass" ≠ "버그 없음"

### 시정 조치 (권장)

- TC 문서의 각 TC ID에 대응하는 dart test가 존재하는지 매핑 검증 단계 추가
- 신규 TC 작성 시 dart test 또는 YAML 시나리오 동시 작성 의무화

---

## §5 Hold'em Core KI 테스트 결과

### 테스트 파일: `test/ki_holdem_core_test.dart`

| # | KI | 테스트 | 결과 | 실제 값 | 기대 값 |
|:-:|:--:|--------|:----:|---------|---------|
| 1 | KI-05 | Raise(200) with stack=100 → stack >= 0 | ❌ | stack = **-100** | stack >= 0 |
| 2 | KI-05 | Raise overflow → clamp to allIn | ❌ | stack = **-100** | stack = 0, allIn |
| 3 | KI-09 | PRE_FLOP → RIVER 직행 차단 | ❌ | street = **river** | 차단 (street ≠ river) |
| 4 | KI-09 | FLOP → SHOWDOWN 직행 차단 | ❌ | street = **showdown** | 차단 (street ≠ showdown) |
| 5 | KI-09 | preflop→flop→turn→river 정상 전이 | ✅ | 정상 | 정상 |
| 6 | KI-03 | 3-way all-in → side pots 생성 | ❌ | sides = **empty** | sides.isNotEmpty |
| 7 | KI-03 | pot total 보존 (street 전환) | ❌ | pot = **25** | pot = 20 |

**결과: 6 Fail / 1 Pass**

### 테스트 파일: `test/ki_critical_test.dart`

| # | KI | 테스트 | 결과 | 실제 값 | 기대 값 |
|:-:|:--:|--------|:----:|---------|---------|
| 1 | KI-01 | Short Deck A-6-7-8-9 straight | ❌ | **highCard** | straight |
| 2 | KI-01 | Short Deck A-6-7-8-9 suited → straightFlush | ❌ | **flush** | straightFlush |
| 3 | KI-01 | ShortDeck variant evaluateHi wheel | ❌ | **highCard** | straight |
| 4 | KI-01 | Standard wheel A-2-3-4-5 (regression) | ✅ | straight | straight |
| 5 | KI-02 | Hi/Lo odd pot(101) → Hi=51, Lo=50 | ❌ | Hi=**50**, Lo=**51** | Hi=51, Lo=50 |
| 6 | KI-02 | Hi/Lo even pot(100) → 50/50 | ✅ | 50/50 | 50/50 |

**결과: 4 Fail / 2 Pass**

> KI-01, KI-02는 Flop variant 범위. Hold'em Core 우선 QA에서는 참고용으로만 기록.

---

## §6 Harness API 동작 확인

| 엔드포인트 | 결과 | 비고 |
|-----------|:----:|------|
| `POST /api/session` (NLH 6인) | ✅ | 세션 생성, 홀카드 딜, legalActions 정상 |
| `GET /api/variants` | ✅ | 16개 variant 반환 |

```
localhost:8888 — Docker 컨테이너 ebs-game-engine 정상 가동
```

---

## §7 KI별 상세 분석

### KI-03: Side Pot Engine 호출 누락 (Critical)

**파일**: `pot.dart` + `engine.dart`

**현상**: `Pot.calculateSidePots()` 알고리즘 자체는 정상 (단위 테스트 Pass). 그러나 `engine.dart`에서 이 함수를 호출하는 지점이 없다. 모든 bet이 `pot.main`에만 누적된다.

**추가 발견**: `_streetAdvance()`(engine.dart:L458-461)에서 `seat.currentBet = 0`으로 리셋. 이로 인해 street 간 누적 기여액이 소실되어, 나중에 side pot을 계산하려 해도 데이터가 없다.

**영향**: 3인 이상 all-in 시 side pot이 생성되지 않아 팟 분배가 불가능.

---

### KI-05: Raise toAmount > stack → 음수 (Major)

**파일**: `betting_rules.dart:L146-148`

**현상**: 
```dart
case Raise(:final toAmount):
  final increment = toAmount - seat.currentBet;  // 200 - 0 = 200
  seat.stack -= increment;                        // 100 - 200 = -100
```

**재현**: P0(stack=100)이 `Raise(200)` 실행 → stack = -100.

**영향**: 음수 스택은 이후 모든 계산(bet, call, pot)을 오염시킨다. 실제 게임에서 CC가 잘못된 금액을 전송하면 즉시 발생.

---

### KI-09: 무효 상태 전이 미차단 (Important)

**파일**: `engine.dart:L454-456`

**현상**:
```dart
static GameState _streetAdvance(GameState state, StreetAdvance event) {
  final newState = state.copyWith(street: event.next);  // 무조건 수락
```

**재현**: `StreetAdvance(Street.river)` 전송 시 PRE_FLOP에서 RIVER로 직행.

**영향**: 잘못된 이벤트 시퀀스가 게임 상태를 파괴. Harness/CC에서 잘못된 이벤트를 보내면 방어 불가.

---

## §8 요약

### 수치

| 항목 | 수치 |
|------|:----:|
| 기존 테스트 | 571 Pass |
| KI Core 테스트 | **6 Fail** / 1 Pass |
| KI Variant 테스트 | **4 Fail** / 2 Pass |
| 확인된 버그 | **KI-03, KI-05, KI-09** (Core) + **KI-01, KI-02** (Variant) |

### 심각도별 버그

| 심각도 | 건수 | 대상 |
|:------:|:----:|------|
| **Critical** | 1 | KI-03 Side Pot 미생성 |
| **Major** | 1 | KI-05 Raise 음수 stack |
| **Important** | 1 | KI-09 무효 전이 허용 |

### QA 프로세스 Gap

| Gap | 내용 | 시정 조치 |
|-----|------|----------|
| TC→테스트 파이프라인 끊김 | TC 문서에 정의된 검증 항목이 dart test로 구현되지 않음 | TC ID ↔ test file 매핑 검증 단계 추가 |
| Happy path 편향 | 571개 테스트가 정상 경로만 커버 | Edge case TC 의무 포함 |
| False confidence | "전부 Pass" ≠ "버그 없음" | 커버리지 메트릭 도입 |
