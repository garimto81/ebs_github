---
id: B-336
title: "Harness_REST_API §1 배포 시나리오 — 1 PC vs 중앙 서버 / LAN 배치 보강"
status: PENDING
priority: P2
created: 2026-04-22
source: docs/2. Development/2.3 Game Engine/Backlog.md
related-foundation: "docs/1. Product/Foundation.md §8.5 (복수 테이블 1 PC = 1 피처 테이블) / §6.3 (ENGINE_URL 표준)"
---

# [B-336] Harness 배포 시나리오 보강 (P2)

## 배경

Foundation §8.5 (신설): "1 PC = 1 피처 테이블. 2+ 테이블은 중앙 서버 1대 (BO + DB) 필수". §6.3 은 ENGINE_URL 환경변수를 LAN 배치 전제로 명시.

현재 `Harness_REST_API.md` 는 배포 시나리오 절 없이 기본 `http://0.0.0.0:8080` 만 언급. 운영자가 Engine 을 중앙 서버에 단일 배치할지, 각 PC 에 로컬 배치할지 판단 근거가 문서에 없다.

## 수정 대상

### `APIs/Harness_REST_API.md`

§1 Endpoint 목록 앞에 "배포 시나리오" 절 추가:

- **Local 배치**: 각 PC 에 `dart run bin/harness.dart` — 단일 테이블 운영 시 지연 최소화 (≤ 5ms)
- **중앙 배치**: Docker 컨테이너를 중앙 서버에 올림 — 복수 테이블 운영 시 LAN 대역폭 + 세션 공유
- **권장 기준**: Foundation §8.5 N PC + 중앙 서버 아키텍처에서는 **중앙 배치**. 단일 테이블 개발 환경에서는 **Local 배치**
- **세션 격리**: 중앙 배치 시 `sessionId` 로 테이블 격리. 현재 in-memory Map 방식은 중앙 서버 재시작 시 모든 테이블 세션 손실 (→ B-338 에서 persistence 해결)

§6 미구현 항목에 "중앙 배치 시 세션 persistence 필요" 추가 (B-338 과 연동).

## 수락 기준

- [ ] §1 배포 시나리오 절 신설 (Local / 중앙 2 가지)
- [ ] Foundation §8.5 참조 링크
- [ ] ENGINE_URL 표준 (§6.3 Foundation) 재언급
- [ ] team4 CC 의 연결 로직 (engine_connection_provider) 과 정합 확인

## 관련

- Foundation §6.3, §8.5
- 연동: B-331 (health endpoint), B-338 (session persistence)
