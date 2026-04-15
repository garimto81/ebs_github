---
name: team-merge
description: 작업 브랜치(work/team{N}/*) → main 통합. rebase + ff merge.
---

# /team-merge — 팀 작업 브랜치 통합

현재 `work/team{N}/{date}-{slug}` 브랜치를 main 으로 통합합니다.

## 동작

```
fetch origin
git rebase origin/main          # 충돌 시 사용자에게 안내 후 중단
git checkout main
git merge --ff-only work/...    # fast-forward only
[--push 시] git push origin main
[--delete-branch 시] 로컬 브랜치 정리
```

## 사용

```
/team-merge                     # rebase + local ff merge
/team-merge --push              # + main push (Conductor 권장)
/team-merge --delete-branch     # + 작업 브랜치 삭제
/team-merge --abort             # rebase 충돌 시 중단
```

## 구현

`python tools/team_merge.py $ARGUMENTS` 호출.

## 주의

- 작업 브랜치(`work/*`)에서만 실행 가능.
- rebase 충돌 발생 시 수동 해결 후 `git rebase --continue` 또는 `--abort` 필요.
- main push는 conductor 세션에서만 권장 (branch_guard hook이 팀 세션 push 차단).
