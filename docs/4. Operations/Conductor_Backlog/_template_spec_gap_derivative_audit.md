---
id: SG-037
title: "기획 공백: 외부 인계 PRD derivative-of frontmatter 미연결 5건"
type: spec_gap
status: PENDING  # PENDING | IN_PROGRESS | DONE (도메인 owner 머지 시 DONE)
owner: conductor  # decision_owner — Wave 1 후속, 도메인 owner 별 분기
created: 2026-05-12
cycle: 6
issue: 309
stream: S10-W
affects_chapter:
  - docs/1. Product/RIVE_Standards.md (frontmatter)
  - docs/1. Product/Game_Rules/Flop_Games.md (frontmatter)
  - docs/1. Product/Game_Rules/Draw.md (frontmatter)
  - docs/1. Product/Game_Rules/Seven_Card_Games.md (frontmatter)
  - docs/1. Product/Game_Rules/Betting_System.md (frontmatter)
protocol: Spec_Gap_Triage
template_kind: derivative_audit  # 본 파일은 `_template_spec_gap*.md` glob 의 audit 변종 — 향후 frontmatter 정합 audit 시 본 형식 재사용
---

# SG-037 — 외부 인계 PRD derivative-of frontmatter 미연결 5건

## 공백 서술

`MEMORY.md` 본문 "주요 문서 위치" 표 직하단 (line 129) 의 SSOT 룰:

> **외부 PRD ↔ 정본 기술 명세 동기화 룰**: `derivative-of: ../<정본>.md` + `if-conflict: derivative-of takes precedence`. 정본 변경 시 PRD 동시 갱신 필수 (룰 20).

이 룰은 `tier: external` 전체에 적용된다. 그러나 Cycle 6 #309 frontmatter audit (2026-05-12, `python tools/doc_discovery.py --tier external`) 결과 8 종 external PRD 중 **5 종이 `derivative-of` 미연결** 상태로 확인됨. 정본 명세가 갱신되어도 외부 인계 PRD 가 stale 됐는지 자동 감지 불가.

## 발견 경위

- 실패 분류: **Type B (기획 공백)** — 룰은 존재하나 5 종 PRD 가 룰 적용 누락
- 트리거: Cycle 5 #286 audit-only close 후속, Cycle 6 #309 (S10-W Wave 1)
- 도구: `python tools/doc_discovery.py --tier external` (read-only)
- 발견 시점: 2026-05-12 (cycle 6 진입 직후)

## 영향받는 챕터 / 구현

### A. 정합 (3 종 — 보강 불필요)

| 외부 PRD | derivative-of | if-conflict 룰 | 상태 |
|----------|---------------|----------------|:----:|
| `docs/1. Product/Command_Center_PRD.md` | `../2. Development/2.4 Command Center/Command_Center_UI/Overview.md` | ✅ 존재 | ✅ PASS |
| `docs/1. Product/Lobby_PRD.md` | `../2. Development/2.1 Frontend/Lobby/Overview.md` | ✅ 존재 | ✅ PASS |
| `docs/1. Product/Back_Office_PRD.md` | `../2. Development/2.2 Backend/Back_Office/Overview.md` | ✅ 존재 | ✅ PASS |

→ Task 의 "외부 PRD 3종 unique pair 검증" 항목은 모두 PASS. 정본 파일 존재 + 1:1 매핑 + if-conflict 룰 모두 확인.

### B. 미연결 (5 종 — derivative-of 부재)

| 외부 PRD | 제안 derivative-of (canonical domain master) | 정본 상태 |
|----------|---------------------------------------------|:--------:|
| `docs/1. Product/Game_Rules/Flop_Games.md` (PRD-GAME-01, BS-06-1X) | `../../2. Development/2.3 Game Engine/Behavioral_Specs/Variants_and_Evaluation.md` (tier: contract) | ✅ active |
| `docs/1. Product/Game_Rules/Draw.md` (BS-06-2X) | `../../2. Development/2.3 Game Engine/Behavioral_Specs/Variants_and_Evaluation.md` (tier: contract) | ✅ active |
| `docs/1. Product/Game_Rules/Seven_Card_Games.md` (BS-06-3X) | `../../2. Development/2.3 Game Engine/Behavioral_Specs/Variants_and_Evaluation.md` (tier: contract) | ✅ active |
| `docs/1. Product/Game_Rules/Betting_System.md` (PRD-GAME-04, BS-06-02/03/06/07) | `../../2. Development/2.3 Game Engine/Behavioral_Specs/Betting_and_Pots.md` (tier: contract) | ✅ active |
| `docs/1. Product/RIVE_Standards.md` (Overlay Graphics 정본 SSOT) | `../2. Development/2.3 Game Engine/APIs/Overlay_Output_Events.md` (legacy-id: API-04) | ✅ active |

> `Behavioral_Specs/Flop_Variants.md`, `Draw_Games.md`, `Stud_Games.md` 는 모두 2026-04-28 deprecated 되어 `Variants_and_Evaluation.md` 도메인 마스터로 redirect 됨. 따라서 derivative-of 는 **deprecated 파일 금지** — domain master 만 지목.

## 결정 방안 후보

| 대안 | 장점 | 단점 | WSOP LIVE 패턴 정렬 |
|------|------|------|---------------------|
| **1. 5 종 모두 derivative-of + if-conflict 추가 (권장)** | KPI 미연결 0건 달성. 정본 변경 → PRD 동시 갱신 강제 (룰 20). | 도메인 owner 5 곳 (team3 Game Engine 4 + team3 Overlay 1) merge 필요. | ✅ SSOT 일관성 |
| 2. RIVE_Standards 를 tier: contract 로 격하 | derivative-of 면제 (자체 SSOT). | RIVE_Standards 는 외부 디자이너/PD 대상 PRD — external 유지가 맞음. | ❌ audience 충돌 |
| 3. Game_Rules 4 종 을 tier: internal 로 변경 | derivative-of 면제. | 외부 인계 대상 — external 유지 필수 (MEMORY.md line 113 SSOT). | ❌ audience 충돌 |

→ **대안 1 채택 권장** (자율 결정 — production 인텐트 + 외부 인계 무결성 우선).

## 결정 (decision_owner 채택 시 기입)

- **채택**: 대안 1 (5 종 모두 frontmatter 보강)
- **이유**: production 출시 프로젝트 (memory `project_intent_production_2026_04_27`) 의 외부 인계 무결성 — derivative-of 룰은 모든 external tier 에 일관 적용되어야 함. tier 격하/변경은 audience 본질 (외부 stakeholder) 과 충돌.
- **영향 챕터 업데이트 PR**: 본 cycle PR (S10-W #309) 의 PR body 에 5 종 patch block 으로 명시 — 도메인 owner (team3) 가 4 종 Game_Rules + 1 종 RIVE_Standards 머지.
- **후속 구현 Backlog 이전**: 없음 (frontmatter only — Implementation 불필요).
- **scope 충돌 사유**: S10-W scope_owns = `_template_spec_gap*.md` only. PRD 직접 편집은 `.claude/hooks/orch_PreToolUse.py` 로 차단되므로 본 SG ticket + PR body 의 patch block 으로 handoff. 도메인 owner (team3 — `2. Development/2.3 Game Engine/` 정본 책임자) merge 권한.

---

## Appendix A — 5 종 도메인 owner 적용 patch (copy-paste ready)

> **적용 방법**: 도메인 owner (team3) 가 본 worktree (예: `C:/claude/ebs` 또는 별도 worktree) 에서 각 PRD 의 frontmatter 에 2 줄 추가 후 commit. `tools/doc_discovery.py --tier external` 로 미연결 0건 확인 후 머지.

### A.1 `docs/1. Product/Game_Rules/Flop_Games.md`

기존 frontmatter 의 `last-updated: 2026-05-04` 직후에 2 줄 추가:

```yaml
derivative-of: ../../2. Development/2.3 Game Engine/Behavioral_Specs/Variants_and_Evaluation.md
if-conflict: derivative-of takes precedence
```

### A.2 `docs/1. Product/Game_Rules/Draw.md`

기존 frontmatter 의 `last-updated: 2026-05-04` 직후에 2 줄 추가:

```yaml
derivative-of: ../../2. Development/2.3 Game Engine/Behavioral_Specs/Variants_and_Evaluation.md
if-conflict: derivative-of takes precedence
```

### A.3 `docs/1. Product/Game_Rules/Seven_Card_Games.md`

기존 frontmatter 의 `last-updated: 2026-05-04` 직후에 2 줄 추가:

```yaml
derivative-of: ../../2. Development/2.3 Game Engine/Behavioral_Specs/Variants_and_Evaluation.md
if-conflict: derivative-of takes precedence
```

### A.4 `docs/1. Product/Game_Rules/Betting_System.md`

기존 frontmatter 의 `last-updated: 2026-05-04` 직후에 2 줄 추가:

```yaml
derivative-of: ../../2. Development/2.3 Game Engine/Behavioral_Specs/Betting_and_Pots.md
if-conflict: derivative-of takes precedence
```

### A.5 `docs/1. Product/RIVE_Standards.md`

기존 frontmatter 의 `confluence-url:` 직후에 2 줄 추가:

```yaml
derivative-of: ../2. Development/2.3 Game Engine/APIs/Overlay_Output_Events.md
if-conflict: derivative-of takes precedence
```

> **경로 주의**: `Game_Rules/` 4 종은 `docs/1. Product/Game_Rules/` 한 단계 더 깊으므로 `../../` (상위 2 단계). `RIVE_Standards.md` 는 `docs/1. Product/` 직접 위치이므로 `../` (상위 1 단계).

---

## Appendix B — Audit Re-run 검증 명령

도메인 owner 가 5 종 patch 머지 후, 동일 명령으로 KPI 검증:

```bash
cd <ebs-worktree>
python tools/doc_discovery.py --tier external 2>&1 | tail -20
```

**기대 결과**: 8 종 external PRD 모두 `← derivative-of: <path>` 출력 (미연결 0건). 미달 시 본 SG-037 재오픈.

---

## Appendix C — Audit Protocol (재사용 템플릿)

본 SG 는 향후 frontmatter audit 시 재사용 가능한 골격을 제공한다:

| 단계 | 명령 / 동작 | 검증 |
|------|------------|------|
| 1. Scan | `python tools/doc_discovery.py --tier external` | 8 종 external 모두 derivative-of 출력 확인 |
| 2. Pair verify | 각 derivative-of 경로 → 정본 파일 존재 + tier=contract/internal 확인 | deprecated 파일 지목 금지 |
| 3. Unique pair | 동일 derivative-of 를 2 개 이상 PRD 가 가리키는지 grep | 1:1 매핑 (cross-cutting 시 related-docs 사용) |
| 4. if-conflict | `grep "if-conflict: derivative-of takes precedence"` 모든 external PRD 에 존재 | 룰 부재 시 추가 |
| 5. Domain owner PR | scope_owns 가 PRD 미포함이면 본 SG ticket + PR body patch block 으로 handoff | 도메인 owner merge |

> **재사용 시**: 본 파일을 `_template_spec_gap_derivative_audit_<YYYY-MM-DD>.md` 로 복제 후 ID/날짜/findings 갱신.

---

## 변경 이력

| 날짜 | 작성자 | 변경 |
|------|--------|------|
| 2026-05-12 | S10-W (Cycle 6 #309) | 최초 작성 — derivative-of audit 결과 + 5 종 handoff patch |
