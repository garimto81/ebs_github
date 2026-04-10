---
name: parallel
description: Multi-agent parallel execution (dev, test, review, research)
version: 3.0.0
team_pattern: true
agents:
  - executor
  - executor-high
  - qa-tester
  - architect
triggers:
  keywords:
    - "parallel"
    - "병렬"
    - "ulw"
    - "ultrawork"
---

# /parallel - 병렬 멀티에이전트 실행

## Agent Teams 실행

이 스킬은 Agent Teams 패턴으로 병렬 작업을 실행합니다.

### 실행 방법

```
# Step 1: 팀 생성
TeamCreate(team_name="parallel-{task}")

# Step 2: 병렬 에이전트 스폰 (동시에 여러 Agent 호출)
Agent(
  subagent_type="executor",
  name="worker-1",
  description="병렬 작업 1 실행",
  team_name="parallel-{task}",
  model="sonnet",
  prompt="작업 1: ..."
)

Agent(
  subagent_type="executor",
  name="worker-2",
  description="병렬 작업 2 실행",
  team_name="parallel-{task}",
  model="sonnet",
  prompt="작업 2: ..."
)

# Step 3: 모든 작업 완료 후 정리
SendMessage(to="worker-1", message={type: "shutdown_request"})
SendMessage(to="worker-2", message={type: "shutdown_request"})
TeamDelete()
```

### 에이전트

| 에이전트 | 모델 | 용도 |
|----------|------|------|
| `executor` | sonnet | 일반 구현 작업 |
| `executor-high` | opus | 복잡한 구현 |
| `qa-tester` | sonnet | 테스트 작업 |
| `architect` | opus | 아키텍처 분석 |

## 서브커맨드 (100% 보존)

| 서브커맨드 | 설명 | 에이전트 수 |
|-----------|------|:-----------:|
| `/parallel dev` | 병렬 개발 | 4 |
| `/parallel test` | 병렬 테스트 | 4 |
| `/parallel review` | 병렬 코드 리뷰 | 4 |
| `/parallel research` | 병렬 리서치 | 4 |
| `/parallel check` | 충돌 검사 | 1 |

## 서브커맨드 상세

### /parallel dev - 병렬 개발

```bash
/parallel dev "사용자 인증 기능"
/parallel dev --branch "API + UI 동시 개발"
```

**Agent Teams 패턴:**
```
TeamCreate(team_name="parallel-dev-{feature}")

Agent(subagent_type="architect", name="arch", description="설계, 인터페이스 정의", team_name="parallel-dev-{feature}", model="opus", prompt="...")
Agent(subagent_type="executor", name="coder", description="핵심 로직 구현", team_name="parallel-dev-{feature}", model="sonnet", prompt="...")
Agent(subagent_type="qa-tester", name="tester", description="테스트 작성", team_name="parallel-dev-{feature}", model="sonnet", prompt="...")
Agent(subagent_type="writer", name="docs", description="문서화", team_name="parallel-dev-{feature}", model="haiku", prompt="...")

# 완료 후
SendMessage(to="arch", message={type: "shutdown_request"})
SendMessage(to="coder", message={type: "shutdown_request"})
SendMessage(to="tester", message={type: "shutdown_request"})
SendMessage(to="docs", message={type: "shutdown_request"})
TeamDelete()
```

### /parallel test - 병렬 테스트

```bash
/parallel test
/parallel test --module auth
/parallel test --strict
```

**Agent Teams 패턴:**
```
TeamCreate(team_name="parallel-test")

Agent(subagent_type="qa-tester", name="unit-tester", description="함수, 클래스, 모듈 테스트", team_name="parallel-test", model="sonnet", prompt="...")
Agent(subagent_type="qa-tester", name="integration-tester", description="API, DB 연동 테스트", team_name="parallel-test", model="sonnet", prompt="...")
Agent(subagent_type="qa-tester", name="e2e-tester", description="전체 사용자 플로우 테스트", team_name="parallel-test", model="sonnet", prompt="...")
Agent(subagent_type="security-reviewer", name="security-tester", description="OWASP Top 10 보안 테스트", team_name="parallel-test", model="sonnet", prompt="...")

# 완료 후 shutdown + TeamDelete()
```

### /parallel review - 병렬 코드 리뷰

```bash
/parallel review
/parallel review src/auth/
/parallel review --security-only
```

**Agent Teams 패턴:**
```
TeamCreate(team_name="parallel-review")

Agent(subagent_type="security-reviewer", name="security-reviewer", description="SQL Injection, XSS 검토", team_name="parallel-review", model="sonnet", prompt="...")
Agent(subagent_type="code-reviewer", name="logic-reviewer", description="알고리즘, 엣지 케이스 검토", team_name="parallel-review", model="sonnet", prompt="...")
Agent(subagent_type="code-reviewer", name="style-reviewer", description="명명 규칙, 가독성 검토", team_name="parallel-review", model="haiku", prompt="...")
Agent(subagent_type="architect", name="perf-reviewer", description="복잡도, 캐싱 검토", team_name="parallel-review", model="sonnet", prompt="...")

# 완료 후 shutdown + TeamDelete()
```

### /parallel research - 병렬 리서치

```bash
/parallel research "React vs Vue 비교"
/parallel research "AI 코딩 도구"
```

### /parallel check - 충돌 검사

```bash
/parallel check "Task A, Task B, Task C"
/parallel check --tasks tasks.md
```

**병렬 작업 전 파일 충돌 가능성 사전 분석:**
```
┌──────────────┬────┬────┬────┬─────────┐
│ 파일         │ A  │ B  │ C  │ 충돌    │
├──────────────┼────┼────┼────┼─────────┤
│ auth.ts      │ W  │ R  │ -  │ -       │
│ user.ts      │ W  │ W  │ -  │ ⚠️ A-B  │
└──────────────┴────┴────┴────┴─────────┘
```

## 커맨드 파일 참조

상세 워크플로우: `.claude/commands/parallel.md`
