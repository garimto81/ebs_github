---
title: CR-team2-20260414-ws-event-catalog
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team2-20260414-ws-event-catalog
---

# CCR-DRAFT: WebSocket 이벤트 카탈로그 WSOP LIVE SignalR 정렬

- **제안팀**: team2
- **제안일**: 2026-04-14
- **영향팀**: [team1, team3, team4]
- **변경 대상 파일**: contracts/api/API-05-websocket-events.md
- **변경 유형**: add
- **변경 근거**: WSOP LIVE Staff App SignalR Hub(Page 1793328277)은 8종 이벤트(Clock/ClockDetail/TournamentStatus/EventFlightSummary/BlindStructure/PrizePool/ClockReload/ClockReloadPage)를 발행. EBS API-05는 이 중 3종(event_flight_summary, clock_tick, clock_level_changed)만 대응. 정식 전체 개발에서 `blind_structure_changed`/`prize_pool_changed` 추가 + 전체 매핑 표가 필요. (clock_detail_changed/clock_reload_requested/tournament_status_changed는 별도 CCR S0-01에서 추가 제안.)

## 변경 요약

1. `contracts/api/API-05 §4.2` 에 WSOP LIVE SignalR 이벤트 ↔ EBS 이벤트 매핑 표 신설
2. 누락 이벤트 2종 추가: `blind_structure_changed`, `prize_pool_changed`

## Diff 초안

```diff
 ### 4.2 Lobby 전용 이벤트

+#### 4.2.0 WSOP LIVE SignalR 이벤트 매핑
+
+| WSOP LIVE Hub 이벤트 | EBS 이벤트 | 발행 트리거 | 정의 섹션 |
+|---|---|---|---|
+| `Clock` | `clock_tick` | 매 1초 (BO 내부 타이머) | §4.2.2 |
+| `Clock` (레벨 전환) | `clock_level_changed` | 레벨 전이 시 | §4.2.3 |
+| `ClockDetail` | `clock_detail_changed` | `PUT /flights/:id/clock/detail` | §4.2.X (S0-01 CCR) |
+| `ClockReload` | `clock_reload_requested` (내부) | 클록 엔진 재로드 | 내부 이벤트 |
+| `ClockReloadPage` | `clock_reload_requested` | `PUT /flights/:id/clock/reload-page` | §4.2.Y (S0-01 CCR) |
+| `TournamentStatus` | `tournament_status_changed` | EventFlightStatus 전이 | §4.2.W (S0-01 CCR) |
+| `EventFlightSummary` | `event_flight_summary` | 엔트리/좌석/스택/스탯 변경 | §4.2.1 |
+| `BlindStructure` | `blind_structure_changed` | 블라인드 구조 수정 | §4.2.4 (이 CCR) |
+| `PrizePool` | `prize_pool_changed` | 엔트리/페이아웃 재계산 | §4.2.5 (이 CCR) |
+
+#### 4.2.4 blind_structure_changed
+
+- **Trigger**: `PUT /flights/:id/blind-structure/*` 성공 또는 자동 레벨 재계산 시.
+- **Payload**:
+```json
+{
+  "flight_id": 3,
+  "levels": [
+    { "level": 1, "sb": 100, "bb": 200, "ante": 0, "duration_sec": 1200, "blind_detail_type": 0 },
+    { "level": 2, "sb": 200, "bb": 400, "ante": 50, "duration_sec": 1200, "blind_detail_type": 0 }
+  ]
+}
+```
+- **Consumer**: Lobby(전광판), CC(레벨 표시), Engine(Team 3 — blind 변경 시 `BlindStructureChanged` 내부 이벤트 수신).
+- **WSOP LIVE 대응**: `BlindStructure` SignalR 이벤트.
+
+#### 4.2.5 prize_pool_changed
+
+- **Trigger**: 엔트리 수 변경 또는 `PUT /flights/:id/prize-pool` 수동 재계산 시.
+- **Payload**:
+```json
+{
+  "flight_id": 3,
+  "total_pool": 171000,
+  "entries": 342,
+  "payouts": [
+    { "place": 1, "amount": 50000 },
+    { "place": 2, "amount": 30000 }
+  ]
+}
+```
+- **Consumer**: Lobby(전광판 상금 표시), CC(최종 테이블 페이아웃 표시).
+- **WSOP LIVE 대응**: `PrizePool` SignalR 이벤트.
```

## Divergence from WSOP LIVE (Why)

1. **SignalR → 순수 WebSocket 2 엔드포인트**: WSOP LIVE는 단일 `/staffHub`, EBS는 `/ws/cc` + `/ws/lobby`.
   - **Why**: FastAPI 네이티브 WebSocket이 SignalR 대비 단순. 이벤트명 1:1 매핑 유지로 의미 동등.
2. **snake_case 이벤트 이름**: WSOP `BlindStructure` → EBS `blind_structure_changed`.
   - **Why**: EBS API-05 기존 컨벤션. 동작형 suffix(`_changed`) 일관성.
3. **payload에 `levels`/`payouts` 배열 포함**: WSOP LIVE 원본은 분리 응답 가능성. 확정 필요.
   - **Why**: 단일 이벤트로 전체 구조 전달 → 클라이언트 부분 업데이트 부담 감소. WSOP LIVE 원본 payload 구조 추가 조사 예정.

## 영향 분석

- **Team 1**: Lobby 전광판이 2 이벤트 수신 리스너 추가 (각 1-2시간)
- **Team 3**: blind_structure_changed를 엔진이 수신 (command 라우팅) — API-04 연계 검토 필요
- **Team 4**: CC 페이아웃 표시 UI 추가 (2-3시간)
- **Team 2**: 이벤트 발행 로직 + payload 스키마 검증

## 대안 검토

1. **각 이벤트를 REST 폴링으로 대체**: 탈락. 실시간성 저하.
2. **단일 generic `summary_changed` 이벤트로 통합**: 탈락. 소비자가 어느 필드 변경인지 판별 불가 → 전량 재조회 부담.

## 검증

- 각 이벤트 payload JSON Schema 검증
- WSOP LIVE SignalR 원본 payload 구조 대조 (Page 1793328277 재확인)
- 구독자별 필터링 정상 동작 (§4.3)

## 승인 요청

- [ ] Team 1, 3, 4 기술 검토
- [ ] 리스크 판정: `python tools/ccr_validate_risk.py --draft <file>`

## 참고 출처

| Page ID | 제목 |
|---|---|
| 1793328277 | Signalr Service (Hub 이벤트 8종 카탈로그) |
| 3728441546 | Clock System Architecture and Operations (Clock/ClockDetail/ClockReload 상세) |
