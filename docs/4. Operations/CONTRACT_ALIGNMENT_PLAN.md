---
title: Contract Alignment Plan — bo ↔ lobby ↔ cc 정합 계획
owner: conductor
tier: critical
last-updated: 2026-04-29
status: PROPOSAL — 사용자 결정 + team1/team2/team4 협력 필요
related-pr: "#71 (본 plan + drift audit 도구)"
trigger: "사용자 LAN 검증 시도 (2026-04-29) — `404 /api/v1/Auth/Login` 발견"
---

# Contract Alignment Plan

## TL;DR

**12-PR 인프라 cascade (#11~#69)가 lobby↔bo 의 application contract drift 를 가렸습니다.** 사용자 LAN 검증 시 발견된 `404 /api/v1/Auth/Login` 은 빙산의 일각:

- **bo 127 endpoint** (lowercase + kebab-case + `/api/v1/` prefix, auth 만 root)
- **lobby 53 HTTP call** (PascalCase + 모두 `/api/v1/` prefix)
- **drift: 42건** (lobby 호출의 79%) — 자세히: `_generated/CONTRACT_DRIFT_AUDIT.md`

본 plan 은 **OpenAPI SSOT 수립 + 양쪽 정합 + contract test 자동화** 5-Phase 로 갭 영구 봉합.

## 1. 현 상태 진단

### 3 contract source 가 있고 모두 충돌

| Source | 위치 | path 형식 | base prefix | auth 위치 | 진실의 권위 |
|--------|------|----------|-------------|----------|:-----------:|
| **bo (FastAPI runtime)** | `team2-backend/src/routers/*.py` | lowercase + kebab-case | `/api/v1/` | root `/auth/*` | ✓ 작동 |
| **lobby (team1 Flutter)** | `team1-frontend/lib/repositories/*.dart` | **PascalCase** | `/api/v1/` (apiBaseUrl 포함) | `/api/v1/Auth/*` (오류) | ✗ 미작동 |
| **API 문서 (team2 docs)** | `docs/2. Development/2.2 Backend/APIs/*.md` | (확인 필요) | (확인 필요) | (확인 필요) | ? |

→ team1 dev 와 team2 dev 가 **다른 spec 가정**으로 작성. 통합 검증 단계 부재 → drift 가 인프라 PR 12 회 동안 누적.

### Drift 분류 (audit 결과 기반)

| 종류 | 사례 | 해결 가능성 |
|------|------|:----------:|
| **Casing** | `/Auth` ↔ `/auth`, `/Series` ↔ `/series` | trivial (문자열 변환) |
| **Naming style** | `/Verify2FA` ↔ `/verify-2fa`, `/ForceLogout` ↔ ? | 의미 매핑 필요 |
| **Prefix** | lobby `/api/v1/Auth/*` ↔ bo `/auth/*` (root) | apiBaseUrl 분리 또는 path 명시 |
| **Semantic 차이** | `/Auth/ForgotPassword` ↔ `/auth/password/reset/send` | 양쪽 합의 필요 |
| **Lobby missing** | bo 에 있는 endpoint 117 개를 lobby 가 안 씀 | 정상 (모든 endpoint 가 frontend 와 1:1 일 필요 없음) |

### 12-PR cascade 가 detect 못 한 이유

| 검증 도구 | 검증 대상 | 사각지대 |
|-----------|----------|----------|
| `verify_harness.py` | 5 서비스 contract level (응답하나) | path 정합성 미검사 |
| `verify_team1_e2e.py` | bo `/api/v1/series` 호출 200 | **lobby 가 그 path 호출하는지** 미검사 |
| 3-tier CI gate (dockerfile-lint / hadolint / build) | Docker 이미지 빌드 | application 계약 미검사 |
| flutter-checks alpha | Dart 정적 분석 + 단위 테스트 | runtime BO 통합 미포함 |

→ **contract test 부재** 가 근본 원인. 본 plan 의 Phase 1 이 이를 영구 도입.

## 2. SSOT 결정 — 사용자 선택 필요

3 옵션 중 1개 선택. 각자 trade-off 명시:

### Option D-1: bo OpenAPI 를 SSOT 로 채택

| 항목 | 평가 |
|------|------|
| 변경 범위 | lobby 전반 (53 호출 수정) + cc 도 동일 패턴이면 cc 도 |
| bo 변경 | 0 (이미 작동) |
| RESTful 정통성 | 높음 (kebab-case, `/api/v1/` prefix, auth root) |
| 시간 | **3-5일** (lobby refactor + 검증) |
| 추천 | ★★★ — bo 가 이미 RESTful + 작동 |

### Option D-2: lobby contract 를 SSOT 로 채택

| 항목 | 평가 |
|------|------|
| 변경 범위 | bo router 전반 (127 endpoint 재작성) + DB schema 영향 가능 |
| lobby 변경 | 0 |
| RESTful 정통성 | 낮음 (PascalCase 는 RESTful 컨벤션 위배) |
| 시간 | 5-7일 |
| 추천 | ★ — RESTful 위배 + bo 큰 변경 |

### Option D-3: 새 SSOT 수립 (권장)

| 항목 | 평가 |
|------|------|
| 변경 범위 | `docs/2. Development/2.5 Shared/api-contract/openapi.yaml` 신규 + bo + lobby + cc 모두 정렬 |
| 정통성 | 최고 — 외부 SSOT, contract-first 접근 |
| 시간 | 5-7일 (1주일) |
| 자동화 | contract test가 SSOT ↔ bo runtime / lobby 호출 매트릭스 자동 비교 |
| 추천 | ★★★★ — 미래 dev 도 같은 SSOT 따라감 |

> **D-1 vs D-3 선택 필요.** D-1 은 빠르지만 SSOT 가 bo 코드 자체 (구현 = 명세). D-3 는 명시적 OpenAPI yaml 이 명세 → 더 정통하지만 1-2일 추가 소요.

## 3. 추천 Plan — D-1 변형 (실용 + 정통)

bo OpenAPI 를 SSOT 의 **사실상 권위** 로 인정하되, 동시에 `docs/2. Development/2.5 Shared/api-contract/openapi.yaml` 에 commit 하여 **명시적 SSOT 도 갖춤**. 두 source 가 같은 PR 에서 자동 sync.

핵심:
- bo runtime OpenAPI = `/openapi.json` (live)
- bo committed SSOT = `docs/2. Development/2.5 Shared/api-contract/openapi.yaml` (file)
- contract test 가 두 source 가 **동일** 한지 매 PR 마다 검증
- lobby 가 committed SSOT 를 따라가도록 contract drift audit 도 매 PR 마다 검증

장점:
- D-1 의 빠름 + D-3 의 정통
- D-3 의 contract-first 효과 (lobby/cc dev 가 명시 SSOT 참조)
- bo 코드와 SSOT 가 자동 sync (drift 차단)

## 4. 5-Phase 실행 계획

### Phase 1 — Contract SSOT Infrastructure (D+1, 1일)

**목표**: SSOT 자산 + 자동 sync infrastructure 도입.

산출물:
- `docs/2. Development/2.5 Shared/api-contract/openapi.yaml` (NEW) — bo runtime OpenAPI 의 첫 스냅샷
- `docs/2. Development/2.5 Shared/api-contract/CONVENTIONS.md` (NEW) — naming/casing/prefix 규칙 명문화
- `tools/contract_drift_audit.py` (이미 PR #71 에 도입) — bo runtime ↔ lobby calls 매트릭스
- `tools/contract_ssot_sync.py` (NEW) — bo runtime → committed SSOT 자동 갱신 (PR-only, manual trigger)
- `.github/workflows/contract-test.yml` (NEW)
  - bo runtime 띄우고 OpenAPI fetch
  - committed SSOT 와 diff → drift 시 fail
  - lobby paths grep → SSOT 와 매트릭스 → unknown 1+ 시 fail
- CONVENTIONS.md 정의:
  - HTTP path: lowercase + kebab-case (e.g., `/auth/verify-2fa`)
  - Prefix: 인증/세션은 root (`/auth/*`), 나머지는 `/api/v1/*`
  - Path param: `{id}` (OpenAPI 표준)
  - Casing: 모든 segment lowercase (Acronym 도)

검증 기준: 본 phase merge 후 `tools/contract_drift_audit.py` 가 매 PR 에서 자동 실행.

### Phase 2 — lobby auth refactor (D+2~D+3, 1.5일)

**목표**: lobby 의 auth_repository 정합. 사용자 login 검증 가능 상태.

작업:
- `lib/foundation/configs/app_config.dart`: apiBaseUrl 분리
  ```dart
  // 신규
  String get authBaseUrl => '${scheme}://${host}:${port}'; // root, no /api/v1
  String get apiBaseUrl => '${authBaseUrl}/api/v1';        // 기존 의도
  ```
- `lib/repositories/auth_repository.dart`: path lowercase + kebab-case + 별도 dio (root host)
- `lib/data/local/mock_dio_adapter.dart`: 동시 정합 (dev 환경 일치)
- `lib/data/remote/auth_interceptor.dart`: `/Auth/Refresh` → `/auth/refresh`
- production.example.json + Dockerfile inline JSON 의 LAN domain 정합 유지
- 검증: `tools/verify_team1_e2e.py` 의 S2b (auth login path) 통과 + 사용자 LAN 도메인 login 동작

산출물 PR #72 (예정).

### Phase 3 — lobby 핵심 entity refactor (D+4~D+5, 2일)

**목표**: series/events/flights/tables/players/hands/competitions repository 정합.

각 repository:
- path PascalCase → kebab-case
- `$id` → `{id}` 의미 매핑 (Dart string interpolation 그대로 OK; 단지 OpenAPI compatibility)
- 모델 (freezed) 변화 시 동시
- mock 매핑 정합

검증: 사용자가 lobby 에서 series 목록 조회, event 진입, flight 정보 등 핵심 user journey 동작.

산출물 PR #73~#76 (entity 별 분리 또는 1 PR).

### Phase 4 — lobby 부가 + cc 동시 정합 (D+5~D+6, 1.5일)

**목표**:
- lobby: audit, configs, decks, payout, reports, skins, blind-structures
- cc (team4): 동일 PascalCase 패턴 사용 가능성 — audit + 정합

산출물 PR #77~#78.

### Phase 5 — Contract Test 강화 + 회귀 차단 (D+6, 0.5일)

**목표**: 향후 PR 이 본 갭 재발 안 하도록 자동 차단.

작업:
- `.github/workflows/contract-test.yml` 확장:
  - bo runtime container 자동 startup
  - committed SSOT diff
  - lobby + cc drift audit
  - drift > 0 → CI fail + PR comment with cheat-sheet (PR #22 패턴)
- `team1-e2e.yml` path filter 에 `team2-backend/**` 추가 (PR #70 발견된 gap)
- contract test 도 PR #20/#22/#26 의 3-tier defense 와 같은 layered 구조에 통합

검증 기준: 의도된 회귀 PR (chaos test, PR #21 패턴) 작성 → CI 가 차단 + cheat-sheet 자동 코멘트.

## 5. 즉시 가능한 Hotfix (옵션)

본 plan 진행 중 **사용자 검증 unblock** 이 시급할 경우:

### Hotfix Option H1 — Mock 모드 활성화

`team1-frontend/production.example.json` 에서 `USE_MOCK: true` 변경 + lobby rebuild. lobby 가 자체 mock dio 사용 → BO 와 미연동. login UI 동작.

| 장점 | 단점 |
|------|------|
| 5분 fix, lobby/bo 코드 0 변경 | bo 미연동 — 검증 가치 ★☆☆ |

### Hotfix Option H2 — bo 에 lobby contract alias

bo `main.py` 에 `lobby_alias_router` 추가 — 모든 lobby PascalCase path 를 기존 핸들러로 redirect.

| 장점 | 단점 |
|------|------|
| 1-2시간, lobby 0 변경, 실제 BO 연동 | bo 코드 추함, alias 유지 부담 |

권장: **H2 + Phase 2-5 병행**. H2 가 즉시 unblock, Phase 가 정통 fix. Phase 2 lobby refactor 머지 시점에 H2 alias 제거.

## 6. 일정

| Phase | 기간 | 누적 일수 | 주요 산출물 |
|-------|:----:|:---------:|------------|
| Phase 1 — SSOT infra | 1일 | D+1 | api-contract/openapi.yaml + contract-test workflow |
| Phase 2 — auth refactor | 1.5일 | D+2.5 | lobby login 정합 (사용자 1차 검증 가능) |
| Phase 3 — 핵심 entity | 2일 | D+4.5 | series/events/flights/tables 정합 |
| Phase 4 — 부가 + cc | 1.5일 | D+6 | lobby 전반 + cc 정합 |
| Phase 5 — contract test 강화 | 0.5일 | D+6.5 | 회귀 자동 차단 |
| **총** | **6.5일** | | |

병렬 진행 시 (team1+team2 동시) 4-5일 단축 가능.

## 7. 리스크 + 완화

| 리스크 | 가능성 | 영향 | 완화 |
|--------|:------:|:----:|------|
| bo OpenAPI 와 docs/API spec 의 추가 drift | 중 | 중 | Phase 1 에서 docs API spec 도 audit |
| lobby refactor 중 model (freezed) 변화 누락 | 중 | 중 | Phase 2-4 마다 build_runner 재생성 + flutter analyze 검증 |
| cc (team4) 도 같은 PascalCase 패턴이면 작업 두 배 | 중 | 중 | Phase 4 시작 전 cc audit (lobby audit 패턴 재사용) |
| contract test False positive | 낮 | 낮 | normalize 휴리스틱 + escape 매커니즘 |
| 본 plan 진행 중 dependabot major bump (cascade) | 낮 | 중 | major-gate (PR #68) 가 차단 → review 후 진행 |

## 8. 사용자 결정 사안

본 plan 진행 전 사용자 결정 필요:

| 결정 항목 | 옵션 |
|-----------|------|
| **SSOT 채택** | D-1 (bo runtime) / **D-3 변형 (committed openapi.yaml + sync)** ← 추천 |
| **즉시 hotfix 동시 진행 여부** | H1 (mock) / **H2 (bo alias)** ← 추천 / 미진행 |
| **cc (team4) 포함 여부** | 포함 (Phase 4 에 추가) / 별도 추후 |
| **CODEOWNERS 자동 reviewer 도입** | bo 변경 → team2, lobby 변경 → team1 자동 배정 / 미도입 |

## 9. 본 PR (#71) 산출물

- ✅ `tools/contract_drift_audit.py` — drift 자동 감지 도구 (작동 검증됨)
- ✅ `docs/4. Operations/_generated/CONTRACT_DRIFT_AUDIT.md` — 첫 audit 보고서 (auto-generated)
- ✅ `tools/_generated/contract_drift.json` — 매트릭스 raw data
- ✅ `docs/4. Operations/CONTRACT_ALIGNMENT_PLAN.md` (본 문서) — 5-Phase plan

**본 PR 은 코드 변경 0건** (lobby/bo 미터치). 사용자 review + 결정 후 Phase 1 별도 PR 진행.

## 10. 책임 인정

본 12-PR cascade (#11~#69) 동안 conductor 가 다음을 못 함:

1. ❌ 첫 PR (#11) 에서 lobby 가 호출하는 path 와 bo 가 제공하는 path 매트릭스 비교
2. ❌ verify_team1_e2e.py 도입 시 wiring level 만 검증, contract level 미검증
3. ❌ chaos test (PR #21) 시 contract drift 시나리오 미포함
4. ❌ Dependabot governance (PR #68) 시 contract drift detection 미포함

이 사각지대가 사용자 LAN 검증 시점까지 누적. 본 plan 은 그 사각지대를 명시 + 영구 봉합.

## 관련 자산

- `tools/contract_drift_audit.py` (PR #71)
- `docs/4. Operations/_generated/CONTRACT_DRIFT_AUDIT.md` (auto-generated)
- `docs/2. Development/2.5 Shared/api-contract/` (Phase 1 신규)
- `.github/workflows/contract-test.yml` (Phase 1 신규)
- 영향받는 lobby 코드: `team1-frontend/lib/repositories/*.dart`, `lib/data/remote/*.dart`, `lib/data/local/mock_*.dart`
- 영향받는 cc 코드: `team4-cc/src/lib/...` (audit 후 결정)
- 영향받는 docs: `docs/2. Development/2.2 Backend/APIs/*.md`
