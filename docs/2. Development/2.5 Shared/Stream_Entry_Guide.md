---
title: Stream Entry Guide (v10.3 멀티세션 진입)
owner: conductor
tier: contract
governance: v10.3 architect_then_observer
confluence-page-id: 3818586623
confluence-parent-id: 3812032646
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818586623/EBS+Stream+Entry+Guide+v10.3
related-spec:
  - ../2.1 Frontend/Lobby/Overview.md
  - ../2.2 Backend/Back_Office/Overview.md
  - ../2.3 Game Engine/Rules/Multi_Hand_v03.md
  - ../2.4 Command Center/Command_Center_UI/Overview.md
mirror: none
---

# Stream Entry Guide — v10.3

EBS 멀티세션은 Stream 단위로 분리된다. 사용자 진입점 = VSCode 에서 sibling worktree 폴더 1회 클릭.

상세 spec: `docs/4. Operations/Multi_Session_Design_v10.3.md` + `team_assignment_v10_3.yaml`.

## Product 영역 매핑 (SSOT 기준)

`docs/1. Product/` = **기준 SSOT**. 모든 Stream 이 Product 의 자기 영역만 수정 + 다른 영역 read.

| Product 파일 / 폴더 | Owner Stream | Read Streams | Phase |
|--------------------|:-----------:|--------------|:-----:|
| `Foundation.md` | **S1** | S2~S8 (all) | P1 |
| `Lobby.md` | **S2** | S6 | P2 |
| `Command_Center.md` | **S3** | S6 | P2 |
| `Back_Office.md` | **S1** (interim — S7 활성됨 2026-05-08, ownership 이관 PR #175 머지 후) | S2, S3, S7 | P1 |
| `RIVE_Standards.md` | **S4** | S2, S3, S6 | P2 |
| `Game_Rules/**` (4) | **S1** (interim — S8 활성됨 2026-05-08, ownership 이관 PR #180 머지 후) | S2, S3, S6, S8 | P1 |
| `References/**` (2) | conductor (frozen) | All | — |
| `images/`, `visual/`, `archive/` | conductor (asset) | All | — |
| `1. Product.md` (landing) | CI generated | — | meta |

### Product cascade chain

Product 파일 Edit 시 영향 받는 derivative 자동 advisory (`tools/doc_discovery.py --impact-of` + `orch_PreToolUse.py:cascade_advisory()`):

```
Foundation.md Edit
   ↓ cascade
   ├─ Lobby.md (derivative-of Lobby Overview)
   ├─ Command_Center.md (derivative-of CC Overview)
   ├─ Back_Office.md (derivative-of BO Overview)
   ├─ docs/2. Development/2.1 Frontend/Lobby/Overview.md (정본)
   ├─ docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md (정본)
   └─ docs/2. Development/2.2 Backend/Back_Office/Overview.md (정본)
```

외부 인계 PRD ↔ 정본 동기화 룰: `derivative-of: ../<정본>.md` + `if-conflict: derivative-of takes precedence`. 정본 변경 시 PRD 동시 갱신 필수.

---

## Stream 매트릭스

| ID | 이름 | 워크트리 | 흡수 폴더 | Phase | 의존 |
|----|------|----------|-----------|:-----:|:----:|
| **S1** | Foundation | `C:/claude/ebs-foundation/` | (신설) | P1 | — |
| **S2** | Lobby Stream | `C:/claude/ebs-lobby-stream/` | `team1-frontend/` | P2+P5 | S1 |
| **S3** | Command Center Stream | `C:/claude/ebs-cc-stream/` | `team4-cc/` | P2+P5 | S1 |
| **S4** | RIVE Standards | `C:/claude/ebs-rive-standards/` | (신설) | P2 | S1 |
| **S5** | AI Track Restructuring | `C:/claude/ebs-ai-track/` | (`tools/ai_track/` 신설) | P3 | S1 |
| **S6** | Prototype Stream | `C:/claude/ebs-prototype/` | `integration-tests/` | P3 | S2, S3, S4 |
| **S7** | Backend Stream | `C:/claude/ebs-backend-stream/` | `team2-backend/` | P2+P5 | S1 (활성화: 2026-05-08) |
| **S8** | Engine Stream | `C:/claude/ebs-engine-stream/` | `team3-engine/` | P2+P5 | S1 (활성화: 2026-05-08) |
| S9 (future) | QA Stream | `C:/claude/ebs-qa/` | (신설) | P4 | (사용자 trigger) |

## Stream 별 진입 가이드

### 공통 진입 절차

1. VSCode 에서 워크트리 폴더 열기 (sibling-dir)
2. 새 Claude Code 세션 시작 → `.claude/hooks/orch_SessionStart.py` 가 identity 자동 부여
3. 워크트리 root 의 `START_HERE.md` 읽기
4. Stream 세션 시작: `python tools/orchestrator/team_session_start.py --stream=SN --title='<제목>'`
   - 자동 GitHub Issue + Draft PR 생성
5. 작업 수행 (scope_owns 영역만, `orch_PreToolUse.py` 가 다른 영역 차단)
6. Stream 세션 종료: `python tools/orchestrator/team_session_end.py --message='<요약>'`
   - auto-merge enabled, branch 자동 삭제

### S1 — Foundation (P1)

- **읽을 문서**: root `CLAUDE.md` / `docs/1. Product/Foundation.md` / `docs/4. Operations/Multi_Session_Design_v10.3.md`
- **scope_owns**: `docs/1. Product/Foundation.md`
- **scope_read**: `docs/1. Product/References/**`
- **출구 조건**: Foundation.md PR 머지 → S2~S6 unblock

### S2 — Lobby Stream (P2 → P5)

- **선행**: S1 P1 완료
- **P2 (기획)**: `scope_owns` = `docs/2. Development/2.1 Frontend/Lobby/`, `docs/1. Product/Lobby.md`
- **P5 (구현)**: `scope_owns` = `team1-frontend/`, `docs/2. Development/2.1 Frontend/Lobby/`
- **읽을 문서**: `team1-frontend/CLAUDE.md` / `docs/2. Development/2.1 Frontend/Lobby/Overview.md` / `docs/1. Product/Lobby.md` / `Foundation.md`
- **api_subscribes**: Backend_HTTP, WebSocket_Events, Auth_and_Session
- **공유 contract 충돌 주의**: API-04 Overlay (team3 publisher), RFID_HAL (team4 publisher)

### S3 — Command Center Stream (P2 → P5)

- **선행**: S1 P1 완료
- **P2 (기획)**: `scope_owns` = `docs/2. Development/2.4 Command Center/`, `docs/1. Product/Command_Center.md`
- **P5 (구현)**: `scope_owns` = `team4-cc/`, `docs/2. Development/2.4 Command Center/`
- **읽을 문서**: `team4-cc/CLAUDE.md` / `docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md` / `docs/1. Product/Command_Center.md`
- **api_subscribes**: Overlay_Output_Events, WebSocket_Events
- **api_publishes**: RFID_HAL

### S4 — RIVE Standards (P2)

- **선행**: S1 P1 완료
- **scope_owns**: `docs/2. Development/2.5 Shared/RIVE_Standards.md`, `docs/2. Development/2.5 Shared/RIVE_Event_Protocol.md` (둘 다 신설 대상)
- **scope_read**: `docs/1. Product/Foundation.md`
- **출구 조건**: 두 파일 PR 머지 → S2/S3/S6 가 RIVE 표준 참조 가능

### S5 — AI Track Restructuring (P3)

- **선행**: S1 P1 완료
- **scope_owns**: `tools/ai_track/**` (신설), `docs/_generated/**`
- **scope_read**: `docs/2. Development/**`, `docs/4. Operations/**`

### S6 — Prototype Stream (P3)

- **선행**: S2 + S3 + S4 모두 P2 완료
- **scope_owns**: `docs/4. Operations/Prototype_Build_Plan.md`, `integration-tests/**`
- **scope_read**: `docs/1. Product/**`, `docs/2. Development/**`

## 공유 contract 충돌 SOP

여러 Stream 이 동일 contract 파일 수정 가능한 시나리오:

| Contract (legacy_id) | Publisher | Subscribers | 동시 편집 가능 Stream |
|----------------------|-----------|-------------|----------------------|
| Backend_HTTP (API-01) | team2 | team1, team4 | S2 / S3 (consumer) ↔ S7 (publisher) |
| WebSocket_Events (API-05) | team2 | team1, team3, team4 | S2 / S3 / S6 ↔ S7 |
| Auth_and_Session (API-06) | team2 | team1 | S2 ↔ S7 |
| Overlay_Output_Events (API-04) | team3 | team4 | S3 (consumer) ↔ S8 (publisher) |
| RFID_HAL (BS-04-04) | team4 | team1 | S2 (consumer) ↔ S3 (publisher 입장) |
| Graphic_Editor_API (API-07) | team2 | team1, team4 | S2 / S3 ↔ S7 |
| Database Schema (DATA-04) | team2 | team1, team3, team4 | S2 / S3 / S6 ↔ S7 |

### 충돌 차단 (Phase 0 Architect 책임)

Architect-then-Observer 모델의 핵심: **Phase 0 사전 설계로 충돌 차단**.

```
사용자 의도 → Architect 분석:
  ├─ contract 변경 필요? → publisher Stream 만 활성화
  ├─ contract subscribe 만? → consumer Stream 활성화 + 최신 contract pin
  └─ 양쪽 모두 변경? → 순차 진행 (publisher → consumer, 의존성 게이트)
```

### 충돌 발생 시 (fallback)

Phase 0 차단 실패 시 (드물게):

1. PR 에 `conflict` 라벨 자동 부여 (`orch_PreToolUse.py`)
2. `team-policy.json` `governance_model.conflict_resolution.ssot_priority` chain 적용:
   - Foundation.md > team-policy.json > Risk_Matrix > APIs > Backlog
   - **publisher Stream PR > consumer Stream PR** (publisher 가 contract 진실)
3. 판정 불가 시 Spec_Gap 등재 (`docs/4. Operations/Spec_Gap_Triage.md` Type C — 기획 모순)

## 동적 Stream 추가 (S9)

S7/S8 은 2026-05-08 정합성 감사 (#168) Phase 0 dispatch 로 활성화 완료. 잔여 future_streams 활성화 트리거:
- **S9 QA Stream**: "QA 추가" / "통합 테스트 보강"

활성화 시퀀스 (Orchestrator Observer → Architect 일시 전환):

1. `team_assignment_v10_3.yaml` `future_streams.SX → streams.SX`
2. `python tools/orchestrator/dynamic_stream_activation.py --stream=SX`
3. `python tools/orchestrator/setup_stream_worktree.py --stream=SX`
4. GitHub 인프라 갱신 (CODEOWNERS, ISSUE_TEMPLATE 등)
5. 사용자 보고: "SX 폴더 준비됨. VSCode 에서 열기"

## Stream 종료 / 외부 인계

모든 Stream 의 PR 머지 + 통합 테스트 (`integration-tests/`) 통과 = 외부 인계 시점.

산출물 = 기획 문서 (`docs/`) + 최종 프로토타입 (`team1~4/`).

## 진입 시 자동 적용되는 6중 방어

| Layer | 메커니즘 | 적용 시점 |
|:-----:|----------|----------|
| 1 | 워크트리 경로 패턴 (`C:/claude/ebs-{stream}/`) | 폴더 진입 시 |
| 2 | `.team` 메타 파일 (워크트리 root) | 폴더 진입 시 |
| 3 | 워크트리 `CLAUDE.md` (identity override) | LLM context 로드 |
| 4 | `.claude/hooks/orch_SessionStart.py` | 세션 시작 |
| 5 | `.claude/hooks/orch_PreToolUse.py` | Edit/Write 직전 |
| 6 | GitHub 인프라 (CODEOWNERS, scope_check.yml) | PR 생성 시 |
