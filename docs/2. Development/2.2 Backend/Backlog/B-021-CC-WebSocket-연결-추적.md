---
id: B-021
title: CC WebSocket 연결 추적
status: PENDING
source: docs/2. Development/2.2 Backend/Backlog.md
---

# [B-021] CC WebSocket 연결 추적
- **날짜**: 2026-04-09
- **teams**: [team2, team4]
- **설명**: CC 연결 시 `OperatorConnected` 이벤트 → Lobby로 전파. CC 연결 해제 시 `OperatorDisconnected`. CC 활성 시 설정 잠금 적용.
- **수락 기준**: CC 연결 → Lobby monitor 채널에 OperatorConnected 이벤트 수신.
- **관련 PRD**: team2-backend/specs/back-office/BO-04-table-management.md, team2-backend/specs/back-office/BO-09-data-sync.md
