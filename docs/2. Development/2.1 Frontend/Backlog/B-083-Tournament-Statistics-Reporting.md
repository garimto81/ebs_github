---
title: B-083 Tournament Statistics & Reporting
owner: team1
tier: internal
---

# B-083 — Tournament Statistics & Reporting

**상태**: PENDING  
**우선순위**: Top 5  
**등재일**: 2026-04-15  
**소유**: team1 (UI) + team2 (API/집계)

## 요구 기능

- Players Count 통계 (실시간·누적)
- Tournament History Report
- Prize Pool Report
- Leaderboard (세션/시리즈 단위)
- Unique Player Report
- Tableau Dashboard 연동 (옵션)

## 수락 기준

- [ ] `Lobby/Reports.md` 신규
- [ ] Backend `/Reports/*` 엔드포인트 명세 · `audit_events` 기반 집계 쿼리
- [ ] Export Folder (Operations.md §1.3 DB Export) 연계

## 참조

- WSOP LIVE STAFF APP/09. Reports/, /41. Tableau/
- `Operations.md §1.3 Export`
