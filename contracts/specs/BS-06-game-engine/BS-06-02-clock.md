# BS-06-02 Tournament Clock FSM — 블라인드 타이머 행동 명세

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-13 | 신규 작성 | Clock 상태 머신, BlindDetailType enum, Pause 우선순위. WSOP LIVE Staff App Live 준거 |

---

## 개요

Tournament Clock은 블라인드 레벨 진행, Break/DinnerBreak, Pause를 관리하는 상태 머신이다. Lobby 대시보드와 CC Clock UI가 이 명세를 기반으로 실시간 타이머를 표시한다.

> **WebSocket 이벤트**: API-05 §4.2.2 `clock_tick`, §4.2.3 `clock_level_changed` 참조.
> **WSOP LIVE 참조**: Staff App Live §Clock 모델 (level, duration, startTime, pauseStartTime, pauseMessage 등 13필드)

---

## 1. Clock FSM 상태

| 상태 | 설명 | 진입 조건 | 퇴장 조건 |
|------|------|----------|----------|
| **STOPPED** | 토너먼트 시작 전 / 종료 후 | 초기 상태, CompleteTournament | StartClock |
| **RUNNING** | 블라인드 타이머 카운트다운 중 | StartClock, ResumeClock, Break End | 레벨 종료(→다음 레벨 또는 Break), PauseClock |
| **PAUSED** | 수동 일시정지 | PauseClock (TD 수동 조작) | ResumeClock |
| **BREAK** | 자동 휴식 | `breakPerLevel` 레벨 도달 시 자동 | Break 시간 종료 → RUNNING (다음 레벨) |
| **DINNER_BREAK** | 식사 휴식 | `DinnerBreakTime` 도달 시 자동 | DinnerBreak 시간 종료 → RUNNING |

### 1.1 상태 전이 다이어그램

```
STOPPED ──StartClock──→ RUNNING
                         │  ↑
            PauseClock ──┘  │── ResumeClock
                         │
                     PAUSED
                         
RUNNING ──breakPerLevel──→ BREAK ──breakEnd──→ RUNNING
RUNNING ──dinnerTime────→ DINNER_BREAK ──end──→ RUNNING
RUNNING ──complete──────→ STOPPED
```

### 1.2 Pause 우선순위

동시에 여러 상태 전이가 요청될 수 있다. 우선순위:

1. **ManualPause** (최고) — TD가 수동으로 일시정지. 어떤 상태에서든 즉시 PAUSED.
2. **DinnerBreak** — 식사 시간 도달. RUNNING 중이면 전환. PAUSED 중이면 Resume 후 전환.
3. **Break** — 자동 휴식. RUNNING 중이면 전환. PAUSED/DINNER_BREAK 중이면 대기.
4. **AutoPause** (최저) — 시스템 자동 정지 (예: 최종 테이블 대기).

> WSOP LIVE 운영 규칙: "BreakTime인 상태에서 Pause 시 Pause가 우선순위 높음" (Staff App Live §Clock)

---

## 2. BlindDetailType enum

Clock tick/level changed 이벤트에서 현재 블라인드 레벨의 유형을 나타낸다.

| 값 | 이름 | 설명 |
|:--:|------|------|
| 0 | **Blind** | 일반 블라인드 레벨 |
| 1 | **Break** | 자동 휴식 |
| 2 | **DinnerBreak** | 식사 휴식 |
| 3 | **ColorUp** | 칩 교환 (Phase 2+) |
| 4 | **EndOfDay** | 데이 종료 |

> WSOP LIVE `BlindDetailType` enum과 값/이름 동일. EBS에서도 동일 int 값을 사용한다.

---

## 3. Clock 데이터 모델 (13 필드)

WSOP LIVE Staff App Live §Clock 준거. API-05 `clock_tick` 이벤트 payload와 1:1 매핑.

| 필드 | 타입 | 설명 |
|------|------|------|
| `event_flight_id` | int | Flight 식별자 |
| `status` | string | Clock FSM 상태 (`stopped/running/paused/break/dinner_break`) |
| `level` | int | 현재 블라인드 레벨 (1부터) |
| `level_index` | int | 블라인드 구조 배열 내 인덱스 (Break 포함) |
| `blind_detail_type` | int | BlindDetailType enum (0~4) |
| `duration_sec` | int | 현재 레벨/브레이크의 전체 시간(초) |
| `time_remaining_sec` | int | 잔여 시간(초). 클라이언트 카운트다운용 |
| `start_time` | string (ISO 8601) | 현재 레벨 시작 시각 |
| `is_paused` | bool | 수동 일시정지 여부 |
| `pause_start_time` | string? | 일시정지 시작 시각 (null이면 미정지) |
| `pause_reason` | string? | 일시정지 사유 |
| `pause_duration_sec` | int | 누적 일시정지 시간(초) |
| `auto_advance` | bool | 레벨 자동 전환 여부 (false면 수동 전환) |

---

## 4. 클라이언트 구현 가이드

### 4.1 Lobby (team1)

- `clock_tick` 수신 시 `time_remaining_sec` 로 로컬 카운트다운 표시
- 서버 `clock_tick` 매 1초 보정 — 클라이언트 로컬 타이머와 ±500ms 이내 유지
- `clock_level_changed` 수신 시 블라인드 정보 업데이트 + Break 전환 UI

### 4.2 CC (team4)

- Clock 위젯: 현재 레벨/블라인드/잔여 시간 상시 표시
- Pause/Resume 버튼: TD 권한일 때만 활성
- Break 진입 시 화면 배너 변경

### 4.3 발동 주기

| 이벤트 | 주기 | 소스 |
|--------|------|------|
| `clock_tick` | 매 1초 | BO가 생성, `cc_event` + `lobby_monitor` 채널 |
| `clock_level_changed` | 레벨 전환 시 1회 | BO가 생성 |
| `event_flight_summary` | 30초 주기 | BO가 생성, `lobby_monitor` 채널 |

---

## 5. WSOP LIVE 대응

| EBS 필드 | WSOP Staff App Live 필드 | 비고 |
|---------|------------------------|------|
| `status` | `isStarted` + `pauseStartTime` 조합 | WSOP는 명시적 FSM 없음, EBS가 정규화 |
| `level` | `level` | 동일 |
| `blind_detail_type` | `type` (BlindDetailType) | 동일 값 |
| `time_remaining_sec` | 클라이언트 계산 (`startTime` + `duration` - now) | WSOP는 서버가 직접 안 줌, EBS는 서버 계산 |
| `pause_reason` | `pauseMessage` | 동일 |
| `auto_advance` | 없음 (항상 자동) | EBS는 수동 전환 옵션 추가 |
