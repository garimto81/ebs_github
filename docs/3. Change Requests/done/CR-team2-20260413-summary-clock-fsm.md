---
title: CR-team2-20260413-summary-clock-fsm
owner: conductor
tier: internal
last-updated: 2026-04-15
---

# CCR-DRAFT: API-05에 EventFlightSummary 이벤트 + Clock FSM 행동 명세 신설

- **제안팀**: team2
- **제안일**: 2026-04-13
- **영향팀**: [team1, team3, team4]
- **변경 대상 파일**: contracts/api/API-05-websocket-events.md, contracts/specs/ (BS-06 확장 또는 신규 BS-06-02-clock.md)
- **변경 유형**: add
- **변경 근거**: WSOP LIVE Confluence `Staff App Live` page에서 `EventFlightSummary`(25+ 필드 실시간 모델)와 `Clock`(13필드 + BlindDetailType enum)이 WebSocket Subscribe로 전달되는데, EBS API-05에는 해당 이벤트가 전혀 없어 Lobby 대시보드와 블라인드 타이머 UI 구현 불가. WSOP `Staff App Live` page를 정본으로 참조.

## 변경 요약

### Part 1: API-05 신규 이벤트 3종

1. **`event_flight_summary`** (`lobby_monitor` 채널): 30초 주기 또는 핸드 종료/탈락 시 Lobby 대시보드로 브로드캐스트.

```json
{
  "type": "event_flight_summary",
  "table_id": "*",
  "seq": 99001,
  "server_time": "2026-04-13T14:30:00Z",
  "payload": {
    "event_flight_id": 123,
    "event_id": 45,
    "display_name": "Day 1A",
    "status": "live",
    "entries": 1200,
    "reentries": 340,
    "players_left": 890,
    "table_count": 100,
    "empty_seat_count": 12,
    "avg_stack": 45000,
    "median_stack": 38000,
    "largest_stack": 185000,
    "smallest_stack": 8200,
    "total_chips_in_play": 40050000,
    "play_level": 8,
    "current_blind": { "sb": 400, "bb": 800, "ante": 100 },
    "next_blind": { "sb": 500, "bb": 1000, "ante": 100 },
    "level_time_remaining_sec": 720,
    "is_on_break": false,
    "break_time_remaining_sec": null,
    "tables_breaking": 3,
    "players_moving": 12,
    "prizepool": null,
    "itm_threshold": null,
    "updated_at": "2026-04-13T14:30:00Z"
  }
}
```

2. **`clock_tick`** (`cc_event` 채널): 매 1초 Clock 상태 브로드캐스트.

```json
{
  "type": "clock_tick",
  "table_id": "*",
  "seq": 99002,
  "payload": {
    "event_flight_id": 123,
    "status": "running",
    "level": 8,
    "blind_detail_type": 0,
    "time_remaining_sec": 719,
    "blind_info": { "sb": 400, "bb": 800, "ante": 100 },
    "is_paused": false,
    "pause_reason": null
  }
}
```

3. **`clock_level_changed`** (`cc_event` 채널): 레벨 전환 시 1회.

```json
{
  "type": "clock_level_changed",
  "table_id": "*",
  "seq": 99003,
  "payload": {
    "event_flight_id": 123,
    "old_level": 7,
    "new_level": 8,
    "blind_detail_type": 0,
    "new_blind": { "sb": 400, "bb": 800, "ante": 100 },
    "is_break": false,
    "next_break_at_level": 10
  }
}
```

### Part 2: Clock FSM 행동 명세 (specs/)

신규 파일 `contracts/specs/BS-06-02-clock.md` 또는 BS-06-00 확장.

**Clock 상태 (FSM)**:

| 상태 | 설명 | 진입 조건 |
|------|------|----------|
| STOPPED | 토너먼트 시작 전 / 종료 후 | 초기 상태, CompleteTournament |
| RUNNING | 블라인드 타이머 진행 중 | StartClock, ResumeClock, Break End |
| PAUSED | 수동 일시정지 | PauseClock (수동) |
| BREAK | 자동 휴식 | breakPerLevel 도달 |
| DINNER_BREAK | 식사 휴식 | DinnerBreakTime 도달 |

**BlindDetailType enum**:

| 값 | 이름 | 설명 |
|:--:|------|------|
| 0 | Blind | 일반 레벨 |
| 1 | Break | 자동 휴식 |
| 2 | DinnerBreak | 식사 휴식 |
| 3 | ColorUp | 칩 교환 (Phase 2+) |
| 4 | EndOfDay | 데이 종료 |

**Pause 우선순위**: ManualPause > DinnerBreak > Break > AutoPause

## 영향 분석

- Team 1 (Lobby): 대시보드 실시간 summary 화면 + 블라인드 타이머 UI 신규 구현 필요. 가장 큰 영향.
- Team 3 (Engine): Clock 이벤트와 Game Engine은 독립. 영향 최소 (clock_tick은 정보 전달만).
- Team 4 (CC): Clock UI 위젯 필요 (블라인드/타이머 표시, Pause/Resume 버튼).
- 마이그레이션: 없음 (신규 이벤트 추가, 기존 이벤트 미변경).

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 1 기술 검토 (대시보드 UI)
- [ ] Team 3 기술 검토 (영향 없음 확인)
- [ ] Team 4 기술 검토 (Clock UI)
