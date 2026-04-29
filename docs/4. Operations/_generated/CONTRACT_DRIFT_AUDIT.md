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
| bo endpoints | 127 |
| lobby HTTP calls | 53 |
| matched | 11 |
| **lobby paths unknown (404 risk)** | **42** |
| bo unused | 117 |

## Drift A — lobby 가 호출하지만 bo 가 모름 (404 위험)

| method | lobby path | 파일:줄 |
|--------|-----------|--------|
| `POST` | `/Auth/Verify2FA` | `team1-frontend/lib/repositories/auth_repository.dart:63` |
| `DELETE` | `/Auth/Session` | `team1-frontend/lib/repositories/auth_repository.dart:87` |
| `GET` | `/Competitions/$id` | `team1-frontend/lib/repositories/competition_repository.dart:23` |
| `PUT` | `/Competitions/$id` | `team1-frontend/lib/repositories/competition_repository.dart:41` |
| `DELETE` | `/Competitions/$id` | `team1-frontend/lib/repositories/competition_repository.dart:49` |
| `GET` | `/Events/$id` | `team1-frontend/lib/repositories/event_repository.dart:23` |
| `PUT` | `/Events/$id` | `team1-frontend/lib/repositories/event_repository.dart:38` |
| `DELETE` | `/Events/$id` | `team1-frontend/lib/repositories/event_repository.dart:46` |
| `GET` | `/Flights/$id` | `team1-frontend/lib/repositories/flight_repository.dart:32` |
| `PUT` | `/Flights/$id` | `team1-frontend/lib/repositories/flight_repository.dart:47` |
| `GET` | `/Hands/$id` | `team1-frontend/lib/repositories/hand_repository.dart:23` |
| `GET` | `/Series/$seriesId/PayoutStructures/$psId` | `team1-frontend/lib/repositories/payout_structure_repository.dart:49` |
| `POST` | `/Series/$seriesId/PayoutStructures` | `team1-frontend/lib/repositories/payout_structure_repository.dart:60` |
| `PUT` | `/Series/$seriesId/PayoutStructures/$psId` | `team1-frontend/lib/repositories/payout_structure_repository.dart:73` |
| `DELETE` | `/Series/$seriesId/PayoutStructures/$psId` | `team1-frontend/lib/repositories/payout_structure_repository.dart:82` |
| `GET` | `/Players/$id` | `team1-frontend/lib/repositories/player_repository.dart:23` |
| `GET` | `/Series/$id` | `team1-frontend/lib/repositories/series_repository.dart:23` |
| `PUT` | `/Series/$id` | `team1-frontend/lib/repositories/series_repository.dart:38` |
| `DELETE` | `/Series/$id` | `team1-frontend/lib/repositories/series_repository.dart:46` |
| `PUT` | `/Competitions/$id` | `team1-frontend/lib/repositories/series_repository.dart:73` |
| `DELETE` | `/Competitions/$id` | `team1-frontend/lib/repositories/series_repository.dart:81` |
| `GET` | `/Series/$seriesId/BlindStructures/$bsId` | `team1-frontend/lib/repositories/settings_repository.dart:55` |
| `POST` | `/Series/$seriesId/BlindStructures` | `team1-frontend/lib/repositories/settings_repository.dart:66` |
| `PUT` | `/Series/$seriesId/BlindStructures/$bsId` | `team1-frontend/lib/repositories/settings_repository.dart:79` |
| `DELETE` | `/Series/$seriesId/BlindStructures/$bsId` | `team1-frontend/lib/repositories/settings_repository.dart:88` |
| `POST` | `/BlindStructures/$blindStructureId/Levels` | `team1-frontend/lib/repositories/settings_repository.dart:113` |
| `PUT` | `/BlindStructures/$blindStructureId/Levels/$levelId` | `team1-frontend/lib/repositories/settings_repository.dart:126` |
| `DELETE` | `/BlindStructures/$blindStructureId/Levels/$levelId` | `team1-frontend/lib/repositories/settings_repository.dart:138` |
| `GET` | `/Skins/$id` | `team1-frontend/lib/repositories/skin_repository.dart:21` |
| `POST` | `/Skins/$id/Activate` | `team1-frontend/lib/repositories/skin_repository.dart:76` |
| `POST` | `/Skins/$id/Deactivate` | `team1-frontend/lib/repositories/skin_repository.dart:83` |
| `DELETE` | `/Skins/$id` | `team1-frontend/lib/repositories/skin_repository.dart:90` |
| `GET` | `/Users/$id` | `team1-frontend/lib/repositories/staff_repository.dart:23` |
| `PUT` | `/Users/$id` | `team1-frontend/lib/repositories/staff_repository.dart:38` |
| `DELETE` | `/Users/$id` | `team1-frontend/lib/repositories/staff_repository.dart:46` |
| `POST` | `/Users/$id/ForceLogout` | `team1-frontend/lib/repositories/staff_repository.dart:50` |
| `GET` | `/Tables/$id` | `team1-frontend/lib/repositories/table_repository.dart:30` |
| `PUT` | `/Tables/$id` | `team1-frontend/lib/repositories/table_repository.dart:45` |
| `DELETE` | `/Tables/$id` | `team1-frontend/lib/repositories/table_repository.dart:53` |
| `POST` | `/Tables/$tableId/Seats` | `team1-frontend/lib/repositories/table_repository.dart:86` |
| `PUT` | `/Tables/$tableId/Seats/$seatNo` | `team1-frontend/lib/repositories/table_repository.dart:98` |
| `DELETE` | `/Tables/$tableId/Seats/$seatNo` | `team1-frontend/lib/repositories/table_repository.dart:106` |

## Drift B — bo 가 제공하지만 lobby 가 호출 안 함 (정보)

| method | bo path |
|--------|--------|
| `POST` | `/auth/logout` |
| `GET` | `/auth/me` |
| `POST` | `/auth/verify-2fa` |
| `POST` | `/auth/2fa/setup` |
| `POST` | `/auth/2fa/disable` |
| `POST` | `/auth/password/reset/send` |
| `POST` | `/auth/password/reset/verify` |
| `POST` | `/auth/password/reset` |
| `GET` | `/auth/google` |
| `GET` | `/auth/google/callback` |
| `GET` | `/api/v1/series` |
| `GET` | `/api/v1/series/{series_id}` |
| `PUT` | `/api/v1/series/{series_id}` |
| `DELETE` | `/api/v1/series/{series_id}` |
| `GET` | `/api/v1/series/{series_id}/events` |
| `POST` | `/api/v1/series/{series_id}/events` |
| `GET` | `/api/v1/events` |
| `GET` | `/api/v1/events/{event_id}` |
| `PUT` | `/api/v1/events/{event_id}` |
| `DELETE` | `/api/v1/events/{event_id}` |
| `GET` | `/api/v1/flights` |
| `GET` | `/api/v1/events/{event_id}/flights` |
| `POST` | `/api/v1/events/{event_id}/flights` |
| `GET` | `/api/v1/flights/{flight_id}` |
| `PUT` | `/api/v1/flights/{flight_id}` |
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
| `GET` | `/api/v1/tables/{table_id}` |
| `PUT` | `/api/v1/tables/{table_id}` |
| `DELETE` | `/api/v1/tables/{table_id}` |
| `GET` | `/api/v1/tables/{table_id}/status` |
| `GET` | `/api/v1/tables/{table_id}/seats` |
| `PUT` | `/api/v1/tables/{table_id}/seats/{seat_no}` |
| `GET` | `/api/v1/players` |
| `POST` | `/api/v1/players` |
| `GET` | `/api/v1/players/search` |
| ... | (67 more) |

## Matched (정합 통과 — 매칭 매트릭스)

| method | lobby path | → | bo path | 파일 |
|--------|-----------|---|---------|------|
| `POST` | `/Auth/Login` | → | `/auth/login` | `team1-frontend/lib/repositories/auth_repository.dart` |
| `POST` | `/Auth/Refresh` | → | `/auth/refresh` | `team1-frontend/lib/repositories/auth_repository.dart` |
| `GET` | `/Auth/Session` | → | `/auth/session` | `team1-frontend/lib/repositories/auth_repository.dart` |
| `POST` | `/Competitions` | → | `/api/v1/competitions` | `team1-frontend/lib/repositories/competition_repository.dart` |
| `POST` | `/Events` | → | `/api/v1/events` | `team1-frontend/lib/repositories/event_repository.dart` |
| `POST` | `/Flights` | → | `/api/v1/flights` | `team1-frontend/lib/repositories/flight_repository.dart` |
| `POST` | `/Series` | → | `/api/v1/series` | `team1-frontend/lib/repositories/series_repository.dart` |
| `POST` | `/Competitions` | → | `/api/v1/competitions` | `team1-frontend/lib/repositories/series_repository.dart` |
| `POST` | `/Skins` | → | `/api/v1/skins` | `team1-frontend/lib/repositories/skin_repository.dart` |
| `POST` | `/Users` | → | `/api/v1/users` | `team1-frontend/lib/repositories/staff_repository.dart` |
| `POST` | `/Tables` | → | `/api/v1/tables` | `team1-frontend/lib/repositories/table_repository.dart` |

