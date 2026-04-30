---
name: agent-teamworks
description: Multi-Agent Team Workflow - 10개 전문 팀 자율 협업 시스템 (V10.0 — 4 base + 6 iteration)
version: 3.0.0
team_pattern: true
agents:
  - executor
  - executor-high
  - architect
  - planner
  - iteration-runner
  - iteration-phase-strategist
  - iteration-curator-a
  - iteration-curator-b
triggers:
  keywords:
    - "/team"
    - "/teamwork"
    - "/iteration"
    - "team dev"
    - "team quality"
    - "team ops"
    - "team research"
    - "team strategy"
    - "team iteration"
    - "team spec custody"
    - "team spec quality"
    - "team spec evolution"
    - "team prototype validation"
model_preference: sonnet
auto_trigger: true
---

# Agent Teamworks - Multi-Agent Team Workflow (V10.0)

> 10개 전문 팀이 Agent Teams 패턴으로 자율 협업하는 시스템.
> **V10.0 (2026-04-30)**: 기존 4팀 (Dev/Quality/Ops/Research) + Strategy 1팀 + Iteration 영역 5팀 (Iteration / Spec Custody / Spec Quality / Spec Evolution / Prototype Validation).

## V10.0 10팀 매트릭스

| 팀 | 핵심 agent | 트리거 | 비고 |
|----|-----------|--------|------|
| **Dev** | executor / architect / code-reviewer | 코드 구현 | 기존 |
| **Quality** | qa-tester / code-reviewer + iteration-e2e-orchestrator | e2e + drift 검증 | iteration agent 합류 |
| **Ops** | devops-engineer / security | CI/CD / 인프라 | 기존 |
| **Research** | researcher / analyst / Explore | 코드/웹 리서치 | 기존 |
| **Strategy** | planner / architect | 큰 그림 설계 | V10.0 신규 |
| **Iteration** | iteration-runner / iteration-phase-strategist / iteration-curator-{a,b} | /iteration cycle | V10.0 핵심 |
| **Spec Custody** | iteration-spec-author / iteration-spec-classifier | spec 작성 / 보강 | V10.0 신규 |
| **Spec Quality** | iteration-spec-coherence / iteration-spec-validator | spec 모순 / 재구현성 | V10.0 신규 |
| **Spec Evolution** | iteration-drift-reconciler / iteration-decision-archivist | drift 분류 / 결정 archive | V10.0 신규 |
| **Prototype Validation** | iteration-prototype-validator / iteration-screenshot-verifier / iteration-e2e-orchestrator | feasibility / UI / e2e | V10.0 신규 |

> 6 iteration 팀 모두 `iteration-` prefix agent 만 사용 (격리 원칙 IL-5).

## 아키텍처

```
/auto (복잡도 기반 라우팅)
  │
  ├─ score < 4 → 기존 경로
  └─ score >= 4 → Team Coordinator
                    │
        ┌───────────┼───────────┬───────────┐
        ▼           ▼           ▼           ▼
    Dev Team    Quality Team  Ops Team   Research Team
```

## 서브커맨드

| 커맨드 | 동작 |
|--------|------|
| `/team dev "작업"` | Dev Team 단독 실행 |
| `/team quality "작업"` | Quality Team 단독 실행 |
| `/team ops "작업"` | Ops Team 단독 실행 |
| `/team research "작업"` | Research Team 단독 실행 |
| `/teamwork "프로젝트"` | Coordinator → 4팀 오케스트레이션 |
| `/team status` | 현재 팀 실행 상태 조회 |

## Agent Teams 실행

### `/team {팀명} "작업"` 실행 시

```
# Step 1: 팀 생성
TeamCreate(team_name="team-{팀명}-{task}")

# Step 2: 팀 에이전트 스폰
Agent(
  subagent_type="executor",
  name="{팀명}-executor",
  description="{팀명} Team 작업 실행",
  team_name="team-{팀명}-{task}",
  model="sonnet",
  prompt="{작업 설명}"
)

# Step 3: 완료 후 정리
SendMessage(to="{팀명}-executor", message={type: "shutdown_request"})
TeamDelete()
```

### `/teamwork "프로젝트"` 실행 시 (4팀 오케스트레이션)

```
# Step 1: 프로젝트 팀 생성
TeamCreate(team_name="teamwork-{project}")

# Step 2: 4팀 병렬 스폰
Agent(
  subagent_type="architect",
  name="dev-lead",
  description="Dev Team: 설계 + 구현",
  team_name="teamwork-{project}",
  model="opus",
  prompt="Dev Team Lead로서 프로젝트를 진행하세요: {프로젝트 설명}
  역할: Architect → Frontend/Backend → Tester → Docs → Integrator"
)

Agent(
  subagent_type="qa-tester",
  name="quality-lead",
  description="Quality Team: PDCA 검증",
  team_name="teamwork-{project}",
  model="sonnet",
  prompt="Quality Team Lead로서 품질 검증을 수행하세요: {프로젝트 설명}
  역할: Reviewer → Analyzer → GapDetector → SecurityChecker"
)

Agent(
  subagent_type="researcher",
  name="research-lead",
  description="Research Team: 조사 및 분석",
  team_name="teamwork-{project}",
  model="sonnet",
  prompt="Research Team Lead로서 리서치를 수행하세요: {프로젝트 설명}
  역할: CodeAnalyst → WebResearcher → DataScientist → Synthesizer"
)

# Step 3: 팀 간 조율 (SendMessage 활용)
SendMessage(to="dev-lead", summary="리서치 결과 전달", message="research-lead 결과: ...")
SendMessage(to="quality-lead", summary="구현 결과 검증 요청", message="dev-lead 구현 완료: ...")

# Step 4: 모든 팀 완료 후 정리
SendMessage(to="dev-lead", message={type: "shutdown_request"})
SendMessage(to="quality-lead", message={type: "shutdown_request"})
SendMessage(to="research-lead", message={type: "shutdown_request"})
TeamDelete()
```

## 팀 구성

### Dev Team
TeamLead → [Architect, Frontend, Backend, Tester, Docs] → Integrator

### Quality Team (PDCA)
Planner → [Reviewer, Analyzer, GapDetector, SecurityChecker] → Iterator/Reporter
- gap < 90%: Iterator → 재검증 (최대 5회)
- gap >= 90%: Reporter → 보고서

### Ops Team
TeamLead → [CI_CD, Infra, Monitor, Security] → Integrator

### Research Team
TeamLead → [CodeAnalyst, WebResearcher, DataScientist, DocSearcher] → Synthesizer

## 복잡도 → 팀 배치

| 점수 | 투입 팀 |
|:----:|---------|
| 0-3 | 기존 경로 |
| 4-5 | Dev |
| 6-7 | Dev + Quality |
| 8-9 | Dev + Quality + Research |
| 10 | 4팀 전체 |
| **iteration** | Iteration + (조건부 Dev + Quality + Spec Custody + Spec Quality + Spec Evolution + Prototype Validation) — phase-strategist 자율 |

## V10.0 Iteration 워크플로우

`/iteration` 호출 시 Iteration Team 이 phase-strategist + runner + hot-swap curators 로 cycle 시작.
상세는 `.claude/skills/iteration/SKILL.md` (entry point), `workflows/impl-first-7-step.md`, `workflows/spec-first-5-step.md`, `curators/swap_policy.md` 참조.

| Phase | 활성화되는 팀 |
|-------|--------------|
| Impl-first Step 1 (구현) | Dev |
| Impl-first Step 2 (감지) | Quality |
| Impl-first Step 3 (결정) | Spec Evolution + Spec Quality |
| Impl-first Step 4a (spec 수정) | Spec Custody + Spec Quality |
| Impl-first Step 4b (코드 수정) | Dev |
| Impl-first Step 5 (e2e) | Quality |
| Impl-first Step 6 (스크린샷, UI 만) | Prototype Validation |
| Impl-first Step 7 (체크포인트) | Iteration (curator swap) |
| Spec-first Step 1 (spec) | Spec Custody |
| Spec-first Step 2 (재구현성) | Spec Quality |
| Spec-first Step 3 (feasibility) | Prototype Validation |
| Spec-first Step 4 (분기) | Iteration (phase-strategist) |
| Spec-first Step 5 (archive) | Spec Evolution |

## 코드 위치

| 파일 | 역할 |
|------|------|
| `src/agents/teams/base_team.py` | 추상 기반 클래스 |
| `src/agents/teams/prompts.py` | 프롬프트 중앙 관리 |
| `src/agents/teams/dev_team.py` | Dev Team |
| `src/agents/teams/quality_team.py` | Quality Team |
| `src/agents/teams/ops_team.py` | Ops Team |
| `src/agents/teams/research_team.py` | Research Team |
| `src/agents/teams/coordinator.py` | Coordinator |
