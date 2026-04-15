---
title: CR-team2-20260414-clock-endpoints-full
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team2-20260414-clock-endpoints-full
---

# CCR-DRAFT: Clock 엔드포인트 10종 완성 (WSOP LIVE Staff App 정렬)

- **제안팀**: team2
- **제안일**: 2026-04-14
- **영향팀**: [team1, team4]
- **변경 대상 파일**: contracts/api/API-01-backend-api.md, contracts/specs/BS-06-game-engine/BS-06-00-triggers.md, contracts/api/API-05-websocket-events.md
- **변경 유형**: add
- **변경 근거**: 현행 API-01 §5.6.1은 Clock 엔드포인트 5종(GET/Start/Pause/Resume/PUT)만 정의. WSOP LIVE Staff App(`/전광판 API`, Page 1651343762; `Clock System Architecture and Operations`, Page 3728441546)은 10종을 제공하며 EBS 정식 전체 개발은 WSOP LIVE 패턴에 정렬해야 함. 누락 5종(Restart/Detail/ReloadPage/AdjustStack + Flight Complete/Cancel)은 토너먼트 운영 필수 기능.

## 변경 요약

1. `contracts/api/API-01-backend-api.md §5.6.1 Clock` 에 엔드포인트 5종 추가 (총 10종)
2. `contracts/api/API-01-backend-api.md §5.6 Flights` 에 Complete/Cancel 2종 추가
3. `contracts/specs/BS-06-game-engine/BS-06-00-triggers.md §2.5 BO Clock 트리거` 에 ClockDetailChanged/ClockReloadRequested/StackAdjusted/EventFlightCompleted/EventFlightCanceled 이벤트 추가
4. `contracts/api/API-05-websocket-events.md §4.2` 에 상응 WebSocket 이벤트 명세 추가

## Diff 초안

### contracts/api/API-01-backend-api.md §5.6.1 (Clock)

```diff
 #### 5.6.1 Clock — Tournament Timer

 > **WSOP LIVE 대응**: `PUT/POST /Series/{seriesId}/EventFlights/{eventFlightId}/Clock/*`
 > **ClockFSM**: BS-00-definitions §3.7. **BlindDetailType**: BS-00-definitions §3.8.
 > **WebSocket 이벤트**: clock_tick / clock_level_changed (API-05 §4.2.2~4.2.3)
+> **추가 WebSocket 이벤트**: clock_detail_changed / clock_reload_requested / stack_adjusted / tournament_status_changed (API-05 §4.2.X~W, 이 CCR에서 추가)

 | Method | Path | 설명 | 역할 제한 |
 |:------:|------|------|:---------:|
 | GET | `/flights/:id/clock` | Clock 현재 상태 (ClockFSM + 잔여 시간 + 현재 레벨) | 인증 사용자 |
 | POST | `/flights/:id/clock/start` | Clock 시작 (STOPPED → RUNNING) | Admin, Operator |
+| POST | `/flights/:id/clock/restart` | Clock 재시작 (현재 레벨을 duration 처음부터 재개) | Admin, Operator |
 | POST | `/flights/:id/clock/pause` | Clock 일시정지 (RUNNING → PAUSED). `duration_sec` 선택적 (자동 재개용) | Admin, Operator |
 | POST | `/flights/:id/clock/resume` | Clock 재개 (PAUSED → RUNNING) | Admin, Operator |
 | PUT | `/flights/:id/clock` | 시간/레벨 수동 조정 (`duration_diff_sec`, `level_diff`) | Admin |
+| PUT | `/flights/:id/clock/detail` | 테마/공지/이벤트명/그룹명/하프브레이크메시지/보너스명 변경 | Admin, Operator |
+| PUT | `/flights/:id/clock/reload-page` | 대시보드(전광판) 리로드 신호 방송 | Admin, Operator |
+| PUT | `/flights/:id/clock/adjust-stack` | 평균 칩 스택 강제 조정 (엔트리 미반영 시) | Admin |

 **POST /flights/:id/clock/pause — Request (optional body):**

+```json
+{ "duration_sec": 600 }
+```
+> `duration_sec` 제공 시 해당 초 경과 후 자동 Resume. 미제공 시 수동 Resume 필요.
+
 **PUT /flights/:id/clock/detail — Request:**
+
+```json
+{
+  "theme": "final_table",
+  "announcement": "Dinner break at Level 15",
+  "event_name_override": null,
+  "group_name": "Day 1B",
+  "half_break_message": "Half-time break in 5 min",
+  "bonus_name": null
+}
+```
+> 모든 필드 optional. 제공된 필드만 업데이트. `clock_detail_changed` WebSocket 이벤트 발행.
+
+**PUT /flights/:id/clock/reload-page — Request:** `{}` (body 없음).
+> 클라이언트(전광판/대시보드)가 수신 시 페이지 강제 리로드. 긴급 UI 동기화용.
+
+**PUT /flights/:id/clock/adjust-stack — Request:**
+
+```json
+{ "average_stack": 45000, "reason": "re-entry window closed, manual recalc" }
+```
+> `reason` 감사 로그 기록용. `stack_adjusted` 이벤트 발행.
```

### contracts/api/API-01-backend-api.md §5.6 (Flights — Complete/Cancel 추가)

```diff
 | DELETE | `/flights/:id` | Flight 영구 제거 | Admin |
+| PUT | `/flights/:id/complete` | EventFlight 완료 (Running → Completed) | Admin |
+| PUT | `/flights/:id/cancel` | EventFlight 취소 (Created/Announce/Registering/Running → Canceled) | Admin |
+
+**PUT /flights/:id/complete — Request:**
+
+```json
+{ "final_results": { "total_entries": 342, "prize_pool": 171000, "winner_player_id": 55 } }
+```
+> Status 전이: Running → Completed. TournamentStatus WebSocket 이벤트 발행. 전이 외 상태에서 호출 시 409.
+
+**PUT /flights/:id/cancel — Request:**
+
+```json
+{ "reason": "venue closure", "refund_policy": "full" }
+```
+> Status 전이: {Created, Announce, Registering, Running} → Canceled. Completed 상태에서는 호출 불가(409). 활성 CC 세션 종료 브로드캐스트 동반.
```

### contracts/specs/BS-06-game-engine/BS-06-00-triggers.md §2.5

```diff
 | `ClockStarted` | Admin/Operator (Lobby) | `lobby_monitor` + `cc_event` | 토너먼트 타이머 시작 → ClockFSM: STOPPED → RUNNING |
+| `ClockRestarted` | Admin/Operator | `lobby_monitor` + `cc_event` | 현재 레벨 duration 처음부터 재시작 |
 | `ClockPaused` | Operator/Admin (CC) | `lobby_monitor` + `cc_event` | TD 수동 정지 → ClockFSM: RUNNING → PAUSED |
 | `ClockResumed` | Operator/Admin (CC) | `lobby_monitor` + `cc_event` | TD 재개 → ClockFSM: PAUSED → RUNNING |
 | `clock_tick` | BO 내부 타이머 | `lobby_monitor` + `cc_event` | 매 1초 자동 발행. 클라이언트 카운트다운용 |
 | `clock_level_changed` | BO 내부 타이머 | `lobby_monitor` + `cc_event` | 레벨 전환·Break 진입/종료 시 발행 |
+| `clock_detail_changed` | Admin/Operator | `lobby_monitor` + `cc_event` | 테마/공지/메시지 변경 시 발행 (WSOP LIVE `ClockDetail` 대응) |
+| `clock_reload_requested` | Admin/Operator | `lobby_monitor` + `cc_event` | 대시보드 강제 리로드 신호 (WSOP LIVE `ClockReloadPage` 대응) |
+| `stack_adjusted` | Admin | `lobby_monitor` + `cc_event` | 평균 스택 강제 조정 시 발행 |
+| `tournament_status_changed` | Admin | `lobby_monitor` + `cc_event` | EventFlightStatus 전이(Created/Announce/Registering/Running/Completed/Canceled) 시 발행 |
```

### contracts/api/API-05-websocket-events.md §4.2

```diff
 ### 4.2 Lobby 전용 이벤트
 ...
+
+#### 4.2.X clock_detail_changed
+
+- **Trigger**: `PUT /flights/:id/clock/detail` 성공 시.
+- **Payload**: `{ flight_id, theme?, announcement?, event_name_override?, group_name?, half_break_message?, bonus_name? }` (변경된 필드만).
+- **Consumer**: Lobby(전광판 UI), CC.
+- **WSOP LIVE 대응**: `ClockDetail` SignalR 이벤트.
+
+#### 4.2.Y clock_reload_requested
+
+- **Trigger**: `PUT /flights/:id/clock/reload-page` 성공 시.
+- **Payload**: `{ flight_id }`.
+- **Consumer**: Lobby(대시보드).
+- **WSOP LIVE 대응**: `ClockReloadPage`.
+
+#### 4.2.Z stack_adjusted
+
+- **Trigger**: `PUT /flights/:id/clock/adjust-stack` 성공 시.
+- **Payload**: `{ flight_id, average_stack, reason, actor_id, timestamp }`.
+- **Consumer**: Lobby, CC.
+
+#### 4.2.W tournament_status_changed
+
+- **Trigger**: `PUT /flights/:id/complete` 또는 `/cancel` 성공 시.
+- **Payload**: `{ flight_id, old_status, new_status, reason?, final_results? }`.
+- **Consumer**: Lobby, CC.
+- **WSOP LIVE 대응**: `TournamentStatus` SignalR 이벤트.
```

## Divergence from WSOP LIVE (Why)

1. **URL에서 Series 경로 생략**: WSOP LIVE `PUT /Series/{sId}/EventFlights/{efId}/Clock/*` → EBS `PUT /flights/:id/clock/*`.
   - **Why**: EBS는 EventFlight ID(`flights/:id`)만으로 전역 유일 식별 가능. Series ID는 flights 테이블 FK로 내부 조회. URL 단축으로 클라이언트 구현 단순화.
2. **SignalR → 순수 WebSocket**: WSOP LIVE는 Microsoft SignalR(MessagePack+Gzip) 단일 Hub, EBS는 순수 WebSocket 2 엔드포인트(`/ws/cc`, `/ws/lobby`).
   - **Why**: Python/FastAPI 스택 호환성. 이벤트 이름은 WSOP LIVE 그대로 매핑 유지.
3. **이벤트 이름 스네이크 케이스**: WSOP LIVE `ClockDetail` → EBS `clock_detail_changed`.
   - **Why**: EBS API-05 컨벤션이 snake_case + 동작형 suffix (`_changed`, `_requested`). 기존 이벤트 패턴 일관성.

## 영향 분석

- **Team 1 (Lobby Frontend)**:
  - 전광판 페이지에 reload 리스너 신설 (1시간).
  - Clock Detail 편집 UI 추가 (2-3시간).
  - TournamentStatus 표시 (Completed/Canceled 배지) (1시간).
- **Team 4 (Command Center)**:
  - clock_detail_changed 수신 시 CC UI 공지 영역 갱신 (1시간).
  - tournament_status_changed 수신 시 CC 세션 종료 처리 (2시간).
- **Team 2 (Backend, 자기 영향)**:
  - 5 신규 엔드포인트 구현 + FSM 전이 검증 + 이벤트 발행 + 테스트.
  - DB 변경 없음 (event_flights 테이블에 상태/스택 필드 기존 존재).
- **마이그레이션**: 없음 (신규 엔드포인트 추가만. 기존 5종 호환 유지).

## 대안 검토

1. **기존 `PUT /flights/:id/clock` 에 reload/stack_adjust 모두 통합**: 단일 엔드포인트 요청마다 action 필드로 분기.
   - 탈락: WSOP LIVE는 분리 설계. 서브리소스 URL이 REST 관례. 감사 로그/권한 경계 명확.
2. **detail/reload를 WebSocket 직접 발행**: 클라이언트가 직접 메시지 전송.
   - 탈락: 권한 경계(Admin only) 강제 불가. REST 경유해야 RBAC + 감사 가능.
3. **Complete/Cancel을 HTTP DELETE 메서드로 표현**: `DELETE /flights/:id?cancel=true`.
   - 탈락: 기존 `DELETE /flights/:id` 가 영구 제거 용도로 예약됨. WSOP LIVE는 `PUT /Complete`, `/Cancel` 명시적 액션 사용.

## 검증 방법

- **단위**:
  - FSM 전이 테스트 (Running→Completed OK, Completed→Canceled 409, etc.)
  - 각 엔드포인트 권한 검증 (Viewer/Operator/Admin)
  - 이벤트 페이로드 스키마 JSON schema 검증
- **통합**:
  - CC → BO → Lobby 플로우: Admin이 detail 변경 → 전광판 UI 즉시 갱신 (<1초)
  - Cancel → 활성 CC 세션 자동 종료 확인
- **WSOP LIVE 정렬 확인**:
  - WSOP LIVE 10 엔드포인트 각각 EBS 대응 1:1 매핑 검증표 작성

## 승인 요청

- [ ] Conductor 승인 (변경 범위가 3 파일 + 5 신규 엔드포인트로 MEDIUM 가능성)
- [ ] Team 1 기술 검토 (Lobby UI 영향)
- [ ] Team 4 기술 검토 (CC UI 영향)
- [ ] 리스크 등급 자동 판정: `python tools/ccr_validate_risk.py --draft CCR-DRAFT-team2-20260414-clock-endpoints-full.md`

## 참고 출처 (WSOP LIVE Confluence)

| 페이지 ID | 제목 | 역할 |
|---|---|---|
| 1651343762 | 전광판 API (Staff App API/Tournament/Event Flight API) | Clock 10 엔드포인트 원본 |
| 3728441546 | Clock System Architecture and Operations | FSM/상태/이벤트 구조 |
| 1960411325 | Enum (BlindDetailType, EventFlightStatus) | enum 값 |
| 1793328277 | Signalr Service | WebSocket 이벤트 매핑 (ClockDetail, TournamentStatus, ClockReloadPage) |
