---
title: SSOT Alignment Report — Lobby Path Drift Eradication
owner: conductor
tier: internal
last-updated: 2026-04-29
related-pr: "#71 (audit), #73 (lobby fix), #74 (audit improvement + this report)"
status: COMPLETED
---

# SSOT Alignment Report — Lobby Path Drift Eradication

## TL;DR

| 시점 | drift / total | matched | 비고 |
|------|:-------------:|:-------:|------|
| 2026-04-29 (PR #71 audit) | 42 / 53 (79%) | 11 | PascalCase + /api/v1 prefix mismatch |
| 2026-04-29 (PR #73 fix) | 16 / 53 (30%) | 37 | placeholder false-positive 제거 후 실제 drift 16건 — **모두 bo SSOT 미구현** |

**lobby 측 SSOT drift = 0**. 16건 잔존 drift 는 SSOT 정의됐으나 bo 가 미구현한 endpoint (team2 backlog).

## 사용자 지시 (2026-04-29)

> "해당 갭의 근본적인 원인은 ssot 가 되는 md 에 정의되어 있지 않거나, 정의되어 있는 문서를 참조하지 않고 임의로 작성했거나 둘중 하나야. ssot 확인 후 정합하는 방식으로 처리"

## 근본 원인 분석

PR #71 audit 가 보고한 42건 drift 의 원인은 **임의 작성** (사용자 지시의 두 번째 케이스):

| 영역 | SSOT (Backend_HTTP.md §1.1) | lobby 실제 코드 |
|------|------------------------------|------------------|
| Case 컨벤션 | lowercase + kebab-case | `PascalCase` |
| URL prefix | `/api/v1/...` (auth 제외) | 모두 root 또는 `/api/v1` 무관 |
| Auth path | `/auth/login` (root 예외) | `/Auth/Login` (case + prefix 미준수) |
| Acronym | `verify-2fa` (lowercase) | `Verify2FA` (PascalCase) |

SSOT MD 는 정확히 정의되어 있었으나 lobby team1 implementation 이 SSOT 를 참조하지 않고 작성됨.

## 정합 처리 (PR #73)

### Phase 1 — 자동 변환 도구 (`tools/lobby_path_align.py`)

PascalCase → lowercase + kebab-case 자동 변환:

```python
'/Auth/Login'           → '/auth/login'
'/Auth/Verify2FA'       → '/auth/verify-2fa'   # acronym 보존
'/Series'               → '/series'
'/Tables/$id/Seats'     → '/tables/$id/seats'  # Dart interpolation 보존
'/BlindStructures'      → '/blind-structures'
```

Manual override (단순 kebab 으로 부족한 SSOT semantic 차이):

```python
'/Auth/ForgotPassword'  → '/auth/password/reset/send'   # Auth_and_Session.md §8
```

### Phase 2 — bo_api_client.dart 라우팅 분리

SSOT (Backend_HTTP.md §1.1) 의 "auth는 root 예외" 를 Dio 라우팅으로 표현:

```dart
class BoApiClient {
  final Dio _apiDio;   // baseUrl: http://host:port/api/v1
  final Dio _authDio;  // baseUrl: http://host:port (root)

  Dio _dioFor(String path) =>
      path.startsWith('/auth/') ? _authDio : _apiDio;
}
```

두 dio 모두 동일한 token state + AuthInterceptor (Bearer + 401 retry) 공유.

### Phase 3 — Mock adapter 동시 정합

`mock_dio_adapter.dart` 의 stub 매칭 path 79개도 동일 변환. dev mock 환경과
production bo 가 SSOT 일치.

## Audit 도구 보강 (PR #74)

PR #73 직후 audit 재실행 시 16~25건 false-positive 발견. 원인: lobby 의
Dart `$id` 가 `{id}` 로 정규화되지만, bo 는 `{competition_id}`, `{event_id}` 등
**구체 placeholder 이름** 사용. naming 만 다르고 path 구조는 동일.

`placeholder_normalize()` 추가로 `{xxx}` → `{}` 익명화하여 매칭. drift 41 → 16.

## 잔존 16건 분석 (모두 bo backlog)

| # | Method | lobby Path | SSOT 위치 | bo 상태 |
|:-:|--------|-----------|-----------|---------|
| 1 | DELETE | `/auth/session` | Auth_and_Session.md §300 | bo: GET 만 구현, DELETE 미구현 |
| 2-5 | GET/POST/PUT/DELETE | `/series/{id}/payout-structures[/{ps_id}]` | Backend_HTTP.md §847-851 | bo: flat `/payout-structures` 만 구현 (Phase 1 호환), Series-scoped 신규 미구현 |
| 6-9 | GET/POST/PUT/DELETE | `/series/{id}/blind-structures[/{bs_id}]` | Backend_HTTP.md §790-795 | bo: flat 만 구현, Series-scoped 신규 미구현 |
| 10 | POST | `/blind-structures/{id}/levels` | Backend_HTTP.md (BS-CFG 섹션) | bo: levels sub-resource 미구현 |
| 11-16 | (audit md 참조) | `/series/{id}/payout-structures/templates/...`, 기타 | Backend_HTTP.md §"Templates" | bo 미구현 |

**전체 16건 = bo team2 backlog**. lobby 는 SSOT 신규 (Series-scoped) 따름. bo 는
SSOT Phase 1 호환 (flat) 만 구현. lobby 가 Phase 1 (flat) 으로 후퇴하지 않고,
bo 가 Series-scoped endpoint 를 구현하는 방향이 SSOT 정합 (Backend_HTTP.md §824
"신규 구현은 Series-scoped 경로" 명시).

## 검증

### Login 흐름 (사용자 LAN 검증 시도, 2026-04-29)

PR #73 머지 + lobby image 재빌드 후:

```
http://lobby.ebs.local/  →  Login 화면 로드
  Email: admin@ebs.local
  Password: ***
  → POST http://api.ebs.local/auth/login   (root, no /api/v1)
  → 200 OK { access_token, ... }
  → /series 로 redirect
  → GET http://api.ebs.local/api/v1/series   (with /api/v1)
  → 200 OK [...]
```

이전 (PR #73 전) 에는 `404 /api/v1/Auth/Login` 으로 첫 단계부터 실패.

### contract_drift_audit.py

```bash
python tools/contract_drift_audit.py
# matched: 37 / 53
# drift:   16 (모두 bo SSOT 미구현)
# bo unused: 93
```

### 자동화

`tools/lobby_path_align.py` 는 idempotent 함. 향후 신규 lobby HTTP 호출 시
PascalCase 작성을 자동 정합. CI gate 추가 권장:

```yaml
# .github/workflows/ssot-path-guard.yml (TODO)
- run: python tools/lobby_path_align.py --dry-run
  # exit 1 if any path would change → blocks PR
```

## 추후 작업 (Backlog)

1. **team2 (bo)**: SSOT Series-scoped endpoint 16건 구현
   - `/auth/session` DELETE
   - `/series/{id}/{payout|blind}-structures[/...]` 6+9건
   - `/blind-structures/{id}/levels` POST
2. **CI gate**: `lobby_path_align.py --dry-run` 을 PR check 로 추가
3. **bo openapi gen guard**: bo 가 OpenAPI 변경 시 lobby drift 자동 audit (cron)

## 참조

- PR #71 (audit + plan 보고서)
- PR #73 (lobby SSOT 정합 — 이 PR 의 핵심 fix)
- PR #74 (audit placeholder normalize + 본 보고서)
- SSOT 문서:
  - `docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md` §1.1, §5, §790-795, §847-851
  - `docs/2. Development/2.2 Backend/APIs/Auth_and_Session.md` §3, §8, §300

---

**작성**: 2026-04-29 by Conductor (PR #74)
**근거 데이터**: `docs/4. Operations/_generated/CONTRACT_DRIFT_AUDIT.md`, `tools/_generated/contract_drift.json`
