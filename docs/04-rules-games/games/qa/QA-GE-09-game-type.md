# QA-GE-09 — game_type 8종 검증

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Master Plan §8.10 확장 — game_type 8종 TC 상세화 v1.0.0 |

---

## 개요

Game Engine의 game_type 8종(Cash, Regular, Bounty, Mystery, Flip, Shootout, Satellite, SNG)이 핸드 진행, 토너먼트 로직, 특수 규칙에 미치는 영향을 검증한다.

---

## game_type 매트릭스

| game_type | 값 | 블라인드 상승 | 리바이 | 탈락 처리 | 특수 로직 | Phase | 우선순위 |
|:---------:|:--:|:----------:|:-----:|:--------:|----------|:-----:|:------:|
| Cash | 0 | 없음 | 없음 | 자발적 퇴장 | 없음 | Phase 1 | P0 |
| Regular | 1 | 자동 (레벨) | 없음 | 스택 0 → bust | 블라인드 타이머 | Phase 2 | P1 |
| Bounty | 2 | 자동 | 없음 | bust → 바운티 지급 | bounty_amount 고정 | Phase 2 | P1 |
| Mystery | 3 | 자동 | 없음 | bust → 랜덤 바운티 | bounty_range (min~max) | Phase 2 | P1 |
| Flip | 4 | 자동 | 없음 | bust | PRE_FLOP 전원 All-In 강제 | Phase 3 | P2 |
| Shootout | 5 | 자동 | 없음 | bust (최종 1인 제외) | 테이블 승자 진출 | Phase 3 | P2 |
| Satellite | 6 | 자동 | 없음 | bust | 상위 N명 티켓 | Phase 3 | P2 |
| SNG | 7 | 자동 | 없음 | bust | 등록 완료 즉시 시작 | Phase 3 | P2 |

---

## TC 목록

### TC-G1-008-01: Cash 게임

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 1 |
| **우선순위** | P0 |
| **Players** | 6인 (P0~P5), stack=10000, BB=100, SB=50, Dealer=P0 |
| **Hole Cards** | P0: As Kd, P1: Qh Jh, P2: 9c 8c, P3: 7s 6s, P4: Td Tc, P5: 2h 3d |
| **Board** | Ks 9h 4d 7c 2s |
| **Actions** | 정상 핸드 1회 진행. PRE_FLOP~SHOWDOWN. P0 승리 (pair of Kings). 핸드 완료 후 다음 핸드 시작 |
| **기대 결과** | 핸드 완료 후: 리바이/애드온 UI 없음. 스택 변동만 반영 (승자 +pot, 패자 -bet). `blind_level` 변경 없음. `game_type == 0`. `rebuy_allowed == false`. `addon_allowed == false`. 다음 핸드 정상 시작 (Dealer 이동) |
| **판정 기준** | `game_type == 0`, `blind_level_changed == false`, `rebuy_allowed == false`, `addon_allowed == false`, `P0.stack == initial + pot_won`, `dealer_position == (prev + 1)` |
| **참조** | PRD-GAME-04, BS-06-00-REF |

### TC-G1-008-01a: Cash 게임 — 칩 소진 퇴장

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 1 |
| **우선순위** | P0 |
| **Players** | 6인, P5: stack=100 (BB만큼), BB=100, SB=50 |
| **Hole Cards** | P5: 2h 3d (기타 플레이어 임의) |
| **Board** | N/A |
| **Actions** | P5 BB 포스팅 (100) → PRE_FLOP: P5 All-In (잔여 0) → P5 패배 |
| **기대 결과** | P5 stack=0. Cash 게임이므로 bust out이 아닌 **자발적 퇴장/리바이 선택**. `P5.eliminated == false` (토너먼트 탈락과 구분). `P5.status == sitting_out` 또는 퇴장. 다음 핸드: P5 제외 5인 진행 |
| **판정 기준** | `P5.stack == 0`, `P5.eliminated == false`, `P5.status != busted`, `active_players.length == 5` (다음 핸드) |
| **참조** | PRD-GAME-04 |

### TC-G1-008-02: Regular 토너먼트

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인 (P0~P5), stack=10000, Level 1: BB=100/SB=50, Level 2: BB=200/SB=100 |
| **Hole Cards** | N/A (블라인드 상승 로직 검증) |
| **Board** | N/A |
| **Actions** | Game Engine: Level 1 (BB=100) 핸드 진행 → 15분 타이머 만료 → Level 2 전환 신호. 다음 핸드에서 BB=200 적용 |
| **기대 결과** | Level 전환: `blind_level == 2`, `bb == 200`, `sb == 100`. 전환은 핸드 완료 후 적용. `game_type == 1`. 탈락 조건: stack=0 → `eliminated == true` |
| **판정 기준** | `game_type == 1`, `blind_level == 2`, `bb == 200`, `sb == 100`, `level_change_applied_at == hand_complete` |
| **참조** | PRD-GAME-04 |

### TC-G1-008-02a: Regular — 핸드 진행 중 레벨 변경

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인, Level 1: BB=100, 핸드 진행 중 (FLOP) |
| **Hole Cards** | 임의 |
| **Board** | FLOP 진행 중 |
| **Actions** | FLOP 베팅 중 Level 전환 타이머 만료 → 전환 신호 수신. 현재 핸드 BB=100 유지 → SHOWDOWN → HAND_COMPLETE → 다음 핸드 BB=200 |
| **기대 결과** | 현재 핸드: `bb == 100` 유지 (변경 없음). `pending_level_change == true`. 핸드 완료 후: `bb == 200`, `pending_level_change == false` |
| **판정 기준** | 핸드 진행 중 `bb == 100` (불변), HAND_COMPLETE 후 `bb == 200`, `level_change_mid_hand == false` |
| **참조** | PRD-GAME-04 |

### TC-G1-008-03: Bounty 토너먼트

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인, stack=10000, BB=100, bounty_amount=500 |
| **Hole Cards** | P0: As Ad, P5: 2h 3d |
| **Board** | Ks 9h 4d 7c 2s |
| **Actions** | PRE_FLOP: P5 All-In(10000) → P0 Call(10000) → 나머지 Fold. SHOWDOWN: P0 승리 (pair of Aces > pair of 2s). P5 stack=0, eliminated |
| **기대 결과** | P5 탈락. P0에게 바운티 지급: `P0.bounty_earned += 500`. `P5.eliminated == true`. `P5.eliminator == P0`. `bounty_amount == 500` (고정). `game_type == 2` |
| **판정 기준** | `game_type == 2`, `P5.eliminated == true`, `P5.eliminator == P0`, `P0.bounty_earned == 500`, `bounty_amount == 500` |
| **참조** | PRD-GAME-04 |

### TC-G1-008-04: Mystery Bounty

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인, stack=10000, BB=100, bounty_range: min=100, max=10000 |
| **Hole Cards** | P0: As Ad, P5: 2h 3d |
| **Board** | Ks 9h 4d 7c 2s |
| **Actions** | P5 All-In → P0 Call → P0 승리. P5 탈락 → 랜덤 바운티 금액 결정 |
| **기대 결과** | P5 탈락. 바운티 금액 `bounty_awarded`는 `bounty_range.min(100) <= bounty_awarded <= bounty_range.max(10000)` 범위 내. `P0.bounty_earned += bounty_awarded`. `game_type == 3` |
| **판정 기준** | `game_type == 3`, `P5.eliminated == true`, `100 <= bounty_awarded <= 10000`, `P0.bounty_earned == bounty_awarded` |
| **참조** | PRD-GAME-04 |

### TC-G1-008-05: Flip

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 3 |
| **우선순위** | P2 |
| **Players** | 6인 (P0~P5), stack=10000, BB=100, SB=50 |
| **Hole Cards** | P0: As Kd, P1: Qh Jh, P2: 9c 8c, P3: 7s 6s, P4: Td Tc, P5: 2h 3d |
| **Board** | Ks 9h 4d 7c 2s |
| **Actions** | SETUP_HAND → PRE_FLOP: **전원 자동 All-In** (액션 버튼 비활성화). 보드 전개 (FLOP → TURN → RIVER) → SHOWDOWN |
| **기대 결과** | PRE_FLOP에서 전원 All-In 강제. `action_buttons_enabled == false`. 플레이어 선택 불가 (Fold/Call/Raise 없음). SHOWDOWN: 최종 승자 결정. `game_type == 4`. 패자 전원: `eliminated == true` (스택 0인 플레이어) |
| **판정 기준** | `game_type == 4`, `all_players_allin == true` (PRE_FLOP 직후), `action_buttons_enabled == false`, `betting_rounds_with_action == 0` (자동 All-In만), `winner.stack == sum(all_stacks)` |
| **참조** | PRD-GAME-04 |

### TC-G1-008-06: Shootout

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 3 |
| **우선순위** | P2 |
| **Players** | 6인 (P0~P5), stack=10000, BB=100 |
| **Hole Cards** | N/A (다수 핸드 진행) |
| **Board** | N/A |
| **Actions** | 복수 핸드 진행. P5 탈락 → P3 탈락 → P2 탈락 → P1 탈락 → P4 탈락. P0 최종 승자 |
| **기대 결과** | P0만 잔여. `P0.status == table_winner`. `P0.advance_to_next_round == true`. P1~P5: `eliminated == true`. `game_type == 5`. 테이블 완료 시: `table_status == completed`, `table_winner == P0` |
| **판정 기준** | `game_type == 5`, `table_winner == P0`, `P0.advance_to_next_round == true`, `eliminated_count == 5`, `table_status == completed` |
| **참조** | PRD-GAME-04 |

### TC-G1-008-07: Satellite

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 3 |
| **우선순위** | P2 |
| **Players** | 6인 (P0~P5), stack=10000, BB=100, ticket_seats=2 (상위 2명 티켓) |
| **Hole Cards** | N/A (다수 핸드 진행) |
| **Board** | N/A |
| **Actions** | 복수 핸드 진행. P5 탈락 (6th) → P3 탈락 (5th) → P2 탈락 (4th) → P1 탈락 (3rd). 잔여: P0, P4 (2명 = ticket_seats) |
| **기대 결과** | P1 탈락 시점(4번째 탈락, 잔여 2명 = ticket_seats): 게임 종료. P0, P4에게 티켓 지급. `P0.ticket_awarded == true`, `P4.ticket_awarded == true`. `game_type == 6`. `game_status == completed` |
| **판정 기준** | `game_type == 6`, `remaining_players == ticket_seats` (종료 조건), `P0.ticket_awarded == true`, `P4.ticket_awarded == true`, `P1.ticket_awarded == false`, `game_status == completed` |
| **참조** | PRD-GAME-04 |

> **핵심 검증**: 잔여 인원이 `ticket_seats`와 동일해지는 시점에 게임 자동 종료. 잔여 플레이어 전원에게 동등 티켓.

### TC-G1-008-08: SNG

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 3 |
| **우선순위** | P2 |
| **Players** | 6인 (P0~P5), stack=5000, BB=50, SB=25 |
| **Hole Cards** | N/A |
| **Board** | N/A |
| **Actions** | 등록: 6명 등록 완료 (max_players=6). Game Engine: 즉시 시작 (대기 없음). 정상 핸드 진행 → 블라인드 자동 상승 (Regular와 동일) |
| **기대 결과** | `registered_players == max_players` 충족 즉시 `game_status == in_progress`. 시작 대기 없음 (`start_delay == 0`). 이후 Regular 토너먼트와 동일: 블라인드 상승, 탈락 처리. `game_type == 7` |
| **판정 기준** | `game_type == 7`, `start_trigger == registration_full`, `start_delay == 0`, `blind_auto_increase == true`, `registered_players == max_players` |
| **참조** | PRD-GAME-04 |

---

## 전체 TC 통계

| TC ID | 시나리오 | Phase | 우선순위 |
|-------|---------|:-----:|:------:|
| TC-G1-008-01 | Cash 게임 | Phase 1 | P0 |
| TC-G1-008-01a | Cash 칩 소진 | Phase 1 | P0 |
| TC-G1-008-02 | Regular 토너먼트 | Phase 2 | P1 |
| TC-G1-008-02a | Regular 레벨 변경 | Phase 2 | P1 |
| TC-G1-008-03 | Bounty | Phase 2 | P1 |
| TC-G1-008-04 | Mystery Bounty | Phase 2 | P1 |
| TC-G1-008-05 | Flip | Phase 3 | P2 |
| TC-G1-008-06 | Shootout | Phase 3 | P2 |
| TC-G1-008-07 | Satellite | Phase 3 | P2 |
| TC-G1-008-08 | SNG | Phase 3 | P2 |
