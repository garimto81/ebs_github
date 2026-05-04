---
id: B-LOBBY-TOPBAR-001
title: "TopBar 운영 컨텍스트 클러스터 (SHOW/FLIGHT/LEVEL/NEXT) — design SSOT 정렬"
status: PENDING
priority: P1
source: docs/4. Operations/Lobby_Modification_Plan_2026-05-04.md §F4
blocked_by:
  - docs/4. Operations/Conductor_Backlog/B-LOBBY-TOPBAR-WS-CONTRACT.md (team2 publisher 계약 정의)
related:
  - docs/2. Development/2.1 Frontend/Lobby/UI.md §"운영 컨텍스트 클러스터 (TopBar Center)"
  - docs/2. Development/2.1 Frontend/Lobby/References/EBS_Lobby_Design/shell.jsx (lines 43-50)
---

# B-LOBBY-TOPBAR-001 — TopBar SHOW/FLIGHT/LEVEL/NEXT 컨텍스트 클러스터

## 배경

design SSOT (`Lobby/References/EBS_Lobby_Design/shell.jsx:43-50`) 의 TopBar 중앙 클러스터가 현재 Flutter 구현 (`team1-frontend/lib/foundation/widgets/lobby_top_bar.dart`) 에 없음. 결과: 다중 Lobby 동시 접속 환경에서 운영자가 "지금 어느 Show/Flight/Level 에서 작업 중인가" 시야 부재 → operator context loss 위험.

사용자 의사결정 (2026-05-04): **데이터 소스 = ㉡ Backend WS 실시간 push** (team2 publisher 계약 우선 정의 필요).

## 수락 기준

- [ ] `lobby_top_bar.dart` 에 `LobbyTopBarContext` 위젯 4-cell 추가 (SHOW / FLIGHT / LEVEL / NEXT)
- [ ] 각 cell = `Padding + Column(['LABEL' uppercase dim, value])`
- [ ] WS subscription = team2 가 정의할 토픽 (B-LOBBY-TOPBAR-WS-CONTRACT 결과)
- [ ] Riverpod stream provider 로 4 값 구독
- [ ] WS 끊김 시 마지막 값 유지 + dim 처리 + "● disconnected" indicator
- [ ] Series/Flight 미선택 시 클러스터 hidden
- [ ] LEVEL `next timer` 클라이언트 1초 보간 (서버 매 1초 push 부담 회피)
- [ ] 위젯 테스트 + golden test (4 상태: idle/connected/disconnected/missing-context)

## 의존성

- **Blocking**: team2 가 `level_changed` + `level_timer` + `current_show_flight` WS 토픽 (또는 단일 `lobby_context` snapshot 토픽) 계약 정의 후 진입
- **Backend**: BO 가 active level 상태 publisher 역할 (team3 engine 으로부터 level transition 수신 후 lobby 에 fan-out)
- **API 계약 위치**: `docs/2. Development/2.5 Shared/` 또는 `2.2 Backend/APIs/WebSocket_Events.md` (team2 결정)

## 구현 방향

```
team2 publisher (FastAPI WS)
       │ level_changed / level_timer
       ▼
team1 Riverpod stream provider
       │ LobbyContext{show, flight, level, next}
       ▼
LobbyTopBarContext 위젯 (4 cells)
```

## 우선순위 / 추정

- P1 (operator visibility, multi-session safety)
- 추정: team2 계약 정의 1~2일 + team1 구현 0.5~1일 = 총 2~3일 (사용자 결정 §F4 ㉡ 옵션 추정과 일치)
