---
name: work
version: 19.0.0
description: /auto로 통합됨 (v19.0). 리다이렉트 stub.
deprecated: true
redirect: auto
audit_exclude: true
---

# /work -> /auto 리다이렉트

> `/work`는 v19.0에서 `/auto`로 통합되었습니다. 모든 기능이 `/auto`에서 실행됩니다.

## 매핑 테이블

| 기존 명령 | 신규 명령 |
|----------|----------|
| `/work "작업"` | `/auto "작업"` |
| `/work --auto "작업"` | `/auto "작업"` |
| `/work --skip-analysis` | `/auto --skip-analysis` |
| `/work --no-issue` | `/auto --no-issue` |
| `/work --strict` | `/auto --strict` |
| `/work --dry-run` | `/auto --dry-run` |
| `/work --loop` | `/auto` (기존 리다이렉트 유지) |

## 실행 방법

`/work`를 감지하면:
1. 사용자에게 "이 작업은 `/auto`로 실행됩니다" 안내
2. `/work` 뒤의 모든 인수를 `/auto`에 전달
3. `/auto` SKILL.md의 Phase 0-5 실행

**상세 워크플로우**: `.claude/skills/auto/SKILL.md`, `.claude/skills/auto/REFERENCE.md`
