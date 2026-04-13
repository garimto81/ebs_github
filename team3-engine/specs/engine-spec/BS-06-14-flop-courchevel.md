# BS-06-14: Courchevel — Flop Extension

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-06 | 신규 작성 | Courchevel 2종 Hold'em 대비 차이점 정의 (SETUP board_1 공개, FLOP 2장, Hi-Lo) |
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
> | antenna | RFID 카드를 감지하는 센서 (seat antenna = 좌석 센서, board antenna = 공용 카드 센서) |

## 개요

Omaha 5장 방식이지만, SETUP 단계에서 **보드 첫 번째 카드 (`board_1`)**(테이블 위에 공개되는 첫 번째 공용 카드)가 미리 공개된다. FLOP에서는 추가 2장만 공개한다. 핸드 평가는 Omaha와 동일한 must-use 2+3 규칙을 따른다.

---

## 대상 게임

| `game_id` | 이름 | `evaluator` | Hi-Lo |
|:--:|------|------|:--:|
| 10 | courchevel | `standard_high` | N |
| 11 | courchevel_hilo | `hilo_8or_better` | Y |

---

## Hold'em과의 차이점 요약

| 항목 | Hold'em | Courchevel |
|------|---------|------------|
| `hole_cards` | 2장 | 5장 |
| 조합 규칙 | best 5 of 7 | **must use 2+3** |
| SETUP 보드 공개 | 0장 | **1장** (`board_1`) |
| FLOP 보드 감지 | 3장 | **2장** (추가분만) |
| SETUP RFID | seat antenna만 | seat + board antenna **동시** |

---

## FSM 변경 사항

Hold'em FSM의 **SETUP_HAND** 단계가 확장된다. 나머지 상태 전이는 동일.

### SETUP_HAND 확장 정의

| 항목 | Hold'em | Courchevel |
|------|---------|------------|
| 홀카드 | 2장 | 5장 |
| 보드 | 0장 | **1장** (`board_1`) |
| RFID | seat antenna만 | seat + board antenna 동시 |
| SETUP 완료 조건 | 전체 홀카드 감지 | 전체 홀카드 + `board_1` 감지 |

- **SETUP_HAND**에서 hole 5장 + `board_1` 1장을 동시에 RFID 감지
- `board_1`은 즉시 오버레이에 표시
- **PRE_FLOP** 베팅은 `board_1`이 공개된 상태에서 진행 (정보 비대칭 증가)

---

## RFID 변경 사항

### SETUP 단계

- Hole 5장 + `board_1` = seat RFID + board RFID **동시 감지**
- Hole card와 `board_1`은 **동일 우선순위**로 병렬 처리 (서브 우선순위 없음)
- `board_1` 미감지 시 SETUP 완료 불가 → 타임아웃 후 수동 입력

| 이벤트 | 처리 | 우선순위 |
|--------|------|---------|
| seat RFID 도착 | 홀카드 기록 | RFID 기본 |
| board RFID 도착 | `board_1` 기록 | RFID 기본 (동일) |
| `board_1`이 hole보다 먼저 도착 | **유효** | 순서 무관 |

### FLOP 보드 카드

| 항목 | Hold'em | Courchevel |
|------|---------|------------|
| FLOP 감지 | 보드 3장 | 보드 **추가 2장**만 |
| 3장 감지 시 | 정상 | **WRONG_CARD** 에러 (초과 카드) |
| 결과 `board_cards` | [card1, card2, card3] | [`board_1`, card2, card3] |

- `board_1`은 이미 SETUP에서 기록됨 → FLOP에서 재감지하면 중복 에러
- FLOP에서 3장 감지 시 **WRONG_CARD** 에러 발생 → 에러 로그 기록, 운영자에게 재스캔 요청

### RFID 감지 시퀀스

```
SETUP:  [홀카드] 5장 + [보드] 1장 감지 → board_cards = [board_1]
FLOP:   board_cards += [card2, card3] → 길이 3
TURN:   board_cards += [card4] → 길이 4
RIVER:  board_cards += [card5] → 길이 5
```

---

## 핸드 평가 변경 사항

### game_id = 10: standard_high

- Omaha 5와 동일: must-use 2+3
- C(5,2) x C(5,3) = 100 조합 평가
- Hold'em과의 차이는 Omaha와 동일 (BS-06-13 참조하지 않고 독립 설명):
  - 홀카드 5장 중 **정확히 2장** + 보드 5장 중 **정확히 3장** = 5장 핸드
  - Hold'em의 "best 5 of 7"과 다름

### game_id = 11: Hi-Lo — hilo_8or_better

**High pot**: `standard_high` 평가와 동일 (must-use 2+3)

**Low pot**:
- 5장 모두 rank <= 8, 모두 다른 rank, A = Low
- must-use 2+3 규칙 동일 적용
- 8-or-better 자격 미충족 시 High가 전체 팟 수령 (scoop)

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

### SETUP_HAND 단계

- Hole + `board_1` 동시 감지 시 우선순위:
  - Hole card = `board_1` (**동일 우선순위**, 병렬 처리)
  - `board_1`이 hole보다 먼저 도착해도 유효
- Hold'em SETUP은 seat antenna만 사용하지만 Courchevel은 seat + board antenna 동시 사용

### FLOP 단계

| 조건 | 처리 |
|------|------|
| board 2장 감지 | 정상 진행 |
| board 3장 감지 | **WRONG_CARD** 에러 |
| board 1장만 감지 | 타임아웃 후 수동 입력 |

---

## 유저 스토리

1. **SETUP 정상**: hole 5장 + `board_1` 동시 RFID 감지 → 홀카드 좌석별 기록 + `board_1` 오버레이 표시 → PRE_FLOP 시작
2. **SETUP board_1 미감지**: hole 5장 감지 완료, `board_1` 미감지 → 타임아웃 → 운영자에게 수동 입력 요청
3. **FLOP 정상**: 2장 감지 → `board_cards` = [`board_1`, card2, card3] → FLOP 베팅 시작
4. **FLOP 초과 카드**: 3장 감지 → **WRONG_CARD** 에러 → 에러 로그 기록, 운영자에게 재스캔 요청
5. **PRE_FLOP 베팅**: `board_1` 공개 상태에서 베팅 → Hold'em과 동일 베팅 규칙 적용 (정보량만 다름)

---

## 예외 처리 변경 사항

| 예외 | Hold'em 대비 변경 | 처리 |
|------|------------|------|
| `board_1` 미감지 | Hold'em에서는 해당 없음 | SETUP 불완전 → 타임아웃 후 수동 입력 |
| FLOP 초과 카드 | Hold'em에서는 3장이 정상 | **WRONG_CARD** → 에러 로그, 운영자에게 재스캔 요청 |
| SETUP RFID 소스 혼재 | Hold'em은 seat만 | seat + board 동시 → 동일 우선순위 병렬 처리 |

---

## 구현 체크리스트

- [ ] SETUP에서 `board_1` 동시 RFID 감지
- [ ] `board_1` 오버레이 즉시 표시
- [ ] FLOP 추가 2장만 감지 (3장 감지 시 **WRONG_CARD**)
- [ ] Hole/`board_1` 동일 우선순위 병렬 처리
- [ ] `board_1` 미감지 타임아웃 처리
- [ ] Hi-Lo split (game_id = 11)
- [ ] Low 자격 미충족 시 High scoop
- [ ] Odd chip → High 우선
