# QA-GE-02 — Blinds / Ante 7종 검증

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Master Plan §8.3 확장 — Ante 7종 TC 상세화 |

---

## 개요

Game Engine의 Blind/Ante 수거 로직 7종을 검증한다. 각 ante_type별 납부자, 수거 순서, Dead/Live Money 구분, 팟 계산 정확성을 확인한다.

---

## Ante 7종 매트릭스

| ante_type | 이름 | 납부자 | Dead/Live | 수거 순서 |
|:---------:|------|--------|:---------:|----------|
| 0 (std) | Standard Ante | 전원 | Dead | Dealer 좌측부터 순회 |
| 1 (button) | Button Ante | Dealer만 | Dead | Dealer 단독 |
| 2 (bb) | BB Ante | BB만 | Dead | BB 단독 |
| 3 (bb_bb1st) | BB Ante (BB 선행) | BB만 | Dead | BB Ante → SB Blind → BB Blind |
| 4 (live) | Live Ante | UTG | Live | UTG 단독 (콜 시 베팅 인정) |
| 5 (tb) | Table Ante | Dealer 대신 | Dead | Dealer 위치에서 총액 수거 |
| 6 (tb_tb1st) | Table Ante (선행) | Dealer 대신 | Dead | Table Ante → SB Blind → BB Blind |

---

## TC 목록

### TC-G1-003-01: Standard Ante — 전원 수거

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 1 |
| **우선순위** | P0 |
| **Players** | 6인 (P0~P5), stack=10000 each, BB=1000, SB=500, Dealer=P0 |
| **Hole Cards** | N/A (수거 단계 검증) |
| **Board** | N/A |
| **Actions** | Engine 자동: ante_type=0, ante=100 → 전원(P0~P5) stack -= 100 → SB(P1) stack -= 500 → BB(P2) stack -= 1000 |
| **기대 결과** | pot = 600(ante 6x100) + 500(SB) + 1000(BB) = 2100. 각 플레이어 stack: P0=9900, P1=9400, P2=8900, P3~P5=9900 |
| **판정 기준** | `gameState.pots[0].amount == 2100`, 모든 `player.stack` 정확 |
| **참조** | BS-06-03 §1 |

### TC-G1-003-01a: Standard Ante + 칩 부족 All-In

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인, P3 stack=50 (ante=100 미만), 나머지 stack=10000, BB=1000, SB=500, Dealer=P0 |
| **Hole Cards** | N/A |
| **Board** | N/A |
| **Actions** | Engine 자동: ante=100 → P3 All-In(50) → 나머지 5인 ante=100 정상 수거 → SB/BB 수거 |
| **기대 결과** | P3 stack=0, All-In 상태. pot = 50(P3) + 500(P0~P2,P4,P5 ante) + 500(SB) + 1000(BB) = 2050. P3은 Main Pot eligible (최대 50x6=300 기여분) |
| **판정 기준** | `P3.isAllIn == true`, `P3.stack == 0`, Side Pot 분리 정상 |
| **참조** | BS-06-03 §1, BS-06-06 |

### TC-G1-003-01b: Standard Ante — Heads-Up (2인)

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 2인 (P0, P1), stack=10000 each, BB=1000, SB=500, Dealer=P0(=SB) |
| **Hole Cards** | N/A |
| **Board** | N/A |
| **Actions** | Engine 자동: ante=100 → P0 ante(100) + SB(500) → P1 ante(100) + BB(1000) |
| **기대 결과** | pot = 200(ante 2x100) + 500(SB) + 1000(BB) = 1700. P0 stack=9400, P1 stack=8900 |
| **판정 기준** | `gameState.pots[0].amount == 1700`, Heads-Up에서 Dealer=SB 규칙 적용 확인 |
| **참조** | BS-06-03 §1 |

### TC-G1-003-02: Button Ante — Dealer만 수거

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인, stack=10000 each, BB=1000, SB=500, ante=500, Dealer=P0 |
| **Hole Cards** | N/A |
| **Board** | N/A |
| **Actions** | Engine 자동: ante_type=1 → P0(Dealer)만 stack -= 500 → SB(P1) -= 500 → BB(P2) -= 1000 |
| **기대 결과** | pot = 500(button ante) + 500(SB) + 1000(BB) = 2000. P0 stack=9500, P1=9500, P2=9000, P3~P5=10000 |
| **판정 기준** | `P0.stack == 9500`, P3~P5 stack 변동 없음, `pots[0].amount == 2000` |
| **참조** | BS-06-03 §2 |

### TC-G1-003-03: BB Ante — BB만 수거

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인, stack=10000 each, BB=1000, SB=500, ante=1000, Dealer=P0, SB=P1, BB=P2 |
| **Hole Cards** | N/A |
| **Board** | N/A |
| **Actions** | Engine 자동: ante_type=2 → P2(BB)만 ante(1000) + BB(1000) 수거 → SB(P1) -= 500 |
| **기대 결과** | pot = 1000(ante) + 500(SB) + 1000(BB) = 2500. P2 stack=8000, P1=9500, 나머지=10000 |
| **판정 기준** | P2만 2000 공제, 나머지(P0,P3~P5) stack 변동 없음 |
| **참조** | BS-06-03 §3 |

### TC-G1-003-04: BB Ante (BB 선행) — 수거 순서 검증

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인, stack=10000 each, BB=1000, SB=500, ante=1000, Dealer=P0, SB=P1, BB=P2 |
| **Hole Cards** | N/A |
| **Board** | N/A |
| **Actions** | Engine 자동: ante_type=3 → **순서**: (1) P2 ante(1000) → (2) P1 SB(500) → (3) P2 BB(1000) |
| **기대 결과** | pot = 2500 (동일). 이벤트 로그 순서: `AntePosted(P2,1000)` → `BlindPosted(P1,500)` → `BlindPosted(P2,1000)` |
| **판정 기준** | 이벤트 타임스탬프 순서 검증: ante < SB < BB. 금액은 TC-G1-003-03과 동일 |
| **참조** | BS-06-03 §4 |

### TC-G1-003-05: Live Ante — UTG Live Money

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인, stack=10000 each, BB=1000, SB=500, ante=200, Dealer=P0, SB=P1, BB=P2, UTG=P3 |
| **Hole Cards** | N/A |
| **Board** | N/A |
| **Actions** | Engine 자동: ante_type=4 → P3(UTG) ante(200) = Live Money → SB(P1) -= 500 → BB(P2) -= 1000 |
| **기대 결과** | pot = 200(live ante) + 500(SB) + 1000(BB) = 1700. P3 stack=9800. PRE_FLOP 액션 순서: P4 → P5 → P0 → P1 → P2 → P3(라이브 앤티 = 이미 200 기여, Call 시 추가 800으로 1000 매칭) |
| **판정 기준** | `P3.liveAnte == true`, P3의 Call 금액 = BB - ante = 800 (1000 - 200). action_on 순서에서 P3 마지막 |
| **참조** | BS-06-03 §5 |

### TC-G1-003-06: Table Ante — Dealer 대신 수거

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인, stack=10000 each, BB=1000, SB=500, ante=600 (총액), Dealer=P0 |
| **Hole Cards** | N/A |
| **Board** | N/A |
| **Actions** | Engine 자동: ante_type=5 → Dealer 위치(P0)에서 총액 600 수거 → SB(P1) -= 500 → BB(P2) -= 1000 |
| **기대 결과** | pot = 600(table ante) + 500(SB) + 1000(BB) = 2100. P0 stack=9400, P1=9500, P2=9000, P3~P5=10000 |
| **판정 기준** | Dealer(P0)만 600 공제, 개별 플레이어 ante 이벤트 없음 (단일 `TableAntePosted` 이벤트) |
| **참조** | BS-06-03 §6 |

### TC-G1-003-07: Table Ante (선행) — 수거 순서 검증

| 항목 | 값 |
|------|:--|
| **Phase** | Phase 2 |
| **우선순위** | P1 |
| **Players** | 6인, stack=10000 each, BB=1000, SB=500, ante=600 (총액), Dealer=P0 |
| **Hole Cards** | N/A |
| **Board** | N/A |
| **Actions** | Engine 자동: ante_type=6 → **순서**: (1) P0 table ante(600) → (2) P1 SB(500) → (3) P2 BB(1000) |
| **기대 결과** | pot = 2100 (동일). 이벤트 로그 순서: `TableAntePosted(P0,600)` → `BlindPosted(P1,500)` → `BlindPosted(P2,1000)` |
| **판정 기준** | 이벤트 타임스탬프 순서 검증: table ante < SB < BB |
| **참조** | BS-06-03 §7 |

---

## 검증 요약

| TC ID | ante_type | 핵심 검증 | Phase | 우선순위 |
|-------|:---------:|----------|:-----:|:--------:|
| TC-G1-003-01 | 0 (std) | 전원 공제 + 팟 합산 | 1 | P0 |
| TC-G1-003-01a | 0 (std) | 칩 부족 All-In 처리 | 2 | P1 |
| TC-G1-003-01b | 0 (std) | Heads-Up Dealer=SB 규칙 | 2 | P1 |
| TC-G1-003-02 | 1 (button) | Dealer만 공제 | 2 | P1 |
| TC-G1-003-03 | 2 (bb) | BB만 공제 | 2 | P1 |
| TC-G1-003-04 | 3 (bb_bb1st) | 수거 순서 (ante 선행) | 2 | P1 |
| TC-G1-003-05 | 4 (live) | Live Money + Call 금액 계산 | 2 | P1 |
| TC-G1-003-06 | 5 (tb) | 총액 수거 + 단일 이벤트 | 2 | P1 |
| TC-G1-003-07 | 6 (tb_tb1st) | 총액 수거 순서 (ante 선행) | 2 | P1 |
