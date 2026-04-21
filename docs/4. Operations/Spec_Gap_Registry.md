---
title: Spec Gap Registry — Drift 집계 + 해소 추적
owner: conductor
tier: internal
last-updated: 2026-04-20
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

## 4. 현재 Drift (2026-04-20 scan)

### 4.1 계약별 요약

| 계약 | D1 | D2 | D3 | D4 | Total | 핵심 조치 |
|------|:--:|:--:|:--:|:--:|:-----:|-----------|
| REST API | 8 | 52 | 87 | 26 | 173 | 2026-04-20 P7: SG-008 (a) 77건 Backend_HTTP §5.17 편입 완료. D3 일부 감소 (93→87), D4 +6 (20→26). D2 증가(40→52)는 §5.17 신규 endpoint 명시 후 code 매칭 중 일부 prefix drift 흡수. (b) 12건은 SG-008-b1~b12 진행 중 |
| OutputEvent | 0 | 0 | 0 | 21 | 21 | **PASS** (2026-04-15 실측 정정 후 정렬) |
| FSM | 1 | 7 | 0 | 16 | 24 | TableFSM case 통일 SG-009 |
| DB Schema | 0 | 1 | 2 | 23 | 26 | scanner 정밀화 (SQLModel detector 추가). D3 `cards`/`settings_kv` + D2 `payout_structures` |
| RFID HAL | 0 | 3 | 0 | 8 | 11 | SG-011 **OUT_OF_SCOPE** (프로토타입 범위 밖 TBD) |
| Settings | 0 | 97 | 17 | 39 | 153 | 2026-04-20 P6: scanner 정규화 (camelCase/snake_case/dotted namespace/frontmatter) 적용. 이전 (D2=23/D3=30/D4=0) → (D2=97/D3=17/D4=39). D4 +39 (신규 매칭), D3 -13 (noise 해소). 잔류 D3 17 중 8건 SG-008-b13 v2 triage. D2 97 은 SG-003 PARTIAL 범위 — team1 구현 대기 |
| WebSocket | 0 | 20 | 0 | 24 | 44 | F2 정밀화 (2026-04-20): 이벤트 카탈로그 테이블 + JSON literal + event_types 배열만 수집. payload 필드 false positive 제거 (89→20). 잔여 D2 20 = 실제 발행 미구현 이벤트 (PascalCase 13 error/warning/command + snake_case 7 CCR-050/054) |

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
| SG-008 | spec_drift | api | PENDING | D3 89 → (a) 77 문서화 + (b) 12 SG 승격 완료 (v4.0, 2026-04-20) + (c) 0 |
| SG-008-b1 | spec_drift_b | api | PENDING | `GET /audit-events` 공개 범위 + RBAC (default: 옵션 1) |
| SG-008-b2 | spec_drift_b | api | PENDING | `GET /audit-logs` RBAC (default: 옵션 1 별도 리소스) |
| SG-008-b3 | spec_drift_b | api | PENDING | `GET /audit-logs/download` 포맷 + rate limit (default: 옵션 1 NDJSON) |
| SG-008-b4 | spec_drift_b | api | PENDING | `GET /auth/me` 반환 필드 (default: 옵션 1 확장) |
| SG-008-b5 | spec_drift_b | api | PENDING | `POST /auth/logout` 범위 (default: 옵션 1 current + `?all`) |
| SG-008-b6 | spec_drift_b | api | PENDING | `POST /sync/mock/seed` env 가드 (default: 옵션 1 dev/staging only) |
| SG-008-b7 | spec_drift_b | api | PENDING | `DELETE /sync/mock/reset` env 가드 (b6 와 페어) |
| SG-008-b8 | spec_drift_b | api | PENDING | `GET /sync/status` 공개 범위 (default: 옵션 1 Public + Admin detail) |
| SG-008-b9 | spec_drift_b | api | PENDING | `POST /sync/trigger/{source}` RBAC (default: 옵션 1 Admin + reject) |
| SG-008-b10 | spec_drift_b | api | PENDING | `POST /events/{id}/undo` 기능 범위 (default: 옵션 3 Phase 1 미지원 — 삭제) |
| SG-008-b11 | spec_drift_b | api | PENDING | `POST /tables/{id}/launch-cc` 필요성 (default: 옵션 1 deep-link 전환 — 삭제) |
| SG-008-b12 | spec_drift_b | api | PENDING | `GET /reports/{type}` deprecate (default: 옵션 1 즉시 삭제 — 사용처 검증 후) |
| SG-008-b13 | spec_drift_b | settings | PENDING | 2026-04-20 v2.0 (Agent G) — scanner P6 fix 후 D3=30→17. 잔류 8건 triage: (a) 6 / (b) 2 / (c) 0. (b) 2 = SG-008-b14 (twoFactorEnabled), SG-008-b15 (fillKeyRouting) 승격 예고 |
| SG-009 | spec_drift | fsm | IN_PROGRESS | TableFSM case 통일 — 이번 커밋에서 BS_Overview §3.1 직렬화 규약 추가 |
| SG-010 | tooling | meta | PENDING | spec_drift_check.py 정밀화 (Settings, Schema, WebSocket). **F2 WebSocket detector 정밀화 완료 (2026-04-20)**, **P6 Settings detector 정규화 완료 (2026-04-20)** — camelCase/snake_case/dotted namespace/frontmatter 지원. D4 +39 |
| SG-011 | spec_drift | rfid | **OUT_OF_SCOPE** | RFID_HAL_Interface §2.1. **프로토타입 범위 밖** — 실제 HAL 은 개발팀 + 제조사 SDK 확정 후 결정 (2026-04-20 재정의) |
| SG-012 | doc_ssot | 2.1 Frontend/Lobby | 사이드바 SSOT 부재 — UI.md §공통 레이아웃 ASCII 예시만, `nav_sections`/`nav_items` 스펙 테이블 없음. → `Critic_Reports/Lobby_IA_Sidebar_2026-04-21.md` §3 |
| SG-013 | nomenclature | 2.1 Frontend/Lobby | "lobby" 앱명 vs 섹션명 용어 충돌 — WSOP LIVE 원어 "Tournaments" 정렬 필요 (원칙 1). → 동 critic §4.1 |
| SG-014 | ia_overlap | 2.1 Frontend/Lobby+Settings | Graphic Editor 진입점 이중화 (헤더 [Graphic Editor] 버튼 + Settings/Graphics 탭) — 에셋 vs 런타임 설정 구분 명문화. → 동 critic §4.3 |
| SG-015 | ia_missing | 2.1 Frontend/Lobby | Players 섹션 유지 근거 미문서화 — user 제안 5탭에 빠짐. WSOP LIVE Player Management 정렬. → 동 critic §3 |
| SG-016 | ia_missing | 2.1 Frontend/Lobby | Reports/Insights 사이드바 항목 미정의 — UI.md §공통 레이아웃 9 권고 채택 시 신설. → 동 critic §7 |
| SG-017 | scope_inconsistency | 2.1 Frontend/Settings | "글로벌 단위" Overview.md §개요 vs MEMORY feedback_settings_global 역전(Series/Event/Table 분리) 모순 — decision_owner 판정 필요. → 동 critic §10 #5 |
| SG-018 | data_model | 2.2 Backend/Database | 5NF 메타모델 테이블 부재 — `nav_sections`/`nav_items`/`report_templates`/`skin_modes`/`setting_categories`/`integration_providers`/`game_rules`/`roles+permissions`. → 동 critic §5.2, §5.3 |
| SG-019 | scope_boundary | 1. Product/Foundation §1.2 | Reports/Insights 탭 ↔ 포스트프로덕션 경계 정의 부재 — "실시간 운영 지표만" 명문화 권고. → 동 critic §6.2 |

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
