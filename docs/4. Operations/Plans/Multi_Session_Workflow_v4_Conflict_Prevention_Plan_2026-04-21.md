---
title: Plan — Multi_Session_Workflow v4.0 Pre-Declaration 충돌 사전 방지 설계
owner: conductor
tier: internal
last-updated: 2026-04-21
reimplementability: PASS
reimplementability_checked: 2026-04-21
reimplementability_notes: "critic + 사용자 제안 통합 설계. Plan only (구현 대기)"
related:
  - docs/4. Operations/Multi_Session_Workflow.md v3.1
  - .claude/hooks/branch_guard.py v3.1
  - ~/.claude/skills/team/SKILL.md
---

# Plan — Multi_Session_Workflow v4.0 (Pre-Declaration 충돌 사전 방지)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-21 | 신규 작성 | 사용자 지시 — critic mode 로 v3.1 검토 + Pre-Declaration 충돌 방지 설계 (계획 단계, 구현은 승인 후) |
| 2026-04-21 | revision 1 | **설계 모델 전환**: Wait (대기) 모델 폐기 → **Exclude + Revise** (충돌 파일 제외 후 재설계) 로 교체. 사용자 지시: "충돌 시 해당 파일을 제외하고 작업하는 형태로 계획을 수정하여 재설계". Critic A/B + 자기반박 상세화 (이전 §3 보강) |
| 2026-04-21 | revision 2 | 최신 기술/트렌드 검증 (WebSearch 5종) 반영. §14 추가: Claude Code Agent Teams 공식 best practice, Cursor locking 실패 교훈, 5-Role 패턴, Kubernetes Lease, Git worktree 2026 표준화, Beads JSONL, Augment Intent workspace. v4.0 revision 1 재검증 결과 "업계 표준과 정렬, Wait fallback 축소 권고". |

## 1. 현재 상태 (v3.1 까지) 와 잔존 문제

### 1.1 v3.1 로 해소된 것

| 증상 | v3.1 해결 방법 |
|------|----------------|
| branch-guard 재경고 반복 | Override key 를 session_id 만 의존 |
| `git index.lock` 충돌 | `_wait_for_index_lock()` 100ms × 30회 |
| "다른 세션 탓인지 불명" 혼란 | Pinned branch 대조 → 경고문에 원인 힌트 |

### 1.2 v3.1 로도 해소 못 한 것 (치명적)

| # | 증상 | 실측 (이번 세션) | 근본 원인 |
|:-:|------|-------------------|-----------|
| 1 | 같은 파일을 다른 세션이 이미 수정 중 | "File has been modified since read, either by the user or by a linter" 다수 발생 | **충돌 사전 감지 메커니즘 없음** |
| 2 | `git add` 시 다른 세션 staged 변경 혼입 | 이번 /team commit 에 team2 `init.sql` · `hands.py` 등 포함됨 (의도 외) | **shared index 격리 없음** + add 범위 제어 부족 |
| 3 | Conductor HEAD 가 team branch 로 튕김 | 5+ 회 발생, v3.1 이 "원인 감지" 만 알려줌 | **subdir 세션의 공유 HEAD race** (근본 미해결) |
| 4 | 두 세션이 같은 문서 동시 편집 → 뒤 세션이 덮어씀 | Backend_HTTP.md / Tech_Stack.md modify-since-read race 관찰 | **쓰기 충돌 사전 차단 없음** |

### 1.3 공통 근본 원인

> **v3.0/3.1 은 "사후 복구" 모델**. 충돌이 발생한 후 감지·대기·retry 로 완화하지만, **작업 시작 시점에 충돌 가능성을 알 수 없음**. branch-guard/file-lock hook 은 tool 호출 단위 (파일 1개) 에서만 동작하며, 세션 전체 의도 (수정할 파일 집합) 를 알지 못함.

## 2. 사용자 제안 요약

```
/team 로 시작하면
  수정할 문서 파일 폴더 등의 목록을 구체적으로 먼저 작성한 후 진행하고,
  /team 을 시작할때 항상 이 문서를 모두 분석하고,
  자신이 수정할 문서와 충돌이 발생하는지 확인.
  충돌이 발생하는 경우 먼저 작업한 작업자가 작업을 종료할때까지 대기하고,
  다른 작업을 이행.
  각 세션별 json 파일을 생성하도록 하고
  /team 은 항상 5개의 파일을 읽도록 처리하여
  충돌을 사전에 방지하도록 설계
```

사용자 핵심 요구 4가지:
1. **Pre-Declaration**: /team 시작 시 수정 대상 목록 명시
2. **Cross-session scan**: 다른 세션의 매니페스트 전부 분석
3. **Wait-or-switch**: 충돌 시 먼저 세션 종료까지 대기
4. **세션별 JSON**: 각 세션의 manifest 를 JSON 으로 분리, /team 이 모두 읽음

## 3. Critic — 사용자 제안 교차 평가 (revision 1: Wait vs Exclude+Revise 비교)

### 3.1 Critic A (지지)

| 강점 | 논거 |
|------|------|
| **충돌을 사후가 아닌 사전에 감지** | v3.1 의 근본 한계 해결. branch-guard/file-lock 이 파일 1개 단위인데, manifest 는 세션 전체 scope |
| **세션 간 가시성 확보** | 현재는 다른 세션이 무엇을 하는지 commit log 로만 사후 확인. manifest 는 실시간 현황 |
| **사용자에게 선택권** | "대기할지 / 다른 작업 할지" 를 사용자가 결정 가능 |
| **구현 단순** | `.claude/.session-manifests/{sid}.json` 만 있으면 됨. 복잡한 lock-free 자료구조 불필요 |
| **WSOP LIVE / 산업 패턴 정렬** | distributed lock manifest 는 멀티 세션 IDE 플러그인의 표준 패턴 (JetBrains `.idea/workspace.xml`, VS Code Live Share 등) |

### 3.2 Critic B (반대)

| 약점 | 논거 | 대응 |
|------|------|------|
| **"수정할 파일 목록을 먼저 작성" 은 LLM 이 예측 못 하는 경우 많음** | /auto 가 exploration 중에 추가로 파일을 발견하는 시나리오. PRD 수정 + 파급된 3팀 문서 수정 등 | Declaration 을 **wildcard glob** 허용 (`docs/2. Development/2.1 Frontend/**`), 실제 쓰기 시 manifest 실시간 확장 |
| **"5개 파일 고정" 은 경직** | 세션 수는 동적. Conductor + 4팀 = 5 라는 숫자가 미래에도 맞을지 불확실. 동시 2 Conductor 세션도 가능 | 고정이 아닌 **`.claude/.session-manifests/*.json` glob scan**. 파일 수는 자연스럽게 결정 |
| **"먼저 세션 종료까지 대기" 는 데드락 위험** | 세션 A 가 B 를 기다리고, B 가 A 기다리면 영원히 대기. 세션 죽으면 manifest 가 남아 유령 블로커 | **Heartbeat TTL** (1분 안 갱신되면 stale 로 간주) + **사이클 감지** (세션 시작 시각 기준 우선순위) |
| **읽기만 하는 세션도 충돌로 오판 가능** | 다른 세션이 편집 중인 파일을 읽기만 해도 대기 걸리면 과도 | **Read vs Write 구분** (planned_reads 는 충돌 판정 제외) |
| **/team 시작 지연** | Phase 0 Declaration + Phase 0.5 Scan 이 기존 8 Phase 에 추가되면 느려짐 | 경량 Python script (< 200ms). 사용자 입력 없이 자동 수행 |
| **JSON 파일 정리 누락 시 유령 세션** | /team 이 도중에 crash 하면 manifest 잔존 | **SessionEnd hook** + **atexit** + **heartbeat TTL expiry** 3중 정리 |

### 3.3 자기반박 (Critic 자체의 약점)

본 critic 이 과하게 낙관하거나 보수적인 부분을 공개한다:

1. **"WSOP LIVE / 산업 패턴" 근거는 약함** — 실제 EBS 스케일 (4팀 × 1-2 세션) 은 산업 scale 과 다름. 오버엔지니어링 위험.
2. **데드락 사이클 감지는 복잡** — 제안 "시작 시각 우선" 은 A-B-C 3 세션 사이클에서 fairness 문제. 실용적으로는 timeout 만으로 충분할 수 있음.
3. **Declaration 정확도 의존** — LLM 이 manifest 를 엉망으로 작성하면 충돌 판정 자체가 무의미. 실제 쓰기 시점 감지 (file_lock_preedit hook 연동) 가 backup 으로 필요.
4. **사용자 insight 를 100% 존중** — 5개 파일 고정 요구는 "5개 세션 = Conductor + 4팀" 의도이므로 존중. 동적 glob scan 은 5개 포함해서 자연스럽게 커버됨.
5. **새 hook 이 hook 지옥 만들 수 있음** — 이미 file_lock_preedit, active_edits_preedit 등 존재. 중복 방지 필요.
6. **완벽하게 처리 = 불가능** — 분산 시스템의 일반 진실. v4.0 은 "대부분의 충돌을 사전 방지 + 소수의 잔존 race 는 v3.1 의 사후 복구" 하이브리드.

### 3.4 혁신 제안 (revision 1, 2026-04-21) — Exclude + Revise 모델

> 사용자 재지시 (revision 1): "충돌이 발생하는 경우 **먼저 작업한 작업자가 작업을 종료할때까지 대기**" → "충돌 파일을 **제외하고 작업하는 형태로 계획을 수정하여 재설계**" 로 모델 전환.

두 모델의 본질적 차이:

| 차원 | Wait 모델 (초안 v4.0) | Exclude+Revise 모델 (revision 1) |
|------|:---------------------:|:--------------------------------:|
| 충돌 발견 시 동작 | Blocking wait + polling 5초 | 충돌 파일 제외 + task 재구성 + 즉시 진행 |
| Deadlock 위험 | 존재 (사이클 감지 필요) | **0** (대기 자체가 없음) |
| Timeout 처리 | 10분 후 user confirm | 불필요 |
| Task 완결성 | 유지 (원 scope 전체 수행) | **깨질 수 있음** (partial scope) |
| 사용자 대기 시간 | 최대 10분 blocking | **0** (즉시 진행) |
| 구현 복잡도 | 사이클/timeout 로직 필요 | 단순 (excluded set 계산) |
| LLM 요구 사항 | 없음 (단순 wait) | **task 재설계 능력** 필요 |
| 부분 작업 커밋 | 없음 | **Deferred list 관리** 필요 |

### 3.5 Critic — Exclude+Revise 모델

#### Critic A (지지)

| 강점 | 논거 |
|------|------|
| **Deadlock 완전 제거** | 대기가 없으므로 사이클 불가능 |
| **사용자 blocking 0** | 생산성 최대화. user UX 저하 없음 |
| **세션 독립성 극대화** | 각 세션이 서로 간섭 없이 병렬 진행 |
| **구현 단순** | 사이클 감지 / timeout / heartbeat-TTL-based-race-recovery 등 불필요 |
| **사용자 의도 존중** | "대기 싫음" 이 명시적으로 표명됨 (revision 1 지시) |
| **실제 시나리오 매칭** | 대부분 충돌은 1-2 파일. 전체 scope 충돌은 드물다 — 제외 후 진행이 합리적 |

#### Critic B (반대)

| 약점 | 논거 | 대응 |
|------|------|------|
| **Task 완결성 깨질 수 있음** | A+B+C 수정이 한 기능인데 A 가 잠겨 있으면 B+C 만 수정해 기능 broken | **Cohesion 검사**: planned_writes 중 >50% 충돌 시 사용자에게 "scope 축소됨" 경고 + confirm |
| **100% 충돌 시 아무것도 못 함** | 모든 파일이 잠겨 있으면 task 수행 불가 | Fallback: user notify + 3 선택지 (Defer / Wait / Force) |
| **Deferred 관리 복잡** | 제외된 파일을 누가 언제 다시 시도? | Manifest `deferred` 필드 + 다음 /team Phase 0.5 에서 "이전 deferred 재시도?" 프롬프트 |
| **LLM 재설계 품질 의존** | "제외하고 재설계" 를 LLM 이 엉성하게 하면 오히려 혼란 | Phase 0.6 revise 에 **safety check**: task description 이 너무 변경되면 user confirm |
| **부분 commit 의 review 오버헤드** | PR 1개가 여러 번 쪼개지면 리뷰어 부담 | Commit message 에 "deferred: [files]" 자동 태그 — grep 으로 관리 추적 가능 |
| **사용자 의도 vs 실제 결과 괴리** | "Hand History 기능 추가" task 인데 핵심 파일 잠겨서 사이드 파일만 수정되면 "거짓 완료" 느낌 | **Cohesion 경고** + deferred list 가 명확히 보고됨 → 사용자가 상황 파악 |

#### 자기반박

1. **"대부분 충돌은 1-2 파일" 은 추정** — 실제 측정 없음. EBS 는 문서 중심이라 docs/ 쪽 편집이 겹치면 5+ 파일 동시 충돌 가능.
2. **"Cohesion 검사 50% 기준" 은 임의** — 20%? 30%? 최적값은 실측 후 조정 필요.
3. **Deferred 자동 재시도 로직 미정의** — 다음 /team 이 언제 deferred 를 재시도할지, 사용자 개입 없이 가능한지 불분명.
4. **Wait 모델의 장점을 완전히 버린 것** — 장시간 실행 PR (예: 1시간짜리 리팩토링) 은 wait 이 더 나을 수 있음. Hybrid 가능성 검토.
5. **LLM 재설계 품질을 과소평가** — Claude Opus 4.7 은 task 재구성을 잘 할 수 있음. 보수적으로 접근할 필요 있는지 재검토.
6. **Critic B 의 "부분 commit 오버헤드" 는 현실과 반대** — 이미 v3.0 은 "매 작업이 완결된 트랜잭션" 이므로 부분 commit 이 자연스러움. 오히려 강점.

### 3.6 최종 판정 (revision 1)

| 항목 | 결론 |
|------|:----:|
| 사용자 제안 (Wait) 폐기 | **✓ 폐기** — Exclude+Revise 로 전환 |
| Exclude+Revise 채택 | **✓ 채택** — 메인 전략 |
| Fallback (100% 충돌 시) | **user notify + 3 선택** (Defer / Wait fallback / Force) |
| Cohesion 경고 기준 | **≥50% 충돌** 시 user confirm (실측 후 조정) |
| Deferred 관리 | **manifest.deferred** + 다음 /team 에서 재시도 프롬프트 |
| v3.1 유지 여부 | **✓ 유지** (safety net) |

## 4. 통합 설계 v4.0 (revision 1 — Exclude + Revise 모델)

### 4.1 Core Concept

```
Before /team 시작:
  Phase 0   — Declaration: 이 세션이 쓸 것으로 예상되는 파일 목록 작성
  Phase 0.5 — Conflict Scan: 다른 모든 세션의 manifest 와 대조
  Phase 0.6 — Plan Revision: 충돌 파일 제외 + task 재구성 + cohesion check
  Phase 0.7 — Safety Gate: 100% 충돌 / cohesion <50% 시 user notify

Conflict 없음    → planned_writes 유지 → 기존 Phase 1-8 진행
Conflict 부분   → excluded set 제외 → 축소된 scope 로 진행 (경고 표시)
Conflict 전체   → user notify 3 선택 (Defer / Wait fallback / Force)
```

**원칙**: 대기(Wait) 없음. 충돌 시 즉시 계획 수정 후 진행. 100% 충돌 시에만 사용자 개입.

### 4.2 Manifest 스키마

**파일**: `.claude/.session-manifests/{sid}.json`

```json
{
  "schema_version": "1.0",
  "sid": "pid-12345-20260421-163045",
  "team_id": "team1",
  "task_description": "Hand_History.md 신설 + UI.md 사이드바 반영",
  "started_at": "2026-04-21T16:30:45Z",
  "heartbeat_at": "2026-04-21T16:35:12Z",
  "phase": 4,
  "status": "active",
  "planned_writes": [
    "docs/2. Development/2.1 Frontend/Lobby/Hand_History.md",
    "docs/2. Development/2.1 Frontend/Lobby/UI.md",
    "docs/2. Development/2.1 Frontend/Lobby/Overview.md"
  ],
  "planned_writes_globs": [
    "docs/2. Development/2.1 Frontend/Lobby/**"
  ],
  "planned_reads": [
    "docs/1. Product/Foundation.md",
    "docs/4. Operations/Plans/**"
  ],
  "actual_writes": [
    "docs/2. Development/2.1 Frontend/Lobby/Hand_History.md"
  ],
  "deferred": [
    "docs/2. Development/2.1 Frontend/Lobby/Overview.md"
  ],
  "revised_task": "Hand_History.md 신설 + UI.md 사이드바 반영 (Overview.md 는 team2 충돌로 제외, 후속 /team 에서 재시도)",
  "excluded_count": 1,
  "original_count": 3,
  "cohesion_ratio": 0.67,
  "priority": 0
}
```

**필드 설명** (revision 1):

| 필드 | 용도 |
|------|------|
| `sid` | 고유 세션 ID (`{pid}-{start_ts}`) |
| `team_id` | 세션 소유 팀 (conductor / team1-4) |
| `task_description` | /team 의 첫 번째 args (읽기 쉬운 제목) — 원본 |
| `revised_task` | Phase 0.6 에서 재구성된 task (충돌 제외 반영) |
| `started_at` | /team 호출 시각 |
| `heartbeat_at` | 마지막 갱신 (phase 변화 or 주기적) |
| `phase` | 현재 /team Phase (0-8) |
| `status` | active / completed / aborted |
| `planned_writes` | 구체 파일 경로 (revision 반영, 제외 후 남은 것) |
| `planned_writes_globs` | Wildcard 패턴 (fallback) |
| `planned_reads` | 읽기만 — 충돌 판정 제외 |
| `actual_writes` | Phase 5 시점 실제 쓴 파일 |
| `deferred` | Phase 0.6 에서 제외된 파일 목록 (다음 /team 재시도 대상) |
| `excluded_count` | Phase 0.6 제외 건수 |
| `original_count` | Phase 0 최초 선언 건수 |
| `cohesion_ratio` | `(original - excluded) / original`. <0.5 시 경고 |
| `priority` | 사용자 긴급도 (기본 0, `!quick` 은 1) |

> `waiting_on` 및 `status=waiting` 필드는 **revision 1 에서 제거** (대기 모델 폐기로 불필요).

### 4.3 /team Phase 확장 (revision 1)

```
Phase 0   NEW — Declaration
Phase 0.5 NEW — Conflict Scan
Phase 0.6 NEW — Plan Revision (Exclude conflicting files + revise task)
Phase 0.7 NEW — Safety Gate (cohesion check, 100% conflict fallback)
Phase 1   기존 — Context Detect
Phase 2   기존 — Pre-Sync
Phase 3   기존 — Branch Prep
Phase 4   기존 — Execute (revised plan 기반)
Phase 5   기존 — Verify (+ manifest.actual_writes 갱신)
Phase 6   기존 — Auto Commit (deferred 태그 포함)
Phase 7   기존 — Merge + Push
Phase 8   기존 — Report (deferred list 보고) + manifest cleanup
```

#### Phase 0 — Declaration (신규)

```python
# scripts/team_declare.py
# 1. task_description 파싱 → LLM 에 "수정할 파일 예측 요청"
#    (/auto 의 Phase 1 Plan 과 유사하나 파일 목록만)
# 2. precise paths + glob patterns 둘 다 작성
# 3. manifest JSON write
# 4. stdout: 사용자에게 declaration 표시
```

사용자 출력 예:
```
📋 /team Declaration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
이 세션이 쓸 것으로 예상되는 파일:
  · docs/2. Development/2.1 Frontend/Lobby/Hand_History.md  (신규)
  · docs/2. Development/2.1 Frontend/Lobby/UI.md            (수정)
  · docs/2. Development/2.1 Frontend/Lobby/Overview.md      (수정)
Glob: docs/2. Development/2.1 Frontend/Lobby/**
Reads only: docs/1. Product/Foundation.md
```

#### Phase 0.5 — Conflict Scan (신규, revision 1)

```python
# scripts/team_conflict_scan.py
# 1. glob .claude/.session-manifests/*.json
# 2. 자기 자신 제외. status != "active" 또는 heartbeat > 5분 전 → stale 자동 정리 + 무시
# 3. 내 planned_writes ∩ 타 세션 planned_writes (precise + glob 매칭)
# 4. 반환: {conflicts: [file, ...], conflicted_sessions: [{sid, task, team_id}, ...]}
# 5. 대기 로직 없음 (revision 1 에서 제거)
```

#### Phase 0.6 — Plan Revision (신규, revision 1)

```python
# scripts/team_plan_revise.py
# 1. conflicts = Phase 0.5 결과
# 2. revised_writes = planned_writes - conflicts
# 3. deferred = conflicts (manifest 기록)
# 4. LLM 에게 task 재구성 요청:
#    input: original_task + removed_files + kept_files
#    output: revised_task (자연어, 제외 이유 명시)
# 5. manifest 갱신: revised_task, deferred, excluded_count, cohesion_ratio
# 6. cohesion_ratio = (original_count - excluded_count) / original_count
```

#### Phase 0.7 — Safety Gate (신규, revision 1)

```python
# scripts/team_safety_gate.py
# 분기:
# a. cohesion_ratio == 1.0 (충돌 없음)
#    → silent pass (Phase 1 이동)
# b. 0.5 <= cohesion_ratio < 1.0 (부분 충돌)
#    → 경고 표시 + 자동 진행 (no user input)
# c. 0 < cohesion_ratio < 0.5 (과반 충돌)
#    → user confirm 필수 ("scope 축소 OK?" y/n)
# d. cohesion_ratio == 0.0 (100% 충돌)
#    → fallback menu (3 선택):
#       [d] Defer (모든 파일을 deferred 로 기록하고 /team 종료)
#       [w] Wait fallback (v4.0 초안의 polling, 최대 10분) — 비상용
#       [f] Force (충돌 무시하고 진행, 사용자가 race 책임)
```

사용자 출력 예 (부분 충돌 case b):
```
⚠ Conflict Detected — 계획 수정됨 (revision 1)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
다른 활성 세션이 쓰고 있는 파일:
  ✗ team2 (5분 전 시작) — Backend Hand History API 필터 확장
    · docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md

조치: 위 1 파일을 이번 /team 에서 제외합니다.
  원본 scope: 3 파일
  수정 scope: 2 파일 (cohesion 67%)
  Deferred:   1 파일 (다음 /team 에서 재시도 권고)

Revised task:
  "Hand_History.md 신설 + UI.md 사이드바 반영
   (Overview.md 는 team2 충돌로 제외)"

진행 중... (Phase 1 →)
```

사용자 출력 예 (과반 충돌 case c):
```
⚠ Major Conflict — scope 40% 만 남음
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
원본 scope: 5 파일 → 수정 scope: 2 파일 (cohesion 40%)

제외된 파일 (Deferred):
  · docs/.../A.md  (team2 충돌)
  · docs/.../B.md  (team3 충돌)
  · docs/.../C.md  (team4 충돌)

계속 진행하시겠습니까? 작업의 완결성이 깨질 수 있습니다.
  [y] 남은 2 파일만 진행
  [d] 전체 defer (이번 /team 취소)
  [n] 취소 후 task 재입력
```

사용자 출력 예 (100% 충돌 case d):
```
✗ Total Conflict — 모든 파일이 다른 세션에서 사용 중
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
원본 scope 5 파일 전체가 충돌. Cohesion 0%.

Fallback 선택:
  [d] Defer 모두 (다음 /team 에서 재시도) — 권장
  [w] Wait fallback (10분 polling) — 비상용
  [f] Force (race 위험 수용)
```

#### Phase 8 확장 — Cleanup + Deferred 보고 (revision 1)

- /team 성공 시: manifest.status = "completed", 30초 후 삭제. **deferred 목록을 Phase 8 Report 에 명시**
- /team 실패 시: manifest.status = "aborted", 즉시 삭제
- Stale cleanup: 다른 /team 이 Phase 0.5 scan 시 heartbeat > 5분 manifest 자동 삭제
- **Deferred 자동 재시도 프롬프트**: 다음 /team 호출 시 같은 세션의 이전 manifest 에 deferred 가 있으면 "이전 deferred N 파일 재시도?" 질문 (기본 y)

### 4.4 Heartbeat

각 Phase 전환 시 `heartbeat_at` 갱신. 추가로 `_common.py` 에 atexit handler 등록:

```python
import atexit
atexit.register(lambda: _cleanup_my_manifest())
```

### 4.5 세션 수 제한

사용자 "5개 파일" 의도를 존중:
- **권장 동시 세션 수: 5** (Conductor + team1-4)
- **하드 한계 없음** — glob 기반 scan 이라 수 무관
- **경고**: 6+ 세션 활성 시 Phase 0.5 에서 "과다 세션 경고" 표시

### 4.6 Read-only 세션

`status = "read_only"` 지정 시 manifest 는 기록되지만 planned_writes 가 빔 → 다른 세션과 충돌 판정 대상이 되지 않음. `/team` args 에 `--read-only` 옵션으로 선언.

## 5. /team SKILL.md 변경 사항

`${HOME}/.claude/skills/team/SKILL.md` 에 추가:

- "실행 순서 — 8 Phase" → "실행 순서 — 10 Phase" 로 확장 (Phase 0, 0.5 추가)
- 각 Phase 상세 로직 `references/phases.md` 갱신
- "Edge Cases" 테이블에 Deadlock / Timeout / Stale manifest 케이스 추가
- 새 스크립트:
  - `scripts/team_declare.py` (Phase 0)
  - `scripts/team_conflict_scan.py` (Phase 0.5)
  - `scripts/team_manifest.py` (CRUD helper, 모든 Phase 에서 호출)
  - `scripts/team_cleanup.py` (Phase 8 + atexit)

## 6. Hook 연동

### 6.1 기존 hook 활용

| Hook | 역할 | v4.0 연동 |
|------|------|-----------|
| `session_branch_init.py` | SessionStart | 세션 시작 시 manifest 초기화 (`status=active`) |
| `branch_guard.py` v3.1 | PreToolUse Bash | 변경 없음 |
| `file_lock_preedit.py` | PreToolUse Edit/Write | manifest 확인 후 다른 세션이 쓰려는 파일이면 block + 안내 |
| `conductor_stop_cleanup.py` | Stop | manifest cleanup 추가 |

### 6.2 file_lock_preedit 강화

현재 `file_lock_preedit.py` 는 active-edits orphan branch 기반. v4.0 에서는 manifest 의 `actual_writes` 도 참조하여 다른 세션이 진짜로 수정 중인 파일을 block.

## 7. 마이그레이션 Phase

### Phase 1 — Manifest 인프라 (구현 ~ 2일)

| 산출물 | 담당 |
|--------|------|
| `scripts/team_manifest.py` CRUD helper | Conductor |
| `.claude/.session-manifests/` 디렉토리 구조 정의 | Conductor |
| JSON schema validator (jsonschema) | Conductor |

### Phase 2 — Phase 0/0.5 스크립트 (구현 ~ 1일)

| 산출물 | 담당 |
|--------|------|
| `scripts/team_declare.py` | Conductor |
| `scripts/team_conflict_scan.py` | Conductor |
| `scripts/team_cleanup.py` | Conductor |

### Phase 3 — SKILL.md 갱신 (문서 ~ 0.5일)

| 산출물 | 담당 |
|--------|------|
| `~/.claude/skills/team/SKILL.md` — 10 Phase 전환 | Conductor |
| `references/phases.md` 업데이트 | Conductor |
| `references/edge_cases.md` 업데이트 (Deadlock / Timeout) | Conductor |

### Phase 4 — Hook 연동 (구현 ~ 1일)

| 산출물 | 담당 |
|--------|------|
| `session_branch_init.py` manifest 초기화 | Conductor |
| `file_lock_preedit.py` manifest 참조 | Conductor |
| `conductor_stop_cleanup.py` manifest cleanup | Conductor |

### Phase 5 — 검증 (QA ~ 1일)

| 검증 항목 | 방법 |
|-----------|------|
| 단일 세션 정상 동작 | /team 실행 후 manifest 생성 → 완료 시 삭제 확인 |
| 2 세션 충돌 감지 | 같은 파일 2 세션 동시 /team → Phase 0.5 에서 대기 |
| 3 세션 FIFO | 3 세션 순차 진입 → 시작 순서대로 실행 |
| 데드락 감지 | A↔B 상호 대기 → FIFO tiebreak 로 하나 진행 |
| Stale manifest | 세션 kill 후 5분 뒤 다른 /team → 자동 정리 |
| 세션 crash 복구 | atexit handler 동작 확인 |

### Phase 6 — Rollout (~ 0.5일)

| 단계 | 동작 |
|------|------|
| 1. dry-run 모드 | manifest 생성하지만 conflict 시 block 대신 warning |
| 2. soft-enforce 모드 | conflict 시 사용자 confirm 필수 (자동 대기 off) |
| 3. full-enforce 모드 | conflict 시 자동 대기 (v4.0 기본) |

## 8. 리스크

| 리스크 | 영향 | 완화 |
|--------|------|------|
| LLM 이 manifest 를 정확하지 않게 작성 | 충돌 감지 실패 | file_lock_preedit 이 actual_writes 감지하여 runtime 차단 |
| 세션이 hang 되어 manifest 가 stale 로 남음 | 다른 세션 blocking | Heartbeat TTL (5분) + atexit cleanup |
| 동시 manifest write race | JSON 깨짐 | atomic rename (tmp file → rename) |
| 사용자 UX 저하 (대기 메시지 반복) | 짜증 | `--no-wait` 옵션 + clear wait indicator |
| 기존 v3.1 hook 과 충돌 | 이중 차단 | file_lock_preedit 이 manifest 참조하므로 one-source-of-truth |
| `--quick` 같은 bypass 남용 | 충돌 무시 | bypass 시에도 manifest 는 기록 (감사 추적) |

## 9. 채택 시 기대 효과 (revision 1 — Exclude+Revise)

| 시나리오 | v3.1 | v4.0 초안 (Wait) | v4.0 revision 1 (Exclude) |
|----------|:----:|:----------------:|:-------------------------:|
| 같은 파일 동시 수정 | 뒤 세션 "modified-since-read" 에러 | Phase 0.5 대기 (최대 10분) | **Phase 0.6 제외 + 재설계 (즉시 진행)** |
| Conductor HEAD 튕김 | 힌트만 제공 | manifest 활동 표시 | manifest 활동 표시 + 자동 우회 |
| `git add` 에 다른 세션 변경 혼입 | 감지 없음 | Phase 6 경고 | Phase 6 경고 + deferred 자동 분리 |
| 세션 간 가시성 | commit log 사후 확인 | 실시간 manifest | 실시간 manifest + revised scope 보고 |
| 사용자 blocking 시간 | 없음 (race 후 복구) | 최대 10분 | **0** (blocking 없음) |
| Deadlock 위험 | 없음 | 있음 (사이클 감지 필요) | **0** |
| Task 완결성 | 100% (race 후) | 100% (대기 후) | 부분 (deferred 재시도로 최종 100%) |
| 100% 충돌 시 | 다수 race | 10분 대기 후 confirm | **즉시 user 3 선택 (Defer/Wait/Force)** |

## 10. 승인 체크리스트 (revision 1)

| 항목 | 상태 |
|------|:----:|
| 현재 v3.1 잔존 문제 4종 정리 | ✓ |
| 사용자 제안 (Wait) Critic A/B + 자기반박 6건 | ✓ |
| **Exclude+Revise 모델 Critic A/B + 자기반박 6건** (revision 1) | ✓ |
| **Wait vs Exclude+Revise 비교 매트릭스** (revision 1) | ✓ |
| Manifest JSON 스키마 정의 (revision 1: deferred/cohesion 필드 추가) | ✓ |
| Phase 0 / 0.5 / **0.6 / 0.7** / Cleanup 흐름 (revision 1) | ✓ |
| ~~데드락 대응~~ → **Deadlock 제거 설계** (revision 1) | ✓ |
| **Cohesion 검사 + 4 case 분기** (revision 1) | ✓ |
| Hook 연동 방안 | ✓ |
| 마이그레이션 6 Phase | ✓ |
| 리스크 6건 + 완화 | ✓ |
| **구현 착수 승인** | 대기 (사용자 confirm) |

## 11. 사용자 제안 → v4.0 매핑 (revision 1)

| 사용자 요구 | v4.0 revision 1 반영 |
|-------------|---------------------|
| 수정할 목록 먼저 작성 | **Phase 0 Declaration** (`planned_writes` + `planned_writes_globs`) |
| /team 시작 시 모든 세션 문서 분석 | **Phase 0.5 Conflict Scan** (glob `.claude/.session-manifests/*.json`) |
| ~~충돌 시 먼저 세션 종료까지 대기~~ | ~~Wait with 10-min timeout~~ → **Phase 0.6 Exclude + Revise (즉시 제외 + 재설계)** |
| **충돌 파일 제외하고 작업 재설계** (revision 1) | **Phase 0.6** — `planned_writes - conflicts`, LLM 재구성, `deferred` 기록 |
| 각 세션별 JSON 파일 | `.claude/.session-manifests/{sid}.json` |
| /team 이 항상 5개 파일 읽음 | 동적 glob scan (Conductor + team1-4 = 5, 더 가능) |
| 충돌 사전 방지 | **Phase 0.5 + 0.6 + 0.7 이 기존 Phase 1 이전에 실행** |

## 12. 다음 /team 호출 (사용자 승인 후)

```
/team "v4.0 Phase 1: Manifest 인프라 (scripts/team_manifest.py + JSON schema)"
/team "v4.0 Phase 2: team_declare.py + team_conflict_scan.py 구현"
/team "v4.0 Phase 3: SKILL.md 10-Phase 전환 + references 업데이트"
/team "v4.0 Phase 4: Hook 3종 manifest 연동"
/team "v4.0 Phase 5: QA 6 시나리오 테스트"
/team "v4.0 Phase 6: dry-run → soft-enforce → full-enforce rollout"
```

총 6 /team 트랜잭션, ~5일 공수. 본 Plan 이 SSOT — **사용자 confirm 대기**.

## 13. 금지

- 본 Plan 승인 없이 scripts/team_*.py 선행 구현 금지
- v4.0 구현 중에도 v3.1 hook 유지 (safety net)
- full-enforce 즉시 전환 금지 (dry-run → soft → full 3단계)

---

## 14. 2026 최신 기술/트렌드 검증 (revision 2, 2026-04-21)

WebSearch 5종 (Claude Code Agent Teams / AI agent file lock / Git worktree race / 분산 lease / multi-agent orchestration) 결과로 본 v4.0 revision 1 설계를 재검증했다.

### 14.1 업계 표준 패턴과 정렬 여부

| 업계 표준 (2026) | v4.0 revision 1 상태 | 판정 |
|------------------|---------------------|:----:|
| **Pre-declaration manifest** (Augment Intent, Beads JSONL) | ✓ Phase 0 Declaration + `.session-manifests/*.json` | **정렬** |
| **Lease with TTL + heartbeat** (Kubernetes Lease, distributed systems) | ✓ Heartbeat 5분 TTL, atexit cleanup | **정렬** |
| **Git worktree isolation (기본 전략)** | △ "권장" 수준, 강제하지 않음 | **강화 필요** |
| **File ownership 사전 분할** (Claude Code Agent Teams 공식 best practice) | △ decision_owner 존재하나 Phase 0 에서 참조 안 함 | **강화 필요** |
| **5-Role orchestration** (Producer/Consumer/Coordinator/Critic/Judge) | ✗ 명시적 매핑 없음 | **신규 매핑 권고** |
| **Exclude+Revise (부분 scope 진행)** | ✓ revision 1 의 핵심 | **업계보다 선진** |
| **Locking 남용 방지** (Cursor 실패 교훈) | △ Wait fallback 존재 | **축소 권고** |

### 14.2 핵심 교훈 3종

#### 교훈 1 — Cursor 의 locking 실패 (경고)

> Cursor 의 multi-agent 초기 시도에서 locking 이 agent throughput 을 20 → 2-3 으로 떨어뜨렸다. Agent 가 lock 을 너무 오래 잡은 것이 원인.

**v4.0 revision 1 에 미치는 영향**:
- 현재 Wait fallback (10분 timeout) 은 Cursor 가 실패한 패턴과 유사
- **권고**: Wait fallback timeout 을 **10분 → 5분** 축소, **Defer 를 기본 권장**으로 강화
- "Lock 은 비상용, Exclude+Revise 가 주류" 원칙 명문화

#### 교훈 2 — Git worktree 가 2026 표준 (기본 전략으로 승격)

> "Running multiple AI coding agents simultaneously introduces failure modes where agents overwrite each other's files ... Git worktrees solve this by giving each agent a dedicated branch and working directory that shares the underlying .git object store." (Augment Code, 2026)
>
> JetBrains IDEs shipped first-class Git worktree support in 2026.1 release (March 2026). VS Code 는 2025.07 지원.

**v4.0 revision 1 에 미치는 영향**:
- 현재 subdir 세션의 공유 HEAD race 가 모든 문제의 근원
- **권고**: **Worktree-First 정책 승격** — 새 팀 세션은 **기본적으로 sibling worktree** 에서 시작, subdir 은 Conductor 및 특수 경우만
- `session_branch_init` 이 subdir 감지 시 **"sibling worktree 로 이주하시겠습니까?" 프롬프트** 추가

#### 교훈 3 — File ownership 사전 분할 (Claude Code 공식 권장)

> "Two teammates editing the same file leads to overwrites, so break the work so each teammate owns a different set of files. The more specific your task decomposition instructions, the cleaner the agent coordination will be." (Claude Code Agent Teams docs, 2026)

**v4.0 revision 1 에 미치는 영향**:
- EBS 는 이미 `team-policy.json` 의 `decision_owner` + `contract_ownership` 이 있음
- **권고**: **Phase 0 Declaration 에서 `team-policy.json` 참조** — 선언한 `planned_writes` 가 다른 팀의 decision_owner 경로면 warning. 다른 팀이 "전용" 소유권 주장하는 경로는 manifest `planned_writes` 에 포함 자체를 차단.

### 14.3 5-Role 패턴 매핑 (신규 권고)

2026 업계 표준 "reliable multi-agent system reduces to 5 roles" 에 EBS /team 을 매핑:

| Role | EBS /team 매핑 | 기능 |
|------|----------------|------|
| **Producer** | Phase 0 Declaration (LLM 예측) | Ambiguous task → precise planned_writes |
| **Consumer** | Phase 4 Execute (/auto) | Execute work items, no cross-session coordination |
| **Coordinator** | Conductor 세션 | Route work, main branch integration, decision_owner 판정 |
| **Critic** | `aiden-auto:critic` 스킬 (선택) | Suggestions, no gate (warning only) |
| **Judge** | Phase 0.7 Safety Gate + Phase 5 Verify | Binary go/no-go (cohesion ratio, drift scan) |

**효과**: 각 Phase 의 책임이 명확해짐. 새 Phase 추가 시 어느 Role 에 속하는지 판단 가능.

### 14.4 Lease 모델 정합성 검증

Martin Fowler / Kubernetes 의 Lease 패턴 공식 정의:

> "Lease is a time-bound lock. Automatically released after timeout. Holder sends periodic heartbeat to extend lease."

**v4.0 revision 1 의 manifest = lease 로 재명명 가능**:

| Lease 필드 | 현재 manifest 필드 | 일치도 |
|-----------|---------------------|:------:|
| `holder` | `sid` + `team_id` | ✓ |
| `acquired_at` | `started_at` | ✓ |
| `renewed_at` | `heartbeat_at` | ✓ |
| `ttl` | 5분 (하드코딩) | ✓ (명시화 권고) |
| `resources` | `planned_writes` + `planned_writes_globs` | ✓ |
| `released_at` | `status=completed` 후 30초 삭제 | ✓ |

**권고**: 스키마에 `lease_ttl_sec: 300` 필드 명시 추가 (현재 암묵).

### 14.5 최종 권고 사항 (revision 2 — 종합)

| # | 변경 대상 | 기존 (r1) | 권고 (r2) | 근거 |
|:-:|----------|-----------|-----------|------|
| R1 | Worktree 정책 | 권장 | **기본 (subdir 는 특수 경우)** | Git worktree 2026 표준화 |
| R2 | File ownership 체크 | 없음 | **Phase 0 Declaration 에서 team-policy.json 참조** | Claude Code 공식 best practice |
| R3 | Wait fallback timeout | 10분 | **5분 + Defer 를 기본 권장** | Cursor locking 실패 교훈 |
| R4 | 5-Role 매핑 | 없음 | **§14.3 매트릭스로 명시** | 업계 pattern language |
| R5 | Manifest = Lease 명명 | 암묵 | **스키마에 `lease_ttl_sec` 명시, 문서에 "Lease" 용어 도입** | Kubernetes/Fowler 표준 정합 |
| R6 | Deferred 재시도 로직 | "다음 /team 에서 재시도 프롬프트" 수준 | **manifest.deferred 가 24h 내 같은 팀 세션에서 최우선 처리** | Beads "land the plane" 패턴 |
| R7 | Critic / Judge 분리 | 섞임 | **Critic (no gate) vs Judge (binary) 명확히 분리** | 업계 표준 용어 |
| R8 | Intent evolution | task_description + revised_task 2 필드 | **Augment Intent 패턴 채택 — spec 이 agents 와 함께 진화** | 2026 Intent workspace 트렌드 |

### 14.6 재검증된 채택 순위

v4.0 revision 2 구현 시 Phase 우선순위 (기존 6 Phase → 7 Phase 로 조정):

```
Phase 1 — Manifest/Lease 인프라 (R5 반영)
Phase 2 — Phase 0/0.5/0.6/0.7 스크립트 (R2 team-policy 참조, R3 timeout 축소)
Phase 3 — Worktree-First 자동화 (R1) — NEW
Phase 4 — SKILL.md 10-Phase + 5-Role 매핑 (R4, R7)
Phase 5 — Hook 3종 manifest 연동 (기존)
Phase 6 — Deferred 자동 우선순위 (R6, R8) — NEW
Phase 7 — QA + Rollout (dry-run → soft → full)
```

총 7 /team 트랜잭션, ~6일 공수 (기존 5일 + 1일).

### 14.7 업계 대비 혁신성 자평

| 요소 | 업계 표준 2026 | v4.0 revision 2 | 혁신성 |
|------|:--------------:|:---------------:|:------:|
| Pre-declaration | Intent workspace (Augment) | Manifest JSON + team-policy 참조 | **동등** |
| Lease | Kubernetes | Manifest = Lease 재명명 | **동등** |
| Worktree 기본 | 표준화 | Worktree-First 정책 | **동등** |
| File ownership | 수동 분할 권장 | **자동 체크 (team-policy.json)** | **선진** |
| Cohesion-based Exclude | 없음 (locking/wait 위주) | **4 case 분기 (1.0/0.5-1/0-0.5/0)** | **혁신** |
| Deferred 자동 재시도 | Beads "land the plane" | **24h 최우선** | **동등** |
| 5-Role 매핑 | 패턴 언어 | Phase 별 명시 매핑 | **동등** |

**결론**: v4.0 revision 2 는 2026 업계 표준을 대부분 따르되, **Cohesion-based Exclude+Revise** + **자동 file ownership 체크** 는 업계보다 선진. Cursor 실패를 답습하지 않고 개선된 방향.

### 14.8 Sources

- [Orchestrate teams of Claude Code sessions — Claude Code Docs](https://code.claude.com/docs/en/agent-teams)
- [Claude Code Agent Teams 2026 Guide (Shipyard)](https://shipyard.build/blog/claude-code-multi-agent/)
- [The Code Agent Orchestra — Addy Osmani](https://addyosmani.com/blog/code-agent-orchestra/)
- [Intent: A workspace for agent orchestration — Augment Code](https://www.augmentcode.com/blog/intent-a-workspace-for-agent-orchestration)
- [6 Multi-Agent Orchestration Patterns for Production (2026) — Beam](https://beam.ai/agentic-insights/multi-agent-orchestration-patterns-production)
- [Multi-Agent Orchestration Patterns: Pattern Language 2026 — DigitalApplied](https://www.digitalapplied.com/blog/multi-agent-orchestration-patterns-producer-consumer)
- [Multi-Agent AI Coding Workflow: Git Worktrees That Scale (2026)](https://blog.appxlab.io/2026/03/31/multi-agent-ai-coding-workflow-git-worktrees/)
- [Git Worktree Conflicts with Multiple AI Agents — Termdock](https://www.termdock.com/en/blog/git-worktree-conflicts-ai-agents)
- [How to Use Git Worktrees for Parallel AI Agent Execution — Augment Code](https://www.augmentcode.com/guides/git-worktrees-parallel-ai-agent-execution)
- [Leases — Kubernetes docs](https://kubernetes.io/docs/concepts/architecture/leases/)
- [Lease — Martin Fowler (Patterns of Distributed Systems)](https://martinfowler.com/articles/patterns-of-distributed-systems/lease.html)
- [AI Coding Agents in 2026: Coherence Through Orchestration — Mike Mason](https://mikemason.ca/writing/ai-coding-agents-jan-2026/)
- [From Conductor to Orchestrator: Multi-Agent Coding 2026](https://htdocs.dev/posts/from-conductor-to-orchestrator-a-practical-guide-to-multi-agent-coding-in-2026/)
- [How to Supervise AI Coding Agents — DEV Community](https://dev.to/battyterm/how-to-supervise-ai-coding-agents-without-losing-your-mind-53m4)
