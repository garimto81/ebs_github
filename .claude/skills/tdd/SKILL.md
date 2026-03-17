---
name: tdd
description: >
  This skill should be used when the user requests Test-Driven Development guidance with Red-Green-Refactor discipline.
version: 2.0.0
triggers:
  keywords:
    - "tdd"
    - "TDD"
    - "테스트 먼저"
    - "test first"
    - "Red-Green"
---

# /tdd - Test-Driven Development

## 실행 방법

```
TeamCreate(team_name="tdd-session")
Agent(subagent_type="tdd-guide", name="tdd-runner",
     description="TDD 워크플로우 실행",
     team_name="tdd-session",
     prompt="TDD 워크플로우 실행: [기능 설명]")
SendMessage(type="message", recipient="tdd-runner", content="TDD 시작.")
# 완료 대기 → shutdown_request → TeamDelete()
```

### 에이전트

| 에이전트 | 모델 | 용도 |
|----------|------|------|
| `tdd-guide` | sonnet | 표준 TDD 워크플로우 |
| `tdd-guide-low` | haiku | 간단한 테스트 제안 |

## 인과관계 (CRITICAL - 절대 보존)

```
/auto Tier 5 AUTONOMOUS
    └── /tdd <feature> (테스트 없는 코드 감지 시)

/auto Tier 3
    └── /tdd <feature> (새 기능 구현 요청 시)
```


## Red-Green-Refactor Cycle

### 🔴 Red: 실패하는 테스트 작성

```bash
# 테스트 파일 먼저 작성
pytest tests/test_feature.py -v
# ❌ FAILED - 예상된 동작

git commit -m "test: Add feature test (RED) 🔴"
```

### 🟢 Green: 최소 구현

```bash
# 테스트 통과하는 최소 코드
pytest tests/test_feature.py -v
# ✅ PASSED

git commit -m "feat: Implement feature (GREEN) 🟢"
```

### ♻️ Refactor: 코드 개선

```bash
# 테스트 유지하며 개선
pytest tests/test_feature.py -v
# ✅ PASSED (유지)

git commit -m "refactor: Improve feature ♻️"
```

## 사용법

```bash
/tdd <feature-name>

# 예시
/tdd user-authentication
/tdd payment-processing
```

## 커맨드 파일 참조

상세 워크플로우: `.claude/commands/tdd.md`
