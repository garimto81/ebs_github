---
title: "Product 폴더 명명 통일 + Confluence↔로컬 정합 Gap Analysis (Cycle 10)"
status: EXECUTED
status-history:
  - "2026-05-12 PROPOSED (Cycle 10, issue #364)"
  - "2026-05-12 EXECUTED Wave 2.1 (PR #367 — 3 파일 git mv + 283 refs cascade, commit dbc519bf)"
  - "2026-05-12 EXECUTED Wave 2.2 (S10-W cycle-12 — 잔존 30 refs / 17 files 정합 보완, 본 보고서 EXECUTED 갱신)"
owner: stream:S10-A (Gap Analysis)
tier: internal
last-updated: 2026-05-12
cycle: 10
issue: "#364"
trigger: "사용자 명시 4축 분석 → Wave 2 (S10-W rename + S11 broker subscribe) trigger"
note: "본문은 PROPOSED 시점 분석 history 보존 — Lobby_PRD.md / Back_Office_PRD.md / Command_Center_PRD.md 잔존은 의도된 역사 기록"
related-docs:
  - ../Spec_Gap_Registry.md
  - ../../1. Product/Lobby.md
  - ../../1. Product/Back_Office.md
  - ../../1. Product/Command_Center.md
  - ../../_generated/confluence-mirror-matrix.md
---

# Product 폴더 명명 통일 + Confluence↔로컬 정합 Gap Analysis

> **Cycle 10 / S10-A Gap Analysis Stream** — 2026-05-12

## 0. Executive Summary (TL;DR)

| 항목 | 수치 |
|------|:----:|
| Rename 대상 | **3 파일** (`Lobby_PRD.md`, `Back_Office_PRD.md`, `Command_Center_PRD.md`) |
| 영향 references | **195 occurrences** / **61 files** (사용자 명시 181 → +14, Cycle 7~9 머지 영향) |
| Confluence page_id (5종) | 모두 frontmatter 기록 + `confluence-mirror-matrix.md` 매핑 완료 |
| frontmatter title vs filename | **3개 mismatch** (filename 에만 `_PRD` 접미사) |
| derivative-of cascade 영향 | **3 PRD → 3 정본 명세** (단방향, cascade 안전) |
| Open PR 충돌 위험 | **LOW** (open PR 1건 #363 / `_PRD` 파일 미수정) |
| Wave 2 trigger 준비도 | **READY** (S10-W rename + S11 broker subscribe) |

**판정**: **GO** — rename 즉시 실행 가능. 충돌 위험 최저, derivative-of cascade 안전, frontmatter title 은 이미 `_PRD` 없음 (filename 만 동기화 필요).

---

## 1. Rename 전후 비교

```
[현재 상태]                                   [목표 상태]
docs/1. Product/                              docs/1. Product/
├── Foundation.md            (정합)            ├── Foundation.md
├── Lobby_PRD.md             ★ rename         ├── Lobby.md
├── Back_Office_PRD.md       ★ rename         ├── Back_Office.md
├── Command_Center_PRD.md    ★ rename         ├── Command_Center.md
├── RIVE_Standards.md        (정합)            ├── RIVE_Standards.md
├── Product_SSOT_Policy.md   (보조 문서)       ├── Product_SSOT_Policy.md
├── 1. Product.md            (인덱스)          ├── 1. Product.md
├── Game_Rules/              (4종, 영향 X)     ├── Game_Rules/
├── References/              (영향 X)          ├── References/
└── images/, archive/, visual/                 └── images/, archive/, visual/
```

**핵심 관찰**: frontmatter `title:` 은 이미 짧은 이름. filename 만 따라가면 4-way 정합 (filename ↔ frontmatter title ↔ 본문 H1 ↔ Confluence page title).

| 파일 | frontmatter title (현재) | 일치성 |
|------|--------------------------|:------:|
| `Lobby_PRD.md` | `"EBS Lobby — 5 화면 시퀀스 + WSOP LIVE 정보 허브"` | filename 만 mismatch |
| `Back_Office_PRD.md` | `"Back Office — 보이지 않는 뼈대"` | filename 만 mismatch |
| `Command_Center_PRD.md` | `"Command Center — 운영자가 머무는 조종석 (v4.0)"` | filename 만 mismatch |

---

## 2. 분석 1 — 영향 매트릭스 (195 refs / 61 files)

### 2.1 Hotspot Top 10 (참조 횟수 기준)

| 순위 | 파일 | refs | 카테고리 |
|:---:|------|:---:|---------|
| 1 | `docs/4. Operations/CC_PRD_Renewal_Plan_2026_05_06.md` | 26 | 운영 |
| 2 | `docs/4. Operations/Doc_Discovery_Failure_Critic_2026_05_06.md` | 22 | 운영 (사례) |
| 3 | `docs/2. Development/2.5 Shared/Stream_Entry_Guide.md` | 10 | 거버넌스 SSOT |
| 4 | `docs/2. Development/2.1 Frontend/Lobby/Backlog/AUDIT-S2-lobby-v3-cascade-2026-05-08.md` | 8 | Backlog |
| 5 | `docs/4. Operations/team_assignment_v10_3.yaml` | 7 | ⚠️ **meta_files_blocked** |
| 6 | `docs/4. Operations/Plans/Planning_Prototype_Gap_Analysis_2026-05-09.md` | 7 | 계획 |
| 7 | `docs/4. Operations/Causality_Dashboard.md` | 6 | 거버넌스 |
| 8 | `docs/4. Operations/Conductor_Backlog/SG-033-ebs-mission-redefinition.md` | 6 | Backlog |
| 9 | `docs/_generated/full-index.md` | 5 | ⚙️ **자동 생성** (재생성 필요) |
| 10 | `docs/4. Operations/orchestration/2026-05-08-consistency-audit/classification.md` | 5 | 감사 |

### 2.2 카테고리별 분포

```
영향 파일 61 개 분포 (195 refs)
+----------------------------------+
|  운영 (Operations)        21 파일 | ████████████████████  (≈55% refs)
|  개발 명세 (Development)  29 파일 | ██████████████████████ (≈32% refs)
|  Product 본문              4 파일 | ████                    (≈4% refs)
|  도구 (tools/)             5 파일 | ████                    (≈5% refs)
|  메타 (.github, archive)   2 파일 | ██                      (≈4% refs)
+----------------------------------+
```

### 2.3 변환 규칙 (sed 패턴, dry-run 권장)

```
# 1. md/yaml/py/json/txt 본문 참조
s|Lobby_PRD\.md|Lobby.md|g
s|Back_Office_PRD\.md|Back_Office.md|g
s|Command_Center_PRD\.md|Command_Center.md|g

# 2. backtick 참조 / link text
s|`Lobby_PRD`|`Lobby`|g
s|`Back_Office_PRD`|`Back_Office`|g
s|`Command_Center_PRD`|`Command_Center`|g

# 3. derivative-of 역방향 (정본 → PRD 참조 시 — 현재 ZERO)
# 정본 명세는 PRD 를 참조하지 않음. cascade 단방향 검증 완료.
```

### 2.4 차단 / 자동 처리 분류

| 파일 | 처리 |
|------|------|
| `docs/4. Operations/team_assignment_v10_3.yaml` (7 refs) | ⚠️ `meta_files_blocked` — S10-W 가 orchestrator scope 통해 우회 갱신 필요 |
| `docs/_generated/full-index.md` (5 refs) | ⚙️ 자동 재생성 — rename 후 `tools/doc_discovery.py --regenerate-index` |
| `docs/_generated/confluence-mirror-matrix.md` (3 refs) | ⚙️ 자동 재생성 — Confluence sync 도구 재실행 |
| `.github/CODEOWNERS` (3 refs) | 수동 1줄 갱신 |
| `tools/doc_discovery.py` (1 ref) | 코드 상수 1줄 |
| `tools/ai_track/cia/self_test.py` (2 refs) + `fixtures/cc_visual_change.json` (1 ref) | 테스트 fixture — sed 동시 처리 |
| `.doc-discovery-orphans.txt` (3 refs) | 빌드 산출물 — `.gitignore` 검토 별건 |
| 나머지 53 파일 (≈164 refs) | sed 일괄 처리 |

---

## 3. 분석 2 — Confluence ↔ 로컬 정합 표

```
Confluence Space: WSOPLive
Parent: 3811344758 (1. Product 인덱스)
                |
                +-- 3625189547  Foundation
                +-- 3811672228  Lobby
                +-- 3811967073  Back Office
                +-- 3811901603  Command Center
                +-- 3816784235  RIVE Standards
                +-- 3811410570  Game_Rules/Betting_System
                +-- 3810853753  Game_Rules/Draw
                +-- 3811443642  Game_Rules/Flop_Games
                +-- 3811771012  Game_Rules/Seven_Card_Games
                +-- 3818848697  Product_SSOT_Policy
                +-- 3819078185  References/PokerGFX_Reference
                +-- 3819274864  References/WSOP-Production-Structure-Analysis
```

### 3.1 5 종 mismatch 표

| Page ID | Confluence Title (추정/현행) | 로컬 filename (현재) | frontmatter `title:` | 로컬 H1 | 정합? |
|:-------:|------------------------------|---------------------|---------------------|---------|:----:|
| 3625189547 | Foundation | `Foundation.md` | Foundation 계열 | 동일 | ✅ |
| **3811672228** | **Lobby** | `Lobby_PRD.md` | `EBS Lobby — 5 화면 시퀀스...` | 본문 H1 동일 | ⚠️ filename 만 mismatch |
| **3811967073** | **Back Office** | `Back_Office_PRD.md` | `Back Office — 보이지 않는 뼈대` | 본문 H1 동일 | ⚠️ filename 만 mismatch |
| **3811901603** | **Command Center** | `Command_Center_PRD.md` | `Command Center — 운영자가 머무는 조종석 (v4.0)` | 본문 H1 동일 | ⚠️ filename 만 mismatch |
| 3816784235 | RIVE Standards | `RIVE_Standards.md` | RIVE_Standards 계열 | 동일 | ✅ |

### 3.2 정합성 매트릭스 (4-way)

```
                filename ─── frontmatter title ─── 본문 H1 ─── Confluence title
                    |              |                   |             |
Foundation         OK             OK                  OK            OK     ✅
Lobby           MISMATCH          OK (이미 "Lobby")    OK            OK     ⚠️ → rename
Back_Office     MISMATCH          OK (이미 "Back...")  OK            OK     ⚠️ → rename
Command_Center  MISMATCH          OK (이미 "Command")  OK            OK     ⚠️ → rename
RIVE_Standards     OK             OK                  OK            OK     ✅
```

**결론**: rename 은 filename 만 frontmatter title 쪽으로 끌어당기는 작업. 본문 H1 / Confluence sync 변경 불필요.

### 3.3 Confluence sync 영향

| 항목 | 영향 |
|------|------|
| `confluence-page-id` frontmatter | 변경 X (page ID 고정) |
| Confluence 측 page title | 변경 X (현재 이미 짧은 이름) |
| `confluence-mirror-matrix.md` filename 컬럼 | 재생성 필요 (rename 후 sync 도구 재실행) |
| md2confluence 업로드 동작 | 영향 X (page_id 기반 PUT) |

---

## 4. 분석 3 — derivative-of Cascade

### 4.1 현행 cascade 방향

```
docs/1. Product/Lobby_PRD.md
  └─ derivative-of: ../2. Development/2.1 Frontend/Lobby/Overview.md
     ↑ 정본 명세 (1273 줄) — 변경 시 PRD 동시 갱신 필수

docs/1. Product/Back_Office_PRD.md
  └─ derivative-of: ../2. Development/2.2 Backend/Back_Office/Overview.md
     ↑ 정본 명세

docs/1. Product/Command_Center_PRD.md
  └─ derivative-of: ../2. Development/2.4 Command Center/Command_Center_UI/Overview.md
     ↑ 정본 명세 — D7 §5.1
```

### 4.2 cascade 안전 검증

```
[질문] 정본 명세가 PRD 를 역참조하는가?
[Grep] derivative-of:.*\.(Lobby_PRD|Back_Office_PRD|Command_Center_PRD)
[결과] No matches found ✅
[해석] cascade 단방향 (PRD → 정본). rename 영향 ZERO.
```

### 4.3 rename 후 frontmatter

```
변경 전:                                       변경 후:
  Lobby_PRD.md frontmatter                     Lobby.md frontmatter
  derivative-of: ../2. Development/...         derivative-of: ../2. Development/... (동일)
```

frontmatter 내부 `derivative-of:` 값은 정본 경로를 가리키므로 PRD 파일명 변경과 무관.

### 4.4 본문 내 PRD 상호참조 (sister-link)

`Command_Center_PRD.md` line 17:
```yaml
related-docs:
  - Lobby_PRD.md (디자인 톤 SSOT — Q2)
```

→ sed 패턴 `Lobby_PRD\.md` → `Lobby.md` 일괄 적용으로 자동 해소.

---

## 5. 분석 4 — Open PR 충돌 위험

### 5.1 현재 open PR 전수 조사

```
$ gh pr list --state open --limit 50
PR #363  work/s10-w/2026-05-12-rive-pivot
         "docs(s10-w/cycle-8): RIVE Standards v0.7.0 architecture pivot — 4 영역 갱신"
         updated: 2026-05-12T10:53:18Z
```

### 5.2 충돌 매트릭스

| Open PR | _PRD 파일 수정? | 충돌 위험 | 비고 |
|:-------:|:---------------:|:--------:|------|
| #363 (S10-W RIVE pivot) | ❌ (RIVE_Standards.md 만) | **LOW** | rename 대상 3 파일과 무관 |

### 5.3 충돌 시점 분석

```
  T0 ───────────────────────────► (현재, Cycle 10 시작)
                  │
                  ├── #363 open (RIVE Standards) — 충돌 ZERO
                  │
                  └── 본 보고서 PR (Reports/ 신규) — 충돌 ZERO

  T+rename ─────────────────────► (Wave 2 S10-W 실행 시점)
                  │
                  ├── 만약 #363 머지 후 rename → 안전
                  └── 만약 #363 머지 전 rename → 안전 (touch 파일 disjoint)
```

**결론**: rename 시점은 **임의 선택 가능**. blocker 없음.

### 5.4 잠재적 신규 PR 위험 (rename 실행 직전 24h)

| 위험 시나리오 | 확률 | 대응 |
|---------------|:----:|------|
| 다른 stream 이 `_PRD` 파일 본문 수정 PR 오픈 | 낮음 (Cycle 10 trigger 후 stream lock) | rename PR 우선 머지 |
| 자동 도구가 `_PRD` 파일 갱신 (md2confluence sync) | 중간 | rename PR 머지 직후 sync 도구 1회 재실행 |
| Foundation cascade 가 PRD 본문 갱신 (#363 같은 패턴) | 낮음 | rename 후 sister-link 점검 (자동) |

---

## 6. Migration Strategy (Wave 2)

### 6.1 실행 순서 (S10-W 담당)

```
[Phase 1] 준비 (1 commit)
  ├─ git mv Lobby_PRD.md → Lobby.md
  ├─ git mv Back_Office_PRD.md → Back_Office.md
  └─ git mv Command_Center_PRD.md → Command_Center.md

[Phase 2] sed 일괄 치환 (1 commit, 53~58 파일)
  ├─ 본문 ".md" 참조 (s|Lobby_PRD\.md|Lobby.md|g)
  ├─ backtick 참조 (s|`Lobby_PRD`|`Lobby`|g)
  └─ ⚠️ meta_files_blocked 제외: team_assignment_v10_3.yaml

[Phase 3] 자동 생성 파일 재빌드 (1 commit)
  ├─ tools/doc_discovery.py --regenerate-index
  ├─ confluence-mirror-matrix 재생성
  └─ .doc-discovery-orphans.txt 재생성

[Phase 4] meta 파일 갱신 (orchestrator scope — S0/S11 협업)
  └─ docs/4. Operations/team_assignment_v10_3.yaml (7 refs)

[Phase 5] 검증
  ├─ grep -r "Lobby_PRD\|Back_Office_PRD\|Command_Center_PRD" → 0 hits 확인
  ├─ 자동 인덱스 빌드 PASS
  └─ md2confluence dry-run PASS
```

### 6.2 Stream 분담

```
S10-A (본 stream)  ─ 본 보고서 + broker publish (pipeline:gap-classified)
                              │
                              ▼
S10-W (Wave 2 신규) ─ Phase 1~3 + Phase 5 검증
                              │
                              ▼
S11 (broker)        ─ pipeline:gap-classified subscribe → Phase 4 (orchestrator scope)
```

### 6.3 Rollback 전략

```
git revert <rename-commit>                    → filename 복원
sed reverse 패턴 일괄 실행                     → 참조 원복
tools/doc_discovery.py --regenerate-index     → 인덱스 재생성
```

3 commit 분리로 단계별 revert 가능.

---

## 7. Decision Points (S10-A 자율 판정)

| # | 결정 항목 | S10-A 판정 | 근거 |
|:-:|----------|-----------|------|
| 1 | rename 실행 여부 | **GO** | 충돌 위험 LOW + cascade 안전 + frontmatter title 이미 정합 |
| 2 | rename 시점 | **즉시** (Wave 2) | #363 와 disjoint, blocker 없음 |
| 3 | meta 파일 처리 | **S11 broker → orchestrator scope** | S10-A/S10-W 모두 `meta_files_blocked` |
| 4 | Confluence 측 변경 | **불필요** | page_id 고정 + page title 이미 짧음 |
| 5 | derivative-of 역방향 점검 | **PASS** | Grep 결과 No matches |
| 6 | 자동 생성 파일 재빌드 | **Phase 3 별도 commit** | 추적성 + revert 분리 |
| 7 | `.doc-discovery-orphans.txt` 처리 | **별건 Backlog** | rename 과 무관, `.gitignore` 검토 |

---

## 8. Spec_Gap_Registry 등재 (S10-A scope_owns)

```
SG-037 — Product 폴더 명명 일관성 부재 (filename ≠ frontmatter title)
  · Type: Type C (기획 모순) — filename 규약 미명시
  · Severity: MEDIUM
  · Origin: 외부 인계 PRD 3 종 filename 에만 `_PRD` 접미사
  · Resolution Plan: Wave 2 (S10-W) rename 실행
  · Cascade: 195 refs / 61 files (sed 일괄)
  · Status: CLASSIFIED → 본 보고서 + S10-W trigger 후 IN_PROGRESS
```

→ 별도 commit 으로 `Spec_Gap_Registry.md` 에 SG-037 추가 (S10-A scope_owns).

---

## 9. broker Publish 명세

```
Topic:   pipeline:gap-classified
Payload: {
  "stream": "S10-A",
  "cycle": 10,
  "gap_id": "SG-037",
  "title": "Product 폴더 명명 통일 (_PRD 접미사 제거)",
  "severity": "MEDIUM",
  "type": "C",
  "rename_targets": [
    "docs/1. Product/Lobby_PRD.md → Lobby.md",
    "docs/1. Product/Back_Office_PRD.md → Back_Office.md",
    "docs/1. Product/Command_Center_PRD.md → Command_Center.md"
  ],
  "impact_files": 61,
  "impact_refs": 195,
  "open_pr_collision_risk": "LOW",
  "trigger_streams": ["S10-W", "S11"],
  "report_path": "docs/4. Operations/Reports/Product_Naming_Unification_Plan_2026-05-12.md",
  "issue": 364
}
```

---

## 10. Annex — 영향 파일 전수 (61 파일)

### A. Operations (21 파일)

```
docs/4. Operations/CC_PRD_Renewal_Plan_2026_05_06.md (26)
docs/4. Operations/Doc_Discovery_Failure_Critic_2026_05_06.md (22)
docs/4. Operations/team_assignment_v10_3.yaml (7) ⚠️ blocked
docs/4. Operations/Plans/Planning_Prototype_Gap_Analysis_2026-05-09.md (7)
docs/4. Operations/Causality_Dashboard.md (6)
docs/4. Operations/Conductor_Backlog/SG-033-ebs-mission-redefinition.md (6)
docs/4. Operations/orchestration/2026-05-08-consistency-audit/classification.md (5)
docs/4. Operations/Multi_Session_Design_v10.3.md (4)
docs/4. Operations/Critic_Reports/Lobby_Spec_Implementation_Drift_2026-05-06.md (4)
docs/4. Operations/orchestration/2026-05-08-consistency-audit/stream-specs/S2-lobby.md (4)
docs/4. Operations/Reports/2026-05-08-consistency-audit-final.md (3)
docs/4. Operations/orchestration/2026-05-08-consistency-audit/stream-specs/S7-backend.md (3)
docs/4. Operations/orchestration/2026-05-08-consistency-audit/stream-specs/S4-rive.md (3)
docs/4. Operations/orchestration/2026-05-08-consistency-audit/stream-specs/S3-cc.md (3)
docs/4. Operations/orchestration/2026-05-08-consistency-audit/foundation_ssot.md (3)
docs/4. Operations/Multi_Session_Design_v11.md (2)
docs/4. Operations/orchestration/2026-05-08-consistency-audit/stream-specs/S1-foundation.md (1)
docs/4. Operations/Inter_Session_Chat_Plan.md (1)
docs/4. Operations/Plans/Lobby_Renewal_Plan_2026-05-06.md (1)
docs/4. Operations/Conductor_Backlog/B-212-backend-coverage-78-to-90.md (1)
docs/4. Operations/orchestration/2026-05-08-consistency-audit/README.md (포함)
```

### B. Development (29 파일)

```
docs/2. Development/2.5 Shared/Stream_Entry_Guide.md (10)
docs/2. Development/2.1 Frontend/Lobby/Backlog/AUDIT-S2-lobby-v3-cascade-2026-05-08.md (8)
docs/2. Development/2.1 Frontend/Backlog/B-092-lobby-visual-screenshots-cascade-2026-05-05.md (4)
docs/2. Development/2.1 Frontend/Lobby/Backlog/AUDIT-S2-v10-4-cascade-2026-05-11.md (4)
docs/2. Development/2.1 Frontend/Lobby/Backlog/NOTIFY-S1-lobby-identity-cascade-2026-05-07.md (3)
docs/2. Development/2.4 Command Center/Backlog/NOTIFY-S1-cc-identity-cascade-2026-05-07.md (3)
docs/2. Development/2.1 Frontend/Lobby/References/EBS_Lobby_Design/README.md (3)
docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md (2)
docs/2. Development/2.4 Command Center/Command_Center_UI/UI.md (2)
docs/2. Development/2.4 Command Center/Command_Center_UI/Seat_Management.md (2)
docs/2. Development/2.4 Command Center/Command_Center_UI/Manual_Card_Input.md (2)
docs/2. Development/2.4 Command Center/Command_Center_UI/Keyboard_Shortcuts.md (2)
docs/2. Development/2.4 Command Center/Command_Center_UI/Hand_Lifecycle.md (2)
docs/2. Development/2.4 Command Center/Overlay/Sequences.md (2)
docs/2. Development/2.3 Game Engine/Behavioral_Specs/Triggers_and_Event_Pipeline.md (2)
docs/2. Development/2.3 Game Engine/Behavioral_Specs/Lifecycle_and_State_Machine.md (2)
docs/2. Development/2.5 Shared/BS_Overview.md (2)
docs/2. Development/2.5 Shared/AI_Cascade_System.md (2)
docs/2. Development/2.1 Frontend/Backlog/NOTIFY-C1-frontend-non-lobby-identity-cascade-2026-05-07.md (2)
docs/2. Development/2.1 Frontend/Backlog/B-091-lobby-design-missing-five-spec-impl.md (2)
docs/2. Development/2.1 Frontend/Lobby/Overview.md (2)
docs/2. Development/2.4 Command Center/Command_Center_UI/Multi_Table_Operations.md (1)
docs/2. Development/2.4 Command Center/Command_Center_UI/Action_Buttons.md (1)
docs/2. Development/2.4 Command Center/RFID_Cards/Overview.md (1)
docs/2. Development/2.3 Game Engine/Behavioral_Specs/Betting_and_Pots.md (1)
docs/2. Development/2.2 Backend/Back_Office/Overview.md (1)
docs/2. Development/2.1 Frontend/Backlog/AUDIT-Conductor-194-frontend-sister-cascade-2026-05-08.md (1)
docs/2. Development/2.1 Frontend/Lobby/UI.md (1)
```

### C. Product 본문 (4 파일 — rename 대상 자기 자신 포함)

```
docs/1. Product/Command_Center_PRD.md (3) — 내부 sister-link
docs/1. Product/Product_SSOT_Policy.md (4)
docs/1. Product/Foundation.md (포함)
docs/1. Product/1. Product.md (포함)
```

### D. Tools / Meta (7 파일)

```
tools/doc_discovery.py (1)
tools/orchestrator/message_bus/server.py (1)
tools/orchestrator/message_bus/tests/test_lock_contention.py (1)
tools/orchestrator/message_bus/tests/test_cascade_race.py (포함)
tools/ai_track/cia/self_test.py (2)
tools/ai_track/cia/fixtures/cc_visual_change.json (1)
.github/CODEOWNERS (3)
.github/ISSUE_TEMPLATE/stream_work.yml (1)
```

### E. 자동 생성 / 빌드 산출물 (3+ 파일 — 재생성 처리)

```
docs/_generated/full-index.md (5) ⚙️ regenerate
docs/_generated/confluence-mirror-matrix.md (3) ⚙️ regenerate
.doc-discovery-orphans.txt (3) ⚙️ regenerate
.orchestrator/streams/S1.activated (1) ⚙️ runtime state
docs/_archive/governance-2026-05/INDEX.md (포함) — archive 보존
```

---

## 11. 다음 액션

1. **본 보고서 PR** (S10-A 자율) — ready for review
2. **`Spec_Gap_Registry.md` SG-037 등재** — 별도 commit (scope_owns)
3. **broker publish** `pipeline:gap-classified` (Cycle 10 trigger)
4. **Wave 2 활성화**:
   - S10-W (rename + sed 일괄): Phase 1~3 + Phase 5 검증
   - S11 (broker → orchestrator scope): Phase 4 (meta 파일)
5. **본 S10-A 보고서는 영구 보존** — Reports/ 내 다른 22+ 분석 보고서와 동일 패턴

---

## Changelog

| 날짜 | 버전 | 변경 내용 | 근거 |
|------|:---:|----------|------|
| 2026-05-12 | v1.0 | 최초 작성 — Cycle 10 / 4축 Gap Analysis | 사용자 명시 |
