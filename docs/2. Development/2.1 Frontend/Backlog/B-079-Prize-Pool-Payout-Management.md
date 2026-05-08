---
title: B-079 Prize Pool & Payout Management
owner: team1
tier: internal
confluence-page-id: 3818455578
confluence-parent-id: 3811606750
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818455578/EBS+B-079+Prize+Pool+Payout+Management
---

# B-079 — Prize Pool & Payout Management

**상태**: PENDING  
**우선순위**: Top 1 (미반영 Lobby 기능 중 최우선)  
**등재일**: 2026-04-15  
**소유**: team1 (Lobby) — 일부 team2 (API)

## 배경

Round 2 에서 WSOP LIVE Tournament Manager · Clock Control · Registration · Table Management 를 Lobby 에 반영했으나, **Prize Pool & Payout 기능은 미반영**. WSOP LIVE `Prize Pool _ Payout Assignment _ Payments.md` 의 핵심 기능을 EBS 에 추가 필요.

## 요구 기능 (WSOP LIVE 원본 기준)

- Guaranteed Prize Pool 설정
- Prize Pool 자동/수동 계산
- Payout 자동 생성 (ITM 도달 시)
- Prize Validation 페이지
- Prize Distribution (ITM 전/후)
- Prize Multiplier (일괄 조정)
- Advanced Payment 처리

## 수락 기준

- [ ] `Lobby/Prize_Pool.md` 신규 작성 (WSOP LIVE 패턴 반영)
- [ ] `Backend/APIs/Backend_HTTP.md` 에 `/prize_pools/*` 엔드포인트 명세 추가
- [ ] `Backend/Database/Schema.md` 에 `prize_pools`, `payouts` 테이블 정의
- [ ] `Registration.md §5 Tournament Refund` 와 Prize Distribution 연동 규칙 명시

## 블로커

- team2 와 `prize_pool_changed` 이벤트 payload 상세 협의 필요

## 참조

- WSOP LIVE Confluence: STAFF APP/04. Tournament Admin/Prize Pool _ Payout Assignment _ Payments.md
- Round 2 PR #4 `Registration.md §5`
