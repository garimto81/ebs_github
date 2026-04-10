# QA-GE-10: Spec Gap 기록

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Game Engine Spec Gap 2건 기록 |
| 2026-04-09 | GAP-GE-003~005 추가 | Contract Test FAIL 3건 기반: Call enforcement, UNDO 제한, EventLog 미사용 |
| 2026-04-09 | GAP-GE-006 추가 | preflop 미종료 버그 — CALL 후 is_betting_round_complete 미호출 |
| 2026-04-09 | GAP-GE-007 추가 | acted_this_round 초기화 규칙 미명시 → BB 체크 옵션 소실 위험 |
| 2026-04-09 | GAP-GE-003~005 → SPEC_DONE | BS-06-02/BS-06-09/BS-06-00-REF 명세 보강 확인 완료 |

## 개요

Game Engine 구현 중 발견된 기획 명세 모호성/누락 항목을 기록한다. 각 항목에 대해 workaround 구현 완료 상태이며, 기획 보강이 필요하다.

---

## GAP-GE-001: `is_betting_round_complete` — "active players" 정의 모호

| 항목 | 설명 |
|------|------|
| **발견일** | 2026-04-09 |
| **심각도** | Critical |
| **관련 문서** | BS-06-10-action-rotation.md, 164-188행 pseudocode |
| **누락 내용** | `is_betting_round_complete` 함수의 조건 1 "Active players <= 1 → return true"에서 "active players"가 `SeatStatus.active`만 의미하는지, `active + allIn`을 포함하는지 미명시. 1 active + N allIn 상태에서 즉시 종료인지, active 플레이어가 행동 후 종료인지 판단 불가 |
| **발생한 버그** | 3-way pot에서 2명 allIn + 1명 active 시, active 플레이어가 call/fold 기회 없이 라운드가 즉시 종료됨 |
| **임시 구현** | `betting_rules.dart:isRoundComplete()`에서 `active.length == 1`일 때 allIn 존재 여부를 추가 확인. allIn이 없으면 즉시 true (전원 fold), allIn이 있으면 acted + bet 매칭 확인 |
| **기획 보강 요청** | BS-06-10 pseudocode 조건 1에 "active = `SeatStatus.active`만 (allIn 제외)" 주석 추가 + "active==1 && allIn 존재 시" 분기 조건 명시 |
| **기획 보강 완료** | 2026-04-09: BS-06-10 조건 1 pseudocode 보강 + 경계 케이스 테이블 2행 추가 |
| **Status** | **SPEC_DONE** — 구현 수정 필요 |

---

## GAP-GE-002: MisDeal 복구 — ante 반환 절차 미상세

| 항목 | 설명 |
|------|------|
| **발견일** | 2026-04-09 |
| **심각도** | Medium |
| **관련 문서** | BS-06-08-holdem-exceptions.md, 308-312행 (Matrix 5: Miss Deal 복구) |
| **누락 내용** | 복구 액션 "pot 복귀, stacks restore, 블라인드 반환"에서 ante가 "pot 복귀"에 포함되는지, "stacks restore"로 별도 처리되는지 미정의. Ante type 0-3, 5-6은 `currentBet`에 포함되지 않으므로 "블라인드 반환"으로는 ante를 복구할 수 없음 |
| **발생한 버그** | Standard Ante(type 0) 포스팅 후 misdeal 발생 시, ante 금액이 영구 소실됨 (각 플레이어 스택에서 ante만큼 감소) |
| **임시 구현** | `Seat` 클래스에 `int antePosted = 0` 필드 추가. Engine ante 포스팅 시 `seat.antePosted = post`로 추적. `_handleMisDeal`에서 `seat.stack += seat.currentBet + seat.antePosted`로 전액 반환 |
| **기획 보강 요청** | BS-06-08 Matrix 5에 "ante 반환: 각 플레이어가 포스팅한 ante 금액을 스택으로 반환" 항목 추가. Ante type별 반환 주체 명시 (type 1: 딜러 → 딜러 반환, type 2: BB → BB 반환) |
| **기획 보강 완료** | 2026-04-09: BS-06-08 Miss Deal 처리에 ante 반환 절차 + type별 반환 주체 추가 |
| **Status** | **SPEC_DONE** — 구현 수정 필요 |

---

## GAP-GE-003: Call 금액 — 외부 amount 무시 미구현

| 항목 | 설명 |
|------|------|
| **발견일** | 2026-04-09 |
| **심각도** | Critical |
| **관련 문서** | BS-06-02 §4 "금액 자동 계산 강제", BS-06-09 IE-02 ActionType enum (call amount=❌ 자동 계산) |
| **누락 내용** | 명세: "Call의 actual_amount는 엔진이 자동 계산한다. CC/외부에서 금액을 전달하더라도 무시한다". 구현: `BettingRules.applyAction()`에서 `Call.amount`를 그대로 사용 |
| **발생한 버그** | `Call(0)` 전달 시 0원 콜 처리, `Call(50)` 전달 시 biggest_bet=100임에도 50만 적용 |
| **임시 구현** | 없음 — 외부 전달값이 그대로 적용되는 상태 |
| **기획 보강 완료** | 2026-04-09: BS-06-02 §4 enforcement pseudocode + BS-06-09 IE-02/ActionType Enum 주석 보강 완료 |
| **Contract Test** | `test/contract/spec_contract_test.dart` CONTRACT 1 — FAIL 2건 (구현 수정 필요) |
| **Status** | **SPEC_DONE** — 구현 수정 필요 (`betting_rules.dart` applyAction 내 Call.amount 무시, 자동 재계산 적용) |

---

## GAP-GE-004: UNDO 5단계 제한 — Session 미적용

| 항목 | 설명 |
|------|------|
| **발견일** | 2026-04-09 |
| **심각도** | Major |
| **관련 문서** | BS-06-00-REF Ch7.6.7 "UNDO 제약" (maxUndoDepth=5), Ch8.4 undo endpoint |
| **누락 내용** | EventLog.maxUndoSteps=5가 정의되어 있으나, Session.undo()는 EventLog를 사용하지 않고 events.removeLast()를 직접 호출하여 무제한 undo 허용 |
| **발생한 버그** | 8개 이벤트에서 6번 undo 시 2개만 남음 (명세: 5번만 허용, 3개 남아야 함) |
| **임시 구현** | 없음 — Session이 EventLog를 사용하지 않는 상태 |
| **기획 보강 완료** | 2026-04-09: BS-06-00-REF Ch7.6.7 "Harness Session 적용" 행 추가 — Session은 반드시 EventLog를 통해 undo 처리, 5단계 제한 Harness까지 적용 명시 |
| **Contract Test** | `test/contract/spec_contract_test.dart` CONTRACT 3 — FAIL 1건 (구현 수정 필요) |
| **Status** | **SPEC_DONE** — 구현 수정 필요 (Session → EventLog 통합, maxUndoSteps=5 적용) |

---

## GAP-GE-005: EventLog 클래스 미사용 (dead code)

| 항목 | 설명 |
|------|------|
| **발견일** | 2026-04-09 |
| **심각도** | Major |
| **관련 문서** | BS-06-00-REF Ch7.6.1 "EventLog 데이터 구조", Ch7.6.7 "UNDO 제약" |
| **누락 내용** | `event_log.dart`에 EventLog 클래스가 정의(maxUndoSteps=5, record/undo/clear)되어 있으나, Session 클래스가 이를 사용하지 않고 `List<Event> events`로 직접 관리 |
| **발생한 버그** | UNDO 제한 미적용(GAP-GE-004), event log 불변성 보장 없음 |
| **임시 구현** | 없음 — EventLog 클래스가 사용되지 않는 dead code |
| **기획 보강 완료** | 2026-04-09: BS-06-00-REF Ch7.6.7 "Session은 내부적으로 EventLog를 사용하여 undo를 처리해야 한다" 명시 완료. GAP-GE-004와 동일 명세 보강. |
| **Contract Test** | `test/contract/spec_contract_test.dart` CONTRACT 7 — EventLog 단독 테스트 PASS (클래스 자체는 정상) |
| **Status** | **SPEC_DONE** — 구현 수정 필요 (Session 클래스 내부에서 `EventLog` 인스턴스 사용으로 전환) |

---

## GAP-GE-006: is_betting_round_complete — CALL/BET 후 미호출

| 항목 | 설명 |
|------|------|
| **발견일** | 2026-04-09 |
| **심각도** | Critical |
| **관련 문서** | BS-06-02-holdem-betting.md 플로우차트 (L567-579), BS-06-10-action-rotation.md |
| **누락 내용** | BS-06-02 플로우차트에서 CALL/BET 액션 후 `is_betting_round_complete` 체크가 없고 바로 `next_player`로 이동함. CHECK만 `all_checked?` 분기를 통해 라운드 종료 판정을 받음 |
| **발생한 버그** | UTG 레이즈 → 전원 콜 시나리오에서 BB 콜 이후 라운드가 자동 종료되지 않음. action_on이 UTG(레이저)로 이동하여 UTG의 추가 CHECK 입력을 대기함 (preflop 무한 대기) |
| **임시 구현** | 없음 |
| **기획 보강 요청** | BS-06-02 플로우차트 F/E/L 경로에 `is_betting_round_complete?` 분기 추가. 공통 원칙 섹션 추가. CHECK 섹션의 `original_first_actor 회귀` 표현을 `is_betting_round_complete(state)` 로 통일 |
| **기획 보강 완료** | 2026-04-09: BS-06-02 플로우차트 수정 + 공통 프로토콜 섹션 추가 + CALL 섹션 라운드 완료 확인 추가 |
| **Status** | **SPEC_DONE** — 구현 수정 필요 (`betting_rules.dart` applyAction 내 is_betting_round_complete 호출 추가) |

---

## GAP-GE-007: acted_this_round 초기화 규칙 미명시 (BB 체크 옵션 소실 위험)

| 항목 | 설명 |
|------|------|
| **발견일** | 2026-04-09 |
| **심각도** | Critical |
| **관련 문서** | BS-06-10-action-rotation.md `is_betting_round_complete` 조건 3, BS-06-03-holdem-blinds-ante.md 포스팅 순서 알고리즘 |
| **누락 내용** | `acted_this_round`의 초기화 시점과 방법이 미명시. 블라인드 포스팅(SB/BB)이 "액션"으로 포함되어서는 안 된다는 규칙이 없음 |
| **발생할 버그** | 구현자가 `acted_this_round`에 블라인드 포스터를 초기 포함하면: 전원 콜 후 all_players_acted = true (BB 미액션 상태) → `is_betting_round_complete` = true → BB 체크 옵션 소실, PRE_FLOP 조기 종료 |
| **임시 구현** | 없음 |
| **기획 보강 요청** | BS-06-10 `is_betting_round_complete` 조건 3에 "acted_this_round 초기화 = {}, 블라인드 포스팅 포함 금지" 명시. BS-06-03 포스팅 순서 알고리즘 마지막 단계에 초기화 규칙 추가 |
| **기획 보강 완료** | 2026-04-09: BS-06-10 조건 3 주석 보강 + BS-06-03 포스팅 알고리즘 step 11 추가 |
| **Status** | **SPEC_DONE** — 구현 검증 필요 (acted_this_round 초기화 지점 확인) |
