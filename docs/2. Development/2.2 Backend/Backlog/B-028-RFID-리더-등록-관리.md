---
id: B-028
title: RFID 리더 등록 관리
backlog-status: open
source: docs/2. Development/2.2 Backend/Backlog.md
mirror: none
---

# [B-028] RFID 리더 등록 관리
- **날짜**: 2026-04-09
- **teams**: [team2]
- **설명**: RFID 리더 CRUD (테이블 할당). `PUT /tables/{id}` — rfid_reader_id 업데이트. RFID 상태 추적 (연결/해제/에러).
- **수락 기준**: RFID 리더 등록 → 테이블에 할당. 상태 변경 → WebSocket 이벤트 전파.
- **관련 PRD**: team2-backend/specs/back-office/BO-04-table-management.md
