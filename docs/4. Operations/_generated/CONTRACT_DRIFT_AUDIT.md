---
title: Contract Drift Audit Report (auto-generated)
owner: conductor
tier: internal
auto_generated_by: tools/contract_drift_audit.py
---

# Contract Drift Audit (bo ↔ lobby)

> ⚠ 본 문서는 자동 생성. 수정하지 마세요. 갱신은 audit 도구 재실행.

## 요약

| 항목 | 값 |
|------|----|
| bo endpoints | 135 |
| lobby HTTP calls | 53 |
| matched | 53 |
| **lobby paths unknown (404 risk)** | **0** |
| bo unused | 85 |

## Drift B — bo 가 제공하지만 lobby 가 호출 안 함 (정보)

| method | bo path |
|--------|--------|
| `GET` | `/auth/me` |
| `POST` | `/auth/2fa/setup` |
| `POST` | `/auth/2fa/disable` |
| `POST` | `/auth/password/reset/send` |
| `POST` | `/auth/password/reset/verify` |
| `POST` | `/auth/password/reset` |
| `GET` | `/auth/google` |
| `GET` | `/auth/google/callback` |
| `GET` | `/api/v1/series` |
| `GET` | `/api/v1/series/{series_id}/events` |
| `POST` | `/api/v1/series/{series_id}/events` |
| `GET` | `/api/v1/events` |
| `GET` | `/api/v1/flights` |
| `GET` | `/api/v1/events/{event_id}/flights` |
| `POST` | `/api/v1/events/{event_id}/flights` |
| `DELETE` | `/api/v1/flights/{flight_id}` |
| `PUT` | `/api/v1/flights/{flight_id}/complete` |
| `PUT` | `/api/v1/flights/{flight_id}/cancel` |
| `GET` | `/api/v1/flights/{flight_id}/clock` |
| `PUT` | `/api/v1/flights/{flight_id}/clock` |
| `POST` | `/api/v1/flights/{flight_id}/clock/start` |
| `POST` | `/api/v1/flights/{flight_id}/clock/pause` |
| `POST` | `/api/v1/flights/{flight_id}/clock/resume` |
| `POST` | `/api/v1/flights/{flight_id}/clock/restart` |
| `PUT` | `/api/v1/flights/{flight_id}/clock/detail` |
| `PUT` | `/api/v1/flights/{flight_id}/clock/reload-page` |
| `PUT` | `/api/v1/flights/{flight_id}/clock/adjust-stack` |
| `POST` | `/api/v1/tables/rebalance` |
| `GET` | `/api/v1/tables` |
| `GET` | `/api/v1/flights/{flight_id}/tables` |
| `POST` | `/api/v1/flights/{flight_id}/tables` |
| `GET` | `/api/v1/tables/{table_id}/status` |
| `GET` | `/api/v1/tables/{table_id}/seats` |
| `GET` | `/api/v1/players` |
| `POST` | `/api/v1/players` |
| `GET` | `/api/v1/players/search` |
| `PUT` | `/api/v1/players/{player_id}` |
| `DELETE` | `/api/v1/players/{player_id}` |
| `GET` | `/api/v1/tables/{table_id}/events` |
| `GET` | `/api/v1/sync/status` |
| `GET` | `/api/v1/sync/wsop-live/status` |
| `POST` | `/api/v1/sync/wsop-live` |
| `GET` | `/api/v1/sync/conflicts` |
| `POST` | `/api/v1/sync/trigger/{source}` |
| `POST` | `/api/v1/sync/mock/seed` |
| `DELETE` | `/api/v1/sync/mock/reset` |
| `GET` | `/api/v1/audit-logs` |
| `GET` | `/api/v1/audit-logs/download` |
| `GET` | `/api/v1/audit-events` |
| `GET` | `/api/v1/users` |
| ... | (35 more) |

## Matched (정합 통과 — 매칭 매트릭스)

| method | lobby path | → | bo path | 파일 |
|--------|-----------|---|---------|------|
| `POST` | `/auth/login` | → | `/auth/login` | `team1-frontend/lib/repositories/auth_repository.dart` |
| `POST` | `/auth/verify-2fa` | → | `/auth/verify-2fa` | `team1-frontend/lib/repositories/auth_repository.dart` |
| `POST` | `/auth/refresh` | → | `/auth/refresh` | `team1-frontend/lib/repositories/auth_repository.dart` |
| `GET` | `/auth/session` | → | `/auth/session` | `team1-frontend/lib/repositories/auth_repository.dart` |
| `POST` | `/auth/logout` | → | `/auth/logout` | `team1-frontend/lib/repositories/auth_repository.dart` |
| `GET` | `/competitions/$id` | → | `/api/v1/competitions/{competition_id}` | `team1-frontend/lib/repositories/competition_repository.dart` |
| `POST` | `/competitions` | → | `/api/v1/competitions` | `team1-frontend/lib/repositories/competition_repository.dart` |
| `PUT` | `/competitions/$id` | → | `/api/v1/competitions/{competition_id}` | `team1-frontend/lib/repositories/competition_repository.dart` |
| `DELETE` | `/competitions/$id` | → | `/api/v1/competitions/{competition_id}` | `team1-frontend/lib/repositories/competition_repository.dart` |
| `GET` | `/events/$id` | → | `/api/v1/events/{event_id}` | `team1-frontend/lib/repositories/event_repository.dart` |
| `POST` | `/events` | → | `/api/v1/events` | `team1-frontend/lib/repositories/event_repository.dart` |
| `PUT` | `/events/$id` | → | `/api/v1/events/{event_id}` | `team1-frontend/lib/repositories/event_repository.dart` |
| `DELETE` | `/events/$id` | → | `/api/v1/events/{event_id}` | `team1-frontend/lib/repositories/event_repository.dart` |
| `GET` | `/flights/$id` | → | `/api/v1/flights/{flight_id}` | `team1-frontend/lib/repositories/flight_repository.dart` |
| `POST` | `/flights` | → | `/api/v1/flights` | `team1-frontend/lib/repositories/flight_repository.dart` |
| `PUT` | `/flights/$id` | → | `/api/v1/flights/{flight_id}` | `team1-frontend/lib/repositories/flight_repository.dart` |
| `GET` | `/hands/$id` | → | `/api/v1/hands/{hand_id}` | `team1-frontend/lib/repositories/hand_repository.dart` |
| `GET` | `/payout-structures/$psId` | → | `/api/v1/payout-structures/{ps_id}` | `team1-frontend/lib/repositories/payout_structure_repository.dart` |
| `POST` | `/payout-structures` | → | `/api/v1/payout-structures` | `team1-frontend/lib/repositories/payout_structure_repository.dart` |
| `PUT` | `/payout-structures/$psId` | → | `/api/v1/payout-structures/{ps_id}` | `team1-frontend/lib/repositories/payout_structure_repository.dart` |
| `DELETE` | `/payout-structures/$psId` | → | `/api/v1/payout-structures/{ps_id}` | `team1-frontend/lib/repositories/payout_structure_repository.dart` |
| `GET` | `/players/$id` | → | `/api/v1/players/{player_id}` | `team1-frontend/lib/repositories/player_repository.dart` |
| `GET` | `/series/$id` | → | `/api/v1/series/{series_id}` | `team1-frontend/lib/repositories/series_repository.dart` |
| `POST` | `/series` | → | `/api/v1/series` | `team1-frontend/lib/repositories/series_repository.dart` |
| `PUT` | `/series/$id` | → | `/api/v1/series/{series_id}` | `team1-frontend/lib/repositories/series_repository.dart` |
| `DELETE` | `/series/$id` | → | `/api/v1/series/{series_id}` | `team1-frontend/lib/repositories/series_repository.dart` |
| `POST` | `/competitions` | → | `/api/v1/competitions` | `team1-frontend/lib/repositories/series_repository.dart` |
| `PUT` | `/competitions/$id` | → | `/api/v1/competitions/{competition_id}` | `team1-frontend/lib/repositories/series_repository.dart` |
| `DELETE` | `/competitions/$id` | → | `/api/v1/competitions/{competition_id}` | `team1-frontend/lib/repositories/series_repository.dart` |
| `GET` | `/blind-structures/$bsId` | → | `/api/v1/blind-structures/{bs_id}` | `team1-frontend/lib/repositories/settings_repository.dart` |
| `POST` | `/blind-structures` | → | `/api/v1/blind-structures` | `team1-frontend/lib/repositories/settings_repository.dart` |
| `PUT` | `/blind-structures/$bsId` | → | `/api/v1/blind-structures/{bs_id}` | `team1-frontend/lib/repositories/settings_repository.dart` |
| `DELETE` | `/blind-structures/$bsId` | → | `/api/v1/blind-structures/{bs_id}` | `team1-frontend/lib/repositories/settings_repository.dart` |
| `POST` | `/blind-structures/$blindStructureId/levels` | → | `/api/v1/blind-structures/{bs_id}/levels` | `team1-frontend/lib/repositories/settings_repository.dart` |
| `PUT` | `/blind-structures/$blindStructureId/levels/$levelId` | → | `/api/v1/blind-structures/{bs_id}/levels/{level_id}` | `team1-frontend/lib/repositories/settings_repository.dart` |
| `DELETE` | `/blind-structures/$blindStructureId/levels/$levelId` | → | `/api/v1/blind-structures/{bs_id}/levels/{level_id}` | `team1-frontend/lib/repositories/settings_repository.dart` |
| `GET` | `/skins/$id` | → | `/api/v1/skins/{skin_id}` | `team1-frontend/lib/repositories/skin_repository.dart` |
| `POST` | `/skins` | → | `/api/v1/skins` | `team1-frontend/lib/repositories/skin_repository.dart` |
| `POST` | `/skins/$id/activate` | → | `/api/v1/skins/{skin_id}/activate` | `team1-frontend/lib/repositories/skin_repository.dart` |
| `POST` | `/skins/$id/deactivate` | → | `/api/v1/skins/{skin_id}/deactivate` | `team1-frontend/lib/repositories/skin_repository.dart` |
| `DELETE` | `/skins/$id` | → | `/api/v1/skins/{skin_id}` | `team1-frontend/lib/repositories/skin_repository.dart` |
| `GET` | `/users/$id` | → | `/api/v1/users/{user_id}` | `team1-frontend/lib/repositories/staff_repository.dart` |
| `POST` | `/users` | → | `/api/v1/users` | `team1-frontend/lib/repositories/staff_repository.dart` |
| `PUT` | `/users/$id` | → | `/api/v1/users/{user_id}` | `team1-frontend/lib/repositories/staff_repository.dart` |
| `DELETE` | `/users/$id` | → | `/api/v1/users/{user_id}` | `team1-frontend/lib/repositories/staff_repository.dart` |
| `POST` | `/users/$id/force-logout` | → | `/api/v1/users/{user_id}/force-logout` | `team1-frontend/lib/repositories/staff_repository.dart` |
| `GET` | `/tables/$id` | → | `/api/v1/tables/{table_id}` | `team1-frontend/lib/repositories/table_repository.dart` |
| `POST` | `/tables` | → | `/api/v1/tables` | `team1-frontend/lib/repositories/table_repository.dart` |
| `PUT` | `/tables/$id` | → | `/api/v1/tables/{table_id}` | `team1-frontend/lib/repositories/table_repository.dart` |
| `DELETE` | `/tables/$id` | → | `/api/v1/tables/{table_id}` | `team1-frontend/lib/repositories/table_repository.dart` |
| ... | (3 more) | | | |

