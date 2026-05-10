---
id: B-338
title: "harness 세션 재시작 복구 — Foundation §8.4 긴급 복구 계약 대응"
status: PENDING
priority: P1
created: 2026-04-22
source: docs/2. Development/2.3 Game Engine/Backlog.md
related-foundation: "docs/1. Product/Foundation.md §8.4 (생방송의 생명줄: 긴급 복구)"
mirror: none
---

# [B-338] harness 세션 재시작 복구 (P1)

## 배경

Foundation §8.4 가 crash 복구를 절대 조건으로 명시:

> **서버 크래시**: 최악의 경우 메인 시스템이 다운되어 재부팅되더라도, 튕기기 바로 직전의 게임 상태와 판돈을 스스로 기억하고 복원해 내어 중단 없이 방송을 이어가게 해 줍니다.

그러나 `Harness_REST_API.md §6` 미구현:

> Multi-tenant: 세션은 프로세스 메모리 내 Map. 재시작 시 손실 (save/load 로 우회).

Foundation §8.5 중앙 서버 배치에서는 중앙 서버 Engine 재시작 = **모든 테이블 세션 손실** = Foundation §8.4 계약 위반. 우선순위 격상 필요.

## 수정 대상

### 코드
- `team3-engine/ebs_game_engine/lib/harness/session.dart` — Session 객체에 disk snapshot 추가
- `team3-engine/ebs_game_engine/lib/harness/server.dart` — Harness 시작 시 snapshot 디렉토리 scan 후 세션 복원
- 저장 경로: `${HARNESS_STATE_DIR:-/var/lib/ebs-harness/sessions}/<sessionId>.json`

### 복구 전략 (MVP)
1. 이벤트 적용 직후 Session state 를 JSON 으로 snapshot (기존 `/api/session/:id/save` 로직 재사용)
2. 프로세스 시작 시 snapshot 디렉토리 로드 → 메모리 Map 복원
3. 각 session 에 `lastHeartbeat` 추가 — TTL 24h 초과 snapshot 은 cleanup

### 문서
- `APIs/Harness_REST_API.md` §6 미구현 항목에서 제거
- `APIs/Harness_REST_API.md` 신규 §5.5 "세션 persistence" 절 추가

## 수락 기준

- [ ] Harness 재시작 후 기존 세션 REST endpoint 가 복원 상태 반환
- [ ] snapshot 저장/복원 경로 환경변수로 제어 가능
- [ ] dart test — `harness/persistence_test.dart` 추가 (restart simulation)
- [ ] 성능 영향 measured (§5 성능 예산 표 갱신)

## 관련

- Foundation §8.4, §8.5
- 연동: B-336 (배포 시나리오), B-331 (health endpoint)
