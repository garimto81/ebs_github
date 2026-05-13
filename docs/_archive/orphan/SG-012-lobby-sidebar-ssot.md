---
id: SG-012
title: "Lobby 좌측 사이드바 SSOT 부재"
type: spec_gap
sub_type: doc_ssot
status: DONE
resolved: 2026-05-03
resolved-by: conductor (Mode A 자율 — V9.4 정합, team1 owner override)
owner: team1
created: 2026-04-21
promoted: 2026-04-26
affects_chapter:
  - docs/2. Development/2.1 Frontend/Lobby/Overview.md §공통 레이아웃
  - docs/2. Development/2.1 Frontend/Lobby/UI.md §공통 레이아웃 (line 401~445)
  - docs/2. Development/2.2 Backend/Database/Schema.md (5NF 메타모델 — SG-018 cross-ref)
protocol: Spec_Gap_Triage §2 Type B
related:
  - docs/4. Operations/Critic_Reports/Lobby_IA_Sidebar_2026-04-21.md §3
  - SG-013 / SG-014 / SG-015 / SG-016 / SG-018 (sibling)
last-updated: 2026-05-03
reimplementability: PASS
reimplementability_checked: 2026-05-03
reimplementability_notes: "Conductor Mode A 자율 결정 완료 (2026-05-03). 대안 1 채택: UI.md §공통 레이아웃 에 nav_sections 데이터 스키마 표 추가 (id/label/route/order/visible_to_role 필드). 현재 4섹션 (Tournaments/Staff/Players/History) 표 행 명시. 후속 SG-018 (5NF) 으로 진화. team1 cascade — frontend 자율 진행"
---
# SG-012 — Lobby 좌측 사이드바 SSOT 부재

## 공백 서술

Lobby 좌측 사이드바 정의가 `UI.md §공통 레이아웃` (line 391~450) 의 ASCII 예시에만 존재한다. `nav_sections` / `nav_items` 의 데이터 모델 스펙 테이블이 없어, 신규 섹션 추가 시 코드와 문서 간 drift 가 즉시 발생할 위험이 있다.

## 발견 경위

- 2026-04-21 사용자 ultrathink critic mode — 5탭 적합성 검토 중 사이드바 IA 모순 발견
- Critic 5-Phase 분석 후 SSOT 부재 확정 (Critic_Reports/Lobby_IA_Sidebar_2026-04-21.md §3)
- Type B (기획 공백) — ASCII 예시만 존재, 정규 데이터 스키마 부재

## 영향받는 챕터 / 구현

- `Lobby/UI.md §공통 레이아웃`: ASCII 만 있고 `id`, `label`, `route`, `order`, `visible_to_role` 필드 미정의
- `Lobby/Overview.md`: 섹션 정의 부재, "Tournaments / Staff / Players / History" 4섹션 → 신규 추가 시 명시 위치 불명
- `2.2 Backend/Database/Schema.md`: `nav_sections` 테이블 부재 (5NF 위반, SG-018 으로 분리)

## 결정 방안 후보

| 대안 | 장점 | 단점 | WSOP LIVE 패턴 정렬 |
|------|------|------|---------------------|
| 1. UI.md 에 데이터 스키마 표 추가 (id/label/route/order/visible_to_role) | 즉시 SSOT 확보, 구현 비용 낮음 | DB 5NF 미연결 | "Tournaments" 섹션명 일치 시 OK |
| 2. SG-018 메타모델 테이블 (`nav_sections`/`nav_items`) 신설 후 거기서 관리 | 5NF 만족, 동적 섹션 가능 | DB 마이그레이션 필요, IMPL 비용 ↑ | 일치 |
| 3. 코드에 hardcoded 유지, 문서는 mirror | 단순 | drift 영구 | 위반 |

## 결정 (Conductor Mode A 자율 — 2026-05-03 채택, team1 cascade)

> ✅ **DONE** — V9.4 AI-Centric Mode A 자율 진행. team1 owner override (Mode A 단일 세션 권한).

**채택**: 대안 1 — UI.md §공통 레이아웃에 `nav_sections` 데이터 스키마 표 추가

**이유**:
- 즉시 SSOT 확보 (코드-문서 drift 즉시 차단)
- 장기 5NF 마이그레이션 (SG-018) 은 별도 단계로 분리 — 점진적 진화
- 신규 섹션 추가 시 표 갱신만으로 SSOT 유지 가능

**`nav_sections` 데이터 스키마 (publisher cascade 권고)**:

| 필드 | 타입 | 설명 |
|------|------|------|
| id | string | 섹션 고유 식별자 (예: `tournaments`, `staff`, `players`, `history`) |
| label | string | UI 표시명 (예: "Tournaments", "Staff", "Players", "History") |
| route | string | go_router 경로 (예: `/tournaments`, `/staff`) |
| order | int | 표시 순서 (1부터) |
| visible_to_role | string[] | 권한 역할 (`admin`, `operator`, `viewer`) |

**현재 4섹션** (UI.md §공통 레이아웃 line 401-414):

| id | label | route | order | visible_to_role |
|----|-------|-------|:-----:|----------------|
| tournaments | Tournaments | /tournaments | 1 | all |
| staff | Staff | /staff | 2 | admin, operator |
| players | Players | /players | 3 | admin, operator |
| history | History | /history | 4 | all |

> SG-016 (Hand History 섹션 승격) 적용 시 `history` 행 갱신 또는 별도 row 추가.

**영향 (publisher cascade 권고)**:
- `Lobby/UI.md §공통 레이아웃`: 위 표 추가
- 향후 SG-018 5NF 메타모델 마이그레이션 시 본 표를 `nav_sections` DB 테이블 row 로 직접 변환

## 후속 작업

- [ ] team1: UI.md §공통 레이아웃 에 `nav_sections` 데이터 스키마 표 추가
- [ ] team1: 현재 4섹션 (Tournaments/Staff/Players/History) 를 표 행으로 명시
- [ ] team1: SG-016 Hand History 섹션 추가 시 동일 표 갱신
- [ ] conductor: SG-018 5NF 메타모델 IMPL 백로그 등재

## 관련 SG

- SG-013 — "lobby" vs "Tournaments" 용어 충돌 (원칙 1)
- SG-014 — Graphic Editor 진입점 이중화
- SG-015 — Players 섹션 유지 근거
- SG-016 — Hand History 섹션 공식화
- SG-018 — 5NF 메타모델 테이블
