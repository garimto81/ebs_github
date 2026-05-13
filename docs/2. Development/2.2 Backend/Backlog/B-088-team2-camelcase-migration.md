---
id: B-088
title: "camelCase 전수 마이그레이션 (team2 PR 2/3/4)"
backlog-status: open
source: docs/4. Operations/Conductor_Backlog/B-088-naming-convention-camelcase-migration.md
mirror: none
---

# [B-088] team2 범위 — PR 2/3/4 (B-088 masters)

- **날짜**: 2026-04-21
- **teams**: [team2]
- **regulation SSOT**: `docs/2. Development/2.5 Shared/Naming_Conventions.md` v2
- **실행 계획 SSOT**: `docs/4. Operations/Plans/B088_team2_execution_plan_2026-04-21.md`

## team2 하위 PR

- [ ] **PR 2** — Pydantic `alias_generator=to_camel` + `populate_by_name=True` 전역 도입 (69 class)
- [ ] **PR 3** — WebSocket publisher snake 10 event → PascalCase + payload camelCase
- [ ] **PR 4** — REST path 126 endpoint PascalCase + 84 path variable camelCase + query param alias

## 전수 검사 실측 (2026-04-21)

| 항목 | 수치 |
|------|:----:|
| REST endpoint 전체 | 126 |
| kebab-case path | 20 |
| lowercase resource path (PascalCase 전환 대상) | ~106 |
| path variable `{snake_case}` | 84 |
| WS snake_case event type | 10 |
| Pydantic BaseModel class | 69 |
| API 문서 snake_case field | 296 |
| test fixture snake_case field | 234 |

## 수락 기준

Plan 문서 §6 참조.

## 의존

- **Blocks**: team1 PR 5/6, team4 PR 7, team3 PR 8 (모두 이 PR 2/3/4 선행)
- **Blocked by**: Conductor PR 1 (Auth_and_Session §4 snake divergence 선언 취소)

## notify

team1, team4, team3 — 동시 배포 필요 (cut-over). 단독 merge 금지.
