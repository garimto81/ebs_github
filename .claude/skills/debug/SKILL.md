---
name: debug
description: 가설-검증 기반 디버깅
version: 3.0.0
team_pattern: true
agents:
  - architect
triggers:
  keywords:
    - "debug"
    - "/debug"
    - "디버깅"
---

# /debug - 체계적 디버깅

## Agent Teams 실행

이 스킬은 Agent Teams 패턴으로 디버깅을 실행합니다.

### 실행 방법

```
# Step 1: 팀 생성
TeamCreate(team_name="debug-{issue}")

# Step 2: Architect 에이전트 스폰 (문제 분석)
Agent(
  subagent_type="architect",
  name="debug-analyst",
  description="문제 원인 분석 및 해결",
  team_name="debug-{issue}",
  model="opus",
  prompt="문제 원인을 분석하세요: {에러 내용}

  D0: 문제 정의 — 재현 조건, 기대 동작, 실제 동작
  D1: 가설 수립 — 가능한 원인 3개 이상 나열
  D2: 검증 — 각 가설을 코드/로그로 검증
  D3: 해결 — 근본 원인 수정
  D4: 회고 — 재발 방지 조치"
)

# Step 3: 완료 후 정리
SendMessage(to="debug-analyst", message={type: "shutdown_request"})
TeamDelete()
```

## 디버깅 Phase

1. D0: 문제 정의
2. D1: 가설 수립
3. D2: 검증
4. D3: 해결
5. D4: 회고
