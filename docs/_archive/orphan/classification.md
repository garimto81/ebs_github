---
title: 683 .md 파일 전수 분류 매트릭스
owner: conductor
tier: internal
basis: "team_assignment_v10_3.yaml scope_owns + path 패턴 매칭"
last-updated: 2026-05-08
confluence-page-id: 3818455738
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818455738/EBS+683+.md
---

# 683 .md 파일 전수 분류 매트릭스

> **분류 원칙**: path 패턴 매칭. 한 파일 = 한 owner. 충돌 시 `Product_SSOT_Policy.md` §3.

## 1. Stream 별 영향 파일 합계

```
+------+--------------------+--------+-----------------------------------+
| ID   | 이름                | Files  | Path 패턴                         |
+------+--------------------+--------+-----------------------------------+
| S1   | Foundation         |   6    | 1.P/{Foundation,BO_PRD,GR/**}     |
| S2   | Lobby              |  116   | 1.P/Lobby + 2.1 Frontend/**   |
| S3   | Command Center     |   74   | 1.P/CC_PRD + 2.4 CC/**            |
| S4   | RIVE Standards     |    1   | 1.P/RIVE_Standards.md             |
| S5   | AI Track / Index   |   ~3   | docs/_generated/**                |
| S6   | Prototype          |  ~15   | 4.Ops/Plans/** + integration-tests|
| S7   | Backend            |  104   | 2.2 Backend/**                    |
| S8   | Game Engine        |   62   | 2.3 Engine/**                     |
+------+--------------------+--------+-----------------------------------+
| Cnd  | Conductor (main)   |  ~302  | 2.5 Shared, 3.CR, 4.Ops 잔여,     |
|      |                    |        | 1.P/References+archive,           |
|      |                    |        | _archive, mockups, examples       |
+------+--------------------+--------+-----------------------------------+
                                합계 683 (CI generated 제외)
```

## 2. 디렉토리별 owner 매트릭스

### `docs/1. Product/` (15 files)

| 파일/패턴 | Owner | 비고 |
|----------|:-----:|------|
| `Foundation.md` | **S1** | 정점 SSOT (v4.5.0) |
| `Back_Office.md` | **S1** (interim) | S7 활성 후에도 PRD = S1 유지 (외부 인계 정체성 SSOT) |
| `Game_Rules/Flop_Games.md` | **S1** (interim) | 22 게임 룰 외부 측 명세 |
| `Game_Rules/Draw.md` | **S1** | |
| `Game_Rules/Seven_Card_Games.md` | **S1** | |
| `Game_Rules/Betting_System.md` | **S1** | |
| `Lobby.md` | **S2** | derivative-of `2.1 Frontend/Lobby/Overview.md` |
| `Command_Center.md` | **S3** | derivative-of `2.4 CC/Command_Center_UI/Overview.md` |
| `RIVE_Standards.md` | **S4** | self (정본) |
| `Product_SSOT_Policy.md` | conductor | governance meta |
| `References/PokerGFX_Reference.md` | frozen (conductor read) | 벤치마크 참조 |
| `References/WSOP-Production-Structure-Analysis.md` | frozen | |
| `archive/Foundation_pre_FB_2026-05-04.md` | frozen | 이력 |
| `archive/Foundation_v41.0.0.md` | frozen | |
| `1. Product.md` | CI (`meta_files_blocked`) | landing |

### `docs/2. Development/2.1 Frontend/` (115 files) → **S2 일괄**

| 패턴 | Owner |
|------|:-----:|
| `2.1 Frontend/Lobby/**` | S2 |
| `2.1 Frontend/Login/**` | S2 |
| `2.1 Frontend/Settings/**` | S2 |
| `2.1 Frontend/Graphic_Editor/**` | S2 (NOTIFY-CCR-011 ownership move) |
| `2.1 Frontend/Backlog/**` | S2 (Frontend backlog) |
| `2.1 Frontend/2.1 Frontend.md` | CI generated (skip) |

### `docs/2. Development/2.2 Backend/` (104 files) → **S7 활성화**

| 패턴 | Owner |
|------|:-----:|
| `2.2 Backend/APIs/**` | S7 |
| `2.2 Backend/Authentication/**` | S7 |
| `2.2 Backend/Backlog/**` | S7 |
| `2.2 Backend/Back_Office/**` | S7 (정본 — `Back_Office.md` derivative-of) |
| `2.2 Backend/Database/**` | S7 |
| `2.2 Backend/Engineering/**` | S7 |
| `2.2 Backend/2.2 Backend.md` | CI generated (skip) |

### `docs/2. Development/2.3 Game Engine/` (62 files) → **S8 활성화**

| 패턴 | Owner |
|------|:-----:|
| `2.3 Game Engine/APIs/**` | S8 |
| `2.3 Game Engine/Backlog/**` | S8 |
| `2.3 Game Engine/Behavioral_Specs/**` | S8 |
| `2.3 Game Engine/2.3 Game Engine.md` | CI generated (skip) |

### `docs/2. Development/2.4 Command Center/` (73 files) → **S3 일괄**

| 패턴 | Owner |
|------|:-----:|
| `2.4 CC/APIs/**` | S3 |
| `2.4 CC/Backlog/**` | S3 |
| `2.4 CC/Command_Center_UI/**` | S3 (정본 — `Command_Center.md` derivative-of) |
| `2.4 CC/Integration_Test_Plan/**` | S3 |
| `2.4 CC/Overlay/**` | S3 |
| `2.4 CC/RFID_Cards/**` | S3 |

### `docs/2. Development/2.5 Shared/` (12 files) → **Conductor**

| 패턴 | Owner |
|------|:-----:|
| `2.5 Shared/team-policy.json` | conductor (meta) |
| `2.5 Shared/Authentication/**` | conductor (cross-team policy) |
| `2.5 Shared/Stream_Entry_Guide.md` | conductor |
| 기타 cross-team docs | conductor |

### `docs/3. Change Requests/` (94 files) → **Conductor (감사 대상 외)**

> **CR 은 정합성 감사 대상이 아님**. 진행 중 작업의 메모. 별도 워크플로우 (각 CR 의 owner stream 이 처리).

| 패턴 | 처리 |
|------|------|
| `3.CR/done/**` | conductor (참조, frozen) |
| `3.CR/in-progress/**` | 각 CR 의 stream owner 가 정상 워크플로우로 처리 |
| `3.CR/pending/**` | conductor 트리아지 |

### `docs/4. Operations/` (175 files)

| 패턴 | Owner |
|------|:-----:|
| `4.Ops/Plans/**` | **S6** |
| `4.Ops/Conductor_Backlog/**` | conductor |
| `4.Ops/Reports/**` | conductor |
| `4.Ops/Critic_Reports/**` | conductor |
| `4.Ops/handoffs/**` | conductor |
| `4.Ops/Task_Dispatch_Board/**` | conductor |
| `4.Ops/_generated/**` | conductor (auto) |
| `4.Ops/orchestration/**` | conductor (이 폴더) |
| `4.Ops/Multi_Session_Design_v10.3.md` | conductor (meta) |
| `4.Ops/team_assignment_v10_3.yaml` | conductor (meta) |
| `4.Ops/Spec_Gap_Triage.md` | conductor |
| `4.Ops/Docker_Runtime.md` | conductor |
| `4.Ops/Multi_Session_Handoff.md` | conductor |

### `docs/_generated/`, `docs/_archive/`, `docs/mockups/`, `docs/examples/` (31 files)

| 패턴 | Owner |
|------|:-----:|
| `_generated/full-index.md` | **S5** (regen) |
| `_generated/by-feature/**` | **S5** |
| `_generated/by-topic/**` | **S5** |
| `_archive/governance-2026-05/**` | frozen (conductor read) |
| `mockups/**` | conductor (asset) |
| `examples/**` | conductor (asset) |
| `images/**` | binary asset (skip) |

## 3. Edge Cases

| 케이스 | 처리 |
|-------|------|
| 같은 파일이 여러 Stream에 영향 | scope_owns 단일 owner. read 는 다수. drift 발견 시 owner 가 정정 |
| Stream A 가 Stream B 영역 정정 필요 | A → `NOTIFY-{B}-2026-05-08-*.md` backlog 생성 |
| 정본 (Overview.md) 변경 시 외부 PRD 동시 cascade | scope_check.yml CI gate 강제 |
| frozen 파일에서 drift 발견 | conductor 보고 (수정 X — 이력 보존) |
| CI generated (`1. Product.md`, `2.1 Frontend.md`, etc.) | skip — 자동 재생성 |

## 4. CI generated 파일 (감사 제외)

| 파일 | 생성 도구 |
|------|----------|
| `docs/1. Product/1. Product.md` | spec_aggregate.py |
| `docs/2. Development/2. Development.md` | spec_aggregate.py |
| `docs/2. Development/2.{1..5} *.md` | spec_aggregate.py |
| `docs/4. Operations/4. Operations.md` | spec_aggregate.py |
| `docs/_generated/full-index.md` | spec_aggregate.py |

> S5 가 spec_aggregate.py 재실행으로 일괄 갱신.

## 5. 검증 명령

```bash
# 자기 scope 영향 파일 list
python tools/doc_discovery.py --impact-of "docs/1. Product/Foundation.md"

# Match Rate (drift 검출률)
python tools/doc_discovery.py --gap-detect --stream=S2 --basis=foundation_ssot.md

# Stream scope 위반 사전 점검
python tools/orchestrator/phase_gate_validator.py --stream=S2 --phase=audit
```

## 6. 분류 검증 결과

```
Total .md files in docs/:     ~683
Classified to streams (S1-S8):  461
Conductor / frozen / CI:        222
                                ----
                                683  ✓
```
