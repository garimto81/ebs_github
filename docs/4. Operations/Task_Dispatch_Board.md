---
title: Task Dispatch Board (V9.0 Hub-and-Spoke)
owner: conductor
tier: contract
last-updated: 2026-04-29
governance: V9.0 conductor_centralized_review
---

# Task Dispatch Board

> **V9.0 Hub-and-Spoke 워크플로우 SSOT.** Conductor 가 백로그를 분해하여 각 팀 세션에 작업을 할당하고, 진행 상태를 단일 보드로 통합 관리한다. 팀 세션은 자기 ROW 만 읽고 결과 PR 을 보고한다.

## 📋 운영 규칙

| 항목 | 규칙 |
|------|------|
| **할당 권한** | Conductor 만 작업 등록 / 우선순위 조정 / 재할당 가능 |
| **상태 갱신** | `ASSIGNED → IN_PROGRESS` 는 팀 세션이 기록. `REVIEW_READY → MERGED` 는 Conductor 만 기록 |
| **머지 권한** | **Conductor 독점** — 팀 세션은 PR 생성 + `REVIEW_READY` 상태 변경까지만 |
| **충돌 해결** | Conductor 가 SSOT (`docs/1. Product/`, `docs/2. Development/2.5 Shared/`) 기준으로 직접 해결 |
| **세션 종료** | 팀 세션은 `REVIEW_READY` 표시 후 Idle 대기. 다음 task 는 Conductor 가 새로 할당 |

## 🔄 상태 전이 다이어그램

```
  +---------+   Conductor    +----------+   Worker      +-------------+
  | PENDING |---할당-------->| ASSIGNED |---착수------->| IN_PROGRESS |
  +---------+                +----------+               +------+------+
                                                                |
                                                          PR 생성
                                                                |
  +--------+   Conductor   +-------+   Conductor      +--------v-----+
  | MERGED |<---병합-------| REVIEW |<---보고---------| REVIEW_READY |
  +--------+               +-------+                   +--------------+
                              |
                         (충돌 시 Conductor 해소 후 머지)
```

## 📊 활성 작업 큐

> 현재 in-flight 만 표기. MERGED 항목은 24h 후 `## 📜 완료 이력` 으로 이동.

### Team 1 — Frontend (lobby-web)

| ID | 상태 | 작업 | Scope | PR | 비고 |
|----|------|------|-------|----|------|
| _(없음)_ | — | — | — | — | — |

### Team 2 — Backend (BO / API / DB)

| ID | 상태 | 작업 | Scope | PR | 비고 |
|----|------|------|-------|----|------|
| _(없음)_ | — | — | — | — | — |

### Team 3 — Game Engine

| ID | 상태 | 작업 | Scope | PR | 비고 |
|----|------|------|-------|----|------|
| _(없음)_ | — | — | — | — | — |

### Team 4 — Command Center (cc-web)

| ID | 상태 | 작업 | Scope | PR | 비고 |
|----|------|------|-------|----|------|
| _(없음)_ | — | — | — | — | — |

### Conductor — Cross-team / Infra

| ID | 상태 | 작업 | Scope | PR | 비고 |
|----|------|------|-------|----|------|
| TDB-001 | MERGED | V9.0 Hub-and-Spoke 인프라 개편 | `team-policy.json`, `Multi_Session_Workflow.md`, `pr-auto-merge.yml`, `Task_Dispatch_Board.md`, `SKILL.md` | 직접 commit (Mode A) | 본 보드 신설 |

## 🧾 Task 등록 템플릿

```markdown
| TDB-NNN | ASSIGNED | <task title> | <files/globs> | <PR URL or "—"> | <constraint or dependency> |
```

**필수 필드**:
- **ID** — `TDB-{3자리 시퀀스}` (Conductor 가 발급)
- **상태** — `ASSIGNED` 시작 / `IN_PROGRESS` (worker) / `REVIEW_READY` (worker) / `MERGED` (Conductor)
- **작업** — 단일 PR 로 마무리 가능한 최소 단위. 너무 크면 분할
- **Scope** — 편집 대상 파일/glob. 다른 팀 영역 침범 시 Conductor 명시 사전 승인 필요
- **PR** — Phase 2 완료 후 `https://github.com/garimto81/ebs_github/pull/NN` 기재
- **비고** — 의존성 / 차단 / 공동 검증 필요 사항

## 🔁 일일 운영 루틴

### Conductor 일과
1. `git fetch && gh pr list --state open` 로 보고된 PR 확인
2. `REVIEW_READY` 상태 PR 을 순차 리뷰 (단일 스레드)
3. 충돌 / 의미 모순 시 SSOT 확인 → 직접 rebase + 해결
4. `gh pr merge --squash --delete-branch` 로 머지
5. 보드에서 해당 row → `MERGED` 갱신 + 다음 task 등록
6. 팀 세션에 다음 작업 dispatch

### Worker (Team 1~4) 일과
1. 본 보드에서 자기 팀 row 의 `ASSIGNED` 항목만 확인
2. 상태 → `IN_PROGRESS` 갱신, sibling worktree 에서 작업
3. 자체 테스트 (pytest / dart analyze / flutter test) 통과 확인
4. `git push` + `gh pr create --draft` (또는 ready PR) — **`auto-merge` 라벨 부여 금지**
5. 보드 row → `REVIEW_READY` + PR URL 기재
6. **Idle 상태 대기**. 다음 작업은 Conductor 가 등록할 때까지 시작 금지

## ⚠️ 절대 규칙

1. **팀 세션은 main 머지 시도 절대 금지**. `gh pr merge`, `git push origin main`, auto-merge 라벨 부여 모두 차단.
2. **Conductor 가 등록하지 않은 작업 자율 착수 금지**. 발견한 추가 작업은 PR comment / Backlog 추가 후 Conductor 결정 대기.
3. **충돌 해결 임의 시도 금지**. Rebase 충돌 발생 시 PR 에 `conflict` 라벨 + Conductor 알림.
4. **보드 = 단일 SSOT**. PR 본문 / Backlog 와 상이 시 본 보드 우선.

## 📜 완료 이력

> 24h 이상 경과한 MERGED 항목 누적. 분기별 `Reports/` 로 archive.

| 일시 | ID | 팀 | 작업 | 머지 PR |
|------|----|----|------|---------|
| 2026-04-29 | TDB-001 | conductor | V9.0 Hub-and-Spoke 인프라 개편 | 직접 commit (Mode A) |

## 관련 문서

- `docs/4. Operations/Multi_Session_Workflow.md` — V9.0 표준 운영 절차 (정책 본문)
- `docs/2. Development/2.5 Shared/team-policy.json` — `governance_model: conductor_centralized_review`
- `.github/workflows/pr-auto-merge.yml` — V9.0 에서 비활성화됨 (history 보존)
- `.claude/skills/team/SKILL.md` — 팀 세션 worker 워크플로우 (PR 보고까지)
