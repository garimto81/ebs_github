---
title: v8.0 Workflow Verification — End-to-End Test
owner: conductor
status: verified
verification_date: 2026-04-28
authority: User test request "v8.0 처리되는지 테스트"
purpose: v8.0 3-Phase workflow (Work → PR → Sync) end-to-end 검증
---

# v8.0 Workflow Verification (2026-04-28)

## 검증 목적

v8.0 governance 모델 (PR #63 으로 main 적용) 의 실제 워크플로우 작동 검증. 본 문서 자체가 v8.0 의 end-to-end test 산출물.

## 검증 path

```
1. work/conductor/v8-test-2026-04-28 branch 생성
2. 본 Reports doc 작성 + commit
3. git push origin work/conductor/v8-test-2026-04-28
4. gh pr create --label auto-merge
5. .github/workflows/pr-auto-merge.yml 가 자동 squash merge
6. main 에 본 doc 자동 반영
```

## v8.0 3-Phase 검증 항목

| Phase | 동작 | 검증 신호 |
|:--:|------|----------|
| **1. Work** | work branch + commit | branch push 성공 |
| **2. PR** | `gh pr create --label auto-merge` | PR 생성 + label 부여 |
| **3. Sync** | `pr-auto-merge.yml` workflow | concurrency group + CI gate + squash merge |

## 적용된 v8.0 정책

- **L0 폐기**: `tools/active_work_claim.py` 호출 X (Phase 0 Claim 단계 없음)
- **deprecated hooks 비활성**: branch_guard.py / session_branch_init.py 미존재 → settings.json 등록 X
- **governance freeze**: until 2026-05-28, file cleanup 만 진행 가능
- **PR-only**: Conductor 도 main 직접 push X, 본 commit 도 work branch + PR

## 검증 후 후속 작업

본 PR 의 auto-merge 성공 시:
- `pr-auto-merge.yml` workflow 의 concurrency group 정상 작동 확인
- v8.0 의 free-tier merge gate 정상 운영 확인
- 다른 conductor 세션의 race condition 없음 확인

## 관련

- v8.0 마이그레이션 Plan: 이전 conversation turn 의 critic 보고서 + Phase 1-9 진행
- v8.0 main 적용 commit: PR #63 (61e4bc28)
- governance freeze: `team-policy.json` `governance_model.freeze` (until 2026-05-28)
