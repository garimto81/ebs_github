# BS-06-13: Omaha — Flop Extension

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-06 | 신규 작성 | Omaha 6종 Hold'em 대비 차이점 정의 (Must-Use 2+3, Hi-Lo split, RFID burst) |
| 2026-04-09 | Phase 표시 | **Phase 3 범위** — Hold'em Core 구현 완료 후 착수 |

---

> **이 문서에서 사용하는 용어**
>
> | 용어 | 설명 |
> |------|------|
> | FSM | 게임 진행 단계를 정의한 상태 흐름도 (Finite State Machine) |
> | RFID | 무선 주파수로 카드를 자동 인식하는 기술. 카드에 내장된 IC를 테이블 센서가 읽는다 |
> | evaluator | 카드 조합을 분석하여 승자를 결정하는 함수 |
> | coalescence | 여러 센서 신호가 동시에 들어올 때 하나로 합치는 처리 규칙 |
> | CC | Command Center, 운영자가 게임을 제어하는 화면 |
> | Hi-Lo | 팟을 가장 높은 패와 가장 낮은 패로 나누어 분배하는 방식 |
> | must-use 2+3 | 홀카드에서 반드시 2장, 보드에서 반드시 3장을 사용해야 하는 Omaha 계열 규칙 |
> | 8-or-better | 8 이하 카드로만 구성된 패만 Low 자격이 있다는 조건 |
> | scoop | 한 사람이 High와 Low 모두 이겨서 팟 전체를 가져가는 것 |
> | odd chip | 팟을 나눌 때 딱 떨어지지 않는 나머지 1개 베팅 토큰 |
> | C(n,2) | n장에서 2장을 고르는 조합의 수 (수학 조합 표기) |
> | antenna | RFID 카드를 감지하는 센서 (seat antenna = 좌석 센서, board antenna = 공용 카드 센서) |

## 개요

Hold'em과 동일한 FSM을 따르되, 홀카드 수가 4/5/6장이며 **반드시 홀카드 2장 + 보드 3장**으로 핸드를 구성해야 한다. Hi-Lo 변형은 팟을 High/Low로 분할한다.

---

## 대상 게임

| `game_id` | 이름 | `hole_cards` | Hi-Lo |
|:--:|------|:--:|:--:|
| 4 | omaha | 4 | N |
| 5 | omaha_hilo | 4 | Y |
| 6 | omaha5 | 5 | N |
| 7 | omaha5_hilo | 5 | Y |
| 8 | omaha6 | 6 | N |
| 9 | omaha6_hilo | 6 | Y |

---

## Hold'em과의 차이점 요약

| 항목 | Hold'em | Omaha |
|------|---------|-------|
| `hole_cards` | 2장 | 4/5/6장 |
| 조합 규칙 | best 5 of 7 | **must use 2+3** |
| `evaluator` | `standard_high` | `standard_high` 또는 `hilo_8or_better` |
| RFID burst(여러 카드가 동시에 감지되는 현상) (6인) | 12 이벤트 | 24/30/36 이벤트 |

---

## 핵심 규칙: Must-Use 2+3

**반드시** `hole_cards` 중 정확히 2장 + `board_cards` 중 정확히 3장 = 5장 핸드를 구성한다.

- Hold'em의 "best 5 of 7"과 다름 — 홀카드 0장 또는 1장만 사용하는 것은 **무효**
- 보드 5장만으로 핸드 구성 **불가**
- Omaha 5/6: 5 또는 6장 홀카드 중 2장 선택 (조합 수 증가)

### 조합 수

| `hole_cards` | 홀카드 조합 C(n,2)(n장에서 2장을 고르는 조합의 수) | 보드 조합 C(5,3) | 총 평가 조합 |
|:--:|:--:|:--:|:--:|
| 4 | 6 | 10 | 60 |
| 5 | 10 | 10 | 100 |
| 6 | 15 | 10 | 150 |

> 참고: Hold'em은 C(7,5) = 21 조합. Omaha 6은 150 조합으로 평가 연산량이 7배 이상 증가한다.

---

## FSM 변경 사항

**없음** — Hold'em FSM 그대로 사용한다 (IDLE → SETUP_HAND → PRE_FLOP → FLOP → TURN → RIVER → SHOWDOWN → HAND_COMPLETE).

---

## 카드 배분

| 게임 | 홀카드/인 | RFID 이벤트 (6인) | Hold'em 대비 배수 |
|------|:--:|:--:|:--:|
| Omaha 4 | 4장 | 24 | 2배 |
| Omaha 5 | 5장 | 30 | 2.5배 |
| Omaha 6 | 6장 | 36 | 3배 |

- RFID burst가 Hold'em 대비 2~3배 → coalescence 윈도우 내 이벤트 수 증가
- 보드 카드 5장은 Hold'em과 동일

---

## 핸드 평가 변경 사항

### standard_high — game 4, 6, 8

- 평가기는 Hold'em과 동일하지만 **입력이 다름**
- 모든 C(n,2) x C(5,3) 조합을 열거하여 최고 핸드를 선택
- Hold'em: 7장 중 best 5 (C(7,5) = 21)
- Omaha 4: C(4,2) x C(5,3) = 60
- Omaha 5: C(5,2) x C(5,3) = 100
- Omaha 6: C(6,2) x C(5,3) = 150

### Hi-Lo — hilo_8or_better — game 5, 7, 9

**High pot**: `standard_high` 평가와 동일 (must-use 2+3 적용)

**Low pot**: 다음 조건을 **모두** 충족해야 Low 자격 성립
- 5장 모두 rank <= 8
- 5장 모두 다른 rank
- A = Low (1로 계산)
- must-use 2+3 규칙 동일 적용 (홀 2장 + 보드 3장)

**8-or-better 자격 미충족 시**: High가 전체 팟 수령 (**scoop**)

**팟 분할 규칙**:
- High half + Low half
- High/Low 동일 플레이어 가능 (scoop)
- odd chip은 **High**에 배분

### Hi-Lo 경우의 수 매트릭스

| High 승자 | Low 자격 | Low 승자 | 팟 분배 |
|:--:|:--:|:--:|------|
| 플레이어 A | 충족 | 플레이어 B | A: 50%, B: 50% |
| 플레이어 A | 충족 | 플레이어 A | A: 100% (scoop) |
| 플레이어 A | 미충족 | — | A: 100% (scoop) |
| 플레이어 A (타이) | 충족 | 플레이어 B | High 타이 분할 + Low 50% |
| 플레이어 A | 충족 | 타이 (B, C) | A: 50%, B: 25%, C: 25% |

---

## Coalescence 변경 사항

- RFID burst 증가로 `MAX_QUEUE_SIZE` = 32 초과 가능성 발생
- Omaha 4: 6인 x 4장 = 24 이벤트 → 큐 범위 내
- Omaha 5: 6인 x 5장 = 30 이벤트 → 큐 범위 내
- **Omaha 6: 6인 x 6장 = 36 이벤트 → `MAX_QUEUE_SIZE` = 32 초과**

### Omaha 6 큐 오버플로우 처리

| 조건 | 처리 | 근거 |
|------|------|------|
| `len(Event_Q)` >= 32 | 최저 우선순위 이벤트 폐기 | Hold'em coalescence 규칙 동일 |
| 폐기된 이벤트 | 로그 기록: `QUEUE_OVERFLOW` | 운영자에게 재스캔 안내 |
| 홀카드 vs 보드 | 홀카드가 보드보다 높은 서브 우선순위 | RFID 서브 우선순위 규칙 적용 |

> 참고: Omaha 6은 유일하게 `MAX_QUEUE_SIZE`를 초과할 수 있는 게임이다. 구현 시 큐 사이즈 확장 또는 배치 처리 검토가 필요하다.

---

## 유저 스토리

1. **Omaha 4 정상 흐름**: 홀카드 4장 RFID 감지 → 좌석별 4장 기록 → PRE_FLOP 베팅 → FLOP~RIVER → SHOWDOWN (must-use 2+3 평가)
2. **Omaha 5 카드 미감지**: 5장 감지 중 1장 미감지 → **RFID_MISSING_CARD** 에러 → 운영자에게 수동 입력 요청
3. **Hi-Lo: Low 자격 없음**: SHOWDOWN에서 모든 플레이어의 Low 조합이 8-or-better 미충족 → High가 전체 팟 수령 (scoop)
4. **Hi-Lo: High/Low 동일 플레이어**: 플레이어 A가 High와 Low 모두 최고 → scoop (100% 수령)
5. **Hi-Lo: High/Low 다른 플레이어**: 플레이어 A가 High, 플레이어 B가 Low → 팟 50/50 분할, odd chip은 High(A)에
6. **Omaha 6 RFID burst**: 36 RFID 이벤트 도착 → `MAX_QUEUE_SIZE` = 32 초과 → 최저 우선순위 이벤트 4개 폐기 → `QUEUE_OVERFLOW` 로그 기록

---

## 예외 처리 변경 사항

| 예외 | Hold'em 대비 변경 | 처리 |
|------|------------|------|
| RFID burst 실패 확률 | 홀카드 수 증가로 **상승** | 수동 입력 전환 임계값 동일 (3회 연속 에러) |
| 큐 오버플로우 | Hold'em에서는 미발생 | Omaha 6 전용: 최저 우선순위 폐기 |
| must-use 2+3 위반 | Hold'em에서는 해당 없음 | 평가기가 자동 적용 (사용자 선택 아님) |

---

## 구현 체크리스트

- [ ] `hole_cards` 4/5/6장 배분 및 RFID 감지
- [ ] Must-Use 2+3 조합 평가 (C(n,2) x C(5,3))
- [ ] Hi-Lo split 알고리즘 (`hilo_8or_better`)
- [ ] Low 자격 미충족 시 High scoop
- [ ] Odd chip → High 우선
- [ ] Omaha 6 RFID burst 36 이벤트 처리
- [ ] `MAX_QUEUE_SIZE` 초과 시 큐 오버플로우 처리
