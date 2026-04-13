# QA-GE-CRITIC: Engine 개발 기획 문서 완성도 Critic 감사 — 2026-04-10

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 초판 작성 | BS-06-*, PRD-GAME-*, QA-GE-* 3축 엄격 critic. MVP 우선 + 22종 병기 판정. |

---

## §1 Context

**평가 목적**: Team 3 (Engine) 의 개발 기획 문서가 **계약 수준 엄밀성** 을 만족하며 MVP 홀덤 1종 구현을 착수할 수 있는 상태인지 엄격하게 critic 한다.

**평가자 / 일자**: Claude (critic mode) / 2026-04-10

**평가 기준 문서**:
- `docs/01-strategy/PRD-EBS_Foundation.md` (v41.0.0)
- `contracts/data/DATA-03-state-machines.md` (Hand FSM 9상태)
- `contracts/api/API-04-overlay-output.md` (OutputEvent + Security Delay)
- `contracts/specs/BS-00-definitions.md` (공통 enum / status)
- `team3-engine/CLAUDE.md` (3축 소유 + 계약 정확 일치 요구)

**스코프**:
- `team3-engine/specs/engine-spec/` (BS-06-00~32, 19 파일)
- `team3-engine/specs/games/` (PRD-GAME-01~04, 4 파일)
- `team3-engine/qa/` (QA-GE-00~10, 13 파일)
- 상위 계약 정렬 + `ebs_game_engine/lib/core/state/game_state.dart` FSM enum 대조

**Out of Scope**:
- `ebs_game_engine/` 소스 코드 전반 품질 (계약 정렬 증거로만 sampling)
- 통합 테스트 자체 품질 (계약 참조 여부만 확인)

**판정 원칙**:
- 사용자 결정(2026-04-10): **MVP 우선 + 22종 병기 / 구현 gap 은 Blocker 로 포함**
- 차원별 최솟값 < 3 → 🔴 **Red** (구현 차단)
- 모든 차원 ≥ 4 → 🟢 **Green** (착수 가능)
- 중간 → 🟡 **Yellow** (조건부 진행)

---

## §2 평가 대상 인벤토리

### 2-1. 실제 파일 배치 (⚠ 구조적 이상 발견)

Team 3 CLAUDE.md 는 소유 경로를 `team3-engine/specs/engine-spec/`, `team3-engine/qa/` 로 명시하지만, **실제 파일들은 한 단계 더 중첩된 경로**에 존재한다:

| CLAUDE.md 선언 경로 | 실제 파일 위치 | 차이 |
|---|---|---|
| `team3-engine/specs/engine-spec/` | `team3-engine/specs/engine-spec/` | ⚠ 이중 디렉토리 |
| `team3-engine/qa/` | `team3-engine/qa/` | ⚠ 이중 디렉토리 |
| `team3-engine/specs/games/` | `team3-engine/specs/games/` | ✅ 일치 |

**영향**: 문서 링크, CCR draft 의 `target_files`, 통합 검색(Grep/Glob)이 의도한 경로로 히트하지 않는다. 본 critic 감사 과정에서도 초기 Glob 검색이 실패했다.

→ **BLOCKER-0 (구조)** 에 기록. Conductor CCR 에스컬레이션 필요성은 Team 3 내부 디렉토리 재편으로 해결 가능(계약 파일 수정 불필요).

### 2-2. 파일 인벤토리

| 축 | 파일 수 | 총 라인 | 범위 |
|----|:-----:|:------:|------|
| `specs/engine-spec/` BS-06-* | 19 | 9,353 | BS-06-00~10, 11~14, 21~22, 31~32 |
| `specs/games/` PRD-GAME-* | 4 | 3,568 | PRD-GAME-01~04 |
| `qa/` QA-GE-* | 13 | 3,168 | QA-GE-00~10 (이중 번호 02/03 포함) |

**BS-06 누락 번호 15개**: 06-15~20 (Flop 확장 슬롯), 06-23~30 (Draw/Stud 사이)
- 번호가 "예약되었지만 작성되지 않은" 상태인지 "번호 체계가 의도적으로 sparse" 인지 문서에서 판단 불가
- → **QUICK-WIN** 에 번호 체계 의도 명시 요구 추가

---

## §3 차원별 점수 (C1~C10)

### 점수 매트릭스 (MVP 홀덤 1종 기준 / 22종 전수 기준)

| # | 차원 | MVP | 22종 | 한줄 요약 |
|---|------|:---:|:----:|-----------|
| C1 | Coverage | **4** | **2** | 홀덤 BS-06-01~10 + QA-GE-01~05 + PRD-GAME-01 §1 견고. 확장 15종 스켈레톤 |
| C2 | Contract Alignment | **2** | **2** | `enum Street` HAND_COMPLETE 누락, SPEC_DONE ≠ RESOLVED 혼동, 7 GAP 중 4 Critical 구현 미수정 |
| C3 | Testability | **4** | **3** | QA-GE 13파일 / 3,168라인 매우 충실. BS-06-10/11/12/14 TC 2건 이하 |
| C4 | Edge Case | **3** | **2** | Hold'em(BS-06-06/07/08) 우수. PRD-GAME-04 All-in/Side Pot/Chop/Run It Twice 섹션 부재 또는 얕음 |
| C5 | FSM 완결성 | **3** | **3** | BS-06-01 ASCII 다이어그램 O, BS-06-21/31 Draw/Stud 다이어그램 X. 계약-구현 enum gap |
| C6 | OutputEvent | **3** | **3** | BS-06-09 IE/IT/OE 3계층 O. BS-06-02/03/04 발행 시점 미명시, Security Delay Buffer 검증 불가 |
| C7 | Confluence 규칙 | **3** | **3** | MD 링크/앵커 0 위반. **Edit History 4파일 모두 누락**, `<img>` 상대 경로 50+건 |
| C8 | Spec Gap 관리 | **4** | **4** | 7 GAP 필드 100% 기재 + Contract Test 증거 2건. SPEC_DONE / RESOLVED 혼동 위험 |
| C9 | WSOP LIVE 정렬 | **3** | **2** | BS-06-* 는 WSOP Rule 번호 활발 인용. PRD-GAME 전부 Edit History 누락, frontmatter 표준 미준수 |
| C10 | 메타데이터 | **4** | **3** | BS-06 Edit History 성실. PRD-GAME-02 Version/Date 완전 누락 |

### Grading Scale (재인용)
- 5: 엔지니어가 추가 질문 없이 구현 가능
- 4: 경미한 모호성, 1-2회 질문이면 해결
- 3: 상당한 모호성, spec gap 문서화 필요
- 2: 구조적 누락, 섹션 단위 재작성 필요
- 1: 프레임만 존재, 실질적 내용 없음
- 0: 파일 자체 없음

---

## §4 차원별 근거 (엄격 인용)

### C1 · Coverage — MVP 4 / 22종 2

**✅ 홀덤 MVP 근거**:
- `BS-06-00-REF-game-engine-spec.md` 1,749라인 + 16회 Edit (2026-04-06~10) — WSOP Rule 28/71/81/87/88/96/100/101 추적
- `BS-06-02-holdem-betting.md` 1,021라인 — NL/PL/FL 액션별 유효조건 매트릭스 + 20 user story
- `BS-06-06-holdem-side-pot.md` 346라인 — 2/3/4인 mixed + fold+allin 4 매트릭스 + 12 user story
- `BS-06-07-holdem-showdown.md` 517라인 — 48 카드 공개 조합 (유효 ~32)
- `BS-06-08-holdem-exceptions.md` 532라인 — 7 예외 매트릭스

**❌ 22종 근거**:
- BS-06-11 Shortdeck 234라인 / BS-06-12 Pineapple 245 / BS-06-13 Omaha 184 / BS-06-14 Courchevel 192 — **모두 2회 Edit 스켈레톤**
- BS-06-21 Draw Lifecycle 482 / BS-06-22 Draw Evaluation 367 — 2회 Edit
- BS-06-31 Stud Lifecycle 436 / BS-06-32 Stud Evaluation 221 — 2~3회 Edit
- 구현 Variant 13종 중 **Draw/Stud 구현 0종** (`lib/core/variants/` 내 flh/nlh/plh/omaha/omaha_hilo/short_deck/short_deck_triton/pineapple/five_card_omaha/six_card_omaha/courchevel/variant/variants 만 존재)

### C2 · Contract Alignment — 2 (MVP/22종 동일)

**Blocker 근거 (확증된 primary source)**:

```dart
// C:\claude\ebs\team3-engine\ebs_game_engine\lib\core\state\game_state.dart:10
enum Street { setupHand, preflop, flop, turn, river, showdown, runItMultiple }
// → 7 상태만 존재
```

```
// contracts/data/DATA-03-state-machines.md (Hand FSM 요구)
IDLE → SETUP_HAND → PRE_FLOP → FLOP → TURN → RIVER → SHOWDOWN → HAND_COMPLETE
                                                      ↘ RUN_IT_MULTIPLE
// → 9 상태 요구
```

**계약 vs 구현 diff**:
```
 CONTRACT (9)                  IMPLEMENTATION (7)
 ───────────────────           ───────────────────
 IDLE                      →   (없음 — setupHand 에 흡수?)
 SETUP_HAND                →   setupHand              ✓ (의미 매칭)
 PRE_FLOP                  →   preflop                ✓
 FLOP                      →   flop                   ✓
 TURN                      →   turn                   ✓
 RIVER                     →   river                  ✓
 SHOWDOWN                  →   showdown               ✓
 HAND_COMPLETE             →   ❌ 누락
 RUN_IT_MULTIPLE           →   runItMultiple          ✓
```

**추가 증거**:
- `qa/QA-GE-10-spec-gap.md` 7 GAP 전체 **Status = SPEC_DONE (구현 수정 필요)**. "기획 보강 완료 ≠ 구현 완료" 라는 상태가 RESOLVED 로 오해될 수 있는 혼동 구조.
- GAP-GE-001 / 003 / 006 / 007 = **Critical 4건**. 그중 GAP-GE-003 은 `test/contract/spec_contract_test.dart` **CONTRACT 1 FAIL 2건**, GAP-GE-004 는 **CONTRACT 3 FAIL 1건** 명시.
- 네이밍 컨벤션: 계약 `SCREAMING_SNAKE_CASE` vs 구현 `camelCase` → grep 기반 추적 불가.

### C3 · Testability — MVP 4 / 22종 3

**✅ 강한 근거**:
- `qa/QA-GE-01-fsm-transitions.md` 326라인 — Hold'em 9상태 FSM 전이 14 TC (정상 11 + 무효 3)
- `qa/QA-GE-02-checklist.md` 475라인 — BS-06 19파일 1:1 대조, Contract Test FAIL 증분 반영
- `qa/QA-GE-03-allin-sidepot.md` 214라인 — 8 TC
- `qa/QA-GE-06-game-matrix.md` 352라인 — 22종 교차 매트릭스

**⚠ 약한 근거**:
- BS-06-10 Action Rotation: edge case TC 2건 이하 (4인+ heads-up, dead button 누락)
- BS-06-11/12/14: 테스트 시나리오 0~1건
- BS-06-05 `holdem-evaluation.md` 279라인: 실제 입/출 예시 없이 "evaluator 함수 참조" 로만 추상화

### C4 · Edge Case — MVP 3 / 22종 2

**✅ 홀덤 근거**:
- BS-06-06 Side Pot 4 매트릭스, BS-06-07 Showdown 32 유효 조합, BS-06-08 예외 7 매트릭스

**❌ PRD-GAME-04 Betting System 부재 섹션** (크로스 게임 공통 규칙 부재):
- **All-in & Side Pot** 섹션 없음 (BS-06-06 은 홀덤 전용)
- **Button Reset / Dead Button** 없음
- **String Bet / Bet Out of Turn** 처벌 규칙 없음
- **Chop 합의 메커니즘** 없음
- **Showdown Order** (누가 먼저 보여주는가) 없음
- **Run It Twice**: §5-3 (라인 547~576) 에 **존재** — "3인+ 원칙" 기재됨 ✓

### C5 · FSM 완결성 — 3 (MVP/22종 동일)

**✅ 강함**: `BS-06-01-holdem-lifecycle.md` 460라인 — ASCII 상태 다이어그램 + 10 user story
**❌ 약함**:
- BS-06-21 Draw Lifecycle 482라인 — ASCII 다이어그램 없음 (Draw round 수 다양성 불명확)
- BS-06-31 Stud Lifecycle 436라인 — 다이어그램 없음 (Bring-in / 3rd~7th Street 전이 미명시)
- C2 계약 ↔ 구현 enum gap 이 FSM 완결성에도 직접 영향

### C6 · OutputEvent 계약 — 3 (MVP/22종 동일)

**✅ 강함**: `BS-06-09-event-catalog.md` 363라인 — IE-01~13 (Input) / IT-01~10 (Internal) / OE-01~20 (Output) 3계층 완전 정의

**❌ 약함**:
- BS-06-02 / 03 / 04 (베팅 / 블라인드 / Coalescence) 는 **OutputEvent 발행 시점 언급 없음** — 내부 state 변경만 기술
- `contracts/api/API-04-overlay-output.md` §3 Security Delay (hole_cards, community_cards, action 배지 등 delay 적용 이벤트) 의 **구현 검증 불가**: `ebs_game_engine/lib/core/actions/output_event.dart` 존재하나 `OutputEventBuffer` 구현 여부 확인 경로가 문서에 없음.
- BS-06-09 에서 OE-* ↔ API-04 OutputEvent 타입 1:1 매핑 표 부재 → 개발자가 직접 비교해야 함.

### C7 · Confluence 규칙 준수 — 3 (MVP/22종 동일)

**✅ PASS**:
- Markdown 링크 `[text](url)` : **0 건**
- 앵커 링크 `](#...)` : **0 건**
- 외부 문서 참조 : 0 건 (내부 `§N` 6건은 회색지대 — Confluence 목차로 변환 가능)

**❌ FAIL**:
- **Edit History 테이블: PRD-GAME-01/02/03/04 모두 누락**
- 이미지: `<img src="visual/screenshots/*.png">` 상대 경로 50+건 — Confluence 업로드 시 깨짐 위험
- PRD-GAME-02: Version/Date 메타 완전 누락 (PRD-GAME-01/03/04 는 blockquote 형식 존재, 표준 frontmatter 아님)

### C8 · Spec Gap 관리 — 4 (MVP/22종 동일)

**✅ 강함**: `qa/QA-GE-10-spec-gap.md` 125라인 — 7 GAP 모두 발견일 / 심각도 / 관련 문서 / 누락 내용 / 발생한 버그 / 임시 구현 / 기획 보강 요청 / 기획 보강 완료 / Status 필드 100% 기재.

```
GAP-GE-001 Critical  is_betting_round_complete active 정의 모호       SPEC_DONE
GAP-GE-002 Medium    MisDeal ante 반환 미상세                         SPEC_DONE
GAP-GE-003 Critical  Call 금액 외부 amount 무시 미구현 [CONTRACT 1 FAIL x2]  SPEC_DONE
GAP-GE-004 Major     UNDO 5단계 제한 Session 미적용     [CONTRACT 3 FAIL x1]  SPEC_DONE
GAP-GE-005 Major     EventLog 클래스 미사용 (dead code) [CONTRACT 7 PASS]     SPEC_DONE
GAP-GE-006 Critical  CALL/BET 후 is_betting_round_complete 미호출     SPEC_DONE
GAP-GE-007 Critical  acted_this_round 초기화 규칙 미명시              SPEC_DONE
```

**⚠ 약함**: "SPEC_DONE" 은 "기획 보강 완료, 구현 수정 필요" 를 뜻하지만 **RESOLVED 와 구분이 약해** 구현 미완료 상태를 "완료" 로 오해할 위험. Status 에 `SPEC_DONE_IMPL_PENDING` 같은 명시적 라벨 권장.

### C9 · WSOP LIVE 정렬 — MVP 3 / 22종 2

**✅ BS-06-00-REF**: WSOP Rule 번호 (28, 71, 81, 87, 88, 96, 100, 101) 활발 인용, 16 Edit 추적.

**❌ PRD-GAME 전체**: Edit History 테이블 누락 — `wsoplive/docs/confluence-mirror/` 의 표준 frontmatter (page_id, version, last_modified) 미참조. Team 0 CLAUDE.md "WSOP LIVE Confluence 정렬" 원칙 위반. 의도적 divergence 문서화도 없음.

### C10 · 메타데이터 — MVP 4 / 22종 3

**✅ 강함**: BS-06-00~10 모든 파일에 Edit History 존재. BS-06-00 은 16회 기록.
**❌ 약함**: PRD-GAME-02 Version/Date 완전 누락, BS-06-11~14/21~22/31~32 Edit 2회 (Phase 3 대기 상태).

---

## §5 종합 판정

### MVP (홀덤 1종) 기준 : 🟡 **YELLOW (조건부 Go)**

- **최솟값 = 2** (C2 Contract Alignment)
- **C2 해소 시 Green 달성 가능** — 차원 C1/C3/C8/C10 은 이미 4점, C4/C5/C6/C7/C9 는 3점으로 경미한 모호성 수준
- 즉, **아래 §6 Top 5 Blocker 중 1~2번 (FSM enum + Critical GAP 4건) 만 해소하면 MVP 구현 착수 가능**

### 22종 전수 기준 : 🔴 **RED (구현 차단)**

- **최솟값 = 2** (C1 Coverage, C2, C4 Edge Case, C9 WSOP LIVE)
- Draw/Stud BS 문서 스켈레톤, 구현 0종, PRD-GAME-04 전체 공통 규칙 미흡, Edit History 전부 누락
- **구조적 재작업 필요** — MVP 런칭 후 Phase 2 로 이월 권장 (2027-01 런칭 시점에 22종 전부 Green 을 요구하면 일정 불가)

### 판정 요약 매트릭스

```
차원        | MVP |22종 |           | MVP |22종 |
C1 Coverage |  4  |  2  | C6 OutEvt |  3  |  3  |
C2 Contract |  2  |  2  | C7 Conflu |  3  |  3  |
C3 TestAbil |  4  |  3  | C8 GapMgmt|  4  |  4  |
C4 EdgeCase |  3  |  2  | C9 WSOPLV |  3  |  2  |
C5 FSM      |  3  |  3  | C10 Meta  |  4  |  3  |
            ─────────────           ─────────────
       MIN  |  2  |  2  |  판정    |  🟡 |  🔴  |
```

---

## §6 Top 5 Blocker (MVP Green 달성 조건)

### BLOCKER-0 (구조적) · `specs/engine-spec/` + `qa/` 이중 디렉토리

- **근거**: Team 3 CLAUDE.md 의 선언 경로와 실제 파일 위치가 불일치. Glob 검색 실패 재현됨.
- **수정**: 디렉토리를 한 단계 평탄화 또는 CLAUDE.md 경로 선언을 실제에 맞게 수정
- **영향**: CCR draft `target_files`, 통합 테스트 경로, 문서 링크, hook scope-guard 모두에 영향

### BLOCKER-1 [C2] · `enum Street` 에 `idle`, `handComplete` 추가

- **근거**: `ebs_game_engine/lib/core/state/game_state.dart:10` (7상태), `contracts/data/DATA-03-state-machines.md` (9상태)
- **수정**: `enum Street { idle, setupHand, preflop, flop, turn, river, showdown, handComplete, runItMultiple }` + `BS-06-01-holdem-lifecycle.md` 전이 로직 업데이트
- **영향**: API-04 OutputEvent 발행 타이밍, 통계 기록, audit_logs INSERT 시점

### BLOCKER-2 [C2] · GAP-GE-001 / 003 / 006 / 007 구현 수정 (Critical 4건)

- **근거**: `qa/QA-GE-10-spec-gap.md` Status 전부 SPEC_DONE, CONTRACT 1/3 FAIL
- **수정 파일**:
  - `ebs_game_engine/lib/core/rules/betting_rules.dart` `applyAction()`
    - Call.amount 외부값 무시 (GAP-003)
    - applyAction 내 `is_betting_round_complete()` 호출 추가 (GAP-006)
  - `ebs_game_engine/lib/harness/session.dart` (또는 동등)
    - acted_this_round 초기화 = {} 블라인드 포스팅 제외 (GAP-007)
    - active players 정의 명확화 (GAP-001: SeatStatus.active 만, allIn 제외)
- **재현 케이스**: GAP 문서에 이미 포함 → 회귀 테스트 즉시 작성 가능

### BLOCKER-3 [C4] · PRD-GAME-04 에 All-in & Side Pot 공통 섹션 신설

- **근거**: BS-06-06 은 홀덤 전용, PRD-GAME-04 §5 (Special Rules) 는 Bomb Pot / Run It Twice / 7-2 Side Bet 만 다룸
- **수정**: `specs/games/PRD-GAME-04-betting-system.md` 에 "§6 All-in & Side Pot" 신설
  - N-way all-in 팟 분할 공식
  - Dead money 처리
  - Eligible set 계산
  - 크로스 게임 일반화 (Flop/Draw/Stud 공통)

### BLOCKER-4 [C9, C10] · PRD-GAME 4파일 Edit History 테이블 추가 + PRD-GAME-02 Version 추가

- **근거**: `specs/games/PRD-GAME-01/02/03/04.md` 상단에 `| 날짜 | 항목 | 내용 |` 표 부재 — Team 0 CLAUDE.md "WSOP LIVE Confluence 정렬" 원칙 위반
- **수정**: 4개 파일 상단에 초판 Edit History 삽입 + PRD-GAME-02 에 Version/Date blockquote 추가
- **영향**: Confluence 발행 전 필수 조건

### BLOCKER-5 [C4, C9] · PRD-GAME-04 "보통 / 일반적으로" 6건 모호성 제거

**확증된 primary source (6건 전체)**:
```
PRD-GAME-04:158  "Small Blind (SB): ... 보통 Big Blind의 절반"
PRD-GAME-04:435  "Standard Ante 금액: 동일 (보통 BB의 10~25%)"
PRD-GAME-04:443  "Button Ante 금액: 보통 BB와 동일"
PRD-GAME-04:449  "BB Ante 금액: 보통 BB와 동일 (전체 합계)"
PRD-GAME-04:538  "Bomb Pot 합의 금액: 보통 5x~10x BB"
PRD-GAME-04:583  "7-2 Side Bet: 참여자 전원 사전 합의 (보통 1x~5x BB)"
```

**수정 원칙**: 엔진 팀이 상수로 구현 가능한 수준까지 구체화
- SB = BB / 2 (기본값, 예외는 GAP-GE-009 에서 블라인드 구조별 재정의)
- Standard Ante 기본값 = BB × 10% (WSOP Rule 인용 또는 이벤트 설정값 명시)
- Bomb Pot / 7-2 Side Bet 은 "이벤트 고유 설정값" 으로 표기하되, Default 를 명시 + 이벤트 설정 필드 (`bombPotAmount`, `sevenDeuceAmount`) 참조

---

## §7 Top 5 Quick-Win (≤1일)

| # | 작업 | 파일 | 예상 작업량 |
|:-:|------|------|:-----------:|
| QW-1 | PRD-GAME-02 에 `> Version`, `> Date` blockquote 1줄씩 추가 | `specs/games/PRD-GAME-02-draw.md` | 2 분 |
| QW-2 | PRD-GAME-02 에 "## 7종 Draw 게임 인벤토리" 테이블 추가 (Five Card Draw / 2-7 Triple Draw / 2-7 Single Draw / Badugi / A-5 Triple Draw 등) | `PRD-GAME-02` | 20 분 |
| QW-3 | BS-06-03:467 "추후 도입 예정" 문구 → GAP-GE-008 draft 로 승격 | `qa/QA-GE-10-spec-gap.md` + `BS-06-03:467` 정리 | 15 분 |
| QW-4 | BS-06-05 평가 문서에 입/출 예시 5건 추가 (AA Two Pair / Straight Flush / Four of a Kind / Full House tie / Kicker 비교) | `BS-06-05-holdem-evaluation.md` | 60 분 |
| QW-5 | `contracts/api/API-04-overlay-output.md` OutputEvent 타입 ↔ `lib/core/actions/output_event.dart` 클래스 ↔ `BS-06-09` OE-01~20 1:1 매핑 표 작성 | `BS-06-09-event-catalog.md` 부록 | 40 분 |

---

## §8 22종 로드맵 Gap (MVP 밖, 정보 제공)

| 영역 | 현황 | 필요 작업 | 우선순위 |
|------|------|-----------|:---:|
| BS-06-15~20 번호 미할당 | Flop variant 확장 슬롯 목적 불명 | 번호 체계 의도 명시 또는 재정렬 | Low |
| BS-06-23~30 번호 미할당 | Draw/Stud 사이 미할당 | 상동 | Low |
| BS-06-11~14 Flop 확장 | 184~245라인 2-Edit 스켈레톤 | BS-06-02 수준 매트릭스 확장 (NL/PL/FL × 액션별) | Mid |
| BS-06-21~22 Draw | FSM 다이어그램 부재 | BS-06-01 스타일 ASCII 다이어그램 + Draw round 수 matrix | Mid |
| BS-06-31~32 Stud | FSM 다이어그램 부재 | Bring-in / 3rd~7th Street 전이 명시 | Mid |
| Variant 구현 Draw/Stud | 0 종 구현 | 11종 Flop 이후 Phase 2 | Mid |
| EventLog dead code | Session 미사용 (GAP-GE-005) | Session → EventLog 통합 (UNDO 5단계) | High (BLOCKER-2 에 포함) |
| OutputEventBuffer | 구현 검증 불가 | `output_event.dart` 내부 확인 + BS-06-09 에 발행 시점 명시 (GAP-GE-011 신규) | High |
| BS-06-10 Action Rotation | TC 2건 이하 | edge case (4인+ heads-up, dead button, 동시 all-in) 추가 | Mid |
| 네이밍 컨벤션 | SCREAMING_SNAKE_CASE vs camelCase grep 불가 | SSOT 매핑 (GAP-GE-010 신규) | Mid |

---

## §9 신규 Spec Gap 제안 (draft)

아래 항목은 `qa/QA-GE-10-spec-gap.md` 에 GAP-GE-008~012 로 추가 후 필요 시 `docs/05-plans/ccr-inbox/CCR-DRAFT-team3-20260410-*.md` 로 에스컬레이션:

### GAP-GE-008 · BS-06-03 "패널티 운영자 재량 (추후 도입 예정)" 구체화
- 심각도: Medium
- 관련 문서: `BS-06-03:467`
- 누락 내용: `ManagerRuling` 이벤트의 payload, 트리거 조건, 로그 저장 경로 미정
- 요청: BS-06-09 에 OE-21 `ManagerRuling` 추가 + BS-06-03 에 절차 (감지 → Staff 승인 → 이벤트 발행 → 적용) 명시

### GAP-GE-009 · PRD-GAME-04 Ante / Blind / Bomb Pot 기본값 정의
- 심각도: Critical (BLOCKER-5 와 연관)
- 관련 문서: `PRD-GAME-04:158, 435, 443, 449, 538, 583`
- 누락 내용: "보통 BB의 10~25%" 같은 범위 표현이 엔진 구현 불가
- 요청: 각 항목에 Default 상수 + 이벤트 설정값 참조 필드 명시

### GAP-GE-010 · FSM enum 네이밍 컨벤션 SSOT
- 심각도: Medium
- 관련 문서: `contracts/data/DATA-03-state-machines.md`, `ebs_game_engine/lib/core/state/game_state.dart:10`, `contracts/specs/BS-00-definitions.md`
- 누락 내용: 계약(SCREAMING_SNAKE_CASE) ↔ Dart 구현(camelCase) 매핑 규칙 없음 → grep / 추적 불가
- 요청: BS-00-definitions 에 매핑 표 추가 OR Dart lint 규칙으로 SCREAMING_SNAKE 강제
- 주의: `contracts/` 수정 동반 → **CCR draft 필요**

### GAP-GE-011 · API-04 OutputEventBuffer (Security Delay) 적용 범위 명시
- 심각도: Major
- 관련 문서: `contracts/api/API-04-overlay-output.md` §3, `ebs_game_engine/lib/core/actions/output_event.dart`
- 누락 내용: `OutputEventBuffer` 구현이 실제로 어느 OE 타입에 적용되는지 BS-06-09 에 매핑 없음
- 요청: BS-06-09 OE-01~20 각각에 `delay_applied: true/false` 필드 명시
- 주의: `contracts/` 수정 동반 → **CCR draft 필요**

### GAP-GE-012 · PRD-GAME 이미지 상대 경로 → Confluence asset 전환 프로세스
- 심각도: Medium
- 관련 문서: `specs/games/PRD-GAME-01~04.md` 의 `<img src="visual/screenshots/...">` 50+건
- 누락 내용: Confluence 발행 시 상대 경로 해석 불가 → 깨진 이미지
- 요청: 이미지 업로드 파이프라인 (로컬 path → Confluence attachment URL) 문서화 또는 base64 embed 전략 결정

---

## §10 Conductor 에스컬레이션 필요 항목

다음 건은 `contracts/` 수정을 동반하므로 `docs/05-plans/ccr-inbox/CCR-DRAFT-team3-20260410-*.md` draft 제출 필요 (hook이 팀의 직접 수정을 차단):

1. **GAP-GE-010** FSM enum 네이밍 컨벤션 SSOT
   - target: `contracts/specs/BS-00-definitions.md`
   - 영향팀: team3 (직접), team4 (CC harness 연동)
2. **GAP-GE-011** OutputEvent Security Delay 적용 범위
   - target: `contracts/api/API-04-overlay-output.md`
   - 영향팀: team3, team4 (Overlay 소비자)

BLOCKER-1 (enum Street) 과 BLOCKER-2 (GAP Critical 구현) 는 **Team 3 내부 파일** 수정이므로 CCR 불필요.

BLOCKER-0 (이중 디렉토리) 는 Team 3 내부 구조이지만, `team-policy.json` 의 scope 정의와 `/auto` cwd 감지 로직에 영향을 줄 수 있어 Conductor 에 사전 통지 권장.

---

## §11 검증 방법 (본 보고서의 재현성)

이 critic 보고서의 주장을 재검증하려면:

1. **enum Street 7상태 확인**
   ```
   Read: C:\claude\ebs\team3-engine\ebs_game_engine\lib\core\state\game_state.dart
   → line 10 에 `enum Street { setupHand, preflop, flop, turn, river, showdown, runItMultiple }` 확인
   ```

2. **7 GAP SPEC_DONE 확인**
   ```
   Read: C:\claude\ebs\team3-engine\qa\qa\QA-GE-10-spec-gap.md
   → GAP-GE-001~007 모두 Status = SPEC_DONE 확인
   → Critical 마킹 = 001/003/006/007 (4건)
   → CONTRACT FAIL = GAP-003 (1건 x2 액션), GAP-004 (1건)
   ```

3. **PRD-GAME-04 모호성 6건 확인**
   ```
   Read: C:\claude\ebs\team3-engine\specs\games\PRD-GAME-04-betting-system.md
   → line 158, 435, 443, 449, 538, 583 에서 "보통" 키워드 확인
   ```

4. **PRD-GAME Edit History 누락 확인**
   ```
   Grep: pattern="Edit History|변경 이력", path="specs/games/"
   → 0 matches 확인
   ```

5. **이중 디렉토리 구조 확인**
   ```
   Glob: pattern="**/BS-06-*.md", path="team3-engine"
   → specs/engine-spec/BS-06-*.md 로 히트 확인
   Glob: pattern="**/QA-GE-*.md", path="team3-engine"
   → qa/QA-GE-*.md 로 히트 확인
   ```

---

## §12 결론 및 권장 다음 단계

### 결론

- **MVP (홀덤 1종) 기준 🟡 Yellow**: BLOCKER-0 (구조) + BLOCKER-1 (enum) + BLOCKER-2 (Critical 4 GAP 구현) 을 해소하면 2027-01 MVP 런칭 일정 내 Green 달성 가능.
- **22종 기준 🔴 Red**: 현재 구조로는 2027-01 에 22종 전수를 Green 으로 만들 수 없음. MVP 런칭 후 Phase 2 로 22종 확장 분리 권장.
- **기획 문서 품질의 이원화**: Hold'em BS-06-00~10 + QA-GE-01~05 는 **구현 가능 수준**(4~5점), 확장 게임 및 PRD-GAME-04 공통 규칙은 **섹션 단위 재작성 필요**(2~3점).

### 권장 다음 단계 (순서대로)

1. **즉시 (Day 0)**: 본 보고서를 팀 공유, BLOCKER-0~2 를 team3 backlog 로 등록
2. **Week 1**: BLOCKER-1 (enum Street 확장) + BLOCKER-2 (GAP-001/003/006/007 구현 수정) + 회귀 테스트 추가
3. **Week 1**: QW-1~5 Quick-Win 병행
4. **Week 2**: BLOCKER-3 (All-in & Side Pot 섹션) + BLOCKER-5 (PRD-GAME-04 모호성 제거)
5. **Week 2**: BLOCKER-4 (Edit History 추가) + Confluence 이미지 파이프라인 결정
6. **Week 2 말**: GAP-GE-010 / 011 CCR draft 제출 → Conductor 에스컬레이션
7. **Week 3 초**: MVP 재평가 (본 critic 보고서 재실행) → Green 확인 후 구현 착수

### 재감사 일정

본 보고서는 2026-04-10 시점 snapshot. **BLOCKER 해소 후 2026-04-17 (Week 1 말)** 에 재감사 권장. 재감사 시 §4 근거의 Status 변화 (SPEC_DONE → RESOLVED) 및 `enum Street` 9상태 여부를 primary source 로 재확인할 것.

---

**작성자**: Claude (critic mode)
**기준 일자**: 2026-04-10
**다음 감사 권장일**: 2026-04-17
