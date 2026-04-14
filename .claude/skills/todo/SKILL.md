---
name: todo
description: Manage project todos with priorities, due dates, and tracking
triggers:
  keywords:
    - "todo"
---

# /todo

이 스킬은 `.claude/commands/todo.md` 커맨드 파일의 내용을 실행합니다.

## 서브커맨드 라우팅

| 서브커맨드 | 동작 |
|-----------|------|
| `list` | TODO 목록 조회 |
| `add` | 새 항목 추가 |
| `done` | 항목 완료 처리 |
| `priority` | 우선순위 변경 |

## Usage

```bash
/todo list                      # 전체 TODO 조회
/todo add "API 테스트 추가" --p high --due 2026-04-15
/todo done B-042                # 항목 완료 처리
/todo priority B-042 high       # 우선순위 변경
```

## 커맨드 파일 참조

상세 워크플로우: `.claude/commands/todo.md`
