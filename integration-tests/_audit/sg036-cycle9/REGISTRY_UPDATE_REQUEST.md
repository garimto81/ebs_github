# SG-036 Registry Update Request (S9 → S10-A)

S9 QA scope_owns 는 `integration-tests/**` + `.github/workflows/*e2e*`. 본 분석은 그 안에서 완결되지만, `docs/4. Operations/Spec_Gap_Registry.md` 갱신은 **S10-A (Gap Analysis Stream)** 또는 **conductor** 권한.

## 권고 변경 (S10-A 가 PR로 처리)

### §3 (drift 카테고리 표) — 92 → 136 mismatch 정정

**현재 (line 50)**:
```
| **integration-tests vs BO** (out-of-scanner) | - | - | - | - | 92 | 🆕 **SG-035 + SG-036 별 추적** — 53 .http endpoints vs 137 router endpoints. 단순 path diff 84 + body schema mismatch (SG-035 username/email) + RBAC/header drift 일부 = 92 mismatch (issue #241) |
```

**변경 권고**:
```
| **integration-tests vs BO** (out-of-scanner) | - | - | - | - | 136 | 🆕 **Cycle 9 정밀 측정** — `.http` 59 unique vs router 137 unique → coverage 19.7% (27/137). 110 uncovered + 26 orphan = 136 mismatch (1차 #241 의 92 추정 정정). Method-aware 매칭 + auth_router prefix 보정 적용. 상세: `integration-tests/_audit/sg036-cycle9/` |
```

### §4.4 SG-036 row 갱신

**현재 (line 144)**:
```
| SG-036 | spec_drift_scenario | integration-tests vs BO | PENDING | **2026-05-11 Cycle 2 후속 영역** — `.http` 53 endpoints vs BO routers 137 endpoints. 단순 path diff 84 + body/RBAC/header drift = issue #241 의 92 mismatch. 정밀 카운팅 + 우선순위 매트릭스 필요. Cycle 3 plan: cycle 별 .http 보강 (top 10 CRUD endpoints/cycle) |
```

**변경 권고**:
```
| SG-036 | spec_drift_scenario | integration-tests vs BO | **IN_PROGRESS (Cycle 9)** | **2026-05-12 Cycle 9 정밀 측정** — `.http` 59 unique vs router 137 unique → 110 uncovered + 26 orphan = **136 mismatch** (92 → 136 정정). 우선순위 4단 분류 완료: P1 51 (CRUD) + P2 16 (auth/audit/settings) + P3 13 (reports/sync) + P4 30 (clock/advanced). Cycle 9 PR: P1 top-10 .http 보강 (`70-sg036-p1-crud-coverage.http`). 잔여 Cycle 10~14 분할. 상세: `integration-tests/_audit/sg036-cycle9/README.md` |
```

### §4.5 신규 entry (Cycle 9 정밀 측정 결과)

§4.5 마지막에 다음 섹션 추가 권고:

````markdown
### Cycle 9 정밀 mismatch 측정 (2026-05-12, S9 #?)

**S9 QA Stream** — `integration-tests vs BO routers` 정밀 분석. method-aware regex 매칭 + auth_router prefix 보정.

| 지표 | 1차 #241 | Cycle 9 정밀 |
|------|:-------:|:-----------:|
| `.http` unique endpoints | 53 | **59** |
| BO router unique endpoints | 137 | **137** |
| coverage (.http 가 router 호출) | 미측정 | **27 / 137 = 19.7%** |
| uncovered routers | 84 | **110** |
| orphan `.http` | 8 | **26** |
| **총 mismatch** | **92** | **136** |

**우선순위 4단 분류 (110 uncovered)**:

| Priority | 카운트 | 영역 |
|:--------:|:------:|------|
| P1 (CRUD core) | 51 | list 9 / read 10 / create 7 / update-delete 25 |
| P2 (auth/audit/settings) | 16 | auth-2fa 9 / audit 3 / settings 4 |
| P3 (reports/sync) | 13 | reports 6 / sync 7 |
| P4 (advanced) | 30 | clock 9 / blind-levels 3 / seats 2 / 기타 16 |

**Orphan 26건 분류**:

- Engine API (정상, 분류 외): 8건 (`/api/session*`, `/api/v1/_mock/*`, `/api/variants`, `/health`)
- 진성 drift (BO 미구현 future spec): 13건 (`/api/v1/skins/{}/metadata`, `/api/v1/tables/{}/output-config`, `/api/v1/sagas/{}` 등)
- Method drift Type D: 5건 (`PATCH /tables/{}` vs router PUT 등)

**처리 계획**: Cycle 9 (top-10) → 10~14 cycle 분할 (총 6 cycle, 123 endpoint 정합).

**산출물**: `integration-tests/_audit/sg036-cycle9/` (README, JSON 4개, py 4개).
````

### §7 한계 추가 권고

§7 (스캐너 한계) 에 다음 entry 추가:

```
| (cycle 9) | scope | `spec_drift_check.py` 가 `integration-tests/scenarios/*.http` 미스캔. 본 cycle 의 정밀 측정은 별도 audit script (`integration-tests/_audit/sg036-cycle9/`). 향후 spec_drift_check.py 에 `--scenarios` 모드 통합 검토. |
```

## broker publish 권고

```
mcp__ebs-broker__publish_event:
  stream: S10-A
  pipeline: gap-classified
  payload:
    sg_id: SG-036
    status: IN_PROGRESS (Cycle 9 top-10)
    measured_mismatch: 136
    previous_estimate: 92
    coverage_pct: 19.7
    remaining_cycles: 5 (cycle 10-14)
```

## Conductor_Backlog ticket 권고

S10-A 또는 conductor 가 다음 신규 ticket 생성 권고:

- **SG-036-c9**: P1 top-10 보강 (이번 cycle PR)
- **SG-036-c10**: P1-read 10 + P1-update 11
- **SG-036-c11**: P1-update 14 + P2-auth-2fa 9
- **SG-036-c12**: P2-audit/settings 7 + P3 13
- **SG-036-c13**: P4 30
- **SG-036-c14**: Orphan B/C 결정 PR (13건 spec ↔ code 정합)
