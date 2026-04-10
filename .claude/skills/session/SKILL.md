---
name: session
description: 세션 관리 통합 (compact, journey, changelog, resume, search)
triggers:
  keywords:
    - "session"
    - "세션 검색"
    - "과거 결정"
---

# /session

이 스킬은 `.claude/commands/session.md` 커맨드 파일의 내용을 실행합니다.

## 서브커맨드 라우팅

| 서브커맨드 | 동작 |
|-----------|------|
| `compact` | 컨텍스트 압축 |
| `journey` | 세션 여정 기록 |
| `changelog` | 변경 로그 생성 |
| `resume` | 이전 세션 이어가기 |
| `save` | 세션 상태 저장 |
| `search` | 과거 세션/결정/학습 키워드 검색 |

## Usage

```bash
/session compact                # 컨텍스트 압축
/session journey                # 세션 여정 기록 생성
/session changelog              # 변경 로그 생성
/session resume                 # 이전 세션 이어가기
/session save                   # 현재 세션 상태 저장
/session search "키워드"         # 과거 세션/결정 검색
```

## 커맨드 파일 참조

상세 워크플로우: `.claude/commands/session.md`
