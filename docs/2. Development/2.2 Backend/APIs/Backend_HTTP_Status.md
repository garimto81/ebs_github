---
title: Backend HTTP — 구현 현황 (2026-04-20)
owner: team2
tier: internal
last-updated: 2026-05-08
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "2026-04-20 업데이트 — SG-007 Reports 6-endpoint 실동작 (mock data, [TODO-T2-009] MV 교체 대기), SG-003 Settings in-memory 실동작 (migration 0005 적용 후 DB 교체), SG-008 b1-b9 스펙 확정 + b10-b12 삭제 완료. pytest 242/242 pass."
parent: Backend_HTTP.md
confluence-page-id: 3818914332
confluence-parent-id: 3811770578
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818914332/EBS+Backend+HTTP+2026-04-20
---

# Backend HTTP — 구현 현황 (Conductor Audit 2026-04-20)

> **주의**: 이 문서는 Conductor 가 2026-04-20 에 Backend_HTTP.md 와 team2-backend/src/routers/ 실측을 교차검증한 **스냅샷**. team2 세션이 실제 개발하면서 최신화해야 하며, 본 문서는 **starting point** 역할.

## 집계

| 항목 | 수치 | 출처 |
|------|:---:|------|
| `Backend_HTTP.md` 선언 HTTP 메서드 등장 | 96건 | `grep -c " POST \| GET \| PUT \| PATCH \| DELETE "` |
| `Backend_HTTP.md` 주요 섹션 (H2/H3) | 65개 | 문서 구조 |
| `team2-backend/src/routers/` 실제 모듈 | 17개 Python 파일 | 코드 실측 |

## 라우터 모듈 ↔ 문서 섹션 매핑

| 라우터 모듈 | 주요 엔드포인트 prefix | Backend_HTTP.md 섹션 (추정) | 완결도 추정 |
|-------------|----------------------|----------------------------|:----------:|
| `auth.py` | `/api/v1/auth/*` | §1 Auth | 높음 (Auth_and_Session.md 별도 상세) |
| `users.py` | `/api/v1/users/*` | §2 Users | 중간 — Suspend/Lock/Delete 정책 미확정 (NOTIFY-CCR-053 참조) |
| `audit.py` | `/api/v1/audit/*` | §14 Audit | 낮음 — event_type 카탈로그 미정식화 (NOTIFY-CCR-039) |
| `competitions.py` | `/api/v1/competitions/*` | §3 Competition | 중간 — WSOP LIVE 정렬 진행 중 |
| `series.py` | `/api/v1/series/*` | §3 Series | 중간 |
| `tables.py` | `/api/v1/tables/*` | §4 Tables | 높음 — 가장 성숙 |
| `hands.py` | `/api/v1/hands/*` | §5 Hands | 중간 — 9→13 게임 지원 Backlog 상 미완 (B-045/056) |
| `players.py` | `/api/v1/players/*` | §6 Players | 중간 — 고도화 Backlog (B-036) |
| `reports.py` | `/api/v1/reports/*` | §5.15 Reports / §16.11 legacy 삭제 | **중간** — SG-007 6 endpoint 실동작 (mock data, MV 교체 대기 [TODO-T2-009]). SG-008-b12: legacy `/reports/{report_type}` 삭제 완료 |
| `skins.py` | `/api/v1/skins/*` | §8 Skins | 중간 — SG-004 `.gfskin` 포맷 확정 필요 |
| `blind_structures.py` | `/api/v1/blind-structures/*` | §9 BlindStructure | 중간 — WSOP LIVE Staff App 정렬 (NOTIFY-CCR-049) |
| `payout_structures.py` | `/api/v1/payout-structures/*` | §10 Payout | 중간 (NOTIFY-CCR-051) |
| `configs.py` | `/api/v1/configs/*` | §11 Configs / Settings | **중간** — SG-003 Settings 6탭은 `settings_kv.py` 별도 라우터 (in-memory 실동작). `configs.py` 는 section-scoped wrapper 로 유지 |
| `settings_kv.py` | `/api/v1/settings/*` | SG-003 Settings (신규) | **중간** — 4-level scope override in-memory 실동작. migration 0005 DB 교체 대기 [TODO-T2-011] |
| `sync.py` | `/api/v1/sync/*` | §15 WSOP LIVE Sync | 중간 — B-041~043 진행 중 |
| `replay.py` | `/api/v1/replay/*` | §16 Replay | 중간 — seq 복구 (NOTIFY-CCR-015) |

## Reports API 기획 공백 (Type B 후보)

`reports.py` 라우터 모듈은 존재하나, Backend_HTTP.md Reports 섹션 명세가 전반적 미완. Backlog:

| Backlog ID | 리포트 | 기획 상태 |
|:---:|--------|----------|
| B-037 | Dashboard API | 미확정 |
| B-038 | Table Activity | 미확정 |
| B-039 | Player Statistics | 미확정 |
| B-048 | Hand Distribution | 미확정 |
| B-049 | RFID Health Report | 미확정 |
| B-050 | Operator Activity Report | 미확정 |

**권고**: team2 세션이 Reports 전체를 **단일 spec_gap (SG-00X)** 로 승격하여 통합 스펙 작성. 6 리포트 각각 (a) 대상 지표 (b) aggregation 주기 (c) 응답 schema (d) RBAC 를 확정.

## 최근 커밋 영향

- `b21f199` "32→96 엔드포인트" (2026-04-16) → 라우터 범위 확장, 각 엔드포인트 스펙 완결도는 후속
- `92cd385` "SSOT compliance recovery" (2026-04-17) → init.sql + SQLModel 간 권위 정리
- `841a6fd` "PlayerMoveStatus + ConfigChanged broadcast" (이전) → WebSocket 이벤트 타입 확장
- `fe8f2bd` "Foundation Ch.5 §B.4 Phase A" (2026-04-22, 옛 §6.4) → §5.18 State Snapshot endpoint 발행 (명세만, 실구현 후속)

pytest 95/95 pass 는 2026-04-14 기록. `b21f199` + `92cd385` 이후 재실행 결과 미공개.

## Foundation Ch.5 §B.4 crash 복구 매트릭스 (2026-04-22 신설, 2026-05-08 cascade 정합)

Foundation Ch.5 §B.4 "실시간 동기화 — DB SSOT + WS push" 의 "Crash 복구: DB snapshot 재로드" 정책에 따른 HTTP status 처리:

| 상황 | 권장 응답 | consumer 동작 |
|------|-----------|----------------|
| 프로세스 시작 → snapshot 요청 (`GET /tables/{id}/state/snapshot`) | `200 OK` + 전체 state | baseline 로드 후 WS 구독 개시 |
| snapshot 요청 중 DB 연결 실패 | `503 Service Unavailable` + `Retry-After: 5` | 1-5초 후 재시도 (Foundation Ch.5 §B.4 polling 주기 범위 내) |
| WS 끊김 후 replay gap > 500 (API-05 §6.4.3) | consumer 가 `/tables/{id}/state/snapshot` 로 전환 | replay 포기 → snapshot 재로드 |
| 중앙 서버 SPOF (N PC 배포) | 네트워크 오류 (timeout/connection refused) | 로컬 buffer 모드 진입 (Operations.md §2.1.E) |

> consumer 는 `seq` 감소 (older snapshot) 를 감지하면 **경고 로그 + 해당 snapshot 적용 건너뜀**. 단조 증가는 `audit_events.seq` 로 보장되며, DB replication lag 로 인한 일시적 역전은 Redis cache 경로에서 발생할 수 있음 (NFR §5).

## 재구현 가능성 판정

| 항목 | 상태 |
|------|:----:|
| 전체 라우터 (17 모듈) 실제 로드 | 가능 (import 체인) |
| Auth/Users/Tables 재구현 | **PASS** |
| Reports (6건) 재구현 | **PASS** — SG-007 6-endpoint mock data 실동작 (MV 교체는 [TODO-T2-009]) |
| Settings (settings_kv.py) 재구현 | **PASS** — SG-003 4-level scope resolver 실동작 (DB 교체는 [TODO-T2-011]) |
| Skins 재구현 | **PASS** (SG-004 확정 후) |
| WSOP LIVE Sync 재구현 | UNKNOWN — 진행 중 |

## 2026-04-20 세션 완료 항목 (team2)

- [x] SG-007 Reports 6 endpoint mock data 실동작 + 12 테스트
- [x] SG-003 Settings in-memory 실동작 + 11 테스트
- [x] SG-008-b1-b9 스펙 확정 (§16 Backend_HTTP.md)
- [x] SG-008-b10 undo 엔드포인트·테스트 삭제 (옵션 3)
- [x] SG-008-b11 launch-cc 엔드포인트 삭제 (옵션 1 deep-link 전환)
- [x] SG-008-b12 legacy `/reports/{report_type}` 삭제 (옵션 1)
- [x] pytest 242/242 pass (baseline 223 + 24 new − 5 deleted undo)

## 후속 작업

- [ ] Reports MV 테이블 설계 + [TODO-T2-009] 실DB 쿼리 교체
- [ ] Settings migration 0005 적용 + [TODO-T2-011] DB session 교체
- [ ] Decks migration 0005 적용 + [TODO-T2-004] DB session 교체
- [ ] Users 에 Suspend/Lock/Delete 3상태 결정 (WSOP LIVE Staff 패턴 NOTIFY-CCR-053)
- [ ] audit event_type 카탈로그 정식화
- [ ] `/api/v1/auth/launch-token` (short-lived, deep-link 용) 신규 endpoint 스펙
- [ ] migration 0002 configs batch_alter_table 이슈 (NoSuchTableError) — alembic upgrade 차단 중
