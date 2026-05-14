---
title: SESSION 3 INIT — Frontend Interface & Routing (team1 영역)
owner: conductor
tier: internal
type: session-init
session: 3
session-status: INITIATED
linked-sg: SG-022 (단일 Desktop) + SG-024 (Mode A) + SG-027 (5-Session Pipeline)
linked-decision: 사용자 Session 3 진입 명시 (2026-04-27)
last-updated: 2026-04-27
confluence-page-id: 3820552941
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3820552941/EBS+SESSION+3+INIT+Frontend+Interface+Routing+team1
---

## Session 3 — Frontend Interface & Routing 진입 (2026-04-27)

### Session 1 + 2 완료 baseline

| Session | 결과 |
|:-------:|------|
| ✅ Session 1 (Foundation & Infrastructure) | COMPLETED |
| ✅ Session 2 (Core Logic & Backend Engine) | COMPLETED — 8 sub-sessions, +154 tests, 78%→89% coverage, B-Q7 ㉠ 90% 재정의 |
| 🟢 **Session 3 (Frontend Interface & Routing)** | **INITIATED 2026-04-27** |
| ⏳ Session 4 (System Integration & QA) | PENDING |
| ⏳ Session 5 (Final Production & Audit) | PENDING |

## Session 3 목표

> Frontend Interface & Routing — Team 1 가동. 단일 Desktop 라우팅, UI 컴포넌트 렌더링, 100ms SLA 클라이언트 측정.

### 핵심 작업 영역

| 우선순위 | 작업 | linked-sg |
|:-------:|------|----------|
| **P0** | B-Q13 — 단일 Desktop 바이너리 라우팅 (go_router) | SG-022 |
| P1 | B-Q14 — Settings 5-level scope UI (Riverpod) | SG-003+017, C.1 |
| P1 | B-Q3 잔여 — team1 web/ + Dockerfile Web 빌드 단계 정리 | SG-022 |
| P2 | C.2 — Rive Manager Validate UI | SG-021 |
| P2 | 100ms SLA 클라이언트 측정 framework | BLANK-1 |
| P3 | team1 frontend test coverage 90% (B-Q7 재정의) | B-Q7 |

## Session 2 잔여 (Session 4 또는 별도 turn)

| ID | 내용 | priority |
|:--:|------|:--------:|
| B-Q18 | structure update tx flush bug | P1 surgical |
| B-Q19 | list_hands SQLAlchemy 2.x Row int() | P1 surgical |
| B-Q11 | OWASP audit | P2 (Session 5) |
| B-Q12 | 100ms SLA 측정 framework | P2 (Session 4 + 일부 Session 3) |

## team1-frontend 외부 활동 발견

본 turn pull --rebase 결과: team1-frontend 에 **production 배포 관련 파일 신규** 발견:
- `team1-frontend/lighthouserc.json` — Lighthouse CI 설정
- `team1-frontend/production.example.json` — production config 예시
- `team1-frontend/scripts/build_release.sh` — release build script
- `team1-frontend/scripts/sentry_release.sh` — Sentry release script
- `team1-frontend/test_driver/integration_driver.dart` — integration 테스트 driver

→ **team1 외부 세션 활발히 진행 중**. Session 3.1 진입 시 이 변경 검토 필요.

## Session 3.1 진입 권고 (다음 turn)

| 작업 | 분량 |
|------|:----:|
| 1. team1-frontend/ 외부 변경 (5 신규 파일) 검토 + 합의 | 작음 |
| 2. lib/foundation/router/app_router.dart 분석 + SG-022 단일 Desktop 라우팅 적용 | 중간 |
| 3. Foundation §5.0 두 런타임 모드 (탭/슬라이딩 vs 다중창) 구현 | 중간 |
| 4. flutter test 단위 테스트 | 작음 |

## Session Isolation 룰 (5-Session Pipeline, SG-027)

Session 3 = team1 영역만. 단:
- Mode A 권한 (SG-024): Conductor 가 team1-frontend/ 직접 진입 가능
- Strict 룰 보존: 가능한 한 surgical edit + 기존 자산 보호

## 참조

- `docs/4. Operations/Conductor_Backlog/SESSION_2_FINAL_REPORT.md`
- `docs/4. Operations/Conductor_Backlog/B-Q13-desktop-routing-implementation.md`
- `docs/4. Operations/Conductor_Backlog/B-Q14-settings-ui-implementation.md`
- `docs/4. Operations/Multi_Session_Workflow.md` §"v7.2 — 5-Session Pipeline"
- `team1-frontend/CLAUDE.md` (team1 세션 진입점)
