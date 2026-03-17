---
name: daily
description: >
  This skill should be used when the user requests daily dashboards, morning briefings, or cross-source analysis from Gmail/Slack/GitHub.
version: 3.1.0

triggers:
  keywords:
    - "daily"
    - "오늘 현황"
    - "일일 대시보드"
    - "프로젝트 진행률"
    - "전체 현황"
    - "데일리 브리핑"
    - "morning briefing"
    - "아침 브리핑"
    - "일일 동기화"
    - "업체 현황"
    - "vendor status"
  file_patterns:
    - "**/daily/**"
    - "**/checklists/**"
    - "**/daily-briefings/**"
  context:
    - "업무 현황"
    - "프로젝트 관리"

auto_trigger: true
---

# Daily Skill v3.0 - 9-Phase Pipeline

3소스(Gmail/Slack/GitHub) 증분 수집 + AI 크로스소스 분석 + 액션 추천 엔진.

**패러다임**: "수집+표시" -> "학습+액션 추천"

**Design Reference**: `C:\claude\docs\02-design\daily-redesign.design.md`

## 실행 규칙 (CRITICAL)

**이 스킬이 활성화되면 반드시 아래 9-Phase Pipeline을 순차 실행하세요!**

```
Phase 0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8
Config   Expert  Collect  Attach  AI     Action  Project  Gmail    State
Bootstrap Context  (incr)  Analyze Analyze Recom   Ops    Housekp  Update
```

## 9-Phase Pipeline 요약

| Phase | 이름 | 핵심 동작 | 에러 처리 |
|:-----:|------|----------|----------|
| 0 | Config Bootstrap | `.project-sync.yaml` 탐색/자동 생성 | CLAUDE.md 없으면 디렉토리명 기반 최소 설정 |
| 1 | Expert Context | 3-Tier 컨텍스트 (Identity/Operational/Deep) | Tier 2 없으면 생략 (초회) |
| 2 | Incremental Collection | Gmail History API + Slack last_ts + GitHub since | 인증 실패 소스 skip, 활성 0개면 중단 |
| 3 | Attachment Analysis | PDF/Excel/이미지 AI 분석, SHA256 캐시 | 다운로드 실패 → skip |
| 4 | AI Cross-Source Analysis | 소스별 독립 + 크로스소스 연결 | 단일 소스 → 독립 분석만 |
| 5 | Action Recommendation | 미응답 48h+, PR 리뷰 대기 3일+ 등 (최대 10건) | 분석 없으면 "액션 불필요" |
| 6 | Project-Specific Ops | vendor: Slack Lists / dev: CI/CD | config 없으면 skip |
| 7 | Gmail Housekeeping | 라벨 자동 적용 + INBOX 정리 | API 실패 → skip |
| 8 | State Update | 커서/Knowledge/Snapshot 갱신 | 쓰기 실패 → 다음 실행 재수집 |

## 서브커맨드

| 커맨드 | 설명 |
|--------|------|
| `/daily` | 전체 대시보드 (9-Phase 전체) |
| `/daily ebs` | EBS 브리핑: `cd C:\claude\ebs\tools\morning-automation && python main.py --post` |

## /auto --daily 연동

`/auto --daily` 실행 시 아래 워크플로우가 적용된다.

### Step 2.0: /auto에서 호출 시

```
Lead가 /auto Step 2.0에서 --daily 옵션 감지 시:
1. 9-Phase Pipeline 전체 실행 (Phase 0-8 순차)
2. 결과를 /auto 컨텍스트에 반환 (액션 추천 + 대시보드)
3. /auto는 daily 결과를 참고하여 구현 진행
```

> **주의**: `/auto --daily`는 구현 전 현황 파악 용도. daily 결과가 /auto Phase 1 계획에 반영된다.

## 상세 참조

> Phase 0-8 상세 설명, Config Bootstrap yaml 예시, Expert Context Tier 세부, 데이터 수집 소스별 상세,
> 첨부파일 분석 방법, 액션 추천 조건, 출력 형식 전체 템플릿 등:
> **Read `references/daily-phases.md`**
