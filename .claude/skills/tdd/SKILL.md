---
name: tdd
description: Guide Test-Driven Development with Red-Green-Refactor discipline
version: 3.0.0
team_pattern: true
agents:
  - tdd-guide
  - tdd-guide-low
triggers:
  keywords:
    - "tdd"
    - "TDD"
    - "테스트 먼저"
    - "test first"
    - "Red-Green"
---

# /tdd - Test-Driven Development

## Agent Teams 실행

이 스킬은 Agent Teams 패턴으로 TDD 워크플로우를 실행합니다.

### 실행 방법

```
# Step 1: 팀 생성
TeamCreate(team_name="tdd-{feature}")

# Step 2: TDD 가이드 에이전트 스폰
Agent(
  subagent_type="tdd-guide",
  name="tdd-runner",
  description="TDD Red-Green-Refactor 워크플로우 실행",
  team_name="tdd-{feature}",
  model="sonnet",
  prompt="TDD 워크플로우를 실행하세요: {기능 설명}

  1. Red: 실패하는 테스트 먼저 작성 → pytest -v (FAIL 확인)
  2. Green: 테스트 통과하는 최소 코드 작성 → pytest -v (PASS 확인)
  3. Refactor: 코드 개선 (테스트 유지) → pytest -v (PASS 유지)

  각 단계마다 커밋:
  - test: Add {feature} test (RED) 🔴
  - feat: Implement {feature} (GREEN) 🟢
  - refactor: Improve {feature} ♻️"
)

# Step 3: 완료 후 정리
SendMessage(to="tdd-runner", message={type: "shutdown_request"})
TeamDelete()
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

/work --loop Tier 3
    └── /tdd <feature> (새 기능 구현 요청 시)
```

**이 인과관계는 Agent Teams 전환과 무관하게 그대로 유지됩니다.**

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
