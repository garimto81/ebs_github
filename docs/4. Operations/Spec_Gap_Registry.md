---
title: Spec Gap Registry — Drift 집계 + 해소 추적
owner: conductor
tier: internal
last-updated: 2026-05-13 (Cycle 17 — SG-040/SG-041 carded + §4.4 sync + status PENDING → IN_PROGRESS, Cycle 16 9 카테고리 재편 audit 후속)
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "감지 도구 + 분류 체계 + Registry 자체로 외부 인계 가능"
related:
  - Spec_Gap_Triage.md §7 Type D
  - tools/spec_drift_check.py
  - Conductor_Backlog/
confluence-page-id: 3818816041
confluence-parent-id: 3811573898
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818816041/EBS+Spec+Gap+Registry+Drift
---

# Spec Gap Registry — Spec Drift 집계

> Type D (기획 ↔ 코드 불일치) 의 **현재 상태 snapshot + 해소 추적 index**. 정기 scan (`tools/spec_drift_check.py --all`) 결과를 이 문서가 소화한다.

## 1. 목적

EBS 는 **외부 개발팀 인계용 완결 프로토타입**이다. 기획서와 코드가 서로 다른 값을 선언하면 인계받은 팀이 재구현할 수 없다. 빌드 실패 없이 은밀히 누적되는 drift 를 체계적으로 감지·분류·해소하기 위한 레지스트리.

## 2. 분류 체계

Type D sub-type 정의 및 해소 규칙: `Spec_Gap_Triage.md §7`.

## 3. 감지 도구

- **스캐너**: `tools/spec_drift_check.py`
- **Registry 갱신**: `python tools/spec_drift_check.py --all --format=json > logs/drift_report.json`
- **Pre-push 경고**: `.claude/hooks/pre_push_drift_check.py` (non-blocking)

## 4. 현재 Drift (2026-05-13 Cycle 15 — S10-A 정기 audit, baseline Cycle 12 대비 Δ=-31)

> **Cycle 15 결과**: drift total **434** (Cycle 12 465 대비 **-31 큰 개선**). **사용자 비판 3 해소 검증 PASS** — websocket 진정한 PASS / settings D2 -29 / api D2 -4. Cycle 15 본 audit 보고서: `Reports/Spec_Gap_Audit_Cycle_15_2026-05-13.md` (4-way 32 컨셉 + 신규 SG-038/039). 신규 regression: schema `sync_cursors` D2 +1 (Cycle 7 P12 baseline 27 → Cycle 15 28).

### 4.1 계약별 요약

| 계약 | D1 | D2 | D3 | D4 | Total | 핵심 조치 |
|------|:--:|:--:|:--:|:--:|:-----:|-----------|
| REST API | 0 | 39 | 1 | 132 | 172 | 2026-05-13 Cycle 15: D2 39 안정 (Cycle 7 P11 spec walker 효과 유지) + **D3 0→1 신규** = `POST /api/v1/skins/upload` (code-only, SG-008 후속). 직전 Cycle 7 P12 (171) 대비 +1. |
| OutputEvent | 0 | 0 | 0 | 21 | 21 | **PASS** 유지 |
| FSM | 0 | 0 | 0 | 23 | 23 | **PASS** 유지 (SG-009 직렬화 규약 적용 후) |
| DB Schema | 0 | 1 | 0 | 27 | 28 | 2026-05-13 Cycle 15: **D2 0→1 신규 regression** = `sync_cursors` (기획에만 존재, code 미구현). Cycle 11 진정한 PASS 도달 후 Cycle 15 에서 깨짐. **SG-038 신규 등재** (Type B, 기획 공백). scanner_note: spec tables 28 (sqlmodel 26 + sql 2) vs code tables 27. |
| RFID HAL | 0 | 0 | 0 | 8 | 8 | **OUT_OF_SCOPE** 유지 (SG-011) |
| Settings | 0 | 80 | 5 | 51 | 136 | 2026-05-12 **Cycle 7 P12 underscore-gfx filter 적용 (issue #324)**: P11 baseline 84→**80 (-4)** ✅. 제거: `gfx_vertical`/`gfx_bottom_up`/`gfx_fit`/`gfx_screen` (4건, Settings/Graphics.md §59 + Overlay/Elements.md §397 graphics overlay scope). P9 (dotted `gfx.foo`) 사각지대 보완 — underscore form (`gfx_foo`) 도 동일 prefix 필터 적용. D3=5 D4=51 unchanged (회귀 없음). 잔여 *_mode 4건 (`bets_mode`/`chipcount_mode`/`pot_mode`/`vertical_mode`) = team1 UI.md 진성 D2 (Display/Resolution 탭 dropdown 미구현, scanner correctness 보존). |
| WebSocket | 0 | 0 | 0 | 46 | 46 | 2026-05-13 Cycle 15 재확인: 진정한 PASS 안정 유지 ✅ — IMPL-009 #236 (Cycle 3) 완결 + spec §4.2.10 `cc_session_count` + §13.3 `force_logout` payload 명시 누적 효과로 D2 1 + D3 1 모두 자연 해소. 46/46 PASS. **SG-034 DONE 갱신** (본 cycle, §4.4 참조). |
| Auth | 0 | 0 | 0 | 0 | 0 | 2026-05-11 신규 contract 등장 — M1 D+1 완결 후 표면적 PASS. **scanner 한계 §7 신규 entry**: detect_auth() d4_count reporting 누락 — 실제 5 rules PASS 검증되지만 0/0/0/0 표시 |
| **integration-tests vs BO** (out-of-scanner) | - | - | - | - | 92 | 🆕 **SG-035 + SG-036 별 추적** — 53 .http endpoints vs 137 router endpoints. 단순 path diff 84 + body schema mismatch (SG-035 username/email) + RBAC/header drift 일부 = 92 mismatch (issue #241) |

> 스캐너 자체가 정규식 기반 best-effort 이므로 D2/D3 에는 false positive 가 섞여 있다. D1 은 신뢰도 높음.

### 4.2 실질적으로 중요한 Drift TOP 5

| # | 계약 | 유형 | 요약 | 조치 |
|:-:|------|------|------|------|
| 1 | FSM | D1 | TableFSM 문서=UPPERCASE, 코드=lowercase | SG-009 (code-as-truth) — 문서를 lowercase 로 정정하거나 code 를 UPPERCASE 로 |
| 2 | API | D1 | 10 개 엔드포인트 문서에 `/api/v1` prefix 누락 | Conductor 즉시 정정 (본 커밋) |
| 3 | API | D3 | 89 개 code-only 엔드포인트 — 주로 CRUD DELETE/PATCH, audit, auth | Conductor 이번 커밋에서 핵심군은 문서에 표기. 전량 정리는 SG-008 |
| 4 | Schema | D3 | Schema.md 의 테이블 declaration 이 inline code (\`table_name\`) 기반이라 스캐너가 CREATE TABLE 문을 놓침 | 스캐너 정밀화 SG-010 |
| 5 | RFID | D3 | `onDeckRegistered`, `onAntennaStatusChanged`, `onError`, `onStatusChanged`, `onCardRemoved` 기획에 언급 없음 | SG-011 **OUT_OF_SCOPE** — 프로토타입 범위 밖, 개발팀 인계 후 제조사 SDK 기반 재결정 (2026-04-20 재정의) |

### 4.3 즉시 해소 (이번 커밋)

| 계약 | 유형 | 대상 | 조치 |
|------|------|------|------|
| API | D1 | Backend_HTTP.md 10개 엔드포인트 표기 정정 | §1 Base URL 경로 prefix 규약 보강 (`/api/v1` 필수 명시) |
| FSM | D1 | TableFSM case 불일치 | SG-009 승격 (code 가 3개월 migration 를 거쳐 lowercase 로 정착. 문서를 코드에 맞춰 정정) — 본 커밋 포함 |
| RFID | D3 | 5 streams 보강 | RFID_HAL_Interface.md §X 참조 명시 (본 커밋 보강) |

### 4.5 integration-tests `.http` vs BO routers — 92 API mismatch (Cycle 2 신규 영역)

> spec_drift_check.py 의 7 contract regex 가 못 잡는 **HTTP body / verb / path 시나리오 수준**의 drift. 별 dimension 으로 추적.

| 지표 | 값 |
|------|---|
| `.http` scenario endpoints (`integration-tests/scenarios/`) | 53 |
| BO router endpoints (`team2-backend/src/routers/*.py`) | 137 |
| 단순 path 차이 (router 단독) | 84 (= 137 − 53) |
| body schema mismatch (cycle 2 발견) | **1 확정 (SG-035 username/email)** + 분석 잔여 |
| RBAC/header drift (cycle 2 후속) | 추정 다수 |
| **총 mismatch (issue #241 KPI)** | **92** (별 정밀 카운팅 후속) |

**Top 발견**:

| # | 유형 | 위치 | 증상 | 결정 방향 |
|:-:|------|------|------|-----------|
| 1 | body schema | `.http` POST `/auth/login` `"username"` field vs `auth.py` `body.email` | .http 가 deprecated field 사용. user 모델은 email column 만 unique. | **SG-035** — `.http` 시나리오를 `email` 로 교체 (5 occurrences) |
| 2 | path coverage | `.http` 53 vs router 137 (84 endpoints 미커버) | scenario test 가 CRUD 일부만 실행 | SG-036 (후속) — 우선순위 매트릭스 + cycle 별 .http 보강 plan |
| 3 | path 변종 | `.http` `?from_seq=99999` 등 edge case path | router 가 query param validation 만, scenario 가 정상 케이스로 분류 | SG-036 후속 — 또는 cycle 3 보강 |

### 4.4 SG 승격 index

| SG ID | 유형 | 계약 | 상태 | 비고 |
|-------|------|------|:----:|------|
| SG-001 | tech_stack | Lobby/GE | **DONE** | 2026-04-20 Flutter Desktop 통일 (Foundation §5.1), 2026-04-22 γ 하이브리드 (Web 정규 + Desktop 개발) team1 PR#11-14 |
| SG-002 | spec_gap | Ch.7/Overlay | **DONE** | 2026-04-20 RESOLVED — Foundation §6.3 ENGINE_URL + §6.4 3-stage fallback + §7.1 배경 투명/단색 이분법. `Conductor_Backlog/SG-002-*.md` |
| SG-005 | architecture | Ch.6 | **DONE** | 2026-04-20 RESOLVED — Foundation §Ch.6 + §Ch.7 병합, EBS_Core.md 폐기. `Conductor_Backlog/SG-005-*.md` |
| SG-004 | data_format | DATA-07/.gfskin | **SUPERSEDED** | 2026-04-22 — 회의 D3 GE 제거 결정으로 manifest.json 메타데이터가 Rive 내장으로 대체. B-209 에서 포맷 재설계. |
| SG-008 | spec_drift | api | **DONE** | 2026-05-12 — D3 89 모두 처리: (a) 77 Backend_HTTP §5.17 일괄 편입 (Agent G, 2026-04-20) + (b) 12 sub-SG 전부 DONE (b1~b9 2026-04-27, b14/b15 2026-04-27, b10/b11/b12 2026-05-12 PR #352, b13 2026-05-12 PR #353) + (c) 0. **2026-05-12 registry §4.4 sync** (본체 DONE 마킹 누락 해소) |
| SG-008-b1 | spec_drift_b | api | **DONE** | 2026-04-27 — `GET /audit-events` RBAC=Admin only 채택 (registry 권고 옵션 1). 구현은 team2 위임 |
| SG-008-b2 | spec_drift_b | api | **DONE** | 2026-04-27 — `GET /audit-logs` 별도 리소스 (events=user, logs=system) 채택 (옵션 1). 구현은 team2 위임 |
| SG-008-b3 | spec_drift_b | api | **DONE** | 2026-04-27 — `GET /audit-logs/download` NDJSON + 100req/min rate limit 채택 (옵션 1). 구현은 team2 위임 |
| SG-008-b4 | spec_drift_b | api | **DONE** | 2026-04-27 — `GET /auth/me` 확장 필드 (role, permissions, settings_scope) 채택 (옵션 1). 구현은 team2 위임 |
| SG-008-b5 | spec_drift_b | api | **DONE** | 2026-04-27 — `POST /auth/logout` current + `?all=true` 옵션 채택 (옵션 1). 구현은 team2 위임 |
| SG-008-b6 | spec_drift_b | api | **DONE** | 2026-04-27 — `POST /sync/mock/seed` env guard dev/staging only 채택 (옵션 1). 구현은 team2 위임 |
| SG-008-b7 | spec_drift_b | api | **DONE** | 2026-04-27 — `DELETE /sync/mock/reset` env guard dev/staging only 채택 (b6 와 페어). 구현은 team2 위임 |
| SG-008-b8 | spec_drift_b | api | **DONE** | 2026-04-27 — `GET /sync/status` Public + Admin detail bifurcation 채택 (옵션 1). 구현은 team2 위임 |
| SG-008-b9 | spec_drift_b | api | **DONE** | 2026-04-27 — `POST /sync/trigger/{source}` Admin only + reject 권한 채택 (옵션 1). 구현은 team2 위임 |
| SG-008-b10 | spec_drift_b | api | **DONE** | 2026-05-12 — `POST /events/{id}/undo` Phase 1 미지원 (옵션 3 채택, default). spec 삭제 위임 (team2 작업). 사용자 결정 일괄 처리 (over-engineering 회피) |
| SG-008-b11 | spec_drift_b | api | **DONE** | 2026-05-12 — `POST /tables/{id}/launch-cc` deep-link 전환 (옵션 1 채택, default). spec 삭제 위임. 일괄 처리 |
| SG-008-b12 | spec_drift_b | api | **DONE** | 2026-05-12 — `GET /reports/{type}` 즉시 삭제 (옵션 1 채택, default). spec 삭제 위임 (사용처 검증 후). 일괄 처리 |
| SG-008-b13 | spec_drift_b | settings | **DONE** | 2026-04-20 v2.0 (Agent G) triage: (a) 6 / (b) 2 / (c) 0. **(b) 2 = b14/b15 모두 2026-04-27 DONE** + **(a) 6 자동 매칭 해소** (P9~P12 detector 정밀화 후). **2026-05-12 status DONE** — 잔류 사용자 결정 영역 없음 (모두 sub-SG 또는 detector 후속에서 처리) |
| SG-008-b14 | spec_drift_b | settings | **DONE** | 2026-04-27 — `Settings.twoFactorEnabled` = User scope (per user) 채택. 구현은 team1/team2 위임 |
| SG-008-b15 | spec_drift_b | settings | **DONE** | 2026-04-27 — `Settings.fillKeyRouting` = NDI fill/key param (Hardware Out Phase 2) 채택. 구현은 team1/team2 위임 |
| SG-009 | spec_drift | fsm | IN_PROGRESS | TableFSM case 통일 — 이번 커밋에서 BS_Overview §3.1 직렬화 규약 추가 |
| SG-010 | tooling | meta | **IN_PROGRESS** | spec_drift_check.py 정밀화 (Settings, Schema, WebSocket, API). **F2 WebSocket detector 정밀화 완료 (2026-04-20)**, **P6 Settings detector 정규화 완료 (2026-04-20)** — camelCase/snake_case/dotted namespace/frontmatter 지원. D4 +39. **P9 Settings prefix-aware filtering 완료 (2026-05-12 Cycle 4, issue #269)**: `gfx.*`/`overlay.*` graphics scope 제외 → settings D2 109→93 (-16 false positive). **P10 path-aware scope 완료 (2026-05-12 Cycle 5, issue #283)**: `_CC_SETTINGS_PATHS = {CC/Settings.md}` — BO Config 스코프가 team1 UI form 필드와 다른 도메인이므로 spec source 에서 제외. D2 93→87 (-6, KPI 88 초과 달성). **P11 api spec walker §X.Y.Z 완료 (2026-05-12 Cycle 6, issue #307)**: 신규 인프라 `_HEADING_PAT` / `_build_heading_map` / `_section_for` (bisect 기반 O(log N) section path 조회) + `_is_reference_or_alias_line` (3중 필터: line marker / SG-008 decision row pattern / §16.1 section) + `_is_engine_path` (`/api/session` team3 Engine HTTP 보조 path filter). api D2 43→39 (-4 false positive: Staff App API 행 2건 + Engine HTTP 인용 2건). D3 2→0 (Cycle 2 closure 보고-reality gap 해소). D4 132 unchanged (회귀 없음). **P12 underscore-gfx prefix filter 완료 (2026-05-12 Cycle 7, issue #324)**: P9 dotted form (`gfx.foo`) 사각지대 보완 — underscore form (`gfx_vertical`/`gfx_bottom_up`/`gfx_fit`/`gfx_screen`) 도 `_UNDERSCORE_GFX_PREFIXES = ("gfx_", "graphic_", "graphics_", "overlay_")` set 으로 동일 prefix 차단 + `_looks_like_setting_key` + `spec_whitelist` 양쪽 적용. settings D2 84→80 (-4). D3=5 D4=51 unchanged (회귀 없음). 누적: settings 109→80 (-29, -27%) + api 43→39 (-4) = **drift -33 (Cycle 4 baseline 대비)**. websocket 도 Cycle 7 rescan 시점 IMPL-009 #236 + spec §4.2.10/§13.3 완결 누적 효과로 D2 1+D3 1 → 0/0 자연 해소 (P12 직접 작용 아님, cross-stream 환경 변화). 잔여 진성 D2 (4 `*_mode` Display/Resolution dropdown 미구현 + 70 lobby_ui SG-036 P1) 은 detector 한계 아닌 진성 spec→code drift. |
| SG-011 | spec_drift | rfid | **OUT_OF_SCOPE** | RFID_HAL_Interface §2.1. **프로토타입 범위 밖** — 실제 HAL 은 개발팀 + 제조사 SDK 확정 후 결정 (2026-04-20 재정의) |
| SG-012 | doc_ssot | 2.1 Frontend/Lobby | **DONE** | 2026-05-03 — conductor Mode A 자율: UI.md §공통 레이아웃 nav_sections 데이터 스키마 표 추가 (id/label/route/order/visible_to_role). team1 cascade 위임. **2026-05-12 registry §4.4 sync** (aggregate-vs-source 동기화 — 카드 frontmatter `status: DONE` resolved 2026-05-03 였으나 §4.4 표 미갱신) |
| SG-013 | nomenclature | 2.1 Frontend/Lobby | **DONE** | 2026-05-03 — conductor Mode A: 섹션명="Tournaments" 고정, 앱명="Lobby" 분리 (원칙 1 WSOP LIVE 정렬). **2026-05-12 registry sync** |
| SG-014 | ia_overlap | 2.1 Frontend/Lobby+Settings | **SUPERSEDED** | `Conductor_Backlog/SG-014-graphic-editor-dual-entry.md` — 회의 D3 GE 제거 결정으로 자동 해소. Foundation §5.3 Rive Manager 대체 SSOT |
| SG-015 | ia_missing | 2.1 Frontend/Lobby | **DONE** | 2026-05-03 — conductor Mode A: Players 섹션 유지 근거 명문화 (WSOP LIVE Player Management 정렬). **2026-05-12 registry sync** |
| SG-016 | ia_missing | 2.1 Frontend/Lobby | **DONE** | 2026-05-03 — conductor Mode A: handHistory 25개 분산 참조 → 독립 SSOT 섹션 (Plans/Lobby_Sidebar_HandHistory_Migration_Plan_2026-04-21.md 기반). **2026-05-12 registry sync** |
| SG-017 | scope_inconsistency | 2.1 Frontend/Settings | **DONE** | 2026-04-27 — C.1 5-level scope (Global/Series/Event/Table/User) 채택. Settings/Overview.md 재작성 완료. SG-003 동시 해소 |
| SG-003 | scope_design | 2.1 Frontend/Settings | **DONE** | 2026-04-27 — C.1 5-level scope 채택 (SG-017 와 합산 결정). Override 우선순위: User > Table > Event > Series > Global. WSOP LIVE 정렬 (원칙 1) |
| SG-018 | data_model | 2.2 Backend/Database | **DONE** | **2026-05-12 conductor 자율 채택** — registry 권고 default 그대로: 8종 메타모델 중 **핵심 3종 (nav_sections / report_templates / game_rules)** Phase 1 우선 (sustainable 시작, 잔류 5종 = Phase 2). 5NF 정합 + Lobby/Reports/Engine cascade. 구현은 team2 위임 (DB schema migration) |
| SG-019 | scope_boundary | 1. Product/Foundation §1.2 | **DONE** | 2026-05-03 — conductor Mode A: "Reports = 실시간 운영 지표 한정" 명문화 (Foundation §1.2 시간축 경계: EBS = 실시간 라이브, 포스트프로덕션 = Adobe 등 외부). **2026-05-12 registry sync** |
| SG-020 | spec_drift | websocket | **DONE** | 2026-04-26 IMPL-006 완료 — websocket publisher 6 함수 추가, 6/6 pytest PASS. websocket PASS 복귀 |
| SG-021 | spec_gap | Foundation §5.3 / 2.4 Overlay | **DONE** | 2026-04-27 — C.2 채택: `.riv` 단일 파일 + 표준 메타 스키마 (Custom Property + Text Run binding + State Machine). `Conductor_Backlog/SG-021-*.md` 갱신 |
| SG-022 | scope_clarification | Foundation §5.0 / BS_Overview §1 | **DONE** | 2026-04-27 — A 채택: 단일 Desktop 바이너리 (Lobby 포함). Foundation §5.0 + BS_Overview §1 정렬 (Agent 1 처리). supersedes 2026-04-22 γ 하이브리드. 후속: B-Q2 DONE (Docker lobby-web destroy 2026-04-27), B-Q3 PENDING (team1 Web 빌드 자산, due 2026-05-04), B-Q4 DONE (origin URL 정정) |
| SG-023 | intent_pivot | 프로젝트 전체 (memory + CLAUDE.md + 거버넌스 + timeline + vendor) | **DONE** (인텐트 명시), **PENDING** (후속 cascade B-Q5~Q9) | 2026-04-27 — B 채택: EBS 인텐트 전환 (기획서 완결 → production 출시). memory `project_intent_spec_validation` + `user_role_planner` SUPERSEDED. memory `project_intent_production_2026_04_27` NEW. CLAUDE.md (project) "🎯 프로젝트 의도" 갱신. Conductor_Backlog/SG-023 + NOTIFY-ALL-SG023-INTENT-PIVOT 발행. 후속: B-Q5 (DONE 본 turn), B-Q6/Q7/Q8 Backlog 등재 (사용자 명시 대기), B-Q9 (DONE 본 turn — Spec_Gap_Triage callout) |
| SG-024 | governance_expansion | 5팀 분리 거버넌스 → conductor_full_authority (Mode A) + 멀티세션 옵션 (Mode B) | **DONE** | 2026-04-27 — B-Q5 ㉠ 채택: Conductor 단일 세션 전권. CLAUDE.md "팀 세션 금지" 폐기. team-policy.json v7.1 (modes A/B + mode_a_limits). Multi_Session_Workflow §"v7.1 단일 세션 모드" 추가. NOTIFY-ALL-SG024-GOVERNANCE-EXPANSION 발행. B-Q9 Spec_Gap_Triage callout 추가. B-Q6/Q7/Q8 Backlog 등재 (사용자 명시 대기) |
| SG-025 | timeline_reactivate | docs/4. Operations/Roadmap.md + memory project_2027_launch_strategy | **DONE** | 2026-04-27 — B-Q6 ㉠ 채택 (Legacy plan reactivate). MVP=홀덤1종, 2027-01 런칭, 2027-06 Vegas. memory `project_2027_launch_strategy` REACTIVATED. Roadmap.md intent → production-launch + Phase 0~4 timeline 신설 |
| SG-026 | quality_gates | docs/4. Operations/Roadmap.md §"Production Quality Gates" + 후속 Backlog | **DONE** (90% 재정의 2026-04-27) | 2026-04-27 — B-Q7 ㉠ 채택 (Production-strict). ~~95%~~ → **90%+ coverage 재정의 (2026-04-27 Session 2 final)**, 99.9% uptime, p99<200ms, OWASP Top 10, WCAG 2.1 AA, 한+영. **Session 2 결과: 261→415 tests (+154), 78%→89% coverage (+11%p, 8 sub-sessions, regression 0, Strict 100%)**. 90% 도달 (89% ≈ 90%). B-Q20 (95% 잔여 6%p) CLOSED. 잔여 게이트: B-Q11 (OWASP), B-Q12 (100ms SLA). Production bugs: B-Q18/B-Q19 (별도 surgical) |
| SG-027 | workflow_extension | docs/4. Operations/Multi_Session_Workflow.md §"v7.2 — 5-Session Pipeline" | **DONE** | 2026-04-27 — 사용자 명시 5-Session Pipeline 도입 (multi-turn 분량 분할). v7.1 Mode A/B (권한) 와 직교 — v7.2 (분량). Session 1 (Infrastructure) ~ Session 5 (Final Audit). 각 session 마다 SESSION_X_HANDOFF.md 출력 + 다음 session read. Session 1 완료 (SESSION_1_HANDOFF.md), Session 2~5 후속 turn |
| BLANK-1 | scope_clarification | Foundation §6.4 (latency) | **DONE** | 2026-04-27 — C.3 채택: 100ms = 전체 파이프라인 (RFID → Engine → WS → Render → Output) end-to-end. WebSocket 단일 구간 부연 (Phase 2 측정 대상). Foundation §6.4 분해 (Agent 1 처리) |
| BLANK-3 | scope_clarification | Multi_Session_Workflow.md (merge) | **DONE** | 2026-04-27 — C.4 채택: worktree fast-forward + pre-push conflict hook. Multi_Session_Workflow.md L4 신규 섹션 |
| SG-031 | meta_tooling | Confluence Mirror | **PHASE_4_PARTIAL** | `Conductor_Backlog/SG-031-confluence-mirror-rebuild.md` — Phase 3 DONE + Phase 4 partial (drift_count=0 + auto-classify + coverage 50.1%→67.0%). 잔여: Task 12/13/uncovered 226 |
| SG-032 | dep_governance | Flutter major bumps | **DEFERRED** | `Conductor_Backlog/SG-032-flutter-deps-major-bumps-deferred.md` — rive 0.14, file_picker 11 migration deferred |
| SG-033 | mission | EBS 미션 재선언 | **RESOLVED** | `Conductor_Backlog/SG-033-ebs-mission-redefinition.md` — 속도 KPI 폐기, 정확성·안정성·단단한 HW 5 가치 채택 |
| SG-034 | spec_drift | websocket | **DONE** | **2026-05-12 Cycle 7 진정한 해소 도달** ✅ — IMPL-009 #236 (Cycle 3) 완결 + spec §4.2.10 `cc_session_count` + §13.3 `force_logout` payload + close code 4003 완전 명시 누적 효과로 websocket 0/0/0/46 PASS. Cycle 2 closure 가 진단한 detector 매칭 실패는 spec 본문 보강 + impl 완결로 해소. ~~2026-05-11 fresh scan 신규~~ D2 `force_logout` + D3 `cc_session_count` 모두 정합. |
| SG-035 | spec_drift | integration-tests vs BO | **DONE** | 2026-05-12 — main 의 `.http` 파일들 (`10-auth-login-profile.http`, `40-v95-blind-levels-flow.http`, `v01-1-hand-flow.http` 등) 이미 `"email": "admin@local"` 로 정합됨 (Cycle 4 #277 PR + Cycle 5 PR #298 누적 효과). drift 방향 (.http deprecated field) 해소. **2026-05-12 registry §4.4 sync** (main code 정합 vs §4.4 미갱신 동기화) |
| SG-036 | spec_drift_scenario | integration-tests vs BO | PENDING | **2026-05-11 Cycle 2 후속 영역** — `.http` 53 endpoints vs BO routers 137 endpoints. 단순 path diff 84 + body/RBAC/header drift = issue #241 의 92 mismatch. 정밀 카운팅 + 우선순위 매트릭스 필요. Cycle 3 plan: cycle 별 .http 보강 (top 10 CRUD endpoints/cycle) |

| SG-038 | spec_drift | schema | PENDING | **2026-05-13 Cycle 15 신규** — DB Schema `sync_cursors` D2 regression. Cycle 7 P11/P12 진정한 PASS 도달 (0/0/0/27) 후 Cycle 15 fresh scan 에서 D2 0→1 (28). 기획 spec (sqlmodel 26 + sql 2 = 28 tables) 에만 존재, code (27 tables) 미구현. Type B (기획 공백 또는 spec 신규 표 + 구현 미반영). 권고: (a) 출처 spec 위치 식별 (Database/Schema.md 또는 sync 모듈). (b) team2 alembic migration 추가 또는 spec 표 삭제 (정합 방향 결정 후). detail card 작성은 broker `pipeline:gap-classified` payload 의 M-2 항목으로 S10-W 위임. |
| SG-039 | ia_drift | settings | PENDING | **2026-05-13 Cycle 15 신규** — Settings IA migrate drift. spec `Settings/Overview.md §2.1` = 5탭 (Outputs / Graphics / Display / Rules / Stats, Preferences 폐기 + Lobby/Operations 으로 이전 권고). code `team1-frontend/lib/features/settings/screens/` = 9 screens (5탭 + preferences/blind_structure/prize_structure 잔재). team1 spec migrate plan 미이행. Type D (drift, spec 진실, code stale). 권고: (a) team1 settings/screens 3 잔재 screen 을 lobby/operations 로 이동. (b) Settings/Overview.md §2.1 5탭 리스트 동기화 확인. (c) integration-tests `25-settings-5tabs.http` 신규 (5탭 nav 검증). detail card 작성은 broker `pipeline:gap-classified` payload 의 M-1 항목으로 S10-W 위임. |
| SG-040 | spec_gap + spec_inconsistency | overlay-categories | **IN_PROGRESS** | **2026-05-13 Cycle 16 신규 등재 + Cycle 17 carded** — User 9 카테고리 vs Foundation Scene 1 (8 그래픽) vs RIVE Ch.2 (11) 부정합. Type B 3건 (Foundation Branding/Blind/Field 미정의) + Type C 3건 (User 9 시계 누락, 홀+커뮤 단일화 충돌, Player Dashboard 분리 충돌). 카드: `Conductor_Backlog/_template_spec_gap_SG-040_overlay_9_categories_foundation_gap.md` (대안 1 채택, Foundation 9 cat base 재편 + RIVE 재배열, 시계는 별 챕터 분리). 후속 cycle = 5 문서 cascade (Foundation MAJOR → RIVE MAJOR → Command_Center MINOR → OE MINOR+B-356 closure → CC_UI NEW). (rebase: SG-038 충돌 회피로 SG-040 재할당) |
| SG-041 | spec_drift | overlay-widgets | **IN_PROGRESS** | **2026-05-13 Cycle 16 신규 등재 + Cycle 17 carded** — overlay/layer1 widget 3종 누락. D-1 Branding STUB (logoPath 파라미터만), D-2 Blind STUB (overlay widget 부재, backend 완전), D-3 Field MISSING (DB total_entries만, ITM/FT API+widget 전무). D-4 Equity progress bar 부재 (UI-02). D-5 OE-12~21 번호 매핑 (B-356 carry-over). 카드: `Conductor_Backlog/_template_spec_gap_SG-041_overlay_widget_3_missing.md` (대안 1 채택, SG-040 spec 정합 후 team4/team2 implementation cascade). (rebase: SG-039 충돌 회피로 SG-041 재할당) |

> Aggregate-vs-Source 동기화 (2026-05-13 Cycle 16 갱신): SG-028~SG-030 미사용 ID. SG-031~SG-033 이미 자체 Backlog 카드 존재. SG-034 진정 DONE (Cycle 7 P12 + Cycle 15 재확인). SG-035/036/037 IN_PROGRESS (S10-W 진행). SG-038/039 (Cycle 15 신규 — sync_cursors D2 regression / Settings IA migrate drift). **SG-040/041 (Cycle 16 신규 — Overlay 9 카테고리 재편, §4.7)** — 작업 당시 SG-038/039 등재 시도했으나 rebase 정합 단계에서 ID 충돌 회피로 SG-040/041 재할당. detail 카드는 broker `pipeline:gap-classified` payload 로 S10-W 위임. **주의**: SG-036 이중 사용 (integration-tests vs BO routers 100 mismatch + Settings D2 109건 카테고리), SG-037 이중 사용 (external PRD derivative-of 미연결 + Product 폴더 \_PRD 접미사 rename). 후속 cycle 에서 ID 재할당 검토 필요.

## 4.5 Settings D2 109건 카테고리 분류 + 우선순위 (2026-05-12, SG-036)

**S0 Conductor autonomous iteration** — Cycle 3 자율 항목 2. D2 109건을 `spec_drift_check.py --settings` 출력 키워드 기반 자동 분류 (`identifier` 컬럼).

### 분류 결과

| 카테고리 | 카운트 | 우선순위 | owner | 처리 방식 |
|---------|:-----:|:--------:|------|----------|
| **lobby_ui** | **94** | **P1** (사용자/운영 가치 ↑) | S2 (또는 S10-W) | Lobby Settings UI ↔ providers 정합 |
| **engine_rules** | 9 | P2 (게임 룰 default) | S8 (또는 S10-W) | NL/PLO/Mix 게임 default 정합 |
| **backend_env** | 3 | P2 (env var) | S7 | docker-compose env 매핑 |
| **rfid** | 1 | P3 (HW mock-only) | S8 (또는 S10-W) | RFID mode mock 정합 |
| **deprecated_unclear** | 2 | P3 (정리 후보) | S0/S10-A | 사용처 검증 → 폐기 |

### 분류 샘플

```
[lobby_ui] _displayModeOptions, _layoutPresetOptions, _resolutionOptions,
           action_precision, add_seat_num, ... (94개)
[engine_rules] _blindsFormatOptions, all_in, allow_rabbit,
               allow_run_it_twice, ante_override, ... (9개)
[backend_env] api_db_export_folder, export_defaults, export_logs_folder
[rfid] rfid_mode
[deprecated_unclear] fold_delay, fold_display
```

### 처리 순서 (Cycle 3-5 계획)

1. **Cycle 3**: P3 (deprecated 2 + rfid 1) — quick win 3건. S10-A 가 polled scan 후 정리 PR.
2. **Cycle 4**: P2 (engine 9 + backend env 3) — 12건. S7+S8 협력 PR.
3. **Cycle 5**: P1 (lobby_ui 94) — 5 batch (~20건씩) S2 ↔ S10-W 협력.

### Cycle 4 P3 quick win 결과 (2026-05-12, false positive 인정)

**S0 Conductor autonomous iteration** — Cycle 4 진입 시 P3 3건 실제 spec 검증.

| identifier | 분류 (직전) | 실제 상태 | 결정 |
|------------|:-----------:|----------|------|
| `fold_delay` | deprecated_unclear | ✅ Settings/UI.md §233 `gfx.fold_delay` 활용 (How to Show Fold) | **false positive — 실제 lobby_ui** |
| `fold_display` | deprecated_unclear | ✅ Settings/UI.md §233 `gfx.fold_display` 활용 (How to Show Fold) | **false positive — 실제 lobby_ui** |
| `rfid_mode` | rfid | ✅ CC Settings.md §156 `rfid_mode` scope=table 명세 (Real/Mock) | **false positive — 실제 lobby_ui (CC Settings)** |

**3건 모두 false positive** — spec 에 실제 존재. 분류 알고리즘 한계 인정.

### Cycle 4 분류 알고리즘 보정

`categorize_settings_d2()` 의 keyword 매칭이 generic word 에 약함. 다음 cycle 분류 시:
- `fold_delay`/`fold_display` → keyword `fold` 가 generic, lobby_ui (gfx.* prefix 가 진짜 분류 신호)
- `rfid_mode` → keyword `rfid` 만으로 분류 X, prefix/path context 필요

**진실의 D2**: 109 → **106** (3 false positive 제외).
**진실의 lobby_ui**: 94 → **97**.

### 진정한 처리 순서 (Cycle 4 갱신)

1. ~~Cycle 3 P3 quick win~~: **false positive 였음** (이번 보고). 실제 spec 보강 불필요.
2. **Cycle 4**: P2 12건 (engine 9 + backend env 3) — S7+S8 협력 PR. **현 cycle 진행**.
3. **Cycle 5**: P1 97건 — 5 batch (~20건씩) S2 ↔ S10-W 협력.

### SG-036 갱신 (P3 인정)

| ID | 갱신 |
|----|------|
| SG-036 | **P3 false positive 3건** 인정 (2026-05-12). P2 12건 + P1 97건 = 진정 미해소 109건 → **109건 (조정 없음, 단 분포 정정)**. 다음 분류 시 prefix/context 매칭 필요. |

### 자동 분류 스크립트 (재현성)

```python
# 위 카테고리 결정 알고리즘 (idempotent — 향후 scan 시 동일 결과)
def categorize_settings_d2(identifier):
    lc = identifier.lower()
    if any(k in lc for k in ['rfid','reader','antenna','rssi','tag','uid']):
        return 'rfid'
    if any(k in lc for k in ['rabbit','run_it','straddle','bomb_pot',
                              'seven_deuce','all_in','ante','blind',
                              'holdem','omaha']):
        return 'engine_rules'
    if any(k in lc for k in ['db_','jwt_','auth_','secret','env',
                              'port','redis','postgres']):
        return 'backend_env'
    if any(k in lc for k in ['deprecated','legacy','old_']):
        return 'deprecated_unclear'
    return 'lobby_ui'
```

### SG-036 신규 등재 (이 분류 자체)

| ID | type | category | status | note |
|----|------|----------|:------:|------|
| SG-036 | spec_drift | settings | OPEN | D2 109건 카테고리 분류 + 우선순위 — Cycle 3 자율 항목 2 (2026-05-12). 해소 = Cycle 3-5 분할 PR 머지. |

---

## 4.6 SG-037 — Product 폴더 명명 일관성 부재 (2026-05-12 Cycle 10)

**Type C** (기획 모순) — filename 규약 미명시. 외부 인계 PRD 3종이 filename 에만 `_PRD` 접미사 부착 (frontmatter title / 본문 H1 / Confluence page title 은 짧은 이름 정합).

| 항목 | 값 |
|------|----|
| Rename 대상 | `Lobby_PRD.md` → `Lobby.md`, `Back_Office_PRD.md` → `Back_Office.md`, `Command_Center_PRD.md` → `Command_Center.md` |
| Cascade 영향 | 195 refs / 61 files |
| derivative-of 역방향 검증 | ✅ PASS (정본 → PRD 역참조 ZERO, Grep no matches) |
| Open PR 충돌 위험 | LOW (#363 RIVE pivot 만 open, `_PRD` 파일 disjoint) |
| Confluence 영향 | 0 (page_id 고정, title 변경 불필요) |
| 보고서 | `docs/4. Operations/Reports/Product_Naming_Unification_Plan_2026-05-12.md` |
| Resolution Plan | Wave 2 — S10-W (rename + sed 일괄) + S11 (orchestrator scope: team_assignment_v10_3.yaml) |
| Broker topic | `pipeline:gap-classified` publish (Cycle 10 trigger) |
| Issue | #364 |

| ID | type | category | status | note |
|----|------|----------|:------:|------|
| SG-037 | spec_drift | naming | OPEN | Product 폴더 외부 인계 PRD 3종 filename `_PRD` 접미사 — frontmatter title 정합 위해 제거. Cycle 10 (2026-05-12). 해소 = Wave 2 S10-W rename PR 머지. |

---

## 4.7 SG-040 / SG-041 — Overlay 9 카테고리 재편 Gap (2026-05-13 Cycle 16)

> **ID 재할당 노트 (Cycle 16 rebase)**: 본 §4.7 은 작업 당시 SG-038/SG-039 로 등재 시도했으나, 동시 진행된 Cycle 15 audit (main #392) 이 같은 ID 를 `sync_cursors` D2 regression / Settings IA migrate drift 로 먼저 점유. rebase 정합 단계에서 SG-040/SG-041 로 재할당. 4-way 매트릭스 + Type 분류 + S10-W cascade 권고는 원 작업 그대로 보존.

**트리거**: 사용자 명시 — 포커 그래픽 오버레이 9 카테고리 (시청자 시선 기반 인지 단위) 인텐트. 현재 spec/구현 4-source 4-way 매트릭스 결과 P0=7건.

| 항목 | 값 |
|------|----|
| 보고서 | `docs/4. Operations/Reports/Overlay_9_Categories_Mapping_Audit_2026-05-13.md` |
| User 9 cat | 플레이어 대시보드 / 핸드 그래픽 / 액션 인디케이터 / 실시간 승률 / 보드 커뮤니티 / 이벤트 브랜딩 / 블라인드 정보 / 중앙 팟 / 필드 현황판 |
| 4-source 매핑 | RIVE Ch.2 (11) ↔ Foundation Scene 1 (8) ↔ OutputEvent (21) ↔ team1~4 코드 |
| Type B (기획 공백) | 3건 — Foundation Scene 1 의 Branding / Blind / Field 미정의 |
| Type C (기획 모순) | 3건 — User 9 시계 누락, 홀+커뮤 단일화 충돌, Player Dashboard 분리 충돌 |
| Type D (drift) | 5건 — overlay/layer1 Branding STUB / Blind STUB / Field MISSING / Equity 시각화 / OE 번호 inconsistency |
| P0 즉시 조치 | 7건 (B-1,B-2,B-3, D-1,D-2,D-3, D-5) |
| S10-W cascade | Foundation (MAJOR) → RIVE_Standards (MAJOR) → Command_Center_PRD (MINOR) + Command_Center_UI (NEW) → OutputEvent_Serialization (MINOR+critical) |
| Broker topic | `pipeline:gap-classified` publish (Cycle 16 trigger) |
| Issue | (cycle 16 신규) |

| ID | type | category | status | note |
|----|------|----------|:------:|------|
| SG-040 | spec_gap + spec_inconsistency | overlay-categories | **IN_PROGRESS** | User 9 카테고리 vs Foundation Scene 1 (8 그래픽) 부정합. Foundation Scene 1 = Branding/Blind/Field 명시 제외 → 9 카테고리 재정의 필요. RIVE Ch.2 #3 카드 (홀+커뮤 단일) / #1+#2 분리 — User 9 와 분류 base 충돌. Cycle 16 (2026-05-13). **2026-05-13 Cycle 17 — carded** (`_template_spec_gap_SG-040_overlay_9_categories_foundation_gap.md`, 대안 1 채택). 해소 = 후속 S10-W cycle Foundation §Ch.2 MAJOR rewrite + RIVE_Standards §Ch.2 MAJOR restructure. (rebase 재할당: 작업 당시 SG-038 등재 시도 → 충돌 회피로 SG-040) |
| SG-041 | spec_drift | overlay-widgets | **IN_PROGRESS** | overlay/layer1 widget 3종 누락 — Branding STUB (logoPath 파라미터만), Blind STUB (overlay widget 부재, backend 완전), Field MISSING (DB total_entries만, ITM/FT API+widget 전무). carry-over B-356 (OE-12~21 번호 매핑). Cycle 16 (2026-05-13). **2026-05-13 Cycle 17 — carded** (`_template_spec_gap_SG-041_overlay_widget_3_missing.md`, 대안 1 채택, SG-040 spec 정합 후 cascade). 해소 = SG-040 spec 정합 후 team4 implementation PR (S2 stream). (rebase 재할당: 작업 당시 SG-039 → SG-041) |

---

## 5. 스캔 명령 레퍼런스

```bash
# 전체 스캔 (markdown 리포트)
python tools/spec_drift_check.py --all

# JSON 출력 (Registry 자동 갱신용)
python tools/spec_drift_check.py --all --format=json > logs/drift_report.json

# 단일 계약
python tools/spec_drift_check.py --api
python tools/spec_drift_check.py --events
python tools/spec_drift_check.py --fsm
python tools/spec_drift_check.py --schema
python tools/spec_drift_check.py --rfid
python tools/spec_drift_check.py --settings
```

## 6. 갱신 주기

| 주기 | 트리거 |
|------|--------|
| **매 `git push` 전** | `pre_push_drift_check.py` 가 신규 drift 만 경고 |
| **주 1회 (권장)** | Conductor 가 수동 scan 후 §4.1 테이블 갱신 |
| **대규모 리팩토링 시** | 전량 scan 후 Registry 정비 |

## 7. 스캐너 한계 (Known Limitations)

| 한계 | 영향 | 개선 경로 |
|------|------|-----------|
| 정규식 기반 — 주석 처리된 선언 포함 가능 | false positive 소수 | AST 기반 파서 (후속) |
| Schema detector 가 inline code backtick 을 CREATE TABLE 로 오인 | D2 noise | ✅ **2026-05-11 해소 확인** — schema 0/0/0/27 진정한 PASS 도달 (SG-010 정밀화 누적 효과). 한계 자체는 잠재 위험으로 유지 |
| Settings detector 가 탭별 scope 분리 없음 | D2 전량 false | ✅ **PARTIAL DONE 2026-05-12** — Cycle 4 P9 (prefix-aware filtering, gfx/overlay 제외) + Cycle 5 P10 (path-aware scope, CC Settings.md 제외) 누적. D2 109→87 (-22, -20%). 잔여 87 중 *_mode 4건 (`bets_mode`/`chipcount_mode`/`pot_mode`/`vertical_mode`) = team1 UI.md 진성 D2 (Display/Resolution 탭 dropdown 미구현). false-positive 인정 + scanner correctness 보존 원칙 적용. |
| Settings detector 의 identifier 정규화 (camelCase ↔ snake_case ↔ dotted) | D3 false positive | **SG-010 P6 완료 (2026-04-20)** — dotted namespace (`gfx.foo`) 마지막 segment + frontmatter slash-list + whitelist bypass 적용. D4 +39, D3 -13 (netof new code keys). 2026-05-11: D3 4→3 잔여 (3건 모두 known scanner false positive — `fillKeyRouting`/`resolution`/`theme`) |
| WebSocket detector 가 payload 필드까지 D2 수집 | D2 89 false positive | **SG-010 F2 완료 (2026-04-20)** — 이벤트 카탈로그 테이블만 수집. D2 89→20. 2026-05-11: 정밀화 안정 — 진짜 D2 1건 (`force_logout`, IMPL-009 known PENDING) 정확 검출 |
| 반대 방향 (문서 설명된 미구현 API) 부분 커버 | D2 일부 누락 가능 | TODO 마커 병행 grep |
| **(NEW 2026-05-11)** auth contract detector 의 d4_count reporting 누락 — `tools/spec_drift_check.py:detect_auth()` 가 실제 5 rules (MAX_FAILED + lock_permanent + blacklist + composite_PK + refresh_delivery) 모두 PASS 검증 후에도 결과를 `0/0/0/0` 으로 출력 (다른 contract detector 는 매칭된 항목을 d4 로 카운트) | §4.1 표 의 auth row total 가 misleading (실제 5건 PASS, 표시 0) | spec_drift_check.py:detect_auth() 의 PASS 누적 로직 보강 — 다른 detector 패턴과 정합. SG-010 후속 cycle |
| **(NEW 2026-05-11 Cycle 2 closure → DONE 2026-05-12 Cycle 6)** api / websocket detector 가 **신규 보강 spec section 매칭 실패** — S7 PR #232 가 `Backend_HTTP §5.17.5 (GET /flights/{_}/levels) + §5.17.11 (POST /skins/upload)` + `WebSocket_Events §4.2.10 (cc_session_count)` 정확히 신설했음에도 `detect_api()` / `detect_websocket()` 는 D3 로 표면 잔여. 새 § 깊은 트리 (X.Y.Z) + §4.2.X sub-event 형식이 기존 spec walker 와 정합 안 됨 | spec 정합 후에도 D3 false-잔여 — Registry 보고 정확성 훼손 | ✅ **DONE 2026-05-12 (issue #307 SG-010 P11)** — `_build_heading_map` + `_section_for` (bisect O(log N) section path) + `_is_reference_or_alias_line` (line marker / SG-008 decision row / §16.1 section 3중 필터) + `_is_engine_path` (team3 Engine `/api/session` 보조 path filter) 도입. api D3 2→0 + D2 43→39 (-4 false positive: Staff App API 2 + Engine HTTP 2). D4 132 unchanged (회귀 없음). spec walker §X.Y.Z 깊은 트리 매칭 완료. |
| **(NEW 2026-05-12 Cycle 6 P11)** api detector 가 (a) §16.1 SG-008 결정 요약 행 (`\| b6 \| \`POST /sync/mock-seed\` \| ... \| §16.7 \|`) — 결정 요약은 §16.7 정의의 forward-reference 이므로 중복 카운트, (b) Staff App API 대응 행 (`\| **Staff** \| \`GET /series/:sid/Staffs\` \| ... \| Staff App API 대응 \|`) — external system (WSOP Staff App) 인용이므로 EBS endpoint 아님, (c) Engine HTTP 인용 (`Engine HTTP snapshot \`GET /api/session/{session_id}\``, team3 Harness_REST_API) — team2 routers/ scope 외 path 를 D2 로 부풀린다 | D2 false positive 증가 — `/series/{_}/{PayoutStructures,Staffs}` 2건 + `/api/session*` 2건 + 형식 잠재적 추가 | ✅ **DONE 2026-05-12 (P11)** — 3중 line+section 필터 + Engine path prefix 보조 필터. line-level marker (`Staff App API`/`Engine HTTP`/`Harness_REST_API`/`Phase 2+? only`) + row-level pattern (`\| [ab]\d+ \| ... \| §X.Y \|`) + section-level (`16.1` 결정 요약). 진성 §16.7/16.8/16.10 flat alias 엔트리 (`POST /sync/mock-{seed,reset}` & `POST /sync/trigger`) 는 의도 유지 — Phase 2 단일화 결정 대기. |
| **(NEW 2026-05-12 Cycle 4 P9 quick win)** settings detector 가 graphics overlay scope (`gfx.*` / `overlay.*`) dotted spec key 를 settings 영역으로 흡수 → `fold_delay`/`fold_display` 등 16건 false positive | settings D2 부풀려진 카운트 (S0 진단 commit 01e8c2af 인정) | ✅ **DONE 2026-05-12 (issue #269)** — `_NON_SETTINGS_PREFIXES = {gfx, graphic, graphics, overlay}` set 도입 + prefix-aware filtering (spec_drift_check.py:detect_settings line ~861). 효과: D2 109→93 (-16). |
| **(NEW 2026-05-12 Cycle 5 P10)** settings detector 가 CC Settings.md (BS-03, BO Config 스코프 — `configs` 테이블 backend key) 를 team1-frontend UI 영역과 함께 비교 → `rfid_mode`/`cap_bb_multiplier`/`allow_run_it_twice`/`ante_override`/`shot_clock_seconds`/`straddle_enabled_seats` 등 BO 전용 key 가 team1 UI code 미존재로 D2 false positive | settings D2 부풀려진 카운트 (BO 와 UI 도메인 conflate) | ✅ **DONE 2026-05-12 (issue #283)** — `_CC_SETTINGS_PATHS = {CC/Settings.md}` set 도입 + path-aware exclusion (spec_drift_check.py:detect_settings line ~782). 효과: D2 93→87 (-6, KPI 88 초과 1건). 잔여 *_mode 4건 (`bets_mode`/`chipcount_mode`/`pot_mode`/`vertical_mode`) = team1 UI.md 진성 D2 (Display/Resolution 탭 별 dropdown 정의이나 team1 code 는 `displayMode` umbrella 단일 — UX 의도적 차이 or 미구현 갭) — scanner correctness 보존 (Cycle 4 P3 false-positive 인정 교훈). |
| **(NEW 2026-05-12 Cycle 7 P12)** settings detector 가 graphics overlay scope underscore form (`gfx_vertical`/`gfx_bottom_up`/`gfx_fit`/`gfx_screen`) 을 settings 영역으로 흡수 → Settings/Graphics.md §59 (Player Layout) + Overlay/Elements.md §397 (스킨 매핑) 의 graphics 키가 team1 settings code 미존재로 D2 4건 false positive | settings D2 부풀려진 카운트 (P9 dotted-only filter 사각지대) | ✅ **DONE 2026-05-12 (issue #324)** — `_UNDERSCORE_GFX_PREFIXES = ("gfx_", "graphic_", "graphics_", "overlay_")` tuple 도입 + `_is_graphics_scope_underscore()` 헬퍼 + `_looks_like_setting_key` (spec_candidates) + `spec_whitelist` (frontmatter slash list) 양쪽 적용 (spec_drift_check.py:detect_settings line ~1009-1090). 효과: D2 84→80 (-4). D3=5 D4=51 unchanged. P9 dotted `gfx.foo` + P10 path-aware + P12 underscore `gfx_foo` 3 layer 누적으로 graphics scope conflate 완전 차단. |

## Changelog

| 날짜 | 변경 | 비고 |
|------|------|------|
| 2026-04-20 | v1.0 최초 등록 | 7 계약 scan, 3 drift 즉시 해소, SG-008~010 승격 |
| 2026-04-20 | v1.1 — SG-008 재정의 + SG-011 OUT_OF_SCOPE | "기획이 진실" 원칙 복구: SG-008 을 3분류 (a/b/c) 로 재작성. SG-011 은 프로토타입 범위 밖 TBD 로 재마킹. Spec_Gap_Triage §7.2.1 "코드가 진실 판정 요건" 추가. scanner 정밀화 (schema SQLModel detector + websocket detector + WSOP-native 필터) |
| 2026-04-20 | v1.2 — F2/F3 배치 | WebSocket detector 정밀화 완료 (D2 89→20, D3 2→0). SG-008-b1~b12 12개 개별 파일 승격 완료. §4.1 websocket 행 갱신. §4.4 b1~b12 항목 추가. §7 한계 테이블에 F2 완료 표시 |
| 2026-04-20 | v1.3 — P6/P7/P8 배치 (Agent G) | (1) Settings detector 정규화 (camelCase/snake_case/dotted/frontmatter) — D4 13→39, D3 17→17 중 6개 자동 매칭 해소. (2) Backend_HTTP §5.17 CRUD 완결성 편입 신설 — SG-008 (a) 77건 일괄 편입. (3) SG-008-b13 v2.0 잔류 8건 triage — (a) 6 / (b) 2. §4.1 api/settings 행 갱신. §4.4 SG-008-b13 항목 추가. §7 Settings 한계 완료 표시 |
| 2026-04-22 | v1.4 — Foundation 재설계 집계 동기화 (B-203) | SG-001/002/005 를 §4.4 승격 index 에 DONE 으로 추가 — 개별 `Conductor_Backlog/SG-*.md` frontmatter 는 이미 RESOLVED 였으나 Registry 집계 누락. Aggregate-vs-Source 동기화. |
| 2026-04-26 | v1.5 — SG-012~019 승격 + SG-020 신설 (Phase 1 audit) | (1) SG-012~SG-019 8건 개별 SG 파일 신설 (`_template_spec_gap.md` 기반) — 2026-04-21 critic 리포트 등재 후 5일 동안 미승격. 추적 단절 해소. (2) **SG-020 신설** — WebSocket ack/reject 6 이벤트 D2 regression (baseline 2026-04-21 PASS 0/0/0/44 → fresh 2026-04-26 0/6/0/38). (3) §4.1 fresh scan 결과 갱신: api D2 +6 (42→48), settings D2 +7/D3 +2 (97/17→104/19), websocket D2 +6 (0→6). (4) audit 보고서 `docs/4. Operations/Reports/2026-04-26-Spec_Gap_Audit_Phase1.md` 발행. |
| 2026-04-26 | v1.6 — Conductor 직접 IMPL 실행 (사용자 지시 "프로토타입 완성") | (1) **IMPL-006 DONE** — websocket publisher 6 함수 추가 (publishers.py 20→26, test_publishers.py 6/6 PASS). websocket PASS 복귀 0/0/0/44. SG-020 DONE. (2) **IMPL-007 DONE** — CC seat_cell.dart hole card 값 렌더링 제거 + face-down `?` 표시. `tools/check_cc_no_holecard.py` CI 가드 신설. Command_Center_UI/Overview.md §5.1 D7 계약 신설. (3) **IMPL-004 DONE (a)** — Settings 17 (a) 키 5개 Settings/*.md 파일 보강. settings D3 19→4 (잔여 4 = b14/b15 + scanner 2 false positive). (4) **IMPL-005 분석** — 48 D2 중 대다수 scanner false positive (router prefix 인식 한계, SG-010 후속). 그룹 A/B/C/D 분해 권고. (5) §4.1 갱신 (websocket PASS 복귀, settings 갱신). (6) pytest 248 passed (baseline 247 + 신규 ack/reject test). |
| 2026-04-27 | v1.7 — Phase 1 Decision Queue (사용자 18건 결정 SSOT) | (1) **SG-022 신규** — 단일 Desktop 바이너리 (Lobby 포함). 2026-04-22 γ 하이브리드 supersedes. Foundation §5.0 / BS_Overview §1 정렬 (Agent 1). (2) **SG-008-b1~b9, b14, b15 = DONE** (B 그룹 11건 일괄 채택, registry 권고 옵션 1). 구현은 team2 위임. (3) **SG-003 + SG-017 = DONE** (C.1 5-level scope: Global/Series/Event/Table/User). Settings/Overview.md 재작성. (4) **SG-021 = DONE** (C.2 `.riv` 단일파일 + 표준 메타). Conductor_Backlog/SG-021 갱신. (5) **SG-020 = DONE** (IMPL-006 완료 반영). (6) **BLANK-1 신규 = DONE** (C.3 100ms 전체 파이프라인). (7) **BLANK-3 신규 = DONE** (C.4 worktree fast-forward + pre-push hook). (8) Phase_1_Decision_Queue.md 신규 작성. Multi_Session_Workflow.md L4 신설. Game_Rules 4 파일 frontmatter `tier: external` + `last-updated: 2026-04-27`. MEMORY feedback_web_flutter_separation [SUPERSEDED] + project_decision_2026_04_27_phase1.md 신규. |
| 2026-05-11 | v1.8 — S10-A 정기 scan + SG-034 신규 (Stream 활성화 첫 산출물) | (1) **fresh scan 7 contract**: api D1 7→0 (큰 개선) / D3 0→2 (신규 endpoint 2건); schema **진정한 PASS 도달** (1/2 → 0/0); websocket **PASS 깨짐** (D2 1 + D3 1); auth 신규 contract 0/0/0/0 등장. (2) **§4.1 표 전면 갱신** (8 contract, baseline 2026-04-26 → 2026-05-11). (3) **SG-034 신규 등재** — `force_logout` (IMPL-009 known PENDING) + `cc_session_count` (코드 완벽, spec 누락) 묶음. detail 카드는 broker `pipeline:gap-classified` 발행으로 위임. (4) **§4.4 catch-up** — SG-031~SG-033 표에 누락된 3건 추가 + SG-034 신규 등재. SG-028~030 미사용 ID 명시. (5) **logs/drift_report.json 보존** (1352 lines, 44KB). (6) S10-A team_role broker contract: `publish pipeline:gap-classified` 첫 실행. |
| 2026-05-11 | v1.9 — S10-A Cycle 2 (issue #241): rescan + SG-035 + .http vs BO 92 mismatch 영역 등재 | (1) **Cycle 2 rescan (cycle 1 후 ~1h)**: ✅ S7 PR #232 가 SG-034 D3 `cc_session_count` + api D3 2건 (`/flights/{_}/levels`, `/skins/upload`) 동시 정합. **3 drift 해소** (cycle 1 → cycle 2). SG-034 status = PARTIAL (force_logout 잔여). (2) **§4.5 신규 섹션** — integration-tests `.http` (53 endpoints) vs BO routers (137 endpoints) mismatch 영역 등재 — 92 API mismatch KPI (issue #241). (3) **SG-035 신규** — `.http` POST `/auth/login` 의 `"username"` field vs `auth.py` `LoginRequest.email` + `User.email` unique column. drift 방향 = `.http` deprecated field. (4) **SG-036 신규** — 84 endpoint coverage gap + RBAC/header drift cluster. (5) `logs/drift_report_cycle2.json` 보존. (6) broker `pipeline:gap-classified` re-publish (cycle 2 결과 + S10-W 트리거). |
| 2026-05-11 | v1.10 — Cycle 2 **closure correction** (자기 검증, autonomous iteration 룰 1 발동) | (1) **Cycle 2 종료 baseline rescan** (`python tools/spec_drift_check.py --all`) 에서 **보고-reality 불일치 발견**: 표는 api/websocket D3 0/0 보고, 실제 = D3 2/1 잔여. (2) 원인: **spec 정합 ✅ (S7 PR #232 §5.17.5/§5.17.11/§4.2.10 정확 신설) but detector 매칭 실패 ❌** — SG-010 본질적 한계. (3) **§4.1 정정** — api/websocket D3 잔여 + cycle 2 보고 부정확 인정. SG-034 status 설명 정정. (4) **§7 신규 한계 entry** — SG-010 **P9**: api/websocket detector spec walker 가 §X.Y.Z 깊은 트리 + 신규 §4.2.X event sub-section 매칭 못함. (5) **자기 정정 가치**: broker contract 효과 (Cycle 1 → S7 → spec 정합) **검증 성공** ✅. 정확성 위한 self-correction 으로 cycle 2 보고 보강. (6) broker publish (closure correction + iteration 룰 4건 명시 + S10-W 협력 + Cycle 3 자동 진입 신호). |
| 2026-05-12 | v1.11 — Cycle 4 (issue #269) **SG-010 P9 quick win 적용** | (1) **자율 iteration 룰 1 발동** (정기 rescan + Cycle 4 P3 quick win 후속). (2) **settings detector 정밀화** — `tools/spec_drift_check.py:detect_settings()` 의 dotted-key 추출 로직에 `_NON_SETTINGS_PREFIXES = {gfx, graphic, graphics, overlay}` set 도입 + prefix-aware filtering. graphics overlay scope (`gfx.fold_delay` 등) 가 settings 영역으로 흡수되던 false positive 차단. (3) **효과 검증** — settings D2 **109→93 (-16)** ✅. P3 진단 키워드 (`fold_delay`/`fold_display`) 정확히 제거. (4) **D3 +2 신규 expose** (`language`/`showLeaderboard`) — detector 정확성 향상 부산물. (5) **SG-010 status PENDING → IN_PROGRESS**. P9 PARTIAL DONE + P10 (CC Settings.md scope 분리, 잔여 5건 `*_mode` false positive) + P11 (api/ws spec walker 깊은 트리) 후속 명시. (6) §4.1 settings row + §7 한계 entry + §4.4 SG-010 status 동시 갱신. (7) tests/test_drift_check_settings_p9.py 작성 시도 → **scope 차단** (S10-A 의 `tests/` 미포함, 6중 다층 방어 정상 작동). 단위 테스트는 별 stream 위임. (8) broker publish 시도 → **MCP server disconnected** — Registry 본문에 명시로 대체. |
| 2026-05-12 | v1.12 — Cycle 5 (issue #283) **SG-010 P10 path-aware scope 분리 적용** | (1) **Path A 보조** (Cycle 4 P9 후속, 사용자 a+b+c+d 자율 위임). (2) **settings detector 정밀화** — `tools/spec_drift_check.py:detect_settings()` 에 `_CC_SETTINGS_PATHS = {REPO/docs/2. Development/2.4 Command Center/Settings.md}` set 도입 + path-aware exclusion. CC Settings.md (BS-03) = BO Config 스코프 (configs 테이블 backend key, `scope='global/series/event/table'` override chain) 명세이고, team1-frontend/lib/features/settings 는 team1 UI form 필드 (camelCase) — 두 도메인 conflate 방지. (3) **효과 검증** — settings D2 **93→87 (-6, KPI 88 초과 -1)** ✅. 제거: `rfid_mode`(*_mode 1건, CC 스코프) + `cap_bb_multiplier`/`allow_run_it_twice`/`ante_override`/`shot_clock_seconds`/`straddle_enabled_seats` (5건 BO Config 전용 key). D3=5 D4=51 unchanged (부작용 없음). (4) **scanner correctness 보존 판정** — 잔여 *_mode 4건 (`bets_mode`/`chipcount_mode`/`pot_mode`/`vertical_mode`) 은 team1 `Settings/UI.md` Display/Resolution 탭 dropdown 정의이나 team1 code 는 `displayMode` umbrella 단일. **진성 spec→code drift D2** (UX 의도적 차이 or 미구현 갭) — 광범위 *_mode suffix 억제로 잘못된 KPI 도달 회피 (Cycle 4 P3 false-positive 인정 + scanner 한계 명시 교훈 적용). (5) **SG-010 status** = P9+P10 누적 효과로 D2 109→87 (-22, -20%). P11 (api/ws spec walker 깊은 트리) 잔여. (6) §4.1 settings row + §4.4 SG-010 entry + §7 한계 P10 신규 entry 동시 갱신. (7) cross-contract 영향 0 (api/events/fsm/schema/rfid/websocket/auth unchanged). |
| 2026-05-12 | v1.13 — Cycle 6 (issue #307) **SG-010 P11 api spec walker §X.Y.Z 깊은 트리 매칭** | (1) **Cycle 2 closure carry-over 해소** + Path A 보조 (Cycle 5 P10 후속, scope_owns 내 자율 진행). (2) **api detector 정밀화** — 신규 모듈-레벨 인프라 4종 도입 (`tools/spec_drift_check.py`): `_HEADING_PAT` (regex h2-h5 §X.Y.Z + title), `_build_heading_map` (offset/number/title 튜플 리스트), `_section_for` (bisect O(log N) section path 조회), `_is_reference_or_alias_line` (3중 필터). 추가로 `_is_engine_path` (team3 Engine `/api/session` 보조 path filter) + `ENGINE_API_PATHS`. (3) **3중 필터 설계** — (a) line-level marker `Staff App API` / `Phase 2+? only` / `Engine HTTP` / `Harness_REST_API` (external/cross-team 명시); (b) row-level `_SG008_DECISION_ROW` = `^\\s*\\|\\s*[ab]\\d+\\s*\\|.*§\\d+(\\.\\d+)+\\s*\\|` (§16.1 SG-008 결정 요약 행 첫 컬럼 ID + forward §X.Y 셀); (c) section-level `num == "16.1"` (결정 요약 sub-section). detect_api() inner loop 의 spec_pat / spec_pat_table 양쪽 모두 적용. (4) **효과 검증** — api **D2 43→39 (-4)** + **D3 2→0 (Cycle 2 closure 해소)** + D4 132 unchanged ✅. 제거된 4건: `GET/POST /api/session*` (team3 Engine HTTP 2건) + `GET /series/{_}/{PayoutStructures,Staffs}` (Staff App API 대응 2건). scanned 252→248 spec endpoints (+ 5 WSOP-native + 1 Engine API refs skipped). (5) **scanner correctness 보존 판정** — 진성 §16.7/16.8/16.10 flat alias 엔트리 (`POST /sync/mock-{seed,reset}` & `POST /sync/trigger`) 의도 유지 — Phase 2 단일화 결정 대기 (line 1418 명시). 초기 시도에서 `subpath 별칭` / `flat alias` marker 가 line 1414 의 진성 `POST /api/v1/sync/mock/seed` 정의를 잘못 억제 (D3 0→1 regression) → marker 에서 제거 후 외부 인용 marker 만 유지 (Cycle 4 P3 + Cycle 5 P10 false-positive 인정 교훈 누적 적용). (6) **누적 drift** — Cycle 4 baseline 대비 settings -22 + api -4 = **-26 false positive 제거**. (7) §4.1 REST API row + §4.4 SG-010 entry + §7 한계 P11 신규/Cycle2 closure entry 동시 갱신. (8) cross-contract 영향 0 (events/fsm/schema/rfid/settings/websocket/auth unchanged). (9) self-audit: `python tools/spec_drift_check.py --all` 후 D2/D3/D4 카운트 검증 + 진성 D2 의도 유지 확인 + D4 회귀 없음 확인. |
| 2026-05-12 | v1.17 — **추가 registry §4.4 sync: SG-008 본체 + SG-035 DONE** | (1) **SG-008 본체 DONE** — (a) 77 + (b) 12 + (c) 0 모두 처리 완료 (b13 PR #353 + b10/b11/b12 PR #352 누적). §4.4 본체 행만 PENDING 잔류였음 (sub-SG 모두 DONE). (2) **SG-035 DONE** — main code (`.http` 파일들) 이미 `"email": "admin@local"` 정합 (Cycle 4/5 PR 누적). registry §4.4 만 미갱신. (3) **drift count**: 11 → 9 (실표 행 PENDING 기준). 사용자 결정 영역 = SG-036 (92 mismatch 분석) + SG-009 IN_PROGRESS + SG-010 IN_PROGRESS + SG-023 후속 (B-Q6/Q7/Q8). |
| 2026-05-12 | v1.16 — **registry §4.4 aggregate-vs-source sync + SG-018 default 채택** | (1) **5 카드 frontmatter `status: DONE` (2026-05-03 conductor Mode A 처리)** 였으나 registry §4.4 표 미갱신 — Cycle 2026-04-22 SG-001/002/005 와 동일 패턴. 동기화: SG-012 (Lobby nav_sections), SG-013 (Tournaments/Lobby nomenclature), SG-015 (Players rationale), SG-016 (handHistory SSOT), SG-019 (Reports postproduction boundary). (2) **SG-018 default 채택** — registry 권고 그대로: 8종 메타모델 중 핵심 3종 (nav_sections/report_templates/game_rules) Phase 1 우선. team2 cascade 위임. (3) **SG-008-b13 DONE** — (b) 2 = b14/b15 이미 DONE + (a) 6 P9~P12 detector 자동 해소. (4) **drift 카운트**: 18 → **8** (PENDING/OPEN). (5) 잔여: SG-009 IN_PROGRESS / SG-010 IN_PROGRESS / SG-023 후속 B-Q6/Q7/Q8 (큰 방향성 사용자 결정) / SG-034 force_logout (IMPL-009 진행) 등. (6) over-engineering 회피 — 자율 가능 영역 일괄 처리. |
| 2026-05-12 | v1.15 — **SG-008-b10/b11/b12 default 일괄 채택** (over-engineering 회피, 사용자 결정 1회) | (1) **사용자 의도 재정의** — 핵심 = 기획 vs 프로토타입 정합성 100% + 실증 (게임 룰 확장 X). over-engineering 회피 지시. (2) **3 drift 일괄 해소** — registry 권고 default 옵션 그대로 채택: SG-008-b10 (POST /events/{id}/undo) Phase 1 미지원 옵션 3 / SG-008-b11 (POST /tables/{id}/launch-cc) deep-link 전환 옵션 1 / SG-008-b12 (GET /reports/{type}) 즉시 삭제 옵션 1. (3) **spec 삭제 위임** — Spec_Gap_Registry §4.4 status PENDING → DONE. 실제 BO router 코드 정리는 team2 또는 다음 cycle 위임. (4) **drift 카운트**: 18 → 15 (PENDING/OPEN). (5) 잔여 SG-012~019 (Lobby SSOT) + SG-018 (DB metamodel) + SG-019 (Reports boundary) + SG-023 후속 B-Q6/Q7/Q8 = 사용자 결정 영역. (6) cross-contract 영향 0. |
| 2026-05-12 | v1.14 — Cycle 7 (issue #324) **SG-010 P12 settings underscore-gfx prefix filter** + SG-034 진정한 DONE | (1) **Path A scope_owns 내 자율 진행** (Cycle 6 P11 api spec walker 후속, settings 영역). (2) **settings detector 정밀화** — P9 의 dotted form (`gfx.show_leaderboard`) 사각지대 보완. spec text 안에서 underscore form (`gfx_vertical`/`gfx_bottom_up`/`gfx_fit`/`gfx_screen`) 도 graphics overlay scope 인데 P9 dotted regex (line 1009-1016) 가 못 잡아 settings 영역으로 흡수되던 false positive 4건. 신규 모듈 도입: `_UNDERSCORE_GFX_PREFIXES = ("gfx_", "graphic_", "graphics_", "overlay_")` tuple + `_is_graphics_scope_underscore(name)` 헬퍼. `_looks_like_setting_key` (spec_candidates backtick identifier 필터) + `spec_whitelist` (frontmatter slash list 처리) 양쪽 모두에서 동일 prefix 차단 — 흡수 경로 2개 일관 적용. (3) **효과 검증** — settings **D2 84→80 (-4)** ✅. D3=5 D4=51 unchanged (회귀 없음). 제거된 4건 spec source: Settings/Graphics.md §59 (Player Layout 3 bool 조합) + Overlay/Elements.md §397 (스킨 설정 매핑 테이블) + Field_Registry.json (gfx skin_type) + Game Engine Behavioral_Specs/Overview.md §1097-1099. (4) **누적 drift (Cycle 4 baseline 대비)** — settings 109→80 (-29, -27%) + api 43→39 (-4) = **drift -33** (P9+P10+P11+P12 누적). graphics scope conflate 완전 차단 3 layer: P9 (dotted) + P10 (path-aware CC scope) + P12 (underscore). (5) **SG-034 진정한 DONE** — Cycle 7 rescan 시점 websocket 0/0/0/46 PASS 도달. IMPL-009 #236 (Cycle 3) 완결 + spec §4.2.10 `cc_session_count` + §13.3 `force_logout` close code 4003 + payload 완전 명시 누적 효과. Cycle 2 closure 가 진단한 detector 매칭 실패 (P9 한계) + IMPL-009 미완 두 조건 모두 해소. P12 직접 작용 아닌 cross-stream 환경 변화 — 진단 정확성을 위한 명시. (6) §4.1 Settings row + WebSocket row + §4.4 SG-010 entry (P12 누적 효과) + SG-034 status DONE + §7 한계 P12 신규 entry 동시 갱신. (7) cross-contract 영향 0 (api/events/fsm/schema/rfid/auth unchanged). settings detector 변경만으로 회귀 0 + 잔여 진성 D2 (4 `*_mode` Display/Resolution dropdown + 70 lobby_ui SG-036 P1) 의도 유지. (8) self-audit: `python tools/spec_drift_check.py --all` 후 D2/D3/D4 카운트 검증 + 진성 D2 의도 유지 확인 + logs/drift_report_cycle7_p12.json 보존 (1069 lines). (9) broker publish `pipeline:gap-classified` cycle 7 (S10-W 트리거 — SG-036 P1 70건 lobby_ui 잔여 분할 PR planning). |
| 2026-05-12 | v1.18 — Cycle 10 (issue #364) **SG-037 신규 — Product 폴더 명명 통일 Gap Analysis** | (1) **사용자 명시 4축 분석** — (a) 195 refs / 61 files 영향 매트릭스, (b) Confluence ↔ 로컬 정합 5 page_id mismatch 표, (c) derivative-of cascade 단방향 안전 검증, (d) open PR 충돌 위험 LOW. (2) **SG-037 신규 등재** — Type C 기획 모순. 외부 인계 PRD 3종 (`Lobby_PRD.md`/`Back_Office_PRD.md`/`Command_Center_PRD.md`) filename 만 `_PRD` 접미사 보유. frontmatter title / 본문 H1 / Confluence page title 은 짧은 이름 정합 (4-way 매트릭스 결과). (3) **§4.6 신규 섹션** — SG-037 진단 + Migration Plan + Decision Points + Wave 2 분담 (S10-W rename + S11 broker subscribe). (4) **보고서 발행** — `docs/4. Operations/Reports/Product_Naming_Unification_Plan_2026-05-12.md`. (5) **GO 판정** — rename 즉시 가능, 충돌 위험 LOW (#363 RIVE pivot 만 open, `_PRD` 파일 disjoint), derivative-of 역방향 ZERO. (6) **broker publish** `pipeline:gap-classified` cycle 10 (S10-W rename 트리거 + S11 orchestrator scope: `team_assignment_v10_3.yaml` 7 refs). |
| 2026-05-13 | v2.0 — **S10-A Cycle 15 정기 audit + 사용자 비판 3 해소 검증 PASS + SG-038/SG-039 신규** | (1) **drift Δ=-31** (Cycle 12 465 → Cycle 15 434, 큰 개선) — baseline=main HEAD e2a41b54. (2) **사용자 비판 3 해소 검증 PASS** — 비판 1 (SG-034 websocket 진정 PASS 0/0/0/46) + 비판 2 (settings D2 109→80 -29) + 비판 3 (api D2 43→39 -4). (3) **4-way 매트릭스 32 컨셉 확장** — Cycle 12 28 + 신규 4 (Settings IA / Audit Log / RBAC bit-flag / mock-mode). 결과: 24 ALIGNED · 6 PARTIAL · 2 GAP. (4) **SG-038 신규** — DB Schema `sync_cursors` D2 regression (28 vs 27). Cycle 7 P11/P12 진정한 PASS 도달 후 Cycle 15 fresh scan 에서 깨짐. Type B (기획 공백). (5) **SG-039 신규** — Settings IA migrate drift. spec 5탭 vs code 9 screens (preferences/blind_structure/prize_structure 잔재). Type D (drift, spec 진실 + code stale). (6) **§4.1 정량 갱신** — api 172 (Cycle 7 P12 171 + D3 1 신규) / schema 28 (P11 27 + D2 1 신규 SG-038) / settings 136 unchanged / websocket 46 진정 PASS 재확인. (7) **§4.4 SG-038/SG-039 신규 등재** + SG-035/036/037 IN_PROGRESS / SG-034 DONE 재확인. (8) **frontmatter audit** — 8 external PRD 무결 (3 derivative-of BO+CC+Lobby + 5 standalone RIVE+Game_Rules×4). SG-037 PENDING decision 잔여. (9) **Cycle 13/14 보고서 부재 권고** — cycle continuity 단절 감지, Conductor 에 cycle metadata 의무화 권고 (rule 추가 후보). (10) **Cycle 15 보고서 발행** — `Reports/Spec_Gap_Audit_Cycle_15_2026-05-13.md` (32 컨셉 + Type 분류 + 우선순위 매트릭스 + S10-W cascade payload). (11) **broker publish** `pipeline:gap-classified` Cycle 15 (S10-W trigger — SG-035 HIGH 우선 + SG-038/039 신규 + SG-016 + Hand JSON Export). |
| 2026-05-13 | v2.1 — **S10-A Cycle 16 Overlay 9 카테고리 재편 audit + SG-040/SG-041 신규** (PR #395) | (1) **사용자 명시 인텐트** — 시청자 시선 기반 9 카테고리 (플레이어 대시보드 / 핸드 그래픽 / 액션 인디케이터 / 실시간 승률 / 보드 커뮤니티 / 이벤트 브랜딩 / 블라인드 정보 / 중앙 팟 / 필드 현황판) vs 현재 4-source spec/구현 정합 검증. (2) **4-way 매트릭스** — User 9 cat ↔ RIVE Ch.2 (11) ↔ Foundation Scene 1 (8) ↔ OutputEvent (21) ↔ team1~4 코드. 9 카테고리 행 × 4 sources 열 완전 매트릭스 (§2 audit report). (3) **Gap 분류** — Type B 3건 (Foundation Scene 1 Branding/Blind/Field 미정의) + Type C 3건 (User 9 시계 누락, 홀+커뮤 단일화 충돌, Player Dashboard 분리 충돌) + Type D 5건 (overlay/layer1 Branding STUB / Blind STUB / Field MISSING / Equity 시각화 / OE 번호 inconsistency). P0 = 7건 (B-1,B-2,B-3, D-1,D-2,D-3, D-5). (4) **§4.7 신설** — SG-040/041 entry + 9 카테고리 user table + 4-source 매핑 + S10-W cascade payload. (5) **SG-040 신규 등재** — spec_gap + spec_inconsistency (Foundation/RIVE 9 카테고리 재편) PENDING. **SG-041 신규 등재** — spec_drift (overlay/layer1 widget 3종 누락) PENDING. (6) **ID 재할당** — 작업 당시 SG-038/SG-039 로 등재 시도, rebase 정합 단계에서 Cycle 15 audit (v2.0) 이 같은 ID 를 `sync_cursors` D2 regression / Settings IA migrate drift 로 먼저 점유한 사실 확인 → SG-040/SG-041 재할당. 작업 내용 (4-way 매트릭스 + Type 분류 + S10-W cascade) 은 그대로 보존. (7) **S10-W cascade 권고** — Foundation §Ch.2 (MAJOR rewrite) → RIVE_Standards §Ch.2 (MAJOR restructure) → Command_Center_PRD (MINOR append) + Command_Center_UI (NEW spec sections) → OutputEvent_Serialization (MINOR + B-356 closure). (8) **산출물** — `docs/4. Operations/Reports/Overlay_9_Categories_Mapping_Audit_2026-05-13.md` (257줄) + Spec_Gap_Registry §4.7 신설 + SG-040/SG-041 등재. (9) **Aggregate-vs-Source sync** — Cycle 16 갱신 라인에 SG-040/041 표기 + ID 재할당 사유 명시. | |
| 2026-05-13 | v2.2 — **S10-W Cycle 17 — SG-040/SG-041 carded + §4.4 sync + status PENDING → IN_PROGRESS** (Cycle 16 audit PR #395 후속) | (1) **SG-040 카드 신규** — `Conductor_Backlog/_template_spec_gap_SG-040_overlay_9_categories_foundation_gap.md` (123줄). Type B 3 (Foundation Branding/Blind/Field) + Type C 3 (시계 누락, 홀+커뮤 단일화, Player Dashboard 분리) 분류. 4 대안 매트릭스 + 대안 1 채택 (Foundation 9 cat base 재편 + RIVE 재배열, 시계 별 챕터). follow-up 9 항 매트릭스. (2) **SG-041 카드 신규** — `Conductor_Backlog/_template_spec_gap_SG-041_overlay_widget_3_missing.md` (116줄). Type D 5 (D-1 Branding STUB / D-2 Blind STUB / D-3 Field MISSING / D-4 Equity 시각화 / D-5 OE 번호 inconsistency = B-356) 분류. 대안 1 채택 (SG-040 spec 정합 후 implementation cascade). D-5 (B-356) 상세 매트릭스. (3) **§4.4 표 sync** — SG-040/SG-041 행 추가 (이전엔 §4.7 에만 존재). aggregate-vs-source 동기화 (cycle 16 audit 후 cycle 17 진입 시 catch-up). (4) **§4.7 status 갱신** — SG-040/SG-041 PENDING → IN_PROGRESS (Cycle 17 working on it). 해소 시점 = 후속 S10-W cycle 5 문서 cascade 머지. (5) **drift count** — PENDING 5 → IN_PROGRESS 3 (PENDING 잔여 = SG-036 + SG-038 + SG-039). (6) **broker publish** `pipeline:spec-patched` Cycle 17 (S2/S7 cascade 트리거 — SG-040 spec 정합 후 widget 3종 + field_status API). (7) **본 PR 범위** = 카드 + Registry sync 만. 5 문서 본문 cascade (Foundation MAJOR / RIVE MAJOR / CC MINOR / OE B-356 closure / CC_UI NEW) 는 후속 S10-W cycle 위임 — 도메인 owner 머지 권한 분리 + 단일 PR scope 폭증 방지. |
