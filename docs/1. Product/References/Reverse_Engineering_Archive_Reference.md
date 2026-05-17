---
doc_type: "reference"
doc_id: "AT-REF-002"
version: "1.0.0"
status: "active"
created: 2026-05-17
last-updated: 2026-05-17
title: ebs_reverse Archive Reference — PokerGFX v3.2.985.0 역공학 자료 인덱스
owner: conductor
tier: internal
confluence-sync: none  # Confluence 업로드 제외 (사용자 명시 2026-05-17)
mirror: none           # 본 프로젝트 의도 외 (경쟁사 역공학 = 시장 분석 범위). 로컬 archive 만 보존, Confluence 발행 안 함.
referenced-by:
  - "../Foundation.md (§C.3 Vision Layer — 1단계 EBS = PokerGFX 패러다임의 자체 구현)"
  - "../References/PokerGFX_Reference.md v8.5.0 (AT-REF-001 — 통합본)"
relates-to:
  - "memory: ebs-reverse-archive-location-2026-05-17"
  - "case_study: 2026-05-17_ebs_reverse_recovery (예정)"
recovery-trigger:
  date: 2026-05-17
  user-directive: "Either restore the ebs_reverse repository or use any means necessary to restore the reverse engineering documentation"
---

# ebs_reverse Archive Reference (AT-REF-002)

> **본 reference 의 목적**: PokerGFX Server v3.2.985.0 역공학 자료의 archive 위치 + 4 중 백업 매트릭스 + 핵심 파일 인덱스를 EBS 레포 내부에서 즉시 접근 가능하게 명시. **Confluence 업로드 제외** — 본 프로젝트 의도 외 (경쟁사 역공학 자료) 이므로 로컬 archive 만 보존.

---

## 한 줄 정의

> **PokerGFX Server v3.2.985.0 (RFID-VPT, 355MB .NET 바이너리) 의 역공학 분석 자료** (74MB / 62 markdown / 3000-line 핵심 파일 포함) **가 archive 폴더로 의도적 이동 보존된 상태**. 본 reference 가 path SSOT.

---

## ⚠ Confluence 업로드 정책 (HARD ENFORCE)

| 영역 | 정책 |
|------|------|
| 본 reference 파일 (AT-REF-002) | **mirror: none** + **confluence-sync: none** — 업로드 제외 |
| archive 의 62 markdown 파일 전체 | **모두 mirror: none 적용** — 업로드 제외 |
| 본 EBS 통합본 PokerGFX_Reference.md (AT-REF-001) | mirror: none (이미 적용, 2026-05-15) |
| 사용자가 향후 archive 자료를 다른 위치로 옮길 시 | 새 위치도 mirror: none 자동 적용 |

**이유** (사용자 명시 2026-05-17):
- archive 자료는 경쟁사 (PokerGFX LLC) 의 역공학 결과
- 본 프로젝트 인텐트 "개발 문서 + 프로토타입 100% 일관성" 의 범위 밖 (경쟁사 분석 = 시장 분석 영역)
- Confluence 외부 공유 시 IP / 법적 리스크
- 로컬 archive 만으로 충분 (4 중 백업 매트릭스 보장)

---

## 4 중 백업 매트릭스 (현 상태 SSOT)

| # | Layer | 위치 | 크기 | Confluence sync |
|---|-------|------|:----:|:---:|
| 1 | **Primary** | `C:/claude/ebs-archive-backup/07-archive/legacy-repos/ebs_reverse/` | 74MB / 62 markdown | ❌ none |
| 2 | **Secondary** | `C:/claude/ebs-archive-backup/07-archive/team4-cc-cleanup-20260414/at-reference/` | (보조 백업) | ❌ none |
| 3 | **Cloud (Read-only ref)** | Google Docs (Doc ID `1Y4YPRicgItRqxdOe4X2KJyW-D8TP3Gd9dE1uDTvSBHU`) | (cloud) | ❌ none (read-only) |
| 4 | **Integrated** | `C:/claude/ebs/docs/1. Product/References/PokerGFX_Reference.md` v8.5.0 (AT-REF-001) | 1500+ 줄 통합본 | ❌ mirror: none |

---

## archive 디렉토리 구조 (62 markdown 전체)

```
C:/claude/ebs-archive-backup/07-archive/legacy-repos/ebs_reverse/
├── CLAUDE.md
├── RECOVERY-README.md
└── docs/
    ├── pokergfx-prd-v2.md                            (EBS 기초 기획서 v28.0.0)
    │
    ├── 00-prd/                                       (2 파일)
    │   ├── coord-picker-global.prd.md
    │   └── overlay-fallback.prd.md
    │
    ├── 01-plan/                                      (10 파일)
    │   ├── pokergfx-competitive-analysis.md          (경쟁사 분석)
    │   ├── pokergfx-glossary.md ⭐                    (176 줄, 용어집)
    │   ├── pokergfx-ui-overview.md
    │   ├── pokergfx-ui-screens.md
    │   ├── prd-v8-checklist.md
    │   ├── prd-v8-research-findings.md
    │   ├── part-vii-completion.plan.md
    │   ├── part-vii-draft.md
    │   ├── overlay-fallback.plan.md
    │   ├── coord-picker-global.plan.md
    │   └── data/overlay-anatomy-legend.md
    │
    ├── 02-design/                                    (6 파일, ⭐⭐⭐ 핵심)
    │   ├── pokergfx-reverse-engineering-complete.md ⭐⭐⭐ (3000 줄)
    │   ├── pokergfx-lookup-tables.md ⭐⭐              (610 줄)
    │   ├── overlay-mapping-redesign-proposal.md
    │   ├── overlay-fallback.design.md
    │   ├── coord-picker-global.design.md
    │   └── features/pokergfx.design.md
    │
    ├── 04-report/                                    (3 파일)
    │   ├── changelog.md
    │   ├── coord-picker-global.report.md
    │   └── overlay-fallback.report.md
    │
    └── archive/                                      (40 파일 — 역사 추적)
        ├── analysis/                                 (8 deep analysis ⭐)
        ├── designs/                                  (1 파일)
        ├── plans/                                    (8 파일 — clone-prd wave1-4 포함)
        ├── prd-versions/                             (8 PRD snapshots: v1.0.0 ~ v24.0.0)
        ├── reports/                                  (6 파일)
        ├── pokergfx-development-prd-v1.md
        ├── pokergfx-ui-design.md
        └── prd-boundary-refactoring.plan.md
```

---

## 핵심 파일 인덱스 (사용 빈도 순)

| # | 파일 | archive 위치 | 분량 | 용도 |
|---|------|-------------|:----:|------|
| 1 | **pokergfx-reverse-engineering-complete.md** | `docs/02-design/` | **3000 줄** | PokerGFX Server v3.2.985.0 역공학 완전본 (88% 커버리지) — Hand FSM / 게임 클래스 / 네트워크 / DRM / 스킨 / UI 모든 영역 |
| 2 | **pokergfx-lookup-tables.md** | `docs/02-design/` | 610 줄 | enum / state / 매핑 lookup tables (game enum 22 값, game_class 3 enum, auto_blinds_type 4 enum 등) |
| 3 | **pokergfx-glossary.md** | `docs/01-plan/` | 176 줄 | PokerGFX 용어집 |
| 4 | pokergfx-prd-v2.md | `docs/` | (대형) | EBS 기초 기획서 v28.0.0 |
| 5 | pokergfx-competitive-analysis.md | `docs/01-plan/` | — | 경쟁사 분석 |
| 6 | pokergfx-ui-overview.md / pokergfx-ui-screens.md | `docs/01-plan/` | — | UI 화면 분석 (43 WinForms 화면) |
| 7 | architecture_overview.md | `docs/archive/analysis/` | ~1,367 줄 | 시스템 구조 / 의존성 / DRM / 암호화 |
| 8 | hand_eval_deep_analysis.md | `docs/archive/analysis/` | — | 핸드 평가 엔진 (Bitmask + Monte Carlo) deep analysis |
| 9 | net_conn_deep_analysis.md | `docs/archive/analysis/` | ~733 줄 | 네트워크 프로토콜 113+ 명령 deep analysis |
| 10 | confuserex_analysis.md | `docs/archive/analysis/` | — | ConfuserEx 난독화 분석 |
| 11 | runtime_debugging_analysis.md | `docs/archive/analysis/` | — | 런타임 디버깅 분석 |
| 12 | infra_modules_analysis.md | `docs/archive/analysis/` | ~1,395 줄 | GPU 렌더링 / God Class 아키텍처 |
| 13 | auxiliary_modules_analysis.md | `docs/archive/analysis/` | ~586 줄 | analytics / RFIDv2 / boarssl |

---

## EBS PRD chain 과의 관계

본 archive 자료는 다음 EBS PRD 의 ground truth 검증 reference:

| EBS PRD 영역 | archive 참조 위치 | 검증 cycle |
|-------------|-----------------|-----------|
| Foundation.md §B.1 (Mixed Game 22 종, 3 클래스) | `02-design/pokergfx-reverse-engineering-complete.md` §5 line 795-877 | 2026-05-17 (v3) |
| Foundation.md §B.3 (통신 매트릭스) | `02-design/pokergfx-reverse-engineering-complete.md` §8 line 1484-1748 (113+ 명령) | 2026-05-17 (v4) |
| Foundation.md §A.4 (Hole Card Visibility 4단 방어) | `02-design/pokergfx-reverse-engineering-complete.md` §10 line 1909-2136 (4계층 DRM — 직교 관계) | 2026-05-17 (v4) |
| Foundation.md §C.2 (RFID 12 안테나) | `02-design/pokergfx-reverse-engineering-complete.md` §9 line 1750-1907 (RFIDv2.dll + boarssl.dll) | 2026-05-17 (v4) |
| Command_Center.md Ch.6 HandFSM 9-state R5 | `02-design/pokergfx-reverse-engineering-complete.md` §5.4 line 879-924 (8-state Flop + 게임 클래스 분기) | 2026-05-17 (v2/v3) |
| Lobby.md Ch.7 (Players 통계 VPIP/PFR/AGR) | `02-design/pokergfx-reverse-engineering-complete.md` §8.7 line 1663-1684 (Wtsd/CumWin 5종) | 2026-05-17 (v4) |
| RIVE_Standards.md (Overlay 9 카테고리) | `02-design/pokergfx-reverse-engineering-complete.md` §11 line 2138-2349 (ConfigurationPreset 99+ 필드) | 2026-05-17 (v4) |

---

## 사용 가이드 (어떤 archive 파일을 언제 참조)

```
   EBS 작업 시 archive 참조 결정 트리
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   
   Q: 게임 룰 / FSM / 게임 클래스 작업?
      → docs/02-design/pokergfx-reverse-engineering-complete.md §5
      → docs/02-design/pokergfx-lookup-tables.md
   
   Q: CC ↔ Engine ↔ BO 통신 spec?
      → docs/02-design/pokergfx-reverse-engineering-complete.md §8 (113+ 명령)
      → docs/archive/analysis/net_conn_deep_analysis.md
   
   Q: RFID 통신 / 보안?
      → docs/02-design/pokergfx-reverse-engineering-complete.md §9
      → docs/archive/analysis/auxiliary_modules_analysis.md
   
   Q: 운영자 부정 방지 / Hole Card Visibility?
      → docs/02-design/pokergfx-reverse-engineering-complete.md §10 (참고만 — EBS 와 직교)
      → docs/archive/analysis/architecture_overview.md
   
   Q: Overlay 9 카테고리 / 시각 디자인?
      → docs/02-design/pokergfx-reverse-engineering-complete.md §11
      → docs/archive/analysis/infra_modules_analysis.md (GPU)
   
   Q: UI 화면 spec?
      → docs/02-design/pokergfx-reverse-engineering-complete.md §13
      → docs/01-plan/pokergfx-ui-overview.md
      → docs/01-plan/pokergfx-ui-screens.md
   
   Q: PokerGFX 용어가 헷갈림?
      → docs/01-plan/pokergfx-glossary.md
   
   Q: 통합본만 보고 싶음 (요약)?
      → C:/claude/ebs/docs/1. Product/References/PokerGFX_Reference.md v8.5.0
        (AT-REF-001, 1500+ 줄 통합본 — Confluence 업로드 안 함)
```

---

## 데이터 손실 방지 정책 (영구 적용)

| 룰 | 내용 | 적용 |
|----|------|------|
| **NEVER DELETE** | archive 의 어떤 자료도 삭제 금지 | HARD |
| **NEVER MOVE PRIMARY** | `legacy-repos/ebs_reverse/` 위치 영구 보존 | HARD |
| **mirror: none 보존** | archive 자료 + 본 reference + 통합본 모두 Confluence 업로드 제외 | HARD |
| **Verify on Cycle Entry** | 매 cycle 진입 시 4 중 백업 매트릭스 검증 | RECOMMENDED |
| **Cross-Ref Required** | EBS 작업 시 archive 자료 인용 시 archive path + section 명시 | RECOMMENDED |
| **Cloud Sync Verify** | 6 개월 1 회 Google Docs 4 종 동기화 상태 확인 | RECOMMENDED |

---

## 복구 절차 (만약 archive 가 손상 시)

```
   복구 우선순위
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   
   1차: archive 폴더가 손상되었으나 git 추적되면
        → cd C:/claude/ebs-archive-backup && git checkout
        → archive 자동 복원
   
   2차: archive 폴더 자체 손실 시
        → Google Docs Doc ID 1Y4YPRicgItRqxdOe4X2KJyW-D8TP3... 다운로드
        → 본 EBS 통합본 (PokerGFX_Reference.md v8.5.0) 사용
        → Secondary 백업 (at-reference/) 활용
   
   3차: 모든 로컬 백업 손실 시
        → Google Docs 4 종 export
        → 본 reference (AT-REF-002) 의 메타데이터 참조
        → 사용자 OneDrive / 개인 백업 확인
```

---

## 변경 이력

| 날짜 | 버전 | 변경 | 사유 |
|------|------|------|------|
| 2026-05-17 | 1.0.0 | 본 reference 신규 작성 | 사용자 긴급 복구 요청 + Confluence 업로드 제외 명시 |

---

## 관련 자료

### 본 EBS 레포

- `docs/1. Product/References/PokerGFX_Reference.md` v8.5.0 (AT-REF-001 — 통합본)
- `docs/1. Product/Foundation.md` v4.5 (§C.3 PokerGFX 패러다임 자체 구현)
- `docs/1. Product/Command_Center.md` v4.3 (Ch.6 HandFSM R5 결정)

### 메모리

- `~/.claude/projects/C--claude-ebs/memory/ebs_reverse_archive_location_2026_05_17.md` (path SSOT)
- `~/.claude/projects/C--claude-ebs/memory/MEMORY.md` (두 레포 관계 표 갱신)

### Plan 보고서 (사용자 영역)

- `~/.claude/plans/ebs-reverse-recovery-report-2026-05-17.md` (복구 보고)
- `~/.claude/plans/decision-report-v2-ultrathink.md` (v2 ultrathink)
- `~/.claude/plans/decision-report-v3-pokergfx-verification.md` (v3 정본 1100 줄 검증)
- `~/.claude/plans/decision-report-v4-pokergfx-full-verification.md` (v4 전수 검증)

---

## 한 줄 마무리

> **AT-REF-002 = ebs_reverse archive 의 EBS 레포 내부 path SSOT + 사용 가이드 + Confluence 업로드 제외 정책 명시화. archive 자료 손실 = 0. 데이터 손실 방지 정책 영구 적용.**
