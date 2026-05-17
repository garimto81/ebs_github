---
id: SG-renewal-ui-31
title: "Architecture_Generations.md → 4 컴포넌트 Gen 3 마이그레이션 cascade"
type: spec_gap_architecture
status: OPEN
owner: conductor
created: 2026-05-17
priority: P2
scope: architecture
mirror: none
confluence-sync: none
affects_files:
  - team1-frontend/** (Riverpod + Feature-based)
  - team2-backend/** (FastAPI 이미 Gen 3 친화)
  - team3-engine/** (Pure Dart 이미 Gen 3 가능)
  - team4-cc/** (Orchestrator pattern 명시 — 가장 우선)
related_sg: [SG-renewal-ui-29, SG-renewal-ui-30]
prd_refs:
  - Foundation Ch.4 Scene 4 (Gen 3 DDD/CQRS target, v5.0)
  - docs/2. Development/2.5 Shared/Architecture_Generations.md (v1.0.0 신규)
pokergfx_refs:
  - archive/.../complete.md line 442-448 (3 generation 공존)
  - archive/.../complete.md line 575-641 (Login CQRS 예시)
parent_plan: ~/.claude/plans/decision-report-v5-ultrathink-rewrite.md
---

# SG-renewal-ui-31 — Gen 3 마이그레이션 cascade

## 공백 서술

신규 doc `Architecture_Generations.md` v1.0.0 = EBS target = Gen 3 (DDD/CQRS). 본 SG = 4 컴포넌트 점진 마이그레이션 계획.

## 권장 조치

### Step 1 — team4-cc 우선 (Orchestrator pattern 명시화)

- Features/{HandFlow/PlayerEdit/CardSelection 등}/ 구조 도입
- Command/Query 분리
- Validator + Handler 패턴

### Step 2 — team1 Lobby 점진

- 이미 Riverpod 기반 → Gen 3 친화 (큰 변경 없음)
- Settings 79 필드를 Feature 별 분리

### Step 3 — team2/team3 (이미 Gen 3 친화)

- FastAPI + Pure Dart = native Gen 3
- 정합 검증만

## 수락 기준

- [ ] 4 컴포넌트 모두 Feature 디렉토리 패턴
- [ ] God Class 회피 (큰 클래스 분해)
- [ ] PRD Foundation Ch.4 Scene 4 정합

## 위상

- Type: D (architecture drift — implicit vs explicit)
- Scope: architecture cascade
- Branch: `work/team4/gen3-orchestrator` (우선) + 별도 cycle
- Estimated diff: ~variable (점진)
- Risk: 중간 — 마이그레이션 비용
- Dependency: SG-29/30 선행
