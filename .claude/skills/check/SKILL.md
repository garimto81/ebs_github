---
name: check
description: 코드 품질 및 보안 검사
version: 3.0.0
team_pattern: true
agents:
  - qa-tester
  - architect
triggers:
  keywords:
    - "check"
    - "/check"
    - "검사"
---

# /check - 코드 품질 검사

## Agent Teams 실행

이 스킬은 Agent Teams 패턴으로 QA 사이클을 실행합니다.

### 실행 방법

```
# Step 1: 팀 생성
TeamCreate(team_name="check-{scope}")

# Step 2: QA 에이전트 스폰
Agent(
  subagent_type="qa-tester",
  name="qa-checker",
  description="코드 품질 및 보안 검사 실행",
  team_name="check-{scope}",
  model="sonnet",
  prompt="코드 품질 검사를 실행하세요.

  검사 항목:
  1. ruff check src/ --fix (린트)
  2. pytest tests/ -v (테스트)
  3. 보안 취약점 스캔

  실패 시 자동 수정 후 재실행 (최대 3회)."
)

# Step 3: 완료 후 정리
SendMessage(to="qa-checker", message={type: "shutdown_request"})
TeamDelete()
```

### QA 사이클
1. 테스트 실행
2. 실패 시 수정
3. 통과까지 반복

## 직접 실행 (옵션)

```bash
# 린트
ruff check src/ --fix

# 테스트
pytest tests/ -v
```
