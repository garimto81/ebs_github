---
title: EBS Governance Archive Index
archived-date: 2026-05-08
archived-by: CLAUDE.md SSOT 일원화 + 미니멀 재설계
ssot-after: 외부 spec 분리 (root CLAUDE.md v1.0.0 + team-policy.json v9.5 + Multi_Session_Design v10.3)
status: frozen
---

# Governance Archive (frozen 2026-05-08)

본 폴더는 EBS 거버넌스 진화 chain 의 폐기 문서 보존소.

**현행 분리 구조** (메인 지침 v1.0.0 모델 적용):

| 역할 | 파일 | 버전 | 비고 |
|------|------|------|------|
| 진입점 (모든 작업) | `C:/claude/ebs/CLAUDE.md` | v1.0.0 | 5 섹션 미니멀 (Safety / Language / Git / Build & Run / Context Loading) |
| 운영 거버넌스 (실체) | `docs/2. Development/2.5 Shared/team-policy.json` | v9.5 | Single Session AI-Centric. 실제 동작 중 |
| Conductor SOP | `docs/4. Operations/Workflow_Conductor_Autonomous.md` | — | Hourglass 패턴, T/I/C 결정 분류 |
| 멀티세션 spec | `docs/4. Operations/Multi_Session_Design_v10.3.md` + `team_assignment_v10_3.yaml` | v10.3 | 6 Stream worktree + orchestrator 도구 |
| 본 archive | `docs/_archive/governance-2026-05/` | — | 진화 chain 보존 (v9.2~v9.5 + V5 마이그레이션 + SG-024 + DEPENDABOT) |

## 폐기 거버넌스 문서 (7개)

| 파일 | 폐기일 | 폐기 사유 | superseded_by | 복원 명령 |
|------|--------|-----------|---------------|-----------|
| V9_2_Gate_Design.md | 2026-05-08 | v9.3+ 에서 supersede | CLAUDE.md §3 (v10.3 거버넌스) | `git mv "docs/_archive/governance-2026-05/V9_2_Gate_Design.md" "docs/4. Operations/"` |
| V9_3_Intent_Execution_Boundary.md | 2026-05-08 | v9.4 → v10.3 chain 상위 supersede | CLAUDE.md §3 | `git mv "docs/_archive/governance-2026-05/V9_3_Intent_Execution_Boundary.md" "docs/4. Operations/"` |
| V9_4_AI_Centric_Governance.md | 2026-05-08 | v9.5 → v10.3 흡수 | CLAUDE.md §3 + §2 (Core Philosophy AI-Centric Zero-Friction) | `git mv "docs/_archive/governance-2026-05/V9_4_AI_Centric_Governance.md" "docs/4. Operations/"` |
| V9_5_Single_Session_Output_Centric.md | 2026-05-08 | v10.3 으로 흡수 (Mode A 단일 세션 + Hourglass workflow) | CLAUDE.md §3 + Workflow_Conductor_Autonomous.md | `git mv "docs/_archive/governance-2026-05/V9_5_Single_Session_Output_Centric.md" "docs/4. Operations/"` |
| V5_Migration_Plan.md | 2026-05-08 | 2026-04-22 마이그레이션 완료 (영구 폐기 가능) | (없음 — 역사 기록 only) | `git mv "docs/_archive/governance-2026-05/V5_Migration_Plan.md" "docs/4. Operations/"` |
| SG-024-governance-expansion.md | 2026-05-08 | 결정 완료 (Mode A 채택) | CLAUDE.md §3 | `git mv "docs/_archive/governance-2026-05/SG-024-governance-expansion.md" "docs/4. Operations/Conductor_Backlog/"` |
| DEPENDABOT_GOVERNANCE.md | 2026-05-08 | team-policy.json 으로 통합 권장 | docs/2. Development/2.5 Shared/team-policy.json | `git mv "docs/_archive/governance-2026-05/DEPENDABOT_GOVERNANCE.md" "docs/4. Operations/"` |
| Workflow_Conductor_Autonomous.md | 2026-05-08 | 단일 turn workflow 모델 폐기. v10.3 멀티세션 (Architect-then-Observer) 단일 운영 | Multi_Session_Design_v10.3.md + team-policy.json | `git mv "docs/_archive/governance-2026-05/Workflow_Conductor_Autonomous.md" "docs/4. Operations/"` |
| Phase_1_Decision_Queue.md | 2026-05-08 | V9.5 Phase 1 결정 SSOT. v10.3 단일화로 무관 | (해당 결정은 모두 적용 완료, 이력 only) | `git mv "docs/_archive/governance-2026-05/Phase_1_Decision_Queue.md" "docs/4. Operations/"` |
| Multi_Session_Handoff.md | 2026-05-08 | V9.5 이관 지침. v10.3 = Stream_Entry_Guide.md 가 진입 SSOT | docs/2. Development/2.5 Shared/Stream_Entry_Guide.md | `git mv "docs/_archive/governance-2026-05/Multi_Session_Handoff.md" "docs/4. Operations/"` |

## CLAUDE.md 변경 이력 (본 파일에서 제거 후 흡수)

기존 CLAUDE.md 의 Role 섹션에 있던 변경 이력 표를 본 INDEX 로 흡수.

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-05-08 | Foundation 자체 정합 + Issue #156 (PR I, #158) | Foundation 본문 "8 액션" 잔재 4곳 정정 → "6 키 (N·F·C·B·A·M)". Foundation Changelog v4.5.0 entry 추가 + Scene 개수 정정. Lobby_PRD "8 버튼 액션" + Fixed 6h 정정. BO_PRD outdated 절번호 일괄 정정 (§Ch.4.2 → Ch.4 Scene 1 / §Ch.6.X → Ch.5 §B.X / §Ch.8.5 → Ch.6 Scene 4 / §Ch.1.4 → Ch.1 Scene 4 / §6.4 NFR → Foundation §Ch.5 §B.4) + version 1.0.1→1.1.0 통일. RIVE Ch.2 "8 vs 11 차이" 박스. Product_SSOT_Policy last-updated 추가. Issue #156 closed (16건 중 12건 ✓, 4건 = 1. Product.md CI generated 자동 갱신). |
| 2026-05-08 | Product 100% 정합 (PR H, #157) | Foundation v4.4 → v4.5 (D2 Hole Card Visibility 4단 방어 + D3 Lobby 4 진입 시점 + D5 Mixed Game HORSE/8-Game 흡수). 3 PRD last-synced 갱신 (D1). Lobby/BO PRD rive-role 명시 (D7). Flop_Games "Foundation Ch 참조" 제거 (D4). Draw.md Pre-Draw/Post-Draw 라벨 (D6). References frontmatter referenced-by (D8). archive frontmatter archived: true + superseded-by (D9). 정합도 95% → **100%**. |
| 2026-05-08 | Cascade 정합 완성 (PR G) | Lobby_PRD related-docs 에 Foundation.md 추가 (cascade 시뮬 누락 정정). 3 PRD 모두 frontmatter 에 `last-synced: 2026-04-15` 추가 (정본 ref, 역방향 drift 정직 표기). `.github/workflows/product_cascade.yml` 신규 — Product 변경 PR 시 cascade impact advisory 출력 + 정본 변경 시 derivative PRD 동시 갱신 권고. |
| 2026-05-08 | Product SSOT 동기화 (PR F) | Product 폴더 = 기준 SSOT 명시. team_assignment_v10_3.yaml 갱신 (S1 scope_owns 확장 BO_PRD + Game_Rules / S4 path 정정 docs/2.5 Shared → docs/1. Product / S2,S3,S6 scope_read 에 RIVE_Standards / References/** 모든 Stream read / 1. Product.md meta_files_blocked). Stream_Entry_Guide.md Product 매핑 표 + cascade chain 추가. Multi_Session_Design §1.5 신설 (cascade 4 Layer). Product_SSOT_Policy.md 신규 (docs/1. Product/, derivative-of 룰 + Stream 책임 매트릭스 + 검증 명령). drift 5건 (D1~D5) 모두 해소. |
| 2026-05-08 | 워크트리 부트스트랩 완료 (PR E) | S6 Prototype Stream 워크트리 등록 (`C:/claude/ebs-prototype` ↔ `work/s6/2026-05-08-init`) + 자산 배치 (.team, START_HERE.md, .vscode). S1~S5 사용자 측 완료. 6 Stream 모두 ACTIVE. Multi_Session_Design §11 갱신 (Layer 1~2 ACTIVE). setup_stream_worktree.py 폴더 판정 bug fix (.git 부재 검증 추가). |
| 2026-05-08 | 단일 turn workflow 폐기 (PR D) | Workflow_Conductor_Autonomous.md (198줄), Phase_1_Decision_Queue.md (738줄), Multi_Session_Handoff.md (279줄) 3 파일 archive 이동. v10.3 = 멀티세션 Architect-then-Observer 단일 모델. Phase 모델 disambiguation 제거 (다른 차원 자체가 사라짐). team1/team2 CLAUDE.md → Stream_Entry_Guide.md redirect. |
| 2026-05-08 | 워크플로우 완성 (PR C) | Stream_Entry_Guide.md 신규 (docs/2.5 Shared, ~150줄). 6 Stream 진입 가이드 + 공유 contract 충돌 SOP (Phase 0 차단 + ssot_priority fallback) + 동적 Stream 추가 (S7~S9) + 6중 방어 매핑. doc2 진입점 결함 (H2) + 공유 contract SOP 결함 (H3) 해소. root CLAUDE.md Context Loading 표 갱신. |
| 2026-05-08 | Spec 정합 (PR B) | Multi_Session_Design_v10.3.md §11 재작성 (TBD 5개 → 모두 ACTIVE, 글로벌 v10.3 자산 subsume 명시). 두 SOP 문서에 Phase 모델 disambiguation 추가 (멀티세션 생명주기 Phase ↔ 단일 turn workflow Phase 분리). |
| 2026-05-08 | v10.3 단일화 (운영 SSOT, PR A) | team-policy.json v9.5 → v10.3 전면 재작성 (Architect-then-Observer 모델, 365→279줄). v9.x narrative 모두 제거. Phantom 도구 5개 = 글로벌 v10.3 자산 (SessionStart.py / PreToolUse.py / Architect-then-Observer 패턴 / GitHub Issue+PR 라벨) 으로 대체 명시. Multi_Session_Workflow.md V9.5 본문 → v10.3 redirect stub. |
| 2026-05-08 | root CLAUDE.md v1.0.0 미니멀 재설계 (2차) | 메인 지침 모델 적용. 239 → 55줄 (79% 추가 감축). 5 섹션 (Safety / Language / Git / Build & Run / Context Loading). Phantom 룰 7개 본문 제거 (도구 부재 5: conflict_resolver/session_branch_init/branch_guard/Mode 자동전환/Conflict_Registry + V9.5 폐기 패턴 2: /team-merge, work/team{N}). 시간 narrative 제거. 거버넌스 라벨 외부 spec 분리. |
| 2026-05-08 | CLAUDE.md SSOT 1차 슬림화 | 7개 폐기 거버넌스 문서 → 본 archive. 427 → 239줄. Mode A/B 중복 정의 통합. v9.x narrative 제거. |
| 2026-04-29 | (인텐트 명시) | 협업 메커니즘 정의 — 비전문 개발자 사용자 × AI 전문 기술. 결과물 = 기획 문서 + 프로토타입 2가지. (CLAUDE.md §1 보존) |
| 2026-04-28 | SG-028 | Mode B autonomous_llm_judgment default. conflict_resolver.py 4-Step Decision Logic. (v10.3 흡수, V9_5 → archive) |
| 2026-04-27 | SG-024 | Mode A 단일 세션 Conductor 전권. (v10.3 흡수, SG-024 → archive) |
| 2026-04-22 | (Docker 사고) | "Desktop 단일 스택" 해석 사고 → Docker_Runtime.md SSOT 강화. (CLAUDE.md §5 보존) |
| 2026-04-17 | v6.0.0 (docs v11) | CCR 완전 폐기. 3 홈 폴더 (1 Product / 2 Development / 4 Operations). free_write_with_decision_owner v7. |
| 2026-04-15 | v5.0.0 (docs v10) | 단일 docs/ 원칙. contracts/, 01-strategy, 05-plans, team*/specs\|ui-design\|qa 폐지. |
| 2026-04-10 | v4.0.0 | 5팀 구조 (Conductor + team1~4) 확정. |

## 검색 키워드 (재발견용)

본 INDEX 가 추후 grep / Doc Discovery 로 검색되도록:

`v9.5` `v9.4` `v9.3` `v9.2` `v8.0` `v7.5` `v7.1` `v7` `v6.0.0` `v5.0.0` `v4.0.0` `CCR` `Change Request Round` `decision_owner v7` `Gate_Design` `Intent_Execution_Boundary` `AI_Centric_Governance` `Single_Session_Output_Centric` `V5_Migration` `V5 Migration` `Migration_Plan` `SG-024` `governance-expansion` `DEPENDABOT_GOVERNANCE` `Dependabot governance`

## 복원 정책

- 본 폴더 문서는 **참조 전용**. 활성 거버넌스로 사용 금지.
- 복원이 필요한 경우:
  1. 사유 명시 (왜 v10.3 이 부족한지)
  2. CLAUDE.md §3 (v10.3) 와의 호환성 검증
  3. 위 표의 복원 명령 실행
  4. CLAUDE.md 의 supersede 표기 갱신
  5. 본 INDEX.md 의 해당 행에 `restored: YYYY-MM-DD` 표시
- 본 INDEX.md 는 git history 와 함께 **영구 보관**. 삭제 금지.

## 관련 문서 (잔존 SSOT)

| 역할 | 경로 |
|------|------|
| 거버넌스 root SSOT | `C:/claude/ebs/CLAUDE.md` |
| 팀 권한 SSOT | `docs/2. Development/2.5 Shared/team-policy.json` |
| 멀티세션 기술 spec | `docs/4. Operations/Multi_Session_Design_v10.3.md` |
| 스트림 할당 | `docs/4. Operations/team_assignment_v10_3.yaml` |
| Conductor 운영 SOP | `docs/4. Operations/Workflow_Conductor_Autonomous.md` |
