---
title: B-082 Staff Role & Permission 관리
owner: team1
tier: internal
confluence-page-id: 3818586752
confluence-parent-id: 3811606750
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818586752/EBS+B-082+Staff+Role+Permission
mirror: none
---

# B-082 — Staff Role & Permission 관리

**상태**: PENDING  
**우선순위**: Top 4  
**등재일**: 2026-04-15  
**소유**: Conductor (Shared) + team1 (UI) + team2 (API)

## 요구 기능

WSOP LIVE 의 6~7 Staff Role 확장:
- System Operator, Staff Admin, Tournament Manager, Tournament Admin, Chip Reporter, Table Dealer, Floor Manager

Role 별 Permission 매트릭스 + 계정 관리 + Staff Notification.

## 수락 기준

- [ ] `Shared/Authentication.md §RBAC` 에 신규 Role 4종 추가 (현재 Admin/Operator/Viewer 3종 → 7종 확장)
- [ ] `Lobby/Staff_Management.md` 신규
- [ ] Backend `user_roles` 테이블 확장 · Permission Bit Flag 확장

## 참조

- WSOP LIVE STAFF APP/02. Staff Admin/, /10. Special Staff Permissions/
