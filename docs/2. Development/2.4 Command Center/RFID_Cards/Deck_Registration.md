---
title: Deck Registration
owner: team4
tier: internal
legacy-id: BS-04-01
last-updated: 2026-04-15
confluence-page-id: 3834118330
confluence-parent-id: 3811901565
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3834118330/Registration
---

# BS-04-01 Deck Registration — 덱 등록 프로세스

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | DeckFSM 상태 전이, Real/Mock 등록 흐름, 진행률 UI, 실패 시나리오, 유저 스토리, 경우의 수 매트릭스 |
| 2026-05-07 | v4 cascade | CC_PRD v4.0 정체성 정합 — 덱 등록 흐름 (DeckFSM) 은 v4.0 정체성 (1×10 그리드 + 6 키 + 5-Act) 과 무관한 사전 셋업 프로세스. 등록 결과 (52장 UID-카드 매핑) 는 게임 진행 시 PlayerGrid SeatCell 행 6 + TopStrip Community Board 5 슬롯에 face-down/up 표시. SSOT 변경 없음. |

---

## 개요

덱 등록은 **52장 카드를 RFID UID와 매핑하는 전처리 과정**이다. 등록된 덱만 게임에 투입 가능하며, Mock 모드에서는 "자동 등록" 1클릭으로 가상 매핑을 즉시 생성한다.

> **v4.0 컨텍스트** (2026-05-07): 덱 등록은 CC_PRD v4.0 정체성 (1×10 그리드 + 6 키 + 5-Act) 과 무관한 사전 셋업 프로세스. 등록 결과 (52장 UID ↔ 카드 매핑) 는 게임 진행 시 PlayerGrid SeatCell 행 6 (Hole cards face-down) + TopStrip Community Board 5 슬롯에 매핑되어 표시.

> **참조**: DeckFSM 상태 정의는 `BS-00-definitions.md §3.5`, RFID 이벤트는 `Triggers.md §2.2` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: BS-06-00-triggers))), HAL registerDeck()은 `RFID_HAL_Interface.md §2.1` (legacy-id: API-03)

---

## 정의

| 용어 | 설명 |
|------|------|
| **덱 등록** | 52장 카드 각각의 RFID UID를 suit+rank와 매핑하는 과정 |
| **카드 매핑** | UID → Card(suit, rank) 연결 관계. 등록 완료 후 `cardMap`에 저장 |
| **전수 스캔** | 52장 모두를 1장씩 리더에 대어 UID를 읽는 행위 (Real 모드) |
| **자동 등록** | Mock HAL이 52장 가상 UID("MOCK-{suit}{rank}")를 즉시 생성하는 행위 |

---

## 전제조건

- Table 상태: SETUP 또는 LIVE
- DeckFSM 상태: UNREGISTERED
- RFID HAL: 초기화 완료 (status = `ready`)
- CC가 BO와 WebSocket 연결됨 (등록 결과 BO 동기화 필요)

---

## 1. DeckFSM 상태 전이

### 1.1 상태 정의

> 참조: BS-00 §3.5

| 상태 | 의미 |
|------|------|
| **UNREGISTERED** | 등록 전 — 카드-UID 매핑 없음 |
| **REGISTERING** | 등록 진행 중 — 52장 전수 스캔 진행 |
| **REGISTERED** | 등록 완료 — 52장 매핑 확인, 게임 투입 가능 |
| **PARTIAL** | 부분 등록 — 일부 카드 매핑 실패 (에러 상태) |
| **MOCK** | Mock 모드 — RFID 없이 소프트웨어 가상 매핑 |

### 1.2 전이 다이어그램

```
UNREGISTERED
    │
    ├── [CC: RegisterDeck + Real 모드]
    │       │
    │       ▼
    │   REGISTERING ──── 52장 완료 ──── REGISTERED
    │       │                               │
    │       ├── 일부 실패 ── PARTIAL        │
    │       └── 사용자 취소 ── UNREGISTERED  │
    │                                       │
    │                                  (게임 투입 가능)
    │
    └── [CC: RegisterDeck + Mock 모드]
            │
            ▼
        MOCK (즉시, 52장 가상 매핑)
            │
        (게임 투입 가능)
```

### 1.3 전이 상세

| 현재 상태 | 이벤트 | 조건 | 다음 상태 |
|----------|--------|------|----------|
| UNREGISTERED | `RegisterDeck` | Real 모드 | REGISTERING |
| UNREGISTERED | `RegisterDeck` | Mock 모드 | MOCK |
| REGISTERING | `DeckRegistrationProgress` | scannedCount < 52 | REGISTERING (유지) |
| REGISTERING | `DeckRegistered` | 52장 완료 | REGISTERED |
| REGISTERING | `ReaderError(deckIncomplete)` | 실패 카드 존재 | PARTIAL |
| REGISTERING | 사용자 취소 | — | UNREGISTERED |
| PARTIAL | `RegisterDeck` (재시도) | — | REGISTERING |
| REGISTERED | 덱 교체 요청 | — | UNREGISTERED |
| MOCK | 모드 전환 → Real | — | UNREGISTERED |

---

## 2. Real 모드 등록 흐름

### 2.1 프로세스

1. 운영자가 CC에서 **"덱 등록"** 버튼 클릭 → `RegisterDeck` 이벤트
2. HAL이 `registerDeck()` 호출 → 리더가 스캔 대기 모드 진입
3. 운영자가 카드를 1장씩 리더 안테나에 대어 스캔
4. 카드 스캔 시 `DeckRegistrationProgress(scannedCount, 52)` 이벤트 발행
5. CC UI에 진행률 표시 (n/52)
6. 52장 완료 → `DeckRegistered(deckId, cardMap)` 이벤트 발행
7. DeckFSM → REGISTERED 전이
8. BO에 등록 결과 동기화 (`RfidStatusChanged`)

### 2.2 스캔 순서

카드 스캔 순서는 자유다. 운영자가 임의의 순서로 카드를 리더에 대면 된다. 시스템은 UID를 읽고, 표면 인쇄(suit+rank)와 매핑한다.

> **주의**: 표면 인쇄와 RFID 태그가 일치하지 않는 카드(제조 불량)는 `unknownCard` 에러를 발생시킨다.

### 2.3 예상 소요 시간

| 항목 | 시간 |
|------|:----:|
| 카드 1장 스캔 | 1~3초 |
| 52장 전체 | 3~5분 |
| 오류 발생 시 재스캔 포함 | 5~8분 |

---

## 3. Mock 모드 등록 흐름

### 3.1 프로세스

1. 운영자가 CC에서 **"자동 등록"** 버튼 클릭 → `RegisterDeck` 이벤트
2. `MockRfidReader.autoRegisterDeck()` 호출
3. 52장 가상 매핑 즉시 생성 (UID: "MOCK-{suit}{rank}")
4. `DeckRegistrationProgress(52, 52)` 이벤트 1회 발행
5. `DeckRegistered(deckId, cardMap)` 이벤트 발행
6. DeckFSM → MOCK 전이
7. 즉시 게임 투입 가능

### 3.2 가상 UID 형식

```
UID = "MOCK-{suit}{rank}"
예: MOCK-012 = Club Ace (suit=0, rank=12)
    MOCK-30  = Spade Two (suit=3, rank=0)
```

---

## 4. 진행률 UI (AT-05 Register Screen) (CCR-026)

> **참조**: AT-05 화면의 상세 명세는 `Register_Screen.md` (legacy-id: BS-04-05) 로 이관되었다. 본 섹션은 등록 **정책**에서 UI가 준수해야 할 핵심 요소만 요약한다.

### 4.1 핵심 UI 요소

AT-05 Register Screen은 다음 요소를 반드시 제공한다:

| 요소 | 설명 |
|------|------|
| 진행률 바 | `n / 54` (또는 52 if Joker 제외) |
| 숫자 표시 | "32 / 54 카드 등록됨" |
| 4 × 13 카드 그리드 | 수트 × 랭크, 상태별 색상 (BS-04-05 §5) |
| 현재 요청 카드 표시 | 노란 펄스 셀 + "Currently expecting: ♠ A" |
| 중복 경고 | "⚠ 이미 등록된 UID입니다" |
| 에러 표시 | "✗ 카드 읽기 실패 (신호 약함)" |

### 4.2 Mock 모드 UI

Mock 모드에서는 `autoRegisterDeck()` API로 즉시 54장이 자동 등록되며 "자동 등록 완료" 메시지가 표시된다. AT-05 화면은 우회된다.

---

## 5. 등록 실패 시나리오

| 시나리오 | 원인 | DeckFSM 전이 | 시스템 반응 | 운영자 대응 |
|---------|------|-------------|-----------|-----------|
| **안테나 오류** | 안테나 연결 해제 | REGISTERING 유지 | `ReaderError(antennaDisconnected)` + 경고 | 안테나 확인 후 재연결 |
| **중복 UID** | 같은 카드 2회 스캔 | REGISTERING 유지 | `ReaderError(duplicateCard)` + 경고 | 다음 카드로 진행 (기존 매핑 유지) |
| **UID 불일치** | 제조 불량 카드 | REGISTERING 유지 | `ReaderError(unknownCard)` | 해당 카드 교체 |
| **물리적 손상** | 태그 파손으로 읽기 불가 | REGISTERING 유지 | `ReaderError(readError)` | 해당 카드 교체 |
| **52장 미만 완료** | 운영자가 "완료" 강제 | → PARTIAL | 경고: "N장 누락" | 누락 카드 추가 스캔 또는 수동 매핑 |
| **리더 연결 끊김** | Serial 통신 장애 | → UNREGISTERED (리셋) | `ReaderError(connectionLost)` | 리더 재시작 후 재등록 |
| **사용자 취소** | 등록 도중 취소 버튼 | → UNREGISTERED | 진행분 폐기 | 필요 시 재시작 |

---

## 6. 유저 스토리

### Real 모드

| ID | 역할 | 스토리 | 수락 기준 |
|----|------|--------|----------|
| US-R01 | 운영자 | "덱 등록" 버튼을 눌러 새 덱 등록을 시작한다 | DeckFSM → REGISTERING, 진행률 0/52 표시 |
| US-R02 | 운영자 | 카드를 1장씩 스캔하며 진행률을 확인한다 | 스캔할 때마다 n/52 증가, 최근 스캔 카드 표시 |
| US-R03 | 운영자 | 52장 모두 스캔 완료 후 등록 성공을 확인한다 | DeckFSM → REGISTERED, "등록 완료" 메시지 |
| US-R04 | 운영자 | 이미 스캔한 카드를 다시 대면 중복 경고를 본다 | "⚠ 이미 등록됨" 경고, 매핑 덮어쓰기 없음 |
| US-R05 | 운영자 | 읽기 실패 카드를 확인하고 교체한다 | 에러 카드 표시, 교체 후 재스캔 가능 |
| US-R06 | 운영자 | 등록 도중 취소하여 처음으로 돌아간다 | DeckFSM → UNREGISTERED, 진행분 폐기 |

### Mock 모드

| ID | 역할 | 스토리 | 수락 기준 |
|----|------|--------|----------|
| US-M01 | 운영자 | "자동 등록" 버튼을 눌러 즉시 덱을 등록한다 | DeckFSM → MOCK, 52장 매핑 즉시 완료 |
| US-M02 | 운영자 | 자동 등록 후 즉시 게임을 시작한다 | MOCK 상태에서 StartHand 허용 |

### 공통

| ID | 역할 | 스토리 | 수락 기준 |
|----|------|--------|----------|
| US-C01 | 운영자 | 등록된 덱을 교체하여 새 덱으로 변경한다 | DeckFSM → UNREGISTERED → 재등록 |
| US-C02 | 운영자 | 누락 카드 목록을 확인하여 빠진 카드를 찾는다 | 미스캔 카드 suit+rank 목록 표시 |
| US-C03 | Admin | Lobby에서 테이블의 덱 등록 상태를 모니터링한다 | REGISTERED/PARTIAL/MOCK 상태 표시 |
| US-C04 | 운영자 | PARTIAL 상태에서 누락 카드를 추가 스캔한다 | 추가 스캔 후 52장 완료 시 → REGISTERED |

---

## 7. 경우의 수 매트릭스

### 7.1 모드 × 카드 상태 × 시스템 반응

| 모드 | 카드 상태 | 시스템 반응 | DeckFSM 전이 |
|------|----------|-----------|-------------|
| **Real** | 정상 (52장 완료) | `DeckRegistered` 이벤트, "등록 완료" 메시지 | → REGISTERED |
| **Real** | 중복 (같은 카드 2회) | `duplicateCard` 경고, 기존 매핑 유지, 카운트 미증가 | REGISTERING 유지 |
| **Real** | 누락 (52장 미만으로 완료 시도) | "N장 누락" 경고, 누락 카드 목록 표시 | → PARTIAL |
| **Real** | 손상 (읽기 실패) | `readError` 경고, 재스캔 유도 | REGISTERING 유지 |
| **Real** | 불일치 (UID-표면 불일치) | `unknownCard` 에러, 해당 카드 교체 유도 | REGISTERING 유지 |
| **Real** | 안테나 오류 | `antennaDisconnected` 경고, 스캔 중단 | REGISTERING 유지 (복구 대기) |
| **Real** | 리더 연결 끊김 | `connectionLost` 에러, 진행분 폐기 | → UNREGISTERED |
| **Real** | 사용자 취소 | 진행분 폐기, 초기 상태 복귀 | → UNREGISTERED |
| **Mock** | 정상 (자동 등록) | 52장 가상 매핑 즉시 생성, "자동 등록 완료" | → MOCK |
| **Mock** | 에러 주입 테스트 | `injectError()` → 에러 이벤트 합성 | 에러 코드에 따라 상이 |

---

## 비활성 조건

- Table 상태가 EMPTY일 때 "덱 등록" 버튼 비활성
- DeckFSM이 이미 REGISTERED 또는 MOCK일 때 "등록" 버튼 비활성 (교체 버튼으로 전환)
- 핸드 진행 중(HandFSM ≠ IDLE)에 덱 재등록 불가

---

## 영향 받는 요소

| 영향 대상 | 이 문서와의 관계 |
|----------|----------------|
| `Overview.md` (legacy-id: BS-04-00) | RFID 전체 흐름에서 덱 등록 단계 |
| `Card_Detection.md` (legacy-id: BS-04-02) | 등록된 덱 기반으로 카드 감지 |
| `Manual_Fallback.md` (legacy-id: BS-04-03) | Mock 자동 등록과 수동 입력의 관계 |
| `Triggers.md §2.2` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: BS-06-00-triggers))) | DeckRegistered, DeckRegistrationProgress 이벤트 정의 |
| `RFID_HAL_Interface.md §2.1` (legacy-id: API-03) | registerDeck() 메서드 계약 |
