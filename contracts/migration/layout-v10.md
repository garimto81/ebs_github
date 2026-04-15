---
title: 문서 재설계 v10 — 레이아웃 SSOT
owner: conductor
tier: contract
legacy-id: LAYOUT-V10
last-updated: 2026-04-15
---

# 문서 재설계 v10 — 레이아웃 SSOT

이 문서는 EBS 프로젝트 문서 재설계 v10의 **최종 디렉토리 레이아웃** 및 **WSOP LIVE Confluence 매핑** SSOT이다.
마이그레이션 스크립트(`tools/migrate_docs_v10.py`), 정책 파일(`team-policy-v5.json`), 검증 도구는 모두 이 문서를 참조한다.

---

## 1. 설계 원칙 (Critic v9 → v10)

| 원칙 | 설명 |
|------|------|
| **최소화** | 홈 레벨 7 → 4, Development 섹션 6 → 5, 팀 내부 `UI_Design/Quality/` 상위 폴더 제거 |
| **WSOP LIVE 정렬** | 홈 레벨 `N. 이름`, 팀 하위번호 `2.N {팀명}/` 패턴 유지 (WSOP `6.N` 모델) |
| **Publisher 집중** | API/DB/BO 계약을 publisher 팀 하위에 배치 (Fast-Track 지원) |
| **Feature 응집** | feature 폴더 내부에 `UI.md`, `QA.md` 동거. 상위 `UI_Design/`, `Quality/` 폐지 |
| **번호 prefix 제거** | 파일명에서 `BS-02-02-` 등 번호 제거, `PascalSnake.md`로 변환. legacy ID는 frontmatter로 보존 |

---

## 2. 최종 디렉토리 트리

```
C:/claude/ebs/
├── docs/
│   ├── README.md
│   │
│   ├── 1. Product/
│   │   ├── 1. Product.md
│   │   ├── Foundation.md
│   │   ├── Architecture.md
│   │   ├── Team_Structure.md
│   │   ├── Communication_Rules.md
│   │   ├── Game_Rules/
│   │   │   ├── Flop_Games.md
│   │   │   ├── Draw.md
│   │   │   ├── Seven_Card_Games.md
│   │   │   └── Betting_System.md
│   │   └── PokerGFX_Reference.md
│   │
│   ├── 2. Development/
│   │   ├── 2. Development.md
│   │   │
│   │   ├── 2.1 Frontend/            ← team1
│   │   │   ├── 2.1 Frontend.md
│   │   │   ├── Login/
│   │   │   │   ├── Overview.md  Form.md  Session_Init.md
│   │   │   │   ├── Error_Handling.md  UI.md  QA.md
│   │   │   ├── Lobby/
│   │   │   │   ├── Overview.md  Session_Restore.md
│   │   │   │   ├── Event_and_Flight.md  Table.md  UI.md  QA.md
│   │   │   ├── Settings/
│   │   │   │   ├── Overview.md  Outputs.md  Graphics.md
│   │   │   │   ├── Display.md  Rules.md  Statistics.md
│   │   │   │   ├── Preferences.md  UI.md  QA.md
│   │   │   ├── Graphic_Editor/
│   │   │   │   ├── Overview.md  Import_Flow.md
│   │   │   │   ├── Metadata_Editing.md  Activate_Broadcast.md
│   │   │   │   ├── RBAC_Guards.md  UI.md  QA.md
│   │   │   ├── Console_UI.md
│   │   │   ├── Engineering.md
│   │   │   ├── Spec_Gaps.md
│   │   │   └── Backlog.md
│   │   │
│   │   ├── 2.2 Backend/             ← team2 (API/DB/BO publisher)
│   │   │   ├── 2.2 Backend.md
│   │   │   ├── APIs/
│   │   │   │   ├── Backend_HTTP.md       (legacy API-01)
│   │   │   │   ├── WebSocket_Events.md   (legacy API-05)
│   │   │   │   └── Auth_and_Session.md   (legacy API-06)
│   │   │   ├── Database/
│   │   │   │   ├── Schema.md  ER_Diagram.md  Field_Registry.json
│   │   │   ├── Back_Office/
│   │   │   │   ├── Overview.md  Sync_Protocol.md  Operations.md
│   │   │   ├── Engineering/
│   │   │   │   ├── Dev_Setup.md  Tech_Stack.md  Project_Structure.md
│   │   │   │   ├── State_Management.md  Routing.md
│   │   │   │   ├── Dependency_Injection.md  Error_Handling.md
│   │   │   │   ├── Logging.md  Testing_Strategy.md
│   │   │   │   ├── Build_and_Deploy.md  Non_Functional_Requirements.md
│   │   │   ├── Spec_Gaps.md
│   │   │   └── Backlog.md
│   │   │
│   │   ├── 2.3 Game Engine/         ← team3 (Overlay API publisher)
│   │   │   ├── 2.3 Game Engine.md
│   │   │   ├── APIs/
│   │   │   │   └── Overlay_Output_Events.md  (legacy API-04)
│   │   │   ├── Behavioral_Specs/
│   │   │   │   ├── Overview.md  Event_Catalog.md  Action_Rotation.md
│   │   │   │   ├── Holdem/
│   │   │   │   │   ├── Lifecycle.md  Betting.md  Blinds_and_Ante.md
│   │   │   │   │   ├── Coalescence.md  Evaluation.md  Side_Pot.md
│   │   │   │   │   ├── Showdown.md  Exceptions.md
│   │   │   │   ├── Flop_Variants.md  Draw_Games.md  Stud_Games.md
│   │   │   ├── Engineering.md
│   │   │   ├── Spec_Gaps.md
│   │   │   └── Backlog.md
│   │   │
│   │   ├── 2.4 Command Center/      ← team4 (RFID HAL publisher)
│   │   │   ├── 2.4 Command Center.md
│   │   │   ├── APIs/
│   │   │   │   └── RFID_HAL.md      (legacy BS-04-04)
│   │   │   ├── RFID_Cards/
│   │   │   │   ├── Overview.md  Deck_Registration.md
│   │   │   │   ├── Card_Detection.md  Manual_Fallback.md
│   │   │   │   ├── Register_Screen.md  UI.md  QA.md
│   │   │   ├── Command_Center_UI/
│   │   │   │   ├── Overview.md  Hand_Lifecycle.md  Action_Buttons.md
│   │   │   │   ├── Seat_Management.md  Manual_Card_Input.md
│   │   │   │   ├── Undo_Recovery.md  Keyboard_Shortcuts.md
│   │   │   │   ├── Statistics.md  Game_Settings_Modal.md
│   │   │   │   ├── Player_Edit_Modal.md  Multi_Table_Operations.md
│   │   │   │   ├── UI.md  QA.md
│   │   │   ├── Overlay/
│   │   │   │   ├── Overview.md  Elements.md  Animations.md
│   │   │   │   ├── Skin_Loading.md  Scene_Schema.md  Audio.md
│   │   │   │   ├── Layer_Boundary.md  Security_Delay.md
│   │   │   │   ├── Sequences.md  UI.md  QA.md
│   │   │   ├── Integration_Test_Plan.md
│   │   │   ├── Engineering.md
│   │   │   ├── Spec_Gaps.md
│   │   │   └── Backlog.md
│   │   │
│   │   └── 2.5 Shared/              ← Conductor
│   │       ├── 2.5 Shared.md
│   │       ├── BS_Overview.md           (legacy BS-00)
│   │       ├── Authentication.md        (legacy BS-01)
│   │       ├── EBS_Core.md
│   │       ├── Data_Analysis.md
│   │       ├── team-policy.json
│   │       └── Risk_Matrix.md
│   │
│   ├── 3. Change Requests/
│   │   ├── 3. Change Requests.md
│   │   ├── pending/
│   │   ├── in-progress/
│   │   └── done/
│   │
│   ├── 4. Operations/
│   │   ├── 4. Operations.md
│   │   ├── Roadmap.md
│   │   ├── Conductor_Backlog.md
│   │   ├── Plans/
│   │   └── Reports/
│   │
│   ├── mockups/
│   ├── images/
│   └── _generated/                  ← CI auto-commit (DO NOT edit)
│       ├── full-index.md
│       ├── by-topic/
│       ├── by-feature/
│       └── by-owner/
│
├── team1-frontend/                  ← 코드만 (src/, tests/)
├── team2-backend/
├── team3-engine/
├── team4-cc/
│
├── integration-tests/
├── tools/
├── contracts/
│   └── migration/                   ← 재설계 도구/정책 (Phase 0 산출물)
├── .claude/
├── CLAUDE.md
└── README.md
```

---

## 3. WSOP LIVE Confluence 매핑

참조 소스: `C:/claude/wsoplive/docs/confluence-mirror/WSOP Live 홈/`

| EBS v10 홈 레벨 | WSOP LIVE 상위 섹션 | 정렬 수준 |
|-----------------|---------------------|-----------|
| `1. Product/` | `1. Product & Specs/` | 동일 |
| `2. Development/` | `2. Development/` | 동일 |
| `2.N {팀명}/` | `6.N {팀명}/` (WSOP LIVE 번호 기준) | 패턴 동일, 번호 오프셋 |
| `3. Change Requests/` | `3. Change Requests/` | 동일 (EBS는 CCR만 유지, Release/Improvements 미운영) |
| `4. Operations/` | `4. Operations/` + `5. Roadmap/` 통합 | 부분 일치 (최소화 justify) |

**의도적 Divergence (justify)**:
- `0. EBS Rules/`, `4. PokerGFX Reference/`, `5. Roadmap/`, `9. 회의록/` (WSOP LIVE 존재) → EBS v10에서 **흡수/제거**. 사유: EBS 현 단계에서 실 파일이 존재하지 않거나 1~2개로 홈 레벨 공간이 과도. `1. Product/` 및 `4. Operations/`로 흡수.
- `2.5 Shared/` (WSOP LIVE 미존재) → EBS는 Conductor 소유 팀 간 계약(`BS_Overview`, `Authentication` 등)을 수용할 슬롯 필요. 팀 Fast-Track 외부 영역으로 격리.

---

## 4. 개발자·검수자 동선

### 팀원 (ex. team1 프론트엔드 개발자)
1. `docs/2. Development/2.1 Frontend/` 한 곳에서 spec + UI + QA + Backlog 편집
2. feature 단위(`Lobby/`, `Settings/` 등) 응집 — feature 폴더 안에서 `Overview.md` → `UI.md` → `QA.md` 이동만으로 완결
3. 계약 변경 필요 시 `docs/3. Change Requests/pending/CR-team1-YYYYMMDD-*.md` draft 작성

### Conductor
1. `docs/2. Development/2.5 Shared/` — 팀 간 계약 (auth, BS_Overview) 관리
2. `docs/3. Change Requests/in-progress/` — 승격 CCR 진행
3. `docs/4. Operations/Conductor_Backlog.md` — 크로스팀 태스크
4. `docs/1. Product/Foundation.md` + `Architecture.md` — 상위 비전/구조 관리

### 외부 리뷰어 (임원·QA·신규 합류자)
1. `docs/README.md` → `_generated/full-index.md` 한 번으로 전체 TOC 확인
2. 주제별: `_generated/by-topic/APIs.md` → 5개 API 전수 링크
3. 팀별: `_generated/by-owner/team{N}.md` → 해당 팀 산출물만 추출
4. feature별: `_generated/by-feature/Lobby.md` → 크로스팀 feature 관점

---

## 5. Conventional Commit 추적 체크리스트

Phase별 커밋 prefix와 검증 커맨드:

- [ ] **Phase 0** — `chore(migration): Phase 0 설계 산출물 9개 — v10 재설계 도구 + 정책`
  - 검증: `python tools/migrate_docs_v10.py --phase=2 --dry-run`
  - 검증: `python tools/wsop_alignment_check.py`

- [ ] **Phase 1** — `feat(scope-guard): v5 path 규칙 + EBS_SCOPE_GUARD_VERSION flag`
  - 검증: `.claude/hooks/pre_tool_guard.py` 단위 테스트

- [ ] **Phase 2** — `refactor(docs): Conductor 영역 이주 — contracts+docs→docs v10`
  - 검증: `python tools/validate_links.py --scope=conductor`

- [ ] **Phase 3-1** — `refactor(team1): specs/ui-design/qa → docs/2. Development/2.1 Frontend/`
- [ ] **Phase 3-2** — `refactor(team2): specs/qa → docs/2. Development/2.2 Backend/`
- [ ] **Phase 3-3** — `refactor(team3): specs/qa → docs/2. Development/2.3 Game Engine/`
- [ ] **Phase 3-4** — `refactor(team4): specs/ui-design/qa → docs/2. Development/2.4 Command Center/`
  - 각 팀 검증: `python tools/validate_links.py --scope=team{N}`
  - 각 팀 검증: `python tools/find_by_legacy.py <대표 ID>` 결과 확인

- [ ] **Phase 4** — `docs(root): CLAUDE.md + README.md v10 경로 반영`

- [ ] **Phase 5** — `ci: spec-aggregate + validate-links + wsop-alignment workflows`

- [ ] **Phase 6** — `chore(cleanup): 빈 폴더 제거 (contracts/, specs/, ui-design/, qa/)`

---

## 6. 산출물 참조

| 파일 | 용도 |
|------|------|
| `contracts/migration/path-mapping.csv` | old → new 전수 매핑 (~200 행) |
| `contracts/migration/team-policy-v5.json` | v10 경로 기반 SSOT |
| `contracts/migration/team-policy-v4-backup.json` | 롤백용 |
| `tools/migrate_docs_v10.py` | 이주 실행 |
| `tools/spec_aggregate.py` | `_generated/` 자동 생성 |
| `tools/validate_links.py` | 상대 링크 무결성 |
| `tools/find_by_legacy.py` | 레거시 ID → 신규 경로 |
| `tools/wsop_alignment_check.py` | WSOP LIVE 정렬 검증 |
