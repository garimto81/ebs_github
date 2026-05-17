---
id: SG-renewal-ui-26
title: "RIVE_Standards ConfigurationPreset 99+ 매핑 reference 작성"
type: spec_gap_reference
status: OPEN
owner: conductor
created: 2026-05-17
priority: P2
scope: reference
mirror: none
confluence-sync: none
affects_files:
  - docs/1. Product/RIVE_Standards.md (Ch.22.5)
related_sg: [SG-renewal-ui-28]
prd_refs:
  - RIVE_Standards.md Ch.22.5 (ConfigurationPreset 매핑, v0.9 신규)
pokergfx_refs:
  - archive/.../complete.md line 2193-2287 (ConfigurationPreset 99+ fields)
parent_plan: ~/.claude/plans/decision-report-v5-ultrathink-rewrite.md
---

# SG-renewal-ui-26 — ConfigurationPreset 매핑 확장

## 공백 서술

RIVE_Standards v0.9 Ch.22.5 가 ConfigurationPreset 99+ fields 의 **7 카테고리 매핑** 명시. 그러나 통계 + 칩 정밀도 + 통화 + 로고 매핑 (총 26 fields) 은 1차 골격만. 정밀 매핑 확장 필요.

## 권장 조치

Ch.22.5 의 4 sub-section 보강:
- 22.5.4 통계 설정 11 fields 매핑
- 22.5.5 칩 표시 정밀도 8 fields 매핑
- 22.5.6 통화/금액 4 fields 매핑
- 22.5.7 로고 에셋 3 fields 매핑

## 수락 기준

- [ ] 99+ fields 모두 Rive 변수 매핑 명시
- [ ] Brand Pack vs Rive 분담 명확
- [ ] 외부 디자이너 인계용 reference 완성

## 위상

- Type: B (PRD 골격 + 정밀 확장)
- Scope: reference document
- Branch: `work/conductor/rive-config-mapping`
- Estimated diff: ~100 줄
- Risk: 매우 낮음
- Dependency: 없음
