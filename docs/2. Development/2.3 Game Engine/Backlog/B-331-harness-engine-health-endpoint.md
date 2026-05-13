---
id: B-331
title: "harness /engine/health endpoint 신설 — Foundation Demo Mode 3-stage 지원"
backlog-status: done
priority: P0
created: 2026-04-22
completed: 2026-05-11
completed-stream: S8 (cycle 2 검증)
discovered-pre-completed: true
source: docs/2. Development/2.3 Game Engine/Backlog.md
related-foundation: "docs/1. Product/Foundation.md §B.3 (Demo Mode fallback)"
supersedes: "Backlog.md §우선작업 항목 5 (harness /engine/health endpoint)"
mirror: none
close-date: 2026-05-13
---

> **2026-05-11 S8 cycle 2 발견**: 본 항목은 cycle 1 dispatch 시점 (NOTIFY-team3) 에 PENDING 으로 분류됐으나, cycle 2 harness E2E 검증 중 코드 이미 구현됨을 확인. 즉시 DONE 처리. NOTIFY-team3 도 CLOSED.

# [B-331] harness /engine/health endpoint 신설 (P0)

## 배경

Foundation §6.3: "Engine 미기동 시: CC 는 **Demo Mode fallback** 3-stage 상태 머신 (SG-002 해소)". §6.4 도 "ENGINE_URL 표준: `--dart-define=ENGINE_URL=http://host:port` (기본 `http://localhost:8080`)" 명시.

team4 `engine_connection_provider` 는 이 3-stage (확인 → 재시도 → fallback) 에서 health probe 를 호출할 수 있어야 하지만 team3 harness 는 현재 `/engine/health` endpoint 를 노출하지 않는다.

## 수정 대상

### 코드
- `team3-engine/ebs_game_engine/lib/harness/server.dart` — `HarnessServer._handleRequest` 에 `GET /engine/health` 라우트 추가

### 응답 스키마
```json
{
  "status": "ok",
  "version": "<engine_version>",
  "uptime_seconds": 1234,
  "sessions_active": 3,
  "timestamp": "2026-04-22T..."
}
```

- `status`: `ok` / `degraded` (scenario load 실패 등)
- `version`: pubspec.yaml 의 engine 패키지 버전
- `sessions_active`: `_sessions.length`

### 문서
- `APIs/Harness_REST_API.md` — §2.13 endpoint 추가, §1 목록 갱신 (13번째)
- `APIs/Harness_REST_API.md` §6 미구현 항목에서 제거

## 수락 기준

- [x] `curl -s http://localhost:8080/engine/health` 200 OK 반환 ✅ test 검증 (HarnessServer listening on http://127.0.0.1:0 + GET /engine/health returns 200)
- [x] `status: ok` 가 JSON 본문에 포함 ✅ test/harness/health_endpoint_test.dart "expected schema" 검증
- [x] `Harness_REST_API.md` §1/§2.13 문서화 ✅ 2026-04-22 commit + 2026-05-11 frontmatter 갱신
- [x] team4 `engine_connection_provider` 가 `/engine/health` 를 probe 하는 PR 트리거 가능 ✅ endpoint ready

## 완료 증거 (2026-05-11 cycle 2 검증)

| 영역 | 증거 | 상태 |
|------|------|:----:|
| 코드 | `team3-engine/ebs_game_engine/lib/harness/server.dart` `_handleRequest` | ✅ 구현 (시점 미상, cycle 1 dispatch 이전) |
| 테스트 | `test/harness/health_endpoint_test.dart` 41 tests pass | ✅ |
| 문서 | `APIs/Harness_REST_API.md` §1#13 + §2.13 | ✅ 2026-04-22 commit |
| Demo Mode 3-stage 지원 | team4 consumer 가 probe 가능 | ✅ |

## 관련

- Foundation §B.3 (=구 §6.3)
- team4 의존: `team4-cc/lib/features/command_center/providers/engine_connection_provider.dart`
- 연동: B-330+B-332 (PR #227, 머지 완료)
- stale NOTIFY: `NOTIFY-team3-B331-engine-health-code-impl-2026-05-11.md` (CLOSED 2026-05-11)
