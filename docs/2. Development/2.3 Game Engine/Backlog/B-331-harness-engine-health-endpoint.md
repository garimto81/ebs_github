---
id: B-331
title: "harness /engine/health endpoint 신설 — Foundation Demo Mode 3-stage 지원"
status: PENDING
priority: P0
created: 2026-04-22
source: docs/2. Development/2.3 Game Engine/Backlog.md
related-foundation: "docs/1. Product/Foundation.md §6.3 (ENGINE_URL + Demo Mode fallback)"
supersedes: "Backlog.md §우선작업 항목 5 (harness /engine/health endpoint)"
---

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

- [ ] `curl -s http://localhost:8080/engine/health` 200 OK 반환
- [ ] `status: ok` 가 JSON 본문에 포함
- [ ] `Harness_REST_API.md` §1/§2.13 문서화
- [ ] team4 `engine_connection_provider` 가 `/engine/health` 를 probe 하는 PR 트리거 가능

## 관련

- Foundation §6.3, §6.4
- team4 의존: `team4-cc/lib/features/command_center/providers/engine_connection_provider.dart`
- CLAUDE.md `team3-engine/CLAUDE.md` "2026-04-21 이관" §5 항목
