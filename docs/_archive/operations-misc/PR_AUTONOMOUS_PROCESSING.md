---
title: PR Autonomous Processing (V10)
owner: conductor
tier: operations
last-updated: 2026-05-04
---

# PR Autonomous Processing — V10 governance

## 결정 근거

2026-05-04 사용자 명시:

> PR 영역은 온전히 AI 몫. AI 가 결정 못하는 사항은 애초에 일어나서는 안 됨.

V9.0 "Conductor 수동 머지" 정책은 **사용자 결정 떠넘김** = governance 위반. 5일 적체 (8건 미처리) 로 정합성 문제 발현.

V10 정책: **사용자 시야에서 PR 완전 제거. AI 자율 100%.**

## 처리 흐름

```mermaid
flowchart TD
    A[PR 발생] --> B{CI 완료?}
    B -- No --> S1[skip<br/>(다음 sweep)]
    B -- Yes --> C{All checks<br/>pass?}
    C -- Yes --> D[squash merge]
    C -- No --> E{실패 분류}
    E -- conflict --> F[close + backlog]
    E -- breaking dep --> F
    E -- scope-label --> G[label 추가 + 머지 재시도]
    E -- ci-fail < 24h --> S2[skip<br/>(자가 해소 대기)]
    E -- stale 30d+ --> F
```

## 결정 트리 상세

| 상태 | mergeStateStatus | mergeable | 추가 조건 | Action |
|------|------------------|-----------|----------|--------|
| Healthy | CLEAN | MERGEABLE | failures = 0 | **merge** |
| Conflict | DIRTY | CONFLICTING | — | **close** (dependabot 재생성) |
| Conflict (own) | DIRTY | CONFLICTING | non-dependabot, age < 30d | close (수동 rebase 비효율) |
| Scope-label only | UNSTABLE | MERGEABLE | failed = scope-check, missing governance-change | **label-retry** |
| Breaking dep | UNSTABLE | MERGEABLE | log 에 breaking pattern | **close + backlog** |
| Pending | — | — | CI in progress | **skip** |
| CI fail (recent) | UNSTABLE | MERGEABLE | dependabot, age < 24h | skip |
| CI fail (dependabot stale) | UNSTABLE | MERGEABLE | dependabot, age >= 24h | **close** (재생성) |
| Stale | * | * | age >= 30d | **close** |

## Breaking Pattern 감지

`tools/pr_sweep.py` 의 `BREAKING_PATTERNS`:

```python
[
    r"Member not found",
    r"isn't defined for the type",
    r"No named parameter",
    r"Target dart2js failed",
    r"undefined name",
    r"AttributeError:.*has no attribute",
    r"ImportError: cannot import",
    r"ModuleNotFoundError",
]
```

CI 실패 로그에서 위 패턴 매칭 → 자동 close + 백로그.

## 보수적 default 원칙

**확신 없으면 close**. 근거:
- dependabot 은 다음 cycle 에 재생성 (close 비용 = 0)
- 사용자 결정 떠넘김 방지 (governance 정합)
- main 안전 우선 (broken build 방지)

## 트리거

| 트리거 | 빈도 | 용도 |
|--------|------|------|
| `schedule: */30 * * * *` | 30분 | 정기 sweep (CI 완료 PR 캐치) |
| `check_suite: completed` | 즉시 | CI 완료 시 재평가 |
| `workflow_dispatch` | 수동 | 디버깅 / 즉시 sweep |

## Workflow 자산

| 파일 | 역할 |
|------|------|
| `.github/workflows/pr-sweep.yml` | sweep 실행 워크플로우 (V10 entry point) |
| `tools/pr_sweep.py` | 자율 결정 트리 + gh CLI 액션 |
| `.github/workflows/pr-auto-merge.yml` | DISABLED stub (V10 폐기 history) |
| `.github/workflows/dependabot-major-gate.yml` | advisory only (label annotation) |
| `.github/workflows/dependabot-label-guard.yml` | dependabot 라벨 자동 부착 (변경 없음) |
| `.github/workflows/dependabot-recreate-guard.yml` | CI 미트리거 PR 재생성 (변경 없음) |

## 사용자 인터페이스

**사용자가 보는 것**: 통계뿐. 어떤 PR 도 사용자 손에 직접 노출 안 됨.

```
$ python tools/pr_sweep.py
PR Sweep — 8 open PR(s)

  [MERGE] #119  chore(deps:team1): sentry_flutter 8→9
           reason: CI green + mergeable
           result: merged
  [CLOSE] #117  chore(deps:team1): rive 0.13→0.14
           reason: breaking dependency (compile fail)
           result: closed
  ...

Summary: merged=5 closed=3 label-retry=0 skipped=0 errors=0
```

artifact 로 sweep-result.json 14일 보존. 사용자는 인지 부담 0.

## Override (운영자 수동 개입)

긴급 상황 시:
- `--dry-run` 으로 결정 미리보기
- `--pr <N>` 단일 PR 처리
- `gh pr` 직접 호출 가능 (sweep 자동 동기화)

라벨 override:
- `do-not-merge`, `wip` → sweep 처리 skip
- `governance-change` → scope-check 우회

## Migration Path

| 시점 | 상태 |
|------|------|
| 2026-04-29 V9.0 | pr-auto-merge.yml DISABLED (Conductor 수동) |
| **2026-05-04 V10 (현재)** | pr-sweep.yml 활성. 자율 처리. |
| 향후 | metric 30일 모니터링. 적체 발생 시 boost frequency / 결정 트리 보강 |

## 30일 ROI Metric

자가 진화 trigger (`team-policy.json` 후속 갱신):
- `user_pr_question_count_per_week > 0` → governance 실패 신호
- `pr_backlog_size > 5` → sweep frequency 올리기
- `auto_close_rate > 50%` → 결정 트리 결함 (false positive close 가능성)
