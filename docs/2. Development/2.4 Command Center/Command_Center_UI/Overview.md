---
title: Overview
owner: team4
tier: internal
legacy-id: BS-05-00
last-updated: 2026-05-07
---

# BS-05-00 Command Center — 개요

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | CC 전체 구조, Launch 플로우, 상태 표시, 화면 레이아웃 정의 |
| 2026-04-21 | §2.0 실행 경로 note | Linked (Lobby Launch) / Dev 테스트 (`flutter run -d windows`) 간결 명시. Demo Scenario scope 제외. 과대 기획 제거 (프로토타입). |
| 2026-04-21 | §1.1.1 호출 순서/책임 분리 신설 | Type C 해소 — `WebSocket_Events §10.1 "BO→Engine 전달"` 과 본 §1.1 "BO→Engine 없음" 모순 해결. CC=Orchestrator (Engine primary + BO secondary 병행), payload 동형성, 실패 처리 4 케이스, multi-CC 독립성. critic 반박 6 건 중 2/3/5 반영. notify: team2 (WebSocket_Events §10.1 정정) |
| 2026-04-22 | §1.1.1 Action-to-Transport Matrix 신설 | P1/P2/P3 cascade 정정. action 유형별 Engine/BO 호출 규칙 표로 명시 (NEW HAND 병행 / DEAL skip Engine / FOLD-ALLIN 병행 / UNDO 병행 / MISS DEAL BO-only). Body derivation rule (correlation_id + 동형 source → 2 target). critic 반박 8 건 중 7 반영. notify: team2 (§9/§11), conductor (Foundation §Ch.6.3) |
| 2026-04-22 | §1.1.1 Engine response schema 실측 정렬 (notify: team3) | B-team4-006 E2E 검증 (curl 실측) 결과 Engine 응답이 `{gameState, outputEvents[]}` 2-field envelope 이 아닌 **full state snapshot** (`sessionId, street, seats[], community[], pot, actionOn, ...` flat) 확인. "outputEvents" 표현 6건 수정 → "state snapshot". Harness_REST_API §2.1 response schema 도 동시 정정. |
| 2026-04-13 | UI-02 redesign | 좌석 S1~S10 변경, 대칭 배치, 수동 편집 우선 원칙, 인라인 편집 전환 |
| 2026-04-17 | 연동 아키텍처 명확화 | §1.1 데이터 흐름 신설 — CC↔Engine(직접 HTTP) + CC↔BO(WS 이벤트 발행) |
| 2026-05-06 | **§Widget Inventory 신설** (B-team4-011) | React 시안 critic 판정 후속 — Visual Uplift V1~V7 위젯 인벤토리. KeyboardHintBar (V1, ✅ 구현) / StatusBar (V2) / MiniDiagram (V3) / PositionShiftChip (V4) / SeatCell 7행 (V5) / ACTING glow (V6) / TweaksPanel (V7). SSOT: `docs/4. Operations/CC_Design_Prototype_Critic_2026_05_06.md`. |
| 2026-05-07 | **v4 정체성 정합** | CC_PRD v4.0 cascade — 1×10 그리드 + 6 키 + 4 영역 위계 + 5-Act 시퀀스 반영. §3.0 v4.0 정체성 신설 (구 §3.1/§3.3/§3.4 v1.x 타원형/8 버튼 기술은 archive 마킹). SSOT: `docs/1. Product/Command_Center_PRD.md` v4.0. |

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

## 1.1 CC 연동 데이터 흐름 (2026-04-17 실측 · 2026-04-21 §1.1.1 신설)

CC는 3개 외부 서비스와 통신한다. BO→Engine 직접 경로는 존재하지 않는다.

```
  운영자 입력 (FOLD/BET/RAISE/NEW HAND)
       │
       ▼
  ┌─────────────────────────────────────────┐
  │            CC (Flutter)                 │
  │                                         │
  │  ① Engine HTTP ──────► Game Engine      │
  │     POST /api/session/:id/event         │
  │     (게임 로직 검증 + state snapshot)    │
  │                                         │
  │  ② BO WebSocket ─────► Back Office      │
  │     WriteAction / WriteGameInfo         │
  │     (이벤트 발행 → DB 저장 → Lobby 포워딩)│
  │                                         │
  │  ③ BO REST ──────────► Back Office      │
  │     테이블/핸드/플레이어 CRUD            │
  └─────────────────────────────────────────┘
```

| 경로 | 프로토콜 | 용도 | 문서 |
|------|:--------:|------|------|
| CC → Engine | HTTP | 게임 로직 검증 (fold/bet/raise → state snapshot 반환) | `Harness_REST_API.md` |
| CC → BO (WS) | WebSocket | 이벤트 발행 + 설정 수신 | `WebSocket_Events.md §3, §9-§12` |
| CC → BO (REST) | HTTP | 테이블/핸드/플레이어 CRUD | `Backend_HTTP.md` |
| BO → Lobby (WS) | WebSocket | CC 이벤트 포워딩 | `WebSocket_Events.md §4` |
| BO → Engine | — | **없음** (CC가 Engine 직접 호출) | — |

> **설계 근거**: CC가 Engine을 직접 호출하므로 BO는 게임 로직에 관여하지 않는다. BO는 이벤트 저장·포워딩·감사 로그 역할만 수행. 이 분리는 BO 장애 시에도 CC←→Engine 게임 진행이 계속되도록 보장한다.

### 1.1.1 호출 순서 및 책임 분리 (2026-04-21 신설)

> **배경**: 2026-04-21 사용자 제보로 `_dispatchAction` 에서 Engine HTTP 호출 전혀 없음 확인. 더불어 `WebSocket_Events.md §10.1` 이 "BO는 Game Engine에 전달하여 게임 로직 검증" 으로 기술되어 있어 본 문서 §1.1 ("BO→Engine 없음") 과 **Type C 기획 모순** 상태. §1.1.1 신설로 아키텍처 확정 + §10.1 정정 (`notify: team2`).

#### 확정 아키텍처 — CC = Orchestrator

CC 가 **단일 action event 당 2 경로 병행 dispatch** 한다:

| 경로 | 역할 | 응답 | 실패 시 |
|------|------|------|---------|
| ① Engine HTTP POST `/api/session/:id/event` | **Primary** — 게임 로직 검증, state snapshot 반환 | `200 { sessionId, street, seats[], community[], pot, actionOn, dealerSeat, legalActions[], ...}` (전체 스키마: `Harness_REST_API.md §2.1`) | StubEngine fallback (`../Overlay/Engine_Dependency_Contract.md §4`), CC UI 상태 롤백 표시 |
| ② BO WebSocket `WriteAction` | **Secondary** — 이벤트 기록/감사, Lobby 브로드캐스트 | `ActionAck { hand_id, action_index }` | warn-only (debug log WARN). 게임 진행은 Engine 응답으로 계속 |

#### Timeline (결정론적)

```
t0  CC: 운영자 버튼 클릭 (예: FOLD)
t0  CC: Engine POST + BO WS send **병렬 dispatch** (동시)
t1  Engine: game logic 검증 → full state snapshot 반환 (seats/pot/street/actionOn/...)
t1' BO: ack + Lobby 브로드캐스트
t2  CC: Engine 응답 수신 → seats/pot/action_on provider 업데이트 (SSOT)
t2' CC: BO ack 수신 → audit log 확인만 (action_on 은 Engine 응답 기준, BO ack 무시)
```

- `t2` 와 `t2'` 는 독립, CC 는 Engine 응답만 대기. BO 응답은 background
- **게임 상태 SSOT**: Engine 응답 (full state snapshot — `Harness_REST_API.md §2.1` 참조)
- BO ack 의 `next_action_seat` 는 정보 중복 — CC 는 Engine 응답에서 derive (※ `WebSocket_Events.md §10.5` 재정의 필요 — notify: team2)

#### Payload 동형성 규칙 (critic 반박 3 반영)

두 경로가 **같은 물리적 사건 (운영자 1 클릭)** 을 전달해야 하므로:

| 필드 | Engine `POST /event` | BO `WriteAction` | 규칙 |
|------|---------------------|-----------------|------|
| action type | `eventType: "fold"` | `action_type: "fold"` | 동일 값 |
| seat | `payload.seatIndex` | `payload.seat` | 동일 seatNo |
| amount | `payload.amount` | `payload.amount` | 동일 (bet/raise/allin 시) |
| timestamp | HTTP request time | WS `timestamp` | 동일 `DateTime.now().toUtc()` |
| correlation_id | `X-Request-Id` header | `message_id` | 같은 UUID (CC 측 1 회 생성) |

> **구현**: CC 는 `correlation_id` 를 먼저 생성 후 두 경로에 동일 값 주입. 기록 후 Engine state snapshot 과 BO 의 `ActionPerformed` 브로드캐스트가 같은 `correlation_id` 로 매칭 가능 (추후 audit 용).

#### 실패 처리 (critic 반박 5 반영)

| 상황 | CC 행동 |
|------|---------|
| Engine 200 + BO 200 | 정상 — Engine 응답으로 state 업데이트 |
| Engine 200 + BO 실패 (timeout/5xx) | UI 정상 진행, debug log WARN. BO 는 replay API 로 보완 (`WebSocket_Events §6.5`) |
| Engine 4xx (`ActionRejected`) | UI 롤백 + SnackBar 경고 "액션 규칙 위반". BO 에 `ActionRejected` 동기화는 CC 책임 |
| Engine 5xx / timeout | StubEngine fallback (Overlay Rive 만 유지), BO 계속 기록 — prod 에서는 운영자 재시도 권고 |
| Engine + BO 모두 실패 | Demo mode UI 유지, offline indicator 표시 (Engine_Dependency §3 Offline stage) |

- **atomicity 없음**: Engine 과 BO 는 **eventual consistency**. BO 는 결국 replay 로 정합성 복구
- Engine 이 primary 이므로 Engine 실패 = 액션 실패. BO 실패는 degraded operation

#### Multi-CC 독립성 (critic 반박 4)

- CC = Table = Overlay 1:1:1 (§1 이하)
- 각 테이블 → Engine 에 독립 세션 생성 (`POST /api/session` 반환 `sessionId` 보관)
- Engine 은 `Map<sessionId, GameState>` 내부 관리 (`Harness_REST_API.md §2.2`)
- 테이블 간 독립 — 한 테이블 Engine 장애가 다른 테이블에 전이하지 않음

#### Harness dev-only vs prod (critic 반박 2)

- `Harness_REST_API.md §개요`: "개발·통합 테스트 전용. 프로덕션 배포 시 인증/인가 레이어 래핑 필요 (현재 미구현)"
- 프로토타입 범위: Harness = Engine 인터페이스 단일화. prod 인증 레이어는 Phase 2 확장
- 기획에 "prod 배포 시 Engine HTTP 를 BO reverse-proxy 경유" 옵션 유지 — 현 아키텍처 (CC→Engine 직접) 는 그대로 유지되고, 인증 레이어만 추가

#### Action-to-Transport Matrix (2026-04-22 신설)

> **배경**: §1.1.1 "병행 dispatch" 원칙만으로는 action 별 세부 규칙이 모호. 특히 DEAL 은 `Harness_REST_API §2.1 POST /api/session` 의 "auto HandStart + 홀카드 배분" 덕분에 Engine 별도 호출 불필요. 이런 예외 케이스를 표로 명시하여 구현자 혼선 방지.

| UI Action | Engine HTTP 경로 | BO WebSocket 경로 | 비고 |
|-----------|:----------------|:------------------|------|
| **NEW HAND** | `POST /api/session` (createSession — auto HandStart + holecards 포함) | `WriteGameInfo` (§9) | 병행 필수. body 동형 규칙 하단 참조 |
| **DEAL** | **호출 skip** (createSession 시점에 이미 PRE_FLOP) | `WriteDeal` (§11) — audit only | Engine 응답의 `seats[i].holeCards` 에서 이미 수신. DEAL 버튼은 CC UI 공개 타이밍 마킹 |
| **FOLD / CHECK / CALL / BET / RAISE / ALL-IN** | `POST /api/session/:id/event` (eventType 매핑) | `WriteAction` (§10) | 병행 필수 |
| **UNDO** | `POST /api/session/:id/undo` | `UndoAction` (확인 필요) | 병행. Engine 응답 기반 state 복원 |
| **MISS DEAL** | Harness endpoint 미정 (Phase 2 확장) | `MissDeal` | BO 만 audit 발행. Engine 은 세션 종료 또는 별도 endpoint 추후 추가 |
| **NEW HAND Re-deal (재딜)** | 신규 `createSession` 재호출 (기존 세션 delete 후) | `WriteGameInfo` 재발행 | 세션 분리 (hand_id 신규) |

#### Body Derivation Rule (critic 반박 3 반영)

CC 는 **single source** (운영자 입력 + 현재 seats/config provider) 로 두 경로 body 를 생성:

| 필드 | Engine `/api/session` | BO `WriteGameInfo` | derivation |
|------|----------------------|--------------------|-----------|
| variant / game_type | `variant: "nlh"` | `game_type: "HOLDEM"` | config 에서 매핑 (1:1 enum table) |
| seatCount | `seatCount: 6` | (암묵: active_seats.length) | seats.where(isOccupied).length |
| stacks | `stacks: [1000, 1000, ...]` | (암묵: players) | seats.player.stack 배열 |
| blinds | `blinds: {sb, bb}` | `sb_amount`, `bb_amount` | config.smallBlind, config.bigBlind |
| dealerSeat | `dealerSeat: N` | `dealer_seat: N` | dealerSeatProvider (§2.3.1) |
| ante / straddle | `config.anteType/straddleEnabled` | `ante_amount`, `straddle_seats` | config 에서 직접 |
| correlation_id | `X-Request-Id` header | `message_id` field | `Uuid().v4()` CC 측 1회 생성 |

**원칙**: Engine body 는 **최소 변경** (variant + initial state), BO body 는 **전체 메타데이터** (24 필드, audit용). CC 의 builder 함수가 동일 source 로부터 두 body 를 생성하여 drift 방지.

#### 구현 체크리스트 (B-team4-006 후속)

- [ ] NEW HAND: `engineClient.createSession(variant, seatCount, stacks, blinds, dealerSeat)` 호출 → `engineSessionProvider` 설정
- [ ] 모든 action (FOLD/CHECK/CALL/BET/RAISE/ALL-IN): `engineClient.send*(sessionId, seatIndex, amount?)` + `ws.sendAction(...)` 병행
- [ ] DEAL: `engineClient.sendDealHole(sessionId)` (Engine 이 auto 배분) + `cardInputProvider.requestManualForSlot()` (Mock 모드 fallback)
- [ ] Engine 응답 (full state snapshot) 을 `dispatchState(state)` 로 `seatsProvider` / `potProvider` / `handFsmProvider` 업데이트 dispatcher 구현 (`engine_output_dispatcher.dart`, 2026-04-22 구현 완료)
- [ ] 모든 경로에 debug log (dispatch 시점, 응답 시점, 실패 시점) 추가
- [ ] `correlation_id` UUID 생성 + Engine/BO 동형 주입

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

### 2.0 실행 경로 (2026-04-21)

- **Linked** (프로덕션): Lobby `[Launch]` → `--table_id --token --cc_instance_id --ws_url` args 전달. §2.1~§2.3, §7 참조.
- **Dev 테스트**: `flutter run -d windows` — args 없이 실행 가능. Engine 미연결 시 StubEngine fallback (`../Overlay/Engine_Dependency_Contract.md §4`). 프로토타입 범위, 별도 기획 문서 없음.
- Demo Scenario (사전 시나리오 자동 재생) 는 2026-04-21 결정으로 scope 제외. 구 `Demo_Test_Mode.md` 는 DEPRECATED.

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

### 3.0 v4.0 정체성 (2026-05-07 신설, SSOT)

> **트리거**: `docs/1. Product/Command_Center_PRD.md` v4.0 cascade. 본 §3.0 가 §3.1~§3.4 v1.x 기술을 *override* 한다. 구 v1.x 타원형 테이블 + 8 버튼 액션 패널 기술은 archive 보존 (다음 메이저 정리에서 제거 예정).

#### 3.0.1 4 영역 위계 (StatusBar / TopStrip / PlayerGrid / ActionPanel)

화면을 위에서 아래로 4 영역. 영역 간 *변화 빈도* 와 *시선 빈도* 가 다르며, 운영자는 본방송 12 시간 동안 이 위계를 *근육 기억* 으로 흡수한다.

```
+-----------------------------------------------+
|  StatusBar  (52px, 거의 고정)                  |
|  - BO/RFID/Engine 연결 dot                     |
|  - Hand # / Phase / Blinds / Lvl               |
+-----------------------------------------------+
|  TopStrip   (158px, 액션마다)                  |
|  - 좌: MiniDiagram + POT 박스                  |
|  - 중: Community Board (FLOP/TURN/RIVER)       |
|  - 우: ACTING / SHOWDOWN / HAND OVER 박스      |
|  - 하단 32px: KeyboardHintBar (6 키 칩)        |
+-----------------------------------------------+
|  PlayerGrid (가변 1fr, 1×10 가로)              |
|  ★ 핵심 변경: 타원형 테이블 폐기                |
|  - 선수 10명을 가로 한 줄에 정렬                |
|  - 각 셀 = 9 행 stacked (Acting/S#/Pos/...)    |
+-----------------------------------------------+
|  ActionPanel (124px, 운영자 입력)              |
|  - 6 키 (N · F · C · B · A · M)                |
|  - Phase-aware (같은 키, phase별 다른 의미)     |
+-----------------------------------------------+
```

| 영역 | 높이 | 변화 빈도 | 시선 빈도 |
|------|:----:|:--------:|:--------:|
| StatusBar | 52px | 수 분 | 5 초마다 곁눈 |
| TopStrip | 158px | 수 초 | 매 액션 후 |
| PlayerGrid | 가변 1fr | 수 초 | 핸드 진행 중 지속 |
| ActionPanel | 124px | 수 초 | 매 액션 발사 직전 |

#### 3.0.2 1×10 가로 그리드 (타원형 테이블 폐기)

이전 EBS PRD (v1.x) 는 화면 중앙에 **타원형 테이블** 을 그리고 10 좌석을 그 둘레에 배치했다. v4.0 은 이 구조를 폐기하고 **1×10 가로 그리드** 로 전환했다.

```
v1.x (deprecated) — 타원형 테이블          v4.0 (current) — 1×10 가로 그리드
─────────────────────────────             ─────────────────────────────────────────
       [S4][S5][S6][S7]                   [S1][S2][S3][S4][S5][S6][S7][S8][S9][S10]
   [S3]              [S8]                  ↑ 한 줄에 10 셀 가로 정렬
   [S2]   [Board]    [S9]                  ↑ 각 셀 = 9 행 stacked (정보 밀도 ↑)
       [S1]      [S10]                    ↑ 공간 관계는 TopStrip MiniDiagram 으로 회복
            [D]
```

**전환 근거 (장점)**:
- 좌석 비교 용이 (가로 정렬로 스택 차이 한눈)
- 정보 밀도 ↑ (9 행 stacked)
- 인지 모드 단순화 (*공간 위치* → *순차 번호* S1~S10)

**전환 한계 (honest, PRD §1.2 단점)**:
- 실 카지노 oval 테이블과 시각 mismatch
- 공간 인지 왜곡 (실제 정면 마주보는 좌석이 grid 에서는 인접 셀)
- MiniDiagram 의존도 ↑ (TopStrip 좌측 미니 oval 로 회복)
- 운영자 재훈련 필요 (수 일 ~ 수 주)

#### 3.0.3 6 키 의미 카탈로그 (N · F · C · B · A · M)

ActionPanel 의 8 분리 버튼 (v1.x) 시대가 끝나고 **6 키 (5 게임 + 1 비상)** 의 시대가 시작된다. 같은 키, phase 에 따라 의미가 자동 전환 (Phase-aware).

| 키 | 명칭 | IDLE | PRE_FLOP / FLOP / TURN / RIVER | SHOWDOWN / HAND_COMPLETE | 분류 |
|:--:|------|:----:|:------------------------------:|:------------------------:|:----:|
| **N** | Next / Finish | START HAND | (disabled) | FINISH HAND | lifecycle |
| **F** | Fold | (disabled) | FOLD | (disabled) | 게임 액션 |
| **C** | Call / Check | (disabled) | CHECK *or* CALL (auto-switch) | (disabled) | 게임 액션 |
| **B** | Bet / Raise | (disabled) | BET *or* RAISE (auto-switch) | (disabled) | 게임 액션 |
| **A** | All-in | (disabled) | ALL-IN | (disabled) | 게임 액션 |
| **M** | Menu / Manual (Miss Deal) | (disabled) | Miss Deal | (disabled) | 비상 |

**자동 전환 룰 (C/B 키)**:
- `biggestBet == playerBet` → **CHECK** (콜할 게 없음)
- `biggestBet > playerBet` → **CALL** (맞춰야 함)
- `biggestBet == 0` → **BET** (첫 베팅)
- `biggestBet > 0` → **RAISE** (이미 베팅 있음)

> ★ **6 키의 가치**: *같은 키 = 같은 손가락 위치 = 다른 의미*. 손가락은 알파벳을 외우지 않고 *위치* 를 외운다. UNDO 만 별도 (Ctrl+Z).

#### 3.0.4 5-Act 시퀀스 카탈로그

12 시간 본방송 한 회 동안 한 핸드의 흐름은 **5 Act** 로 추상화된다. HandFSM 9-state 의 의미 묶음.

| Act | 단계 | 9-state 매핑 | CC 화면 변화 | 6 키 활성 |
|:---:|------|--------------|--------------|-----------|
| **Act 1** | IDLE | IDLE | StatusBar PHASE = "IDLE", PlayerGrid 정적 | N (START HAND) |
| **Act 2** | PreFlop | SETUP_HAND → PRE_FLOP | 블라인드 수거 → 홀카드 분배 → action_on 펄스 | F · C · B · A · M |
| **Act 3** | Flop / Turn / River | FLOP → TURN → RIVER | Community Board 슬롯 채움, 폴드 반투명 | F · C · B · A · M |
| **Act 4** | Showdown | SHOWDOWN | 승자 강조, 핸드 공개, ACTING 박스 = "SHOWDOWN" | (disabled, viewing) |
| **Act 5** | Settlement | HAND_COMPLETE | 팟 분배 애니메이션, 스택 갱신, ACTING = "HAND OVER" | N (FINISH HAND) |

> 참조: PRD §Ch.6 (HandFSM), `Hand_Lifecycle.md` (5-Act ↔ 9-state 정합).

#### 3.0.5 v4.0 정체성 → 자매 문서 cascade 매트릭스

| 자매 문서 | v4.0 cascade |
|----------|--------------|
| `Action_Buttons.md` | 6 키 (N·F·C·B·A·M) 동적 매핑 |
| `Hand_Lifecycle.md` | 5-Act 시퀀스 (Act 1~5) |
| `Multi_Table_Operations.md` | 1×10 그리드 multi-table 적용 |
| `Seat_Management.md` | 1×10 가로 그리드 좌석 관리 |
| `Keyboard_Shortcuts.md` | 6 키 단축키 표준 |
| `Manual_Card_Input.md` | M 키 (Manual) 진입 |
| `RFID_Cards/*` | Reader Panel 정체성 |
| `Overlay/Sequences.md` | 5-Act → Overlay 시퀀스 매핑 |

---

### 3.1 [archive — v1.x] 레이아웃 3영역

> ⚠️ **Archive (v1.x)**: 본 §3.1 ~ §3.4 는 v1.x 타원형 테이블 + 8 버튼 기술이며 v4.0 정체성 (§3.0) 으로 *override* 됨. 다음 메이저 정리에서 제거 예정. 인용 금지.

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

### 3.3 [archive — v1.x] 테이블 영역

> ⚠️ **Archive**: v4.0 에서 타원형 테이블 폐기 → §3.0.2 (1×10 가로 그리드) 참조.

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

### 3.4 [archive — v1.x] 액션 패널 (8버튼)

> ⚠️ **Archive**: v4.0 에서 8 분리 버튼 → 6 키 (N·F·C·B·A·M) 동적 매핑으로 통합. §3.0.3 참조.

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
| **카드 비노출 (D7, 2026-04-22)** | 운영자(딜러)는 hole cards 의 **값** 을 절대 보지 못한다. 분배 여부만 face-down (`?`) 표시 |

### 5.1 D7 — 카드 비노출 계약 (2026-04-22 회의 결정)

운영자(딜러)가 CC 화면을 통해 hole cards 의 값(rank/suit)을 미리 알면 부정 행위 위험이 발생한다. 따라서 **CC widget 트리는 hole cards 값을 절대 렌더링하지 않는다**.

#### 5.1.1 비노출 / 노출 매트릭스

| 정보 | CC | Overlay | 근거 |
|------|:--:|:-------:|------|
| **hole cards 값 (rank/suit)** | ❌ 비노출 | ✅ 노출 (Rive 송출) | D7 — 운영자 부정 방지 |
| hole cards **분배 여부** (count) | ✅ face-down `?` 표시 | ✅ 정상 | 운영자가 분배 진행 인지 필요 |
| community cards (flop/turn/river) | ✅ 노출 | ✅ 노출 | 공개 정보 |
| pot / stacks / bets | ✅ 노출 | ✅ 노출 | 공개 정보 |
| 좌석 / position / status | ✅ 노출 | ✅ 노출 | 공개 정보 |

#### 5.1.2 데이터 흐름 (data layer 는 보존)

```
Engine 응답 (hole cards 포함)
   │
   ├──> CC seat_provider.holeCards (state 보관 — Overlay 송출용)
   │      │
   │      └──> CC widget 렌더링: face-down `?` 만 표시 (값 불노출)
   │
   └──> Overlay seat_provider (별도) → Rive 송출 (시청자 화면)
```

CC widget 은 `seat.holeCards.length` (count) 만 사용. `seat.holeCards[i].rank` / `.suit` 직접 접근 **금지**.

#### 5.1.3 정적 가드 (CI)

`tools/check_cc_no_holecard.py` 가 CC widget 디렉토리(`team4-cc/src/lib/features/command_center/widgets/`)를 스캔하여 hole card 값 노출 패턴을 검출한다. 위반 시 exit 1.

검출 규칙:
- `_buildHoleCards(...)` / `_buildMiniCard(...)` 함수 호출
- `card.rank` / `card.suit` 직접 접근
- `holeCards[i].rank` / `holeCards[i].suit` 배열 요소 접근

허용:
- `seat.holeCards.isEmpty` / `.isNotEmpty` / `.length` (count check)
- `_buildHoleCardBack(count)` (face-down 표시 helper)

#### 5.1.4 디버그 모드 예외 없음

D7 의 의도는 운영자 부정 방지이므로, **디버그/개발 모드에서도 노출 금지**. 조건 분기 없이 위 규칙 적용.

#### 5.1.5 위반 사례 (2026-04-26 IMPL-007 적용 전)

`seat_cell.dart` line 500-501 (적용 전):
```dart
// Row 3: Hole cards (if any)
if (seat.holeCards.isNotEmpty) _buildHoleCards(seat.holeCards),
```
→ `_buildHoleCards` / `_buildMiniCard` 가 rank/suit 를 그대로 화면에 렌더링했다. IMPL-007 에서 face-down 표시로 교체.

> 참조: `docs/4. Operations/Conductor_Backlog/IMPL-007-cc-no-card-display-contract.md`

### 수동 편집 우선 원칙

운영자가 수동으로 수정한 값은 DB/WebSocket 에서 들어오는 값보다 우선한다. 각 좌석 위젯 우상단의 동기화 아이콘이 현재 상태를 표현한다.

#### 동기화 아이콘 3 상태

| 상태 | 아이콘 | 의미 | 배경 |
|------|:-----:|------|------|
| `AUTO_SYNC` | 🔄 (회색) | 서버 값과 일치. 다음 서버 push 가 자동 반영됨. 운영자 수정 없음 | 투명 |
| `MANUAL_OVERRIDE` | ✋ (주황) | 운영자가 수정한 이후 서버에서 다른 값이 온 적 없음. 현재 화면은 수동 값 SSOT | 주황 반투명 (`#F57C00 alpha 30%`) |
| `CONFLICT` | ⚠️ (빨강) | 수동 편집 이후 서버에서 다른 값이 도착 → 두 값 불일치. 운영자 결정 대기 | 빨강 반투명 (`#E53935 alpha 30%`) |

#### 상태 전이

```
AUTO_SYNC ──[운영자 인라인 편집 저장]──> MANUAL_OVERRIDE
MANUAL_OVERRIDE ──[서버 push 도착 & 값 동일]──> AUTO_SYNC  (무시, 이미 일치)
MANUAL_OVERRIDE ──[서버 push 도착 & 값 다름]──> CONFLICT
CONFLICT ──[운영자가 아이콘 tap → "서버 값으로 갱신" 선택]──> AUTO_SYNC
CONFLICT ──[운영자가 아이콘 tap → "수동 값 유지" 선택]──> MANUAL_OVERRIDE (새 서버 값 버림)
MANUAL_OVERRIDE | CONFLICT ──[HandCompleted 이벤트]──> AUTO_SYNC (자동 리셋)
```

#### Tap 동작 (상태별)

- `AUTO_SYNC`: 무동작 (아이콘은 단순 표시).
- `MANUAL_OVERRIDE`: 선택지 2개 — `서버 값으로 강제 갱신` / `유지 (닫기)`.
- `CONFLICT`: 선택지 2개 — `서버 값으로 갱신` / `수동 값 유지`. 다이얼로그에 두 값을 나란히 표시 (before/after).

#### 필드 범위

인라인 편집이 가능한 좌석 필드(플레이어 이름, stack, 국기, sitting_out 등) 각각에 개별 적용. 핸드 전체가 아닌 **필드 단위** 상태.

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
| AT-06 | Table Settings (Rules 탭) | 600×auto (모달) | M-01 Toolbar `[⚙]` 버튼 → Table Settings → Rules 탭 | `Settings.md §Rules`, `BS-05-08` |
| AT-07 | Player Edit | 모달 | 좌석 요소 탭(인라인 편집) 또는 롱프레스 컨텍스트 메뉴 | `BS-05-09-player-edit-modal.md` |

### 6.2 AT-01 Main의 7 Zone 구조

| Zone | 이름 | 기능 |
|:----:|------|------|
| M-01 | Toolbar | NEW HAND, HIDE GFX 토글, `[⚙]` Table Settings, Menu |
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

---

## 11. 카드 호출 로직 (cross-ref)

CC 가 dispatch 하는 카드 입력 (RFID 홀카드 / 커뮤니티 카드) 의 4-tier 문서 구조와 권위 SSOT 매핑은 `../../2.5 Shared/Card_Flow_Index.md` 참조. 카드 파이프라인의 Trigger/OutputEvent 권위는 `../../2.3 Game Engine/Behavioral_Specs/Triggers_and_Event_Pipeline.md` (§1.4 카드 파이프라인 / §3.5 트리거 매트릭스 / §4.10 Atomic Flop 예외).

---

## 12. Widget Inventory — Visual Uplift (B-team4-011, 2026-05-06)

> **트리거**: 2026-05-05 디자이너 React 시안 critic 판정. SSOT: `docs/4. Operations/CC_Design_Prototype_Critic_2026_05_06.md`.

### 12.1 13개 위젯 인벤토리 (V1 ~ V13, 2026-05-06 시각 검토 후 확장)

| ID | 위젯 | 위치 | 상세 정책 SSOT | 상태 |
|:--:|------|------|----------------|:----:|
| **V1** | KeyboardHintBar | InfoBar 직하 32px | `Keyboard_Shortcuts.md §5` | ✅ 2026-05-06 |
| **V2** | cc_status_bar (BO/RFID/Engine 통합) + V10 | Toolbar 대체 또는 보강 | `UI.md §Visual Uplift V2` | ⏳ |
| **V3** | mini_table_diagram + R2 가드 | Toolbar 좌측 또는 InfoBar | `UI.md §Visual Uplift V3` | ⏳ |
| **V4** | position_shift_chip | SeatCell 행 3 | `Seat_Management.md §8.3` | ⏳ |
| **V5** | SeatCell 7행 + V11/V12 결합 | SeatCell 전체 | `Seat_Management.md §8.1` | ⏳ |
| **V6** | ACTING glow ring + V9 명시 박스 | SeatCell + 우측 명시 박스 | `UI.md §Visual Uplift V6` | ⏳ |
| **V7** | tweaks_panel (debug only) | Settings popup 또는 fab | `UI.md §Visual Uplift V7` | ⏳ |
| **V8** | FLOP 1·2·3 / TURN / RIVER 슬롯 라벨 | community board | (이 §) | ⏳ NEW |
| **V9** | ACTING 우측 명시 박스 | V6 일부 | V6 SSOT | ⏳ NEW |
| **V10** | POT 좌상단 강조 박스 | V2/V3 영역 | V2/V3 SSOT | ⏳ NEW |
| **V11** | 베팅 칩 부유 시각 | V5 일부 | V5 SSOT | ⏳ NEW |
| **V12** | 카드 슬롯 + ADD affordance | V5 일부 | V5 SSOT | ⏳ NEW |
| **V13** | IDLE 시 액션 disabled visual hint | ActionPanel | 현 Flutter 정합 | ✅ 확인 |

### 12.2 가드레일 (HARD ENFORCE)

| # | 가드 | 검증 |
|:-:|------|------|
| 1 | hole card 값 노출 금지 (D7) | `tools/check_cc_no_holecard.py` CI |
| 2 | CDN 의존 도입 금지 | `pubspec.yaml` 리뷰 |
| 3 | 통신 모델 변경 금지 (Engine HTTP + BO WS 병행 dispatch 보존) | `engine_output_dispatcher.dart` diff = 0 |
| 4 | HandFSM 9-state 전이 룰 변경 금지 | `hand_fsm_provider.dart` 테스트 |

### 12.3 진행 단계 (Phase A ~ G)

| Phase | 작업 | 상태 |
|:-----:|------|:----:|
| A | archive + Backlog 등재 + critic SSOT | ✅ |
| B | V1 KeyboardHintBar | ✅ |
| C | V2 cc_status_bar | ⏳ |
| D | V3 mini_table_diagram + V4 position_shift_chip | ⏳ |
| E | V5 SeatCell 7행 (executor 위임 권장 — 250줄 변경) | ⏳ |
| F | V6 glow + V7 tweaks_panel | ⏳ |
| G | screenshot diff + critic verify | ⏳ |

### 12.4 거절된 시안 항목 (12 결함)

| # | 시안 결함 | EBS CC 정책 |
|:-:|----------|-------------|
| 1 | 운영자 화면 카드 값 노출 (D7 위반) | **face-down only** (§Hole_Cards / Foundation §5.4) |
| 2 | React/Babel/Inter CDN 의존 | Flutter assets 자족 (Docker 컨테이너) |
| 3 | WebSocket / Engine 통신 부재 | **§1.1.1 Engine + BO 병행 dispatch 유지** |
| 4 | HandFSM 단순 phase string | **9-state Riverpod FSM 유지** (`hand_fsm_provider.dart`) |
| 5 ~ 12 | RFID HAL / RBAC / UndoStack / i18n / 테스트 / AT-04~07 / 9 게임 / Babel runtime | 모두 **거절** (현 Flutter CC 패턴 보존) |

상세: `docs/4. Operations/CC_Design_Prototype_Critic_2026_05_06.md` Act 2 (Incident).
