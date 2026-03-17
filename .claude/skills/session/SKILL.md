---
name: session
description: >
  This skill should be used when the user needs session management operations like compact, journey, changelog, resume, save, or search.
version: 1.0.0
triggers:
  keywords:
    - "session"
    - "/session"
    - "세션 검색"
    - "세션 저장"
    - "세션 이어가기"
    - "과거 결정"
    - "컨텍스트 압축"
auto_trigger: false
---

# /session - 세션 관리 통합

컨텍스트 압축, 세션 여정 기록, 변경 로그, 세션 이어가기, 키워드 검색을 통합 관리한다.
커맨드 파일: `.claude/commands/session.md`

## 서브커맨드 라우팅

| 서브커맨드 | 동작 | 기본값 |
|-----------|------|--------|
| `compact` | 컨텍스트 압축 | - |
| `journey` | 세션 여정 기록 | `/session` 기본 동작 |
| `changelog` | 변경 로그 생성 | - |
| `resume` | 이전 세션 이어가기 | - |
| `save` | 세션 상태 저장 | - |
| `search` | 과거 세션/결정/학습 키워드 검색 | - |

## 서브커맨드별 실행 로직

### compact — 컨텍스트 압축

컨텍스트 사용량이 높아졌을 때 세션을 압축하여 성능을 유지한다.

```
/session compact              # 즉시 압축
/session compact save         # 압축 결과 파일 저장
/session compact load [date]  # 저장된 압축 로드
/session compact status       # 현재 컨텍스트 사용량 확인
```

**실행 흐름**:
1. 현재 컨텍스트 사용량 측정
2. 완료된 태스크 → 1줄 요약, 탐색 파일 → 경로만, 에러 로그 → 핵심만 보존
3. 진행 중 태스크, 핵심 의사결정, 미해결 이슈는 보존
4. 압축 결과를 `.claude/compacts/{date}-session.md`에 저장 (save 옵션 시)

**임계값**: 0-40% Safe, 40-60% 주의, 60-80% 압축 권장, 80%+ 즉시 압축

### journey — 세션 여정 기록

현재 세션의 작업 흐름, 의사결정, 변경 파일을 기록한다.

```
/session journey              # 현재 세션 표시 (기본값)
/session journey save         # 세션 저장
/session journey export       # PR용 마크다운 생성
```

**실행 흐름**:
1. 세션 시작 시점부터 milestones, decisions, files_changed, blockers 자동 수집
2. `/create pr` 실행 시 여정 섹션이 PR 본문에 자동 포함
3. 저장 시 `.claude/sessions/{date}-session.json`에 기록

### changelog — 변경 로그 생성

커밋 히스토리를 분석하여 CHANGELOG.md를 업데이트한다.

```
/session changelog            # Unreleased에 추가
/session changelog 1.2.0      # 특정 버전으로 릴리즈
```

**실행 흐름**:
1. `git log` 분석 → 커밋 접두어별 분류 (feat→Added, fix→Fixed, refactor→Changed)
2. Keep a Changelog 형식으로 CHANGELOG.md 업데이트
3. PRD 링크 자동 연결 (커밋 메시지에 PRD 참조 있을 때)

### resume — 이전 세션 이어가기

저장된 세션 상태를 로드하여 미완료 작업을 이어간다.

```
/session resume               # 최근 세션 로드
/session resume list          # 저장된 세션 목록
/session resume [date]        # 특정 날짜 세션 로드
```

**실행 흐름**:
1. `.claude/sessions/`에서 저장된 상태 파일 검색
2. 세션 상태 로드 및 요약 표시
3. 미완료 항목을 TodoWrite로 자동 등록
4. 핵심 파일 경로, 브랜치 정보 등 컨텍스트 복원

### save — 세션 상태 저장

세션 종료 전 현재 작업 상태를 저장한다.

```
/session save                 # 현재 상태 저장
/session save "작업 설명"      # 설명과 함께 저장
```

**저장 내용**: 진행 중 작업 (이슈, 브랜치, 진행률), 완료/미완료 항목, 핵심 컨텍스트 (파일, 결정), 다음 단계

### search — 과거 세션 키워드 검색

저장된 세션, 결정 기록, 학습 내용을 키워드로 검색한다.

```
/session search <keyword>           # 키워드 검색
/session search <keyword> --recent  # 최근 7일만
/session search <keyword> --type decisions  # 결정 기록만
```

**검색 대상**:
- `.claude/sessions/*.md` — 저장된 세션 상태
- `.claude/compacts/*.md` — 압축된 세션 요약
- `docs/notepads/*/learnings.md` — 기술 발견/패턴
- `docs/notepads/*/decisions.md` — 아키텍처/설계 결정
- `docs/notepads/*/issues.md` — 알려진 이슈/해결책

**실행 흐름**: Grep으로 검색 → 날짜순 정렬 → 매치 주변 컨텍스트 (+-3줄) 포함

## 저장 경로

```
.claude/
├── compacts/          # compact 결과
├── sessions/          # save/journey 결과
└── research/          # 연구 자료
```

## /auto 연동

| /auto Phase | session 서브커맨드 | 연동 |
|-------------|-------------------|------|
| Phase 0 INIT | resume | 이전 세션 컨텍스트 복원 |
| Phase 4 CLOSE | save, journey | 세션 상태 저장 + 여정 기록 |
| 릴리즈 시 | changelog | CHANGELOG.md 자동 업데이트 |

## 권장 워크플로우

```
[세션 시작] /session resume → [작업 진행] → [종료 전] /session save → [다음 세션] /session resume
```

## 관련 스킬

| 스킬 | 관계 |
|------|------|
| `/auto` | Phase 0/4에서 session 자동 호출 |
| `/commit` | changelog가 커밋 히스토리 분석 |
| `/pr` | journey가 PR 본문에 자동 포함 |
