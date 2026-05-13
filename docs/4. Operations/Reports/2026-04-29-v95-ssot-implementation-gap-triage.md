---
title: V9.5 SSOT vs Implementation Gap Triage
owner: conductor
tier: operations
last-updated: 2026-04-29
governance: v9.5
related: ["Spec_Gap_Triage.md", "../../docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md"]
confluence-page-id: 3819176427
confluence-parent-id: 3811573898
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819176427/EBS+V9.5+SSOT+vs+Implementation+Gap+Triage
---

# V9.5 SSOT vs Implementation Gap Triage

> **사용자 의도 trigger (2026-04-29)**: "ssot 와 구현 사이의 gap 처리". V9.5 SSOT-first judgment 자율 진행.

## 🎯 진단 결과 요약

| 항목 | 수 |
|------|----|
| BO endpoints (SSOT 구현) | 127 |
| Lobby HTTP calls (frontend 호출) | 53 |
| Matched (정합) | 37 |
| **Drift A** (lobby 사용, BO 모름) | **16** |
| **Drift B** (BO 제공, lobby 미사용) | 93 (정보 only) |

## 🔍 SSOT-First Judgment 분류

### Drift A 16 paths Type 분류

#### Type A1 — Frontend 구현 stale (10 paths)

Frontend 가 series-scoped path 사용. SSOT (Backend_HTTP.md + BO 구현) 는 flat path 채택. **Backend 의 routing 모델이 SSOT** (V9.5 `conflict_resolution.ssot_priority`: team-policy > APIs).

| Frontend (현재) | Backend SSOT |
|-----------------|---------------|
| `GET /series/{id}/payout-structures` | `GET /api/v1/payout-structures?series_id=...` |
| `GET /series/{id}/payout-structures/{psId}` | `GET /api/v1/payout-structures/{ps_id}` |
| `POST /series/{id}/payout-structures` | `POST /api/v1/payout-structures` |
| `PUT /series/{id}/payout-structures/{psId}` | `PUT /api/v1/payout-structures/{ps_id}` |
| `DELETE /series/{id}/payout-structures/{psId}` | `DELETE /api/v1/payout-structures/{ps_id}` |
| `GET /series/{id}/blind-structures` | `GET /api/v1/blind-structures?series_id=...` |
| `GET /series/{id}/blind-structures/{bsId}` | `GET /api/v1/blind-structures/{bs_id}` |
| `POST /series/{id}/blind-structures` | `POST /api/v1/blind-structures` |
| `PUT /series/{id}/blind-structures/{bsId}` | `PUT /api/v1/blind-structures/{bs_id}` |
| `DELETE /series/{id}/blind-structures/{bsId}` | `DELETE /api/v1/blind-structures/{bs_id}` |

**처리**: team1-frontend 의 `payout_structure_repository.dart`, `settings_repository.dart` path 갱신 + method signature `int seriesId` 매개변수 → `int? seriesId` (query 파라미터로 변경).

#### Type A2 — Frontend 잘못된 method (1 path)

| Frontend (현재) | Backend SSOT |
|-----------------|---------------|
| `DELETE /auth/session` | `POST /auth/logout` |

**처리**: `team1-frontend/lib/repositories/auth_repository.dart` L87 logout() 메서드:
```dart
// before:
await _client.delete<dynamic>('/auth/session');
// after:
await _client.post<dynamic>('/auth/logout');
```

#### Type A3 — Backend missing endpoints (4 paths)

Frontend 가 `/blind-structures/{id}/levels/...` 호출 → BO 가 endpoint 미제공.

| Frontend 호출 | Backend 상태 |
|--------------|--------------|
| `POST /blind-structures/{id}/levels` | **BO 미제공** |
| `GET /blind-structures/{id}/levels` | **BO 미제공** |
| `PUT /blind-structures/{id}/levels/{levelId}` | **BO 미제공** |
| `DELETE /blind-structures/{id}/levels/{levelId}` | **BO 미제공** |

**처리**: team2-backend 가 `/api/v1/blind-structures/{bs_id}/levels` CRUD endpoints 추가 필요. team2 영역 작업.

## 🛠 자율 처리 Plan

### Phase 1 (본 PR — 진단 보고만)

- 본 문서 자체가 산출물 (Drift_Type_Analysis)
- 외부 인계 가능한 SSOT-구현 정합 audit trail

### Phase 2 (다음 cycle — frontend fix, 별도 PR)

- team1-frontend `payout_structure_repository.dart` series-scope 제거 (5 path)
- team1-frontend `settings_repository.dart` series-scope 제거 (5 path)
- team1-frontend `auth_repository.dart` logout method 변경 (1 path)
- 각 method signature 갱신 + caller 업데이트
- `flutter analyze` + `flutter test` PASS 확인
- 분량: ~80 LOC, 3 files

### Phase 3 (별도 cycle — backend Type A3, team2 영역)

- team2-backend `/api/v1/blind-structures/{bs_id}/levels` CRUD 4 endpoints
- team2 publisher Fast-Track (Backend_HTTP.md 자체 보강 + 구현)
- 분량: ~150 LOC + 테스트

## 📊 V9.5 critic 결함 정합

| ID | V9.5 정합 |
|----|-----------|
| **SSOT-first** | ✅ 본 진단이 SSOT (BO 구현 + Backend_HTTP.md) 검색 + 자율 분류 |
| **AI 자율 결정** | ✅ Type 분류 + fix 방향 모두 AI 자율 (Backend SSOT 우선) |
| **사용자 입력 0** | ✅ "gap 처리" 의도 한 줄 trigger 만 |
| **결과물 중심주의** | ✅ 본 진단 = 외부 인계 가능 audit trail (결과물 quality 직결) |
| **점진 진행** | ✅ Phase 1/2/3 분리로 분량 control |

## 🔗 관련

- `tools/contract_drift_audit.py` — 자동 drift 검출 도구
- `docs/4. Operations/_generated/CONTRACT_DRIFT_AUDIT.md` — 자동 생성 raw report
- `docs/4. Operations/Spec_Gap_Triage.md` — Type A/B/C/D 분류 프로토콜
- `docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md` §1.1 — `/api/v1/` prefix 정책 (`/auth/*` 예외)
- `docs/2. Development/2.5 Shared/team-policy.json` `conflict_resolution.ssot_priority`
