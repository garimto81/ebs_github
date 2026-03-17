---
name: debug
description: >
  This skill should be used when the user needs hypothesis-verification based debugging with structured Phase Gate D0-D4.
version: 2.0.0
triggers:
  keywords:
    - "debug"
    - "/debug"
    - "디버깅"
auto_trigger: false
---

# /debug - 체계적 디버깅

가설-검증 기반 5단계 디버깅 프로세스. architect 에이전트가 원인 분석을 수행하고, 필요 시 executor가 수정을 실행한다.

## 실행 방법

```
TeamCreate(team_name="debug-session")
Agent(subagent_type="architect", name="debugger",
     description="디버깅 원인 분석",
     team_name="debug-session",
     prompt="문제 원인 분석: [에러 내용]")
SendMessage(type="message", recipient="debugger", content="디버깅 시작.")
# 완료 대기 → shutdown_request → TeamDelete()
```

수정이 필요한 경우 architect 분석 완료 후 executor를 추가 투입:

```
Agent(subagent_type="executor-high", name="fixer",
     description="디버깅 수정 구현",
     team_name="debug-session",
     prompt="architect 분석 결과 기반 수정: [분석 내용]")
SendMessage(type="message", recipient="fixer", content="수정 시작.")
```

## 디버깅 Phase Gate (D0-D4)

### D0: 문제 정의 (재현)

- 에러 메시지, 스택 트레이스, 재현 조건 수집
- 영향 범위 파악 (어떤 기능, 어떤 파일)
- 재현 가능 여부 확인 — 재현 불가 시 로그/환경 추가 수집
- **산출물**: 문제 정의서 (에러, 재현 단계, 영향 범위)

### D1: 가설 수립

- D0 정보 기반으로 원인 가설 3개 이내 도출
- 각 가설에 확률 부여 (높음/중간/낮음)
- 검증 순서 결정 (확률 높은 것부터)
- **산출물**: 가설 목록 + 검증 계획

### D2: 검증 실행

- 가설별 검증 수행 (코드 추적, 로그 확인, 테스트 실행)
- 각 가설의 확인/기각 기록
- 원인 확정 시 file:line 수준으로 특정
- **산출물**: 검증 결과 + 근본 원인 (Root Cause)

### D3: 수정

- 근본 원인에 대한 최소 수정 적용
- 수정 후 재현 테스트 — 문제 해결 확인
- 부작용 검증 (관련 테스트 실행)
- **산출물**: 수정 코드 + 테스트 통과 증거

### D4: 회고

- 근본 원인 요약 (1-2줄)
- 재발 방지 조치 (테스트 추가, 가드 코드 등)
- 학습 사항 기록 (MEMORY.md 또는 notepads)
- **산출물**: 회고 보고서

## 에이전트 매핑

| Phase | 에이전트 | subagent_type | 역할 |
|-------|---------|---------------|------|
| D0-D2 | debugger | architect | 문제 정의, 가설 수립, 검증 (READ-ONLY) |
| D3 | fixer | executor-high | 수정 구현 (코드 변경) |
| D4 | debugger | architect | 회고 및 재발 방지 분석 |

> architect는 READ-ONLY — 코드 수정이 필요하면 반드시 executor 계열 사용.

## /auto 연동 (인과관계)

`/auto` Phase 2 BUILD 중 빌드/테스트 실패 시 자동 트리거:

```
/auto Phase 2 (BUILD)
  └─ 빌드 실패 또는 테스트 실패 감지
  └─ /debug 자동 호출 (D0-D3)
  └─ 수정 완료 → /auto Phase 2 복귀
```

수동 호출도 가능: 사용자가 `/debug` 또는 "디버깅" 키워드 사용 시 직접 실행.

## Phase Gate 규칙

- 각 Phase는 산출물 없이 다음 Phase로 진행 불가
- D2에서 모든 가설 기각 시 → D1로 회귀 (새 가설 수립)
- D3 수정 후 재현 테스트 실패 시 → D2로 회귀
- 3회 회귀 시 → 사용자에게 보고 + 판단 요청

## 관련 스킬

| 스킬 | 관계 |
|------|------|
| `/auto` | Phase 2 빌드 실패 시 /debug 호출 |
| `/check` | 수정 후 품질 검증에 사용 |
| `/tdd` | D3 수정 시 테스트 우선 작성 |
