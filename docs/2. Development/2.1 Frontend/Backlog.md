---
title: Backlog
owner: team1
tier: internal
last-updated: 2026-04-15
---

# Team 1 — Frontend 백로그

> 이 파일은 해당 팀이 소유합니다. 다른 팀은 수정 금지 (hook 차단).
> 크로스팀 항목은 `teams` 필드로 표기하고, 기록팀 파일에만 작성합니다.

## PENDING

### [B-075] React 아카이브 → Quasar 이식 (B-068 하위)
- **날짜**: 2026-04-10
- **teams**: [team1]
- **설명**: `C:/claude/ebs-archive-backup/07-archive/legacy-repos/ebs_lobby-react/` 의 9 pages + 19 api modules + 2 Zustand stores + mock-handler 를 Quasar (Vue 3) + Pinia + MSW 2.x 로 이식. JSX→Vue template, react-router→vue-router, Zustand `create()`→Pinia `defineStore()`, `useNavigate`→`useRouter` 변환.
- **수락 기준**: `src/pages/*.vue`, `src/stores/*.ts`, `src/api/*.ts`, `src/mocks/*` 모두 존재. `pnpm dev` 시 MSW 활성화 + Login → Series 플로우 동작.
- **관련 PRD**: `UI-A1-architecture.md` §1.2/§2/§3, `UI-01-lobby.md`, `UI-03-settings.md`, `UI-04-graphic-editor.md`
- **블로커**: B-068 완료 선행 필수

### [B-076] QA-LOBBY-06 기반 Vitest + Playwright 셋업
- **날짜**: 2026-04-10
- **teams**: [team1]
- **설명**: `QA-LOBBY-06-quasar-test-strategy.md` 를 기반으로 Vitest + @vue/test-utils + Playwright + MSW server mode 실제 셋업. `vitest.config.ts`, `playwright.config.ts`, `.github/workflows/frontend-test.yml` 작성.
- **수락 기준**: `pnpm test` 가 샘플 unit test 통과, `pnpm e2e` 가 최소 1개 E2E (로그인 → Series) 통과, GitHub Actions 에서 lint+typecheck+unit+e2e 모두 녹색.
- **관련 PRD**: `qa/lobby/QA-LOBBY-06-quasar-test-strategy.md`
- **⚠ 2026-04-14 비고**: `qa/` 폴더 삭제됨. 본 항목은 QA-LOBBY-06 실재 복원 또는 대체 전략(BS-0X 문서 하단 §검증 섹션) 확정 후 재평가 필요.

### [B-077] WSOP LIVE 기준 레포 실재 확인 (인프라)
- **날짜**: 2026-04-14
- **teams**: [conductor]
- **설명**: `C:/claude/wsoplive/` 및 `C:/claude/ebs/wsoplive/` 모두 실재하지 않음. 그러나 `ebs/CLAUDE.md §원칙 1` 은 해당 레포를 "WSOP LIVE 정렬" 의 기준 미러로 명시. 실증 불가 상태에서 팀 문서 구조(압축/분할) 결정이 근거를 갖지 못함. team1 문서 압축 검토(22개→7/10/15) 가 본 이슈로 인해 보류됨.
- **수락 기준**: (a) 레포 경로 확정 및 접근 가능 확인, 또는 (b) `ebs/CLAUDE.md §원칙 1` 수정으로 "정렬 원칙" 의존성 제거.
- **관련**: `team1-frontend/INDEX.md` §상태, `CCR-DRAFT-team1-20260414-deadlink-cleanup.md`

### [B-078] team1 specs 이미지 ↔ docs/00-reference 동기화 자동화
- **날짜**: 2026-04-14
- **teams**: [team1, conductor]
- **설명**: BS-02-lobby 이미지 13개를 미리보기 호환을 위해 `team1-frontend/specs/BS-02-lobby/visual/screenshots/` 에 로컬 복사함 (원본: `docs/00-reference/images/lobby/`). 워크스페이스 외부 `../../../` 경로가 일부 markdown 미리보기 도구에서 차단되므로 short relative path 가 필요. 원본 갱신 시 자동 동기화 스크립트 또는 hook 필요.
- **수락 기준**: `tools/sync_specs_images.py` 작성 + pre-commit 또는 CI 단계에서 drift 검출. team2/3/4 도 재사용 가능한 일반화.
- **관련**: Phase C (2026-04-14), `docs/00-reference/images/lobby/` (19종 ↔ team1 mirror)




### [NOTIFY-CCR-039] 검토 요청: audit_events.event_type 카탈로그 35값 공식 정의
- **알림일**: 2026-04-13
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-039-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/data/DATA-04-db-schema.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-040] 검토 요청: BS-01 refresh_token 전달 방식을 환경별 조건부로 통일
- **알림일**: 2026-04-13
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-040-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/specs/BS-01-auth/BS-01-auth.md, contracts/api/API-06-auth-session.md`
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


### [NOTIFY-CCR-043] 검토 요청: WSOP LIVE Sync 대상 엔드포인트 카탈로그 + GGPass 통합 전략
- **알림일**: 2026-04-14
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-043-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/api/API-01-backend-api.md` (Part II, WSOP LIVE Integration)
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


### [NOTIFY-CCR-049] 검토 요청: BlindStructure 관리 엔드포인트 추가 (WSOP LIVE 정렬)
- **알림일**: 2026-04-14
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-049-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/api/API-01-backend-api.md, contracts/data/DATA-02-entities.md`
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


### [NOTIFY-CCR-053] 검토 요청: Users 엔드포인트에 WSOP LIVE Staff 패턴 (Suspend/Lock/Download) 추가
- **알림일**: 2026-04-14
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-053-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/api/API-01-backend-api.md, contracts/data/DATA-02-entities.md, contracts/data/DATA-04-db-schema.md, contracts/specs/BS-01-auth/BS-01-auth.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-054] 검토 요청: WebSocket 이벤트 카탈로그 WSOP LIVE SignalR 정렬
- **알림일**: 2026-04-14
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-054-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/api/API-05-websocket-events.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기

## IN_PROGRESS

### [B-068] team1-frontend Quasar 프로젝트 실제 초기화
- **날짜**: 2026-04-10
- **teams**: [team1]
- **설명**: `team1-frontend/src/`가 `.gitkeep`만 포함하여 사실상 빈 상태. commit `9c45acf`가 "ebs_lobby 통합 완료"를 주장하지만 실제 소스 파일이 들어있지 않음. Quasar (Vue 3) + TypeScript 프로젝트를 실제로 초기화하고 기존 `C:/claude/ebs-archive-backup/07-archive/legacy-repos/ebs_lobby-react/` 또는 통합 이전 `ebs_lobby_web` 내용을 Quasar로 이식/재작성.
- **수락 기준**: `team1-frontend/src/` 하위에 Quasar 프로젝트 구조(`src/`, `quasar.config.js` 등) 존재, `pnpm dev` 또는 `quasar dev` 명령으로 Lobby 기본 화면이 로컬에서 부팅.
- **관련 PRD**: CLAUDE.md §Team 1, contracts/specs/BS-02-lobby/, team1-frontend/CLAUDE.md, `UI-A1-architecture.md`, `UI-04-graphic-editor.md`, `QA-LOBBY-06-quasar-test-strategy.md`
- **진행 상황 (2026-04-10)**: Phase A 완료 (UI-A1 아키텍처 문서 작성, UI-00 §9-12 확장, CLAUDE.md 보강). Phase D 진행 예정.

_기존 IN_PROGRESS placeholder 는 본 항목으로 대체_



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
- **변경 대상**: `contracts/api/API-01-backend-api.md`
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
- **변경 대상**: `contracts/api/API-01-backend-api.md`
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
- **변경 대상**: `contracts/specs/BS-05-command-center/BS-05-00-overview.md, contracts/api/API-01-backend-api.md`
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

## DONE

| ID | 제목 | 완료일 | 관련 |
|----|------|--------|------|
| B-069 | Team 1 frontend 기획서 critic revision — WSOP LIVE Confluence parity + Quasar 전환 정렬 + CCR-011/025 후속 반영 | 2026-04-10 | UI-00-design-system.md (Quasar 확정 + GE 이관), UI-01-lobby.md (§9 WSOP Parity Notes, 배너 APPLIED 전환), UI-03-settings.md (§1.1 Ownership & Boundary + ConfigChanged 흐름 + GE 허브 반영), team1-frontend/CLAUDE.md (Settings 6탭 + GE 범위 신설), QA-LOBBY-02/04/05 (DEPRECATED 배너). 드래프트: `ccr-inbox/archived/CCR-DRAFT-team1-20260410-wsop-parity.md` → **CCR-017 APPLIED**, `ccr-inbox/archived/CCR-DRAFT-team1-20260410-tech-stack-ssot.md` → **CCR-016 APPLIED**. 후속 반영 CCR: CCR-011 ge-ownership-move (GE Team 1 이관) APPLIED, CCR-025 bs03-graphic-settings-tab APPLIED. Plan: `C:/Users/AidenKim/.claude/plans/floofy-stargazing-wren.md` |
| B-070 | UI-A1-architecture.md 신규 작성 (Router/Pinia/API client/WS client/Mock/i18n/Build) | 2026-04-10 | `team1-frontend/ui-design/UI-A1-architecture.md` 신규. Vue Router 전체 트리(3계층 Lobby + Player 독립 + Settings 6탭 + GE 허브), Pinia 5 store 설계(auth/lobby/settings/ge/ws), axios client wrapper with CCR-019 Idempotency-Key auto-injection, WebSocket client with CCR-021 seq validation + replay, MSW 2.x mock 전략, vue-i18n 3 locale (ko/en/es), pnpm 빌드 명령. 약 600줄. |
| B-072 | UI-00 §9-12 확장 (Quasar 컴포넌트 매핑, 접근성, 성능, 공통 상태 패턴) | 2026-04-10 | `team1-frontend/ui-design/UI-00-design-system.md` §9 Quasar q-* 30+ 컴포넌트 매핑 표, §10 WCAG 2.1 AA 접근성(ARIA 랜드마크 + 키보드 단축키), §11 Core Web Vitals 성능 목표(FCP<1.5s, LCP<2.5s, TTI<3.5s, bundle<500KB), §12 Loading/Error/Empty 공통 상태 패턴 + FSM. 약 330줄 추가. |
| B-077 | team1-frontend/CLAUDE.md CCR-019/021 + Mock + i18n 보강 | 2026-04-10 | `team1-frontend/CLAUDE.md` §API 경계에 CCR-019 Idempotency-Key 자동 주입, §WebSocket 에 CCR-021 seq 검증 + replay, §Mock Server 신규, §i18n 신규, §Build 실제 pnpm 명령으로 교체. UI-A1 cross-reference 명시. |
| B-074 | QA-LOBBY-06-quasar-test-strategy.md 신규 | 2026-04-10 | `team1-frontend/qa/lobby/QA-LOBBY-06-quasar-test-strategy.md` 신규. Vitest unit 60% + @vue/test-utils component 30% + Playwright E2E 10% 피라미드, 10개 critical E2E 시나리오, MSW 재사용 전략, GitHub Actions CI workflow. 약 450줄. |
| B-078 | QA-LOBBY-03 GAP-L-009 Session restore UX 추가 | 2026-04-10 | `qa/lobby/QA-LOBBY-03-spec-gap.md` 요약 테이블에 GAP-L-009 Session restore UX 미정의 Medium IN_PROGRESS 추가. 상세 섹션 신설 (UI-01 §0.3 + §9.6 선반영, BS-01 lastContext 필드 보강 제안). |
| B-079 | UI-03 §Rules 탭 UI-04 cross-link | 2026-04-10 | `ui-design/UI-03-settings.md` L335 부근에 GEM-01~25 필드 전체는 UI-04-graphic-editor.md §5 참조 1줄 추가. Settings GFX 탭은 activated skin 의 메타데이터를 읽기 전용으로 노출하고 [Graphic Editor 열기] 버튼으로 허브로 이동하는 경계 명시. |
| B-080 | UI-04-graphic-editor.md 신규 작성 (CCR-011 APPLIED 기반 GE 허브 기획서) | 2026-04-10 | `team1-frontend/ui-design/UI-04-graphic-editor.md` 신규 (886줄). CCR-011/012/013/014/015/025 APPLIED 기반. §1 개요 + In/Out-of-scope, §2 라우팅(Hub+Detail), §3 3-Zone ASCII 와이어프레임(≤65자), §4 Use Case Flows(Upload/Activate+GameState 가드/Revert/Delete), §5 GEM-01~25 전체 25개 필드 매트릭스(Identity 3 / Resolution·Background 2 / Colors 9 / Fonts 6 / Animations 5), §6 Upload Dropzone(4단계 검증), §7 rive-js Preview(`@rive-app/canvas`), §8 Activate 흐름(6-state 버튼 머신 + WS skin_updated + Replay), §9 RBAC 3중 가드(UI gate + 라우터 + API 서버), §10 에러/로딩/빈 상태 9개 하위, §11 CCR footer, §12 연관 문서. |
