---
title: B-080 Blind & Prize Structure Template 관리
owner: team1
tier: internal
confluence-page-id: 3818816061
confluence-parent-id: 3811606750
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818816061/EBS+B-080+Blind+Prize+Structure+Template
---

# B-080 — Blind & Prize Structure Template 관리

**상태**: PENDING  
**우선순위**: Top 2  
**등재일**: 2026-04-15  
**소유**: team1 (Lobby UI) + team2 (API/DB)

## 요구 기능

- Blind Level 정의 (Small/Big/Ante/Limit · duration · detail_type)
- Prize Structure 템플릿 관리 (순위별 배분 %)
- Template 복사 · 편집 · Tournament별 적용
- Blind Type 4종: Fixed / Progressive / Double / Half Pot

## 수락 기준

- [ ] `Lobby/Structure_Templates.md` 신규
- [ ] `blind_structure_changed`, `prize_structure_changed` WebSocket 이벤트 활용 흐름 명시

## 참조

- WSOP LIVE STAFF APP/05. Blind Structure/, /06. Prize Structure/
- Backend `DATA-04 §blind_structures`, `DATA-04 §payout_structures`
