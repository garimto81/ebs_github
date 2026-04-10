# QA-GE-03 — All-In + Side Pot 검증

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Master Plan §8.4 확장 — All-In / Side Pot TC 상세화 |
| 2026-04-09 | TC 추가 | 코드 리뷰 발견: TC-G1-004-07~08 (Side Pot 통합 E2E, Sub-call All-In) |

---

## 개요

Game Engine의 All-In 처리와 Side Pot 분배 알고리즘을 검증한다. 2인~10인 시나리오, 동일/다른 스택, Fold 병행, 역순 판정 순서를 포함한다.

---

## Side Pot 분배 규칙 요약

| 규칙 | 설명 |
|------|------|
| Main Pot | 최소 All-In 금액 x eligible 인원 |
| Side Pot N | 다음 최소 All-In 금액까지의 차액 x 해당 eligible 인원 |
| Eligible Set | 해당 Pot에 최소 해당 금액 이상 기여한 플레이어만 |
| Dead Money | Fold한 플레이어의 기여분은 해당 Pot에 잔류 |
| Odd Chip | 최소 단위 미만 분배 불가 시 Dealer 좌측 첫 eligible 플레이어에게 |
| 판정 순서 | Side Pot (가장 마지막 생성) → ... → Main Pot (역순) |

---

## TC 목록

### TC-G1-004-01: 2인 All-In — 동일 스택

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 1 |
| **우선순위** | P0 |
| **Players** | 2인, P0(5000), P1(5000), BB=100, Dealer=P0(=SB) |
| **Hole Cards** | P0: `As Ad`, P1: `Ks Kh` |
| **Board** | `7c 4d 2s Jh 8c` |
| **Actions** | PRE_FLOP: P0 All-In(5000) → P1 Call(5000) |
| **기대 결과** | Main Pot = 10000, Side Pot 없음. P0 승 (Pair of Aces > Pair of Kings). P0 stack = 10000, P1 stack = 0 |
| **판정 기준** | `pots.length == 1`, `pots[0].amount == 10000`, `pots[0].winners == [P0]` |
| **참조** | BS-06-06 §1 |

### TC-G1-004-02: 2인 All-In — 다른 스택

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 2인, P0(3000), P1(8000), BB=100, Dealer=P0(=SB) |
| **Hole Cards** | P0: `Ah Kh`, P1: `Qd Qc` |
| **Board** | `As 9d 4c 7h 2s` |
| **Actions** | PRE_FLOP: P0 All-In(3000) → P1 Call(3000) |
| **기대 결과** | Main Pot = 6000 (3000 x 2). P1 잔여 5000 반환. P0 승 (Pair of Aces). P0 stack = 6000, P1 stack = 5000 |
| **판정 기준** | `pots.length == 1`, `pots[0].amount == 6000`, P1 미사용 5000 즉시 반환 |
| **참조** | BS-06-06 §2 |

### TC-G1-004-03: 3인 All-In — 모두 다른 스택

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 3인, P0(1000), P1(3000), P2(5000), BB=100, Dealer=P0(=SB) |
| **Hole Cards** | P0: `Ah Ad`, P1: `Ks Kh`, P2: `7c 2d` |
| **Board** | `As Kd Qc Jh Ts` |
| **Actions** | PRE_FLOP: P0 All-In(1000) → P1 All-In(3000) → P2 Call(3000) |
| **기대 결과** | Main Pot = 3000 (1000 x 3), eligible: P0, P1, P2. Side Pot 1 = 4000 (2000 x 2), eligible: P1, P2. P2 잔여 2000 반환. P0 승 Main Pot (Broadway Straight = P1,P2도 동점이나 P0: A-high straight). 실제: 전원 Broadway Straight → Main Pot 3등분(1000 each), Side Pot 1 2등분(2000 each) |
| **판정 기준** | `pots.length == 2`, `pots[0].amount == 3000` (Main), `pots[1].amount == 4000` (Side 1). Split 시 odd chip 규칙 적용 |
| **참조** | BS-06-06 §3 |

### TC-G1-004-03a: 3인 All-In — 승자 분리 (Main ≠ Side)

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 3인, P0(1000), P1(3000), P2(5000), BB=100, Dealer=P0(=SB) |
| **Hole Cards** | P0: `Ah Ad`, P1: `Ks Kh`, P2: `7c 2d` |
| **Board** | `As Kd 4c 8h 3s` |
| **Actions** | PRE_FLOP: P0 All-In(1000) → P1 All-In(3000) → P2 Call(3000) |
| **기대 결과** | Main Pot = 3000, Side Pot 1 = 4000, P2 잔여 2000 반환. **역순 판정**: Side Pot 1 먼저 → P1 승 (Pair of Kings > 7-high). Main Pot → P0 승 (Pair of Aces > Pair of Kings). P0 stack = 3000, P1 stack = 4000, P2 stack = 2000 |
| **판정 기준** | 판정 순서: Side Pot → Main Pot. `pots[1].winners == [P1]`, `pots[0].winners == [P0]` |
| **참조** | BS-06-06 §3 |

### TC-G1-004-04: All-In + 나머지 베팅 계속

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 3인, P0(2000), P1(10000), P2(10000), BB=100, Dealer=P0(=SB) |
| **Hole Cards** | P0: `Jd Jc`, P1: `As Ks`, P2: `Qh Qd` |
| **Board** | `Ah 9c 4d 7s 2c` |
| **Actions** | PRE_FLOP: P0 All-In(2000) → P1 Call(2000) → P2 Call(2000). FLOP: P1 Bet(3000) → P2 Call(3000). TURN: P1 Check → P2 Check. RIVER: P1 Check → P2 Check |
| **기대 결과** | Main Pot = 6000 (2000 x 3), eligible: P0, P1, P2. Side Pot 1 = 6000 (3000 x 2), eligible: P1, P2만. P1 승 전체 (Pair of Aces). P1 stack = 10000 + 2000(Main 이익) + 3000(Side 이익) = 15000. 실제: P1 원래 10000 - 2000 - 3000 = 5000 잔여 + Main 6000 + Side 6000 = 17000 |
| **판정 기준** | P0 All-In 후 FLOP/TURN/RIVER 베팅이 Side Pot에만 반영. Main Pot은 PRE_FLOP에서 확정 |
| **참조** | BS-06-06 §4 |

### TC-G1-004-05: All-In 후 Fold 동시 발생

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 3인, P0(5000), P1(5000), P2(5000), BB=100, Dealer=P0(=SB) |
| **Hole Cards** | P0: `As Ad`, P1: `7c 2d`, P2: `Ks Kh` |
| **Board** | `Ah 9c 4d 7s 2c` |
| **Actions** | PRE_FLOP: P0 Raise(500) → P1 Call(500) → P2 Call(500). FLOP: P0 All-In(4500) → P1 Fold → P2 Call(4500) |
| **기대 결과** | Main Pot = 500(P1 기여, dead money) + 5000(P0) + 5000(P2) = 10500. Side Pot 없음. P1의 500은 Dead Money로 Main Pot에 잔류. P0 승 (Three of a Kind Aces). P0 stack = 10500 |
| **판정 기준** | `pots[0].amount == 10500`, Fold한 P1의 기여분이 Pot에 포함, P1은 eligible set에서 제외 |
| **참조** | BS-06-06 §5 |

### TC-G1-004-06: 10인 전원 All-In

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 10인 (P0~P9), stack = 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, BB=100, Dealer=P0 |
| **Hole Cards** | P0~P9 각각 고유 핸드 (상세 별도) |
| **Board** | `Ah Kd Qc Jh Ts` |
| **Actions** | PRE_FLOP: P0 All-In(1000) → P1 All-In(2000) → ... → P9 All-In(10000) |
| **기대 결과** | 팟 구조 (9개 팟): |

**팟 분배 상세:**

| Pot | 금액 계산 | Eligible |
|-----|----------|----------|
| Main Pot | 1000 x 10 = 10000 | P0~P9 |
| Side Pot 1 | 1000 x 9 = 9000 | P1~P9 |
| Side Pot 2 | 1000 x 8 = 8000 | P2~P9 |
| Side Pot 3 | 1000 x 7 = 7000 | P3~P9 |
| Side Pot 4 | 1000 x 6 = 6000 | P4~P9 |
| Side Pot 5 | 1000 x 5 = 5000 | P5~P9 |
| Side Pot 6 | 1000 x 4 = 4000 | P6~P9 |
| Side Pot 7 | 1000 x 3 = 3000 | P7~P9 |
| Side Pot 8 | 1000 x 2 = 2000 | P8~P9 |

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **기대 결과** | 총 9개 팟, 합계 = 10000+9000+8000+7000+6000+5000+4000+3000+2000 = 54000 (= 전원 stack 합 - P9 잔여 0). 판정 순서: Side Pot 8 → 7 → ... → Main Pot (역순) |
| **판정 기준** | `pots.length == 9`, 각 Pot의 amount/eligible 정확, 역순 판정 순서 로그 검증. 총 분배금 = 55000 (1000+2000+...+10000) |
| **참조** | BS-06-06 §6 |

---

## Side Pot 알고리즘 검증 매트릭스

| 검증 항목 | TC 커버리지 | 판정 기준 |
|----------|-----------|----------|
| Main Pot 단독 (Side Pot 없음) | TC-G1-004-01 | `pots.length == 1` |
| 잔여 금액 반환 | TC-G1-004-02 | 미사용 stack 즉시 반환 |
| Main + Side 1개 | TC-G1-004-02, 04, 05 | `pots.length == 2` |
| Main + Side 다수 | TC-G1-004-03, 06 | `pots.length >= 3` |
| 역순 판정 | TC-G1-004-03a, 06 | Side Pot → Main Pot 순서 |
| Dead Money (Fold 기여분) | TC-G1-004-05 | Fold 플레이어 금액 Pot 잔류 |
| Eligible Set 정확성 | TC-G1-004-03, 04, 06 | All-In 금액 이상 기여자만 |
| 최대 Side Pot 수 | TC-G1-004-06 | 10인 = 최대 9개 Pot |
| 베팅 계속 (Side Pot 추가) | TC-G1-004-04 | FLOP 이후 베팅 → Side Pot |

---

## 검증 요약

| TC ID | 시나리오 | 핵심 검증 | Phase | 우선순위 |
|-------|---------|----------|:-----:|:--------:|
| TC-G1-004-01 | 2인 동일 스택 | Main Pot 단독 | 1 | P0 |
| TC-G1-004-02 | 2인 다른 스택 | 잔여 금액 반환 | 2 | P1 |
| TC-G1-004-03 | 3인 모두 다른 스택 | Main + Side 분리 | 2 | P1 |
| TC-G1-004-03a | 3인 승자 분리 | 역순 판정 (Side ≠ Main 승자) | 2 | P1 |
| TC-G1-004-04 | All-In + 베팅 계속 | Side Pot 추가 생성 | 2 | P1 |
| TC-G1-004-05 | All-In + Fold | Dead Money 처리 | 2 | P1 |
| TC-G1-004-06 | 10인 전원 All-In | 최대 9개 Pot + 역순 판정 | 2 | P1 |
| TC-G1-004-07 | Side Pot 통합 E2E | calculateSidePots → Showdown 자동 연결 | 1 | P0 |
| TC-G1-004-08 | Sub-call All-In | 25 vs 50+50 eligible set | 2 | P1 |

---

## 코드 리뷰 발견 TC (2026-04-09)

### TC-G1-004-07: Side Pot 통합 E2E — calculateSidePots → Showdown 자동 연결

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 1 |
| **우선순위** | P0 |
| **Known Issue** | KI-03 — `Pot.calculateSidePots()` 미호출, `seat.currentBet` Street마다 리셋으로 누적 기여액 소실 |
| **Players** | 3인, P0(1000), P1(3000), P2(5000), BB=100 |
| **Hole Cards** | P0: `Ah Ad`, P1: `Ks Kh`, P2: `7c 2d` |
| **Board** | `As Kd Qc Jh Ts` |
| **Actions** | PRE_FLOP: P0 All-In(1000), P1 All-In(3000), P2 Call(3000) |
| **기대 결과** | Engine이 자동으로 `calculateSidePots` 호출 → Main Pot=3000 (P0,P1,P2), Side Pot=4000 (P1,P2) → Showdown → Main→P0, Side→P1. 현재 구현: `pot.sides` 항상 빈 리스트, 수동 `PotAwarded` 필요 |
| **판정 기준** | `state.pot.sides.length >= 1`, `awards[P0] == 3000`, `awards[P1] == 4000` |
| **참조** | BS-06-06 §Side Pot, `pot.dart` L19-40, `engine.dart` |

> **설계 Gap**: `seat.currentBet`이 Street 전환마다 0으로 리셋. Showdown 시 누적 기여액 복원 불가. `seat.totalInvested` 같은 누적 필드 추가 필요.

### TC-G1-004-08: Sub-call All-In — 콜 미달 금액 All-In

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 3인, P0(50), P1(5000), P2(5000), BB=100 |
| **Hole Cards** | P0: `Ah Kh`, P1: `Qs Qd`, P2: `Jd Td` |
| **Board** | `7c 4d 2s Jh 8c` |
| **Actions** | P1 Bet(100), P0 All-In(50, sub-call), P2 Call(100) |
| **기대 결과** | Main Pot=150 (P0×50, P1×50, P2×50) eligible={P0,P1,P2}. Side Pot=100 (P1×50, P2×50) eligible={P1,P2} |
| **판정 기준** | `sidePots[0].eligible == {P0,P1,P2}`, `sidePots[0].amount == 150`, `sidePots[1].eligible == {P1,P2}`, `sidePots[1].amount == 100` |
| **참조** | BS-06-06 §Sub-call All-In |
