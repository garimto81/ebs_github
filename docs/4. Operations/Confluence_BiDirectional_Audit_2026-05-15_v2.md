---
title: Confluence 양방향 Audit v2
date: 2026-05-15
mirror: none
---

# Confluence 양방향 Audit v2 - 2026-05-15

> **S11 DevOps** | Forward+Reverse 양방향 검증 | PR #483 blind spot 정정

## 핵심 발견

이전 audit 오진단 원인: archived 페이지도 HTTP 200 반환 -> 동기화 완료 오판.

**WSOPLive EBS 페이지 342개 전부 archived. git sync 현재 비작동 상태.**

## 요약 대시보드



## 자율 정정 완료

| 파일 | 조치 |
|------|------|
| docs/4. Operations/4. Operations.md | mirror: none 인라인 주석 제거 |

> YAML 파서 버그: mirror: none  # comment -> 전체 값으로 읽어 skip 안 됨
> -> mirror: none 으로 정리 완료 (1건 자율 수정)

## 사용자 결정 필요 - Space 정책

EBS WSOPLive 342개 전부 archived. 사용자 작업본 = personal space.

옵션 A: Personal space를 정식 mirror로 채택
  -> git page-id를 personal ID로 전수 업데이트
  -> title 매칭 96개 확인, 246개 수동 확인 필요

옵션 B: WSOPLive 전체 un-archive + 재발행
  -> archived 342개 un-archive 후 git에서 push

옵션 C: Sync 중단 - mirror: none 전수 적용
  -> 즉시 안전, Confluence는 stale 유지

## Title Cross-match 상위 30건 (사용자 확인 필요)

| git page-id (archived) | git 제목 | personal page-id | personal 제목 |
|------------------------|----------|------------------|---------------|
| 3811344758 | EBS · 1. Product | 3833495705 | 1. Product |
| 3811901603 | EBS Command Center | 3832905876 | 2.4 Command Center / APIs |
| 3811410570 | EBS Game Rules — Betting System | 3834085681 | Betting |
| 3811672228 | EBS Lobby | 3834216497 | Lobby |
| 3816784235 | EBS Overlay Graphics - RIVE Standar | 3833266224 | Overlay |
| 3811377375 | EBS · 2. Development | 3834249275 | 2. Development |
| 3818881468 | EBS · AUDIT-Conductor-194 — Fronten | 3834052660 | Graphic_Editor |
| 3819766263 | EBS · B-083 Tournament Statistics & | 3833069731 | Statistics |
| 3820552701 | EBS · Backlog | 3832873103 | Backlog |
| 3818684911 | EBS · Deployment | 3833626839 | Deployment |
| 3818750433 | EBS · Engineering — Frontend (Flutt | 3833036900 | Engineering |
| 3818684971 | EBS · Overview | 3833856204 | Overview |
| 3818848738 | EBS · board-re-crosscheck | 3833790574 | board-re-crosscheck |
| 3818750473 | EBS · layout-css-extraction | 3833921630 | layout-css-extraction |
| 3818717668 | EBS-Skin-Editor_v3.prd | 3833462916 | EBS-Skin-Editor_v3.prd |
| 3818521139 | EBS · ebs-ui-layout-anatomy | 3832807585 | ebs-ui-layout-anatomy |
| 3818717688 | EBS · prd-skin-editor.prd | 3832938650 | prd-skin-editor.prd |
| 3818619311 | EBS · README | 3833856224 | README |
| 3819766363 | EBS · ui-feature-verification-workf | 3832840364 | ui-feature-verification-workflow |
| 3818914312 | EBS · UI | 3833528483 | UI |
| 3818586772 | EBS · Operations | 3834151023 | Operations |
| 3818455598 | EBS · Overview (6750) | 3833856204 | Overview |
| 3818848718 | EBS · Registration | 3834118330 | Registration |
| 3820552741 | EBS · Table | 3833888968 | Table |
| 3818455618 | EBS · Form | 3834118350 | Form |
| 3819766303 | EBS · Display | 3834249297 | Display |
| 3819766323 | EBS · Graphics | 3833462936 | Graphics |
| 3818619271 | EBS · Outputs | 3833069711 | Outputs |
| 3818914500 | EBS · Settings · Overview | 3833856204 | Overview |
| 3818619291 | EBS · Preferences | 3832873186 | Preferences |
| *(+66gun JSON 참조)* | | | |

## Archived 전용 - personal 없음 상위 30건

| git page-id | git 제목 |
|-------------|----------|
| 3625189547 | EBS 기초 기획서 |
| 3811967073 | EBS Back Office |
| 3810853753 | EBS Game Rules — Draw Games |
| 3811443642 | EBS Game Rules — Flop Games |
| 3811771012 | EBS Game Rules — Seven Card Games |
| 3818848697 | EBS · Product SSOT Policy |
| 3819078185 | EBS · PokerGFX Reference |
| 3818455578 | EBS · B-079 Prize Pool & Payout Management |
| 3818816061 | EBS · B-080 Blind & Prize Structure Template 관리 |
| 3819078245 | EBS · B-081 Chip Management & Chip Reporter |
| 3818586752 | EBS · B-082 Staff Role & Permission 관리 |
| 3818684951 | EBS · Activate Broadcast |
| 3820552721 | EBS · Import Flow |
| 3819766283 | EBS · Metadata Editing |
| 3818750453 | EBS · RBAC Guards |
| 3819274944 | EBS Compact Mockup Design System |
| 3818947157 | EBS · Clock Control |
| 3818881488 | EBS · Event and Flight |
| 3819274904 | EBS · Session Restore |
| 3818816081 | EBS · UI (6750) |
| 3819274924 | EBS · Error Handling |
| 3819176565 | EBS · Session Init |
| 3818586793 | EBS · Auth and Session |
| 3818816101 | EBS · Backend HTTP |
| 3818914332 | EBS · Backend HTTP — 구현 현황 (2026-04-20) |
| 3820552761 | EBS · Graphic Editor API |
| 3819078266 | EBS · WebSocket Events |
| 3818816121 | EBS · Concurrency and Race Conditions (Auth domain) |
| 3818455638 | EBS · Quickstart — Local Cluster (Auth domain) |
| 3820552781 | EBS · Sync Protocol |
| *(+20gun)* | |

## Personal Orphan 상위 20건 (EBS 관련)

| page-id | 제목 | URL |
|---------|------|-----|
| 3638689898 | PRD-F001: WSOPTV Foundation | [link](https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3638689898/PRD-F001+WSOPTV+Foundation) |
| 3659071655 | WSOPLIVE → EBS 데이터 연동 통합 PRD | [link](https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3659071655/WSOPLIVE+EBS+PRD) |
| 3677487177 | Riot Games — 레퍼런스 상세 분석 | [link](https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3677487177/Riot+Games) |
| 3763044575 | EBS 개요 및 개발 계획 | [link](https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3763044575/EBS) |
| 3832807544 | Lobby (1. Product) | [link](https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3832807544/Lobby+1.+Product) |
| 3832840302 | 2.3 Game Engine | [link](https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3832840302/2.3+Game+Engine) |
| 3832840384 | README (EBS_Lobby_Design) | [link](https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3832840384/README+EBS_Lobby_Design) |
| 3832840404 | B-026-CC-로컬-버퍼-동기화-프로토콜 | [link](https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3832840404/B-026-CC-+-+-+-) |
| 3832840464 | GFSkin_Schema | [link](https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3832840464/GFSkin_Schema) |
| 3832873166 | Command_Center (1. Product) | [link](https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3832873166/Command_Center+1.+Product) |
| 3832873227 | Error_Handling (Engineering) | [link](https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3832873227/Error_Handling+Engineering) |
| 3832873267 | Overlay_Output_Events | [link](https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3832873267/Overlay_Output_Events) |
| 3832905876 | 2.4 Command Center / APIs | [link](https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3832905876/2.4+Command+Center+APIs) |
| 3832938601 | 2.4 Command Center | [link](https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3832938601/2.4+Command+Center) |
| 3832971356 | EBS_Lobby_Design | [link](https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3832971356/EBS_Lobby_Design) |
| 3832971399 | Engineering (2.1 Frontend) | [link](https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3832971399/Engineering+2.1+Frontend) |
| 3833004200 | Betting_and_Pots | [link](https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3833004200/Betting_and_Pots) |
| 3833036900 | Engineering | [link](https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3833036900/Engineering) |
| 3833036921 | Betting_System | [link](https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3833036921/Betting_System) |

> 기타 personal 페이지 EBS 무관: 약 353건

---
*생성: confluence_bidir_audit_v2 | 343 unique page IDs scanned*