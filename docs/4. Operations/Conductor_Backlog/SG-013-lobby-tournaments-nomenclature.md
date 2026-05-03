---
id: SG-013
title: "Lobby 사이드바 \"lobby\" vs \"Tournaments\" 용어 충돌"
type: spec_gap
sub_type: nomenclature
status: DONE
resolved: 2026-05-03
resolved-by: conductor (Mode A 자율 — 원칙 1 정렬 권한, V9.4 정합)
owner: conductor
created: 2026-04-21
promoted: 2026-04-26
affects_chapter:
  - docs/2. Development/2.1 Frontend/Lobby/UI.md §공통 레이아웃
  - docs/2. Development/2.1 Frontend/Lobby/Overview.md
  - docs/1. Product/Foundation.md §5.1 (Lobby 정의)
protocol: Spec_Gap_Triage §2 Type C (원칙 1 위반 가능성)
related:
  - docs/4. Operations/Critic_Reports/Lobby_IA_Sidebar_2026-04-21.md §4.1
  - SG-012 (sibling — Lobby IA)
last-updated: 2026-05-03
reimplementability: PASS
reimplementability_checked: 2026-05-03
reimplementability_notes: "Conductor 자율 결정 완료 (2026-05-03). 대안 1 채택: 섹션명 = Tournaments (영문, 원칙 1 정렬), 앱명 = Lobby (영문) / 로비 (한글 UI). 의미 레이어 분리 + WSOP LIVE Confluence 일치. 외부 개발팀 인계 가능 SSOT 확정"
---
# SG-013 — Lobby 사이드바 "lobby" vs "Tournaments" 용어 충돌

## 공백 서술

"Lobby" 가 **앱 전체 명칭** (Foundation §5.1) 이면서 사이드바 첫 번째 **섹션명** 으로 사용되면, Breadcrumb (`EBS > Series > Event`) 와 사이드바 (`Lobby > ...`) 의 의미 레이어가 겹친다.

WSOP LIVE Confluence 원어는 "Tournaments". EBS 는 원칙 1 (WSOP LIVE 정렬) 적용 대상이므로 섹션명을 "Tournaments" 로 정렬해야 한다. 정렬하지 않을 경우 `Why:` justify 필수.

## 발견 경위

- 2026-04-21 critic 보고 — 사용자 5탭 제안 중 "lobby" 라벨 분석
- Critic_Reports/Lobby_IA_Sidebar_2026-04-21.md §4.1 에서 용어 충돌 + 원칙 1 위반 잠재성 식별

## 영향받는 챕터 / 구현

- `UI.md §공통 레이아웃` ASCII line 401: `■ Tournaments` (이미 영문)
- `Overview.md`: "lobby" 한글 표기 ↔ 사이드바 영문 표기 불일치
- `team1-frontend/lib/features/lobby/`: app 명칭 vs route 명 정합

## 결정 방안 후보

| 대안 | 장점 | 단점 | WSOP LIVE 패턴 정렬 |
|------|------|------|---------------------|
| 1. 섹션명 = "Tournaments" 고정, 앱명 = "Lobby" 별도 | 원칙 1 만족, 의미 레이어 분리 | 한글 사용자 학습 곡선 | ✅ 일치 |
| 2. 섹션명 = "Lobby" 변경, "Tournaments" 폐기 | 한글 사용자 즉시 이해 | 원칙 1 위반 | ✗ 위반 (justify 필수) |
| 3. 섹션명 = "Tournaments / 토너먼트" 양국어 | 양립 | 라벨 길이 ↑ | △ 부분 |

## 결정 (Conductor Mode A 자율 — 2026-05-03 채택)

> ✅ **DONE** — V9.4 AI-Centric Mode A 자율 진행. 사용자 도메인 질문 0회 (원칙 1 정렬 권한 = conductor 자체).

**채택**: 대안 1 — 섹션명 "Tournaments" (영문 고정), 앱명 "Lobby" (영문) / "로비" (한글 UI label)

**이유**:
- 원칙 1 (WSOP LIVE Confluence 정렬) 정합 — Confluence 원어 "Tournaments" 일치
- 의미 레이어 분리: 앱 전체 명칭 vs 사이드바 섹션명 구분 명확
- 한글 사용자 학습 곡선 부담 = 앱명 "로비" 한글 표기로 완화

**영향 (publisher cascade 권고)**:
- `UI.md §공통 레이아웃`: line 401 `■ Tournaments` 이미 정합 (변경 0)
- `Overview.md`: 한글 "로비" (앱명) ↔ 영문 "Tournaments" (섹션명) 컨벤션 명시
- `Foundation.md §5.1`: "Lobby (앱명) ≠ Tournaments (섹션명)" cross-ref 보강
- `BS_Overview §1`: "앱명 = 로비/Lobby, 섹션명 = Tournaments" 컨벤션 등재

## 후속 작업

- [ ] conductor: Foundation §5.1 에 "Lobby (앱명) ≠ Tournaments (섹션명)" 명시
- [ ] team1: UI.md `■ Tournaments` 유지 + Overview.md 한글 표기 정비
- [ ] team1: 앱명 한글 "로비", 섹션명 영문 "Tournaments" 컨벤션 BS_Overview §1 추가

## 관련 SG

- SG-012 — Lobby 사이드바 SSOT
- 원칙 1 (CLAUDE.md §"프로젝트 설계 원칙")
