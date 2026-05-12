# SG-036 Registry Update Request (Cycle 10, S9 → S10-A)

S9 QA scope_owns = `integration-tests/**` + `.github/workflows/*e2e*`. 본 분석은 그 안에서 완결. `docs/4. Operations/Spec_Gap_Registry.md` 갱신은 **S10-A** 권한.

## 권고 변경 (S10-A 가 PR로 처리)

### §3 (drift 카테고리 표) — 136 → 100 정정

**현재 (line ~50)**:
```
| **integration-tests vs BO** (out-of-scanner) | - | - | - | - | 136 | 🆕 **Cycle 9 정밀 측정** ... 1차 92 추정 정정 ... |
```

**변경 권고**:
```
| **integration-tests vs BO** (out-of-scanner) | - | - | - | - | 100 | 🆕 **Cycle 10 P1-read+update 보강** — `.http` 89 unique vs router 137 unique → coverage 43.8% (60/137, +24.1pp). 77 uncovered + 23 orphan = 100 mismatch (Cycle 9 136 → -36). extractor `{{path_var}}` 버그 수정 (extract_http_endpoints.py) + P1-read 10 + P1-update 11 추가. 상세: `integration-tests/_audit/sg036-cycle10/` |
```

### §4.4 SG-036 row 갱신

**변경 권고**:
```
| SG-036 | spec_drift_scenario | integration-tests vs BO | **IN_PROGRESS (Cycle 10)** | **2026-05-12 Cycle 10 P1-read+update 보강** — `.http` 89 unique vs router 137 → coverage 43.8% (60/137). 77 uncovered + 23 orphan = **100 mismatch** (Cycle 9 136 → -36, -26%). 우선순위 잔여: P1 17 (list 3 + create 3 + update 11) + P2 16 + P3 13 + P4 30 + P5 1. Cycle 10 PR: `71-sg036-p1-read-coverage.http` + `72-sg036-p1-update-coverage.http`. extractor 버그 fix 동봉. 잔여 5 cycle (11-15). 상세: `integration-tests/_audit/sg036-cycle10/README.md` |
```

### §4.5 신규 entry (Cycle 10 결과)

§4.5 마지막에 다음 섹션 추가 권고:

````markdown
### Cycle 10 P1-read + P1-update 보강 (2026-05-12, S9 PR #?)

**S9 QA Stream** — Cycle 9 baseline 대비 단일 cycle 최대 향상.

| 지표 | Cycle 9 | Cycle 10 | 변화 |
|------|:-------:|:--------:|:----:|
| `.http` unique endpoints | 69 | **89** | +20 |
| BO router unique endpoints | 137 | 137 | 0 |
| coverage | 19.7% | **43.8%** | **+24.1pp** |
| uncovered routers | 110 | **77** | -33 |
| orphan `.http` | 26 | **23** | -3 |
| **총 mismatch** | **136** | **100** | **-36 (-26%)** |

**향상 요인 분리**:

| 요인 | mismatch 감소 |
|------|:------------:|
| extractor `{{path_var}}` 버그 수정 | ~10 |
| Cycle 10 P1-read 10 endpoint | ~10 |
| Cycle 10 P1-update 11 endpoint | ~10 |
| 중복 (cycle 9 list/create 와 path 동일) | -4 |

**잔여 우선순위 분류 (77 uncovered)**:

| Priority | 카운트 | 잔여 |
|:--------:|:------:|------|
| P1 | 17 | list 3 + create 3 + update 11 |
| P2 | 16 | auth-2fa 9 + audit 3 + settings 4 |
| P3 | 13 | reports 6 + sync 7 |
| P4 | 30 | clock 9 + advanced 21 |
| P5 | 1 | events 서브 분류 누락 |

**처리 계획**: Cycle 11~15 (5 cycle, 95 endpoint + 18 orphan/drift).

**산출물**: `integration-tests/_audit/sg036-cycle10/` (README, REGISTRY_UPDATE_REQUEST, JSON 4개, py 4개 (fixed extractor 포함)).
````

### §7 한계 갱신 권고

§7 (스캐너 한계) Cycle 9 entry 갱신:

```
| (cycle 10) | scope | `spec_drift_check.py` 가 `integration-tests/scenarios/*.http` 미스캔. 본 cycle 까지 별도 audit script. Cycle 10 에서 `extract_http_endpoints.py` 의 `{{path_var}}` 정규화 버그 발견/수정 (cycle 9 측정이 ~10 mismatch 과대 카운트). 향후 spec_drift_check.py 에 `--scenarios` 모드 통합 시 본 fixed extractor 활용. |
```

## broker publish payload

```yaml
mcp__ebs-broker__publish_event:
  stream: S10-A
  pipeline: gap-classified
  payload:
    sg_id: SG-036
    cycle: 10
    status: IN_PROGRESS
    measured_mismatch: 100
    prior_mismatch: 136
    delta: -36
    coverage_pct: 43.8
    prior_coverage_pct: 19.7
    coverage_delta_pp: +24.1
    remaining_priority:
      P1: 17
      P2: 16
      P3: 13
      P4: 30
      P5: 1
    remaining_cycles: 5  # cycle 11-15
    artifacts: "integration-tests/_audit/sg036-cycle10/"
    extractor_bug_fix: true
```

## Conductor_Backlog ticket 권고

S10-A 또는 conductor 가 다음 신규 ticket 생성 권고:

- **SG-036-c10**: ✅ DONE (본 PR) — P1-read 10 + P1-update 11 + extractor fix
- **SG-036-c11**: P1 잔여 17 (list 3 + create 3 + update 11)
- **SG-036-c12**: P2 auth-2fa 9 + audit 3 + settings 4
- **SG-036-c13**: P3 reports 6 + sync 7
- **SG-036-c14**: P4 clock 9 + advanced 21
- **SG-036-c15**: Orphan B/C 결정 PR (진성 drift 13 + method drift 5)
