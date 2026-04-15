---
title: Clock Control
owner: team1
tier: internal
last-updated: 2026-04-15
---

# Lobby — Clock Control (블라인드 타이머·레벨·브레이크 제어)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-15 | 신규 작성 | WSOP LIVE Confluence p2334752899 (Clock Control) 의 기능을 EBS Lobby 에 반영. team1 발신, Round 2 Phase A. |

---

## 개요

Tournament Director 가 Flight 의 블라인드 타이머·레벨·브레이크를 수동 제어한다. EBS Lobby 의 Flight 화면 헤더에서 `[Clock Control]` 드롭다운으로 진입.

**근거**: [WSOP LIVE Clock Control p2334752899](https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/2334752899/Clock+Control) 의 모든 기능을 EBS 에 그대로 채택. WSOP LIVE 와 동일한 시계 동작이 검증된 산업 표준이므로 divergence 최소화.

**RBAC**: Admin (= TD) 전용. Operator 는 자기 할당 테이블의 일시정지(LIVE+is_pause) 만 가능.

---

## 1. Clock 시작 전 제어 (이벤트 시작 전)

WSOP LIVE 가 추가한 핵심 개선점: Event 가 시작하지 않았더라도 Clock Control 가능.

| 컨트롤 | 동작 |
|--------|------|
| **시작 레벨 표시** | Day 1 또는 앞선 Day 의 Flight 가 모두 종료된 시점부터 표시 |
| **시작 남은 시간 표시** | 동 위 |
| **레벨 수동 변경** | 시작 전에도 레벨 변경 가능 |
| **남은 시간 조정** | 시작 전 남은 시간 입력 |

조건: 현재 Flight 가 `Day 1` 이거나, **앞 Day 의 모든 Flight 가 Completed** 인 경우만 활성.

---

## 2. Clock 진행 중 제어

### 2.1 Blind Level 수동 제어

| 컨트롤 | 동작 | 영향 |
|--------|------|------|
| **Next Level** | 다음 레벨로 즉시 전환 | `clock_level_changed` 이벤트 발행 |
| **Previous Level** | 직전 레벨로 되돌림 | 동 위 |
| **Set to Level N** | 특정 레벨로 점프 | 동 위 |
| **Adjust Remaining Time** | 현재 레벨 남은 시간 ± 입력 | `clock_tick` 이벤트로 즉시 반영 |

### 2.2 Break / Dinner Break

| 동작 | 동작 상세 |
|------|----------|
| **Start Break** | `is_pause = true` + 브레이크 카운트다운 시작. 블라인드 타이머 정지 |
| **End Break** | `is_pause = false` + 다음 레벨 자동 진입 (또는 현재 레벨 잔여 시간 유지 옵션) |
| **Dinner Break** | 브레이크와 동일 동작, 별도 라벨 (UI 에만 표시) |
| **Pause / Resume** | `is_pause` 토글 (브레이크가 아닌 일반 정지) |

브레이크 시작 시 Overlay 에 "BREAK" 배지 표시 (skin 설정).

---

## 3. Day Close (Day 종료 처리)

Day 의 진행을 종료하는 4가지 옵션:

| 옵션 | 동작 |
|------|------|
| **Play Levels** | 추가 N 레벨 진행 후 종료 |
| **Play Rounds** | 추가 N 라운드 진행 후 종료 (라운드 = 모든 플레이어 1회 BB) |
| **Play Down To N Players** | N 명 남을 때까지 진행 후 종료 |
| **Remaining %** | 시작 인원 대비 X% 남았을 때 종료 |

종료 트리거 시:
- 새 핸드 시작 차단
- 현재 핸드 완료 후 Day End 처리
- `tournament_status_changed` 이벤트 발행 (status=Completed)

---

## 4. Clock Recreate (DB 변경 사항 적용)

Backend DB 에서 Tournament 정보를 직접 수정한 경우 (예: Blind Structure 교체, Late Reg 종료 시각 변경) Clock 엔진이 자동 인지하지 못함. **Reset 기능** 으로 강제 재로드.

| 컨트롤 | 동작 |
|--------|------|
| **Clock Recreate** | 현재 Flight 의 Blind Structure / Late Reg / Day Close 정책을 DB 에서 재로드. 진행 중 시간은 보존 |
| **Clock Reload Page** | 클라이언트 페이지 강제 새로고침 (서버는 변경 없음). `clock_reload_requested` 이벤트로 모든 구독자에게 신호 |

Recreate 는 `is_pause = true` 상태에서만 권장 (진행 중 변경은 운영 혼란).

---

## 5. UI 레이아웃

```
┌─ Flight 헤더 ─────────────────────────────────────┐
│ Day 1A  · LIVE · Level 8                         │
│ ──────────────────────────                       │
│   Blind 400/800 +100   ⏱ 00:12:34 / 00:20:00    │
│   Next: 500/1000 +100  Players left: 890/1240   │
│                                                   │
│   [⏸ Pause]  [☕ Break]  [⏭ Next Lv]            │
│   [🔄 Reload Page]   [🔧 Clock Control ▼]       │
└──────────────────────────────────────────────────┘
```

`[Clock Control ▼]` 드롭다운 메뉴: Adjust Time · Set to Level · Day Close · Clock Recreate · Late Reg Override.

---

## 6. WebSocket 이벤트

(Backend `WebSocket_Events.md §4.2` 와 정합)

| 이벤트 | 발행 시점 | 클라이언트 처리 |
|--------|----------|---------------|
| `clock_tick` | 매 1초 | 헤더 카운트다운 갱신 (throttle 500ms) |
| `clock_level_changed` | 레벨 전환·Break 시작/종료 | 헤더 레벨/블라인드 갱신 + 토스트 |
| `clock_detail_changed` | Clock detail PUT | 테마/공지/이벤트명 갱신 |
| `clock_reload_requested` | Reload Page 클릭 | 페이지 강제 새로고침 |
| `tournament_status_changed` | Day Close 등 status 전이 | 헤더 상태 배지 + 잠금 규칙 적용 |

---

## 7. UI 상태

로딩·에러·성공 피드백은 `../Engineering.md §4.7 공통 UI 상태` 를 따른다.

| 상황 | UI |
|------|-----|
| Clock Recreate 진행 중 | 헤더에 Spinner + "재로드 중..." 배너 |
| WebSocket 단절 → clock_tick 미수신 | 카운트다운 회색 처리 + "연결 끊김" 배너 |
| Day Close 진행 중 | "다음 핸드 후 종료 예정" 배너 |

---

## 8. 트리거

| 트리거 | 주체 | 결과 |
|--------|:----:|------|
| Flight 헤더 `[Clock Control]` 클릭 | Admin | 드롭다운 열림 |
| Pause / Break 버튼 | Admin | `is_pause` 토글 + WebSocket broadcast |
| Day Close 옵션 적용 | Admin | 종료 정책 저장 + 다음 핸드 후 적용 |
| 자동 레벨 전환 | 시스템 | 남은 시간 0초 도달 시 |
| Clock Recreate 클릭 | Admin | DB 재로드 + 모든 구독자에게 갱신 |

---

## 9. 경우의 수 매트릭스

| 조건 | Pause | Break | Next Level | Day Close |
|------|:----:|:-----:|:----------:|:---------:|
| Flight 시작 전 | ✗ | ✗ | ✓ (시작 레벨 변경) | ✓ |
| Flight LIVE | ✓ | ✓ | ✓ | ✓ |
| Flight LIVE + 핸드 진행 중 | 다음 핸드 후 적용 | 다음 핸드 후 적용 | 다음 핸드 후 적용 | 핸드 후 종료 |
| 이미 Break 중 | ✗ (Resume 만 가능) | End Break | ✗ | ✓ |
| Day Close 진행 중 | ✗ | ✗ | ✗ | ✗ (취소만 가능) |
| WebSocket 단절 | 변경 불가 | 변경 불가 | 변경 불가 | 변경 불가 |

---

## 10. 유저 스토리

| # | As a | When | Then |
|:-:|------|------|------|
| C-1 | TD | Flight 시작 전 시작 레벨을 Level 3 으로 변경 | DB 갱신, 시작 시 Level 3 으로 시작 |
| C-2 | TD | LIVE 중 `[Break]` 클릭 → 15분 입력 | `is_pause=true`, Overlay "BREAK" 배지, 15분 후 자동 Resume |
| C-3 | TD | `[Day Close]` → "Play Down to 18 Players" | 18명 남으면 핸드 후 자동 Day End |
| C-4 | TD | DB 에서 Late Reg 종료 시각 변경 후 `[Clock Recreate]` | 새 종료 시각으로 타이머 갱신, 영향 받는 테이블에 알림 |
| C-5 | Operator (할당 테이블) | `[Pause]` 시도 | 권한 없음 안내, Admin 만 가능 |

---

## 11. 연관 문서

- `Event_and_Flight.md` — Late Registration 타이머 공식
- `Table.md §6` — LIVE+is_pause UI 표시
- `Operations.md` — System Log (Clock 이벤트 스트리밍)
- `../Engineering.md §5.4` — WebSocket 구독 매트릭스 (`clock_*` 이벤트)
- WSOP LIVE Confluence p2334752899 — Clock Control 원본

---

## 12. EBS divergence

| 항목 | WSOP LIVE | EBS |
|------|-----------|-----|
| Clock 알고리즘 | 자체 구현 | Game Engine (team3) Pure Dart Clock 엔진 사용 |
| Recreate 트리거 | 수동 버튼 | 수동 버튼 (동일) |
| Day Close 4 옵션 | 제공 | 제공 (동일) |
| Late Reg Override | 제공 | 제공 (동일) |
| Real-time tick 정밀도 | 1초 | 1초 (동일) |
