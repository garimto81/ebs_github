# QA-GE-05 — 예외 시나리오 검증

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Master Plan §8.6 확장 — 예외 시나리오 TC 상세화 |

---

## 개요

Game Engine의 예외 시나리오 처리를 검증한다. Miss Deal, Run It Twice, Bomb Pot, 플레이어 이탈, 타임아웃, 카드 부족 등 정상 핸드 진행을 벗어나는 6가지 예외 유형의 감지, 복구, 상태 정합성을 포함한다.

---

## 예외 유형 요약

| 예외 | 트리거 소스 | 복구 방식 |
|------|-----------|----------|
| Miss Deal | Engine 자동 (RFID 불일치 감지) | 핸드 무효화, 전체 스택 원상 복구 |
| Run It Twice | CC 수동 (All-In 후 동의) | 복수 보드 생성, 독립 판정 |
| Bomb Pot | CC 수동 (SetBombPot) | 전원 강제 투입, PRE_FLOP 스킵 |
| 플레이어 이탈 | Engine 자동 (연결 단절) | sitting_out + 자동 Fold |
| 타임아웃 | Engine 자동 (timeout 초과) | 자동 Fold 또는 Check |
| 카드 부족 | Engine 자동 (덱 소진) | 커뮤니티 카드 전환 |

---

## TC 목록

### TC-G1-006-01: Miss Deal

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인, P0(5000)~P5(5000), BB=100, SB=50, Dealer=P0 |
| **Hole Cards** | P0: `As Kd`, P1: `Qh Jc`, P2~P5: 각 2장 정상 배분 |
| **Board** | 없음 (PRE_FLOP 단계) |
| **Actions** | PRE_FLOP 진행 중, RFID에서 P3 카드 불일치 감지 → Engine 자동: MisdealDetected 이벤트 발생 |
| **기대 결과** | 핸드 무효화. game_phase=IDLE. 모든 플레이어 스택 원상 복구(SB, BB 포함 반환). pot=0. 다음 핸드 재시작 가능 상태. Dealer 버튼 위치 변경 없음 |
| **판정 기준** | `game_phase == IDLE`, `pot == 0`, `P0.stack == P1.stack == ... == 5000`, `dealer_seat` 변경 없음, 이벤트 로그에 `MisdealDetected` 기록 |
| **참조** | BS-06-08 §MisDeal |

### TC-G1-006-02: Run It Twice

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 2인, P0(5000), P1(5000), BB=100, SB=50, Dealer=P0(=SB) |
| **Hole Cards** | P0: `As Ad`, P1: `Ks Kh` |
| **Board** | FLOP: `7c 4d 2s` (FLOP 완료 시점 All-In) |
| **Actions** | FLOP: P0 All-In(4900) → P1 Call(4900). CC 수동: SetRunItTimes(2). Run 1 Board: `7c 4d 2s Jh 8c`, Run 2 Board: `7c 4d 2s Th 3s` |
| **기대 결과** | Run 1: P0 승 (Pair A > Pair K). Run 2: P0 승 (Pair A > Pair K). 동일 승자 양쪽 → P0 전체 팟(10000) 획득 |
| **판정 기준** | `runs.length == 2`, `runs[0].winner == [P0]`, `runs[1].winner == [P0]`, `P0.awarded == 10000`, `P1.awarded == 0` |
| **참조** | BS-06-08 §RunItMultiple |

### TC-G1-006-02a: Run It Twice — 각 런 다른 승자

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 2인, P0(5000), P1(5000), BB=100, SB=50, Dealer=P0(=SB) |
| **Hole Cards** | P0: `Ah Kh`, P1: `Qd Qc` |
| **Board** | FLOP: `Qs 9h 2d` (FLOP 완료 시점 All-In) |
| **Actions** | FLOP: P0 All-In(4900) → P1 Call(4900). CC 수동: SetRunItTimes(2). Run 1 Board: `Qs 9h 2d Jd 4c`, Run 2 Board: `Qs 9h 2d Kd As` |
| **기대 결과** | Run 1: P1 승 (Trips Q). Run 2: P0 승 (TwoPair A-K). Pot 50/50 분할: P0 5000, P1 5000 |
| **판정 기준** | `runs[0].winner == [P1]`, `runs[1].winner == [P0]`, `P0.awarded == 5000`, `P1.awarded == 5000` |
| **참조** | BS-06-08 §RunItMultiple |

### TC-G1-006-02b: Run It Three Times

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 2인, P0(5000), P1(5000), BB=100, SB=50, Dealer=P0(=SB) |
| **Hole Cards** | P0: `Jh Jd`, P1: `Ts Tc` |
| **Board** | FLOP: `8c 5d 3s` (FLOP 완료 시점 All-In) |
| **Actions** | FLOP: P0 All-In(4900) → P1 Call(4900). CC 수동: SetRunItTimes(3). Run 1~3: 각각 독립 TURN+RIVER |
| **기대 결과** | 3회 독립 판정. Pot = 10000. 각 런 승자에게 10000/3 ≈ 3333. Odd chip(1) → Dealer 좌측 첫 eligible 플레이어 |
| **판정 기준** | `runs.length == 3`, 각 런 독립 승자, 총 분배액 == 10000, Odd chip 규칙 적용 |
| **참조** | BS-06-08 §RunItMultiple |

### TC-G1-006-03: Bomb Pot

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인, P0(5000)~P5(5000), BB=100, SB=50, Dealer=P0 |
| **Hole Cards** | P0~P5: 각 2장 배분 |
| **Board** | `Kh 9d 4c` (FLOP 직행) |
| **Actions** | CC 수동: SetBombPot(amount=500). 전원 500 자동 수납 → PRE_FLOP 스킵 → FLOP 직행. FLOP: P1 Bet(500) → P2 Call → 나머지 Fold |
| **기대 결과** | Bomb Pot contribution = 500 x 6 = 3000. PRE_FLOP 베팅 라운드 없음. FLOP에서 action_on 재설정 (Dealer 좌측부터). 정상 진행 |
| **판정 기준** | `pot >= 3000` (FLOP 시작 시), `game_phase` PRE_FLOP 건너뜀, `action_on` Dealer 좌측 첫 active 플레이어부터 시작 |
| **참조** | BS-06-08 §BombPot |

### TC-G1-006-03a: Bomb Pot + Short Contribution → Side Pot

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인, P0(300), P1(5000)~P5(5000), BB=100, SB=50, Dealer=P0(=SB) |
| **Hole Cards** | P0~P5: 각 2장 배분 |
| **Board** | `Jh 8d 3c` (FLOP 직행) |
| **Actions** | CC 수동: SetBombPot(amount=500). P0 최대 300 수납(short), P1~P5 각 500 수납 → PRE_FLOP 스킵 → FLOP 직행 |
| **기대 결과** | Main Pot = 300 x 6 = 1800 (P0 eligible). Side Pot = 200 x 5 = 1000 (P1~P5만 eligible). P0은 Main Pot만 수상 가능 |
| **판정 기준** | `pots.length == 2`, `pots[0].amount == 1800`, `pots[0].eligible` P0 포함, `pots[1].amount == 1000`, `pots[1].eligible` P0 미포함 |
| **참조** | BS-06-08 §BombPot |

### TC-G1-006-04: 플레이어 이탈 — Mid-Hand

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인, P0(5000)~P5(5000), BB=100, SB=50, Dealer=P0 |
| **Hole Cards** | P0~P5: 각 2장 배분 |
| **Board** | FLOP: `Kh 9d 4c` |
| **Actions** | PRE_FLOP: 전원 Call. FLOP 시작 후 P3 이탈 (연결 단절) |
| **기대 결과** | P3 status=sitting_out. P3 자동 Fold. 나머지 5인 핸드 계속 진행. P3 기여분(100)은 Pot에 잔류 (Dead Money) |
| **판정 기준** | `players[3].status == sitting_out`, `players[3].action == fold`, `activePlayers.length == 5`, `pot` P3 기여분 포함 |
| **참조** | BS-06-08 §PlayerDisconnect |

### TC-G1-006-05: 타임아웃 — Fold (베팅 있을 때)

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 3인, P0(5000), P1(5000), P2(5000), BB=100, SB=50, Dealer=P0, timeout_seconds=30 |
| **Hole Cards** | P0: `As Kd`, P1: `Qh Jc`, P2: `7c 2d` |
| **Board** | FLOP: `9h 5d 3c` |
| **Actions** | FLOP: P1 Bet(200) → P2 action_on 상태에서 30초 초과 |
| **기대 결과** | P2 자동 Fold. 베팅이 존재하므로 Check 불가 → Fold 실행 |
| **판정 기준** | `players[2].action == fold`, `players[2].timedOut == true`, 핸드 계속 진행 |
| **참조** | BS-06-08 §Timeout |

### TC-G1-006-05a: 타임아웃 + Check 가능 → 자동 Check

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 3인, P0(5000), P1(5000), P2(5000), BB=100, SB=50, Dealer=P0, timeout_seconds=30 |
| **Hole Cards** | P0: `As Kd`, P1: `Qh Jc`, P2: `7c 2d` |
| **Board** | FLOP: `9h 5d 3c` |
| **Actions** | FLOP: P1 Check → P2 action_on 상태에서 30초 초과 (현재 베팅 없음) |
| **기대 결과** | P2 자동 Check. 베팅 없으므로 Fold가 아닌 Check 실행 |
| **판정 기준** | `players[2].action == check`, `players[2].timedOut == true`, 핸드 계속 진행 |
| **참조** | BS-06-08 §Timeout |

### TC-G1-006-05b: 타임아웃 + Call 필요 → 자동 Fold

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 3인, P0(5000), P1(5000), P2(5000), BB=100, SB=50, Dealer=P0, timeout_seconds=30 |
| **Hole Cards** | P0: `As Kd`, P1: `Qh Jc`, P2: `7c 2d` |
| **Board** | TURN: `9h 5d 3c Kc` |
| **Actions** | TURN: P1 Raise(500) → P2 action_on 상태에서 30초 초과 (Call 500 필요) |
| **기대 결과** | P2 자동 Fold. Call 금액 존재 → Fold |
| **판정 기준** | `players[2].action == fold`, `players[2].timedOut == true`, P2 기여분은 Pot에 잔류 |
| **참조** | BS-06-08 §Timeout |

### TC-G1-006-06: 카드 부족 — Stud 8인 테이블

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 3 |
| **우선순위** | P2 |
| **Players** | 8인, P0(5000)~P7(5000), ante=25, bring-in=50. game_type=7CardStud |
| **Hole Cards** | P0~P7: 각 3장 초기 배분 (3rd Street). 이후 4th~6th Street: 각 1장 추가 |
| **Board** | 없음 (Stud) |
| **Actions** | 3rd~6th Street 정상 진행. 7th Street 시작 시 덱 잔여 = 52 - (8x6) = 4장. 8인에게 각 1장 필요(8장) → 4장 부족 |
| **기대 결과** | 잔여 덱 4장은 4명에게 배분. 나머지 4명은 공용 커뮤니티 카드 1장 공개로 대체. 전원 해당 커뮤니티 카드 공유 |
| **판정 기준** | `communityCard != null`, `communityCard` 전원 공유, 7th Street 정상 완료, 핸드 평가에 공유 카드 포함 |
| **참조** | BS-06-08 §CardShortage |
