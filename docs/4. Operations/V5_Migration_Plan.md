---
title: V5 Migration Plan — v4.0/v4.1 → v5.0 전환 로드맵
owner: conductor
tier: internal
last-updated: 2026-04-21
status: IN_PROGRESS
---

# V5.0 Migration Plan (2 주 로드맵)

## 현재 상태 (2026-04-21)

- **v5.0 주요 자산 구현 완료** (이 문서와 함께 커밋)
- **v4.0/v4.1 스킬 병행 동작** (deprecation window)
- **Free-tier 제약 확인** (Merge Queue 불가 → Actions concurrency 로 대체)

## 마이그레이션 단계

### D0 (오늘, 2026-04-21) — v5.0 자산 생성 ✅

이 커밋에 포함:

- [x] `.claude/skills/team-v5/SKILL.md` (project-local skill)
- [x] `.github/workflows/pr-auto-merge.yml` (free-tier merge gate)
- [x] `.github/CODEOWNERS` (자동 리뷰어 배정)
- [x] `tools/team_v5_merge.py` (Phase 2 PR 생성)
- [x] `docs/4. Operations/Multi_Session_Workflow.md` v5.0 rewrite
- [x] `.claude/hooks/session_branch_init.py` v4.1 subdir 차단 (v5.0 에서도 유지)
- [x] 본 문서 (V5_Migration_Plan.md)

### D1-3 (Week 1 시작) — 검증 + 스모크

- [ ] Conductor 세션이 `tools/team_v5_merge.py --dry-run` 으로 body/flow 확인
- [ ] 첫 실 PR 생성 (작은 문서 수정) → `auto-merge` 라벨 부여
- [ ] GitHub Actions `pr-auto-merge.yml` 가 concurrency group 정상 획득 확인
- [ ] Merge 성공 시 main 에 squash commit 확인

### D4-7 (Week 1 후반) — 팀 worktree 전환

- [ ] `python tools/setup_team_worktrees.py --team all` 실행 → team1-4 sibling 생성
- [ ] 각 팀 세션을 해당 sibling 에서 재시작
- [ ] 기존 subdir 세션 종료 (session_branch_init 이 warning 출력)
- [ ] 각 팀이 첫 v5.0 PR 생성 → merge 확인

### D8-10 (Week 2 시작) — v4.0 deprecation 공지

- [ ] `~/.claude/skills/team/SKILL.md` 상단에 "DEPRECATED — use /team-v5" 배너 추가 (user 수동)
- [ ] `~/.claude/skills/team/scripts/*.py` 에 deprecation stderr 출력 (user 수동)
- [ ] MEMORY.md 의 workflow 관련 메모를 v5.0 기준으로 업데이트

### D11-14 (Week 2 후반) — 실험 + 보강

- [ ] 4 팀 동시 PR 시나리오 테스트 (concurrency 직렬화 검증)
- [ ] CI 실패 → 라벨 제거 → 재부여 플로우 검증
- [ ] CODEOWNERS 리뷰 요청 알림 동작 확인
- [ ] Merge time 측정 (평균 CI 소요 / queue 대기)

### D15+ (Week 3 이후) — 정리

- [ ] `.claude/hooks/session_branch_init.py` 제거 (claude -w 로 완전 대체 시)
- [ ] `.claude/hooks/branch_guard.py` 제거 또는 warning-only 축소
- [ ] `~/.claude/skills/team/` v4.0 스킬 디렉토리 제거 (user 수동)
- [ ] `tools/team_pr_merge.py` (v4.1 호환) 제거 or alias → `team_v5_merge.py`

## Free-tier 제약 및 수용 리스크

### 확인된 제약

| 기능 | Free tier | 대응 |
|------|:---------:|------|
| GitHub Merge Queue | ❌ (Team plan) | `concurrency:` group in Actions |
| Branch protection (private) | ❌ (Pro plan) | workflow 가 gate 역할 |
| Required review enforcement | ❌ | CODEOWNERS 알림만 |
| auto-merge (private) | ❌ | `auto-merge` 라벨 + workflow |
| GitHub Actions 분 | 2000 min/mo | 초과 시 비용 or self-host |

### 수용 리스크

1. **서버측 강제 없음** — `gh pr merge --admin` 으로 우회 가능.
   - **수용 이유**: EBS 단일 소유자 repo (garimto81). 소유자 본인이 bypass 결정.

2. **CI 시간 제약** — 2000 min/mo 로 80 PR/day × 5 min CI × 20 영업일 = 2000 min. 여유 없음.
   - **대응**: `paths:` filter 로 팀별 CI 분할. 불필요한 팀 CI 생략

3. **Stacked PRs 불가** — GitHub native 는 2026-03 private preview.
   - **수용**: classic PR + `Depends on #N` 주석 관행 유지. stacked PR GA 후 재평가

4. **Merge queue batch 불가** — `concurrency:` 는 1개씩만 처리 (GitHub Merge Queue 는 batch).
   - **수용**: EBS 규모 (4 팀, 하루 20 PR) 에서는 batch 없이도 충분

## Plan 업그레이드 결정 포인트

다음 조건 중 1 개라도 충족 시 Pro 또는 Team plan 업그레이드 재검토:

- [ ] GitHub Actions 분 월 80% 초과
- [ ] 동시 PR queue 대기 시간 평균 30분 초과
- [ ] 외부 협업자 추가 (현재 단일 소유자)
- [ ] 프로젝트가 기획 검증 → 실제 제품 출시로 전환

## 롤백 경로

v5.0 에 문제 발생 시 복구 절차:

### 롤백 Level 1 (부분) — v4.1 복원
1. `.github/workflows/pr-auto-merge.yml` disable
2. `tools/team_v5_merge.py` 대신 `tools/team_pr_merge.py` 사용 (유지됨)
3. `/team-v5` 대신 `/team` (v4.0) 호출

### 롤백 Level 2 (전체) — v4.0 복원
1. 롤백 L1 + `.claude/skills/team-v5/` 삭제
2. `.claude/hooks/session_branch_init.py` 의 v4.1 subdir 차단 제거 (revert)
3. Multi_Session_Workflow.md v4.0 내용으로 revert

## 완료 기준

- [ ] 4 팀 worktree 생성 + 각 팀 첫 v5.0 PR merge 성공
- [ ] Conductor docs/ 편집 PR 도 merge 성공
- [ ] `pr-auto-merge.yml` 이 동시 PR 2개 이상에서 concurrency 직렬화 증명
- [ ] 2 주간 race condition 보고 0건
- [ ] v4.0 script 호출 빈도 0 (user 전환 완료)

## 미해결 질문

| 질문 | 담당 | 결정 기한 |
|------|------|-----------|
| Pro plan 업그레이드 여부 | user | D14 까지 (위 조건 확인 후) |
| Stacked PRs 도입 시점 | Conductor | GA 공개 후 재평가 |
| `~/.claude/skills/team/` 완전 제거 시점 | user | D21 이후 |
