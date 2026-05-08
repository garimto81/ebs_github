---
title: CR-team2-20260414-wsop-sync-catalog
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team2-20260414-wsop-sync-catalog
confluence-page-id: 3819177089
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819177089/EBS+CR-team2-20260414-wsop-sync-catalog
---

# CCR-DRAFT: WSOP LIVE Sync 대상 엔드포인트 카탈로그 + GGPass 통합 전략

- **제안팀**: team2
- **제안일**: 2026-04-14
- **영향팀**: [team1]
- **변경 대상 파일**: contracts/api/`Backend_HTTP.md` (legacy-id: API-01) (Part II, WSOP LIVE Integration)
- **변경 유형**: add
- **변경 근거**: WSOP LIVE는 공개 Public API 카탈로그가 별도 존재하지 않음 (조사 결과). Staff App API는 내부 사용. 외부 통합은 GGPass External API(S2S, Page 1975582764, API Key + JWT) 경유. EBS 동기화 전략을 명시화 필요: Phase 1 mock seed, Phase 2 GGPass 통합 협상, Phase 3 Staff App API 양방향.

## 변경 요약

1. API-01 Part II에 Sync 대상 엔티티별 매핑 표 신설 (Series/Event/EventFlight/Player/BlindStructure/PayoutStructure/Staff)
2. Phase별 통합 전략 명시 (1: mock, 2: GGPass S2S, 3: Staff App 직접 연동)
3. 인증 방식 명시 (Phase 2+): `X-API-KEY` + `Z-Authorization` JWT 헤더
4. 폴링 주기 + wsop_id 매핑 전략
5. 충돌 해결 우선순위 표

## Diff 초안

```diff
+## 1. Sync 대상 엔티티 카탈로그
+
+| 엔티티 | WSOP LIVE 원본 엔드포인트 | EBS 대응 테이블 | 폴링 주기 | Source 필드 |
+|---|---|---|---|---|
+| Series | Staff App `/Series` | `series` | 24h | wsop_id |
+| Event | Staff App `/Series/{sId}/Events` | `events` | 1h | wsop_id |
+| EventFlight | Staff App `/Series/{sId}/EventFlights` | `event_flights` | 5min | wsop_id |
+| Player | Staff App `/Series/{sId}/Players` | `players` | 10min | wsop_id |
+| BlindStructure | Staff App `/BlindStructures` | `blind_structures` | 1h | wsop_id |
+| PayoutStructure | Staff App `/PayoutStructures` | `payout_structures` | 1h | wsop_id |
+| Staff | Staff App `/Staffs` | `users` | 24h (낮 우선) | wsop_id |
+
+## 2. Phase별 통합 전략
+
+| Phase | 방식 | 근거 |
+|---|---|---|
+| Phase 1 (2026 H2) | Mock seed (`POST /sync/mock/seed`) | 외부 API 접근 협상 전 |
+| Phase 2 (2027 Q1) | GGPass External API S2S (계정/인증만) | 인증 통합, 조직 계정 sync |
+| Phase 3 (2027 Q2+) | Staff App API 읽기 전용 양방향 sync | 토너먼트 데이터 통합 |
+
+## 3. 인증 (Phase 2+)
+
+> **GGPass External API 방식** (Page 1975582764, 1970962433):
+
+| 헤더 | 값 | 용도 |
+|---|---|---|
+| `X-API-KEY` | `{WSOP_API_KEY}` env | 시스템 인증 |
+| `Z-Authorization` | `Bearer {JWT}` | 사용자 컨텍스트 |
+
+**IP Whitelist (Phase 2):** WSOP 측에 EBS Prod IP 등록 필요:
+- Test: 16.163.194.60/32, 43.198.149.82/32 (WSOP 참고)
+- Prod: EBS 배포 IP 확정 후 협상
+
+## 4. wsop_id 매핑 전략
+
+모든 Sync 대상 테이블에 `wsop_id VARCHAR(64) UNIQUE NULL` 컬럼 추가:
+- Phase 1: NULL (EBS 로컬 생성)
+- Phase 2+: WSOP 원본 ID 저장, UNIQUE 제약으로 중복 동기화 차단
+
+## 5. 충돌 해결 우선순위
+
+| 상황 | 우선순위 | 근거 |
+|---|---|---|
+| wsop_id 존재 + source='api' 업데이트 | WSOP 값 우선 | 정규 소스 |
+| wsop_id 존재 + source='manual' + manual_override=true | EBS 값 유지 | Admin 수동 결정 존중 |
+| wsop_id 존재 + source='manual' + manual_override=false | WSOP 값으로 덮어씀 + sync_conflicts 로그 | 안전 기본값 |
+| wsop_id NULL | EBS 로컬 엔티티, WSOP 동기화 대상 아님 | 로컬 생성 |
+
+**sync_conflicts 테이블 신규**:
+| Field | Type | Description |
+|---|---|---|
+| conflict_id | int | PK |
+| entity_table | string | events/series/... |
+| entity_id | int | EBS PK |
+| wsop_id | string | |
+| wsop_value | jsonb | |
+| ebs_value | jsonb | |
+| resolution | enum | wsop_wins / ebs_wins / pending |
+| resolved_by | int | FK users |
+| resolved_at | timestamp | |
+
+## 6. Sync Worker 구현 원칙
+
+- Circuit Breaker (기존 `observability/`): 5회 연속 실패 시 15분 open
+- Exponential Backoff: 1s → 2s → 4s → ... → 5min max
+- 동시 실행 방지: 엔티티별 Redis lock (Phase 2+) 또는 DB advisory lock (Phase 1)
+- Idempotent: 같은 polling tick 재실행 시 부작용 없음 (updated_at 비교)
```

## Divergence from WSOP LIVE (Why)

1. **Public API 없어 Staff App 직접 연동 가정**: WSOP 측 승인 필요.
   - **Why**: 공개 API 카탈로그 부재. Phase 2 협상 대상.
2. **Phase 1 mock seed 유지**: WSOP LIVE에 없는 EBS 고유 개념.
   - **Why**: 외부 API 접근 전 개발/테스트 가능해야 함.

## 영향 분석

- **Team 1 (Lobby)**: Sync 대시보드 UI (엔티티별 마지막 sync 시각, sync_conflicts 해결 화면) — 3일.
- **Team 2**: Sync Worker 구현 (Phase 1 mock, Phase 2 실연동), sync_conflicts 테이블, lock 메커니즘.

## 대안 검토

1. **양방향 sync (EBS → WSOP)**: 탈락. EBS는 소비자. WSOP 단방향 pull만.
2. **이벤트 기반 sync (WSOP webhook)**: 탈락. WSOP 측 webhook 미제공 가정.

## 검증

- Mock seed → DB 반영 확인
- Circuit breaker 5회 실패 → open 전환 + 15분 후 half-open 재시도
- wsop_id UNIQUE 제약 (중복 동기화 시도 시 upsert)
- sync_conflicts 로그 기록

## 승인 요청

- [ ] Team 1 검토 (Sync UI)
- [ ] Phase 2 전 WSOP 측 API 접근 협상 선행 확인

## 참고 출처

| Page ID | 제목 |
|---|---|
| 1975582764 | GGPass External API (S2S 4 엔드포인트) |
| 1970962433 | How to Set API Headers (X-API-KEY + Z-Authorization) |
| 1599537917 | Staff App API / Tournament (Sync 대상) |
| 1603666061 | BlindStructure API (Sync 대상) |
| 1603600679 | PayoutStructure API (Sync 대상) |
| 1597768061 | Staff API (Sync 대상) |
