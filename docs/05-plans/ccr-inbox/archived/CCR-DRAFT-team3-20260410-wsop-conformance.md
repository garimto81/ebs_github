# CCR-DRAFT: WSOP LIVE 공식 규칙 준수 — Engine 기획서 18건 수정 제안

- **제안팀**: team3
- **제안일**: 2026-04-10
- **영향팀**: [team4]
- **변경 대상 파일**:
  - `team3-engine/specs/engine-spec/engine-spec/BS-06-00-REF-game-engine-spec.md`
  - `team3-engine/specs/engine-spec/engine-spec/BS-06-01-holdem-lifecycle.md`
  - `team3-engine/specs/engine-spec/engine-spec/BS-06-02-holdem-betting.md`
  - `team3-engine/specs/engine-spec/engine-spec/BS-06-03-holdem-blinds-ante.md`
  - `team3-engine/specs/engine-spec/engine-spec/BS-06-07-holdem-showdown.md`
  - `team3-engine/specs/engine-spec/engine-spec/BS-06-08-holdem-exceptions.md`
  - `team3-engine/specs/engine-spec/engine-spec/BS-06-09-event-catalog.md`
- **변경 유형**: modify
- **변경 근거**: WSOP LIVE Confluence 미러(`C:\claude\wsoplive\docs\confluence-mirror\`)의 공식 규칙(Rules 56, 71, 74, 78, 81, 86, 87, 89, 95, 96, 100, 101, 109, 110)과 현재 BS-06 기획서를 교차 비교하여 18건의 규정 불일치를 발견. 방송 포커 엔진의 WSOP conformance 확보를 위해 수정 제안.

## 변경 요약

WSOP LIVE 프로덕션에서 운영 중인 공식 Hold'em/Live Action Rules 14개를 EBS engine 기획서(BS-06 시리즈 Hold'em 코어)에 반영한다. 주요 변경은 다음과 같다:

1. **P0 CRITICAL (3건)** — 현재 EBS 코드와 기획서 모두 WSOP 규정 위반:
   - Rule 96 all-in below min raise action reopen 금지 누락
   - Rule 95 under-raise 50% rule 누락
   - Rule 100 heads-up raise cap "토너먼트 전체 2명" vs "핸드 내 2명" 오해석
2. **P1 HIGH (5건)** — 주요 운영 규칙 누락:
   - Rule 87 heads-up button 조정, Rule 28.3.2 bomb pot button freeze, Mixed Omaha button freeze, Rule 89 four-card flop 복구, Rule 71/110 tabled hand 보호 & folded hand 복구
3. **P2 MEDIUM (6건)**, **P3 LOW (4건)** — 품질·일관성·참조

## 제안 개요

| Priority | 개수 | 주요 Rule | 영향 파일 |
|:--------:|:----:|-----------|----------|
| 🔴 P0 CRITICAL | 3 | Rule 95, 96, 100 | BS-06-02, BS-06-00-REF |
| 🟠 P1 HIGH | 5 | Rule 28.3.2, 71, 87, 89, 110 + Mixed Omaha | BS-06-00-REF, BS-06-01, BS-06-03, BS-06-07, BS-06-08, BS-06-09 |
| 🟡 P2 MEDIUM | 6 | Rule 56, 78, 81, 86, 101, 109 | BS-06-00-REF, BS-06-01, BS-06-02, BS-06-03, BS-06-07, BS-06-08 |
| 🟢 P3 LOW | 4 | Rule 28.3.1, 62, 80-83, 88 | BS-06-01, BS-06-02, BS-06-08, BS-06-09 |

신규 State 필드(총 9개), 신규 이벤트(2개), 신규 섹션(9개)을 포함한다.

---

## Part A: P0 CRITICAL — WSOP 공식 규정 위반 (즉시 수정)

### P0-1. Rule 96 누락 — All-in Below Min Raise의 Action Reopen 금지

**WSOP Rule 96 (verbatim, 2022 Korean Translation)**:
> 노 리밋 및 팟 리밋에서 모든 레이즈는 이전 베팅 또는 해당 베팅 라운드의 레이즈 크기와 같거나 커야 합니다. **전체 레이즈 미만의 올인 베팅은 이미 행동한 참가자에게 베팅을 재개하지 않습니다.**

**BS-06-02 현재 상태**:
- §5 ALL-IN 섹션은 기본 정의만 존재 (`allInAmount = seat.stack`)
- `allin_size < min_raise_size` 예외 처리 규정 **명시 없음**
- 참조 코드: `ebs_game_engine/lib/core/rules/betting_rules.dart:170-186`
  * `case AllIn()` 내부에서 무조건 `betting.actedThisRound = {seatIndex}` (줄 185)
  * 즉 **모든 all-in이 action reopen**을 발생시킴 → WSOP 규정 정면 위반

**문제점**:
1. FL(Fixed Limit) 게임에서 under-full all-in이 무한 action reopen 유발 가능
2. NL 게임에서 short stack player의 incomplete all-in을 이미 행동한 플레이어가 다시 raise 할 수 있게 됨 (불공정)
3. 코드 계약 테스트 GAP-003 관련 contract test와 간접 충돌

**제안 변경 (BS-06-02 §5 "ALL-IN" 하위에 §5.3 신설)**:

```diff
  ## 5. ALL-IN
  
  (기존 §5.1, §5.2 유지)
  
+ ### 5.3 All-in Below Minimum Raise (Rule 96)
+ 
+ **원칙**: NL/PL 게임에서 all-in 금액이 min_raise 미만인 경우, 해당 베팅 라운드의
+ 이미 행동한 플레이어에게 action을 재개하지 않는다 (WSOP Official Live Action Rules Rule 96).
+ 
+ #### 5.3.1 분기 조건
+ 
+ ```
+ allin_size = seat.stack  // all-in 금액
+ previous_bet = betting.currentBet  // 이전 베팅 금액
+ current_bet = seat.currentBet  // 이미 낸 bet
+ raise_to = current_bet + allin_size  // all-in 후 total bet
+ raise_increment = raise_to - previous_bet  // 실제 raise 증가분
+ 
+ if raise_increment >= betting.minRaise:
+     # Full raise → action reopen (기존 동작 유지)
+     betting.actedThisRound = {seat.index}
+     betting.lastAggressor = seat.index
+     betting.minRaise = raise_increment
+     betting.currentBet = raise_to
+     betting.raiseCount += 1
+ else:
+     # Incomplete all-in (Rule 96)
+     # → call matching만 수행, action 재개 금지
+     betting.currentBet = max(betting.currentBet, raise_to)
+     # 아래 3개는 변경하지 않음:
+     #   betting.actedThisRound  (기존 유지 → 이미 행동한 플레이어 재행동 없음)
+     #   betting.lastAggressor   (기존 aggressor 지위 유지)
+     #   betting.minRaise        (기존 raise 기준선 유지)
+     # 이 플레이어는 acted로 기록
+     betting.actedThisRound.add(seat.index)
+ ```
+ 
+ #### 5.3.2 예시
+ 
+ **상황**: NLH, BB=10, 3인 핸드
+ - P1 open raise to 30 (previous_bet=30, minRaise=20)
+ - P2 call 30
+ - P3 all-in 45 (stack=45)
+ 
+ **raise_increment 계산**: 45 - 30 = 15
+ **비교**: 15 < 20 (minRaise) → **Incomplete all-in (Rule 96)**
+ 
+ **결과**:
+ - betting.currentBet = 45
+ - betting.actedThisRound 유지: {P1, P2, P3} (P1/P2는 재행동 기회 없음)
+ - P3는 acted 상태
+ - P1과 P2는 call 45로 매칭만 가능, raise 옵션 없음
+ - 액션 라운드 종료 → Flop 진행
+ 
+ **반면 만약 P3 all-in 50**이었다면:
+ - raise_increment = 50 - 30 = 20 ≥ 20 (minRaise) → **Full raise**
+ - betting.actedThisRound = {P3}
+ - P1, P2에게 call/fold/re-raise 옵션 열림 (reopen)
+ 
+ #### 5.3.3 FL(Fixed Limit) 게임 적용
+ 
+ FL 게임에서는 raise 증가분이 고정(`low_limit` 또는 `high_limit`)이므로 
+ incomplete all-in은 raise_increment < fixed_raise_amount 조건으로 판별한다.
+ Rule 100.b의 raise cap은 본 규정과 독립적으로 적용됨 (P0-3 §4.5 참조).
+ 
+ #### 5.3.4 Side Pot 연동
+ 
+ Incomplete all-in은 여전히 side pot을 생성한다 (`Pot.calculateSidePots()` 호출).
+ Action reopen 금지와 side pot 생성은 별도 규정이며 병행 적용.
```

**영향**:
- **코드 수정 필수** (Phase 1 완료 후 별도 세션):
  * `betting_rules.dart:170-186` `case AllIn()` 분기 로직 추가
  * 신규 테스트 `test/all_in_below_min_raise_test.dart`
- **계약 영향 없음**: OutputEvent 시그니처 변경 없음
- **기획서만 변경 시 기존 코드는 WSOP 비준수 상태 유지** → Phase 1은 기획서 + 코드 동시 또는 근접 시점에 반영 권장

---

### P0-2. Rule 95 누락 — Under-raise 50% Rule

**WSOP Rule 95 (verbatim, 2022 Korean Translation)**:
> 참가자가 이전 베팅의 50% 이상이지만 최소 인상액보다 적은 레이즈를 걸면 **전체 레이즈를 해야 합니다.** 레이즈는 정확히 허용된 미니멈 레이즈가 될 것입니다. 참가자가 이전 금액의 50% 미만으로 레이즈를 하면 **대신 콜을 해야 합니다.**

**BS-06-02 현재 상태**:
- §4 RAISE에서 `min_raise_total` 정의만 있음
- 불법 raise 입력(min_raise 미만이지만 call보다 큰 금액)에 대한 처리 규정 **없음**
- 참조 코드: `betting_rules.dart:147-156` `case Raise()`
  * `final rawIncrement = toAmount - seat.currentBet;`
  * `final increment = rawIncrement.clamp(0, seat.stack);` → **silent clamp** (규정 없이 임의 처리)

**문제점**:
1. CC에서 잘못된 raise 금액 입력 시 silent clamp로 플레이어 의도와 다른 동작 발생
2. WSOP 공식 규정인 50% rule을 엔진이 알지 못해, 수동 판정(Staff/Floor)과 엔진 판정이 불일치
3. 외부 API(테스트 harness, 외부 시뮬레이터)가 잘못된 raise를 보낼 때 검증 부재

**제안 변경 (BS-06-02 §4 "RAISE"에 §4.4 신설)**:

```diff
  ## 4. RAISE
  
  (기존 §4.1 ~ §4.3 유지: min_raise_total 정의, FL 고정 금액, 유효성 검증)
  
+ ### 4.4 Under-raise 처리 (Rule 95)
+ 
+ **원칙**: CC가 제출한 raise 금액이 `min_raise_total` 미만인 경우, 
+ 해당 금액이 이전 raise의 50% 이상인지에 따라 분기한다 
+ (WSOP Official Live Action Rules Rule 95).
+ 
+ #### 4.4.1 분기 로직
+ 
+ ```
+ requested_raise_to = action.toAmount
+ previous_bet = betting.currentBet
+ previous_raise_increment = betting.minRaise  // 이전 raise의 크기
+ requested_increment = requested_raise_to - previous_bet
+ 
+ if requested_raise_to >= min_raise_total:
+     # 정상 raise → 그대로 수락
+     apply_raise(requested_raise_to)
+ 
+ elif requested_increment >= previous_raise_increment * 0.5:
+     # 50% rule: Full raise 강제
+     apply_raise(min_raise_total)  # 자동 보정
+     # CC에 경고 로그: "raise amount adjusted to min_raise per Rule 95"
+ 
+ else:
+     # 50% 미만 → Call로 변환
+     apply_call()
+     # CC에 경고 로그: "raise amount too small, converted to call per Rule 95"
+ ```
+ 
+ #### 4.4.2 예시
+ 
+ **상황**: NLH, BB=10, 핸드 진행 중
+ - P1 bet 20 (previous_bet=20, minRaise=20)
+ - P2 raise to 50 (previous_bet=50, minRaise=30, previous_raise_increment=30)
+ - P3 요청: raise to 65
+ 
+ **판정**:
+ - `requested_increment = 65 - 50 = 15`
+ - `min_raise_total = 50 + 30 = 80`
+ - 65 < 80 → 정상 raise 아님
+ - `15 >= 30 * 0.5 = 15` → Full raise 강제
+ - 자동 보정: raise to **80**
+ 
+ **반면 P3가 55 요청**이었다면:
+ - `requested_increment = 5`
+ - `5 < 30 * 0.5 = 15` → **Call로 변환**
+ - P3 call 50
+ 
+ #### 4.4.3 UI 계층 정책
+ 
+ CC의 raise 슬라이더는 기본적으로 `[min_raise_total, max_raise_total]` 범위만 
+ 허용하여 이 상황이 일반적으로 발생하지 않는다. 본 규정은:
+ - 외부 API(harness, 시뮬레이터)에서 임의 금액을 제출할 때
+ - CC UI가 수동 입력 모드(advanced mode)에서 사용자가 bypass 할 때
+ - 하드웨어 RFID 칩 카운트 오인식으로 잘못된 금액이 감지될 때
+ 
+ 위 경우에 엔진이 자동으로 Rule 95를 적용해 일관된 판정을 보장한다.
+ 
+ #### 4.4.4 All-in 예외
+ 
+ 플레이어가 stack 전체를 push한 경우 (amount == stack)는 본 규정이 아닌 
+ §5.3 All-in Below Minimum Raise (Rule 96)를 적용한다.
```

**영향**:
- **코드 수정**: `betting_rules.dart:147-156` `case Raise()` 분기 로직 추가
- **신규 테스트**: `test/under_raise_50_percent_test.dart`
- **CC UI 영향**: 없음 (엔진이 자동 보정, CC는 경고 로그만 수신)

---

### P0-3. Rule 100 해석 모호 — Heads-up Raise Cap 경계

**WSOP Rule 100 (verbatim, 2022 Korean Translation)**:
> a. 노 리밋 및 팟 리밋 게임에서는 레이즈 횟수에 제한이 없습니다. 
> b. 제한 이벤트에서는 손에 두 명의 참가자만 남아 있더라도 최대 1회의 베팅과 4회의 레이즈가 가능합니다. **토너먼트가 헤즈업이 되면(즉, 전체 토너먼트에 두 명의 참가자만 남음) 이 규칙이 적용되지 않습니다.** 헤즈업 레벨에서 무제한 인상이 있을 수 있습니다.

**BS-06-02 현재 상태**:
- "raise_count < cap (기본 4회)" 정의
- "또는 num_active_players == 2 (heads-up, cap 무시)" 명시 → **핸드 내 2명** 기준으로 해석
- 참조 코드: `betting_rules.dart:102-104`
  ```dart
  final activeCount = state.seats.where((s) => s.isActive).length;
  if (activeCount <= 2) return true;
  ```

**문제점**:
- WSOP Rule 100.b는 **"전체 토너먼트에 2명만 남은 상태"** 를 의미
- EBS는 **"핸드 내 2명"** 으로 오해석 중 (FL 10인 테이블에서 8명 폴드 → 2명 남음 시 현재 EBS는 cap 무시 → **규정 위반**)
- 캐시 게임 FL: 항상 핸드 내 2명 이상이므로 cap 유지해야 하는데, 오해석 시 cap 무시됨

**제안 변경**:

#### (1) BS-06-00-REF Ch1 State Fields 확장

```diff
  ## Ch1. State Model
  
  ### Game-level State
  
  | 필드 | 타입 | 기본 | 설명 |
  |------|------|------|------|
  (기존 필드들 유지)
+ | tournament_heads_up | bool | false | 전체 토너먼트에 2명만 남은 상태 (Rule 100.b). FL raise cap 무제한 적용 기준. |
```

#### (2) BS-06-02 §4 RAISE §4.5 신설

```diff
+ ### 4.5 Raise Cap 적용 (Rule 100)
+ 
+ **원칙**: FL 게임의 raise cap은 **"핸드 내 플레이어 수"** 가 아닌 
+ **"전체 토너먼트의 남은 플레이어 수"** 로 판단한다 
+ (WSOP Official Live Action Rules Rule 100.b).
+ 
+ #### 4.5.1 판정 표
+ 
+ | 게임 형식 | 핸드 내 2명 | 핸드 내 3명+ | 전체 토너먼트 2명 |
+ |-----------|:----------:|:-----------:|:---------------:|
+ | NL (No-Limit) | 무제한 | 무제한 | 무제한 |
+ | PL (Pot-Limit) | 무제한 | 무제한 | 무제한 |
+ | FL (Fixed-Limit) | **cap 적용** (1 bet + 4 raises) | cap 적용 | **cap 무제한** |
+ | Spread Limit | cap 적용 | cap 적용 | cap 무제한 |
+ 
+ #### 4.5.2 State 필드
+ 
+ 엔진은 `state.tournament_heads_up: bool` 필드를 참조하여 판정한다.
+ 
+ ```
+ can_raise(state, limit):
+     if limit.raise_cap is None:
+         return True  # NL/PL은 항상 무제한
+     
+     # FL/Spread: raise cap 존재
+     if state.tournament_heads_up:
+         return True  # 토너먼트 2인 → cap 무시 (Rule 100.b 단서)
+     
+     # 캐시 게임 또는 핸드 내 2명 이상 → cap 적용
+     return state.betting.raise_count < limit.raise_cap
+ ```
+ 
+ #### 4.5.3 캐시 게임 특수 규정
+ 
+ **캐시 게임 heads-up**은 `tournament_heads_up`가 항상 false이므로 본 규정상 
+ cap 적용된다. 단, House 설정으로 "캐시 heads-up uncapped" 옵션을 제공할 수 있으며, 
+ 이 경우 별도 필드 `cash_heads_up_uncapped: bool`를 추가해 우회 가능 
+ (P3 선택 항목으로 분리).
+ 
+ #### 4.5.4 `tournament_heads_up` 필드 설정 주체
+ 
+ - **BO (Backoffice)**: 토너먼트 생성 시 player 수 추적 → 2명 도달 시 
+   WebSocket 이벤트로 각 engine harness에 `SET_TOURNAMENT_HEADS_UP { value: true }` 전파
+ - **Lobby**: 토너먼트 최종 2인 상태를 UI에 표시
+ - **Engine**: 수동으로 설정 불가. BO 이벤트 수신으로만 변경
+ - **Cash game**: 항상 false 고정
```

**영향**:
- **코드 수정**: `betting_rules.dart:102-104` `_canRaise()` 로직 변경
- **계약 영향**: `contracts/api/API-02-backoffice.md` 또는 `API-05-websocket.md`에 `SET_TOURNAMENT_HEADS_UP` 이벤트 추가 필요 → **후속 CCR 필요**
- **신규 테스트**: `test/heads_up_cap_tournament_vs_hand_test.dart`
- **Team 2 영향**: BO에서 player count tracking 및 이벤트 발행 로직 신설

---

## Part B: P1 HIGH — 주요 규칙 누락 (운영 영향)

### P1-4. Rule 87 부분 누락 — Heads-up Button 조정 & 딜링 순서

**WSOP Rule 87 (verbatim)**:
> 헤즈업 플레이에서 스몰 블라인드는 버튼에 있으며 첫 번째 프리플랍에서 행동하고 다른 모든 베팅 라운드에서 마지막으로 행동합니다. 마지막 카드는 버튼으로 처리됩니다. **헤즈업 플레이를 시작할 때 두 참가자 모두 연속으로 빅 블라인드가 없도록 버튼을 조정해야 할 수 있습니다.**

**BS-06-03 현재 상태**:
- §5 Heads-up 섹션에 "Dealer = SB, SB가 PRE_FLOP first-to-act" 정의 ✅
- **"헤즈업 전환 시 button 조정"** (두 참가자 연속 BB 방지) ❌ 누락
- **"마지막 카드는 버튼에"** (딜링 순서 특이성) ❌ 누락

**문제점**:
1. 3명+ → 2명 전환 시 이전 핸드 BB 플레이어가 다음 핸드에도 BB가 되는 불공정 상황 발생 가능
2. Button 조정 로직이 없어 운영자(CC)가 수동으로 dealer 위치를 변경해야 함 → 인적 오류 위험

**제안 변경**:

#### (1) BS-06-00-REF Ch1 Seat 필드 확장

```diff
  ### Seat-level State
  
  (기존 필드 유지)
+ | prev_hand_bb_seat | int? | null | 직전 핸드에서 BB였던 플레이어 index. 헤즈업 전환 감지 시 button 조정용 (Rule 87). HAND_COMPLETE 시 현재 bbSeat를 복사. |
```

#### (2) BS-06-03 §5 Heads-up 섹션 확장

```diff
  ## 5. Heads-up (2인) 특수 규칙
  
  ### 5.1 Seat 매핑 (기존)
  
  (현재 내용 유지)
  
+ ### 5.2 Heads-up 전환 시 Button 조정 (Rule 87)
+ 
+ **원칙**: 3명+ → 2명 전환 시 이전 핸드의 BB 플레이어가 다시 BB가 되지 
+ 않도록 button 위치를 조정한다 (WSOP Official Live Action Rules Rule 87 
+ 단서: "two participants both do not have the big blind in a row").
+ 
+ #### 5.2.1 전환 감지
+ 
+ ```
+ HAND_COMPLETE 시점:
+     num_active_next = count(seats where status != SITTING_OUT and stack > 0)
+     if num_active_next == 2 and state.num_active_prev_hand >= 3:
+         # 3명+ → 2명 전환 발생
+         apply_heads_up_button_adjustment()
+ ```
+ 
+ #### 5.2.2 Button 조정 규칙
+ 
+ ```
+ apply_heads_up_button_adjustment():
+     prev_bb = state.prev_hand_bb_seat
+     remaining = [seats[i] for i in active_seats]
+     
+     if prev_bb in remaining:
+         # 이전 BB 플레이어가 살아있음
+         # 다음 핸드에서 Dealer(=SB)로 전환
+         new_dealer_seat = prev_bb
+     else:
+         # 이전 BB가 이미 탈락 → 정상 회전
+         new_dealer_seat = (state.dealer_seat + 1) % n
+     
+     state.dealer_seat = new_dealer_seat
+ ```
+ 
+ #### 5.2.3 예시
+ 
+ **상황**: 3인 토너먼트, 직전 핸드에서 P3이 BB였고, P1이 탈락
+ 
+ 직전 핸드:
+ - dealer=P1, sb=P2, bb=P3
+ - 결과: P1 탈락, P2/P3 생존
+ 
+ 다음 핸드 (heads-up 시작):
+ - **조정 전**: 정상 회전 시 dealer=P2, sb=P2, bb=P3 (P3이 연속 BB)
+ - **조정 후** (Rule 87): dealer=P3(=SB), bb=P2 → P2가 BB, P3은 SB
+ 
+ 결과적으로 P3이 연속 BB가 되는 것을 방지.
+ 
+ ### 5.3 딜링 순서 (Rule 87 보충)
+ 
+ Heads-up에서 카드 딜링은 일반적으로 "딜러 왼쪽부터 시계방향" 원칙을 
+ 따르나, 2명일 때는 실질적으로 상대방 → 본인 순서로 처리된다. 
+ WSOP Rule 87은 "마지막 카드는 버튼으로 처리됨"을 명시하며, 
+ 이는 다음을 의미:
+ 
+ 1. 첫 번째 hole card: BB(상대방)에게 먼저
+ 2. 두 번째 hole card: BB → SB(Dealer)
+ 3. (결과적으로) 마지막 카드가 Dealer에게 도달
+ 
+ **Engine 구현**: RFID 스캔 순서와 무관하게 논리적 딜링 순서를 
+ `DealHoleCards` 이벤트에서 관리. Physical 순서는 Team 4 CC의 hardware 
+ layer 담당.
```

**영향**:
- **코드 수정**: `engine.dart:557-575` `_endHand()` 함수 내 button 이동 로직 확장
- **신규 테스트**: `test/heads_up_button_adjustment_test.dart` — 3→2 전환 시 연속 BB 방지 확인
- **Team 4 영향**: 전환 이벤트 감지 시 CC UI에 "Button Adjusted" 알림 표시 (선택)

---

### P1-5. Rule 28.3.2 누락 — Bomb Pot Button Freeze & Opt-Out

**WSOP Rule 28.3.2 (verbatim)**:
> 플레이어(들)가 '폭탄 팟'에 참여하기를 원하지 않고 자신의 시간을 지불하기로 선택한 경우, 그렇게 할 수 있지만 '폭탄 팟' 핸드 동안에는 처리되지 않습니다. **버튼은 '폭탄 팟' 핸드에서 진행되지 않으므로** '폭탄 팟'에 참여하지 않기로 선택한 플레이어는 포지션 에퀴티를 잃지 않습니다.

**BS-06-01 현재 상태**:
- §9 Bomb Pot 섹션에 상태 전이(`SETUP_HAND → FLOP` 직행) 정의 ✅
- **Button freeze 규칙** ❌ 누락 (코드 `engine.dart:560-574` `_endHand`는 항상 dealer +1 이동)
- **Opt-out 플레이어 처리** ❌ 누락 (현재 EBS는 전원 강제 참여 가정)

**문제점**:
1. Bomb pot 핸드에서 button이 이동하면 opt-out 플레이어의 position equity가 손실됨 (WSOP 규정 위반)
2. 강제 참여 가정은 실제 운영에서 "Short stack 플레이어가 bomb pot에 참여 거부"와 충돌 → 운영 실수 유발
3. CC UI에서 opt-out 토글 제공 불가 (엔진이 지원 안 함)

**제안 변경**:

#### (1) BS-06-00-REF Ch1 State 확장

```diff
  ### Game-level State
  
  (기존)
+ | bomb_pot_opted_out | Set<int> | {} | 현재 bomb pot 핸드에서 opt-out한 플레이어 seat indexes (Rule 28.3.2). bomb_pot_enabled=false 시 clear. |
```

#### (2) BS-06-01 §9 Bomb Pot 섹션 확장

```diff
  ## 9. Bomb Pot (특수 상태 전이)
  
  ### 9.1 정의 및 활성화 조건 (기존)
  
  (현재 내용 유지)
  
+ ### 9.2 Button Freeze & Opt-Out (Rule 28.3.2)
+ 
+ **원칙**: Bomb pot 핸드 동안 button은 이동하지 않으며(freeze), opt-out을 
+ 선택한 플레이어는 위치 에퀴티를 잃지 않는다 
+ (WSOP Official Live Action Rules Rule 28.3.2).
+ 
+ #### 9.2.1 Button Freeze
+ 
+ ```
+ SETUP_HAND 진입 시 (bomb_pot_enabled == true):
+     state.frozen_dealer_seat = state.dealer_seat  // 현재 dealer 보존
+ 
+ HAND_COMPLETE 시 (bomb_pot_enabled == true):
+     # _endHand() 로직에서 dealer +1 이동 스킵
+     state.dealer_seat = state.frozen_dealer_seat  // 동일 유지
+     state.bomb_pot_enabled = false  // 다음 핸드부터 평소대로
+ 
+ 다음 핸드 SETUP_HAND:
+     state.dealer_seat = (state.dealer_seat + 1) % n  // 평소 이동
+ ```
+ 
+ #### 9.2.2 Opt-Out 플레이어
+ 
+ **Opt-out 신청 시점**: Bomb pot 핸드 시작 전 SETUP_HAND에서 CC가 
+ `BOMB_POT_OPT_OUT { seat_index }` 이벤트 전송.
+ 
+ **Opt-out 상태 처리**:
+ ```
+ state.bomb_pot_opted_out.add(seat_index)
+ state.seats[seat_index].status = SEATED_OUT  // 임시
+ # 기존 stack 보존 (ante 납부 안 함)
+ # 카드 딜링 대상 아님
+ # 액션 순서에서 제외
+ ```
+ 
+ **HAND_COMPLETE 시 복귀**:
+ ```
+ for idx in state.bomb_pot_opted_out:
+     state.seats[idx].status = ACTIVE  // 정상 복귀
+ state.bomb_pot_opted_out = {}  // clear
+ ```
+ 
+ #### 9.2.3 Short Contribution (기존 유지 + 명확화)
+ 
+ Opt-out과 short contribution은 구분된다:
+ 
+ | 구분 | Opt-out | Short Contribution |
+ |------|---------|-------------------|
+ | 조건 | 플레이어 명시 거부 | stack < bomb_pot_amount |
+ | Ante | 납부 안 함 | 최대 stack 납부 (all-in) |
+ | 카드 | 받지 않음 | 정상 수령 |
+ | 핸드 참여 | 완전 제외 | 참여 (all-in 상태) |
+ | Button 영향 | Freeze로 equity 보존 | 정상 freeze |
+ 
+ #### 9.2.4 Default Ante (Rule 28.3.1 참조)
+ 
+ WSOP Rule 28.3.1은 bomb pot default ante를 다음과 같이 제안:
+ - $1-$2-$5 limit games: $20/player
+ - $5-$5 limit games: $25/player
+ 
+ EBS 기본값은 "2×BB"로 유지하되, House 설정으로 WSOP 권장값 override 가능.
+ 상세는 P3-18 참조.
```

#### (3) BS-06-09 Event 추가

```diff
  ## Input Events
  
  (기존)
+ ### IE-12: BOMB_POT_OPT_OUT
+ 
+ | 필드 | 타입 | 설명 |
+ |------|------|------|
+ | seat_index | int | opt-out 신청 플레이어 |
+ 
+ - 소스: CC
+ - 유효 상태: SETUP_HAND (bomb_pot_enabled == true)
+ - 전제조건: state.bomb_pot_opted_out에 아직 없음
+ - 결과: seat.status = SEATED_OUT, bomb_pot_opted_out.add(seat_index)
```

**영향**:
- **코드 수정**: `engine.dart:556-575` `_endHand()` 내 bomb pot freeze 분기 + `_startHand()` opt-out 처리
- **신규 테스트**: `test/bomb_pot_freeze_optout_test.dart`
- **Team 4 영향**: CC SETUP_HAND 화면에 "Opt-out" 버튼 추가 (선택)

---

### P1-6. Mixed Omaha Button Freeze 누락

**WSOP "New Blind Type: Mixed Omaha" (Confluence 원문)**:
> Button movement: Does NOT advance during game transitions (button freezes)
> Game transitions occur: At level change (not mid-level)

**WSOP Rule 288 (Stud 관련 보충)**:
> 스터드 이벤트 또는 스터드 변형이 있는 혼합 이벤트의 테이블 균형을 조정할 때 테이블에서 높은 카드를 가져와 이동할 참가자를 결정합니다.

**BS-06-00-REF 현재 상태**:
- Ch1 `event_game_type = 8 Mixed` 정의만 존재
- **Mix 순서**, **전환 규칙**, **button freeze** 전부 누락
- HORSE, 8-Game, Mixed Omaha 각각의 특수 규정 미반영

**문제점**:
1. Mixed 토너먼트에서 게임 전환 시 button 동작이 정의되지 않음 → Team 3 구현 시 추측 기반
2. Team 4 CC는 "현재 핸드가 transition인지" 알 수 없어 UI 표시 불가
3. Team 2 BO는 blind structure 전환 시점에 엔진과 동기화할 메커니즘 부재

**제안 변경 (BS-06-00-REF Ch1.9 확장)**:

```diff
  ### 1.9 event_game_type (WSOP 매핑)
  
  (기존 매핑 표)
  
+ ### 1.9.1 Mixed Game Rotation & Button Freeze
+ 
+ **원칙**: Mixed 토너먼트에서 게임 전환은 **레벨 종료 시**에만 발생하며, 
+ 전환 핸드 동안 button은 freeze된다 (WSOP LIVE "New Blind Type: Mixed Omaha" 기준).
+ 
+ #### Mix Type별 Rotation 규칙
+ 
+ | Mix Type | Rotation 단위 | Button 이동 | Bet Structure 전환 | 참조 |
+ |----------|--------------|------------|-------------------|------|
+ | HORSE | 레벨 종료 시 전환 | **전환 핸드 freeze** | Limit 유지 (BB stud 포함) | WSOP Rule 287-288 |
+ | 8-Game | 레벨 종료 시 전환 | **전환 핸드 freeze** | 게임별 상이 (NL, PL, FL 혼합) | WSOP Rule 287-288 |
+ | Mixed Omaha (NEW) | 레벨 종료 시 전환 | **전환 핸드 freeze** | PLO ↔ Limit 교대 | New Blind Type: Mixed Omaha |
+ | Dealer's Choice | 매 핸드 딜러 선택 | 평소대로 이동 | 게임별 상이 | WSOP 별도 |
+ | PPC (Player Pick) | 매 핸드 플레이어 선택 | 평소대로 이동 | 게임별 상이 | 비표준 |
+ 
+ #### State 필드
+ 
+ ```
+ state.mixed_game_sequence: List<GameDef>  // 전체 mix 순서 (예: [O8, Razz, Stud, Stud8, NLH, PLO])
+ state.current_game_index: int              // 현재 game 인덱스
+ state.game_transition_pending: bool        // 다음 핸드에서 전환 예정
+ ```
+ 
+ `GameDef` 구조:
+ ```
+ GameDef {
+     variant_name: str,      // "O8", "Razz", "Stud", etc.
+     bet_structure: int,     // NL/PL/FL
+     hole_card_count: int,   // variant에 따름
+     level_hands: int?,      // null이면 레벨당 hand 수 무관 (시간 기반)
+ }
+ ```
+ 
+ #### 전환 트리거
+ 
+ BO(Backoffice)가 blind level 종료 이벤트를 전파하면:
+ ```
+ SET_GAME_TRANSITION_PENDING { table_id } 이벤트 수신
+ → state.game_transition_pending = true
+ ```
+ 
+ 현재 핸드 HAND_COMPLETE 시:
+ ```
+ if state.game_transition_pending:
+     state.current_game_index = (state.current_game_index + 1) % len(sequence)
+     state.variantName = sequence[current_game_index].variant_name
+     state.bet_structure = sequence[current_game_index].bet_structure
+     # Button freeze: dealer_seat 유지 (이동 스킵)
+     state.game_transition_pending = false
+     emit OutputEvent.GameTransitioned { from, to, button_frozen: true }
+ else:
+     state.dealer_seat = (state.dealer_seat + 1) % n  // 평소 이동
+ ```
+ 
+ #### Stud 계열 테이블 균형 (Rule 288 참조)
+ 
+ Mix에 Stud 변형이 포함된 경우 table balance 시 high card rule을 적용:
+ - 대상 플레이어 선정: 모든 seat에 1장씩 open card 딜 → 가장 높은 카드 플레이어가 이동
+ - 현재 게임이 Stud이든 Flop 게임이든 동일하게 적용
+ - EBS 엔진은 `BalancePlayerSelection` 이벤트를 BO로부터 수신하여 판정 수행
```

**영향**:
- **코드 수정**: `engine.dart` _endHand 로직에 `game_transition_pending` 분기 추가
- **신규 OutputEvent**: `GameTransitioned { from, to, button_frozen }` → **contracts/api/API-04 CCR 필요**
- **Team 2 영향**: BO에 `SET_GAME_TRANSITION_PENDING` 전파 로직 신설
- **Team 4 영향**: Mixed Omaha 전환 시 CC/Overlay에 "game transition" 표시

---

### P1-7. Rule 89 누락 — Four-Card Flop 복구

**WSOP Rule 89 (verbatim)**:
> 플롭에 4장(3장이 아닌) 카드가 있는 경우, 노출 여부에 관계없이 딜러는 4장의 카드를 뒤집어서 스크램블해야 합니다. 토너먼트 임원이 다음 번 카드로 사용할 카드 한 장을 무작위로 선택하고 나머지 세 장의 카드는 플롭이 됩니다.

**BS-06-08 현재 상태**:
- Miss Deal 조건에 "카드 수 mismatch" 수준만 정의
- **Four-card flop 전용 복구 절차** ❌ 누락

**문제점**:
1. RFID가 flop에 4장 감지 시 (딜러 오류 또는 리더 오감지) 복구 절차 없음 → 핸드 강제 취소
2. WSOP 규정은 "새 덱 필요 없이" 4장 재섞기로 복구 가능 → 엔진 미지원으로 핸드 손실 발생
3. Team 4 CC는 이 상황에서 어떤 UI를 제공해야 하는지 명세 부재

**제안 변경**:

#### (1) BS-06-08 §3.4 신설

```diff
  ## 3. 복구 가능 예외
  
  (기존 §3.1 ~ §3.3: Miss Deal, 카드 중복, 잘못된 카드 딜)
  
+ ### 3.4 Four-Card Flop 복구 (Rule 89)
+ 
+ **원칙**: Flop에 4장의 카드가 감지된 경우 (노출 여부 무관), 4장 전부 
+ 회수 후 섞어 무작위 1장을 다음 burn으로 보존하고 나머지 3장을 정식 flop으로 
+ 노출한다 (WSOP Official Live Action Rules Rule 89).
+ 
+ #### 3.4.1 감지 조건
+ 
+ ```
+ state.street == FLOP
+ state.community.length > 3
+ ```
+ 
+ 감지 시점:
+ - Engine이 `DealCommunity` 이벤트 적용 후 invariant 검사에서 감지
+ - 또는 CC가 수동으로 `RecoveryRequest { type: "four_card_flop" }` 전송
+ 
+ #### 3.4.2 상태 전이
+ 
+ ```
+ [FLOP]
+   ↓ invariant violation: community.length == 4
+ [EXCEPTION_FOUR_CARD_FLOP]
+   ↓ ManagerRuling { decision: "recover" } 수신
+ [FLOP_RECOVERY_SCRAMBLE]
+   ↓ engine이 4장 shuffle → 무작위 1장 선택
+   ↓ DealCommunityRecovery 이벤트 적용
+ [FLOP]
+   ↓ 베팅 라운드 정상 진행
+ ```
+ 
+ #### 3.4.3 복구 절차
+ 
+ ```
+ recover_four_card_flop(state):
+     extra_cards = state.community[:4]  // 4장 전부
+     shuffled = shuffle(extra_cards, seed=session_rng_seed)
+     burn_candidate = shuffled[0]  // 무작위 1장 = 다음 burn
+     new_flop = shuffled[1:4]       // 남은 3장 = 정식 flop
+     
+     state.community = new_flop
+     state.pending_burn = burn_candidate  // turn 딜 전에 사용
+     state.street = FLOP
+     
+     emit OutputEvent.FlopRecovered { 
+         original_cards: extra_cards, 
+         new_flop, 
+         reserved_burn: burn_candidate 
+     }
+ ```
+ 
+ #### 3.4.4 신규 이벤트 (BS-06-09 참조)
+ 
+ - Input: `ManagerRuling { decision: "recover_four_card_flop" }`
+ - Engine 내부: `DealCommunityRecovery { extra_card, new_flop }`
+ - Output: `FlopRecovered { original_cards, new_flop, reserved_burn }` (OutputEvent)
+ 
+ #### 3.4.5 복구 불가 조건
+ 
+ - 4장 이상 (5장 이상 감지): 전체 misdeal 처리
+ - 플레이어가 이미 action 시작: 여전히 복구 가능 (Rule 89는 노출 여부 무관)
+ - 두 번째 four-card flop 재발: 덱 손상 의심, deck change (Rule 78)로 전환
```

#### (2) BS-06-09 Event Catalog 확장

```diff
  ## Input Events
  
  (기존)
+ ### IE-13: ManagerRuling
+ 
+ | 필드 | 타입 | 설명 |
+ |------|------|------|
+ | decision | str | "recover_four_card_flop", "retrieve_fold", "kill_hand", "muck_retrieve" 중 하나 |
+ | target_seat | int? | 대상 seat (decision에 따라) |
+ | rationale | str? | 운영자 사유 (감사 로그용) |
+ 
+ - 소스: CC (Floor/Manager 권한 필요)
+ - 유효 상태: EXCEPTION_* 상태 또는 HAND_COMPLETE 직전
+ - 전제조건: decision별 상이 (§3.4, §7 참조)
+ - 결과: decision에 따른 복구/판정 수행
+ 
+ ### Internal Events
+ 
+ #### IE-INT-01: DealCommunityRecovery
+ 
+ (Engine 내부 사용, CC에서 직접 전송 불가)
+ 
+ | 필드 | 타입 | 설명 |
+ |------|------|------|
+ | extra_card | Card | 추가로 감지된 카드 (4번째) |
+ | new_flop | List<Card> | 복구 후 정식 flop 3장 |
```

**영향**:
- **코드 수정**: `engine.dart`에 `_handleManagerRuling`, `_recoverFourCardFlop` 함수 신설
- **신규 테스트**: `test/four_card_flop_recovery_test.dart`
- **Team 4 영향**: CC에 manager ruling 버튼 + 4-card flop 감지 시 복구 확인 다이얼로그

---

### P1-8. Rule 71 & 110 누락 — Tabled Hand 보호 & Folded Hand 복구

**WSOP Rule 71 (verbatim)**:
> 딜러는 테이블 위에 있고 분명히 이기는 패를 죽일 수 없습니다. 테이블 핸드는 딜러와 테이블의 모든 참가자가 읽을 수 있도록 참가자가 테이블 위에 놓는 핸드로 정의됩니다.

**WSOP Rule 110 (verbatim)**:
> 딜러 오류 또는 참가자에게 제공한 잘못된 정보로 인해 접힌 핸드 리트리버블을 규정하기 위해 추가 노력을 기울일 것입니다.

**BS-06-07 현재 상태**:
- Muck 관련 `card_reveal_type` 6종 정의 ✅
- **Tabled hand 보호 규정** ❌ 누락 (엔진이 임의 muck 처리 방지 로직 없음)
- **Folded hand 복구 규정** ❌ 누락 (Session.undo()는 있으나 manager discretion 개념 없음)

**문제점**:
1. 엔진 버그로 tabled winning hand가 muck 처리되는 치명적 시나리오 방어 불가
2. 딜러 오류로 인한 잘못된 fold 상황에서 복구 절차가 없음 → 플레이어 분쟁
3. Manager/Floor 재량 판정이 엔진 이벤트로 기록되지 않아 감사 추적 불가

**제안 변경**:

#### (1) BS-06-00-REF Ch1 Seat 필드 확장

```diff
  ### Seat-level State
  
  (기존)
+ | cards_tabled | bool | false | 플레이어가 테이블 위에 카드를 공개한 상태 (Rule 71). true일 때 dealer/engine이 임의 muck 처리 금지. |
```

#### (2) BS-06-07 §7 신설

```diff
  ## 6. Muck 규정
  
  (기존)
  
+ ## 7. 핸드 보호 & 복구 규정 (Rule 71, 110)
+ 
+ ### 7.1 Tabled Hand 보호 (Rule 71)
+ 
+ **원칙**: 플레이어가 명시적으로 테이블 위에 카드를 공개한 경우, 
+ 딜러 또는 엔진은 해당 핸드를 임의로 kill/muck 처리할 수 없다 
+ (WSOP Official Live Action Rules Rule 71).
+ 
+ #### 7.1.1 Tabled 상태 설정
+ 
+ CC가 `TableHand { seat_index }` 이벤트를 전송하면:
+ ```
+ state.seats[seat_index].cards_tabled = true
+ emit OutputEvent.HandTabled { seat_index, cards }
+ ```
+ 
+ #### 7.1.2 보호 규칙
+ 
+ 이후 엔진이 muck 로직을 수행할 때:
+ ```
+ for seat in state.seats:
+     if seat.cards_tabled:
+         # Muck 금지, 카드 정보 보존
+         continue
+     else:
+         apply_muck_logic(seat)
+ ```
+ 
+ #### 7.1.3 Winning Hand 자동 수여
+ 
+ Tabled hand 중 명백한 winning hand가 있으면 엔진은 자동으로 
+ pot을 award한다. 딜러/CC의 수동 개입 없이 판정.
+ 
+ ### 7.2 Folded Hand 복구 (Rule 110)
+ 
+ **원칙**: 딜러 오류 또는 잘못된 정보로 인한 fold는 manager discretion 
+ 판정 후 복구 가능하다 (WSOP Official Live Action Rules Rule 110).
+ 
+ #### 7.2.1 복구 조건
+ 
+ 1. 카드가 완전히 muck에 섞이기 전 (state 추적)
+ 2. UNDO 5단계 제한 내 (BS-06-01 §UNDO 참조)
+ 3. ManagerRuling 이벤트로 명시적 승인
+ 
+ #### 7.2.2 복구 절차
+ 
+ ```
+ CC → ManagerRuling { decision: "retrieve_fold", target_seat: N, rationale: "dealer error" }
+ 
+ Engine:
+     # 1. UNDO로 마지막 Fold 이벤트 취소
+     session.undo()
+     # 2. 복구 확인
+     assert state.seats[N].status == ACTIVE
+     # 3. 감사 로그에 ManagerRuling 기록
+     emit OutputEvent.HandRetrieved { seat: N, manager_rationale: "..." }
+ ```
+ 
+ #### 7.2.3 복구 실패 조건
+ 
+ | 조건 | 엔진 응답 |
+ |------|----------|
+ | 카드가 이미 muck에 섞임 (다음 핸드 시작) | ERROR: "card already mucked" |
+ | UNDO 5단계 초과 | ERROR: "undo limit exceeded" |
+ | Fold 이벤트가 아닌 경우 | ERROR: "not a fold event" |
+ | target_seat가 fold 상태 아님 | ERROR: "seat not in folded state" |
+ 
+ ### 7.3 ManagerRuling 이벤트 참조
+ 
+ 본 섹션의 규정은 `ManagerRuling` 이벤트 (BS-06-09 IE-13)를 통해 트리거된다.
+ Manager 권한은 CC의 RBAC에서 Floor/Manager 이상만 허용 (Team 4 관할).
```

**영향**:
- **코드 수정**: `engine.dart`에 `_handleManagerRuling`, `_handleTableHand` 함수 신설
- **신규 테스트**: `test/tabled_hand_protection_test.dart`, `test/folded_hand_retrieve_test.dart`
- **Team 4 영향**: 
  * CC UI에 "Table Hand" 버튼 (showdown 시)
  * Manager 권한 체크 및 판정 버튼
  * 감사 로그 표시

---

## Part C: P2 MEDIUM — 품질 개선

### P2-9. Rule 56 — Verbal Declaration vs Chip Push 우선순위

**WSOP Rule 56 (verbatim)**:
> 베팅은 구두 선언 및/또는 칩을 밀어내는 방식입니다. 플레이어가 두 가지 모두를 수행하는 경우 둘 중 먼저 하는 것이 베팅을 정의합니다. 동시적이라면 명확하고 합리적인 구두 선언이 우선하고 그렇지 않으면 칩 플레이 입니다.

**BS-06-02 현재 상태**:
- §1 개요에 베팅 입력 방식에 대한 WSOP 참조 없음
- EBS는 CC 전자식 입력을 전제하므로 verbal/chip 구분 불필요하나, WSOP 준수 명시가 필요

**제안 변경 (BS-06-02 §1.1 주석 추가)**:

```diff
  ## 1. 베팅 개요
  
+ ### 1.1 베팅 입력 방식 (Rule 56 참조)
+ 
+ EBS는 CC(Command Center)의 전자식 입력을 유일한 공식 소스로 간주한다. 
+ WSOP Official Live Action Rules Rule 56은 구두/칩 동시 발생 시 
+ 우선순위를 규정하지만, EBS 운영 환경에서는 다음과 같이 해석한다:
+ 
+ 1. **라이브 테이블 (physical)**: 딜러 또는 CC 운영자가 Rule 56을 적용하여 
+    verbal/chip 의도를 판단한 후, 결과를 CC에 단일 이벤트로 입력
+ 2. **EBS Engine**: CC가 전송한 이벤트를 재해석 없이 그대로 수락
+ 3. **CC UI 구현 권고**:
+    - 구두 먼저 → 칩 금액 불일치 시 구두 우선 (Rule 56.a)
+    - Amount-only 선언은 동일 금액 call/raise로 자동 판정 (Rule 56.c)
+    - 불분명한 상황은 Floor 판정 버튼 활성화 (Rule 56 전단)
+ 
+ **Engine 입력 계약**: CC는 검증된 액션만 전송해야 하며, 엔진은 Rule 56 
+ 재해석을 수행하지 않는다. 이는 Rule 95 (under-raise)와 Rule 96 
+ (incomplete all-in)과 독립적인 레이어이다.
```

**영향**: 문서 명확화만, 코드 변경 없음

---

### P2-10. Rule 109 — Muck 카드 재판정

**WSOP Rule 109 (verbatim)**:
> muck에 던져진 카드는 죽은 것으로 간주될 수 있습니다. 그러나 명확하게 식별할 수 있는 핸드가 게임에 가장 좋은 경우 관리자의 재량에 따라 실시간으로 검색 및 판정될 수 있습니다.

**BS-06-07 현재 상태**:
- Muck = 영구 dead로 처리
- Manager discretion 복구 규정 없음

**제안 변경 (BS-06-07 §6.2 Muck 섹션 확장)**:

```diff
  ## 6. Muck 규정
  
  (기존 §6.1)
  
+ ### 6.2 Muck 카드 재판정 (Rule 109)
+ 
+ **원칙**: 기본적으로 muck에 들어간 카드는 dead로 처리되나, 다음 조건을 
+ 모두 충족하는 경우 ManagerRuling 이벤트로 재판정(retrieve)할 수 있다 
+ (WSOP Official Live Action Rules Rule 109).
+ 
+ #### 6.2.1 복구 조건
+ 
+ 1. **카드 식별 가능**: Muck 시점 RFID 스캔 로그에 카드 정보가 
+    명확히 남아 있음 (`state.muck_log: List<{seat, cards, timestamp}>`)
+ 2. **Winning Hand**: 해당 핸드가 evaluator 기준 명백한 winning hand
+ 3. **Manager 승인**: Manager/Floor 권한의 CC 사용자가 `ManagerRuling` 
+    이벤트 전송
+ 
+ #### 6.2.2 복구 절차
+ 
+ ```
+ CC → ManagerRuling { 
+     decision: "muck_retrieve", 
+     target_seat: N, 
+     rationale: "tabled winning hand mucked by dealer error" 
+ }
+ 
+ Engine:
+     # 1. muck_log에서 N의 카드 조회
+     cards = state.muck_log.find(seat=N)
+     assert cards is not None
+     
+     # 2. 해당 seat의 holeCards 복원
+     state.seats[N].holeCards = cards
+     state.seats[N].status = ACTIVE  # 또는 SHOWDOWN 상태
+     state.seats[N].cards_tabled = true  # Rule 71 보호 활성화
+     
+     # 3. Showdown 재평가
+     run_showdown_evaluation()
+     
+     # 4. 감사 로그
+     emit OutputEvent.MuckRetrieved { seat: N, cards, rationale }
+ ```
+ 
+ #### 6.2.3 복구 불가 조건
+ 
+ - 카드가 이미 다음 덱으로 섞임 (physical 섞임)
+ - 2개 이상의 seat에서 동시에 muck retrieve 요청
+ - Hand가 이미 HAND_COMPLETE 상태 (새 핸드 시작 후)
+ 
+ #### 6.2.4 P1-8 §7.2 Folded Hand 복구와의 차이
+ 
+ | 구분 | Muck 재판정 (Rule 109) | Folded Hand 복구 (Rule 110) |
+ |------|----------------------|---------------------------|
+ | 대상 | 이미 muck에 던진 카드 | 폴드 직후, muck 이전 |
+ | 조건 | Winning hand + 식별 가능 | 딜러 오류 + UNDO 가능 |
+ | 절차 | muck_log에서 복원 | Session.undo()로 이벤트 취소 |
+ | 시점 | Showdown 전후 | Fold 직후 |
```

**영향**:
- **코드 수정**: `engine.dart`에 `muck_log` 필드 및 `_handleMuckRetrieve` 추가
- **신규 테스트**: `test/muck_retrieve_test.dart`

---

### P2-11. Rule 101 — Pot Size Display PL only

**WSOP Rule 101 (verbatim)**:
> 참가자는 팟 리밋 게임에서만 팟 크기에 대한 정보를 받을 수 있습니다. 딜러는 리미트 및 노리밋 게임에서 팟을 계산하지 않습니다. 요청이 있을 경우 딜러는 참가자가 셀 수 있도록 팟을 퍼뜨릴 수 있습니다.

**BS-06-00-REF 현재 상태**:
- Ch7 OutputEvent에 pot 관련 이벤트 있으나 display policy 없음
- CC/Overlay는 모든 게임에서 pot 정확 금액 표시 가능 → WSOP 규정 위반 가능

**제안 변경 (BS-06-00-REF Ch7.5 신설)**:

```diff
  ## Ch7. OutputEvent & API Contract
  
  (기존 §7.1 ~ §7.4)
  
+ ### 7.5 Pot Size Display Policy (Rule 101)
+ 
+ **원칙**: 플레이어를 위한 pot 정확 금액 표시는 PL(Pot-Limit) 게임에만 
+ 허용된다 (WSOP Official Live Action Rules Rule 101). NL/FL/Spread 게임에서는 
+ 플레이어 대상 UI에서 pot 정확 금액을 숨겨야 한다.
+ 
+ #### 7.5.1 게임 형식별 정책
+ 
+ | 게임 형식 | Pot 정확 금액 (플레이어 UI) | Pot 추정/힌트 | Pot 표시 (CC/Overlay) |
+ |-----------|:--------------------------:|:-------------:|:--------------------:|
+ | NL (No-Limit) | ❌ 금지 | 선택적 ("약 X BB") | ✅ CC/Overlay 자유 |
+ | PL (Pot-Limit) | ✅ 허용 | ✅ 허용 | ✅ 자유 |
+ | FL (Fixed-Limit) | ❌ 금지 | 선택적 | ✅ 자유 |
+ | Spread Limit | ❌ 금지 | 선택적 | ✅ 자유 |
+ 
+ #### 7.5.2 Canvas 구분
+ 
+ Output은 canvas_type에 따라 다르게 렌더링:
+ 
+ - **Broadcast Canvas**: 관객 대상이므로 모든 pot 정보 **항상 표시** 
+   (Rule 101은 플레이어 대상 규정으로, 방송은 제외)
+ - **Venue Canvas**: 테이블 옆 모니터 등 플레이어가 볼 수 있는 디스플레이 
+   → 게임 형식에 따라 제한
+ - **CC Canvas**: 운영자 대상 내부 UI → 항상 표시
+ 
+ #### 7.5.3 OutputEvent 플래그
+ 
+ `PotUpdated` OutputEvent에 `display_to_players: bool` 플래그 추가:
+ 
+ ```
+ PotUpdated {
+     main: int,
+     sides: List<SidePot>,
+     total: int,
+     display_to_players: bool  // 게임 형식 기반 자동 설정
+ }
+ ```
+ 
+ `display_to_players` 계산:
+ ```
+ display_to_players = (state.bet_structure == PL)
+ ```
+ 
+ #### 7.5.4 CC/Overlay 구현 책임
+ 
+ - **Engine**: `PotUpdated.display_to_players` 플래그 자동 설정
+ - **CC**: 플레이어 대상 UI (table monitor 등)에서 플래그 false면 금액 숨김
+ - **Overlay (Broadcast)**: 플래그 무시, 항상 표시
+ - **Overlay (Venue)**: 플래그 준수
```

**영향**:
- **코드 수정**: `engine.dart`에서 OutputEvent 생성 시 플래그 추가
- **계약 영향**: `contracts/api/API-04-overlay-output.md`에 PotUpdated 스키마 확장 → 후속 CCR
- **Team 4 영향**: Overlay 렌더링 로직에 `display_to_players` 반영

---

### P2-12. Rule 81 — Rabbit Hunting 금지

**WSOP Rule 81 (verbatim)**:
> 래빗헌팅은 허용되지 않습니다. 래빗 헌팅이란 핸드가 끝나지 않았다면 '나왔을' 카드를 공개하는 것입니다.

**BS-06-01 현재 상태**:
- Run It Multiple 규정은 있음 (§8)
- Rabbit hunting과 RIM의 구분 명시 없음
- 사용자가 "이후 카드 확인" 요청 시 엔진 응답 정의 없음

**제안 변경 (BS-06-01 §8.4 신설)**:

```diff
  ## 8. Run It Multiple
  
  (기존 §8.1 ~ §8.3)
  
+ ### 8.4 Run It Multiple vs Rabbit Hunting (Rule 81)
+ 
+ **원칙**: Rabbit hunting은 허용되지 않는다 
+ (WSOP Official Live Action Rules Rule 81). Run It Multiple (RIM)과 
+ 명확히 구분하여 엔진이 처리한다.
+ 
+ #### 8.4.1 개념 구분
+ 
+ | 구분 | Run It Multiple (허용) | Rabbit Hunting (금지) |
+ |------|----------------------|---------------------|
+ | 조건 | 2+ 플레이어 all-in, 보드 미완성 | 핸드 종료 후 잔여 카드 노출 요청 |
+ | 시점 | SHOWDOWN 직전 | HAND_COMPLETE 이후 |
+ | 합의 | 관련 all-in 플레이어 전원 합의 | 요청자만 |
+ | 결과 | Pot 분배에 영향 (독립 board 2~3회) | 영향 없음 (단순 호기심) |
+ | WSOP | 허용 (단, 규정에 따라) | **금지 (Rule 81)** |
+ | Engine 지원 | ✅ `RunItChoice` 이벤트 | ❌ 요청 거부 |
+ 
+ #### 8.4.2 엔진 응답 정책
+ 
+ - `RunItChoice { times: 2 or 3 }`: 정상 처리 (§8.1 참조)
+ - 그 외 "카드 공개 요청" 이벤트 (hypothetical `RabbitHuntRequest`): 
+   엔진이 수신해도 거부 응답
+ 
+ ```
+ if event_type == "rabbit_hunt_request":
+     emit OutputEvent.Error { 
+         code: "rabbit_hunt_not_allowed", 
+         message: "Rabbit hunting is not allowed (WSOP Rule 81)" 
+     }
+     return state  // 상태 변경 없음
+ ```
+ 
+ #### 8.4.3 CC UI 구현 권고
+ 
+ - Run It Multiple 옵션은 all-in 상황에서만 활성화
+ - Rabbit hunting 버튼/메뉴는 **제공하지 않음**
+ - 딜러 수동 덱 조회도 운영 매뉴얼상 금지 (Team 4 훈련 문서)
```

**영향**: 문서 명확화, 코드 변경 없음 (애초에 rabbit hunting을 지원하지 않았음을 명시)

---

### P2-13. Rule 86 — Missed Blind 복귀 규정

**WSOP Rule 86 (verbatim)**:
> 기존 좌석에서 이동할 때 의도적으로 블라인드를 피하는 참가자는 규칙 40, 113 및 114에 따라 두 블라인드를 모두 몰수하고 패널티를 부과합니다.

**BS-06-03 현재 상태**:
- Blind 포스팅 규정은 있으나 missed blind 상태 관리 없음
- 결석(sit out) 후 복귀 시 blind 포스팅 의무 정의 없음

**제안 변경**:

#### (1) BS-06-00-REF Ch1 Seat 필드 확장

```diff
  ### Seat-level State
  
  (기존)
+ | missed_sb | bool | false | 최근 lap에서 SB를 놓친 상태 (Rule 86). 복귀 시 포스팅 의무. |
+ | missed_bb | bool | false | 최근 lap에서 BB를 놓친 상태 (Rule 86). 복귀 시 포스팅 의무. |
```

#### (2) BS-06-03 §7 신설

```diff
  (기존 §1 ~ §6)
  
+ ## 7. Missed Blind 복귀 규정 (Rule 86)
+ 
+ **원칙**: 플레이어가 SB 또는 BB 포지션을 놓친 후 (sit out, absence 등) 
+ 복귀할 때는 missed blind를 포스팅해야 한다 
+ (WSOP Official Live Action Rules Rule 86).
+ 
+ ### 7.1 Missed Blind 감지
+ 
+ ```
+ HAND_COMPLETE 시점:
+     for seat in state.seats:
+         if seat.status == SITTING_OUT:
+             if seat.index == sb_index:
+                 seat.missed_sb = true
+             if seat.index == bb_index:
+                 seat.missed_bb = true
+ ```
+ 
+ ### 7.2 복귀 옵션
+ 
+ 플레이어가 `SitIn { seat_index }` 이벤트로 복귀 신청 시:
+ 
+ | 상태 | 복귀 옵션 | 설명 |
+ |------|----------|------|
+ | missed_sb = false, missed_bb = false | 즉시 복귀 | 의무 없음 |
+ | missed_sb = true, missed_bb = false | 다음 SB 포지션까지 대기 또는 SB+BB 포스트 | SB는 dead, BB는 live |
+ | missed_sb = false, missed_bb = true | 다음 BB 포지션까지 대기 또는 BB 포스트 | BB는 live bet |
+ | missed_sb = true, missed_bb = true | SB+BB 동시 포스트 (SB dead, BB live) 또는 다음 BB까지 대기 | 양쪽 포스팅 의무 |
+ 
+ ### 7.3 의도적 회피 처벌
+ 
+ Rule 86은 "의도적으로 blind를 피하는" 경우 패널티를 부과하도록 규정하나, 
+ EBS 엔진은 의도 감지 불가. 대신 다음과 같이 처리:
+ 
+ - Lobby 측에서 seat 이동 기능 사용 시 Staff 수동 감시
+ - Staff App에서 "missed blind" 플래그 수동 설정 허용
+ - Missed blind 포스팅 없이 복귀 시도 시 경고만 표시 (엔진이 차단하지 않음)
+ 
+ ### 7.4 리셋 조건
+ 
+ `missed_sb = false`, `missed_bb = false`는 다음 시점에 리셋:
+ - 해당 blind 포지션에 도달하여 정상 포스팅 완료
+ - 수동 포스팅 (다음 핸드 시작 전 SitIn + PostBlinds)
+ - Tournament 새 level 시작 (선택적, House 규정)
```

**영향**:
- **코드 수정**: `engine.dart`의 `_endHand`에서 sitting out 감지 후 missed 플래그 설정
- **신규 이벤트**: `SitIn { seat_index, post_blinds: bool }` (BS-06-09 추가)

---

### P2-14. Rule 78 — Deck Change 조건

**WSOP Rule 78 (verbatim)**:
> 덱 변경은 딜러 푸시 또는 제한 변경 또는 Rio에서 규정한 대로 이루어집니다. 참가자는 카드가 손상된 경우를 제외하고 덱 변경을 요청할 수 없습니다.

**BS-06-08 현재 상태**:
- RFID 덱 등록(`DeckFSM`)은 있으나 덱 교체 시점 규정 없음
- 플레이어 요청 처리 정의 없음

**제안 변경 (BS-06-08 §5 신설)**:

```diff
  (기존 §1 ~ §4)
  
+ ## 5. Deck Change 절차 (Rule 78)
+ 
+ **원칙**: 덱 변경은 규정된 시점에만 이루어지며, 플레이어 요청은 
+ 카드 손상 등 특수 경우에만 허용된다 
+ (WSOP Official Live Action Rules Rule 78).
+ 
+ ### 5.1 허용 조건
+ 
+ | 조건 | 트리거 | 자동/수동 |
+ |------|--------|----------|
+ | 블라인드 레벨 변경 | BO `LEVEL_CHANGE` 이벤트 | 자동 (Tournament 설정) |
+ | 딜러 교대 (dealer push) | Staff App `DealerPush` 이벤트 | 자동 (House 설정) |
+ | 카드 손상 감지 | RFID read failure (3회 연속) | 자동 |
+ | Staff 수동 요청 | Staff App `DeckChangeRequest` 이벤트 | 수동 |
+ | 플레이어 요청 (손상 증거) | Staff 승인 후 `DeckChangeRequest` | 수동 |
+ 
+ ### 5.2 절차
+ 
+ ```
+ 1. 현재 핸드 HAND_COMPLETE 대기
+ 2. Deck FSM 상태 전이:
+    REGISTERED → UNREGISTERED → REGISTERING → REGISTERED (신 덱)
+ 3. 새 덱 RFID 등록 (DATA-03 DeckFSM 참조)
+ 4. 다음 핸드 SETUP_HAND 진입
+ ```
+ 
+ ### 5.3 금지 사항
+ 
+ - 플레이어가 단순 호기심/불안감으로 덱 변경 요청 시: Staff는 거부
+ - 핸드 진행 중 덱 변경 금지 (현재 핸드 종료까지 대기)
+ - Bomb pot / Run It Multiple 진행 중 덱 변경 금지
+ 
+ ### 5.4 긴급 덱 손상 감지
+ 
+ RFID가 3회 연속 read failure 시:
+ ```
+ engine emit OutputEvent.DeckIntegrityWarning { 
+     failure_count: 3, 
+     suggested_action: "change_deck" 
+ }
+ CC 운영자가 수동으로 DeckChangeRequest 전송
+ 현재 핸드 MisDeal 처리 후 덱 교체
+ ```
```

**영향**:
- **코드 수정**: `engine.dart` DeckFSM 확장, `_handleDeckChange` 추가
- **계약 영향**: `contracts/data/DATA-03-state-machines.md` DeckFSM 문서에 Rule 78 레퍼런스

---

## Part D: P3 LOW — 참조용 (Engine 직접 영향 적음)

### P3-15. Rule 80-83 — Time Bank / At-Seat Rules

**WSOP Rules 80-83 요약**:
- Rule 80: "Time" 요청 (delay 호출)
- Rule 82: "At your seat" 정의 — 의자에 닿을 수 있는 거리 이내
- Rule 83: Action pending 상태에서 테이블 이탈 금지

**BS-06-02 현재 상태**:
- `state.action_timeout_ms` 필드만 존재, 규정 참조 없음

**제안 변경 (BS-06-02 §timeout 섹션에 주석 추가)**:

```diff
  ### 2.X Action Timeout
  
  (기존 action_timeout_ms 설명)
  
+ #### WSOP Rule 80-83 참조
+ 
+ - Rule 80 "Time": 다른 플레이어가 "time"을 요청하면 30~60초 카운트다운 시작
+ - Rule 82 "At Your Seat": 플레이어는 자리에 있어야 라이브 핸드 참여 가능 (의자에 닿을 수 있는 거리)
+ - Rule 83 "Action Pending": action이 자신에게 돌아온 상태에서 자리 이탈 시 자동 폴드 처리 후 패널티
+ 
+ **EBS 구현**:
+ - `action_timeout_ms` 초과 시 `TimeoutFold` 이벤트 자동 발행 (Rule 83 준수)
+ - "At your seat" 검증은 Team 4 CC의 hardware layer 담당 (엔진은 불가)
+ - "Time" 요청은 CC UI의 수동 트리거 (별도 이벤트 불요)
```

**영향**: 문서 명확화만, 코드 변경 없음

---

### P3-16. Rule 62 — Stack Count Request

**WSOP Rule 62 (verbatim)**:
> 상대방의 칩 스택 수: 참가자는 상대방의 칩 스택을 합리적으로 추정할 수 있습니다. 참가자는 올인 베팅에 직면한 경우에만 더 정확한 카운트를 요청할 수 있습니다.

**BS-06-09 현재 상태**:
- Stack count request 이벤트 없음
- CC/Overlay에 stack 정보 자동 표시 중 (Rule 62에 따라 all-in facing 시에만 노출해야 함)

**제안 변경 (BS-06-09에 선택적 이벤트 추가)**:

```diff
  ## Input Events
  
  (기존)
  
+ ### IE-14 (선택): StackCountRequest
+ 
+ | 필드 | 타입 | 설명 |
+ |------|------|------|
+ | requesting_seat | int | 요청 플레이어 seat |
+ | target_seat | int | 대상 플레이어 seat |
+ 
+ - 소스: CC (플레이어 요청 대행)
+ - 유효 상태: target_seat가 all-in 상태이거나 all-in을 직면한 경우에만 (Rule 62)
+ - 전제조건: requesting_seat와 target_seat 모두 active/all-in
+ - 결과: OutputEvent.StackCountResponse { target_seat, stack } 발행
+ 
+ **구현 권고**:
+ - EBS는 CC/Overlay에 항상 stack 정보를 노출하고 있으므로, Rule 62는 
+   실무적으로 "플레이어 UI에만 숨김" 수준으로 적용
+ - CC 운영자는 모든 stack을 볼 수 있음 (내부 UI)
+ - Player-facing venue display에서만 Rule 62 규정 적용 (선택적)
```

**영향**: 선택적 이벤트, 필수 아님. Team 4 CC의 venue display 구현 시 참조용

---

### P3-17. Rule 88 — Boxed Card 2+ Misdeal

**WSOP Rule 88 (보충)**:
- 2장 이상의 boxed card (뒤집힌 채로 dealt된 카드) → misdeal 선언 가능

**BS-06-08 현재 상태**:
- Misdeal 조건: "카드 수 mismatch"만 정의
- Boxed card 감지 조건 없음

**제안 변경 (BS-06-08 Misdeal 조건 확장)**:

```diff
  ## 2. Misdeal 조건
  
  (기존)
  - 카드 수 mismatch
  - 카드 중복
  - 잘못된 카드 배포
  
+ - **Boxed Card 2+ 감지** (Rule 88): 
+   RFID가 한 핸드에서 2장 이상의 boxed card (뒤집힌 상태 감지)를 
+   보고하면 misdeal 처리. 
+   
+   `state.boxed_card_count: int` 필드 추가하여 핸드별 누적 카운트:
+   ```
+   if state.boxed_card_count >= 2:
+       trigger_misdeal("boxed_card_limit_exceeded")
+   ```
+   
+   HAND_COMPLETE 시 리셋.
```

**영향**: 
- **코드 수정**: `engine.dart`에 `boxed_card_count` 필드 및 감지 로직 추가
- **Hardware 의존**: RFID 리더가 "boxed card" 감지 가능한지 확인 필요

---

### P3-18. Rule 28.3.1 — Bomb Pot Default Ante

**WSOP Rule 28.3.1 (verbatim)**:
> 플레이어가 '폭탄 팟'에 동의하지만 앤티 금액에 동의할 수 없는 경우 다음과 같은 결정이 내려집니다. $1-$2-$5 limit type games - 각 플레이어는 $20를 앤티합니다. $5-5$ limit type games - 각 플레이어는 $25를 앤티합니다.

**BS-06-01 현재 상태**:
- Bomb pot default ante: "보통 2×BB"로 기술
- WSOP 공식 권장값 미반영

**제안 변경 (BS-06-01 §9 기본값 보강)**:

```diff
  ### 9.1 활성화 조건
  
  (기존)
  
  #### 기본 금액
- - 보통 2BB
- - 캐시 게임의 "이벤트" 핸드로 사용
+ 
+ **EBS Engine 기본값**: 2×BB (설정 가능)
+ 
+ **WSOP 권장값** (Rule 28.3.1 참조):
+ 
+ | 게임 스테이크 | WSOP 권장 ante |
+ |--------------|---------------|
+ | $1-$2-$5 limit | $20/player |
+ | $5-$5 limit | $25/player |
+ | 기타 | 2×BB (EBS 기본) |
+ 
+ House는 `bomb_pot_amount` 필드로 임의 값 설정 가능. 
+ WSOP 토너먼트 운영 시 Rule 28.3.1 권장값을 사용할 것.
```

**영향**: 문서 수치 보강, 코드 변경 없음

---

## 영향 분석

### Team 3 (Self)
- **기획서 수정**: 7개 BS-06 파일
- **신규 State 필드 9개** (BS-06-00-REF Ch1):
  * `tournament_heads_up: bool` (P0-3)
  * `prev_hand_bb_seat: int?` (P1-4)
  * `bomb_pot_opted_out: Set<int>` (P1-5)
  * `mixed_game_sequence: List<GameDef>` (P1-6)
  * `current_game_index: int` (P1-6)
  * `game_transition_pending: bool` (P1-6)
  * `cards_tabled: bool` (Seat 필드, P1-8)
  * `missed_sb: bool` (Seat 필드, P2-13)
  * `missed_bb: bool` (Seat 필드, P2-13)
- **신규 이벤트 2개** (BS-06-09):
  * `ManagerRuling { decision, target_seat, rationale }` (P1-8, P2-10)
  * `DealCommunityRecovery { extra_card, new_flop }` (P1-7)
- **코드 수정 연계 (P0)**: `ebs_game_engine/lib/core/rules/betting_rules.dart`
  * `case AllIn()`: incomplete all-in 감지 및 `actedThisRound` 보존 로직 (Rule 96)
  * `case Raise()`: under-raise 50% 보정 또는 Call 변환 (Rule 95)
  * `_canRaise()`: `tournament_heads_up` 필드 반영 (Rule 100)

### Team 4 (CC) — 영향 3건
1. **ManagerRuling UI**: manager discretion 판정 버튼 추가 (folded hand retrieve, muck retrieve, kill hand)
2. **Mixed Omaha 전환 시각화**: 현재 핸드가 "game transition" 임을 CC 화면에 표시 (button freeze 중)
3. **Pot Size Display Policy 준수**: NL/FL 게임에서 플레이어 대상 pot 정확 금액 숨김 옵션 (Rule 101)

### Contracts 영향 (후속 CCR 필요 가능)
- `contracts/api/API-04-overlay-output.md`: OutputEvent 카탈로그에 `ManagerRuling`, `DealCommunityRecovery` 소비 계약 추가 필요
- **이 DRAFT는 우선 engine-spec 내부 변경만 다룸**. `contracts/` 영향은 본 DRAFT 승인 후 별도 CCR-DRAFT로 분리 제출 예정.

### 마이그레이션
- Phase 1 (P0) 이전 녹화된 핸드 리플레이: Rule 96 로직 변경 전후 결과가 다를 수 있음 → event log에 엔진 버전 스탬프 필요 (후속 과제)
- 기획서만 수정하는 Phase 1~4는 backward incompatibility 없음 (문서 변경)
- 코드 변경은 Phase 1 완료 후 별도 세션에서 진행하며, CI 단위 테스트 Green 조건 하 merge

---

## 대안 검토

| 대안 | 장점 | 단점 | 채택 여부 |
|------|------|------|:--------:|
| **각 Rule별 개별 CCR 18개** | 승인 granularity 최대 | 관리 오버헤드 과다, cross-reference 단절 | ❌ |
| **Phase별 분리 CCR (4개)** | Phase 단위 리뷰 | P0/P1 간 state 필드 공유 (`tournament_heads_up`) 설명 중복 | ❌ |
| **단일 통합 CCR-DRAFT** | 리뷰 용이, 추적성 확보, 우선순위별 단계 적용 가능 | 문서 길이 증가 | ✅ 채택 |
| **CCR 없이 직접 BS-06 수정** | 즉시 반영 | Team 4 영향 리뷰 기회 없음, 대규모 변경의 추적성 부족 | ❌ |
| **Confluence 미러 → 자동 동기화** | 장기 유지보수 | 도구 개발 비용 크고 1회성 작업에 비효율 | ❌ |

---

## 검증 방법

### 1. 문서 일관성 검증
- 각 BS-06 파일이 `BS-06-00-REF` Ch1 state fields와 참조 정합 확인
- 모든 수정 섹션에 "(Rule XX)" 형태로 WSOP 근거 인용 확인
- Edit History에 "2026-04-10 | WSOP 규정 반영 | CCR-DRAFT-team3-20260410 참조" 항목 추가 확인

### 2. 코드 연계 검증 (Phase 1 P0만)
- `ebs_game_engine/lib/core/rules/betting_rules.dart` 수정 후:
  * 기존 574+ TC 회귀 테스트 통과 (`cd ebs_game_engine && dart test`)
  * 신규 TC 3개 추가:
    - `test/all_in_below_min_raise_test.dart` (Rule 96)
    - `test/under_raise_50_percent_test.dart` (Rule 95)
    - `test/heads_up_cap_tournament_vs_hand_test.dart` (Rule 100)
- CI Green 상태 확인 후 merge

### 3. WSOP 추적성 검증
- 본 DRAFT의 각 제안이 원본 WSOP Rule과 1:1 매핑되는지 리뷰어 확인
- 원본 경로: `C:\claude\wsoplive\docs\confluence-mirror\WSOP Live 홈\0. WSOP Rules\`

### 4. Team 4 영향 리뷰
- `ManagerRuling` 이벤트 소비 측 UX 플로우 검토 (CC 운영자용 판정 버튼)
- `Mixed Omaha` 전환 시각화 UI 설계 검토
- Pot Size Display Policy 설정 UI 설계 검토

---

## 승인 요청

- [ ] 사용자 (Team 3 Lead) 승인
- [ ] Team 4 (CC) 영향 검토 (ManagerRuling, Mixed Omaha, Pot Display)
- [ ] Conductor 계약 영향 검토 (후속 contracts/api/API-04 CCR 필요 여부 판단)

---

## 적용 절차 (승인 후)

이 DRAFT는 **review-only**이며 자동 promotion(`tools/ccr_promote.py`) 대상이 아니다. 대상 파일이 `team3-engine/` 내부이므로 Team 3이 직접 수정한다. CCR-DRAFT 문서는 변경 근거와 추적성을 위한 제안서 역할.

### Phase 1 — P0 CRITICAL (3건, 최우선)
1. `BS-06-02-holdem-betting.md` §4.4 "Under-raise 처리 (Rule 95)" 신설
2. `BS-06-02-holdem-betting.md` §4.5 "Raise Cap 적용 (Rule 100)" 표 추가
3. `BS-06-02-holdem-betting.md` §5.3 "All-in Below Minimum Raise (Rule 96)" 신설
4. `BS-06-00-REF-game-engine-spec.md` Ch1 state fields에 `tournament_heads_up: bool` 추가
5. (별도 세션) `betting_rules.dart` 코드 수정 + 3개 신규 TC

### Phase 2 — P1 HIGH (5건)
1. `BS-06-03-holdem-blinds-ante.md` §5.2 "Heads-up 전환 시 Button 조정 (Rule 87)" + §5.3 딜링 순서
2. `BS-06-01-holdem-lifecycle.md` §9.2 "Bomb Pot — Button Freeze & Opt-Out (Rule 28.3.2)"
3. `BS-06-00-REF.md` Ch1.9 "Mixed Game Rotation & Button Freeze"
4. `BS-06-08-holdem-exceptions.md` §3.4 "Four-Card Flop 복구 (Rule 89)"
5. `BS-06-07-holdem-showdown.md` §7 "핸드 보호 & 복구 (Rule 71/110)" + `BS-06-09` ManagerRuling/DealCommunityRecovery 이벤트 신설

### Phase 3 — P2 MEDIUM (6건)
1. `BS-06-02-holdem-betting.md` §1.1 "베팅 입력 방식 (Rule 56 참조)"
2. `BS-06-07-holdem-showdown.md` §6.2 "Muck 카드 재판정 (Rule 109)"
3. `BS-06-00-REF.md` Ch7.5 "Pot Size Display Policy (Rule 101)"
4. `BS-06-01-holdem-lifecycle.md` §8.4 "Run It Multiple vs Rabbit Hunting (Rule 81)"
5. `BS-06-03-holdem-blinds-ante.md` §7 "Missed Blind 복귀 규정 (Rule 86)"
6. `BS-06-08-holdem-exceptions.md` §5 "Deck Change 절차 (Rule 78)"

### Phase 4 — P3 LOW (4건, 선택)
- P3-15 ~ P3-18 (참조 주석 또는 선택적 event)

### Phase 5 — 각 BS-06 파일 Edit History 업데이트
```markdown
| 2026-04-10 | WSOP 규정 반영 | CCR-DRAFT-team3-20260410-wsop-conformance 참조. Rules XX, XX, ... 반영 |
```

### Phase 6 — Contracts 후속 CCR (별도 세션)
`contracts/api/API-04-overlay-output.md`에 `ManagerRuling`, `DealCommunityRecovery` 이벤트 소비 계약 추가를 위한 후속 CCR-DRAFT 작성. Conductor 검토 → `ccr_promote.py` 자동 promotion.

---

## 부록: WSOP 원본 참조

본 DRAFT에서 인용한 모든 WSOP Rule은 다음 원본 문서에서 verbatim 추출:

- `C:\claude\wsoplive\docs\confluence-mirror\WSOP Live 홈\0. WSOP Rules\2021 World Series of Poker® Official Tournament Rules\WSOP Official Live Action Rules.md`
- `C:\claude\wsoplive\docs\confluence-mirror\WSOP Live 홈\0. WSOP Rules\2021 World Series of Poker® Official Tournament Rules.md`
- `C:\claude\wsoplive\docs\confluence-mirror\WSOP Live 홈\0. WSOP Rules\2021 World Series of Poker® Official Tournament Rules\2022 World Series of Poker® Official Tournament Rules(번역).md`
- `C:\claude\wsoplive\docs\confluence-mirror\WSOP Live 홈\1. Documents\Player App\Tournament Clock (APP + Display)\New Blind Type _ Mixed Omaha.md`

각 제안의 "WSOP Rule" 블록은 원문 그대로 인용되었으며, 번역/해석은 하지 않았다.
