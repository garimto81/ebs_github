---
title: Multi-Session Orchestration Design v10.3
status: SUPERSEDED
superseded_by: docs/4. Operations/Multi_Session_Design_v11.md
superseded_at: 2026-05-08
superseded_reason: "Message Bus 통합 (PR #195) → push 기반 v11 전환 (Phase A/B/C 머지: PR #197/#198/#199)"
last-updated: 2026-05-08
owner: conductor
tier: internal
provenance:
  triggered_by: user_directive
  trigger_summary: "v10.3 멀티 세션 자율 시스템 + 글로벌 스킬화"
  user_directive: |
    "orchestrator 가 멀티 세션을 시작할 폴더까지 지정 / 작업 시작하기 전까지
     orchestrator 가 모든 것을 관할하여 완벽하게 사전 설계 / 실제 작업이 진행
     될 때는 철저하게 모니터링만"
  trigger_date: "2026-05-07"
predecessors:
  - path: docs/4. Operations/Multi_Session_Workflow.md
    relation: superseded_partially
    reason: v10.3 패러다임 (Architect-then-Observer)으로 진화
  - path: docs/2. Development/2.5 Shared/team-policy.json
    relation: continued
    reason: SCOPE 매트릭스 보존, Phase 게이트 추가
---

## Edit History

| 날짜 | 버전 | 트리거 | 변경 |
|------|:----:|--------|------|
| 2026-05-07 | v10.3.0 | 사용자 directive — 멀티 세션 v10.3 | 최초 작성 (글로벌 orchestrator 스킬 v10.3 적용) |
| 2026-05-08 | v10.3.1 | 정합성 감사 #168 Phase A | S7/S8 활성화 반영 — §1 6 Streams → 8 Streams. S9 (QA) 만 future_streams 잔존. |
| 2026-05-08 | v10.3.2 | v11 머지 (Phase A~C, PR #197/#198/#199) | **SUPERSEDED by v11**. v10.3 polling path 는 v11 의 legacy fallback (broker dead 시) 으로 보존. 신규 작업은 v11 spec 참조. |

## 🎯 Thesis

> **Architect-then-Observer**: Orchestrator는 Phase 0에서 모든 것을 사전 설계 + 사전 세팅한 뒤, Phase 1+에는 GitHub 모니터링만 한다. 사용자 진입점은 VSCode 폴더 클릭 1회.

## Reader Anchor

이 문서는 EBS 멀티 세션 운영 SSOT입니다. 입구(현재 단일 세션 + 가끔 worktree 분리) → 출구(6 Stream 자율 워크트리 병렬 + Orchestrator 모니터링).

> **Phase 모델**: Phase 0 Architect Setup → Phase 1+ Observer Operation. 멀티세션 프로젝트 생명주기 단일 모델.

---

## §1. 8 Streams 매트릭스 (S7/S8 활성화 2026-05-08)

상세 SSOT: [`team_assignment_v10_3.yaml`](./team_assignment_v10_3.yaml)

```
+------+------------------+----------------------------+--------+----------+
| ID   | 이름              | 흡수 폴더                  | Phase  | 의존     |
+------+------------------+----------------------------+--------+----------+
| S1   | Foundation       | (없음, 신설)                | P1     | -        |
| S2   | Lobby Stream     | team1-frontend/            | P2+P5  | S1       |
| S3   | CC Stream        | team4-cc/                  | P2+P5  | S1       |
| S4   | RIVE Standards   | (없음, 신설)                | P2     | S1       |
| S5   | AI Track         | (tools/ai_track 신설)       | P3     | S1       |
| S6   | Prototype        | integration-tests/         | P3     | S2,S3,S4 |
| S7   | Backend Stream   | team2-backend/             | P2+P5  | S1       |
| S8   | Engine Stream    | team3-engine/              | P2+P5  | S1       |
+------+------------------+----------------------------+--------+----------+

미래 동적 추가:
| S9   | QA               | (ebs-qa)                   | P4     | All      |
```

**S7/S8 활성화 출처** (2026-05-08): 정합성 감사 #168 Phase 0 dispatch (Issue #166 + #174 + PR #175 / Issue #167 + PR #180). ownership 이관 (Back_Office_PRD → S7, Game_Rules → S8) 은 별도 후속 작업 — 현재 S1 interim 보존.

## §1.5 Product = SSOT, Cascade Routing

`docs/1. Product/` = **기준 SSOT**. 모든 Stream 이 Product 의 자기 영역만 수정 + 다른 영역 read.

상세 매핑: [`Stream_Entry_Guide.md` §Product 영역 매핑](../2. Development/2.5 Shared/Stream_Entry_Guide.md). 정책 SSOT: [`Product_SSOT_Policy.md`](../1. Product/Product_SSOT_Policy.md).

### Cascade Routing 4 Layer

| Layer | 도구 / 파일 | 역할 |
|:-----:|------------|------|
| L1 | PRD frontmatter `derivative-of` + `if-conflict` | 정본 ↔ derivative 관계 선언 |
| L2 | `tools/doc_discovery.py --impact-of` | reverse-graph (변경 대상의 영향 list) |
| L3 | `orch_PreToolUse.py:cascade_advisory()` | hook 으로 Edit 직전 advisory 출력 |
| L4 | `.github/workflows/scope_check.yml` | CI gate (Product Edit + derivative 동시 변경 강제) |

**Edit 흐름 예시**:

```
S1 워크트리에서 Foundation.md Edit 시도
   ↓
orch_PreToolUse.py
   ├─ Layer 3 scope check: S1 의 owner 인가 → ✓
   └─ Layer 2 cascade advisory:
       "Editing Foundation.md may affect:
         - Lobby_PRD.md (derivative cascade, S2 영역)
         - Command_Center_PRD.md (derivative cascade, S3 영역)
         - Back_Office_PRD.md (derivative cascade, S1 interim)
         - 3 정본 (Lobby/CC/BO Overview.md, 각 Stream P5 영역)"
   ↓
Edit 진행 → commit → PR
   ↓
Layer 4 scope_check.yml
   └─ Product 동시 변경 검증 (미동기화 PRD = WARN)
```

## §2. Architect-then-Observer 모델

```
                Phase 0
          [Architect Mode]
                 │
                 │  Orchestrator: 90분 자율
                 │  - 설계서 + 도구 + GitHub 인프라
                 │  - 6 워크트리 폴더 + 모든 파일 사전 세팅
                 │
                 v
          +------------------+
          | 게이트            |
          | - 산출물 검증      |
          | - 사용자 검토 1회  |
          +--------+---------+
                   │
                   v
                Phase 1+
          [Observer Mode]
                 │
                 │  Orchestrator: 영구 모니터링
                 │  - gh pr/issue list 30s 폴링
                 │  - 의존성 위반 감지
                 │  - 사용자 동적 요청 처리
                 │
                 v
          (영구 자율 cycle)
```

## §3. 6 워크트리 폴더 사전 지정

```
C:/claude/ebs-foundation/        ← S1
C:/claude/ebs-lobby-stream/      ← S2 (team1-frontend 흡수)
C:/claude/ebs-cc-stream/         ← S3 (team4-cc 흡수)
C:/claude/ebs-rive-standards/    ← S4
C:/claude/ebs-ai-track/          ← S5
C:/claude/ebs-prototype/         ← S6 (integration-tests 흡수)
```

각 폴더에 사전 세팅된 파일:
```
.team                          (Layer 2: Stream identity SSOT)
CLAUDE.md                      (Layer 3: 워크트리-local 가이드)
START_HERE.md                  (사용자 첫 화면)
.claude/
  ├── settings.local.json      (hook 활성화)
  └── hooks/
      ├── SessionStart.py      (Layer 4)
      └── PreToolUse.py        (Layer 5)
.vscode/settings.json
```

## §4. 6중 다층 방어 (Identity + Scope)

| Layer | 메커니즘 | 강제 시점 |
|:-:|---------|---------|
| 1 | 워크트리 경로 패턴 | 진입 시 |
| 2 | `.team` 메타 파일 | 진입 시 |
| 3 | 워크트리 CLAUDE.md | LLM context |
| 4 | SessionStart hook | 세션 시작 |
| 5 | PreToolUse hook | Edit/Write 직전 |
| 6 | GitHub 인프라 | PR 생성/머지 |

상세: 글로벌 스킬 `~/.claude/skills/orchestrator/references/6-layer-defense.md`

## §5. Phase 게이트 (시간차 SCOPE)

```
S2 Lobby Stream:
  P2 (기획):
    write: docs/2.1/Lobby/, docs/1./Lobby_PRD.md
    blocked: team1-frontend/src/    ← P5에서 unlock
  P5 (코드, 사용자 동적 요청 시):
    write: team1-frontend/, docs/2.1/Lobby/
```

→ 같은 Stream이 Phase에 따라 SCOPE 자동 확장. 새 워크트리 안 만들고 unlock만.

## §6. 사용자 워크플로우

```
1. 사용자: VSCode에서 워크트리 폴더 열기
   → C:/claude/ebs-foundation/  (예: S1부터)
   
2. 자동 발생:
   - SessionStart hook → identity 주입
   - START_HERE.md 화면에 표시
   - .team context 자동 로드
   
3. 사용자: "작업 시작"
   → tools/orchestrator/team_session_start.py 자동 실행
   → GitHub Issue + Draft PR 자동 생성
   
4. 작업 진행 (PreToolUse hook이 SCOPE 강제)
   
5. 사용자: "작업 완료"
   → tools/orchestrator/team_session_end.py 자동 실행
   → PR ready + auto-merge + branch 삭제
   
6. 다른 Stream으로 전환 (또는 병렬 진행):
   - VSCode 새 창에서 다른 워크트리 폴더 열기
   - 이전 Stream의 PR이 머지되면 의존 Stream 자동 unblock
```

## §7. 동적 추가 패턴

사용자: "Backend 코드 시작" 또는 "QA 추가"

→ Orchestrator (Observer → Architect 일시 전환):
1. team_assignment_v10_3.yaml의 future_streams.S7 → streams.S7 활성화
2. setup_stream_worktree.py --stream=S7 실행
3. GitHub 인프라 갱신
4. 사용자 보고: "S7 Backend Stream 폴더 준비. VSCode에서 열기"

## §8. Orchestrator 도구

위치: `tools/orchestrator/`

| 도구 | 호출자 | 역할 |
|------|-------|------|
| `team_session_start.py` | Stream 세션 (자동) | issue + draft PR |
| `team_session_end.py` | Stream 세션 (자동) | PR ready + auto-merge |
| `setup_stream_worktree.py` | Orchestrator | 워크트리 폴더 + 파일 세팅 |
| `orchestrator_monitor.py` | Orchestrator | GitHub 폴링 |
| `analyze_repo.py` | Orchestrator (1회) | 프로젝트 분석 |

## §9. 글로벌 스킬과의 관계

본 EBS 적용은 글로벌 `/orchestrator` 스킬의 첫 번째 사례. 모든 패턴은 보편화되어 다음 프로젝트 적용 가능.

글로벌 스킬: `~/.claude/skills/orchestrator/`
- 모든 프로젝트에서 자동 로드
- EBS는 기존 매트릭스(이 yaml) 발견 → 자동 추론 스킵
- 다른 프로젝트는 폴더 스캔 → 매트릭스 추론 → 사용자 1회 검토

## §10. v10.3 → 향후 진화

| 버전 | 상태 | 트리거 |
|------|------|--------|
| v10.3 | ACTIVE | 2026-05-07 |
| v10.4 (예정) | 사용자 동적 갱신 시 | future_streams 활성화 |
| v11.0 (가능) | 패러다임 변경 시 | (미정) |

## §11. Implementation Status

본 spec 의 모든 패턴은 글로벌 orchestrator 스킬 v10.3 자산으로 ACTIVE.

| 패턴 | 상태 | 구현 |
|------|:----:|------|
| 6 Stream 워크트리 (sibling-dir) | **ACTIVE** | `setup_stream_worktree.py`, `analyze_repo.py`. S1~S6 모두 부트스트랩 완료 (`C:/claude/ebs-{stream}/`, work/sN/... branch). |
| Stream 세션 자동화 (Issue + Draft PR + auto-merge) | **ACTIVE** | `team_session_start.py`, `team_session_end.py` |
| Orchestrator 모니터링 (GitHub 폴링) | **ACTIVE** | `orchestrator_monitor.py` |
| 동적 Stream 추가 | **ACTIVE** | `dynamic_stream_activation.py` |
| Phase 게이트 검증 | **ACTIVE** | `phase_gate_validator.py` |
| 충돌 해결 | **ACTIVE** (Architect-then-Observer subsumes) | Phase 0 사전 설계로 충돌 차단. fallback = ssot_priority chain (`team-policy.json` `governance_model.conflict_resolution`) |
| 세션 identity 초기화 | **ACTIVE** | `.claude/hooks/orch_SessionStart.py` (151줄, 글로벌 `hook_templates/SessionStart.py` 적용) |
| Scope 가드 (다른 Stream 접근 차단) | **ACTIVE** | `.claude/hooks/orch_PreToolUse.py` (232줄, 글로벌 `hook_templates/PreToolUse.py` 적용) |
| Stream 모드 전환 | **ACTIVE** (자동) | 워크트리 폴더 진입 = identity 자동 (sibling-dir 경로 패턴 + `.team` 메타). 환경변수 / 수동 전환 불필요 |
| 충돌 audit | **ACTIVE** | GitHub Issue + Draft PR 라벨 기반 분산 audit (별도 registry 파일 불필요) |

**모든 패턴 ACTIVE**. 이전 세대 phantom 도구 분류 (`conflict_resolver.py` / `session_branch_init.py` / `branch_guard.py` / Mode A·B 자동전환 / `Conflict_Registry.md`) 는 글로벌 v10.3 자산이 동등 또는 우월한 패턴으로 subsume — 별도 신규 구현 불필요.

---

**Last verified**: 2026-05-07. 글로벌 스킬 SKILL.md와 정합성 검증 완료.
