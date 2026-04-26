---
id: SG-018
title: "5NF 메타모델 테이블 부재 (nav_sections / nav_items / report_templates / 외 6종)"
type: spec_gap
sub_type: data_model
status: PENDING
owner: team2  # decision_owner (DB)
created: 2026-04-21
promoted: 2026-04-26
affects_chapter:
  - docs/2. Development/2.2 Backend/Database/Schema.md
  - docs/2. Development/2.1 Frontend/Lobby/UI.md (nav_sections 사용처)
  - docs/2. Development/2.1 Frontend/Reports/Overview.md (report_templates 사용처)
protocol: Spec_Gap_Triage §2 Type B
related:
  - docs/4. Operations/Critic_Reports/Lobby_IA_Sidebar_2026-04-21.md §5.2-5.3
  - SG-012 (Lobby 사이드바 SSOT — 본 SG 가 진화형)
  - SG-016 (Hand History 섹션 — nav_sections 추가 행)
---

# SG-018 — 5NF 메타모델 테이블 부재

## 공백 서술

Lobby 사이드바, Reports 템플릿, Skin 모드, Settings 카테고리, Integration 프로바이더, Game Rules, Roles+Permissions 등 **메타데이터 성격 정보** 가 코드에 hardcoded 되어 있다. 5NF 관점에서 메타모델 테이블 8종이 누락.

## 발견 경위

- 2026-04-21 critic 보고 §5.2-5.3 — 사용자 "5정규화 법칙" 요청에 따라 분석
- 8종 테이블 부재 식별: `nav_sections`, `nav_items`, `report_templates`, `skin_modes`, `setting_categories`, `integration_providers`, `game_rules`, `roles+permissions`

## 영향받는 챕터 / 구현

- `Schema.md`: 8종 테이블 신설 필요
- `Lobby/UI.md`: 사이드바 hardcoded → `nav_sections` 참조로 전환
- `Reports/Overview.md`: 템플릿 hardcoded → `report_templates` 참조
- `team2-backend/src/db/init.sql`: 8종 CREATE TABLE 추가
- `team2-backend/src/db/enums.py`: 메타데이터 enum 정합성

## 결정 방안 후보

| 대안 | 장점 | 단점 | WSOP LIVE 패턴 정렬 |
|------|------|------|---------------------|
| 1. 8종 메타모델 테이블 일괄 신설 | 5NF 만족, 동적 확장 가능 | 마이그레이션 비용 大 | △ WSOP LIVE 일부 일치 |
| 2. 핵심 3종만 (nav_sections/report_templates/game_rules) | 점진적, 위험 ↓ | 5종은 미해결 | △ 부분 |
| 3. 코드 hardcoded 유지, 문서만 mirror | 즉시 가능 | drift 영구 + 5NF 위반 | ✗ |

## 결정 (decision_owner team2 판정 시 기입)

- **default 권고**: 대안 2 (핵심 3종 우선) → 단계적 확장
- 이유: 마이그레이션 비용 균형 + 동적 섹션/템플릿/룰의 우선순위 ↑
- decision_owner: team2

## 후속 작업

- [ ] team2: Schema.md 에 3종 테이블 (nav_sections / report_templates / game_rules) 추가
- [ ] team2: init.sql + Alembic migration 신설
- [ ] team2: 5종 잔여 (nav_items / skin_modes / setting_categories / integration_providers / roles+permissions) 후속 SG 분리
- [ ] team1: UI.md / Reports/Overview.md hardcoded 참조 → DB 참조 전환
- [ ] conductor: 5NF 메타모델 사용 가이드 BS_Overview 추가

## 관련 SG

- SG-012 — Lobby 사이드바 SSOT (본 SG 가 진화형)
- SG-016 — Hand History 섹션 (nav_sections 추가 행)
