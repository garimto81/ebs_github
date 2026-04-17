---
id: B-F004
title: "문서 누락 API 경로 보강 대기 (team2/Conductor 책임)"
status: BLOCKED
blocker: decision_owner = Conductor (docs) → team2 (구현)
source: docs/2. Development/2.1 Frontend/Backlog.md
---

# B-F004 — Frontend 호출하지만 Backend_HTTP.md에 없는 경로 보강 필요

## 현황

team1이 호출하고 있으나 `docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md`에 명시되지 않은 경로 6개:

| 경로 | 사용 UI | 우선도 |
|------|---------|:------:|
| `POST /users/:id/force-logout` | Staff List 강제 로그아웃 버튼 | 🟡 |
| `POST /skins/:id/deactivate` | GFX 스킨 비활성화 | 🟡 |
| `POST /tables/:id/seats` | Table Detail 플레이어 추가 | 🔴 |
| `DELETE /tables/:id/seats/:n` | Table Detail 플레이어 제거 | 🔴 |
| `POST/PUT/DELETE /blind-structures/:id/levels[/:level_id]` | Settings Blind Level 편집 | 🟡 |
| `GET /tables/:id/status` | Table Detail 실시간 상태 | 🟡 |

## 요청 사항

1. Conductor — `Backend_HTTP.md`에 위 6개 경로 명세 추가 (request/response schema, RBAC)
2. team2 — 명세 확정 후 BO에 구현

## team1 대기 방침

- 현재 호출 유지 (삭제 금지)
- 호출 실패 시 try/catch + 사용자 안내 메시지 (graceful degradation)
- 문서 확정 후 schema 변경 필요 시 재조정
