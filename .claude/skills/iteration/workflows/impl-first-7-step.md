# Workflow A — Impl-first 7-step

**트리거**: 미구현 list > 0 OR 사용자 implementation 인텐트 OR drift 감지 OR e2e fail.

## 7 단계 흐름

```
[Trigger: 미구현 list OR 사용자 인텐트]
  ↓
1. 프로토타입 구현
   Team: Dev (executor + architect + code-reviewer)
   Output: PR 생성 + 자율 머지
  ↓
2. 문제점 감지
   Trigger: e2e fail OR drift 감지 OR phase-strategist 호출
   Team: Quality (qa-tester + iteration-e2e-orchestrator)
  ↓
3. SSOT vs 코드 결정 ★
   Team: iteration-drift-reconciler + iteration-spec-validator
   Output:
     - SSOT 문제 → Step 4a
     - 코드 문제 → Step 4b
     - 둘 다 → 4a + 4b 병렬
  ↓
4a. 기획 문서 수정
   Team: iteration-spec-author + iteration-spec-classifier + iteration-spec-coherence
   Output: docs/ 파일 수정 (additive 원칙)

4b. 코드 수정
   Team: Dev (executor + code-reviewer)
   Output: 코드 fix + PR
  ↓
5. e2e 검증
   Team: iteration-e2e-orchestrator + qa-tester
   Output: Playwright PASS
  ↓
6. 스크린샷 확인
   Team: iteration-screenshot-verifier
   Trigger: UI 관련 phase 만 (조건부)
   Output: test-results/*.png 보존
  ↓
7. 체크포인트 (1줄) → 다음 phase
   - 모든 KPI 갱신
   - hot-swap 시점이면 curator 교체
```

## 단계별 상세

### Step 1 — 프로토타입 구현

| 항목 | 값 |
|------|-----|
| 팀 | Dev (executor / architect / code-reviewer) |
| 입력 | 미구현 list 1 항목 (예: `GET /events/{eid}/players`) |
| 출력 | 구현 코드 + PR 머지 |
| 자율성 | architect 가 design 자율 판단, executor 가 code 작성 |
| 종료 조건 | code 컴파일 PASS AND lint PASS |

### Step 2 — 문제점 감지

| 항목 | 값 |
|------|-----|
| 팀 | Quality (qa-tester / iteration-e2e-orchestrator) |
| 입력 | Step 1 머지 후 코드 |
| 출력 | 문제 분류 (e2e fail / drift / spec gap / 없음) |
| 트리거 | Playwright run + `tools/spec_drift_check.py` 실행 |
| 종료 조건 | 문제 1건+ 발견 OR 모두 PASS (PASS 시 Step 7 직행) |

### Step 3 — SSOT vs 코드 결정 (CRITICAL)

| 항목 | 값 |
|------|-----|
| 팀 | iteration-drift-reconciler + iteration-spec-validator |
| 입력 | Step 2 의 문제 분류 |
| 출력 | Type A/B/C/D 분류 (Spec_Gap_Triage 기준) |
| 자율 판단 기준 | SSOT 명확 + 코드 다름 → Type A (코드 fix) / SSOT 공백 → Type B (spec PR) / SSOT 모순 → Type C (spec PR) / SSOT-구현 drift → Type D (drift_reconciler 자율 판정) |
| 종료 조건 | 다음 단계 (Step 4a / 4b / 4a+4b) 결정 |

### Step 4a — 기획 문서 수정

| 항목 | 값 |
|------|-----|
| 팀 | iteration-spec-author + iteration-spec-classifier + iteration-spec-coherence |
| 출력 | `docs/` 파일 수정 (additive 원칙) |
| 조건 | Step 3 = Type B/C OR Type D-spec |
| 종료 조건 | spec_drift_check D1=0 + reimplementability_pass_rate ≥ 0.9 |

### Step 4b — 코드 수정

| 항목 | 값 |
|------|-----|
| 팀 | Dev (executor / code-reviewer) |
| 출력 | 코드 fix + PR |
| 조건 | Step 3 = Type A OR Type D-code |
| 종료 조건 | 컴파일 PASS + lint PASS + Step 5 e2e PASS |

### Step 5 — e2e 검증

| 항목 | 값 |
|------|-----|
| 팀 | iteration-e2e-orchestrator + qa-tester |
| 입력 | Step 4 결과 |
| 출력 | Playwright report (PASS/FAIL) |
| 종료 조건 | 모든 e2e PASS |
| FAIL 시 | Step 2 로 회귀 (circuit breaker: 3 same-fail = exit) |

### Step 6 — 스크린샷 확인 (조건부)

| 항목 | 값 |
|------|-----|
| 팀 | iteration-screenshot-verifier |
| 입력 | Step 5 PASS 결과 |
| 트리거 | **UI 관련 phase 만** — phase-strategist 가 자율 판단 |
| 출력 | `test-results/*.png` 보존 + UI regression 검사 |
| 비-UI phase | skip |

### Step 7 — 체크포인트 + 다음 phase

| 항목 | 값 |
|------|-----|
| 출력 | 1줄 체크포인트 + KPI 갱신 |
| 작업 | `v10_metrics.yml` append + rotation_log.md 갱신 |
| Hot-swap | phase 종료 시 자동 (IL-7) |
| 다음 phase | 미구현 list > 0 OR drift 잔존 → Step 1 / 모두 해소 → exit |

## 자율 step skip / 추가

`iteration-phase-strategist` 가 자율 판단:

- UI 없는 phase → Step 6 skip
- 신규 endpoint 만 추가 (drift 0) → Step 3 skip (Type A 직접)
- 사용자 explicit override → 명시 step 부터 시작

## Exit 조건

```
exit = (
  reimplementability_pass_rate ≥ 0.9 AND
  drift_direction 명확 (단조 감소) AND
  missing == 0
)
OR user explicit stop
OR circuit_breaker(3 same-fail in same step)
```

미충족 시 IL-2 에 의해 자동 CONTINUE — "보고" = 체크포인트.
