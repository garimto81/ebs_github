---
name: research
description: >
  This skill should be used when the user requests codebase analysis, external research, or AI-powered code review (RPI Phase 1).
version: 2.0.0
triggers:
  keywords:
    - "research"
    - "리서치"
    - "분석"
    - "조사"
---

# /research - 통합 리서치 커맨드

## 실행 방법

```
TeamCreate(team_name="research-session")
Agent(subagent_type="researcher", name="researcher",
     description="리서치 실행",
     team_name="research-session",
     prompt="리서치: [주제]")
SendMessage(type="message", recipient="researcher", content="리서치 시작.")
# 완료 대기 → shutdown_request → TeamDelete()
```

### 에이전트

| 에이전트 | 모델 | 용도 |
|----------|------|------|
| `researcher` | sonnet | 문서/API 리서치 |
| `researcher-low` | haiku | 빠른 문서 조회 |
| `scientist` | sonnet | 데이터 분석 |
| `explore` | haiku | 코드베이스 탐색 |

## 인과관계 (CRITICAL - 절대 보존)

```
/auto Phase 1 Step 1.2 (사전 분석)
    └── /research code (코드 분석 필요 시)
    └── /research web (오픈소스 탐색 필요 시)

/auto Phase 1 Step 1.3 (계획 수립)
    └── /research plan (구현 계획 수립)
```

## 서브커맨드 (100% 보존)

| 서브커맨드 | 설명 |
|-----------|------|
| `/research code [path]` | 코드베이스 분석 |
| `/research web <keyword>` | 오픈소스/솔루션 검색 |
| `/research plan [target]` | 구현 계획 수립 |
| `/research review [scope]` | AI 코드 리뷰 |

## 서브커맨드 상세

### /research code - 코드베이스 분석 (기본값)

```bash
/research                    # 현재 디렉토리 분석
/research code               # 전체 코드베이스 분석
/research code src/api/      # 특정 경로 분석
/research code 123           # 이슈 #123 관련 코드
/research code --codebase    # 전체 구조 분석
/research code --deps        # 의존성 분석
```

### /research web - 오픈소스/솔루션 검색

```bash
/research web "React state management"
/research web "Python async HTTP client"
```

**수행 작업:**
1. 관련 오픈소스 라이브러리 검색
2. Make vs Buy 분석
3. 유사 구현 사례 조사

### /research plan - 구현 계획 수립

```bash
/research plan 123           # 이슈 #123 구현 계획
/research plan "user auth"   # 기능 구현 계획
/research plan --tdd         # TDD 기반 계획
/research plan --detailed    # 상세 계획
```

### /research review - AI 코드 리뷰

```bash
/research review             # staged 변경사항 리뷰
/research review --branch    # 브랜치 전체 변경사항
/research review --pr #42    # 특정 PR 리뷰
/research review --docs      # 문서 일관성 검사
```

## 옵션

| 옵션 | 설명 |
|------|------|
| `--save` | 결과를 `.claude/research/`에 저장 |
| `--quick` | 빠른 탐색 (5분 이내) |
| `--thorough` | 철저한 분석 (15-30분) |

## RPI 워크플로우

```
[R] Research → [P] Plan → [I] Implement
```

| Phase | 커맨드 | 목적 |
|-------|--------|------|
| **R** | `/research` | 정보 수집, 코드 분석 |
| **P** | `/research plan` | 구현 계획 수립 |
| **I** | 구현 | 코드 작성, 테스트 |

## 커맨드 파일 참조

상세 워크플로우: `.claude/commands/research.md`
