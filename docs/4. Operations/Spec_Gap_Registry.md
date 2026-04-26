---
title: Spec Gap Registry — Drift 집계 + 해소 추적
owner: conductor
tier: internal
last-updated: 2026-04-27
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "감지 도구 + 분류 체계 + Registry 자체로 외부 인계 가능"
related:
  - Spec_Gap_Triage.md §7 Type D
  - tools/spec_drift_check.py
  - Conductor_Backlog/
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

## 4. 현재 Drift (2026-04-26 fresh scan)

### 4.1 계약별 요약

| 계약 | D1 | D2 | D3 | D4 | Total | 핵심 조치 |
|------|:--:|:--:|:--:|:--:|:-----:|-----------|
| REST API | 7 | 48 | 0 | 114 | 169 | 2026-04-26 fresh: D2 +6 (baseline 42→48). 분석 결과 (IMPL-005) **scanner false positive dominant** — 대부분의 D2 는 router prefix 매칭 한계 (SG-010 후속). 실제 누락 endpoint 는 소수 (SG-021 metadata, SG-008-b10/b11 삭제 권고 endpoint). team2 라우터 실구현 + scanner 정밀화 대기 |
| OutputEvent | 0 | 0 | 0 | 21 | 21 | **PASS** 유지 |
| FSM | 0 | 0 | 0 | 23 | 23 | **PASS** 유지 (SG-009 직렬화 규약 적용 후) |
| DB Schema | 0 | 1 | 2 | 23 | 26 | 변화 없음. 잔여 D2 `payout_structures` + D3 `cards`/`settings_kv` (SG-010 scanner 잔여 noise) |
| RFID HAL | 0 | 0 | 0 | 8 | 8 | **OUT_OF_SCOPE** 유지 (SG-011) |
| Settings | 0 | 110 | 4 | 52 | 166 | 2026-04-26 IMPL-004 완료 후: D3 19→4 (15 키 (a) 매핑 해소). 잔여 4 = `fillKeyRouting` (SG-008-b15) + `twoFactorEnabled` (SG-008-b14) + `resolution`/`theme` (scanner false positive — backtick 인식 실패, SG-010). D2 +6 / D4 +13 = 신규 spec 보강의 부산물 |
| WebSocket | 0 | 0 | 0 | 44 | 44 | ✅ **PASS 복귀** 2026-04-26 IMPL-006 완료 — publisher 6 함수 추가 + 6/6 pytest PASS. SG-020 DONE |

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

### 4.4 SG 승격 index

| SG ID | 유형 | 계약 | 상태 | 비고 |
|-------|------|------|:----:|------|
| SG-001 | tech_stack | Lobby/GE | **DONE** | 2026-04-20 Flutter Desktop 통일 (Foundation §5.1), 2026-04-22 γ 하이브리드 (Web 정규 + Desktop 개발) team1 PR#11-14 |
| SG-002 | spec_gap | Ch.7/Overlay | **DONE** | 2026-04-20 RESOLVED — Foundation §6.3 ENGINE_URL + §6.4 3-stage fallback + §7.1 배경 투명/단색 이분법. `Conductor_Backlog/SG-002-*.md` |
| SG-005 | architecture | Ch.6 | **DONE** | 2026-04-20 RESOLVED — Foundation §Ch.6 + §Ch.7 병합, EBS_Core.md 폐기. `Conductor_Backlog/SG-005-*.md` |
| SG-004 | data_format | DATA-07/.gfskin | **SUPERSEDED** | 2026-04-22 — 회의 D3 GE 제거 결정으로 manifest.json 메타데이터가 Rive 내장으로 대체. B-209 에서 포맷 재설계. |
| SG-008 | spec_drift | api | PENDING | D3 89 → (a) 77 문서화 + (b) 12 SG 승격 완료 (v4.0, 2026-04-20) + (c) 0. b1~b9/b14/b15 는 2026-04-27 일괄 DONE (B 그룹) |
| SG-008-b1 | spec_drift_b | api | **DONE** | 2026-04-27 — `GET /audit-events` RBAC=Admin only 채택 (registry 권고 옵션 1). 구현은 team2 위임 |
| SG-008-b2 | spec_drift_b | api | **DONE** | 2026-04-27 — `GET /audit-logs` 별도 리소스 (events=user, logs=system) 채택 (옵션 1). 구현은 team2 위임 |
| SG-008-b3 | spec_drift_b | api | **DONE** | 2026-04-27 — `GET /audit-logs/download` NDJSON + 100req/min rate limit 채택 (옵션 1). 구현은 team2 위임 |
| SG-008-b4 | spec_drift_b | api | **DONE** | 2026-04-27 — `GET /auth/me` 확장 필드 (role, permissions, settings_scope) 채택 (옵션 1). 구현은 team2 위임 |
| SG-008-b5 | spec_drift_b | api | **DONE** | 2026-04-27 — `POST /auth/logout` current + `?all=true` 옵션 채택 (옵션 1). 구현은 team2 위임 |
| SG-008-b6 | spec_drift_b | api | **DONE** | 2026-04-27 — `POST /sync/mock/seed` env guard dev/staging only 채택 (옵션 1). 구현은 team2 위임 |
| SG-008-b7 | spec_drift_b | api | **DONE** | 2026-04-27 — `DELETE /sync/mock/reset` env guard dev/staging only 채택 (b6 와 페어). 구현은 team2 위임 |
| SG-008-b8 | spec_drift_b | api | **DONE** | 2026-04-27 — `GET /sync/status` Public + Admin detail bifurcation 채택 (옵션 1). 구현은 team2 위임 |
| SG-008-b9 | spec_drift_b | api | **DONE** | 2026-04-27 — `POST /sync/trigger/{source}` Admin only + reject 권한 채택 (옵션 1). 구현은 team2 위임 |
| SG-008-b10 | spec_drift_b | api | PENDING | `POST /events/{id}/undo` 기능 범위 (default: 옵션 3 Phase 1 미지원 — 삭제) |
| SG-008-b11 | spec_drift_b | api | PENDING | `POST /tables/{id}/launch-cc` 필요성 (default: 옵션 1 deep-link 전환 — 삭제) |
| SG-008-b12 | spec_drift_b | api | PENDING | `GET /reports/{type}` deprecate (default: 옵션 1 즉시 삭제 — 사용처 검증 후) |
| SG-008-b13 | spec_drift_b | settings | PENDING | 2026-04-20 v2.0 (Agent G) — scanner P6 fix 후 D3=30→17. 잔류 8건 triage: (a) 6 / (b) 2 / (c) 0. (b) 2 = SG-008-b14 (twoFactorEnabled), SG-008-b15 (fillKeyRouting) 승격 예고 |
| SG-008-b14 | spec_drift_b | settings | **DONE** | 2026-04-27 — `Settings.twoFactorEnabled` = User scope (per user) 채택. 구현은 team1/team2 위임 |
| SG-008-b15 | spec_drift_b | settings | **DONE** | 2026-04-27 — `Settings.fillKeyRouting` = NDI fill/key param (Hardware Out Phase 2) 채택. 구현은 team1/team2 위임 |
| SG-009 | spec_drift | fsm | IN_PROGRESS | TableFSM case 통일 — 이번 커밋에서 BS_Overview §3.1 직렬화 규약 추가 |
| SG-010 | tooling | meta | PENDING | spec_drift_check.py 정밀화 (Settings, Schema, WebSocket). **F2 WebSocket detector 정밀화 완료 (2026-04-20)**, **P6 Settings detector 정규화 완료 (2026-04-20)** — camelCase/snake_case/dotted namespace/frontmatter 지원. D4 +39 |
| SG-011 | spec_drift | rfid | **OUT_OF_SCOPE** | RFID_HAL_Interface §2.1. **프로토타입 범위 밖** — 실제 HAL 은 개발팀 + 제조사 SDK 확정 후 결정 (2026-04-20 재정의) |
| SG-012 | doc_ssot | 2.1 Frontend/Lobby | PENDING | `Conductor_Backlog/SG-012-lobby-sidebar-ssot.md` (2026-04-26 승격) — UI.md `nav_sections` 데이터 스키마 표 추가 필요 |
| SG-013 | nomenclature | 2.1 Frontend/Lobby | PENDING | `Conductor_Backlog/SG-013-lobby-tournaments-nomenclature.md` — 섹션명="Tournaments" 고정, 앱명="Lobby" 분리 (원칙 1) |
| SG-014 | ia_overlap | 2.1 Frontend/Lobby+Settings | **SUPERSEDED** | `Conductor_Backlog/SG-014-graphic-editor-dual-entry.md` — 회의 D3 GE 제거 결정으로 자동 해소. Foundation §5.3 Rive Manager 대체 SSOT |
| SG-015 | ia_missing | 2.1 Frontend/Lobby | PENDING | `Conductor_Backlog/SG-015-players-section-rationale.md` — Players 섹션 유지 근거 명문화 (WSOP LIVE Player Management 정렬) |
| SG-016 | ia_missing | 2.1 Frontend/Lobby | PENDING | `Conductor_Backlog/SG-016-hand-history-sidebar-section.md` — 25개 분산 참조 → 독립 SSOT 섹션 (`Plans/Lobby_Sidebar_HandHistory_Migration_Plan_2026-04-21.md` 기반) |
| SG-017 | scope_inconsistency | 2.1 Frontend/Settings | **DONE** | 2026-04-27 — C.1 5-level scope (Global/Series/Event/Table/User) 채택. Settings/Overview.md 재작성 완료. SG-003 동시 해소 |
| SG-003 | scope_design | 2.1 Frontend/Settings | **DONE** | 2026-04-27 — C.1 5-level scope 채택 (SG-017 와 합산 결정). Override 우선순위: User > Table > Event > Series > Global. WSOP LIVE 정렬 (원칙 1) |
| SG-018 | data_model | 2.2 Backend/Database | PENDING | `Conductor_Backlog/SG-018-5nf-metamodel-tables.md` — 8종 메타모델 테이블, default 권고: 핵심 3종(nav_sections/report_templates/game_rules) 우선 |
| SG-019 | scope_boundary | 1. Product/Foundation §1.2 | PENDING | `Conductor_Backlog/SG-019-reports-postproduction-boundary.md` — "Reports = 실시간 운영 지표 한정" 명문화 권고 |
| SG-020 | spec_drift | websocket | **DONE** | 2026-04-26 IMPL-006 완료 — websocket publisher 6 함수 추가, 6/6 pytest PASS. websocket PASS 복귀 |
| SG-021 | spec_gap | Foundation §5.3 / 2.4 Overlay | **DONE** | 2026-04-27 — C.2 채택: `.riv` 단일 파일 + 표준 메타 스키마 (Custom Property + Text Run binding + State Machine). `Conductor_Backlog/SG-021-*.md` 갱신 |
| SG-022 | scope_clarification | Foundation §5.0 / BS_Overview §1 | **DONE** | 2026-04-27 — A 채택: 단일 Desktop 바이너리 (Lobby 포함). Foundation §5.0 + BS_Overview §1 정렬 (Agent 1 처리). supersedes 2026-04-22 γ 하이브리드. 후속: B-Q2 DONE (Docker lobby-web destroy 2026-04-27), B-Q3 PENDING (team1 Web 빌드 자산, due 2026-05-04), B-Q4 DONE (origin URL 정정) |
| SG-023 | intent_pivot | 프로젝트 전체 (memory + CLAUDE.md + 거버넌스 + timeline + vendor) | **DONE** (인텐트 명시), **PENDING** (후속 cascade B-Q5~Q9) | 2026-04-27 — B 채택: EBS 인텐트 전환 (기획서 완결 → production 출시). memory `project_intent_spec_validation` + `user_role_planner` SUPERSEDED. memory `project_intent_production_2026_04_27` NEW. CLAUDE.md (project) "🎯 프로젝트 의도" 갱신. Conductor_Backlog/SG-023 + NOTIFY-ALL-SG023-INTENT-PIVOT 발행. 후속: B-Q5 (DONE 본 turn), B-Q6/Q7/Q8 Backlog 등재 (사용자 명시 대기), B-Q9 (DONE 본 turn — Spec_Gap_Triage callout) |
| SG-024 | governance_expansion | 5팀 분리 거버넌스 → conductor_full_authority (Mode A) + 멀티세션 옵션 (Mode B) | **DONE** | 2026-04-27 — B-Q5 ㉠ 채택: Conductor 단일 세션 전권. CLAUDE.md "팀 세션 금지" 폐기. team-policy.json v7.1 (modes A/B + mode_a_limits). Multi_Session_Workflow §"v7.1 단일 세션 모드" 추가. NOTIFY-ALL-SG024-GOVERNANCE-EXPANSION 발행. B-Q9 Spec_Gap_Triage callout 추가. B-Q6/Q7/Q8 Backlog 등재 (사용자 명시 대기) |
| BLANK-1 | scope_clarification | Foundation §6.4 (latency) | **DONE** | 2026-04-27 — C.3 채택: 100ms = 전체 파이프라인 (RFID → Engine → WS → Render → Output) end-to-end. WebSocket 단일 구간 부연 (Phase 2 측정 대상). Foundation §6.4 분해 (Agent 1 처리) |
| BLANK-3 | scope_clarification | Multi_Session_Workflow.md (merge) | **DONE** | 2026-04-27 — C.4 채택: worktree fast-forward + pre-push conflict hook. Multi_Session_Workflow.md L4 신규 섹션 |

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
| Schema detector 가 inline code backtick 을 CREATE TABLE 로 오인 | D2 noise | Schema.md 의 표준 declaration 블록 확정 후 스캐너 정밀화 |
| Settings detector 가 탭별 scope 분리 없음 | D2 전량 false | SG-010 |
| Settings detector 의 identifier 정규화 (camelCase ↔ snake_case ↔ dotted) | D3 false positive | **SG-010 P6 완료 (2026-04-20)** — dotted namespace (`gfx.foo`) 마지막 segment + frontmatter slash-list + whitelist bypass 적용. D4 +39, D3 -13 (netof new code keys) |
| WebSocket detector 가 payload 필드까지 D2 수집 | D2 89 false positive | **SG-010 F2 완료 (2026-04-20)** — 이벤트 카탈로그 테이블만 수집. D2 89→20 |
| 반대 방향 (문서 설명된 미구현 API) 부분 커버 | D2 일부 누락 가능 | TODO 마커 병행 grep |

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
