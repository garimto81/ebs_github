---
name: todo
version: 1.1.0
description: >
  This skill should be used when the user needs to manage project todos with priorities, due dates, and progress tracking.
triggers:
  keywords:
    - "todo"
    - "/todo"
    - "할일"
    - "할 일 목록"
    - "작업 관리"
    - "task list"
---

# /todo — Todo List Manager

프로젝트 작업을 우선순위, 마감일, 진행률과 함께 관리합니다.

## Usage

```
/todo [action] [args]

Actions:
  list              전체 목록 조회
  add "내용"        새 할일 추가
  done <id>         완료 처리
  status <id> <s>   상태 변경
  priority <id> <p> 우선순위 변경
  depends <id> on <ids>  의존성 설정
  next              다음 작업 표시
  today             오늘 할 일
  progress          진행률 리포트
  --log "내용"      작업 로그 기록
```

---

## /todo list

전체 할일을 우선순위별로 그룹화하여 표시합니다.

```bash
/todo list               # 전체 목록
/todo list --phase=1     # Phase별 필터
```

상태 아이콘: `[ ]` pending, `[→]` in_progress, `[x]` completed, `[!]` failed, `[⏸]` blocked

---

## /todo add

```bash
/todo add "OAuth2 구현" --priority=high --due=2025-01-20 --tags=auth,security
/todo add "Quick task"                    # 기본값으로 추가
```

**옵션**: `--priority` (low/medium/high), `--due` (YYYY-MM-DD), `--tags`, `--assignee`, `--estimate` (hours)

---

## /todo done / status

```bash
/todo done 1                          # 완료 처리 (단축)
/todo status 2 in_progress            # 상태 변경
/todo status 3 blocked "PR 대기"      # 사유와 함께 차단
```

상태 옵션: `pending`, `in_progress`, `completed`, `failed`, `blocked`

---

## /todo priority / depends

```bash
/todo priority 2 high                 # 우선순위 변경
/todo depends 3 on 1,2               # Task 3은 1, 2 완료 후 시작
```

---

## /todo progress

전체 진행률 리포트를 출력합니다.

```bash
/todo progress

# 출력 예시:
# Overall: 7/10 (70%)
# Phase 0: 100% (2/2)
# Phase 1:  60% (3/5)
# Phase 2:   0% (0/3)
```

---

## /todo --log

작업 진행 내용을 MD 파일에 상세 기록합니다.

```bash
/todo --log "API 인증 구현 완료"
```

자동 생성 경로: `logs/work-log-YYYY-MM-DD.md`

기록 형식:
```markdown
# 작업 로그 - 2025-01-20

## 10:30 - API 인증 구현 완료
- **작업 내용**: JWT 기반 인증 미들웨어 구현
- **변경 파일**: src/auth/middleware.ts
- **관련 이슈**: #123
- **다음 단계**: 테스트 케이스 작성
```

사용 시나리오: 복잡한 디버깅 과정 기록, 의사결정 문서화, 컨텍스트 보존

---

## PRD 연동 — Task 자동 생성

```bash
/todo generate tasks/prds/0001-prd-auth.md
```

PRD에서 Phase별 Task를 자동 생성합니다 (Task 0.0 Setup ~ Task N.0).

---

## 파일 저장 위치

`tasks/NNNN-tasks-feature.md` 형식으로 저장:

```markdown
# Task List: User Authentication (PRD-0001)

## Task 1.0: Implementation
- [→] Task 1.1: Create auth module
  Priority: High | Due: 2025-01-20 | Estimate: 4h
- [ ] Task 1.2: Write tests
  Priority: High | Depends: 1.1
```

---

상세: `.claude/commands/todo.md`
