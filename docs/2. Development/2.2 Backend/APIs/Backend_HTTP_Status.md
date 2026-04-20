---
title: Backend HTTP — 구현 현황 (2026-04-20)
owner: team2
tier: internal
last-updated: 2026-04-20
reimplementability: PARTIAL
reimplementability_checked: 2026-04-20
reimplementability_notes: "96 엔드포인트 선언. 17 라우터 모듈 구현. 각 엔드포인트 스펙 완결도 검증 미완"
parent: Backend_HTTP.md
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
| `reports.py` | `/api/v1/reports/*` | §7 Reports | **낮음** — Dashboard/Table Activity/Player Stats/Hand Distribution/RFID Health/Operator 6 대상 (B-037~050) 중 기획 미완 |
| `skins.py` | `/api/v1/skins/*` | §8 Skins | 중간 — SG-004 `.gfskin` 포맷 확정 필요 |
| `blind_structures.py` | `/api/v1/blind-structures/*` | §9 BlindStructure | 중간 — WSOP LIVE Staff App 정렬 (NOTIFY-CCR-049) |
| `payout_structures.py` | `/api/v1/payout-structures/*` | §10 Payout | 중간 (NOTIFY-CCR-051) |
| `configs.py` | `/api/v1/configs/*` | §11 Configs / Settings | **낮음** — SG-003 Settings 6탭 스키마 반영 미완 |
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

pytest 95/95 pass 는 2026-04-14 기록. `b21f199` + `92cd385` 이후 재실행 결과 미공개.

## 재구현 가능성 판정

| 항목 | 상태 |
|------|:----:|
| 전체 라우터 (17 모듈) 실제 로드 | 가능 (import 체인) |
| Auth/Users/Tables 재구현 | **PASS** |
| Reports (6건) 재구현 | **FAIL (B)** — 기획 공백 |
| Settings (configs.py) 재구현 | **FAIL (B)** — SG-003 스키마 후속 |
| Skins 재구현 | **PASS** (SG-004 확정 후) |
| WSOP LIVE Sync 재구현 | UNKNOWN — 진행 중 |

## 후속 작업 (team2 세션에서 확정)

- [ ] Reports 6건 통합 spec_gap 승격 + 지표·schema 확정
- [ ] Settings 라우터를 SG-003 `settings_kv` 스키마로 정렬
- [ ] Users 에 Suspend/Lock/Delete 3상태 결정 (WSOP LIVE Staff 패턴 NOTIFY-CCR-053)
- [ ] audit event_type 카탈로그 정식화
- [ ] `b21f199` + `92cd385` 이후 pytest 재실행 → CI 로그 문서화
