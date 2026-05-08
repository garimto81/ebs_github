---
title: SSOT Alignment Progress
owner: conductor
tier: internal
last-updated: 2026-04-20
parent: Roadmap.md (구 SSOT 정렬 진척표, 프로젝트 의도 재정의로 분리 보존)
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "WSOP LIVE 정렬 진척표 구조 명확"
---

# SSOT Alignment Progress — EBS ↔ WSOP LIVE Confluence

> **주의**: 이 문서는 "EBS 기획서가 WSOP LIVE 원본과 얼마나 정렬되었는가" 만 추적합니다.
> "프로젝트 완결성" 추적은 `Roadmap.md` 로 이동 (2026-04-20 프로젝트 의도 재정의).

## 목적

EBS `docs/` + 팀별 코드 산출물을 WSOP LIVE Confluence 원본과 1:1 정렬.
`/ssot-align` 스킬이 이 문서를 auto_update 로 유지.

## 실행 방법

각 팀 세션에서:

```
/ssot-align                 # 자기 팀 스코프 전체 자동
/ssot-align --audit         # drift 검증만
/ssot-align --dry-run       # 미리보기
```

Conductor 세션에서:

```
cd C:/claude/ebs && /ssot-align
```

## 스코프 진행 현황

상태: `PENDING` (미처리) / `IN_PROGRESS` (진행 중) / `COMPLETED` (완료) / `NATIVE` (SSOT 없음) / `DEFERRED` (후순위)

### contracts/ (26 파일 / Conductor 소유)

| 파일 | 주요 섹션 추정 | WSOP 소스 | 상태 | 최종 확인 |
|------|-------------|----------|------|----------|
| api/`Backend_HTTP.md` (legacy-id: API-01) | 엔드포인트 목록 + WSOP LIVE Integration (Part II) | Staff App API 계열 + WSOPLIVE → EBS 데이터 연동 PRD (3659071655) | PENDING | — |
| api/API-03-rfid-hal-interface.md | 전체 | — | NATIVE | — |
| api/`Overlay_Output_Events.md` (legacy-id: API-04) | 전체 | EBS UI Design Console (3646783501) 부분 | PENDING | — |
| api/`WebSocket_Events.md` (legacy-id: API-05) | 이벤트 목록 | Staff App Live (실시간 데이터 처리) | PENDING | — |
| api/`Auth_and_Session.md` (legacy-id: API-06) | 전체 | GGPass 연동 | PENDING | — |
| api/`Graphic_Editor_API.md` (legacy-id: API-07) | 전체 | — | NATIVE | — |
| api/README.md | — | — | NATIVE | — |
| data/DATA-01-er-diagram.md | ERD | WSOP+ Database 설명 (1652949021) | PENDING | — |
| data/DATA-03-state-machines.md | 상태 머신 | (혼합) | PENDING | — |
| data/DATA-04-db-schema.md | table_seats / event_type / waiting_list | Action History (1679556614), Waiting API (2418737362) | PENDING | 2026-04-14 (critic) |
| data/DATA-07-gfskin-schema.md | 전체 | — | NATIVE | — |
| data/README.md | — | — | NATIVE | — |
| specs/BS-00-definitions.md | 정의 | (혼합) | PENDING | — |
| specs/BS-01-auth/BS-01-auth.md | 인증 | GGPass 연동 | PENDING | — |
| specs/BS-04-rfid/BS-04-04-hal-contract.md | HAL | — | NATIVE | — |
| specs/BS-06-game-engine/`Triggers.md` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: BS-06-00-triggers)))) | 트리거 | (부분) Action History | PENDING | — |
| specs/BS-06-game-engine/README.md | — | — | NATIVE | — |
| specs/README.md | — | — | NATIVE | — |
| ccr-risk-matrix.md | — | — | NATIVE | — |
| README.md | — | — | NATIVE | — |
| _templates/SSOT-ALIGNED-SPEC-TEMPLATE.md | — | — | NATIVE (template) | — |

### team1-frontend/

| 파일 | 상태 | 비고 |
|------|------|------|
| ui-design/UI-01-lobby.md | PENDING | EBS UI Design Console (3646783501) 참조 |
| specs/** | PENDING | 팀 세션에서 `/ssot-align` 실행 |

### team2-backend/

| 파일 | 상태 | 비고 |
|------|------|------|
| specs/BO-02-wsop-sync.md | PENDING | WSOPLIVE → EBS 데이터 연동 (3659071655) + Staff App API 계열 |
| qa/** | PENDING | 팀 세션 집행 |

### team3-engine/

| 파일 | 상태 | 비고 |
|------|------|------|
| specs/games/** | NATIVE | EBS 게임 규칙 (Confluence 발행 대상, 역참조 아님) |
| 기타 | PENDING | 팀 세션 집행 |

### team4-cc/

| 파일 | 상태 | 비고 |
|------|------|------|
| specs/BS-05-command-center/** | PENDING | Action Tracker (3702325397) 참조 |
| ui-design/** | PENDING | 팀 세션 집행 |

## 핵심 WSOP LIVE 페이지 맵

| page_id | 제목 | 참조되는 EBS 영역 |
|---------|------|-----------------|
| 1679556614 | Action History | SeatStatus, EventFlightActionType |
| 2418737362 | Waiting API | waiting_list |
| 1652949021 | WSOP+ Database 설명(2023.04.17) | ERD, 엔티티 |
| 3659071655 | WSOPLIVE → EBS 데이터 연동 통합 PRD | 전반적 데이터 흐름 |
| 3646783501 | EBS UI Design Console | UI, Overlay |
| 3702325397 | EBS UI Design - Action Tracker | CC |
| 3625189547 | EBS 기초 기획서 | Foundation PRD |

추가는 `/con-lookup` 으로 수시 발견/확장.

## 완료 조건

- 모든 PENDING 파일이 COMPLETED / NATIVE / DEFERRED 중 하나로 분류됨
- COMPLETED 파일의 모든 WSOP-참조 섹션이 5-블록 템플릿 적용
- 매핑표 모든 행에 판정 존재, DEFERRED 는 후순위 근거 보유
- sprint 시작마다 `/ssot-align --audit` 로 drift 검증

## 이력

- **2026-04-20** — `Roadmap.md` 에서 분리 (프로젝트 의도 재정의: Roadmap 은 기획서 완결성 로드맵으로 재작성)
- **2026-04-14 09:27 UTC** — rendered=7 (ssot-align auto-update)
- **2026-04-14** — 초기 작성 (스킬 제작 후 초기 스켈레톤)
