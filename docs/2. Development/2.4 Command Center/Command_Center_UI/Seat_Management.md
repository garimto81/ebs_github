---
title: Seat Management
owner: team4
tier: internal
legacy-id: BS-05-03
last-updated: 2026-04-15
---

# BS-05-03 Command Center — 좌석 관리

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 10좌석 배치, 플레이어 등록/이동, Sit In/Out, 핸드 중 제한 |
| 2026-04-13 | UI-02 redesign | 좌석 S1~S10 변경, 인라인 편집(좌석 상세 패널 대체), 국기/Equity 위젯 요소 추가 |
| 2026-04-21 | §2.3 딜러 배정/재지정 신설 | 기존 §1.1/§5.3 의 dealer 관련 문장이 흩어져 있어 "초기 빈 테이블 → BTN 없음 → NEW HAND canStartHand=false" 미정의. 3-mechanism 명세 (auto-assign on first seat / position-chip click re-assign / hand-complete auto-rotate) + Edge Case 4 건. Type B 기획 공백 해소. critic 반박 5 (렌더링 책임) 반영 — Heads-up 등 포커 규약 연산은 Game Engine 책임, CC UI 는 `dealerSeatProvider` 시각화만 |
| 2026-05-06 | **§Visual Uplift 신설** (B-team4-011 V4·V5) | PositionShiftChip (D/SB/BB/STR ‹ ›) UX + SeatCell 7행 컬럼 레이아웃 도입. 기존 §1.1 표 (6개 표시 항목) 을 7행 그리드로 시각 재배치. hole card 행은 face-down 만 (D7 유지). SSOT: `docs/4. Operations/CC_Design_Prototype_Critic_2026_05_06.md`. |

---

## 개요

CC 테이블 영역의 10좌석(Seat 1~10)은 타원형 테이블 둘레에 배치된다. 각 좌석에 플레이어 이름, 스택, 카드, 상태가 표시되며, 운영자는 좌석 배치·이동·등록·퇴장을 관리한다.

> 참조: BS-00 §3.3 Seat 상태 (SeatFSM), BS-02-lobby §Table Management

---

## 정의

| 용어 | 정의 |
|------|------|
| **Seat** | 테이블 내 물리적 좌석 위치 (1~10). SeatFSM으로 상태 관리 |
| **SeatFSM** | VACANT / OCCUPIED / RESERVED 3가지 상태 |
| **Sit Out** | 플레이어가 자리는 유지하되 핸드에 불참하는 상태 (player.status = sitting_out) |
| **Sit In** | Sit Out에서 복귀하여 다음 핸드부터 참여 |

---

## 트리거

| 트리거 | 발동 주체 | 설명 |
|--------|----------|------|
| `SeatAssign` | 운영자 (CC) | 빈 좌석에 플레이어 배치 |
| `SeatVacate` | 운영자 (CC) | 좌석에서 플레이어 제거 |
| `SeatMove` | 운영자 (CC) | 두 좌석 간 플레이어 이동 |
| `PlayerUpdated` | BO (자동) | Lobby에서 플레이어 정보 변경 시 CC 반영 |

> 참조: 트리거 상세는 BS-06-00-triggers.md §2.1 CC 소스 이벤트

---

## 전제조건

좌석 관리 기능은 다음 조건에서 사용 가능:

| 조건 | 설명 |
|------|------|
| Table 상태 ∈ {SETUP, LIVE, PAUSED} | EMPTY/CLOSED에서는 좌석 관리 불가 |
| CC 인스턴스 활성 | CC가 Launch 완료된 상태 |

---

## 1. 좌석 배치

### 1.1 10좌석 그리드

타원형 테이블 둘레에 Seat 1~10이 배치된다. 각 좌석은 **Seat Cell** 컴포넌트로 구성된다.

| Seat Cell 표시 항목 | 데이터 | 상태별 표시 |
|-------------------|--------|-----------|
| **플레이어 이름** | player.name | 빈 좌석: "OPEN" |
| **스택** | player.stack | 숫자 (예: 50,000) |
| **홀카드** | 2장 슬롯 | RFID 감지 또는 수동 입력. 비공개 시 뒷면 |
| **현재 베팅** | player.current_bet | 베팅 중일 때만 표시 |
| **포지션 뱃지** | D / SB / BB / STR | 해당 포지션에만 표시 |
| **상태 아이콘** | active / folded / allin / sitting_out | 색상 + 텍스트 |

### 인라인 편집 (좌석 상세 패널 대체)

좌석 상세 패널(별도 화면)은 **제거되었다** (UI-02 2026-04-13). 대신 좌석 위젯의 각 요소를 직접 탭하여 수정한다:

| 탭 대상 | 동작 | 조건 |
|---------|------|------|
| 이름 | 이름 편집 다이얼로그 | IDLE에서만 |
| 국기 | 국가 선택 피커 | IDLE에서만 |
| Stack | 칩 수동 조정 다이얼로그 | 항상 |
| 홀카드 | 카드 입력 화면 진입 | 해당 슬롯 선택 |
| 포지션 뱃지 | 포지션 재지정 메뉴 | IDLE에서만 |
| 좌석 전체 롱프레스 | 컨텍스트 메뉴: Move/Swap/Remove/Sit Out | 핸드 중 Move/Remove 불가 |

### 좌석 위젯 구성 요소

| 요소 | 바인딩 | 비고 |
|------|--------|------|
| 국기 | `seat.player.country_code` | ISO 3166-1 alpha-2 → Flag emoji/icon |
| 이름 | `seat.player.name` | 말줄임, 인라인 탭 수정 |
| 포지션 뱃지 | D / SB / BB / STR | 해당 포지션에만 |
| Stack | `seat.player.stack` | Roboto Mono, 콤마 포맷 |
| 홀카드 2장 | `seat.cards[0,1]` | RFID 또는 수동, 탭으로 수정 |
| 액션 배지 | `seat.last_action` | CHECK/FOLD/BET/CALL/RAISE/ALL-IN |
| Equity | `seat.equity` | **'%' 숫자만** (프로그레스 바 제거) |

### 1.2 좌석 상태별 시각 처리

| SeatFSM 상태 | Player 상태 | 시각 처리 |
|:----------:|:---------:|----------|
| **VACANT** | — | 빈 좌석 아이콘 + "OPEN" 텍스트 |
| **OCCUPIED** | active | 정상 표시. action_on이면 펄스 애니메이션 |
| **OCCUPIED** | folded | 반투명 (opacity 0.4) + 회색 |
| **OCCUPIED** | allin | 스택 강조 + "ALL IN" 텍스트 |
| **OCCUPIED** | sitting_out | 회색 + "AWAY" 텍스트 |
| **OCCUPIED** | eliminated | 빨간색 + "OUT" 텍스트 (토너먼트) |
| **RESERVED** | — | 예약 아이콘 + 플레이어 이름 (착석 전) |

---

## 2. 플레이어 등록

### 2.1 빈 좌석에 플레이어 배치

| 단계 | 운영자 액션 | CC 반응 |
|:----:|------------|---------|
| 1 | VACANT 좌석 클릭 | 플레이어 검색 다이얼로그 열림 |
| 2 | 이름 검색 또는 신규 입력 | BO DB에서 플레이어 검색 결과 표시 |
| 3 | 플레이어 선택 | 이름, 국가, 프로필 사진 미리보기 |
| 4 | 스택 입력 | 초기 칩 스택 금액 입력 (기본값: Event 설정값) |
| 5 | 확인 | `SeatAssign` 이벤트 → 좌석 OCCUPIED, 플레이어 표시 |

### 2.2 신규 플레이어 등록

BO DB에 없는 플레이어를 즉석 등록:

| 필드 | 필수 | 설명 |
|------|:----:|------|
| **이름** | ✅ | 오버레이 표시용 이름 |
| **국가** | ❌ | 국기 표시용 |
| **스택** | ✅ | 초기 칩 스택 |

> 참조: 플레이어 상세 정보 (KYC, 금융 등)는 EBS 범위 외. 오버레이 표시에 필요한 최소 정보만 수집.

### 2.3 딜러 배정 및 재지정 (2026-04-21 신설)

> **배경**: 기존 기획에 `§1.1 포지션 뱃지 클릭 → 포지션 재지정 (IDLE only)` · `§5.3 딜러 버튼 자동 이동` · `§6.1 Dealer 뱃지 시각` 이 개별 명시되었으나 **"빈 테이블 → 첫 핸드 시작 전 BTN 이 없는 상태"** 의 배정 경로가 undefined. 2026-04-21 NEW HAND silent fail 사용자 제보 (`canStartHand=false — no dealer`) 로 drift 확정 → 본 §2.3 로 해소.

딜러 배정은 **3 mechanism** 이 단계적으로 보완한다. 운영자는 대부분 §2.3.1 자동 배정 + §2.3.3 자동 전진만 겪고, §2.3.2 수동 재지정은 예외 교정 경로.

#### 2.3.1 자동 배정 — 첫 플레이어 착석 시 (Auto-assign on first seat)

| 상태 전이 | CC 반응 |
|-----------|---------|
| `dealerSeatProvider == null` 상태에서 `SeatAssign` 이벤트 발생 | 그 좌석을 **BTN 자동 배정** (`setDealer(seatNo)`) |
| 모든 좌석 VACATE → 다시 첫 착석 | 동일 경로 재적용 |
| 이미 dealer 배정된 상태에서 추가 플레이어 착석 | 자동 배정 로직 skip (기존 BTN 유지) |

- **Why**: "뱃지가 없어서 §2.3.2 진입점 자체가 없음" 무한 루프 해소. 빈 테이블 → NEW HAND 경로를 별도 UI 없이 확보
- **How to apply**: `SeatNotifier.seatPlayer(seatNo)` 내부에서 `if (dealerSeatProvider == null) setDealer(seatNo)`. UI 없음 (자동)
- 시각: BTN 뱃지 즉시 표시 (§6.1)

#### 2.3.2 수동 재지정 — 포지션 뱃지 클릭 (IDLE only)

| 트리거 | CC 반응 |
|--------|---------|
| BTN/SB/BB 포지션 뱃지 (§1.1) 클릭 | `Hand FSM == idle/handComplete` 인지 체크 |
| IDLE 이면 | 포지션 재지정 다이얼로그 open |
| IDLE 아니면 (PRE_FLOP 이후) | 경고 "핸드 진행 중에는 변경 불가" (§5.2 준수), 다이얼로그 안 뜸 |

**재지정 다이얼로그 내용**:

| 필드 | 설명 |
|------|------|
| Dealer (BTN) | 드롭다운 — 현재 occupied 좌석 목록 (sit-out 제외). 기본값: 현재 BTN |
| Cancel / Confirm | Confirm 시 `SeatMove`-like dealer-only update 이벤트 |

- **Why**: 빈 테이블 외의 상황에서 운영자가 잘못된 배정 또는 수동 조정이 필요한 edge case 교정
- **How to apply**: 기존 `§1.1 좌석 상세 편집` 테이블의 "포지션 뱃지" 행 (line 86) 을 직접 구현. 포지션 뱃지 원형 위젯에 `GestureDetector(onTap: ...)` 래핑
- **IDLE 제약 근거**: `§5.2 차단 동작` 의 "딜러 위치 변경 ❌ 핸드 내 불변" 일관성 유지

#### 2.3.3 자동 전진 — 핸드 완료 시 (Auto-rotate)

`§5.3 핸드 종료 후 자동 적용` 의 "딜러 버튼 자동 이동 (다음 좌석)" 규칙 재수록 (flow 명확화):

| 단계 | 동작 |
|:----:|------|
| 1 | `HandFsm == handComplete` 전이 시 |
| 2 | BTN 이 시계방향 **다음 occupied** 좌석으로 auto-advance |
| 3 | `sitting_out` 좌석은 skip |
| 4 | Heads-up (2 명 active) 시 Dealer = SB (별도 포커 규칙 문서 참조 — `BS-06-01` Heads-up 블라인드) |

> **렌더링 책임 분리 (critic 반박 5 반영)**: CC UI 는 `dealerSeatProvider` 현재 값만 시각화한다. Heads-up 특수 규칙 (Dealer=SB), missed blinds, dead button 등 포커 규약 연산은 **Game Engine 의 책임** — Engine 이 `dealerSeatProvider` state 를 올바르게 설정하고 CC 는 그 값을 BTN 뱃지로 렌더만. 이 분리로 CC UI 코드는 포커 규칙에 독립적.

#### 2.3.4 Edge Cases

| 상황 | 처리 | Provider 상태 |
|------|------|--------------|
| 현재 BTN 좌석의 플레이어가 `SeatVacate` (IDLE 중) | 다른 occupied 좌석으로 이동 (`§2.3.2 self-redirect`), occupied 없으면 `dealerSeatProvider → null` (§2.3.1 재활성) | `setDealer()` 또는 `clearDealer()` |
| 현재 BTN 좌석의 플레이어가 `SeatMove` (IDLE 중) | **BTN 은 좌석 위치 속성**이므로 플레이어가 이동해도 BTN 은 원 좌석에 유지. 운영자 의도가 "플레이어와 함께 BTN 도 이동" 이면 §2.3.2 로 별도 재지정 | 변경 없음 |
| BTN 좌석의 플레이어 Sit Out | BTN 유지, 핸드 시작 시 §2.3.3 의 skip 규칙 적용 | 변경 없음 |
| 모든 좌석 VACANT → 첫 착석까지 BTN 없음 | `§2.3.1` auto-assign 대기. NEW HAND 시도 시 `canStartHand=false` (활성 2명 < 2 부터 차단) | `dealerSeatProvider == null` |
| 2 좌석만 occupied 에서 `§2.3.2` 재지정 → 자신의 좌석 선택 | no-op (현재 BTN 과 동일), 다이얼로그 그냥 close | — |

#### 2.3.5 프로토타입 제약 (구현 범위)

프로토타입 범위에서는 다음은 **scope 외**:

| 항목 | 사유 |
|------|------|
| Dead button rule (heads-up 후 3인 복귀) | 정식 포커 토너먼트 규칙 — Phase 2 |
| Missed blinds tracking | Sit-out 관련 정밀 규칙, `BS-06-01` 범위 |
| Dealer 이동 애니메이션 (`§6.3 action-glow` 와 유사) | Overlay 측 애니메이션 필요, 별도 기획 |

#### 2.3.6 WSOP LIVE 정렬 (원칙 1 divergence)

WSOP LIVE Staff App Table Management (`wsoplive/docs/confluence-mirror/WSOP Live 홈/1. Documents/STAFF APP/04. Tournament Admin/Table Management.md`) 는 dealer 설정 UX 를 명시하지 않는다. WSOP LIVE 는 Staff App (토너먼트 관리 — 등록/좌석/지불) 과 Fatima.app (실시간 핸드 입력) 이 분리되어 있으며, dealer UX 는 Fatima.app 내부 로직.

EBS 는 `cc-web` 컨테이너 (Command Center) 에서 좌석 관리 + 실시간 핸드 입력 + RFID 카드 처리를 통합하므로 dealer 설정 UX 가 CC UI 에 필요. **의도적 divergence** — WSOP LIVE 의 테이블 관리 도메인 구조는 따르되, dealer 설정은 EBS 고유 (`cc-web` 라우트 내부에 포함).

---

## 3. 좌석 이동

### 3.1 드래그 앤 드롭

| 단계 | 운영자 액션 | CC 반응 |
|:----:|------------|---------|
| 1 | 플레이어 좌석 길게 클릭 (또는 우클릭) | 이동 모드 활성화, 좌석 하이라이트 |
| 2 | 대상 좌석으로 드래그 | 이동 가능 좌석 녹색, 불가 좌석 빨간색 |
| 3 | 대상 좌석에 드롭 | `SeatMove` 이벤트 발행 |

### 3.2 이동 규칙

| 대상 좌석 상태 | 이동 가능 | 결과 |
|:------------:|:--------:|------|
| VACANT | ✅ | 플레이어 이동, 원래 좌석 VACANT |
| OCCUPIED (다른 플레이어) | ✅ | 두 플레이어 좌석 교환 (Swap) |
| RESERVED | ❌ | "예약된 좌석입니다" 경고 |

### 3.3 컨텍스트 메뉴 이동

드래그 대신 컨텍스트 메뉴로 이동할 수 있다:

| 메뉴 항목 | 동작 |
|----------|------|
| Move to Seat... | 대상 좌석 번호 선택 다이얼로그 |
| Swap with Seat... | 교환할 좌석 번호 선택 |
| Remove from Seat | 좌석에서 퇴장 (SeatVacate) |

---

## 4. Sit In / Sit Out 토글

### 4.1 Sit Out

| 항목 | 설명 |
|------|------|
| **트리거** | 좌석 클릭 → 컨텍스트 메뉴 → "Sit Out" |
| **효과** | player.status = sitting_out. 다음 핸드부터 자동 폴드 처리 |
| **시각** | 좌석 회색 + "AWAY" 텍스트 |
| **스택** | 유지 (칩 제거 없음) |

### 4.2 Sit In

| 항목 | 설명 |
|------|------|
| **트리거** | "AWAY" 좌석 클릭 → "Sit In" |
| **효과** | player.status = active. 다음 핸드부터 참여 |
| **시각** | 정상 표시 복귀 |

---

## 5. 핸드 진행 중 좌석 변경 제한

### 5.1 허용 동작

| 동작 | 핸드 중 허용 | 적용 시점 |
|------|:----------:|----------|
| Sit Out 토글 | ✅ | **다음 핸드**부터 적용 (현재 핸드 영향 없음) |
| 스택 수동 조정 (ADJUST STACK) | ✅ | 즉시 반영 |

### 5.2 차단 동작

| 동작 | 핸드 중 허용 | 이유 |
|------|:----------:|------|
| 플레이어 추가 (SeatAssign) | ❌ | 핸드 중 인원 변경 불가 |
| 플레이어 제거 (SeatVacate) | ❌ | 핸드 데이터 무결성 |
| 좌석 이동 (SeatMove) | ❌ | 포지션 변경 불가 |
| 딜러 위치 변경 | ❌ | 핸드 내 불변 |

> 핸드 중 차단된 동작을 시도하면 "핸드 진행 중에는 사용할 수 없습니다" 경고가 표시된다.

### 5.3 핸드 종료 후 자동 적용

핸드가 HAND_COMPLETE → IDLE로 전환되면:
- 대기 중인 Sit Out 요청 적용
- 대기 중인 좌석 이동 실행 가능
- 딜러 버튼 자동 이동 (다음 좌석)

---

## 유저 스토리

| # | As a | When | Then |
|:-:|------|------|------|
| 1 | 운영자 | 빈 좌석 클릭 | 플레이어 검색 다이얼로그 열림 |
| 2 | 운영자 | 플레이어 검색 후 선택 + 스택 입력 | 좌석에 플레이어 배치, 이름+스택 표시 |
| 3 | 운영자 | 플레이어를 다른 빈 좌석으로 드래그 | 좌석 이동 완료, 원래 좌석 VACANT |
| 4 | 운영자 | 두 플레이어 좌석 간 드래그 | 두 플레이어 좌석 교환 (Swap) |
| 5 | 운영자 | 좌석 우클릭 → "Sit Out" | 해당 플레이어 AWAY 표시, 다음 핸드부터 자동 폴드 |
| 6 | 운영자 | AWAY 좌석 클릭 → "Sit In" | 다음 핸드부터 활성 참여 |
| 7 | 운영자 | 핸드 진행 중 좌석 이동 시도 | "핸드 진행 중에는 사용할 수 없습니다" 경고 |
| 8 | 운영자 | 핸드 종료 후 좌석 이동 | 정상 이동 처리 |
| 9 | 운영자 | 좌석 우클릭 → "Remove from Seat" | 확인 다이얼로그 → 좌석 VACANT |
| 10 | 운영자 | 예약된 좌석에 다른 플레이어 이동 시도 | "예약된 좌석입니다" 경고 |

---

## 경우의 수 매트릭스

### Matrix: SeatFSM × 운영자 가능 동작

| SeatFSM | 클릭 동작 | 드래그 동작 | 컨텍스트 메뉴 |
|:-------:|----------|-----------|-------------|
| **VACANT** | 플레이어 등록 | 드롭 대상 (수신) | — |
| **OCCUPIED (active)** | 플레이어 정보 보기 | 드래그 이동/교환 | Sit Out, Move, Remove, Adjust Stack |
| **OCCUPIED (sitting_out)** | Sit In 토글 | 드래그 이동 | Sit In, Move, Remove |
| **OCCUPIED (folded)** | 정보 보기만 | 핸드 중 이동 불가 | Sit Out (다음 핸드) |
| **OCCUPIED (allin)** | 정보 보기만 | 핸드 중 이동 불가 | — |
| **RESERVED** | 예약 정보 보기 | 이동 불가 | 예약 해제 (Admin만) |

---

## 비활성 조건

- Table 상태가 EMPTY/CLOSED일 때 좌석 관리 전체 비활성
- hand_in_progress == true일 때 SeatAssign/SeatVacate/SeatMove 차단
- Viewer 역할일 때 모든 좌석 관리 읽기 전용

---

## 영향 받는 요소

| 영향 대상 | 이 문서와의 관계 |
|----------|----------------|
| BS-05-01 핸드 라이프사이클 | 핸드 중 좌석 변경 제한 |
| BS-05-02 액션 버튼 | 활성 플레이어 수에 따른 버튼 활성 조건 |
| BS-02-lobby | Lobby Table Management와 좌석 데이터 동기화 |
| BS-07-overlay | 좌석 변경 시 Overlay 플레이어 위치 반영 |

---

## 6. 시각 규격 (CCR-032)

CC M-03 좌석 라벨 행과 M-05 좌석 카드 행의 색상·애니메이션 규격. Overlay(BS-07-01)는 동일 체계를 Rive 애니메이션으로 재현한다 (CCR-034).

### 6.1 포지션 마커 색상 (M-03)

| 포지션 | 표시 | CSS 색상 | 근거 |
|--------|------|---------|------|
| **Dealer** | 🔴 빨간 원 + "D" | `#E53935` (Material Red 600) | WSOP 원본 포커 관습 |
| **SB** (Small Blind) | 🟡 노란 원 + "SB" | `#FDD835` (Material Yellow 600) | WSOP 원본 |
| **BB** (Big Blind) | 🔵 파란 원 + "BB" | `#1E88E5` (Material Blue 600) | WSOP 원본 |
| **UTG** | 🟢 초록 원 + "UTG" | `#43A047` (Material Green 600) | WSOP 원본 |
| 일반 | ⚪ 흰색 원 (포지션 숫자) | `#FFFFFF` | Neutral fallback |

### 6.2 좌석 상태 배경색 (M-05)

| SeatFSM × Player 상태 | 배경색 | 투명도 | 추가 요소 |
|----------------------|--------|:------:|----------|
| VACANT | `#616161` (Gray 700) | 100% | "OPEN" 텍스트 |
| OCCUPIED + active | `#2E7D32` (Green 800) | 100% | — |
| OCCUPIED + active + action_on | `#2E7D32` + action-glow 펄스 | 100% | 노란 테두리 강조 |
| OCCUPIED + folded | `#616161` (Gray 700) | 40% | — |
| OCCUPIED + sitting_out | `#616161` (Gray 700) | 60% | "AWAY" 텍스트 |
| OCCUPIED + all_in | `#000000` (Black) | 100% | "ALL-IN" 텍스트 (흰색) |

### 6.3 action-glow 애니메이션

- **효과**: box-shadow 펄스 (Preattentive Processing)
- **주기**: 0.8초 (`infinite alternate`)
- **근거**: 아래 §7 설계 근거 참조

```css
@keyframes action-glow {
  from { box-shadow: 0 0 0 0 rgba(253, 216, 53, 0.4); }
  to   { box-shadow: 0 0 16px 4px rgba(253, 216, 53, 1.0); }
}

.seat-cell[data-action-on="true"] {
  animation: action-glow 0.8s infinite alternate;
}
```

### 6.4 Overlay 동기화

Overlay(BS-07-01-elements)는 본 섹션의 색상 체계와 주기(0.8s)를 동일하게 사용한다. CC와 Overlay의 색상 분열이 운영자와 시청자의 시각 언어를 분열시키는 것을 방지 (CCR-034).

### 6.5 Table별 Override

특정 테이블에서 브랜딩 목적으로 색상을 override하는 정책은 `BS-03-02-gfx §7 Overlay 색상 Override` (CCR-025) 참조.

---

## §7 설계 근거

> 본 섹션은 v10 이전 `team4-cc/ui-design/reference/action-tracker/analysis/EBS-AT-Design-Rationale.md §4.4` 에 분산되어 있던 설계 근거를 통합·보강한 결과이다. 원본 문서는 이주 과정에서 폐지되었으며 이 섹션이 SSOT이다.

### 7.1 색상체계 근거 (3색 분리)

| 상태 | 색상 | 설계 근거 |
|------|------|----------|
| OCCUPIED + active | Green 800 (`#2E7D32`) | 긍정 · 안정 신호. 운영자가 **중립 상태의 다수 좌석**을 한눈에 스캔 가능 |
| OCCUPIED + folded | Gray 700 40% | "비활성" 의 시각적 표현. 채도/명도 동시 감소로 인지 부하 감소 |
| OCCUPIED + all_in | Black (`#000000`) | 매우 높은 명도 대비(흰 ALL-IN 텍스트) + 채도 0 — Preattentive feature 로 즉시 탐지 |
| OCCUPIED + action_on | Green 800 + Yellow 600 테두리 펄스 | 기본 색상(active) 을 유지하면서 **추가 레이어**(테두리+애니메이션) 로 주의 유도. 색상 교체 대신 additive signal 을 선택해 문맥 유지 |

**선택 원칙**: 동시에 표시되는 최대 9좌석에서 운영자가 각 좌석의 상태를 시각 탐색(visual search) 이 아닌 사전주의 처리(preattentive processing, <250ms) 로 인지해야 한다. 따라서 각 상태는 채도·명도·형태 3개 차원 중 **최소 2개**가 동시에 달라지도록 배정.

### 7.2 배치 근거 (원형 9-max 유지)

PokerGFX Reference 및 WSOP LIVE Confluence 원본을 따라 원형 9좌석 배치 유지.

- **원형 배치가 행-based 대비 우월한 점**
  - 카드룸 물리 좌석과의 공간적 일치 → 운영자가 물리 좌석 번호↔화면 좌석을 **직접 매핑 없이** 찾음
  - dealer button 위치의 시계방향 회전이 자연스러운 mental model 제공
- **trade-off**: 좁은 화면에서 좌석 크기가 작아짐 — Lobby 에서 multi-table tiling 을 하지 않고 **1 table = 1 CC 인스턴스**(CLAUDE.md §"Lobby:CC = 1:N") 로 해결

### 7.3 애니메이션 주기 0.8초 근거

| 주기 후보 | 평가 |
|-----------|------|
| 0.3초 | 운영자 주의 점유율 과다. 복수 좌석 동시 펄스 시 인지 피로 |
| 0.5초 | 짧은 동작 · 시각 피로 중간 |
| **0.8초** | **선택** — 시각 인지 한계치(약 100ms 감지) 대비 충분히 길고, 1Hz 인체 반응 주기 이내 |
| 1.2초 | 반응 지연 인식. "지금 action_on 좌석인가?" 확인 시간 초과 |

또한 Overlay(시청자 화면) 와 **동일 주기**로 동기화(CCR-034) — 시청자 시각 언어와 운영자 시각 언어가 분열되지 않도록 한다.

### 7.4 배제된 대안

- **깜빡임(blink)**: 접근성(광민감 발작 WCAG 2.3.1, 3Hz 이상 금지) 문제. 0.8초 펄스는 1.25Hz 로 안전.
- **화살표/마커 추가**: 좁은 좌석 셀 내 추가 UI 요소는 이미 있는 position chip(Dealer/SB/BB) 과 시각 충돌.
- **사운드**: CC 는 방송 현장에서 운용되므로 청각 피드백 사용 불가.

### 7.5 변경 시 재평가 필요 항목

아래 항목을 변경할 때는 위 §7.1~7.4 의 근거를 함께 업데이트해야 한다.

1. 색상 팔레트 (§6.2) → §7.1 trade-off 재평가
2. 애니메이션 주기 (§6.3) → §7.3 후보 비교 갱신
3. 배치 (행-based 전환 등) → §7.2 PokerGFX 일치성 재검증

---

## 8. Visual Uplift — Seat Cell 7행 보강 + Position Shift (B-team4-011 V4·V5, 2026-05-06)

> **트리거**: 2026-05-05 디자이너 React 시안 critic 판정. 기존 §1.1 (6개 표시 항목) 은 정보 밀도 우월하나 운영자가 핸드 중 정보 스캔 비용 큼. SSOT: `docs/4. Operations/CC_Design_Prototype_Critic_2026_05_06.md`.

### 8.1 7행 컬럼 레이아웃 (V5)

각 SeatCell 내부를 7행으로 재구성. 좌석 배치 (oval 360°) 자체는 변경 없음 — Cell **내부 정보 밀도** 만 강화.

| 행 | 내용 | 인라인 편집 | D7 가드 |
|:-:|------|:-----------:|:-------:|
| 1 | ACTING / WAITING / FOLD / DELETE strip (preHand 시 DELETE) | — | — |
| 2 | S번호 (대형) | tap → vacate confirm | — |
| 3 | Position (STRADDLE · SB·BB · D 3 sub-rows) | ‹ › shift 화살표 (V4) | — |
| 4 | Country flag + Player name | tap → name dialog | — |
| 5 | **Hole cards (face-down only)** | — | **CI 가드 강제** |
| 6 | STACK (mono $) | tap → stack dialog | — |
| 7 | BET / LAST action (동적) | tap → 수정 dialog | — |

### 8.2 D7 가드 (절대 위반 금지)

행 5 (Hole cards) 는 **face-down (뒷면) 만**. 디자인 시안의 `<img src=cardImagePath>` 패턴은 모방 금지. 검증:

```
tools/check_cc_no_holecard.py  # CI 가드 — face-up 카드 위젯 1 개라도 발견 시 빌드 실패
```

이유: 운영자(딜러) 가 카드 값을 미리 알면 부정 행위 가능 (SG-021 / Foundation §5.4 / IMPL-007). 라이브 토너먼트 = 사업 신뢰 의존.

### 8.3 PositionShiftChip — D/SB/BB/STR ‹ › 화살표 (V4)

행 3 의 각 position sub-row 에 좌/우 화살표 추가. 클릭 시 해당 position 마커가 시계방향(›) 또는 반시계방향(‹) 좌석으로 이동.

| Position | shift 가능 시점 | 결정 권한 | 검증 |
|----------|----------------|----------|------|
| **D (BTN)** | HandFSM ∈ {idle, handComplete} | CC 운영자 (§2.3.2) | 핸드 진행 중 차단 (§5.2 SnackBar) |
| **SB / BB** | — | **Game Engine 자동 결정** (§2.3.3) | 사용자 shift 비활성 — 안내 tooltip만 |
| **STRADDLE** | preHand only | CC 운영자 | 핸드 진행 중 차단 |

> **렌더링 책임 분리** (§2.3 critic 5 반영): SB/BB 는 Heads-up / Big-Blind-Ante 등 포커 규약 연산 결과로 Engine 이 결정한다. CC UI 는 결과만 표시. shift 화살표는 D/STRADDLE 에만 활성.

### 8.4 ACTING strip 상태별 색상

| 상태 | 색상 | 트리거 |
|------|------|--------|
| ACTING | accent (`Theme.colorScheme.primary`) | `seat.actionOn == true` |
| WAITING | outline (gray) | occupied & 다른 좌석이 acting |
| FOLD | error variant (dim red) | `seat.activity == folded` |
| DELETE | dashed red border | preHand (idle/handComplete) + 빈 좌석 아님 |

### 8.5 변경 영향

| 영향 | 비고 |
|------|------|
| oval 좌석 배치 (§1.1) | 변경 없음 |
| Engine 통신 (Overview §1.1.1) | 변경 없음 |
| HandFSM 전이 룰 | 변경 없음 |
| Seat Cell 위젯 코드 | `seat_cell.dart` ~250줄 보강 (V5) + `position_shift_chip.dart` 신규 (~120줄, V4) |

### 8.6 구현 위치 (예정)

- `team4-cc/src/lib/features/command_center/widgets/seat_cell.dart` 보강 (V5)
- `team4-cc/src/lib/features/command_center/widgets/position_shift_chip.dart` 신규 (V4)

진행 추적: `Backlog/B-team4-011-cc-visual-uplift-from-design-prototype.md`
