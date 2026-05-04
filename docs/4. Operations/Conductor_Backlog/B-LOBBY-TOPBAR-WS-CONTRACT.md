---
id: B-LOBBY-TOPBAR-WS-CONTRACT
title: "Lobby TopBar 컨텍스트 클러스터 — team2 publisher WS 계약 정의"
type: cross_team_contract
status: PENDING
priority: P1
owner: conductor (계약 author) → team2 (publisher implementation)
created: 2026-05-04
source: docs/4. Operations/Lobby_Modification_Plan_2026-05-04.md §F4
blocks:
  - docs/2. Development/2.1 Frontend/Backlog/B-LOBBY-TOPBAR-001.md
related:
  - docs/2. Development/2.1 Frontend/Lobby/UI.md §"운영 컨텍스트 클러스터 (TopBar Center)"
  - docs/2. Development/2.5 Shared/team-policy.json (publisher = team2)
  - team2-backend/CLAUDE.md (publisher 영역 — APIs/WebSocket)
---

# B-LOBBY-TOPBAR-WS-CONTRACT — Lobby TopBar 컨텍스트 WS 계약

> **목적**: team1 의 `B-LOBBY-TOPBAR-001` 가 시작 가능하도록 team2 publisher 가 정의해야 할 WS 계약 명세.
>
> **사용자 의사결정 (2026-05-04 §F4)**: 데이터 소스 = ㉡ Backend WS push (team2 협의 필요, 2~3일 추가).

## 컨텍스트

design SSOT (`Lobby/References/EBS_Lobby_Design/shell.jsx:43-50`) 의 TopBar 중앙 클러스터 = SHOW / FLIGHT / LEVEL / NEXT 4-cell. 디자인 자산은 정적 mock 값이지만 실제 운영에서는 team3 engine 의 level transition + team2 BO 의 active series/flight 상태가 lobby 4 cell 로 fan-out 되어야 함.

## team2 가 정의해야 할 산출물

### 1. WS 토픽 (택1 권고)

| 옵션 | 토픽 | 페이로드 | 빈도 |
|------|------|---------|------|
| **A. 통합 snapshot** | `lobby.context` | `{show, flight, level{label, sb, bb, ante}, next{seconds, label}}` | 변경 시 + 1초 timer tick |
| **B. 분리 토픽** | `lobby.show`, `lobby.flight`, `lobby.level`, `lobby.timer` | 각 도메인별 | 도메인별 트리거 |

> 권고: **Option A (통합 snapshot)**. 4 cell 이 동기화되어야 하고 (e.g. Flight 변경 시 level reset), 분리 토픽은 race 발생 가능. timer 만 별도 분리 가능 (`lobby.context` 변경 빈도 낮음 + `lobby.timer` 1초 tick 분리).

### 2. 페이로드 스키마 (Option A 가정)

```typescript
// lobby.context (변경 시 push)
type LobbyContextSnapshot = {
  show: { id: string; shortName: string; longName: string } | null;
  flight: { id: string; label: string; status: 'registering'|'running'|'completed' } | null;
  level: { num: number; label: string; sb: number; bb: number; ante: number; durationSec: number } | null;
  // next 의 정적 부분만. timer 보간은 클라이언트가 매 1초 자체 감산
  next: { num: number; label: string; sb: number; bb: number } | null;
};

// lobby.timer (1초 tick)
type LobbyTimerTick = {
  flightId: string;
  remainingSec: number;  // 다음 level 까지
  serverTs: number;      // ms epoch (시계 동기화 보정용)
};
```

### 3. publisher 트리거 (BO 측 책임)

| 트리거 | 발행 토픽 |
|--------|----------|
| Flight 시작 / 일시정지 / 재개 / 종료 | `lobby.context` (full snapshot) |
| Level 전환 (engine `level_changed` 수신) | `lobby.context` (level + next 갱신) |
| 1초 마다 (active flight 가 있을 때만) | `lobby.timer` |
| Series/Flight 미선택 (lobby 진입 직후) | `lobby.context` with `null` 값들 |

### 4. RBAC

- **Admin / Operator / Viewer** 모두 구독 가능 (운영 컨텍스트는 read-only 정보)
- 인증: 기존 Lobby WS auth 흐름 재사용 (`Auth_and_Session.md`)

### 5. 재연결 / 초기 snapshot

- WS 재연결 시 클라이언트가 `subscribe lobby.context` 하면 publisher 가 즉시 현재 snapshot 1회 push
- 별도 REST fallback 없음 (WS 만으로 충분)

## team2 작업 범위 추정

| 항목 | 추정 |
|------|------|
| WS 계약 명세 (`docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md` 보강) | 0.5일 |
| publisher 구현 (BO) | 1~1.5일 |
| 통합 테스트 (engine → BO → lobby WS) | 0.5일 |
| **합계** | **2~2.5일** |

## 진행 절차

1. team2 가 본 메모 검토 + 계약 옵션 (A/B) 결정
2. team2 가 `2.2 Backend/APIs/WebSocket_Events.md` 에 `lobby.context` + `lobby.timer` 섹션 추가 (additive)
3. team2 가 publisher 구현 + 통합 테스트
4. team1 의 `B-LOBBY-TOPBAR-001` unblock → 구현 진입

## 의사결정 / 승인 경로

- **계약 author**: Conductor (본 메모)
- **publisher 결정권**: team2 (WS 계약 SSOT publisher per `team-policy.json`)
- **subscriber**: team1 (소비자, 계약 변경 요청 권한 있음)
- 합의 도달 후 본 파일 status = DONE 처리, B-LOBBY-TOPBAR-001 unblock
