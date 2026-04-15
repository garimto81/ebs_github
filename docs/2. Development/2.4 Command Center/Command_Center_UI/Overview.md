---
title: Overview
owner: team4
tier: internal
legacy-id: BS-05-00
last-updated: 2026-04-15
---

# BS-05-00 Command Center — 개요

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | CC 전체 구조, Launch 플로우, 상태 표시, 화면 레이아웃 정의 |
| 2026-04-13 | UI-02 redesign | 좌석 S1~S10 변경, 대칭 배치, 수동 편집 우선 원칙, 인라인 편집 전환 |

---

## 개요

Command Center(CC)는 운영자가 포커 핸드를 실시간으로 진행하는 **게임 입력 전용 Flutter 앱**이다. 구 PokerGFX의 Action Tracker가 EBS에서 이름 변경된 것이며, 본방송 중 **운영자 주의력의 85%**가 이 화면에 집중된다.

CC는 Lobby(웹)와 별도 앱이다. Lobby에서 테이블을 선택하고 [Launch]하면 해당 테이블 전용 CC Flutter 인스턴스가 생성된다.

> 참조: BS-00 §1 앱 아키텍처 용어, BS-02-lobby §Lobby-Command Center 관계

---

## 정의

| 용어 | 정의 |
|------|------|
| **Command Center (CC)** | 테이블 1개의 게임 진행을 입력하는 Flutter 앱. 테이블당 1개 인스턴스 |
| **Overlay** | CC와 1:1 대응하는 시청자용 방송 그래픽 출력 |
| **Game Engine** | CC에 import되는 순수 Dart 패키지. 게임 규칙·상태 관리 |
| **Back Office (BO)** | Lobby↔CC 간 데이터 간접 공유 계층 (REST API + WebSocket + DB) |

---

## 1. CC = Table = Overlay (1:1:1)

| 관계 | 설명 |
|------|------|
| **CC 1개 = Table 1개** | CC 인스턴스는 단일 테이블만 담당 |
| **CC 1개 = Overlay 1개** | CC가 생성하는 게임 데이터가 Overlay 1개에 출력 |
| **Lobby : CC = 1 : N** | 1개 Lobby에서 N개 테이블의 CC를 관리 |

CC 인스턴스 간에는 직접 통신이 없다. 모든 데이터 공유는 Back Office DB를 경유한다.

---

## 2. CC Launch 플로우

### 2.1 Lobby에서 CC 생성

| 단계 | 주체 | 동작 |
|:----:|------|------|
| 1 | Lobby | 테이블 카드에서 [Launch] 클릭 |
| 2 | Lobby | BO에 CC 인스턴스 생성 요청 (REST API) |
| 3 | BO | table_id로 설정 로드 (게임 유형, 블라인드, RFID 모드, 출력 설정) |
| 4 | CC | Flutter 앱 실행, BO WebSocket 연결 |
| 5 | CC | 초기 GameState 수신 (IDLE 상태) |
| 6 | CC | UI 초기화 완료 — 운영자 입력 대기 |

### 2.2 전제조건

CC Launch 전 Lobby에서 다음이 완료되어야 한다:

| 전제조건 | 설명 |
|---------|------|
| Series/Event/Flight 선택 | 대회 경로 확정 |
| Table 생성 + 게임 설정 | 게임 유형, 블라인드 구조, 베팅 구조(NL/PL/FL) |
| 좌석 배치 (최소 2명) | 플레이어 2인 이상 착석 |
| RFID 모드 결정 | Real/Mock 선택 (Feature Table은 Real 권장) |

### 2.3 세션 복원

CC가 비정상 종료 후 재시작되면:

| 상태 | 복원 동작 |
|------|----------|
| 핸드 미진행 (IDLE) | 마지막 테이블 설정으로 IDLE 복원 |
| 핸드 진행 중 | Event Sourcing 기반 이벤트 리플레이 → 마지막 상태 복원 |
| BO 연결 불가 | 로컬 캐시로 최소 동작, 재연결 시도 |

---

## 3. CC 화면 구조

### 3.1 레이아웃 3영역

| 영역 | 위치 | 내용 |
|------|------|------|
| **상단 바** | 화면 최상단 고정 | 연결 상태, 게임 종류, 핸드 번호, RFID 상태 |
| **테이블 영역** | 화면 중앙 | 타원형 포커 테이블 + 10좌석(1~10) + 커뮤니티 카드 + 팟 |
| **액션 패널** | 화면 하단 고정 | 8개 액션 버튼 + 베팅 입력 + UNDO |

### 3.2 상단 바 표시 항목

| 항목 | 표시 | 상태 구분 |
|------|------|----------|
| BO 연결 | ● Connected / ○ Disconnected | 녹색 / 빨간색 |
| RFID 리더 | ● Online / ○ Offline / ⚠ Error | 녹/회/빨간색 |
| 게임 종류 | HOLDEM / PLO4 / PLO5 등 | 텍스트 |
| 핸드 번호 | Hand #N | 자동 증가 |
| HandFSM 상태 | IDLE / PRE_FLOP / FLOP 등 | 텍스트 + 색상 |
| 블라인드 레벨 | SB/BB (예: 100/200) | 텍스트 |

### 3.3 테이블 영역

| 요소 | 설명 |
|------|------|
| **타원형 테이블** | 화면 중앙에 포커 테이블 형태 배치 |
| **10좌석** | 타원 둘레에 Seat 1~10 배치. 각 좌석에 이름/스택/카드/상태 표시 |
| **딜러 버튼** | BTN 좌석에 D 뱃지 |
| **포지션 뱃지** | SB/BB/STR 뱃지 |
| **커뮤니티 카드** | 테이블 중앙에 5슬롯 (Flop 3 + Turn 1 + River 1) |
| **팟 표시** | 커뮤니티 카드 아래 현재 총 팟 금액 |

### 좌석 배치 — Dealer 기준 대칭

D(Dealer) 하단 중앙. D 왼쪽(시계방향): S1(SB) → S2(BB) → S3 → S4 → S5. D 오른쪽(반시계방향): S10 → S9 → S8 → S7 → S6. 좌우 대칭.

### 3.4 액션 패널 (8버튼)

하단 고정 영역에 8개 액션 버튼이 배치된다:

| 버튼 | 단축키 | 핵심 역할 |
|------|:------:|----------|
| **NEW HAND** | N | 새 핸드 시작 |
| **DEAL** | D | 홀카드 딜 시작 |
| **FOLD** | F | 현재 플레이어 포기 |
| **CHECK** | C | 패스 (베팅 없이 넘김) |
| **BET** | B | 첫 베팅 (금액 입력) |
| **CALL** | C | 콜 (동일 금액 맞춤) |
| **RAISE** | R | 레이즈 (추가 베팅, 금액 입력) |
| **ALL-IN** | A | 스택 전부 베팅 |

> 참조: 각 버튼 상세 명세는 BS-05-02-action-buttons.md

---

## 4. CC 상태 표시

### 4.1 HandFSM 상태별 CC 화면 변화 요약

| HandFSM 상태 | 테이블 영역 | 액션 패널 | 상단 바 |
|-------------|-----------|----------|---------|
| **IDLE** | 이름+스택만 표시 | NEW HAND 활성 | Hand # 대기 |
| **SETUP_HAND** | 포지션 뱃지 표시, 블라인드 수거 애니메이션 | DEAL 활성 | "Setting Up" |
| **PRE_FLOP** | 홀카드 슬롯 활성, action_on 펄스 | FOLD/CHECK/BET/CALL/RAISE/ALL-IN | 팟 실시간 |
| **FLOP** | 보드 3장, 폴드 반투명 | 동일 | 팟 갱신 |
| **TURN** | 보드 4장 | 동일 | 팟 갱신 |
| **RIVER** | 보드 5장 | 동일 | 최종 팟 |
| **SHOWDOWN** | 승자 강조, 핸드 공개 | 특수 버튼 (CHOP, RUN IT) | 결과 표시 |
| **HAND_COMPLETE** | 팟 분배 애니메이션 → 스택 갱신 | 비활성 → 3초 후 IDLE | Hand#+1 |

> 참조: HandFSM 상세 전이는 BS-06-01-holdem-lifecycle.md

### 4.2 연결 상태 모니터링

| 상태 | 표시 | 운영자 영향 |
|------|------|-----------|
| BO Connected | ● 녹색 | 정상 운영 |
| BO Disconnected | ○ 빨간색 + 재연결 카운트다운 | 로컬 캐시로 게임 계속, 핸드 데이터 BO 미전송 |
| RFID Online | ● 녹색 | 카드 자동 인식 가능 |
| RFID Offline | ○ 회색 | Mock 모드 또는 수동 입력만 가능 |
| RFID Error | ⚠ 빨간색 | 에러 내용 표시, 수동 폴백 필요 |

---

## 5. CC 설계 원칙

| 원칙 | 구현 |
|------|------|
| **키보드 우선** | 모든 핵심 액션을 단축키로 수행 가능. 마우스 없이 핸드 전체 진행 가능 |
| **시각적 명확성** | action_on 좌석 펄스, folded 반투명, 상태별 색상 구분 |
| **오류 복구** | UNDO 무제한 (현재 핸드 내), Miss Deal 선언, 수동 카드 입력 폴백 |
| **일관성** | 모든 게임 타입에서 동일한 레이아웃 및 버튼 패턴 유지 |
| **피로 최소화** | 수 시간 연속 사용 고려. 반복 동작(NEW HAND → 액션 → HAND_COMPLETE) 패턴 고정 |

### 수동 편집 우선 원칙

운영자가 수동으로 수정한 값은 DB/WebSocket에서 들어오는 값보다 우선한다.
- 수동 편집 후 DB 동기화 시 옵션: "수동 값 유지" (기본) / "DB 값으로 갱신"
- 좌석 위젯 우상단 동기화 아이콘(🔄)으로 제어
- 핸드 종료 시 자동 동기화 (수동 편집 상태 리셋)

---

## 비활성 조건

- Table 상태가 EMPTY 또는 CLOSED일 때 CC 인스턴스 생성 불가
- BO WebSocket 미연결 시 Lobby 모니터링 불가 (CC 로컬 동작은 가능)
- RFID 모드가 Real이고 리더 미연결 시 수동 폴백 모드로 전환

---

## 영향 받는 요소

| 영향 대상 | 이 문서와의 관계 |
|----------|----------------|
| BS-05-01 핸드 라이프사이클 | CC UI 관점의 핸드 진행 상세 |
| BS-05-02 액션 버튼 | 8개 버튼 각각의 활성/비활성 조건 상세 |
| BS-05-03 좌석 관리 | 테이블 영역의 좌석 배치/이동 UI |
| BS-05-04 수동 카드 입력 | RFID 폴백 시 카드 입력 UI |
| BS-05-05 Undo/복구 | 오류 복구 메커니즘 상세 |
| BS-05-06 키보드 단축키 | 단축키 전체 맵 |
| BS-05-07 Statistics | AT-04 Statistics 화면 (CCR-027) |
| BS-05-08 Game Settings Modal | AT-06 모달 (CCR-028) |
| BS-05-09 Player Edit Modal | AT-07 모달 (CCR-028) |
| BS-05-10 Multi-Table Operator | 다중 테이블 운영 패턴 (CCR-030) |
| BS-02-lobby | Lobby에서 CC Launch 플로우 |
| BS-06-00-triggers | CC 이벤트 21종 정의 |
| BS-06-01-holdem-lifecycle | HandFSM 상태 전이 |
| BS-07-overlay | CC와 1:1 대응 Overlay 출력 |

---

## 6. AT 화면 체계 (CCR-028)

CC 앱은 **8개 독립 화면**(AT-00 ~ AT-07)으로 구성되며, AT-01 Main은 **7개 Zone**(M-01 ~ M-07)으로 그룹핑된다. Miller's Law(7±2) 기반 인지 부하 최소화, 6시간+ 라이브 방송 피로 최소화 원칙.

### 6.1 화면 카탈로그

| 화면 ID | 이름 | 크기 | 진입 경로 | 상세 문서 |
|---------|------|------|---------|----------|
| AT-00 | Login | 480×360 | 앱 시작 | `BS-01-auth` |
| AT-01 | Main | 720 min-width, auto height | Login 성공 | 본 문서 §3, §6.2 |
| AT-02 | Action View | AT-01 Layer 4~6 오버레이 | 핸드 진행 중 | `BS-05-01`, `BS-05-02` |

> **AT-02 Action View**: AT-01 Main의 하위 레이어(Layer 4~6)로, 핸드 진행 중 액션 패널(M-07)이 활성화된 상태를 가리킨다. 별도 화면 전환 없이 AT-01 위에 오버레이되며, BS-05-02의 액션 버튼 활성/비활성 매트릭스가 적용된다.
| AT-03 | Card Selector | 560×auto (모달) | 카드 슬롯 탭 또는 RFID Fallback | `BS-05-04` |
| AT-04 | Statistics | — | M-01 Toolbar → Menu → Statistics | `BS-05-07-statistics.md` |
| AT-05 | RFID Register | — | Settings 또는 메뉴 | `BS-04-05-register-screen.md` |
| AT-06 | Game Settings | 600×auto (모달) | M-01 Toolbar → Menu → Game Settings | `BS-05-08-game-settings-modal.md` |
| AT-07 | Player Edit | 모달 | 좌석 요소 탭(인라인 편집) 또는 롱프레스 컨텍스트 메뉴 | `BS-05-09-player-edit-modal.md` |

### 6.2 AT-01 Main의 7 Zone 구조

| Zone | 이름 | 기능 |
|:----:|------|------|
| M-01 | Toolbar | NEW HAND, HIDE GFX 토글, Menu |
| M-02 | Info Bar | Hand #, Pot, SB/BB/Ante 표시 |
| M-03 | 좌석 라벨 행 | 포지션 마커 (Dealer/SB/BB/UTG) — 시각 규격은 `BS-05-03 §시각 규격` |
| M-04 | 스트래들 토글 행 | 좌석별 Straddle ON/OFF |
| M-05 | 좌석 카드 행 | 10좌석(S1~S10) 상태 (Active/Empty/Folded/All-In) |
| M-06 | 블라인드 패널 | `WriteGameInfo` 프로토콜 필드 (API-05 §9) |
| M-07 | 액션 패널 | FOLD/CALL/BET/RAISE/ALL-IN + UNDO |

### 6.3 반응형 해상도

- **최소 폭**: 720px (568px 이하 미지원)
- **높이**: auto (CSS Container Queries 기반)
- **근거**: Nielsen Heuristic #7 (Flexibility and Efficiency of Use)

### 6.4 데이터 계산 책임

| 데이터 | 계산 주체 | CC 역할 |
|--------|---------|--------|
| Equity (승률) | Game Engine (`EquityUpdated` 이벤트) | **표시만** ('%' 숫자) |
| Pot (팟 총액) | Game Engine (베팅 누적 계산) | **표시만** (WebSocket 수신) |
| Side Pot | Game Engine (올인 시 자동 분리) | **표시만** |
| 통계 (VPIP/PFR 등) | Backend (API-01 집계) | **조회 + Push** (BS-05-07) |

> CC는 자체적으로 Equity/Pot를 계산하지 않는다. Game Engine이 계산한 결과를 WebSocket/OutputEvent로 수신하여 표시한다.

---

## 7. Launch 플로우 상세 (CCR-029)

### 7.1 시퀀스

```
[Operator] → [Lobby Web] → [BO] → [DB] → [CC 신규 프로세스]

1. Operator가 Lobby에서 [Launch] 클릭
2. Lobby → BO: POST /api/v1/tables/{id}/launch
3. BO 검증:
   - auth 확인 (JWT role=Admin/Operator)
   - RBAC (Operator면 assigned_tables에 해당 table 포함)
   - TableFSM이 SETUP 이상인지
4. BO → DB: cc_session record 생성 (cc_instance_id 할당)
5. BO: launch_token 생성 (JWT 5분 수명)
6. BO → Lobby: 200 OK { cc_instance_id, launch_token, ws_url }
7. Lobby → OS: Flutter CC 앱 실행
   (OS별 shell command 또는 deep link)
8. CC 앱 시작 with args:
   --table_id={id}
   --token={launch_token}
   --cc_instance_id={uuid}
9. CC → BO: WebSocket 연결
   ws://host/ws/cc?table_id=X&token=launch_token&cc_instance_id=U
10. BO: launch_token 검증 + cc_instance_id 매칭
    + cc_session.status = CONNECTED
11. BO → CC: 초기 상태 JSON 전송 (TableState + Seat + 현재 Hand)
12. CC: IDLE 화면 진입, Ready
```

### 7.2 Launch 실패 복구

| 실패 | 대응 |
|------|------|
| Launch token 만료 (5분 초과) | Lobby가 자동 재요청 → 새 토큰 |
| CC 프로세스 실행 실패 | Lobby 경고 배너 "CC 실행 실패. OS 권한 확인" |
| WebSocket 연결 실패 | CC 재연결 시도 (§8 참조) |
| BO 검증 실패 (RBAC) | Lobby 배너 "권한 부족" + 403 |

### 7.3 API-01 엔드포인트

`POST /api/v1/tables/{id}/launch` 상세는 `API-01-backend-api.md` 참조.

---

## 8. BO 연결 상실 복구 (CCR-031, W2 해소)

### 8.1 감지

- WebSocket `Ping` 30초 간격 / `Pong` 10초 타임아웃 (API-05 §하트비트)
- 3회 연속 Pong 타임아웃 → 연결 상실로 판단

### 8.2 복구 흐름

```
BO WebSocket 연결 상실 감지
  │
  ├─ 핸드 미진행 (HandFSM == IDLE)
  │   ├─ AT-01 우상단 연결 상태 아이콘 → 적색
  │   ├─ M-01 Toolbar에 "재연결 중..." 토스트
  │   ├─ 재연결 시도: 0ms → 5s → 10s × 최대 100회 → 중단
  │   └─ 재연결 성공:
  │        ├─ GET /tables/{id}/state 호출
  │        ├─ 서버 상태 수신 → IDLE 복귀
  │        └─ 연결 아이콘 → 녹색
  │
  └─ 핸드 진행 중 (HandFSM ∈ { PRE_FLOP, FLOP, TURN, RIVER, SHOWDOWN })
      ├─ AT-01 최상단 경고 배너 "BO 연결 끊김 — 로컬 모드 (액션 X/20)"
      ├─ 로컬 Event Sourcing 스택에 모든 액션 기록 (최대 20 이벤트)
      ├─ 액션 버튼은 정상 활성 (로컬 검증만, 서버 ActionOnResponse 무시)
      ├─ RFID 감지 계속 동작 (로컬 스택에 기록)
      │
      └─ 재연결 성공 시:
         ├─ 로컬 이벤트 스택 → `ReplayEvents` 프로토콜로 BO에 일괄 전송
         │   payload: { hand_id, events: [{ type, payload, local_timestamp }, ...] }
         │
         ├─ BO 응답 처리:
         │   ├─ Accept → 모든 이벤트 수용, 상태 동기화, 배너 해제
         │   ├─ PartialAccept → N개까지 수용, "N번째부터 재입력 필요" 다이얼로그
         │   └─ Reject → "동기화 실패, 핸드 Reset 필요" → `AbortHand`
         │
         └─ 20 이벤트 초과 시:
             ├─ 로컬 스택 가득 참 → "이벤트 버퍼 초과" 경고
             ├─ 새 액션 입력 차단
             └─ 운영자가 핸드 Reset 선택 가능
```

### 8.3 구현 요구사항

| 항목 | 값 |
|------|---|
| 하트비트 간격 | 30초 |
| Pong 타임아웃 | 10초 |
| 재연결 백오프 | 0ms → 5s → 10s × 100 → 중단 |
| 로컬 이벤트 버퍼 | 20 이벤트 |
| ReplayEvents 최대 payload | 20 × 2KB = 40KB |

---

## 9. Table FSM vs HandFSM 경계 (CCR-031, W6 해소)

| FSM | 소관 | 전이 주체 |
|-----|------|----------|
| **TableFSM** (`EMPTY/SETUP/LIVE/PAUSED/CLOSED`) | 테이블 생명주기 (Lobby 관리) | Lobby 또는 Admin |
| **HandFSM** (`IDLE/SETUP_HAND/PRE_FLOP/.../HAND_COMPLETE`) | 현재 핸드 진행 (CC 관리) | CC 운영자 + Game Engine |

**규칙**:
- `PAUSED`는 **TableFSM** 상태 (CC는 구독자)
- TableFSM == PAUSED면 HandFSM은 freeze — 액션 버튼 비활성
- TableFSM이 PAUSED → LIVE 전이 시 HandFSM은 이전 상태 복원 (로컬 Event Sourcing 기반)

---

## 10. 운영 패턴 — 1:1:1 vs 1:N (CCR-030)

| 관계 | 의미 |
|------|------|
| **CC : Table : Overlay = 1:1:1** | 기술적 인스턴스 관계 (불변) |
| **Operator : CC 인스턴스 = 1:N** | 한 명의 운영자가 여러 CC 동시 관리 가능 |

다중 테이블 운영의 3가지 패턴(A/B/C)과 키보드 포커스 정책 등 상세는 `BS-05-10-multi-table-ops.md` 참조.
