---
title: Backlog
owner: team4
tier: internal
last-updated: 2026-04-15
---

# Team 4 — Command Center 백로그

> 이 파일은 해당 팀이 소유합니다. 다른 팀은 수정 금지 (hook 차단).
> 크로스팀 항목은 `teams` 필드로 표기하고, 기록팀 파일에만 작성합니다.

## PENDING

_현재 PENDING 항목 없음_



### [NOTIFY-LEGACY-CCR-001] [LEGACY] 검토 요청: DATA-04에 idempotency_keys, audit_events 테이블 신설
> ⚠ **LEGACY NOTIFY** — 2026-04-10 CCR 일괄 적용 이전 세션 항목. 현재 CCR 번호 체계와 불일치. 현재 유효 CCR: `docs/05-plans/ccr-inbox/promoting/CCR-*.md`.

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/CCR-001-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/data/DATA-04-db-schema.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-LEGACY-CCR-003] [LEGACY] 검토 요청: 모든 Mutation API에 Idempotency-Key 헤더 표준 도입
> ⚠ **LEGACY NOTIFY** — 2026-04-10 CCR 일괄 적용 이전 세션 항목. 현재 CCR 번호 체계와 불일치. 현재 유효 CCR: `docs/05-plans/ccr-inbox/promoting/CCR-*.md`.

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/CCR-003-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/api/API-01-backend-api.md, contracts/api/API-05-websocket-events.md, contracts/api/API-06-auth-session.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-LEGACY-CCR-015] [LEGACY] 검토 요청: WebSocket 이벤트에 단조증가 seq 필드 + replay 엔드포인트 추가
> ⚠ **LEGACY NOTIFY** — 2026-04-10 CCR 일괄 적용 이전 세션 항목. 현재 CCR 번호 체계와 불일치. 현재 유효 CCR: `docs/05-plans/ccr-inbox/promoting/CCR-*.md`.

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/CCR-015-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/api/API-05-websocket-events.md, contracts/api/API-01-backend-api.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-LEGACY-CCR-016] [LEGACY] 검토 요청: WSOP LIVE Parity — EventFlightStatus/Restricted/BlindDetailType/Table 2축/Bit Flag RBAC
> ⚠ **LEGACY NOTIFY** — 2026-04-10 CCR 일괄 적용 이전 세션 항목. 현재 CCR 번호 체계와 불일치. 현재 유효 CCR: `docs/05-plans/ccr-inbox/promoting/CCR-*.md`.

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/CCR-016-*.md`
- **제안팀**: team1
- **변경 대상**: `contracts/specs/BS-02-lobby/BS-02-02-event-flight.md, contracts/specs/BS-02-lobby/BS-02-03-table.md, contracts/specs/BS-03-settings/BS-03-04-rules.md, contracts/specs/BS-01-auth/BS-01-02-rbac.md, contracts/data/DATA-02-entities.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-018] 검토 요청: DATA-04에 idempotency_keys, audit_events 테이블 신설

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-018-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/data/DATA-04-db-schema.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-021] 검토 요청: WebSocket 이벤트에 단조증가 seq 필드 + replay 엔드포인트 추가

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-021-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/api/API-05-websocket-events.md, contracts/api/API-01-backend-api.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-019] 검토 요청: 모든 Mutation API에 Idempotency-Key 헤더 표준 도입

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-019-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/api/API-01-backend-api.md, contracts/api/API-05-websocket-events.md, contracts/api/API-06-auth-session.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-012] 검토 요청: .gfskin ZIP 포맷 단일화 및 DATA-07 신설

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-012-*.md`
- **제안팀**: conductor
- **변경 대상**: `contracts/data/DATA-07-gfskin-schema.md, contracts/specs/BS-07-overlay/BS-07-03-skin-loading.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-011] 검토 요청: Graphic Editor 소유권 Team 4 → Team 1 이관 (Lobby 허브)

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-011-*.md`
- **제안팀**: conductor
- **변경 대상**: `contracts/specs/BS-08-graphic-editor/BS-08-00-overview.md, contracts/specs/BS-08-graphic-editor/BS-08-01-import-flow.md, contracts/specs/BS-08-graphic-editor/BS-08-02-metadata-editing.md, contracts/specs/BS-08-graphic-editor/BS-08-03-activate-broadcast.md, contracts/specs/BS-08-graphic-editor/BS-08-04-rbac-guards.md, contracts/specs/BS-00-definitions.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-017] 검토 요청: WSOP LIVE Parity — EventFlightStatus/Restricted/BlindDetailType/Table 2축/Bit Flag RBAC

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-017-*.md`
- **제안팀**: team1
- **변경 대상**: `contracts/specs/BS-02-lobby/BS-02-02-event-flight.md, contracts/specs/BS-02-lobby/BS-02-03-table.md, contracts/specs/BS-03-settings/BS-03-04-rules.md, contracts/specs/BS-01-auth/BS-01-02-rbac.md, contracts/data/DATA-02-entities.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-039] 검토 요청: audit_events.event_type 카탈로그 35값 공식 정의
- **알림일**: 2026-04-13
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-039-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/data/DATA-04-db-schema.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-041] 검토 요청: DATA-04에 Seat Status enum 정의 + waiting_list 테이블 신설
- **알림일**: 2026-04-13
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-041-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/data/DATA-04-db-schema.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-042] 검토 요청: API-05에 EventFlightSummary 이벤트 + Clock FSM 행동 명세 신설
- **알림일**: 2026-04-13
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-042-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/api/API-05-websocket-events.md, contracts/specs/`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-047] 검토 요청: Competition 계층 WSOP LIVE 정렬 (Series→Event→EventFlight)
- **알림일**: 2026-04-14
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-047-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/data/DATA-02-entities.md, contracts/data/DATA-04-db-schema.md, contracts/api/API-01-backend-api.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-048] 검토 요청: 인증 체계 WSOP LIVE GGPass 패턴 정렬
- **알림일**: 2026-04-14
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-048-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/specs/BS-01-auth/BS-01-auth.md, contracts/api/API-06-auth-session.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-050] 검토 요청: Clock 엔드포인트 10종 완성 (WSOP LIVE Staff App 정렬)
- **알림일**: 2026-04-14
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-050-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/api/API-01-backend-api.md, contracts/specs/BS-06-game-engine/BS-06-00-triggers.md, contracts/api/API-05-websocket-events.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-051] 검토 요청: PayoutStructure (PrizePool) 엔드포인트 추가 (WSOP LIVE 정렬)
- **알림일**: 2026-04-14
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-051-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/api/API-01-backend-api.md, contracts/data/DATA-02-entities.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-052] 검토 요청: Rate Limiting & 보안 정책 정의 (OWASP + WSOP LIVE GGPass 준거)
- **알림일**: 2026-04-14
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-052-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/specs/BS-01-auth/BS-01-auth.md, contracts/api/API-01-backend-api.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-054] 검토 요청: WebSocket 이벤트 카탈로그 WSOP LIVE SignalR 정렬
- **알림일**: 2026-04-14
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-054-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/api/API-05-websocket-events.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-055] 검토 요청: OutputEventBuffer 구현 소유팀 명시 (API-04 §3)
- **알림일**: 2026-04-14
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-055-*.md`
- **제안팀**: team3
- **변경 대상**: `contracts/api/API-04-overlay-output.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-056] 검토 요청: 외부 파일의 구 contracts/specs/BS-0X-* 경로 dead link 일괄 정리
- **알림일**: 2026-04-14
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-056-*.md`
- **제안팀**: team1
- **변경 대상**: `contracts/api/API-07-graphic-editor.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기

## IN_PROGRESS

_현재 진행 중인 항목 없음_
