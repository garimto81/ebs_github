---
id: SG-012
title: "Lobby 좌측 사이드바 SSOT 부재"
type: spec_gap
sub_type: doc_ssot
status: PENDING
owner: team1  # decision_owner
created: 2026-04-21
promoted: 2026-04-26  # Registry §4.4 → 개별 파일
affects_chapter:
  - docs/2. Development/2.1 Frontend/Lobby/Overview.md §공통 레이아웃
  - docs/2. Development/2.1 Frontend/Lobby/UI.md §공통 레이아웃 (line 401~445)
  - docs/2. Development/2.2 Backend/Database/Schema.md (5NF 메타모델 — SG-018 cross-ref)
protocol: Spec_Gap_Triage §2 Type B
related:
  - docs/4. Operations/Critic_Reports/Lobby_IA_Sidebar_2026-04-21.md §3
  - SG-013 / SG-014 / SG-015 / SG-016 / SG-018 (sibling)
reimplementability: UNKNOWN
reimplementability_checked: 2026-05-03
reimplementability_notes: "status=PENDING — Lobby 좌측 사이드바 SSOT 미해결"
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

## 결정 (decision_owner team1 판정 시 기입)

- **default 권고**: 대안 1 (UI.md 스키마 표 추가) → 후속 SG-018 (5NF) 으로 진화
- 이유: 즉시 SSOT 확보 → 장기 5NF 마이그레이션은 별도 단계
- decision_owner: team1 (Frontend)

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
