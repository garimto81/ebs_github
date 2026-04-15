---
id: GAP-BO-012
title: JWT 12h 만료 × WebSocket 재연결 interplay 미정
status: RESOLVED
source: docs/2. Development/2.2 Backend/Spec_Gaps.md
---

# [GAP-BO-012] JWT 12h 만료 × WebSocket 재연결 interplay 미정

- **관찰**: BS-01은 Access 15분 정책인데, 방송 14-16h 연속 환경에서 분당 refresh 빈도가 과도. 또한 WebSocket이 토큰 만료 시 끊는지/유지하는지 명시 없음.
- **참조**: WSOP Staff App `Auth.md` (expires_in: 43200초 = 12h)
- **구현 가능성**: ~~불가(CCR)~~ → **가능 (CCR-006 contracts 반영 완료)**
- **액션**: ~~CCR-DRAFT 제출~~ → **완료**. 승격본 `docs/05-plans/CCR-006-bs-01에-jwt-accessrefresh-만료-정책-명시.md`. 정본은 `contracts/specs/BS-01-auth/BS-01-auth.md §5` (dev 1h / staging·prod 2h / live 12h, `AUTH_PROFILE` 환경 플래그, WebSocket `token_expiring`/`reauth`, blacklist 저장소)
- **상태**: **RESOLVED (2026-04-10)** — IMPL-10 §9.1, IMPL-05 §6.2 환경변수 (`AUTH_PROFILE`, `JWT_ACCESS_TTL_S`, `JWT_REFRESH_TTL_S`) 반영됨

---

## 요약 표

| ID | 주제 | 구현 가능성 | 상태 |
|----|------|------------|:----:|
| GAP-BO-001 | Idempotency-Key 헤더 표준 | 가능 (CCR-003 반영) | **RESOLVED** |
| GAP-BO-002 | 리밸런싱 saga 응답 스키마 | 가능 (CCR-010 반영) | **RESOLVED** |
| GAP-BO-003 | 분산락 TTL·fencing 정책 | 가능 | **RESOLVED** |
| GAP-BO-004 | WebSocket seq 필드/replay | 가능 (CCR-015 반영) | **RESOLVED** |
| GAP-BO-005 | Redis 캐시 TTL 및 Pub/Sub 무효화 | 가능 | **RESOLVED** |
| GAP-BO-006 | 서버 시계 동기화 (NTP) | 가능 | **RESOLVED** |
| GAP-BO-007 | 타임아웃 기본값 카탈로그 | 미결 | OPEN |
| GAP-BO-008 | audit_events 스키마 + inverse | 가능 (CCR-001 반영) | **RESOLVED** |
| GAP-BO-009 | WSOP LIVE 폴링 서킷브레이커 | 가능 | **RESOLVED** |
| GAP-BO-010 | EventFlightSeat.updated_at 인덱스 | 가능 | **RESOLVED** |
| GAP-BO-011 | init.sql ↔ DATA-04 큰 격차 | 미결(감사) | IN_PROGRESS (audit_events/idempotency_keys 부분 동기화. core 엔티티 전면 동기화는 Stage 1 진입 시점) |
| GAP-BO-012 | JWT 12h × WebSocket 재연결 | 가능 (CCR-006 반영) | **RESOLVED** |

**RESOLVED (2026-04-10)**: 001~006, 008~010, 012 (10건)
- CCR 계약 반영 5건: 001, 002, 004, 008, 012 (CCR-001/003/006/010/015)
- 독립 작업 완료 5건: 003, 005, 006, 009, 010 (IMPL-10/IMPL-05/BO-02 반영)

**IN_PROGRESS**: 011 (init.sql core 엔티티 동기화 — Stage 1 진입 시점의 별개 작업)
**OPEN**: 007 (타임아웃 기본값 product 오너 확정 대기. IMPL-10 §6 에 임시 기본값 존재)
