---
name: parallel
description: >
  This skill should be used when the user requests multi-agent parallel execution for dev, test, review, or research tasks.
version: 2.0.0
triggers:
  keywords:
    - "parallel"
    - "병렬"
auto_trigger: false
---

# /parallel - 병렬 멀티에이전트 실행

## 실행 방법

```
TeamCreate(team_name="parallel-session")
Agent(subagent_type="executor", name="worker-1",
     description="병렬 작업 1 실행",
     team_name="parallel-session", prompt="작업 1")
Agent(subagent_type="executor", name="worker-2",
     description="병렬 작업 2 실행",
     team_name="parallel-session", prompt="작업 2")
SendMessage(type="message", recipient="worker-1", content="Task 할당.")
SendMessage(type="message", recipient="worker-2", content="Task 할당.")
# 완료 대기 → shutdown_request → TeamDelete()
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

**에이전트 역할:**
| 에이전트 | 역할 |
|----------|------|
| Architect | 설계, 인터페이스 정의 |
| Coder | 핵심 로직 구현 |
| Tester | 테스트 작성 |
| Docs | 문서화 |

### /parallel test - 병렬 테스트

```bash
/parallel test
/parallel test --module auth
/parallel test --strict
```

**테스터 역할:**
| 에이전트 | 범위 |
|----------|------|
| Unit | 함수, 클래스, 모듈 |
| Integration | API, DB 연동 |
| E2E | 전체 사용자 플로우 |
| Security | OWASP Top 10 |

### /parallel review - 병렬 코드 리뷰

```bash
/parallel review
/parallel review src/auth/
/parallel review --security-only
```

**리뷰어 역할:**
| 에이전트 | 검토 항목 |
|----------|----------|
| Security | SQL Injection, XSS |
| Logic | 알고리즘, 엣지 케이스 |
| Style | 명명 규칙, 가독성 |
| Performance | 복잡도, 캐싱 |

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
