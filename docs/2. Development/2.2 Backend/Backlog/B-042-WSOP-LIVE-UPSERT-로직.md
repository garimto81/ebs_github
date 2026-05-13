---
id: B-042
title: WSOP LIVE UPSERT 로직
backlog-status: open
source: docs/2. Development/2.2 Backend/Backlog.md
mirror: none
---

# [B-042] WSOP LIVE UPSERT 로직
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: wsop_id 기준 매칭 → INSERT/UPDATE. source='manual' 필드 보호. API 끊김 시 재시도 + DB 캐시 폴백.
- **수락 기준**: source='manual' 플레이어 → WSOP LIVE 동기화 대상 제외 확인.
- **관련 PRD**: team2-backend/specs/back-office/BO-10-wsop-live-sync.md
