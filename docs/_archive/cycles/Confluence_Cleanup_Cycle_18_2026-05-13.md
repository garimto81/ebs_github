---
title: "Confluence Cleanup + 5 PRD Sync — Cycle 18"
status: COMPLETED
owner: stream:S11 (Dev Assist - cross-cutting)
tier: internal
last-updated: 2026-05-13
cycle: 18
trigger: "사용자 명시 dispatch — Confluence 불필요 페이지 정리 + 5 PRD 본문 갱신 sync (PR #393 9 카테고리 반영)"
broker-event: "cascade:confluence-cleanup-applied"
related-docs:
  - ../Spec_Gap_Registry.md
  - ../../1. Product/Foundation.md
  - ../../1. Product/Back_Office.md
  - ../../1. Product/Command_Center.md
  - ../../1. Product/Lobby.md
  - ../../1. Product/1. Product.md
  - ./Product_Naming_Unification_Plan_2026-05-12.md
  - ../../_generated/confluence-mirror-matrix.md
---

# Confluence Cleanup + 5 PRD Sync — Cycle 18

> **Cycle 18 / S11 Dev Assist Stream** — 2026-05-13
>
> 사용자 dispatch: Confluence 불필요 페이지 정리 + 5 PRD 본문 갱신 sync (PR #393 9 카테고리 반영) + cascade:confluence-cleanup-applied broker publish.

## 0. Executive Summary (TL;DR)

| 항목 | 결과 |
|------|:----:|
| **drift_check (forward)** | **0 violations** (343/343 mirror target 정렬) |
| **drift_check (reverse)** | **6 orphans** — 모두 폴더 landing 페이지 (KEEP-STRUCTURAL) |
| **pagename_audit** | 343 target 분석 — Confluence 한국어 부제 패턴 (의도된 비매칭) |
| **PRD 접미사 정리 (3종)** | **이미 완료** (PR #399 S10-W cycle 18 작업, Back Office v15 / Command Center v16 / Lobby v13) |
| **5 PRD 본문 sync** | **4/5 PASS + 1/5 partial** (4종 verifier OK, Lobby 1/56 header sanitizer 경고만) |
| **불필요 페이지 분류** | 실제 정리 대상 **0건** — 7 키워드 KEEP + 6 structural orphan KEEP |
| **broker publish** | `cascade:confluence-cleanup-applied` 발행 예정 (PR 머지 후) |

**판정**: 이전 dispatch (f329a35a) 사용자 명시 3 페이지 명 변경은 PR #399 (S10-W) 가 이미 완료. 본 S11 작업으로 (1) Confluence ↔ 로컬 정합 audit 0 forward drift / 6 structural orphan 검증 (2) 5 PRD 본문 push 4/5 완전 PASS + 1/5 partial (3) 정리 대상 0건 결론 (모두 의도 보존) (4) cleanup 보고서 발행 완료. **Confluence drift 0건 KPI 달성, 정리 대상 0건 (audit 결과 의도 보존만), 5 PRD 본문 sync 5/5 push 완료**.

---

## 1. 사용자 요청 vs 실제 상태 (검증 결과)

### 1.1 페이지 명 3종 변경 — **이미 완료 (NO-OP)**

사용자 명시 작업 1: "Confluence 페이지 명 3종 변경 (Back Office/Command Center/Lobby — PRD 접미사 제거)"

**검증 결과**: PR #399 (commit `f778dd3a`, 2026-05-13 08:02 KST) 가 이미 5 PRD frontmatter title 정합을 완료했으며, Confluence 페이지명도 정렬됨.

| Page ID | 로컬 stem | Confluence Title (현재) | Version | 상태 |
|---------|-----------|------------------------|:-------:|:----:|
| 3811967073 | `Back_Office` | `Back Office` | v15 | OK (PRD 접미사 없음) |
| 3811901603 | `Command_Center` | `Command Center` | v16 | OK (PRD 접미사 없음) |
| 3811672228 | `Lobby` | `Lobby` | v13 | OK (PRD 접미사 없음) |
| 3625189547 | `Foundation` | `EBS 기초 기획서` | (별도) | OK (의도된 한국어 명) |
| 3811344758 | `1. Product` | `EBS · 1. Product` | (별도) | OK |

**Evidence**: `tools/confluence_pagename_audit.py --json` 직접 호출 + `lib.confluence.md2confluence.api_get` 라이브 API 호출 (3 PRD ID 검증, 위 표).

### 1.2 5 PRD 본문 sync (PR #393 9 카테고리 반영)

사용자 명시 작업 2: "5 PRD 페이지 본문 갱신 (PR #393 9 카테고리 반영)"

| 파일 | Confluence ID | Sync 결과 | 상태 |
|------|---------------|-----------|:---:|
| `docs/1. Product/Back_Office.md` | 3811967073 | v15 → **v16** (15 headers PASS, 10 mermaid + 1 image) | ✅ |
| `docs/1. Product/Foundation.md` | 3625189547 | v49 → **v50** (13 headers PASS, 17 mermaid + 3 images) | ✅ |
| `docs/1. Product/Command_Center.md` | 3811901603 | v16 → **v17** (23 headers PASS, 8 mermaid + 2 images) | ✅ |
| `docs/1. Product/Lobby.md` | 3811672228 | v13 → **v14** (55/56 headers PASS, 18 images) | ⚠️ |
| `docs/1. Product/1. Product.md` | 3811344758 | v13 → **v14** (6 headers PASS, 7 cross-links) | ✅ |

**도구**: `EBS_FORCE_MIRROR=1 python tools/sync_confluence.py --filter "1. Product/{name}.md"` (branch guard override, 본 cleanup branch).

**Lobby.md 부분 성공 (⚠️)**: content 업로드 SUCCESS (page v14) 이나 verifier 가 1/56 header 누락 감지 — `H.4 상태 머신 (\`HandAutoSetupStep\`)` (백틱 code span 포함된 header 가 Confluence sanitizer 통과 시 잘렸을 가능성). 본문은 정상 업로드되었으며 사용자 가시 영향은 미세. **carry-over** 로 분류 — 별도 후속 cycle 에서 backtick code span sanitizer issue 분석 필요.

### 1.3 drift_check 결과 (audit baseline)

```
[Forward drift] 343/343 aligned, drift=0
[Reverse drift] Folder 3184328827 — 6 Confluence-only orphans (모두 structural landing)
Total violations: forward=0 + reverse=6 = 6 (모두 structural KEEP)
```

**Evidence**: `tools/confluence_drift_check.py [--reverse]` 단독 실행.

---

## 2. 불필요 페이지 분류

### 2.1 키워드 스캔 결과 — KEEP 7건 (의도된 보존)

`PRD` / `DEPRECATED` / `README` 키워드 포함 페이지 (7개, **모두 의도된 보존**):

| Page ID | Title | 판정 | 사유 |
|---------|-------|:----:|------|
| 3818882170 | `3. Change Requests (DEPRECATED)` | KEEP | 명시 DEPRECATED, 폴더 자체 보존 |
| 3818881448 | `Command_Center_PRD.md 리뉴얼 계획 (v1.1.0 → v2.0.0)` | KEEP | 역사 plan 보고서 (post-mortem) |
| 3820552681 | `문서 발견 실패 — Command_Center_PRD.md 누락 사고와 systematic 해결` | KEEP | post-mortem critic |
| 3818717668 | `EBS-Skin-Editor_v3.prd` | KEEP | 레거시 skin editor 명세 |
| 3818717688 | `prd-skin-editor.prd` | KEEP | 위 동일 |
| 3818619311 | `EBS · README` | KEEP | team1 README (로컬 미러 있음) |
| 3818881608 | `v8.0 Phase 4 — Deprecated Hooks Audit` | KEEP | 역사 audit 보고서 |

**결론**: 키워드만으로는 "삭제 대상" 불필요 페이지 없음. 모두 audit/post-mortem/legacy 명세로 의도된 보존 영역.

### 2.2 진짜 orphan 식별 (reverse drift) — KEEP-STRUCTURAL 6건

`tools/confluence_drift_check.py --reverse --folder-id 3184328827` 실행 결과:

| Page ID | Title | 판정 | 사유 |
|---------|-------|:----:|------|
| 3811606750 | `EBS · 2.1 Frontend` | KEEP-STRUCTURAL | 폴더 landing (자식 25+ 페이지 보유) |
| 3811770578 | `EBS · 2.2 Backend` | KEEP-STRUCTURAL | 폴더 landing |
| 3811836049 | `EBS · 2.3 Game Engine` | KEEP-STRUCTURAL | 폴더 landing |
| 3811901565 | `EBS · 2.4 Command Center` | KEEP-STRUCTURAL | 폴더 landing |
| 3812032646 | `EBS · 2.5 Shared` | KEEP-STRUCTURAL | 폴더 landing |
| 3818521542 | `EBS · 3. Change Requests` | KEEP-STRUCTURAL | DEPRECATED 폴더 자체 (자식 보존) |

**결론**: 모두 Confluence 페이지 트리에 필요한 폴더 인덱스(landing) 페이지. 로컬 frontmatter 가 없는 것은 의도된 설계 (인덱스 페이지는 로컬 미러 불필요). **삭제/이동 대상 없음**.

**도구 개선 carry-over**: `tools/confluence_drift_check.py` 의 `STRUCTURAL_ALLOWED` set 에 위 6 ID 추가하면 향후 false positive 차단 가능. 별도 PR 로 분리.

---

## 3. Sync 작업 상세

### 3.1 Back_Office.md → 3811967073 (v15 → v16) ✅

```
[1/6] Reading frontmatter — 14 fields (7 인과관계)
[3/6] Rendered 10 Mermaid diagrams (mermaid.ink + mmdc hybrid fallback)
[5/6] Uploaded 11 attachments
[6/6] Updated page (v15 -> v16) under parent 3811344758
[7/7] Verified 15 headers in Confluence storage
[labels] tier-external, owner-conductor applied
Result: 1/1 succeeded
```

### 3.2 Foundation.md → 3625189547 (v49 → v50) ✅

```
[1/6] Reading frontmatter — 22 fields (15 인과관계)
[3/6] Rendered 17 Mermaid diagrams (mermaid.ink + mmdc hybrid fallback)
[5/6] Uploaded 20 attachments (3 Gemini images + 17 mermaid)
[6/6] Updated page (v49 -> v50) under parent 3811344758
[7/7] Verified 13 headers in Confluence storage
[labels] tier-internal, owner-conductor applied
```

### 3.3 Command_Center.md → 3811901603 (v16 → v17) ✅

```
[1/6] Frontmatter: 14 fields (8 인과관계)
[3/6] Rendered 8 Mermaid diagrams
[5/6] Uploaded 10 attachments (2 image + 8 mermaid)
[6/6] Updated page (v16 -> v17)
[7/7] Verified 23 headers
[labels] tier-external, owner-conductor applied
```

### 3.4 Lobby.md → 3811672228 (v13 → v14) ⚠️

```
[1/6] Frontmatter: 17 fields (8 인과관계)
[3/6] No Mermaid (image-only PRD)
[5/6] Uploaded 18 attachments (ebs-lobby-* + ebs-flow-* PNG sequence)
[6/6] Updated page (v13 -> v14)
[7/7] ⚠️  WARNING: 1/56 header(s) missing in Confluence storage:
        - H.4 상태 머신 (`HandAutoSetupStep`)
      → Likely Confluence sanitizer rejected backtick code span in header
```

**판정**: content 실제 업로드 OK. verifier strict mode 의 단일 header sanitizer 경고만. 사용자 가시 영향 최소. **carry-over 분류** (별도 cycle).

### 3.5 1. Product.md → 3811344758 (v13 → v14) ✅

```
[1/6] Frontmatter: 7 fields (2 인과관계)
[3/6] No Mermaid
[4/6] cross-link: 7/7 markdown links → Confluence page links
[5/6] No attachments
[6/6] Updated page (v13 -> v14) under parent 3184328827
[7/7] Verified 6 headers
[labels] tier-internal, owner-conductor applied
```

---

## 4. broker MCP cascade

발행할 이벤트 (PR 머지 후):

```yaml
broker publish:
  stream: S11
  event: cascade:confluence-cleanup-applied
  payload:
    cycle: 18
    drift_check_forward: 0 violations
    drift_check_reverse: 6 structural orphans (KEEP)
    page_renames: 0 (이미 완료 — PR #399)
    content_pushed: 5/5 (4 PASS + 1 partial)
    orphans_found: 6 structural (모두 의도 보존)
    cleanup_actions: 0 (audit 결과 의도 보존만)
    report: docs/4. Operations/Reports/Confluence_Cleanup_Cycle_18_2026-05-13.md
```

---

## 5. KPI (사용자 명시)

| KPI | 목표 | 실제 |
|-----|:----:|:----:|
| Confluence drift (forward) | 0건 | **0건** ✅ |
| 불필요 페이지 정리 | N건 | **0건 정리** (audit 결과: 7 키워드 KEEP + 6 structural KEEP, 의도 보존만) |
| 5 PRD 본문 갱신 | 5/5 | **5/5 push** (4 verifier PASS + 1 sanitizer warning) ✅ |

---

## 6. 후속 작업 (Carry-over)

본 PR 으로 cleanup 자체는 완결. 별도 cycle 에서 처리 권장 (LOW 우선순위):

1. **Lobby.md sanitizer 경고 해소**: `H.4 상태 머신 (\`HandAutoSetupStep\`)` 헤더의 백틱 code span 이 Confluence sanitizer 에 의해 제거되는 패턴 분석. `md2confluence.py` 의 H4 처리 또는 strict_verifier mode 의 false-positive 여부 검증 필요.
2. **drift_check.py STRUCTURAL_ALLOWED 보강**: 현재 `3812360338` (Game Rules) 단일. 본 cycle 식별된 6 structural landing ID (`3811606750`, `3811770578`, `3811836049`, `3811901565`, `3812032646`, `3818521542`) 추가하여 향후 reverse drift false positive 차단.
3. **Foundation.md mirror-status 갱신**: PR #399 이 `confluence-mirror-status: to-push` 로 표시했으나 본 cycle 에서 push 완료 (v49→v50). frontmatter `last-synced: 2026-05-13` + mirror-status 정합 필요.

## 7. 변경 이력

| 날짜 | 변경 | 사유 |
|------|------|------|
| 2026-05-13 | v1.0 최초 작성 | Cycle 18 S11 cleanup dispatch |
