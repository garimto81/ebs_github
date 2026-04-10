# Team 1 — Frontend 백로그

> 이 파일은 해당 팀이 소유합니다. 다른 팀은 수정 금지 (hook 차단).
> 크로스팀 항목은 `teams` 필드로 표기하고, 기록팀 파일에만 작성합니다.

## PENDING

### [B-068] team1-frontend Quasar 프로젝트 실제 초기화
- **날짜**: 2026-04-10
- **teams**: [team1]
- **설명**: `team1-frontend/src/`가 `.gitkeep`만 포함하여 사실상 빈 상태. commit `9c45acf`가 "ebs_lobby 통합 완료"를 주장하지만 실제 소스 파일이 들어있지 않음. Quasar (Vue 3) + TypeScript 프로젝트를 실제로 초기화하고 기존 `docs/07-archive/legacy-repos/ebs_lobby-react/` 또는 통합 이전 `ebs_lobby_web` 내용을 Quasar로 이식/재작성.
- **수락 기준**: `team1-frontend/src/` 하위에 Quasar 프로젝트 구조(`src/`, `quasar.config.js` 등) 존재, `pnpm dev` 또는 `quasar dev` 명령으로 Lobby 기본 화면이 로컬에서 부팅.
- **관련 PRD**: CLAUDE.md §Team 1, contracts/specs/BS-02-lobby/, team1-frontend/CLAUDE.md



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
- **변경 대상**: `contracts/api/API-01-backend-endpoints.md, contracts/api/API-05-websocket-events.md, contracts/api/API-06-auth-session.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-LEGACY-CCR-006] [LEGACY] 검토 요청: BS-01에 JWT Access/Refresh 만료 정책 명시
> ⚠ **LEGACY NOTIFY** — 2026-04-10 CCR 일괄 적용 이전 세션 항목. 현재 CCR 번호 체계와 불일치. 현재 유효 CCR: `docs/05-plans/ccr-inbox/promoting/CCR-*.md`.

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/CCR-006-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/specs/BS-01-auth/BS-01-auth.md, contracts/api/API-06-auth-session.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-LEGACY-CCR-010] [LEGACY] 검토 요청: /tables/rebalance 응답에 saga 구조 추가
> ⚠ **LEGACY NOTIFY** — 2026-04-10 CCR 일괄 적용 이전 세션 항목. 현재 CCR 번호 체계와 불일치. 현재 유효 CCR: `docs/05-plans/ccr-inbox/promoting/CCR-*.md`.

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/CCR-010-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/api/API-01-backend-endpoints.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-LEGACY-CCR-015] [LEGACY] 검토 요청: WebSocket 이벤트에 단조증가 seq 필드 + replay 엔드포인트 추가
> ⚠ **LEGACY NOTIFY** — 2026-04-10 CCR 일괄 적용 이전 세션 항목. 현재 CCR 번호 체계와 불일치. 현재 유효 CCR: `docs/05-plans/ccr-inbox/promoting/CCR-*.md`.

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/CCR-015-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/api/API-05-websocket-events.md, contracts/api/API-01-backend-endpoints.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-LEGACY-CCR-016] [LEGACY] 검토 요청: WSOP LIVE Parity — EventFlightStatus/Restricted/BlindDetailType/Table 2축/Bit Flag RBAC
> ⚠ **LEGACY NOTIFY** — 2026-04-10 CCR 일괄 적용 이전 세션 항목. 현재 CCR 번호 체계와 불일치. 현재 유효 CCR: `docs/05-plans/ccr-inbox/promoting/CCR-*.md`.

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/CCR-016-*.md`
- **제안팀**: team1
- **변경 대상**: `contracts/specs/BS-02-lobby/BS-02-02-event-flight.md, contracts/specs/BS-02-lobby/BS-02-03-table.md, contracts/specs/BS-03-settings/BS-03-04-rules.md, contracts/specs/BS-01-auth/BS-01-02-rbac.md, contracts/data/DATA-02-entities.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-LEGACY-CCR-017] [LEGACY] 검토 요청: BS-05에 AT 화면 체계(AT-00~AT-07) 도입
> ⚠ **LEGACY NOTIFY** — 2026-04-10 CCR 일괄 적용 이전 세션 항목. 현재 CCR 번호 체계와 불일치. 현재 유효 CCR: `docs/05-plans/ccr-inbox/promoting/CCR-*.md`.

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/CCR-017-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-05-command-center/BS-05-00-overview.md, contracts/specs/BS-05-command-center/BS-05-03-seat-management.md, contracts/specs/BS-05-command-center/BS-05-04-manual-card-input.md, contracts/specs/BS-05-command-center/BS-05-08-game-settings-modal.md, contracts/specs/BS-05-command-center/BS-05-09-player-edit-modal.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-LEGACY-CCR-019] [LEGACY] 검토 요청: BS-05 시각/동작 명세 구체화 (카드 슬롯 FSM, 포지션 색상, 애니메이션)
> ⚠ **LEGACY NOTIFY** — 2026-04-10 CCR 일괄 적용 이전 세션 항목. 현재 CCR 번호 체계와 불일치. 현재 유효 CCR: `docs/05-plans/ccr-inbox/promoting/CCR-*.md`.

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/CCR-019-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-05-command-center/BS-05-03-seat-management.md, contracts/specs/BS-05-command-center/BS-05-04-manual-card-input.md, contracts/specs/BS-07-overlay/BS-07-02-animations.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-LEGACY-CCR-021] [LEGACY] 검토 요청: API-05 MessagePack 직렬화 프로토콜 채택 (WSOP Fatima.app 패턴)
> ⚠ **LEGACY NOTIFY** — 2026-04-10 CCR 일괄 적용 이전 세션 항목. 현재 CCR 번호 체계와 불일치. 현재 유효 CCR: `docs/05-plans/ccr-inbox/promoting/CCR-*.md`.

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/CCR-021-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/api/API-05-websocket-events.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-LEGACY-CCR-024] [LEGACY] 검토 요청: BS-07 Overlay 시각 일관성 (CC 색상 체계 재사용)
> ⚠ **LEGACY NOTIFY** — 2026-04-10 CCR 일괄 적용 이전 세션 항목. 현재 CCR 번호 체계와 불일치. 현재 유효 CCR: `docs/05-plans/ccr-inbox/promoting/CCR-*.md`.

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/CCR-024-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-07-overlay/BS-07-01-elements.md, contracts/specs/BS-07-overlay/BS-07-04-scene-schema.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-LEGACY-CCR-025] [LEGACY] 검토 요청: BS-08 Graphic Editor 행동 명세 신규 작성 (WSOP 8모드)
> ⚠ **LEGACY NOTIFY** — 2026-04-10 CCR 일괄 적용 이전 세션 항목. 현재 CCR 번호 체계와 불일치. 현재 유효 CCR: `docs/05-plans/ccr-inbox/promoting/CCR-*.md`.

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/CCR-025-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-08-graphic-editor/BS-08-00-overview.md, contracts/specs/BS-08-graphic-editor/BS-08-01-modes.md, contracts/specs/BS-08-graphic-editor/BS-08-02-skin-editor.md, contracts/specs/BS-08-graphic-editor/BS-08-03-color-adjust.md, contracts/specs/BS-08-graphic-editor/BS-08-04-rive-import.md, contracts/specs/BS-08-graphic-editor/BS-08-05-preview-apply.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-018] 검토 요청: DATA-04에 idempotency_keys, audit_events 테이블 신설

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-018-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/data/DATA-04-db-schema.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-020] 검토 요청: /tables/rebalance 응답에 saga 구조 추가

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-020-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/api/API-01-backend-endpoints.md`
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


### [NOTIFY-CCR-014] 검토 요청: GE 요구사항 ID prefix 재편 (범위 축소 반영)

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-014-*.md`
- **제안팀**: conductor
- **변경 대상**: `contracts/specs/BS-00-definitions.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-013] 검토 요청: API-07 Graphic Editor 엔드포인트 신설

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-013-*.md`
- **제안팀**: conductor
- **변경 대상**: `contracts/api/API-07-graphic-editor.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-023] 검토 요청: API-05 MessagePack 직렬화 프로토콜 채택 (WSOP Fatima.app 패턴)

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-023-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/api/API-05-websocket-events.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-028] 검토 요청: BS-05에 AT 화면 체계(AT-00~AT-07) 도입

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-028-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-05-command-center/BS-05-00-overview.md, contracts/specs/BS-05-command-center/BS-05-03-seat-management.md, contracts/specs/BS-05-command-center/BS-05-04-manual-card-input.md, contracts/specs/BS-05-command-center/BS-05-08-game-settings-modal.md, contracts/specs/BS-05-command-center/BS-05-09-player-edit-modal.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-029] 검토 요청: BS-05 Lobby → BO → CC Launch 플로우 상세 명세

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-029-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-05-command-center/BS-05-00-overview.md, contracts/api/API-01-backend-endpoints.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-030] 검토 요청: BS-05 Multi-Table 운영자 시나리오 명시

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-030-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-05-command-center/BS-05-10-multi-table-ops.md, contracts/specs/BS-05-command-center/BS-05-00-overview.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-032] 검토 요청: BS-05 시각/동작 명세 구체화 (카드 슬롯 FSM, 포지션 색상, 애니메이션)

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-032-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-05-command-center/BS-05-03-seat-management.md, contracts/specs/BS-05-command-center/BS-05-04-manual-card-input.md, contracts/specs/BS-07-overlay/BS-07-02-animations.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-034] 검토 요청: BS-07 Overlay 시각 일관성 (CC 색상 체계 재사용)

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-034-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-07-overlay/BS-07-01-elements.md, contracts/specs/BS-07-overlay/BS-07-04-scene-schema.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-036] 검토 요청: BS-07 Security Delay (홀카드 공개 지연) 명세

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-036-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-07-overlay/BS-07-07-security-delay.md, contracts/api/API-04-overlay-output.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-037] 검토 요청: BS-08 Graphic Editor 행동 명세 신규 작성 (WSOP 8모드)

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-037-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-08-graphic-editor/BS-08-00-overview.md, contracts/specs/BS-08-graphic-editor/BS-08-01-modes.md, contracts/specs/BS-08-graphic-editor/BS-08-02-skin-editor.md, contracts/specs/BS-08-graphic-editor/BS-08-03-color-adjust.md, contracts/specs/BS-08-graphic-editor/BS-08-04-rive-import.md, contracts/specs/BS-08-graphic-editor/BS-08-05-preview-apply.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기

## IN_PROGRESS

_현재 진행 중인 항목 없음_

## DONE

| ID | 제목 | 완료일 | 관련 |
|----|------|--------|------|
| B-069 | Team 1 frontend 기획서 critic revision — WSOP LIVE Confluence parity + Quasar 전환 정렬 + CCR-011/025 후속 반영 | 2026-04-10 | UI-00-design-system.md (Quasar 확정 + GE 이관), UI-01-lobby.md (§9 WSOP Parity Notes, 배너 APPLIED 전환), UI-03-settings.md (§1.1 Ownership & Boundary + ConfigChanged 흐름 + GE 허브 반영), team1-frontend/CLAUDE.md (Settings 6탭 + GE 범위 신설), QA-LOBBY-02/04/05 (DEPRECATED 배너). 드래프트: `ccr-inbox/archived/CCR-DRAFT-team1-20260410-wsop-parity.md` → **CCR-017 APPLIED**, `ccr-inbox/archived/CCR-DRAFT-team1-20260410-tech-stack-ssot.md` → **CCR-016 APPLIED**. 후속 반영 CCR: CCR-011 ge-ownership-move (GE Team 1 이관) APPLIED, CCR-025 bs03-graphic-settings-tab APPLIED. Plan: `C:/Users/AidenKim/.claude/plans/floofy-stargazing-wren.md` |
