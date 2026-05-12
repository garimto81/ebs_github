---
title: NOTIFY Conductor — Betting_System.md §7-6 v04 deeper game 룰 추가 요청 (BLOCKED meta)
type: notify
from: S8 (Cycle 7 spec)
to: Conductor (BLOCKED meta 파일 수정 권한 보유)
status: pending
priority: P1
created: 2026-05-12
related-issue: 327
related-cycle: 7
target-file: docs/1. Product/Game_Rules/Betting_System.md
target-section: §7-6 Deeper Game Rules (신규)
related-specs:
  - docs/2. Development/2.3 Game Engine/Rules/Bomb_Pot.md
  - docs/2. Development/2.3 Game Engine/Rules/Seven_Deuce.md
  - docs/2. Development/2.3 Game Engine/Rules/Run_It_Three.md
---

# NOTIFY Conductor — Betting_System.md §7-6 deeper game 룰 추가

## 배경

S8 Cycle 7 v04 (#327) 의 Acceptance Criteria 1 = "Betting_System.md §7-6 bomb_pot 명세". `docs/1. Product/Game_Rules/Betting_System.md` 는 S8 의 `meta_files_blocked` 목록에 포함되어 S8 가 직접 수정 불가. Conductor 에게 §7-6 신설을 요청한다.

본 NOTIFY 는 §7-6 본문 후보를 첨부하여 Conductor 가 그대로 또는 편집 후 적용할 수 있도록 한다.

---

## 1. 신규 §7-6 후보 본문

> Game_Rules 는 Confluence 발행 규칙 (markdown 링크 금지, 다른 문서명 언급 금지, 독립 완결). 아래는 그 규칙 준수 후보.

```markdown
## §7-6 Deeper Game Rules — 변형 베팅 옵션

표준 hold'em 베팅 위에 선택 활성화 가능한 변형 룰. 각각 operator 또는 dealer 가
다음 핸드 시작 전에 활성화하며, 단발성 (매 핸드 새로 활성화 필요).

### §7-6.1 Bomb Pot

**정의**: 다음 핸드 시작 시 모든 active player 가 사전에 합의된 금액 (bombPotAmount)
을 강제로 ante 로 납부하고, preflop 베팅 라운드를 건너뛰어 곧바로 flop 으로 진입한다.

**활성화**: operator 가 다음 핸드 시작 전에 금액 (양의 정수) 을 지정. 금액이
0 이하인 경우 활성화 거부.

**핸드 진행**:
1. ante 단계 직후, 모든 active/all-in seat 으로부터 bombPotAmount 만큼을 강제
   pot 적립. stack 부족 시 보유 stack 전액을 적립하고 all-in 상태로 전환.
2. SB / BB blind 미부과.
3. preflop 베팅 라운드 미진행.
4. street 을 flop 으로 직접 설정. first-to-act 는 dealer 좌측 첫 active seat.
5. 이후 flop / turn / river / showdown 은 표준 hold'em 룰과 동일.

**자동 해제**: 핸드 종료 시 bomb pot 활성화 상태는 자동 해제. 다음 핸드에도
bomb pot 을 적용하려면 operator 가 재활성화해야 한다.

### §7-6.2 Seven-Deuce Side Bet

**정의**: showdown winner 가 7 과 2 의 offsuit hole cards (서로 다른 suit) 를
보유한 경우, 각 non-folded 패자가 사전에 합의된 금액 (sevenDeuceAmount) 만큼
winner 에게 추가 지불한다.

**적용 조건** (모두 충족):
- winner 의 hole cards 가 정확히 2 장 (hold'em 계열 한정)
- hole cards rank 가 {7, 2}
- hole cards suit 가 서로 다름 (offsuit)
- winner 가 양의 pot 을 수령

**산출**:
- winner 1 인의 보너스 = sevenDeuceAmount × (non-folded 패자 수)
- 각 패자가 부담하는 금액 = sevenDeuceAmount × (보너스 수령 winner 수)
- 패자 stack 부족 시 받는 winner 들의 보너스를 비례 차감.

**Split pot**: 양쪽 winner 가 모두 7-2 offsuit 인 경우, 각자 보너스 수령 +
각 패자가 winner 2 인 분의 보너스 부담.

### §7-6.3 Run It Three

**정의**: 전원 all-in 후 river 시점에서 RIT2 (run it twice) 의 자연 확장.
잔여 community runout 을 3 번 반복하여 pot 을 3 분할 한다.

**적용 조건**:
- river deal 완료 시점 (community = 5 cards) 이고 모든 잔존 player 가 all-in
- variant 가 hold'em 계열 (NLH / PLH / FLH 등)
- 모든 all-in player 가 RIT3 에 합의

**진행**:
1. 기존 community (flop 3 + turn + river) 를 board 1 으로 보존.
2. flop 3 장은 board 1 / 2 / 3 가 공유.
3. board 2 의 turn / river 2 장을 deck 에서 새로 deal.
4. board 3 의 turn / river 2 장을 deck 에서 새로 deal.
5. pot 을 3 분할: board 1 / 2 / 3 각 1 / 3. 나머지 odd chip 은 board 1 흡수.
6. 각 board 별 winners 산출 후 awards 합산하여 stack 적립.

**Side pot**: 각 side pot 도 동일하게 3 분할. eligible seat 집합 보존.

### §7-6.4 정합

§7-6 의 3 룰은 표준 §7-1 ~ §7-5 베팅 룰과 독립 동작. bomb pot 활성화 시
preflop 미진행이므로 straddle (§7-3) 미적용 — 양립 불가.
```

---

## 2. 적용 권장 위치

`docs/1. Product/Game_Rules/Betting_System.md` 의 §7-5 (Cycle 4 mediation 9 keys default 패치) **다음** 위치. §7-6 으로 신설.

---

## 3. 적용 후속 작업

| 항목 | 책임 | 비고 |
|------|------|------|
| Conductor 적용 | Conductor | 위 §1 본문 적용 (or 편집 후 적용) |
| derivative-of 링크 갱신 | S10-A | `Bomb_Pot.md` / `Seven_Deuce.md` / `Run_It_Three.md` frontmatter 에 `derivative-of: ../../1. Product/Game_Rules/Betting_System.md#7-6` 추가 (또는 reverse: Betting_System.md 가 derive 받는 형태로 결정) |
| spec_drift_check | S10-A | §7-6 의 새 키워드 (`bomb_pot`, `seven_deuce`, `run_it_three`) 가 Engine_Defaults.md §1 의 키와 매핑되는지 검증 |
| Confluence 발행 | conductor 또는 docs stream | `--con` skill 로 page upload |

---

## 4. 정합 기준 (Engine SSOT)

본 NOTIFY 의 §1 본문은 다음 Engine SSOT 와 정합:

| Game_Rules 표현 | Engine SSOT |
|----------------|-------------|
| "bombPotAmount" | `GameState.bombPotAmount` (game_state.dart:45) |
| "sevenDeuceAmount" | `GameState.sevenDeuceAmount` (game_state.dart:49) |
| "RIT3" | `GameState.runItTimes == 3` + `runItBoard3Cards` (game_state.dart:52,54) |
| "non-folded 패자" | `seats.where(!s.isFolded && s.holeCards.notEmpty)` |
| "비례 차감" | `Rules/Seven_Deuce.md` §2.2 algorithm |
| "1/3 분할 + odd chip board1" | `Rules/Run_It_Three.md` §2.3 convention |

충돌 시 우선순위:
1. Engine 코드 정본
2. `docs/2.3 Game Engine/Rules/*.md` (Engine derive snapshot)
3. `Game_Rules/Betting_System.md` §7-6 (사용자 외부 인계 표현)

---

## 5. 진행 상태

| 항목 | 상태 | 일자 |
|------|:----:|------|
| S8 §7-6 본문 후보 작성 | ✅ 완료 | 2026-05-12 |
| Conductor 에 NOTIFY 전달 | ✅ 완료 (본 파일) | 2026-05-12 |
| Conductor §7-6 적용 결정 | ⏳ pending | TBD |
| Confluence 발행 | ⏳ pending | TBD |
| spec_drift_check pass | ⏳ pending | TBD |
