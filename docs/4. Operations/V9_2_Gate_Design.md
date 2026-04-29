---
title: V9.2 Gate Design (3-gate enforcement scaffolding)
owner: conductor
tier: contract
last-updated: 2026-04-29
governance: v9.2
related: ["TDB-011", "Multi_Session_Workflow.md"]
---

# V9.2 Gate Design

> **목적**: V9.2 Hub-and-Spoke 워크플로우의 enforcement 를 정책 문서가 아닌 **실제 차단 메커니즘** 으로 구현. `infra/v92-gates` 브랜치 첫 PR 의 산출물.

## 🎯 설계 원칙

| 원칙 | 구현 |
|------|------|
| **사전 분리** | Conductor dispatch 시 scope 명시 → cross-PR overlap 검출 |
| **자동 검증** | `tools/scope_check.py` (PR 시 카테고리 + 라벨 검증) |
| **머지 게이트** | `tools/team_v92_safe_merge.py` (scope + CI + reviews 통합 체크) |
| **물리적 차단** | `.githooks/pre-push` (main 직접 push 금지) |
| **로깅 가시성** | 차단 사유 명확 출력 + GitHub Actions 로그 보존 |

## 📁 자산 구성

| 파일 | 역할 |
|------|------|
| `tools/scope_check.py` | PR 변경 카테고리 분류 + 라벨 검증 |
| `tools/team_v92_safe_merge.py` | 머지 전 통합 체크리스트 (scope/CI/reviews) |
| `.github/workflows/v92-scope-check.yml` | PR 이벤트 시 scope_check 자동 실행 |
| `.githooks/pre-push` | main 직접 push 차단 + work/infra/feat/fix/chore allowlist |
| `docs/4. Operations/V9_2_Gate_Design.md` | 본 문서 |

## 🚦 카테고리 분류 (scope_check 기준)

| 카테고리 | Path 패턴 | 검증 라벨 |
|----------|-----------|-----------|
| `governance` | `docs/2. Development/2.5 Shared/`, `.github/CODEOWNERS`, `.github/workflows/`, `.githooks/`, `.claude/hooks/` | **governance-change 필수** |
| `docs` | `docs/**` (governance 제외) | — |
| `tools` | `tools/`, `scripts/` | — |
| `team1~4` | 팀별 코드 + docs 폴더 | — |
| `tests` | `tests/`, `*_test.py`, `*.spec.ts/js` | — |
| `mixed` | 2 카테고리 이상 | **mixed-scope 필수** |

## 🛡 차단 규칙

| 행위 | 차단 layer | 사유 |
|------|------------|------|
| `git push origin main` | `.githooks/pre-push` | V9.2 정책: main 은 PR 경로만 |
| governance PR + governance-change 라벨 없음 | `tools/scope_check.py` (CI) | 거버넌스 변경은 명시 라벨 필수 |
| 다중 카테고리 PR + mixed-scope 라벨 없음 | `tools/scope_check.py` (CI) | 단일 목적 권장 |
| CI 실패 PR 머지 시도 | `tools/team_v92_safe_merge.py` | 모든 status 통과 필수 |

## 🔧 활성화 절차

### 1. CI workflow (즉시 활성)
PR merge 시 자동 활성화. 별도 작업 불필요.

### 2. pre-push hook (선택 활성화)
```bash
# 사용자 로컬에서 활성화
git config core.hooksPath .githooks
```

기본 inactive. 사용자가 명시적으로 활성화. 무력화 시 `git config --unset core.hooksPath`.

### 3. CODEOWNERS 갱신 (별도 PR)
본 PR 은 인프라 스캐폴딩만 포함. 실제 CODEOWNERS 항목 추가는 사용자 의도 결정 영역이므로 후속 PR 분리.

권장 default (Conductor 가 모든 거버넌스/CI 소유):
```
# governance
docs/2. Development/2.5 Shared/  @garimto81
.github/CODEOWNERS               @garimto81
.github/workflows/               @garimto81
.githooks/                       @garimto81

# team-owned
docs/2. Development/2.1 Frontend/  @garimto81
docs/2. Development/2.2 Backend/   @garimto81
docs/2. Development/2.3 Game Engine/  @garimto81
docs/2. Development/2.4 Command Center/  @garimto81

team1-frontend/  @garimto81
team2-backend/   @garimto81
team3-engine/    @garimto81
team4-cc/        @garimto81
```

1인 사용자 환경에서는 모든 owner 가 동일. 향후 협업 확장 시 각 팀 멤버로 분기.

## 📊 V9.2 critic 결함 정합

| critic ID | 결함 | 본 PR 의 해소 |
|-----------|------|---------------|
| **M1** | enforcement 부재 (auto-merge 라벨 정책만) | `scope_check` + `pre-push` + `safe_merge` 3 layer 도입 |
| **H1** | governance self-modification 정합성 | governance-change 라벨 + 2 approval 요구 |
| **M4** | SSOT tie-breaker 부재 | (별도 후속 PR — Foundation > team-policy > 2.5 Shared > APIs/Backlog 명문화) |

## 🔄 운영 가이드

### Worker (자율 머지 권한, 충돌 없는 PR 한정)
1. `tools/team_v92_safe_merge.py --pr <NN>` 실행 — dry-run 결과 확인
2. 모든 게이트 PASS → `--merge` flag 추가하여 squash merge
3. 어느 게이트라도 FAIL → PR 에 `conflict` 라벨 + Conductor 알림

### Conductor (충돌 PR 처리)
1. `gh pr list --label conflict` 로 큐 확인
2. 단일 스레드로 순차 리뷰
3. SSOT 기반 의미적 충돌 해소 + rebase
4. `tools/team_v92_safe_merge.py --pr <NN> --merge`

## 🚧 후속 작업 (별도 PR)

- **CODEOWNERS 항목 등록** — 사용자 의도 결정 후
- **SSOT tie-breaker 명문화** — `team-policy.json` `governance_model.conflict_resolution.ssot_priority`
- **30일 ROI 측정 frame** — `Reports/v92_metrics.yml`
- **Mode A trigger 자동 감지** — `tools/v92_active_check.py`

## 🔗 관련 문서

- `docs/4. Operations/Multi_Session_Workflow.md` — V9.2 SOP
- `docs/4. Operations/Task_Dispatch_Board.md` — TDB-011 작업
- `docs/2. Development/2.5 Shared/team-policy.json` — governance_model
