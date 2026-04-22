---
title: State Machines
owner: team2
tier: internal
legacy-id: DATA-03
last-updated: 2026-04-15
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "DATA-03 상태 기계 완결 (15KB) — SG-009 직렬화 규약 반영"
---
# DATA-03 State Machines

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 5개 FSM 상태 전이 다이어그램 + 트리거/가드/부작용 초판 |
| 2026-04-13 | WSOP LIVE 정합성 수정 | SeatFSM 3→9상태 확장(관측된 Seat Status 코드), EventFSM Announce→Announced + isRegisterable + 표시 상태, TableFSM RESERVED_TABLE 추가 |
| 2026-04-15 | G1 재분류 | SeatStatus 코드를 "WSOP LIVE 준거" → **관측 기반 justified divergence** 로 재분류. Confluence 미러 전수 조사(Enum 1960411325 / Action History 1679556614 / Database 설명 2234666099 / SQL 1655537989)에서 `EventFlightSeat.Status` 명시적 enum 값 정의 불발견. 외부 sync 대상 아님 |

---

## 개요

EBS에서 상태를 관리하는 5개 FSM(Finite State Machine)의 전이 다이어그램을 정의한다. 각 전이에 트리거(누가 발동), 가드 조건(언제 허용), 부작용(무엇이 변경)을 명시한다.

> 참조: 상태값 정의 — BS-00 Definitions 3, FSM 이름 규약 — BS-00 5

### crash 복구 패턴 — Foundation §6.4 정합 (2026-04-22 신설)

본 5 FSM 의 상태는 DB (Schema.md) 가 SSOT 다. 프로세스 재시작 시 복구는 다음 순서로 수행된다:

1. `GET /api/v1/tables/{id}/state/snapshot` (API-01 §5.18) 호출 → 현재 FSM 상태 + `seq` 획득
2. snapshot 의 `table.status`, `current_hand.phase` 등을 소비자 로컬 state 에 **그대로** 적용
3. 이후 WebSocket 구독으로 전이 이벤트 (delta) 적용
4. WS gap 감지 시 replay API (`/tables/{id}/events?since_seq=N`, CCR-015)

**FSM 별 SSOT 분류** (WebSocket_Events §1.2.1 정합):

| FSM | SSOT 소스 | crash 복구 소스 |
|-----|-----------|----------------|
| TableFSM (§1) | BO DB | `GET /tables/{id}` 또는 snapshot `table.status` |
| HandFSM (§2) | **Engine** (audit 참고값은 BO) | Engine `GET /api/session/{id}.gameState` 우선 |
| SeatFSM (§3) | BO DB | snapshot `seats[*].status` |
| DeckFSM (§4) | BO DB | `GET /decks/{id}` |
| EventFSM (§5) | BO DB | `GET /events/{id}` |

---

## 1. TableFSM

Table의 생명주기. Lobby에서 관리.

```mermaid
stateDiagram-v2
    [*] --> EMPTY : 테이블 생성
    EMPTY --> SETUP : 게임 설정 시작
    SETUP --> LIVE : CC Launch 완료
    LIVE --> PAUSED : 운영자 Pause
    PAUSED --> LIVE : 운영자 Resume
    LIVE --> CLOSED : 운영자 Close
    PAUSED --> CLOSED : 운영자 Close
    CLOSED --> EMPTY : Reset (재사용)
    LIVE --> RESERVED_TABLE : Admin Reserve Table
    SETUP --> RESERVED_TABLE : Admin Reserve Table
    RESERVED_TABLE --> LIVE : Admin Release Table
    RESERVED_TABLE --> SETUP : Admin Release Table (SETUP 복귀)
```

### 전이 상세

| 전이 | 트리거 | 가드 조건 | 부작용 |
|------|--------|----------|--------|
| [*] → EMPTY | Admin: [+ New Table] | — | `tables` INSERT, `audit_logs` INSERT |
| EMPTY → SETUP | Admin: [Start Setup] | 게임 설정 완료 + 플레이어 1명+ 등록 | `table_sessions` 레코드 생성 |
| SETUP → LIVE | Admin: [Go Live] / CC Launch | 좌석 배치 완료, Feature: RFID 할당 + 덱 등록 | CC 인스턴스 생성, WebSocket 구독 시작 |
| LIVE → PAUSED | Admin/Operator: [Pause] | — | CC 핸드 입력 차단, 오버레이 "PAUSED" 표시 |
| PAUSED → LIVE | Admin/Operator: [Resume] | — | CC 핸드 입력 재개, 오버레이 복원 |
| LIVE → CLOSED | Admin: [Close] | 진행 중 핸드 없음 | `table_sessions.ended_at` 기록, CC 종료, 오버레이 제거 |
| PAUSED → CLOSED | Admin: [Close] | — | 위와 동일 |
| CLOSED → EMPTY | Admin: [Reset] | 확인 다이얼로그 승인 | 핸드 카운트 초기화, 설정 유지, 좌석 초기화 |
| LIVE → RESERVED_TABLE | Admin: Reserve Table | — | `tables.status` UPDATE, Auto Seating 제외, 짙은 회색 표시 |
| SETUP → RESERVED_TABLE | Admin: Reserve Table | — | 동일 |
| RESERVED_TABLE → LIVE | Admin: Release Table | — | `tables.status` UPDATE, Auto Seating 포함 |

### Feature Table 추가 가드

| 전이 | 추가 가드 | 차단 메시지 |
|------|----------|------------|
| SETUP → LIVE | RFID 리더 할당 | "RFID 리더를 할당하세요" |
| SETUP → LIVE | 덱 등록 완료 (52장) | "덱 등록을 완료하세요" |
| SETUP → LIVE | 좌석 배치 완료 | "좌석 배치를 완료하세요" |

---

## 2. HandFSM

Hand의 생명주기. Game Engine에서 관리. CC 명령 + RFID 입력으로 전이.

```mermaid
stateDiagram-v2
    [*] --> IDLE
    IDLE --> SETUP_HAND : NEW HAND
    SETUP_HAND --> PRE_FLOP : DEAL
    PRE_FLOP --> FLOP : 보드 3장 공개
    FLOP --> TURN : 보드 4장째 공개
    TURN --> RIVER : 보드 5장째 공개
    RIVER --> SHOWDOWN : 쇼다운 진입
    PRE_FLOP --> HAND_COMPLETE : 전원 폴드
    FLOP --> HAND_COMPLETE : 전원 폴드
    TURN --> HAND_COMPLETE : 전원 폴드
    RIVER --> HAND_COMPLETE : 전원 폴드
    SHOWDOWN --> HAND_COMPLETE : 승자 결정
    HAND_COMPLETE --> IDLE : 핸드 종료
    RIVER --> RUN_IT_MULTIPLE : 런잇타임 선택
    RUN_IT_MULTIPLE --> HAND_COMPLETE : 모든 런 완료
```

### 전이 상세

| 전이 | 트리거 | 가드 조건 | 부작용 |
|------|--------|----------|--------|
| IDLE → SETUP_HAND | CC: NEW HAND | 활성 플레이어 2명+ | `hands` INSERT, hand_number 증가 |
| SETUP_HAND → PRE_FLOP | CC: DEAL | 블라인드 수집 완료, 딜러 위치 결정 | 홀카드 배분, 블라인드 자동 수집 |
| PRE_FLOP → FLOP | RFID/CC: 보드 3장 | 프리플롭 베팅 라운드 완료 | board_cards 업데이트, Equity 재계산 |
| FLOP → TURN | RFID/CC: 보드 4장째 | 플롭 베팅 라운드 완료 | board_cards 업데이트, Equity 재계산 |
| TURN → RIVER | RFID/CC: 보드 5장째 | 턴 베팅 라운드 완료 | board_cards 업데이트, Equity 재계산 |
| RIVER → SHOWDOWN | Engine: 자동 | 리버 베팅 라운드 완료, 활성 2명+ | 카드 공개 요청 |
| SHOWDOWN → HAND_COMPLETE | Engine: 자동 | 승자 결정 | 팟 분배, `hand_players` 승자/PnL 기록 |
| {any_street} → HAND_COMPLETE | Engine: 자동 | 활성 1명만 남음 (전원 폴드) | 마지막 남은 플레이어에게 팟 전달 |
| HAND_COMPLETE → IDLE | Engine: 자동 | 팟 분배 완료 | `hands` 업데이트 (종료 시각, duration), 통계 갱신 |
| RIVER → RUN_IT_MULTIPLE | CC: Run It | 올인 2명+, 보드 미완성 | 추가 보드 생성 |
| RUN_IT_MULTIPLE → HAND_COMPLETE | Engine: 자동 | 모든 런 완료 | 런별 팟 분배 |

> 상세: BS-06-01 시나리오 문서 참조

---

## 3. SeatFSM

Seat의 상태. Lobby + CC에서 관리. WSOP LIVE Seat Status 코드 9상태.

```mermaid
stateDiagram-v2
    [*] --> EMPTY : 테이블 생성 시
    EMPTY --> NEW : SeatAssign (플레이어 배치)
    EMPTY --> RESERVED : SeatReserve (배치 제외)
    EMPTY --> HOLD : Hold Seats (Seat Draw 선점)
    NEW --> PLAYING : 10분 경과 또는 핸드 참여
    PLAYING --> EMPTY : SeatVacate (이탈)
    PLAYING --> BUSTED : PlayerEliminate (탈락 요청)
    PLAYING --> EMPTY : SeatMove (출발)
    EMPTY --> MOVED : SeatMove (도착)
    MOVED --> PLAYING : 10분 경과 또는 핸드 참여
    BUSTED --> EMPTY : PlayerEliminate (FM/TD confirm)
    RESERVED --> EMPTY : SeatRelease (예약 해제)
    HOLD --> EMPTY : Hold 해제
    EMPTY --> WAITING : Auto Seating 웨이팅 배정
    WAITING --> PLAYING : 플레이어 도착
    EMPTY --> OCCUPIED : BreakTable 재배치 예약
    OCCUPIED --> PLAYING : 플레이어 도착
```

### 전이 상세

| 전이 | 트리거 | 가드 조건 | 부작용 |
|------|--------|----------|--------|
| [*] → EMPTY | 시스템: 테이블 생성 | — | `table_seats` INSERT (seat_no별 10개) |
| EMPTY → NEW | Admin/Auto: 좌석 배치 | 유효한 player_id | `table_seats` UPDATE (player_id, status='new'). 10분 타이머 시작 |
| NEW → PLAYING | 시스템: 10분 경과 또는 핸드 참여 | — | `table_seats` UPDATE (status='playing') |
| PLAYING → EMPTY | Admin: 제거 / CC: Vacate | 핸드 미진행 중 | `table_seats` UPDATE, `audit_logs` INSERT |
| PLAYING → BUSTED | CC: PlayerEliminate (요청) | 핸드 미진행 중 | `table_seats` UPDATE (status='busted'). FM/TD 확인 대기 |
| BUSTED → EMPTY | Admin: PlayerEliminate (확인) | FM/TD 권한 | `table_seats` UPDATE (player_id=NULL, status='empty'), `audit_logs` INSERT |
| PLAYING → EMPTY (이동 출발) | Admin: SeatMove | 도착 좌석 EMPTY | 출발 좌석 EMPTY, 도착 좌석 MOVED |
| EMPTY → MOVED | Admin: SeatMove (도착) | 출발 좌석 PLAYING | `table_seats` UPDATE (status='moved'). 10분 타이머 시작 |
| MOVED → PLAYING | 시스템: 10분 경과 또는 핸드 참여 | — | `table_seats` UPDATE (status='playing') |
| EMPTY → RESERVED | Admin: SeatReserve | — | `table_seats` UPDATE (status='reserved'). Auto Seating 제외 |
| RESERVED → EMPTY | Admin: SeatRelease | — | `table_seats` UPDATE (status='empty') |
| EMPTY → WAITING | Auto Seating: 웨이팅 배정 | 웨이팅 큐에 플레이어 존재 | `table_seats` UPDATE (status='waiting', player_id). 황색 표시 |
| WAITING → PLAYING | 시스템: 플레이어 도착 | — | `table_seats` UPDATE (status='playing') |
| EMPTY → HOLD | Admin: Hold Seats (Seat Draw) | — | `table_seats` UPDATE (status='hold'). 회색 표시 |
| HOLD → EMPTY | Admin: Hold 해제 | — | `table_seats` UPDATE (status='empty') |
| EMPTY → OCCUPIED | BO: BreakTable 재배치 예약 | — | `table_seats` UPDATE (status='occupied'). 도착 예정 플레이어 매핑 |
| OCCUPIED → PLAYING | 시스템: 플레이어 도착 | — | `table_seats` UPDATE (status='playing') |

### EBS 내부 SeatStatus 코드 (2026-04-15 justified divergence)

**근거 불발견**: WSOP LIVE Confluence 미러 전수 조사(Enum `1960411325`, Action History `1679556614`, WSOP+ Database 설명 `2234666099`, Sp 자리 배치 `1655537989`)에서 `EventFlightSeat.Status` 의 명시적 enum 값 정의를 찾지 못했다. 공개 자료에서는 `Database 설명: int, 기본값 0` 과 SQL 프로시저의 `Status = 0/1/2` 만 관측되며, 각 정수값의 의미는 문서화되어 있지 않다.

**재분류 판정**: 아래 코드 문자(E/N/M/B/O/R/W/H)는 **WSOP LIVE 원문 enum 이 아닌, EBS Dealer Page UI 관측 기반으로 구성한 내부 shorthand** 다. 외부 sync 대상이 아니며, EBS FSM 내부 표시/전이에만 사용한다. Schema.md §table_seats SeatStatus CHECK 6값(empty/new/playing/moved/busted/reserved)이 DB 영속 enum 의 SSOT 이며, 아래 9상태 중 `occupied`/`waiting`/`hold`는 FSM 전이 표현용 임시 상태로, DB 저장 시 Schema 6값으로 매핑된다(→ 구체 매핑 규칙은 Spec Gap 후속 정리 대상).

| 코드 | EBS 상태 | 색상 | 설명 | DB 저장 값 (Schema 6값 매핑) |
|------|---------|------|------|---------|
| E | EMPTY | 백색 | 빈 좌석 | `empty` |
| N | NEW | — | 신규 배정 (10분 카운트다운) | `new` |
| M | MOVED | — | 이동해 온 좌석 (10분 카운트다운) | `moved` |
| B | BUSTED | 적색 | 탈락 요청 (FM/TD confirm 대기) | `busted` |
| O | OCCUPIED | — | Break Table 등 예약 점유 | `reserved` (예약 점유의 한 형태) |
| R | RESERVED | 짙은 회색 | Auto Seating 제외 | `reserved` |
| W | WAITING | 황색 | 웨이팅 플레이어에게 배정됨 | `new` (sit-in 대기의 한 형태) |
| H | HOLD | 회색 | Seat Draw in Advance 선점 | `reserved` (사전 선점의 한 형태) |
| — | PLAYING | 녹색 | 플레이 중 | `playing` |

---

## 4. DeckFSM

Deck의 RFID 등록 상태. CC + RFID HAL에서 관리.

```mermaid
stateDiagram-v2
    [*] --> UNREGISTERED : 덱 생성
    UNREGISTERED --> REGISTERING : 등록 시작
    REGISTERING --> REGISTERED : 52장 완료
    REGISTERING --> PARTIAL : 일부 실패
    PARTIAL --> REGISTERING : 재시도
    UNREGISTERED --> MOCK : Mock 모드 활성화
    MOCK --> UNREGISTERED : Mock 해제
```

### 전이 상세

| 전이 | 트리거 | 가드 조건 | 부작용 |
|------|--------|----------|--------|
| [*] → UNREGISTERED | Admin: 덱 생성 | — | `decks` INSERT, `deck_cards` 52행 INSERT (uid=NULL) |
| UNREGISTERED → REGISTERING | CC: 등록 시작 | RFID 리더 연결됨 | registered_count = 0, 스캔 UI 활성화 |
| REGISTERING → REGISTERED | RFID: 52장 감지 완료 | registered_count == 52, 중복 UID 없음 | registered_at 기록, `tables.deck_registered` = true |
| REGISTERING → PARTIAL | RFID: 스캔 중단/오류 | registered_count < 52 | 에러 로그 기록 |
| PARTIAL → REGISTERING | CC: 재시도 | RFID 리더 연결됨 | 미등록 카드부터 재개 |
| UNREGISTERED → MOCK | 시스템: Mock 모드 | Config: rfid_mode == 'mock' | 52장 가상 UID 자동 매핑, registered_count = 52 |
| MOCK → UNREGISTERED | 시스템: Real 모드 전환 | Config: rfid_mode == 'real' | 가상 UID 제거 |

---

## 5. EventFSM

Event 진행 상태. WSOP LIVE API 또는 Lobby에서 관리.

```mermaid
stateDiagram-v2
    [*] --> Created : 이벤트 생성
    Created --> Announced : 공지
    Announced --> Registering : 등록 시작
    Registering --> Running : 게임 시작
    Running --> Completed : 이벤트 종료
    Created --> Canceled : 이벤트 취소
    Announced --> Canceled : 이벤트 취소
    Registering --> Canceled : 이벤트 취소
```

### 전이 상세

| 전이 | 트리거 | 가드 조건 | 부작용 |
|------|--------|----------|--------|
| [*] → Created | Admin: 이벤트 생성 / API | — | `events` INSERT |
| Created → Announced | Admin: 공지 / API | — | `events.status` UPDATE |
| Announced → Registering | Admin: 등록 시작 / API | — | `events.status` UPDATE |
| Registering → Running | Admin: 게임 시작 / API | 참가자 1명+ | `events.status` UPDATE, EBS 활성 상태 |
| Running → Completed | Admin: 이벤트 종료 / API | 모든 테이블 CLOSED | `events.status` UPDATE |
| {Created/Announced/Registering} → Canceled | Admin: 이벤트 취소 | — | `events.status` UPDATE, 관련 Flight/Table 정리 |

> 참조: event_flight_status enum — BS-06-00-REF 1.2.5. EBS는 Running 상태에서만 게임 데이터를 처리한다.

### 표시 상태 (WSOP LIVE Tournament Status 정합)

Backend 상태와 `isRegisterable` 플래그, Day 번호의 조합으로 UI 표시 상태가 결정된다.

| Backend 상태 | isRegisterable | Day | 표시 상태 | 설명 |
|-------------|:-:|:-:|---------|------|
| Created | F | * | Created | App에서 미노출 |
| Announced | F | 1 | Announced | 등록 전 공지 상태 |
| Announced | F | 2+ | **Restricted** | Day2 이상에서 Announce 상태는 등록 불가 |
| Registering | T | 1 | Registering | Day1 등록 가능 |
| Registering | T | 2+ | **Late Reg.** | Day2 이상 등록 가능 |
| Registering | F | * | Registering | Staff만 등록 가능 (App 불가) |
| Running | T | * | **Late Reg.** | 시작 후에도 등록 가능 |
| Running | F | * | Running | 등록 마감 |
| Completed | * | * | Completed | Flight 종료 |
| Canceled | * | * | Canceled | Flight 취소 |

> **참조**: WSOP LIVE Tournament Status (Confluence page 1904542277)

---

## FSM 관리 위치 요약

| FSM | 관리 주체 | 저장 위치 | 실시간 동기화 |
|-----|----------|----------|:----------:|
| **TableFSM** | Lobby (BO) | `tables.status` | WebSocket → CC |
| **HandFSM** | Game Engine (CC) | CC 메모리 → `hands` | WebSocket → Lobby |
| **SeatFSM** | Lobby + CC | `table_seats.status` | WebSocket 양방향 |
| **DeckFSM** | CC + RFID HAL | `decks.status` | WebSocket → Lobby |
| **EventFSM** | Lobby (BO) / API | `events.status` | REST API |
