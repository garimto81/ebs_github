---
id: B-023
title: 핸드 기록 수신 — CC → BO WebSocket
status: PENDING
source: docs/2. Development/2.2 Backend/Backlog.md
---

# [B-023] 핸드 기록 수신 — CC → BO WebSocket
- **날짜**: 2026-04-09
- **teams**: [team2, team4]
- **설명**: CC로부터 핸드 완료 이벤트 수신. hands, hand_players, hand_actions INSERT (append-only). Event Sourcing 보장.
- **수락 기준**: CC에서 HandCompleted 이벤트 전송 → 3개 테이블에 레코드 생성 확인.
- **관련 PRD**: team2-backend/specs/back-office/BO-06-hand-history.md
