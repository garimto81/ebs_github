# QA-GE-07 — Mix 게임 전환 QA

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Master Plan §8.8 확장 — Mix 게임 전환 TC 상세화 v1.0.0 |
| 2026-04-09 | WSOP 규정 검증 | 2025 WSOP 공식 규정 교차 검증. 8-Game 순서/전환 트리거 오류 수정, 버튼 freeze 규칙 추가, ante 구조 매핑 추가 |

---

## 개요

Mix 게임 4종(HORSE, 8-Game, PPC, Dealer's Choice)의 게임 전환 시나리오를 검증한다. 전환 전후 상태 초기화, FSM 정합성, bet_structure 전환을 포함한다.

---

## Mix 유형 매트릭스

| Mix | 포함 게임 (WSOP 공식 순서) | 전환 방식 | bet_structure 변동 |
|-----|---------------------------|----------|-------------------|
| HORSE | ①Hold'em ②Omaha Hi-Lo ③Razz ④Stud ⑤Stud Hi-Lo | **orbit 기반** — 이벤트 구조표에 정의된 핸드 수마다 전환 | **전부 FL** (FL → FL → FL → FL → FL) |
| 8-Game | ①2-7 Triple Draw ②Hold'em ③Omaha Hi-Lo ④Razz ⑤Stud ⑥Stud Hi-Lo ⑦NL Hold'em ⑧PLO | **6핸드마다** 전환 (WSOP Event #73 기준) | FL → FL → FL → FL → FL → FL → **NL** → **PL** |
| PPC | Dealer's Choice subset | 플레이어 선택 — 1~N핸드 유지 (구조표 정의) | 선택 게임에 따라 |
| Dealer's Choice | 22종 전체 | 플레이어 선택 — 1핸드~최대 테이블 인원 수 핸드 유지 | 선택 게임에 따라 |

> **출처**: `2025-WSOP-Tournament-Rules.pdf` Rule 67b, 73, 79 + `2025-WSOP-Event73-DealersChoice.pdf` 구조표

### WSOP Mixed Game 버튼 규칙 (Rule 67b)

Flop 게임에서 Stud 게임으로 전환 시:
1. 마지막 Flop 핸드 완료 후, 버튼을 다음 Hold'em이었으면의 위치로 이동
2. Stud 게임 동안 버튼 **freeze** (이동하지 않음)
3. 다시 Flop 게임으로 복귀 시, freeze된 위치에서 재개

### WSOP Ante/Blind 구조 전환 규칙 (Event #73)

같은 레벨에서도 게임 유형별로 구조가 다르다:

| 게임 유형 | Ante | Bring-in | Small Blind | Big Blind | Limits |
|----------|------|---------|-------------|-----------|--------|
| **Limit Flop/Draw** | — | — | SB | BB | small bet - big bet |
| **Stud Games** | ante | bring-in | — | — | completion - limits |
| **PL & NL** | BB ante / 1.5×BB ante | — | SB | BB | — |

> **PL 특수 규칙**: ante는 BB와 동일하지만, **FLOP 이후에만** pot에 포함됨

---

## TC 목록

### TC-G1-020-01: HORSE 5종 순환 전환

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 3 |
| **우선순위** | P2 |
| **Players** | 6인 (P0~P5), stack=10000, 레벨별 블라인드/앤티 변동 |
| **Hole Cards** | N/A (전환 로직 검증) |
| **Board** | N/A |
| **Actions** | Game Engine: Mix 설정 = HORSE. 이벤트 구조표에 정의된 핸드 수(예: 6핸드) 완료 → 전환 신호 → 다음 게임 시작. 순서: ①Hold'em ②Omaha Hi-Lo ③Razz ④Stud ⑤Stud Hi-Lo → 반복 |
| **기대 결과** | 전환 직전: `game_phase=HAND_COMPLETE → IDLE`. 전환 직후: `pot=0`, `hand_in_progress=false`, `game_phase=IDLE`, `bets=[]`, `community_cards=[]`. evaluator 전환: standard_high → omaha_hilo → ace_to_five → standard_high → stud_hilo. bet_structure: **전부 FL** (전환 시 변동 없음). blind→bring-in 전환: Hold'em/O8 (SB+BB) → Razz/Stud/Stud8 (ante+bring-in). **Flop→Stud 전환 시 버튼 freeze** (O8 완료 후 Razz 시작 시 버튼 위치 고정). Stud→Flop 복귀 시 freeze 해제 |
| **판정 기준** | `pot == 0`, `hand_in_progress == false`, `game_phase == IDLE`, `current_game_index == (prev + 1) % 5`, `evaluator_type` 매칭, Flop→Stud 전환 시 `button_frozen == true` |
| **참조** | WSOP Rule 67b, PRD-GAME-01~03 |

### TC-G1-020-02: HORSE 전환 중 진행 핸드

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 3 |
| **우선순위** | P2 |
| **Players** | 6인, stack=10000 |
| **Hole Cards** | P0~P5 각 2장 (Hold'em 진행 중) |
| **Board** | Ks 9h 4d (FLOP 진행 중) |
| **Actions** | Game Engine: HORSE Level 1 Hold'em, FLOP 베팅 진행 중 → Level 전환 타이머 만료 → 전환 신호 수신. P3 Bet(200) → P4 Call(200) → TURN → RIVER → SHOWDOWN → HAND_COMPLETE |
| **기대 결과** | 현재 핸드 **중단 없이 완료**. 전환은 HAND_COMPLETE → IDLE 이후에만 발생. 전환 대기 상태: `pending_game_change=true`, `next_game=omaha_hilo`. 핸드 완료 후: `pending_game_change=false`, `current_game=omaha_hilo` |
| **판정 기준** | 핸드 진행 중 `game_type` 변경 없음, `pending_game_change == true` (전환 신호 수신 시점), HAND_COMPLETE 후 `current_game == omaha_hilo`, `pending_game_change == false` |
| **참조** | PRD-GAME-01 |

> **핵심 검증**: 진행 중 핸드를 절대 중단하지 않는다. 전환 신호는 큐에 저장되고 핸드 완료 후 적용.

### TC-G1-020-03: 8-Game 8종 순환

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 3 |
| **우선순위** | P2 |
| **Players** | 6인, stack=10000 |
| **Hole Cards** | N/A (전환 로직 검증) |
| **Board** | N/A |
| **Actions** | Game Engine: Mix 설정 = 8-Game. PRD-GAME-04 순서: ①2-7 Triple Draw (FL) → ②Hold'em (FL) → ③Omaha Hi-Lo (FL) → ④Razz (FL) → ⑤Stud (FL) → ⑥Stud Hi-Lo (FL) → ⑦NL Hold'em (NL) → ⑧PLO (PL). **6핸드마다 전환** |
| **기대 결과** | 6핸드 완료 시점(현재 핸드 완료 후)에 다음 게임으로 전환. 각 전환 시: `pot=0`, `hand_in_progress=false`, `game_phase=IDLE`. bet_structure: FL→FL→FL→FL→FL→FL→**NL**→**PL**. Flop→Stud 전환 시 **버튼 freeze** (Rule 67b). NL/PL ante: NL = 1.5×BB, PL = BB (FLOP 후에만 pot 포함) |
| **판정 기준** | `game_sequence == [27TD, LH, O8, Razz, Stud, Stud8, NLH, PLO]`, `hand_count_since_change == 6` 시 전환, 각 전환 후 `bet_structure` 매칭, Flop→Stud 전환 시 `button_frozen == true`, Stud→Flop 전환 시 `button_position == frozen_position` |
| **참조** | PRD-GAME-04 §6-4, WSOP Event #73 구조표, WSOP Rule 67b |

> **WSOP 검증 (2026-04-09)**: 전환 트리거 "레벨당"→"6핸드마다" 수정. 버튼 freeze 검증 추가. HORSE = 전부 FL 확인. 8-Game 순서 = PRD-GAME-04 §6-4 기준 채택 (WSOP Event #73 타이틀 순서와 다름 — WSOP는 이벤트별로 순서가 달라질 수 있으며 PRD가 EBS 기준).

### TC-G1-020-04: PPC — 플레이어 선택 전환

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 3 |
| **우선순위** | P2 |
| **Players** | 6인, stack=10000, Dealer=P0 |
| **Hole Cards** | N/A |
| **Board** | N/A |
| **Actions** | CC 트리거: Dealer(P0)가 다음 게임 선택 → `GameChangeRequest(game=razz, requested_by=P0)`. 현재 핸드 완료 대기 → IDLE → 새 게임 적용 |
| **기대 결과** | 다음 핸드부터 Razz 적용. `current_game=razz`, `evaluator_type=ace_to_five`, `bet_structure=fixed_limit`. 전환 전 상태 초기화 완료: `pot=0`, `community_cards=[]`, `player_cards=[]` |
| **판정 기준** | `game_change_source == player_choice`, `current_game == razz`, `effective_from_hand == current_hand_number + 1`, `game_phase == IDLE` (전환 시점) |
| **참조** | PRD-GAME-01~03 |

### TC-G1-020-05: Dealer's Choice 임의 전환

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 3 |
| **우선순위** | P2 |
| **Players** | 6인, stack=10000, Dealer=P2 |
| **Hole Cards** | N/A |
| **Board** | N/A |
| **Actions** | CC 트리거: 현재 게임 = Texas Hold'em → Dealer(P2) 선택 = Badeucy. GameChangeRequest(game=badeucy, requested_by=P2) → 현재 핸드 완료 → IDLE → Badeucy 적용 |
| **기대 결과** | 전환 후: `current_game=badeucy`, `evaluator_type=badeucy`, `hole_cards_count=5`, `draw_rounds=3`. 이전 게임 잔여 상태 = 0: `pot=0`, `bets=[]`, `community_cards=[]`, `player_cards=[]`, `side_pots=[]` |
| **판정 기준** | `pot == 0`, `bets.length == 0`, `community_cards.length == 0`, `player_cards == {} (전원 빈 핸드)`, `side_pots.length == 0`, `current_game == badeucy` |
| **참조** | PRD-GAME-02 Badeucy |

### TC-G1-020-06: Dealer's Choice 동일 게임 연속 선택

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 3 |
| **우선순위** | P2 |
| **Players** | 6인, stack=10000, Dealer=P3 |
| **Hole Cards** | N/A |
| **Board** | N/A |
| **Actions** | CC 트리거: 현재 게임 = Omaha → 핸드 완료 → Dealer(P3) 선택 = Omaha (동일). GameChangeRequest(game=omaha, requested_by=P3) |
| **기대 결과** | 불필요한 리셋 없이 계속. `current_game=omaha` 유지. `evaluator_type=omaha_high` 유지. `game_change_applied=false` (실질적 변경 없음). 새 핸드 정상 시작 (IDLE → SETUP_HAND) |
| **판정 기준** | `current_game == omaha` (변경 전후 동일), `evaluator_type == omaha_high`, `game_reset_triggered == false`, `new_hand_started == true` |
| **참조** | PRD-GAME-01 Omaha |

> **핵심 검증**: 동일 게임 연속 선택 시 불필요한 상태 초기화가 발생하지 않아야 한다. 핸드 간 정상 초기화 (pot=0 등)는 모든 핸드에서 발생하는 기본 동작이며, 게임 전환에 의한 추가 리셋은 불필요.

### TC-G1-020-07: 전체 Mix 전환 후 FSM 상태

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 3 |
| **우선순위** | P2 |
| **Players** | 6인, stack=10000 |
| **Hole Cards** | N/A |
| **Board** | N/A |
| **Actions** | 4종 Mix 유형 각각에서 전환 실행: HORSE (5회 전환), 8-Game (8회 전환), PPC (3회 전환), Dealer's Choice (5회 전환). 각 전환 직후 FSM 상태 스냅샷 |
| **기대 결과** | **모든** 전환 직후: `game_phase == IDLE`. 예외 없음. IDLE이 아닌 상태에서 새 게임이 시작되면 FSM 무결성 위반 |
| **판정 기준** | 모든 전환 시점 (21회)에서 `game_phase == IDLE` 확인. `hand_in_progress == false`. `pot == 0`. `active_players == []` (아직 새 핸드 미시작) |
| **참조** | PRD-GAME-01~03 |

---

## 전체 TC 통계

| TC ID | 시나리오 | Phase | 우선순위 |
|-------|---------|:-----:|:------:|
| TC-G1-020-01 | HORSE 5종 순환 | Phase 3 | P2 |
| TC-G1-020-02 | HORSE 전환 중 핸드 | Phase 3 | P2 |
| TC-G1-020-03 | 8-Game 8종 순환 | Phase 3 | P2 |
| TC-G1-020-04 | PPC 플레이어 선택 | Phase 3 | P2 |
| TC-G1-020-05 | Dealer's Choice 임의 전환 | Phase 3 | P2 |
| TC-G1-020-06 | Dealer's Choice 동일 게임 연속 | Phase 3 | P2 |
| TC-G1-020-07 | 전체 Mix FSM 검증 | Phase 3 | P2 |
