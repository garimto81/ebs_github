# BS-05-03 Command Center — 좌석 관리

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 10좌석 배치, 플레이어 등록/이동, Sit In/Out, 핸드 중 제한 |

---

## 개요

CC 테이블 영역의 10좌석(Seat 0~9)은 타원형 테이블 둘레에 배치된다. 각 좌석에 플레이어 이름, 스택, 카드, 상태가 표시되며, 운영자는 좌석 배치·이동·등록·퇴장을 관리한다.

> 참조: BS-00 §3.3 Seat 상태 (SeatFSM), BS-02-lobby §Table Management

---

## 정의

| 용어 | 정의 |
|------|------|
| **Seat** | 테이블 내 물리적 좌석 위치 (0~9). SeatFSM으로 상태 관리 |
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

타원형 테이블 둘레에 Seat 0~9이 배치된다. 각 좌석은 **Seat Cell** 컴포넌트로 구성된다.

| Seat Cell 표시 항목 | 데이터 | 상태별 표시 |
|-------------------|--------|-----------|
| **플레이어 이름** | player.name | 빈 좌석: "OPEN" |
| **스택** | player.stack | 숫자 (예: 50,000) |
| **홀카드** | 2장 슬롯 | RFID 감지 또는 수동 입력. 비공개 시 뒷면 |
| **현재 베팅** | player.current_bet | 베팅 중일 때만 표시 |
| **포지션 뱃지** | D / SB / BB / STR | 해당 포지션에만 표시 |
| **상태 아이콘** | active / folded / allin / sitting_out | 색상 + 텍스트 |

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
- **근거**: `team4-cc/ui-design/reference/action-tracker/analysis/EBS-AT-Design-Rationale.md §4.4`

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
