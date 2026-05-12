# SG-036 Cycle 10 — P1-read + P1-update .http coverage 보강

**Date**: 2026-05-12
**Owner**: S9 QA Stream
**Branch**: `work/s9/cycle9-2026-05-12` (cycle 10 work continues on same branch)
**Issue**: SG-036 (Spec_Gap_Registry §4.5)
**Prior**: [Cycle 9 README](../sg036-cycle9/README.md) — PR #361 MERGED 2026-05-12

## 결론 (TL;DR)

| 지표 | Cycle 9 baseline | Cycle 10 정밀 | 변화 |
|------|:----------------:|:-------------:|:----:|
| `.http` unique endpoints | 69 (post-PR #361, raw) | **89** | **+20** |
| BO router unique endpoints | 137 | 137 | 0 |
| router coverage (.http 가 호출) | 19.7% (27/137) | **43.8% (60/137)** | **+24.1pp** |
| uncovered routers | 110 | **77** | **-33** |
| orphan `.http` | 26 | **23** | **-3** |
| **총 mismatch** | **136** | **100** | **-36 (-26%)** |

### 향상 요인 분리

| 요인 | 기여도 (mismatch 감소) | 비고 |
|------|:---------------------:|------|
| (1) extractor `{{path_var}}` 버그 수정 | ~10 | Cycle 9 가 `{{series_id}}` 등 path-param 변수를 host prefix 로 오인 → orphan 으로 잘못 카운트. fixed `extract_http_endpoints.py` 적용. |
| (2) Cycle 10 P1-read 10 endpoint .http 추가 | ~10 | `71-sg036-p1-read-coverage.http` 신규 |
| (3) Cycle 10 P1-update 11 endpoint .http 추가 | ~10 | `72-sg036-p1-update-coverage.http` 신규 |
| 일부 중복 (cycle 9 list/create 가 이미 cover) | -4 | 동일 path 의 다른 method 등 |

**Net effect**: 1 cycle 단일 PR 로 **단일 cycle 최대 mismatch 감소 (-36)** 달성.

## 우선순위 분류 (77 uncovered 잔여)

| Priority | 카운트 | 변화 (Cycle 9 → 10) | 영역 |
|:--------:|:------:|:-----------------:|------|
| **P1** (CRUD core) | **17** | 51 → 17 (-34) | list 3 + create 3 + update/delete 11 |
| **P2** (auth/audit/settings) | **16** | 16 → 16 (-0) | auth-2fa 9 + audit 3 + settings 4 |
| **P3** (reports/sync) | **13** | 13 → 13 (-0) | reports 6 + sync 7 |
| **P4** (advanced) | **30** | 30 → 30 (-0) | clock 9 + 기타 21 |
| **P5** (분류 누락) | **1** | 0 → 1 (+1) | events 서브 1건 — Cycle 11 분류 보강 |

P1 잔여 17건:
- list 3: `GET /events`, `GET /flights`, `GET /payout-structures`
- create 3: `POST /events`, `POST /flights`, `POST /payout-structures`
- update 11: DELETE `/blind-structures/{id}/levels/{id}` PUT/DELETE, DELETE `/competitions/{id}`, DELETE `/events/{id}`, DELETE `/flights/{id}`, DELETE `/payout-structures/{id}`, DELETE `/players/{id}`, DELETE `/series/{id}`, PUT/DELETE `/skins/{id}`, PUT/DELETE `/tables/{id}/seats/{id}`

## Orphan .http (23건)

Cycle 9 의 26 → 23 (-3, extractor fix 효과). 분류는 [Cycle 9 README §Orphan](../sg036-cycle9/README.md#orphan-http-26건--진성-spec-drift) 와 동일 카테고리 (Engine API / 진성 drift / Method drift).

## 처리 계획 (Cycle 11+ 분할)

| Cycle | 범위 | endpoint 수 | PR 예상 |
|:-----:|------|:-----------:|--------|
| **10 (이번)** | P1-read 10 + P1-update 11 | **21** | 1 PR (본) |
| 11 | P1 잔여 17 (list 3 + create 3 + update/delete 11) | 17 | 1-2 PR |
| 12 | P2 auth-2fa 9 + audit 3 + settings 4 | 16 | 2 PR |
| 13 | P3 reports 6 + sync 7 | 13 | 1-2 PR |
| 14 | P4 clock 9 + advanced 21 | 30 | 2-3 PR |
| 15 | Orphan B/C 결정 PR (진성 drift 13 + method drift 5) | 18 | spec ↔ code 결정 PR |

총 5 cycle (Cycle 11-15) 잔여, 95 endpoint + 18 orphan/drift = 113 mismatch 해소 계획.

## 재현 명령

```bash
# Extract HTTP endpoints (Cycle 10 fixed extractor)
python integration-tests/_audit/sg036-cycle10/extract_http_endpoints.py > /tmp/http_endpoints.json

# Router endpoints (Cycle 9 와 동일 — BO 변화 없음)
# cp integration-tests/_audit/sg036-cycle9/router_endpoints.json /tmp/

# Mismatch analysis (JOB env var override 필요)
JOB=/tmp python integration-tests/_audit/sg036-cycle10/mismatch_analyze.py > /tmp/mismatch_result.json
```

## extractor 버그 수정 상세

**Before (Cycle 9)** — `VAR_RE.sub("", p)` 가 `{{series_id}}` 등 path param 변수까지 제거:
```python
p = VAR_RE.sub("", p).strip()  # {{host}}/api/v1/series/{{series_id}} → /api/v1/series/
```

**After (Cycle 10)** — 모든 handlebars 를 `{}` 치환, 선두 host prefix 만 제거:
```python
p = VAR_RE.sub("{}", p)  # {{host}}/api/v1/series/{{series_id}} → {}/api/v1/series/{}
while p.startswith("{}"):
    p = p[2:]  # → /api/v1/series/{}
p = PARAM_RE.sub("{}", p)
```

## Iron Law 준수

- **Core Philosophy**: 사용자 진입점 1회 (PR 검토). 측정 → 신규 .http → 갱신 모두 자율 사이클.
- **Visual-First**: 표 + 우선순위 매트릭스 + 향상 요인 분리 표.
- **Spec_Gap_Registry 갱신**: REGISTRY_UPDATE_REQUEST.md 별도 작성.
- **broker publish**: `pipeline:gap-classified` payload 발행 (REGISTRY_UPDATE_REQUEST §broker).
