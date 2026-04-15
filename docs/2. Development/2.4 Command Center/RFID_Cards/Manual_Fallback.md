---
title: Manual Fallback
owner: team4
tier: internal
legacy-id: BS-04-03
last-updated: 2026-04-15
---

# BS-04-03 Manual Fallback — 수동 카드 입력 (Mock 기본 경로 + Real 폴백)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 수동 입력 UI, 키보드 단축키, Mock 기본 경로, Real 폴백 전환, 유저 스토리, 경우의 수 매트릭스 |
| 2026-04-15 | 구현 계약 보강 | §5.5 RfidReaderStatus enum 매핑, §5.6 경고 배너 규격(색·문구·아이콘), §5.7 혼합 운영 granularity(슬롯별 독립), §6 RFID 재연결 시 동작 신설. 구버전 §6/§7 → §7/§8 재번호 |

---

## 개요

**수동 카드 입력은 Mock 모드의 기본 경로이자 Real 모드의 폴백이다.** 운영자가 CC에서 카드를 직접 선택하면, `MockRfidReader.injectCard()`를 통해 `CardDetected` 이벤트가 합성되고, Game Engine은 RFID 자동 감지와 동일하게 처리한다.

| 입력 방식 | 사용 조건 | 빈도 |
|----------|----------|:----:|
| **RFID 자동** | Feature Table + Real 모드 + 하드웨어 정상 | 프로덕션 기본 |
| **수동 입력 (Mock 기본)** | Mock 모드 또는 General Table | **개발/테스트 기본** |
| **수동 입력 (Real 폴백)** | Real 모드에서 RFID 장애 발생 | 비상 시 |

> **참조**: Mock 모드 정의는 `BS-00-definitions.md §9`, 이벤트 합성 규칙은 `BS-06-00-triggers.md §4`, Mock HAL API는 `API-03-rfid-hal-interface.md §6.2`

---

## 정의

| 용어 | 설명 |
|------|------|
| **수동 입력** | 운영자가 CC UI에서 suit+rank를 선택하여 카드를 지정하는 행위 |
| **카드 선택 UI** | 4 suit × 13 rank = 52칸 그리드 형태의 카드 선택 인터페이스 |
| **이벤트 합성** | 수동 입력 → `injectCard()` → `CardDetected` 이벤트 생성 |
| **Real 폴백** | Real 모드에서 RFID 장애 시 수동 입력으로 전환하는 비상 절차 |

---

## 전제조건

- DeckFSM: REGISTERED 또는 MOCK (덱 등록 완료)
- HandFSM: SETUP_HAND 이후 (카드 입력 가능 상태)
- CC가 활성 상태 (Table LIVE)

---

## 1. 카드 선택 UI 상세

### 1.1 그리드 레이아웃

4 suit × 13 rank = 52칸 그리드. 수트별 행, 랭크별 열.

```
        2   3   4   5   6   7   8   9   T   J   Q   K   A
  ♣   [2c][3c][4c][5c][6c][7c][8c][9c][Tc][Jc][Qc][Kc][Ac]
  ♦   [2d][3d][4d][5d][6d][7d][8d][9d][Td][Jd][Qd][Kd][Ad]
  ♥   [2h][3h][4h][5h][6h][7h][8h][9h][Th][Jh][Qh][Kh][Ah]
  ♠   [2s][3s][4s][5s][6s][7s][8s][9s][Ts][Js][Qs][Ks][As]
```

### 1.2 카드 상태 표시

| 상태 | 시각적 표시 | 클릭 가능 |
|------|-----------|:---------:|
| **사용 가능** | 기본 색상 (밝은 배경) | O |
| **이미 사용됨** | 회색 비활성화 + 취소선 | X |
| **현재 선택 중** | 하이라이트 (파란 테두리) | — |
| **최근 선택** | 강조 표시 (녹색) | X (이미 사용됨) |

### 1.3 중복 방지

이미 사용된 카드(현재 핸드에서 홀카드 또는 보드 카드로 배정된 카드)는 그리드에서 **비활성화**된다. 운영자는 물리적으로 선택할 수 없다.

| 항목 | 설명 |
|------|------|
| 비활성화 범위 | 현재 핸드에서 이미 `CardDetected`된 모든 카드 |
| 핸드 종료 시 | 모든 카드 다시 활성화 (새 핸드 시작) |
| 덱 교체 시 | 모든 카드 다시 활성화 |

---

## 2. 키보드 단축키

### 2.1 2자 입력 규칙

수트 1자 + 랭크 1자 = 2자 입력으로 카드를 빠르게 선택한다.

**수트 키**:

| 키 | 수트 | 기호 |
|:--:|------|:----:|
| `c` | Club | ♣ |
| `d` | Diamond | ♦ |
| `h` | Heart | ♥ |
| `s` | Spade | ♠ |

**랭크 키**:

| 키 | 랭크 | 값 |
|:--:|------|:--:|
| `2`~`9` | Two~Nine | 0~7 |
| `T` 또는 `0` | Ten | 8 |
| `J` | Jack | 9 |
| `Q` | Queen | 10 |
| `K` | King | 11 |
| `A` | Ace | 12 |

### 2.2 입력 순서

**랭크 먼저, 수트 나중**: `As` = Ace of Spades, `Th` = Ten of Hearts

| 입력 | 결과 |
|------|------|
| `A` → `s` | Ace of Spades (As) 선택 |
| `T` → `h` | Ten of Hearts (Th) 선택 |
| `2` → `c` | Two of Clubs (2c) 선택 |
| `K` → `d` | King of Diamonds (Kd) 선택 |

### 2.3 자동 완성

랭크만 입력하면 해당 랭크의 미사용 수트 목록이 표시된다.

| 시나리오 | 입력 | 표시 |
|---------|------|------|
| Ace 4장 모두 미사용 | `A` | ♣ ♦ ♥ ♠ (4개 후보) |
| Ace 중 As 이미 사용 | `A` | ♣ ♦ ♥ (3개 후보, ♠ 비활성) |
| Ace 1장만 남음 | `A` | ♥ (1개 후보, 자동 선택 가능) |

> **1장만 남은 경우**: 랭크 입력만으로 자동 선택 (수트 입력 불필요). 단, 운영자 확인 후 적용.

### 2.4 취소 및 수정

| 키 | 동작 |
|----|------|
| `Escape` | 현재 입력 취소, 카드 선택 초기화 |
| `Backspace` | 마지막 입력 문자 삭제 |
| `Ctrl+Z` | 마지막 카드 선택 취소 (Undo, 최대 1회) |

---

## 3. 이벤트 합성 흐름

### 3.1 수동 입력 → CardDetected 변환

```
[운영자] CC 카드 선택 UI에서 카드 선택 (suit, rank)
    │
    ▼
CC가 MockRfidReader.injectCard(suit, rank, antennaId) 호출
    │
    ▼
MockRfidReader가 CardDetected 이벤트 합성:
    - antennaId: 좌석 안테나 ID (CC가 결정) 또는 0 (Mock 기본)
    - cardUid: "MOCK-{suit}{rank}"
    - suit: 선택된 수트
    - rank: 선택된 랭크
    - confidence: 1.0
    - timestamp: DateTime.now()
    │
    ▼
Stream<RfidEvent>에 CardDetected 발행
    │
    ▼
Game Engine 수신 → 카드 정보 반영 (Real 모드와 동일 처리)
    │
    ▼
Overlay 업데이트 (카드 표시, Equity 재계산)
```

### 3.2 핵심 원칙

- **Game Engine은 이벤트 소스를 구분하지 않는다.** Real HAL이든 Mock HAL이든 동일한 `CardDetected` 이벤트를 수신한다.
- **이벤트 스트림은 하나다.** `IRfidReader.events` 스트림을 통해 모든 이벤트가 전달된다.
- **수동 입력의 결과는 RFID 자동 감지와 100% 동일하다.** Overlay, Equity, Statistics 모두 동일하게 동작한다.

---

## 4. Mock 모드 — 기본 경로

### 4.1 Mock 모드에서의 카드 입력 흐름

Mock 모드에서 카드 입력은 **수동 입력이 유일한 경로**다. 이는 fallback이 아니라 **기본 동작**이다.

| 단계 | 운영자 동작 | 시스템 반응 |
|:----:|-----------|-----------|
| 1 | NEW HAND 버튼 | HandFSM → SETUP_HAND |
| 2 | 좌석 선택 + 카드 선택 (홀카드 1) | injectCard → CardDetected |
| 3 | 같은 좌석 + 카드 선택 (홀카드 2) | injectCard → CardDetected |
| 4 | 모든 활성 좌석 홀카드 입력 완료 | HoleCardsDealt → PRE_FLOP |
| 5 | 베팅 라운드 진행 (Fold/Bet/Raise...) | — |
| 6 | Flop 카드 3장 선택 | injectCard × 3 → 보드 Flop |
| 7 | 베팅 → Turn 카드 1장 선택 | injectCard → 보드 Turn |
| 8 | 베팅 → River 카드 1장 선택 | injectCard → 보드 River |
| 9 | Showdown → 핸드 종료 | HAND_COMPLETE |

### 4.2 Mock + General Table

General Table은 RFID 장비가 없으므로 항상 수동 입력이다. Mock 모드와 동일한 UI와 흐름을 사용한다.

---

## 5. Real 모드 — RFID 실패 시 수동 전환

### 5.1 전환 트리거

| 트리거 | 조건 | 자동/수동 |
|--------|------|---------|
| 안테나 장애 | `AntennaStatusChanged(disconnected)` | 자동 감지 → 운영자 확인 |
| 리더 장애 | `ReaderError(connectionLost)` | 자동 감지 → 운영자 확인 |
| 카드 미인식 | 타임아웃 (설정 가능, 기본 10초) | 자동 감지 → 운영자 확인 |
| 운영자 판단 | CC에서 "수동 모드" 버튼 | 수동 전환 |

### 5.2 전환 플로우

```
RFID 장애 감지
    │
    ▼
CC에 경고 배너 표시: "RFID 장애 — 수동 입력으로 전환하시겠습니까?"
    │
    ├── [운영자 확인] → 수동 입력 모드 활성화
    │       │
    │       ▼
    │   카드 선택 UI 표시 (§1 그리드)
    │   이후 수동 입력으로 카드 지정
    │
    └── [운영자 거부] → RFID 재시도 대기
            │
            ▼
        리더 재연결 시 자동 복귀
```

### 5.3 혼합 모드 (Real + 수동)

Real 모드에서 일부 안테나만 장애인 경우, **정상 안테나는 RFID 자동, 장애 안테나는 수동 입력**으로 혼합 운영이 가능하다.

| 시나리오 | 처리 |
|---------|------|
| Seat 3 안테나만 장애 | Seat 3만 수동 입력, 나머지 좌석은 RFID 자동 |
| 보드 안테나만 장애 | 보드 카드만 수동 입력, 홀카드는 RFID 자동 |
| 모든 안테나 장애 | 전체 수동 입력 (사실상 Mock 모드와 동일) |

### 5.4 Real 폴백 → RFID 복귀

| 조건 | 동작 |
|------|------|
| 현재 핸드 진행 중 | 핸드 종료까지 수동 모드 유지 |
| RFID 복구 + 핸드 종료 | 다음 핸드부터 RFID 자동 복귀 |
| RFID 복구 + 운영자 확인 | "RFID 복구됨 — 자동 모드로 복귀하시겠습니까?" |

### 5.5 RfidReaderStatus enum 매핑 (구현 계약)

`team4-cc/src/lib/rfid/abstract/i_rfid_reader.dart` 의 5개 status 값을 본 문서 §5 의 "장애" 정의와 결정적으로 매핑한다. CC 가 구현 시점에 임의 판단할 여지를 없앤다.

| `RfidReaderStatus` | 장애 판정 | 배너 종류 (§5.6) | 슬롯 타이머 (§Manual_Card_Input §6.5) |
|--------------------|:--------:|:----------------:|:------------------------------------:|
| `connected` | ❌ | 숨김 | 정상 5초 |
| `connecting` | ❌ | 정보 (파랑) | **일시 정지** (연결 시도 동안 카운트 X) |
| `reconnecting` | ⚠️ | 경고 (주황) | **즉시 FALLBACK** (대기 없이 수동 가능) |
| `connectionFailed` | ✅ | 오류 (빨강) | 즉시 FALLBACK |
| `disconnected` | ✅ | 오류 (빨강) | 즉시 FALLBACK |

> "즉시 FALLBACK" = `CardInputNotifier.startDetecting()` 호출 시 5초 타이머를 생략하고 곧바로 `CardSlotStatus.fallback` 으로 전이. 새 메서드 `requestManualForSlot(index)` 가 이 분기를 담당.

### 5.6 경고 배너 규격 (구현 계약)

CC AT-01 화면 **상단 툴바 바로 아래** 에 전폭 배너로 표시. 위젯 클래스: `_RfidStatusBanner` (`at_01_main_screen.dart`).

| 속성 | 값 |
|------|----|
| 위치 | 툴바 직하단, 전폭 |
| 높이 | 36 px |
| 진입 애니메이션 | 200 ms slide-down + fade in |
| 해제 애니메이션 | 200 ms fade out (status → `connected` 전이 즉시) |
| 닫기 버튼 | **없음** (자동 해제만; 장애 상태인 동안 dismiss 불가) |

배너 종류별 색상 / 아이콘 / 표준 메시지:

| 종류 | 배경색 | 아이콘 | 메시지 (정확한 문자열) |
|------|--------|--------|-----------------------|
| 정보 (`connecting`) | `#1976D2` | `Icons.wifi_tethering` | `RFID 리더 연결 중…` |
| 경고 (`reconnecting`) | `#F57C00` | `Icons.warning_amber` | `RFID 재연결 중 — 수동 입력으로 진행 가능` |
| 오류 (`connectionFailed`) | `#E53935` | `Icons.error_outline` | `RFID 연결 실패 — 수동 입력으로 진행하세요` |
| 오류 (`disconnected`) | `#E53935` | `Icons.error_outline` | `RFID 장애 — 수동 입력 모드` |

문자 색은 모두 `#FFFFFF`. 폰트는 `EbsTypography.toolbarTitle` 동일.

### 5.7 혼합 운영 — 감지 단위 (구현 계약)

§5.3 의 시나리오를 다음 granularity 로 결정적으로 해석한다.

- **감지 단위 = 슬롯별 독립**. 각 `HoleCardSlot` 이 자신의 DETECTING 타이머를 소유. 한 슬롯의 FALLBACK 전이가 다른 슬롯의 타이머에 영향 없음.
- 안테나-좌석 매핑상 **특정 안테나만** 장애여도 정상 안테나의 카드 감지는 계속 유효 — 정상 슬롯은 RFID 경로, 장애 슬롯만 수동.
- **리더 자체** 가 `disconnected`/`connectionFailed` 면 슬롯별 분기 없이 **모든 슬롯이 즉시 FALLBACK** (§5.5 매핑 그대로). 배너도 오류 종류로 표시.

---

## 6. RFID 재연결 시 동작 (구현 계약)

리더 status 가 장애에서 `connected` 로 전이될 때:

1. **배너 자동 숨김** — 200 ms fade out (§5.6).
2. **이미 DEALT 된 수동 카드는 유지** — 서버로 재전송하지 않으며, 운영자 확인 없이 그대로 보존.
3. **EMPTY / FALLBACK 슬롯은 다음 NewHand 까지 현재 상태 유지** — RFID 자동 재감지를 자체 트리거하지 **않는다**. 운영자가 명시적으로 Undo + 재입력하도록 한다. 근거: 진행 중 입력 흐름이 갑자기 RFID 감지로 끊기는 혼란 방지.
4. **진행 중인 AT-03 모달은 유지** — 운영자 결정 우선. 모달 안에서 `Cancel`/`ESC` 또는 카드 선택 확정으로 모달이 닫혀야 RFID 경로로 복귀할 수 있는 슬롯 상태가 다시 노출된다.

---

## 7. 유저 스토리

### Mock 기본 경로

| ID | 역할 | 스토리 | 수락 기준 |
|----|------|--------|----------|
| US-F01 | 운영자 | Mock 모드에서 카드 선택 그리드를 열어 홀카드를 지정한다 | 52칸 그리드 표시, 카드 선택 가능 |
| US-F02 | 운영자 | 키보드 `As`를 입력하여 Ace of Spades를 빠르게 선택한다 | 2자 입력 → 카드 선택 완료 |
| US-F03 | 운영자 | 이미 사용된 카드가 그리드에서 비활성화되어 선택 불가하다 | 사용된 카드 회색 + 클릭 불가 |
| US-F04 | 운영자 | `A` 입력 시 미사용 Ace 수트 목록이 자동 완성으로 표시된다 | 미사용 수트만 후보 표시 |
| US-F05 | 운영자 | Flop 카드 3장을 연속 선택하여 보드를 구성한다 | 3장 injectCard → Flop 보드 완성 |
| US-F06 | 운영자 | 잘못 선택한 카드를 Ctrl+Z로 취소한다 | 마지막 카드 선택 Undo, 그리드 복원 |

### Real 폴백

| ID | 역할 | 스토리 | 수락 기준 |
|----|------|--------|----------|
| US-F07 | 운영자 | RFID 장애 시 경고 배너를 보고 수동 모드로 전환한다 | 경고 배너 + "수동 전환" 버튼 표시 |
| US-F08 | 운영자 | 수동 모드에서 카드를 입력하여 게임을 중단 없이 계속한다 | 수동 입력 → CardDetected 합성 → 게임 계속 |
| US-F09 | 운영자 | 일부 좌석만 수동, 나머지는 RFID로 혼합 운영한다 | 장애 안테나 좌석만 수동, 정상 좌석 자동 |
| US-F10 | 운영자 | RFID 복구 후 다음 핸드부터 자동 모드로 복귀한다 | 복구 알림 + 다음 핸드 RFID 자동 |

### 에러 상황

| ID | 역할 | 스토리 | 수락 기준 |
|----|------|--------|----------|
| US-F11 | 운영자 | 이미 사용된 카드를 키보드로 입력 시도하면 경고를 본다 | "이미 사용된 카드" 경고, 입력 거부 |
| US-F12 | 운영자 | Escape 키로 카드 선택을 취소하고 초기 상태로 돌아간다 | 입력 초기화, 그리드 기본 상태 |
| US-F13 | 운영자 | 핸드 종료 후 모든 카드가 다시 활성화되는 것을 확인한다 | HAND_COMPLETE → 52칸 모두 활성 |
| US-F14 | 운영자 | General Table에서 수동 입력만으로 전체 핸드를 진행한다 | 홀카드 + 보드 전부 수동 입력, 정상 핸드 완료 |

---

## 8. 경우의 수 매트릭스

### 8.1 입력 방식 × 카드 유효성 × 시스템 반응

| 입력 방식 | 카드 유효성 | 시스템 반응 |
|----------|-----------|-----------|
| **RFID 자동** | 유효 (등록된 카드, 미사용) | CardDetected → 정상 처리 |
| **RFID 자동** | 중복 (이미 사용된 카드) | DUPLICATE_CARD 경고, 이벤트 무시 |
| **RFID 자동** | 미등록 (unknownCard) | ReaderError, 운영자 확인 요청 |
| **수동 입력** | 유효 (미사용 카드 선택) | injectCard → CardDetected 합성 → 정상 처리 |
| **수동 입력** | 중복 (이미 사용된 카드) | UI에서 선택 차단 (비활성화). 키보드 입력 시 경고 |
| **수동 입력** | 범위 초과 (suit/rank 범위 밖) | UI에서 발생 불가. API 레벨에서 assertion 에러 |
| **혼합 (RFID+수동)** | RFID 성공 + 수동 미입력 | RFID 결과 사용 (정상 경로) |
| **혼합 (RFID+수동)** | RFID 실패 + 수동 입력 | 수동 입력 결과 사용 (폴백) |
| **혼합 (RFID+수동)** | 같은 카드 RFID+수동 동시 | RFID 우선, 수동 무시 (BS-06-00-triggers §3.1) |
| **혼합 (RFID+수동)** | 다른 카드 RFID+수동 동시 | RFID 우선, CARD_CONFLICT 경고, 운영자 확인 |

### 8.2 모드별 전환 매트릭스

| 현재 모드 | RFID 상태 | 수동 입력 | 결과 모드 |
|----------|----------|---------|----------|
| **Mock** | 해당 없음 | 기본 경로 | Mock 유지 |
| **Real** | 정상 | 불필요 | Real 유지 |
| **Real** | 일부 안테나 장애 | 장애 좌석만 | 혼합 |
| **Real** | 전체 장애 | 전체 | 사실상 Mock |
| **Real → 수동 전환** | 장애 | 운영자 확인 후 | 수동 모드 |
| **수동 → Real 복귀** | 복구됨 | 운영자 확인 후 | Real 복귀 (다음 핸드) |

---

## 비활성 조건

- HandFSM = IDLE일 때 카드 선택 UI 비활성
- DeckFSM = UNREGISTERED일 때 카드 선택 UI 비활성
- 해당 Street에서 필요한 카드 수가 이미 충족된 경우 추가 입력 차단
- Table 상태가 PAUSED 또는 CLOSED일 때 카드 입력 불가

---

## 영향 받는 요소

| 영향 대상 | 이 문서와의 관계 |
|----------|----------------|
| `BS-04-00-overview.md` | 전체 흐름에서 수동 입력의 위치 |
| `BS-04-02-card-detection.md` | 카드 감지와 수동 입력의 관계 |
| `BS-04-04-hal-contract.md` | Mock HAL injectCard() API |
| `BS-05-command-center/` | CC UI에서 카드 선택 UI 배치 |
| `BS-06-00-triggers.md §3.1` | CC vs RFID 우선순위 |
| `API-03-rfid-hal-interface.md §6.2` | MockRfidReader.injectCard() 사양 |
