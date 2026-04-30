---
name: iteration
description: V10.0 자율 iteration cycle skill. 사용자 결정 점 0, iteration- prefix 격리, hot-swap curator (#1↔#2 매 phase 자동 교체), dual workflow (Impl-first 7-step / Spec-first 5-step). 미구현 list / e2e fail / drift 감지 / 신규 기획 / 사용자 인텐트 시 호출.
---

# /iteration — V10.0 자율 iteration cycle skill

## 본질 (한 줄)

> `iteration-` prefix 격리된 ~13 agent pool + hot-swap curators (매 phase 자동 교체, swap 직전 1회 검사 + 1회 개선) + dual workflow (Impl-first 7-step / Spec-first 5-step) + 3 KPI 자율 측정 + Iron Law self-contained. **사용자 결정 점 0, 다른 프로젝트 영향 0**.

## 호출 시점

| 트리거 | 분류 |
|--------|------|
| 미구현 list > 0 | Impl-first |
| 신규 기능 / 변경 인텐트 | Spec-first |
| Drift 감지 (`tools/spec_drift_check.py`) | Impl-first Step 3 부터 |
| e2e fail | Impl-first Step 2 부터 |
| 사용자 결정 archive 필요 | Spec-first Step 5 |
| 혼합 | 다중 workflow 병렬 |

`/iteration` 호출 시 `iteration-phase-strategist` 가 위 분류를 자율 판정.

## 7 Iron Laws (skill self-contained)

### IL-1. Cycle Activation = Skill 호출
사용자가 `/iteration` 호출 OR `iteration-phase-strategist` 가 자동 트리거 시 cycle 활성.

### IL-2. 보고 ≠ 멈춤
iteration cycle 활성 중 보고 작성 = 체크포인트일 뿐. exit_criteria 미충족 시 자동 CONTINUE. **"최종 보고" 표현 자체 금지** (체크포인트 표현만).

### IL-3. Exit Criteria
```
exit = (
  reimplementability_pass_rate ≥ 0.9 AND
  drift_direction 명확 AND
  missing == 0
) OR user explicit stop ("멈춰", "stop", "ok") OR circuit_breaker(3 same-fail).
```

### IL-4. SSOT 우선
프로토타입 implementation 진척만으로 exit 불가. 기획 quality 동시 충족 필수.

### IL-5. 격리 원칙
모든 신규 agent / 진화 = `iteration-` prefix 만. 기존 project-wide agent 수정 X.

### IL-6. Workflow 명시
모든 cycle = Impl-first 7-step OR Spec-first 5-step OR 명시적 변형. 임의 흐름 X.

### IL-7. Hot-swap
curator-a / curator-b 교체 = phase 종료 시점만. 실시간 X. swap 직전 1회 검사 + 1회 개선.

## 실행 흐름

```
[Skill 호출]
  ↓
1. iteration-phase-strategist
   - 인텐트 분류 (Impl-first / Spec-first / 혼합)
   - registry signature scan (중복 방지)
   - workflow 선택
  ↓
2. iteration-curator-{a|b} (ACTIVE)
   - 해당 phase agent 선택 (registry scan)
   - reuse 우선, iteration- 신규는 부재 시만
  ↓
3. iteration-runner (continuation_loop)
   - Workflow A (Impl-first 7-step) 실행 → workflows/impl-first-7-step.md
   - OR Workflow B (Spec-first 5-step) 실행 → workflows/spec-first-5-step.md
  ↓
4. Phase 종료
   - exit_criteria 충족 검사
   - 미충족 → 자동 CONTINUE (IL-2)
   - 충족 → checkpoint + KPI 갱신
  ↓
5. Hot-swap (자동, IL-7)
   - swap 직전: STANDBY curator 가 ACTIVE 의 phase 작업 1회 전수 검사
   - STANDBY curator 가 ACTIVE 의 prompt 1회 개선
   - rotation_log.md append
   - ACTIVE ↔ STANDBY 교체
  ↓
6. 다음 phase OR exit
```

## Workflow 선택 (phase-strategist 자율)

```
사용자 인텐트 / SSOT 상태 분석
  ├─ 미구현 list > 0 → Impl-first
  ├─ 신규 기능 / 변경 → Spec-first
  ├─ Drift 감지 → Impl-first Step 3 부터
  ├─ e2e fail → Impl-first Step 2 부터
  ├─ 사용자 결정 → Spec-first Step 5
  └─ 혼합 → 다중 workflow 병렬
```

상세는 `workflows/impl-first-7-step.md`, `workflows/spec-first-5-step.md` 참조.

## Hot-Swap Curator 메커니즘

| 항목 | 규칙 |
|------|------|
| **자동 교체** | phase 종료 시 항상. 조건 X. |
| **검사 횟수** | swap 직전 1회. ACTIVE 의 결정 log + agent 선택 + 결과 전수 검사. |
| **개선 횟수** | swap 직전 1회. STANDBY 가 ACTIVE 의 prompt 개선안 적용. |
| **무한 진화 방지** | 매 phase 1회 개선 hard-cap → 메커니즘 차원에서 폭주 0. |
| **rotation_log.md** | swap timestamp + version diff + 검사 요약 + 개선 내용 기록. |
| **동시 활성** | 1 (ACTIVE = 결정 권한 / STANDBY = swap 직전 검사+개선만). 충돌 0. |

상세는 `curators/swap_policy.md` 참조.

## 3 KPI (자동 측정)

| KPI | Target | 측정 |
|-----|:-:|------|
| `reimplementability_pass_rate` | ≥ 90% | iteration-spec-validator |
| `drift_trend` | 단조 감소 | tools/spec_drift_check.py |
| `runner_halts` | 0 | iteration-runner exit log |

매 phase 종료 시 자동 측정 + `docs/4. Operations/v10_metrics.yml` append.

## 자율 결정 default (사용자 결정 점 0)

| 결정 | Default |
|------|---------|
| 10 팀 매트릭스 | ACCEPT |
| 단일 도입 (Wave X) | ACCEPT |
| 영구 agent 추가 | auto-PR |
| 6주 미사용 archive | ACCEPT |
| Hot-swap timing | phase 종료 시 무조건 자동 |
| Curator 검사+개선 횟수 | swap 직전 각 1회만 |
| Workflow 선택 | iteration-phase-strategist 자율 |
| 스크린샷 step 조건부 | UI 관련 phase 만 |
| KPI 측정 cadence | per-phase |
| Iron Law | self-contained (이 SKILL.md) |
| freeze unblock | ACCEPT |

## 격리 검증

```
grep -r "V10.0" ~/.claude/         → 0 (다른 프로젝트 영향 0)
grep -r "iteration-" .claude/agents/ → 13 (격리 원칙 준수)
```

## 관련 파일

| 파일 | 역할 |
|------|------|
| `workflows/impl-first-7-step.md` | Impl-first 7-step 워크플로우 |
| `workflows/spec-first-5-step.md` | Spec-first 5-step 워크플로우 |
| `curators/swap_policy.md` | Hot-swap 메커니즘 정책 |
| `curators/rotation_log.md` | swap 이력 (자동 append) |
| `.claude/agents/iteration-*.md` | 13 격리 agent |
| `.claude/skills/agent-teamworks/SKILL.md` | 10 팀 매트릭스 (iteration 팀 4개 포함) |
| `docs/2. Development/2.5 Shared/team-policy.json` | V10.0 governance + iteration_skill block + curator_swap block |
