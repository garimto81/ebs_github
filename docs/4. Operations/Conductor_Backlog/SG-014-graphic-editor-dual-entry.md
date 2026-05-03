---
id: SG-014
title: "Graphic Editor 진입점 이중화 (헤더 vs Settings 탭)"
type: spec_gap
sub_type: ia_overlap
status: SUPERSEDED  # 회의 D3 (GE 제거) 결정으로 전체 GE 폐기
created: 2026-04-21
promoted: 2026-04-26
superseded_by: B-209 (회의 D3 GE 제거) + SG-021 (manifest 재설계)
owner: conductor
affects_chapter:
  - docs/2. Development/2.1 Frontend/Lobby/UI.md (헤더 [Graphic Editor] 버튼)
  - docs/2. Development/2.1 Frontend/Settings/Graphics.md (Graphics 탭)
  - docs/1. Product/Foundation.md §5.3 (Rive Manager — 새 SSOT)
protocol: Spec_Gap_Triage §2 Type C (모순)
related:
  - docs/4. Operations/Critic_Reports/Lobby_IA_Sidebar_2026-04-21.md §4.3
  - docs/4. Operations/Critic_Reports/Meeting_Analysis_2026_04_22.md D3
  - B-209 (GE 제거 결정 전파)
reimplementability: N/A
reimplementability_checked: 2026-05-03
reimplementability_notes: "SUPERSEDED — D3 회의 GE 제거 결정으로 전체 폐기"
---
# SG-014 — Graphic Editor 진입점 이중화

## 공백 서술

Lobby 헤더 `[Graphic Editor]` 버튼과 Settings/Graphics 탭이 **둘 다 그래픽 관련 진입점** 으로 존재. 사용자에게 "에셋 편집" vs "런타임 그래픽 설정" 구분이 모호.

## 2026-04-22 SUPERSEDED — 회의 D3 GE 제거 결정

회의록 분석 (Meeting_Analysis_2026_04_22.md) D3 결정으로 사내 Graphic Editor 자체가 제거됨. 따라서 진입점 이중화 문제는 자동 해소 (GE 진입점 자체가 사라짐).

**대체 SSOT**:
- `docs/1. Product/Foundation.md §5.3 Rive Manager` (D3, 2026-04-22 신설)
- 아트 디자이너가 외부 도구로 `.riv` 파일 제작 → Rive Manager 에서 업로드/검증/활성화
- Settings/Graphics 탭은 **활성 스킨 선택 + 화면 요소 배치** 만 담당 (편집 X)

## 후속 작업

- [x] Foundation §5.3 Rive Manager 신설 (커밋 d6e28a6, d07289f)
- [x] B-209 GE 제거 결정 5 지점 전파 (커밋 57fce5b)
- [ ] team1: Lobby 헤더 `[Graphic Editor]` 버튼 제거 → `[Rive Manager]` 또는 Settings 진입
- [ ] team1: Settings/Graphics.md 텍스트 정비 (편집 기능 제거, 배치/선택만 명시)
- [ ] SG-004 .gfskin 포맷 → SG-021 Rive 내장 메타데이터 재설계로 이전

## 관련 SG

- SG-004 SUPERSEDED (`.gfskin` ZIP 포맷 → Rive 내장 메타데이터)
- SG-021 (신설) — Rive 파일 메타데이터 schema
- B-209 — GE 제거 결정 전파
