---
id: SG-036
title: "기획 공백 + 구현 drift: integration-tests `.http` 시나리오 vs Back Office routers — 100 endpoint mismatch (Cycle 10 snapshot)"
type: spec_gap
status: IN_PROGRESS
owner: conductor
created: 2026-05-11
updated: 2026-05-12
affects_chapter:
  - docs/1. Product/Back_Office.md §Ch.3 (REST API surface)
  - docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md §전체
  - integration-tests/scenarios/*.http (test coverage)
protocol: Spec_Gap_Triage
related:
  - broker seq=25 (2026-05-11 09:39, SG-036 birth)
  - broker seq=1100 (2026-05-12 10:14, Cycle 9 측정 136)
  - broker seq=1108 (2026-05-12 11:46, Cycle 10 측정 100)
  - integration-tests/_audit/sg036-cycle10/REGISTRY_UPDATE_REQUEST.md
  - issue #241 (Cycle 2 birth)
  - PR #361 (Cycle 9 P1 top-10), PR #370 (Cycle 10 P1-read+update + extractor fix)
---

# SG-036 — integration-tests `.http` vs Back Office routers 정합 격차

> **두 시각으로 같은 ID 가 운영되고 있음에 주의** (§3.2 참조). 본 카드의 주 분석 영역은 *integration-tests `.http` vs BO routers* (S9 운영 중). Settings D2 카테고리화는 별도 §3.2 에서 cross-reference.

## 1. 공백 서술

**관측 사실**:

| 차원 | Cycle 9 (2026-05-12 10:14) | Cycle 10 (2026-05-12 11:46) | 단일 cycle 변화 |
|------|:--------------------------:|:--------------------------:|:--------------:|
| `.http` unique endpoints | 59 | **89** | +30 |
| BO router unique endpoints | 137 | 137 | 0 |
| 커버되는 router | (계산 19.7%) | **60** (43.8%) | **+24.1pp** |
| uncovered router | 110 | **77** | -33 |
| orphan `.http` | 26 | **23** | -3 |
| **총 mismatch** | **136** | **100** | **-36 (-26%)** |

**의미**: `team2-backend/src/routers/*.py` 에 137 개 endpoint 가 선언되어 있으나 `integration-tests/scenarios/` 의 `.http` 시나리오는 그 중 43.8% (60 개) 만 호출. 외부 개발팀 인계 시 "이 API 실제로 동작하는가" 를 자체 검증할 수 있는 시나리오가 부재한 endpoint 가 77 개 잔존.

**Cycle 2 originally 측정 추정 92 → Cycle 9 정밀 측정 136 → Cycle 10 보강 100**. 측정 정밀도 향상 (extractor `{{path_var}}` 정규화 버그 fix, PR #370 동봉) + cycle 별 P1 보강 누적 효과.

## 2. 발견 경위

- **2026-05-11 09:39** (broker seq=25, Cycle 2): S10-A 정기 scan 에서 spec_drift_check.py 의 7 contract regex 가 못 잡는 *HTTP body / verb / path 시나리오 수준* drift 로 처음 인식. 1차 추정 92 mismatch. issue #241 KPI 로 등재.
- **2026-05-11 10:21** (broker seq=35, Cycle 2 closure): S10-W trigger 발행 — "SG-035 detail card creation" 요청 (SG-036 는 S9 후속 분석으로 일임).
- **2026-05-12 10:14** (broker seq=1100, Cycle 9): S9 가 정밀 측정 도구 (`extract_http_endpoints.py` + `extract_router_endpoints.py` + `mismatch_analyze.py` + `classify_priority.py`) 자체 제작. 측정 136 mismatch. P1 top-10 .http 보강 PR #361 머지.
- **2026-05-12 11:46** (broker seq=1108, Cycle 10): S9 가 extractor 의 `{{path_var}}` 정규화 버그 발견/수정 + P1-read 10 + P1-update 11 추가. 측정 100 mismatch. PR #370 머지.
- **본 카드 작성 (2026-05-12 S10-W Cycle 12)**: SG-036 이 PENDING 상태로 Conductor_Backlog 에 detail card 없이 broker seq=25 ~ seq=1108 동안 운영되어 인계 어려움. S10-W 가 retroactive card 작성 (이번 PR).

**실패 분류**: 복합형.

| 차원 | 카운트 | Type | 처리 |
|------|:------:|:----:|------|
| uncovered router (BO 만 존재) | 77 | Type B (시나리오 공백) | S9 cycle 11~15 분할 보강 |
| orphan `.http` (시나리오 만 존재) | 23 | 혼합 | 분류 필요 (§4 참조) |
| ㄴ engine_api (team3 별 도메인) | 8 | Type A (scope 오인) | scenario 측 별 file 분리 또는 삭제 |
| ㄴ true_drift (router 미존재 path) | 13 | Type B/C | path 정의 누락 (B) 또는 router 삭제 후 잔재 (C) |
| ㄴ method_drift_type_d | 5 | **Type D** | code 와 spec 의 HTTP verb 불일치 — code-as-truth 시 spec 정정 |

> Spec_Gap_Triage §7.2 (Type D 해소 요건) 준수: code 가 진실로 판정되려면 (a) e2e 통과, (b) 사용자 가치 명확, (c) PRD 인용 가능. 5 method_drift 항목은 cycle 15 에서 개별 판정 필요.

## 3. 영향받는 챕터 / 구현

| 챕터 / 위치 | 어떤 결정이 비어있나 |
|-------------|---------------------|
| `docs/1. Product/Back_Office.md` §Ch.3 (REST API surface) | 137 router endpoint 중 외부 인계용 표준 cover list 가 명시되지 않음. "이 API 는 production 필수" vs "내부 운영 도구" 분류 부재 |
| `docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md` | spec walker (Cycle 6 P11) 가 §X.Y.Z 깊은 트리 매칭 후에도 진성 D2/D3 가 잔존. spec 측 endpoint 명시 누락분 (77 uncovered 의 일부) 보강 필요 |
| `integration-tests/scenarios/*.http` | 우선순위별 cover plan 미명시. cycle 별 endpoint allocation (cycle 11: 17, cycle 12: 16 ...) 이 _audit 폴더에만 존재 |
| `integration-tests/_audit/sg036-cycle10/` | S9 가 제작한 측정 도구가 별 location 에 있음. spec_drift_check.py 와 통합 안 됨 (Cycle 11+ 통합 후속) |

### 3.1 잔여 77 uncovered 의 우선순위 분포 (Cycle 10 결과)

| Priority | 카운트 | 내용 | 권장 cycle |
|:--------:|:------:|------|:----------:|
| **P1** | 17 | list 3 + create 3 + update 11 (CRUD 미완) | Cycle 11 |
| **P2** | 16 | auth-2fa 9 + audit 3 + settings 4 | Cycle 12 |
| **P3** | 13 | reports 6 + sync 7 | Cycle 13 |
| **P4** | 30 | clock 9 + advanced 21 | Cycle 14 (분할) |
| **P5** | 1 | events sub-classification 누락 | Cycle 15 (orphan 결정 PR 동시) |

총 77 + 23 orphan ÷ 5 cycle ≈ **20 endpoint/cycle** (S9 의 자체 cycle plan 과 정합).

### 3.2 SG-036 ID 의 이중 사용 (Registry §4.5 와의 의미 분리)

`docs/4. Operations/Spec_Gap_Registry.md` §4.5 "Settings D2 109건 카테고리 분류 + 우선순위" 에서도 `SG-036` ID 가 사용되고 있다 (2026-05-12 신규 등재). 이는:

- **본 카드 (SG-036 주 영역)**: integration-tests `.http` vs BO routers (S9 측정 / S10-W triage / S10-A registry)
- **Registry §4.5 (SG-036 부 영역)**: Settings D2 109건 (97 lobby_ui + 9 engine + 3 backend env + ...) 카테고리화 (S2/S7/S8 협력)

**판정**: 동일 SG ID 의 의도된 multi-faceted 사용. 두 영역 모두 "spec_drift_scenario 검증을 위한 endpoint/key 분류" 라는 공통 골격. **Cycle 12 이후 분리 필요 시 SG-036-a (integration-tests) / SG-036-b (Settings D2) 로 sub-ID 도입 권고**.

## 4. orphan `.http` 23 건 분류

S9 가 Cycle 9 측정 (broker seq=1100) 에서 분류:

| 분류 | 카운트 | 의미 | 후속 |
|------|:------:|------|------|
| `engine_api` | 8 | team3 Engine HTTP API (`/api/session/*` 등) | scenarios 측 별 file 분리 또는 명시 주석 — S9 cycle 15 결정 PR |
| `true_drift` | 13 | router 에 진짜 미존재 path | (a) router 추가 필요 (Type B) — S7 위임 또는 (b) `.http` 삭제 (Type C — 시나리오가 invalid path 사용) |
| `method_drift_type_d` | 5 | path 는 존재하나 HTTP method 불일치 | code-as-truth 판정 — Spec_Gap_Triage §7.2 정밀 검증 후 spec 정정 |

## 5. 결정 방안 후보

| 대안 | 장점 | 단점 | WSOP LIVE 패턴 정렬 |
|------|------|------|---------------------|
| 1. **S9 cycle 11~15 분할 보강 + Cycle 15 orphan 결정 PR** | 측정 정확 / 누적 정합 / scope_owns 정합 (S9 = integration-tests) | 5 cycle 진행 시간 | ✅ (점진 완결, 측정 가능) |
| 2. 일괄 보강 (1 PR 으로 77 + 23 처리) | 단기간 완결 | PR 크기 폭발 + critic 어려움 + 리뷰 부담 | ❌ |
| 3. SG-036 폐기 + 개별 endpoint 별 신규 SG 발행 | 세밀한 추적 | 카드 폭발 (100+ 신규 카드) + 인계 어려움 | ❌ |
| 4. coverage 목표 폐기 (현 43.8% 유지) | 작업 종료 | external handoff 시 "왜 절반은 테스트 없는가" 정당화 불가 | ❌ |

## 6. 결정

- **채택**: 대안 1 (S9 cycle 11~15 분할 보강 + Cycle 15 orphan 결정 PR)
- **이유**: SG-036 의 본질은 "외부 개발팀 인계 시 API 동작 검증 가능성" 보장. 점진 보강이 측정 정확도와 critic 품질을 동시에 유지. S9 가 Cycle 9~10 에서 이미 -36 mismatch 실증.
- **영향 카드 업데이트 PR**: 본 PR (S10-W cycle 12) — branch `worktree-s10w-cycle12-sg036`
- **후속 구현 PR (S9 위임)**: 아래 §7 cycle plan

## 7. 후속 cycle plan (S9 위임)

| ticket | cycle | 영역 | endpoint count | 예상 mismatch 감소 |
|--------|:-----:|------|:--------------:|:-----------------:|
| SG-036-c11 | Cycle 11 | P1 잔여 (list 3 + create 3 + update 11) | 17 | -17 |
| SG-036-c12 | Cycle 12 | P2 (auth-2fa 9 + audit 3 + settings 4) | 16 | -16 |
| SG-036-c13 | Cycle 13 | P3 (reports 6 + sync 7) | 13 | -13 |
| SG-036-c14 | Cycle 14 | P4 (clock 9 + advanced 21, 2 batch) | 30 | -30 |
| SG-036-c15 | Cycle 15 | P5 1 + Orphan 결정 PR (engine_api 8 분리 + true_drift 13 + method_drift 5) | 27 | -23 (orphan resolve) + 23 (drift fix) |

**완결 시 KPI**: coverage 43.8% → ≥95% (잔여 5% = engine_api orphan + 의도된 internal-only endpoint).

**완결 트리거**: Cycle 15 PR 머지 + broker `pipeline:gap-classified` payload `{sg_id: "SG-036", status: "DONE", final_coverage_pct: ≥95}` publish.

## 8. 후속 follow-up (cross-stream)

| 후속 항목 | 담당 stream | 우선순위 |
|----------|------------|:-------:|
| `spec_drift_check.py --scenarios` 모드 통합 (fixed extractor 흡수) | S10-A | P2 |
| Backend_HTTP.md §X 신규 endpoint 명시 누락분 (77 uncovered 중 spec 측 공백) | S7 또는 S10-W cycle 13+ | P2 |
| Back_Office.md §Ch.3 "외부 인계 API surface" 표 신규 (137 → production-required 분류) | S10-W cycle 14+ | P3 |
| SG-036 ID 의 이중 사용 → SG-036-a / SG-036-b 분리 (Settings D2 영역) | S10-A 또는 conductor | P3 |
| method_drift_type_d 5 건 code-as-truth 정밀 검증 (e2e 통과 + PRD 인용 가능 확인) | S9 cycle 15 + S10-W critic | P1 (cycle 15) |

## 9. 산출물 / 증적

- 본 카드: `docs/4. Operations/Conductor_Backlog/_template_spec_gap_SG-036_integration_tests_routers_mismatch.md` (이 파일)
- S9 측정 도구: `integration-tests/_audit/sg036-cycle10/{README.md, REGISTRY_UPDATE_REQUEST.md, extract_http_endpoints.py, extract_router_endpoints.py, mismatch_analyze.py, classify_priority.py, http_endpoints.json, mismatch_result.json}`
- 보강 시나리오: `integration-tests/scenarios/71-sg036-p1-read-coverage.http`, `72-sg036-p1-update-coverage.http`
- PR trail: #361 (Cycle 9), #370 (Cycle 10), 본 PR (Cycle 12 detail card)
- broker trail: seq=25 → 35 → 1100 → 1108
