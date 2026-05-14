---
title: CI Chaos Test Handoff (PR #20 gate validation)
owner: conductor
tier: internal
session: work/conductor/chaos-test-ci-gate (closed)
last-updated: 2026-04-28
status: PARTIAL — gate response 검증 ✅, gate 정확도 부분 결함 발견 ⚠
confluence-page-id: 3819766464
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819766464/EBS+CI+Chaos+Test+Handoff+PR+20+gate+validation
---

# CI Pre-Merge Gate — Chaos Test Validation

## TL;DR

PR #20 의 `team1-e2e.yml` Docker Build Gate 에 대한 의도적 회귀 (Type A `COPY ../shared/...`) 주입 결과:

| 결과 | 검증 항목 |
|:---:|---|
| ✅ | CI 가 fail 상태 (4m48s, exit 1) |
| ✅ | `actions/github-script` 가 5-layer cheat-sheet PR 코멘트 자동 게시 |
| ✅ | `auto-merge` 라벨 부재 → auto-merge workflow 정상 skip → PR 자동 머지 차단 |
| ✅ | chaos PR #21 close + 브랜치 삭제 + worktree 정리 완료 |
| ⚠ | **L1 (Type A COPY 위반) 자체는 detected 되지 않음** — Linux BuildKit이 `..` silently normalize. |
| ⚠ | 다른 latent 회귀 (cc-web Flutter 3.22.0 cascade) 가 발견됨 — PR #18이 lobby-web만 pin 했고 cc-web은 누락. |

## 1. ebs_v2 빈 폴더 삭제 (Step 1)

| 시도 | 결과 |
|------|------|
| `Remove-Item -Recurse -Force` | The process cannot access the file (lock persists) |
| `cmd /c "rd /s /q"` | 동일 오류 |
| `[System.IO.Directory]::Delete($path, $false)` (non-recursive) | 동일 오류 |
| `rm -rf` (Git Bash) | Device or resource busy |

**상태**: 본 세션은 Claude Code 동일 conversation — OS 레벨 lock 미해소. 사용자가 task spec 에서 가정한 "session restarted" 조건 미충족 (실제로 23개 claude.exe 프로세스 동시 실행 중). 데이터 영향 0 (`_archive/ebs_v2_2026-04-28.zip` archive 완료, PR #18). **다음 fresh PowerShell session 또는 Claude Code 재시작 후 자연 해소 예상**.

## 2. Chaos Injection (Step 2-3)

### 분기 전략

PR #20 (`work/conductor/ci-docker-build-gate`) 이 origin/main 에 아직 미머지 → workflow 가 main 에 없음 → 일반 chaos PR (main base) 은 trigger 안 됨. **PR #20 head 에서 분기** 하여 workflow self-validation 활용.

```
git fetch origin work/conductor/ci-docker-build-gate
git worktree add C:/claude/ebs-conductor-chaos \
                 -b work/conductor/chaos-test-ci-gate \
                 origin/work/conductor/ci-docker-build-gate
```

### 주입한 위반

`team1-frontend/docker/lobby-web/Dockerfile`:
```diff
- COPY shared/ebs_common /shared/ebs_common
+ # CHAOS TEST: 의도적 build context 위반 (Type A 회귀). CI gate 가 차단해야 함.
+ COPY ../shared/ebs_common /shared/ebs_common
```

### Chaos PR 생성

```
gh pr create \
  --base work/conductor/ci-docker-build-gate \
  --title "test(chaos): Verify CI build gate and auto-comment" \
  --body "🚨 CHAOS TEST PR — DO NOT MERGE."
# (NO auto-merge label)
→ https://github.com/garimto81/ebs_github/pull/21
```

## 3. CI 실패 검증 (Step 4)

### 폴링 결과

```
$ gh pr checks 21
Docker Compose Build Verification    fail        4m48s  https://github.com/garimto81/ebs_github/actions/runs/25036928258/job/73330671625
auto-merge                           skipping    0      ...
GitGuardian Security Checks          pass        0      ...
```

### Per-step 상세

```
Set up job                            → success
Checkout PR                           → success
Set up Docker Buildx                  → success
Expose GHA cache vars to compose      → success
Build lobby-web (Type A gate)         → success     ← ⚠ 의도된 chaos가 검출되지 않음
Build cc-web (team4 cascade gate)     → failure     ← latent 회귀 발견 (cc-web Flutter 3.22)
Smoke probe — lobby-web nginx config  → skipped
Smoke probe — cc-web nginx config     → skipped
Comment on failure                    → success     ← cheat-sheet 자동 게시 ✓
```

### 핵심 발견 1 — Linux BuildKit `..` normalization

```
#16 [builder 4/9] COPY ../shared/ebs_common /shared/ebs_common
#16 DONE 0.0s    ← 0초 만에 SUCCESS
```

Linux BuildKit (GitHub Actions runner) 은 `COPY ../shared/...` 의 `..` 를 silently 처리:
- 로컬 Windows BuildKit: `failed to compute cache key: "/shared/ebs_common": not found` → FAIL
- GitHub Actions Linux BuildKit: `..` 정규화/무시 → SUCCESS (의도된 violation 통과)

**결론**: 본 CI gate 는 OS 별로 다른 동작. Type A 위반이 로컬 dev 머신에서는 차단되지만 CI에서는 silent pass. **gate 의 protection 범위가 OS-bound**.

### 핵심 발견 2 — cc-web Flutter 3.22.0 cascade 회귀

cc-web Dockerfile 은 PR #18 (Flutter SDK pin) cascade 에서 누락 — 여전히 `flutter:3.22.0` 사용 중. CI 가 이를 정확히 catch:

```
#10 [builder 1/8] FROM ghcr.io/cirruslabs/flutter:3.22.0
#17 19.04 Target dart2js failed: ProcessException: Process exited abnormally with exit code 1
```

본 chaos PR 의 의도와 별개로 **PR #20 의 머지 자체를 차단하는 진짜 회귀 발견**. PR #18 이 lobby-web 만 pin → cc-web 는 동일 cascade 갭 유지 → CI gate 가 발견.

## 4. 자동 코멘트 검증 (Step 4)

```
$ gh pr view 21 --comments

author:    github-actions
association: contributor
edited:    false
status:    none
--
❌ **Team 1 Docker Build Gate failed**

`docker compose --profile web build lobby-web cc-web` 가 PR head 에서 실패했습니다.

### 빈번한 cascade 갭 cheat-sheet (PR #17/#18 history 참조)

| Layer | 증상 (build log) | 가능 원인 / 1차 점검 |
|:-----:|------------------|---------------------|
| L1 | `COPY ../shared/ebs_common: not found` | docker-compose.yml `build.context` 가 `.` 이고 Dockerfile COPY paths 에 `team1-frontend/` prefix 가 있는지 |
| L2 | `Because ebs_lobby depends on intl ^X.Y` | pubspec.yaml `intl` pin 과 Flutter SDK 의 flutter_localizations pin 일치 여부 |
| L3 | `requires SDK version >=X.Y` | Dockerfile `FROM ghcr.io/cirruslabs/flutter:3.41.7` 와 dev_dependencies 의 dart sdk 요구 일치 |
| L4 | `Could not find an option named "--web-renderer"` | `--web-renderer=html` flag 폐기. 빌드 명령에서 제거 |
| L5 | `Could not find an option named "--obfuscate"` | flutter build web 은 `--obfuscate` 미지원. flag 제거 + `mkdir -p build/debug-info` 로 runtime COPY 호환 |

자세한 사후 분석: `P0_REMEDIATION_HANDOFF.md` (PR #17), `P1_FOLLOWUP_HANDOFF.md` (PR #18).
--
```

✅ **자동 코멘트 정상 게시**.

## 5. Teardown (Step 5)

```
$ gh pr close 21 --comment "..."
✓ Closed pull request garimto81/ebs_github#21 (test(chaos): Verify CI build gate and auto-comment)

$ git worktree remove C:/claude/ebs-conductor-chaos --force
(removed)

$ git branch -D work/conductor/chaos-test-ci-gate
Deleted branch work/conductor/chaos-test-ci-gate (was 852f1b8).

$ git push origin --delete work/conductor/chaos-test-ci-gate
- [deleted] work/conductor/chaos-test-ci-gate
```

✅ chaos PR closed + 로컬 brach 삭제 + 원격 brach 삭제 + worktree 제거.

## 6. 발견된 후속 작업

### P0 (즉시 — PR #20 자체 머지 가능하게)

- [ ] **`team4-cc/docker/cc-web/Dockerfile` 의 Flutter SDK pin** — `flutter:3.22.0` → `flutter:3.41.7` (PR #18 cascade 누락 보강)
- [ ] cc-web pubspec / build flags cascade 갭 점검 (lobby-web 과 동일 5-layer 가능성)

### P1 (gate 정확도 강화 — Linux BuildKit blind spot)

본 CI gate 는 Linux BuildKit 의 `..` normalization 으로 Type A 가 silent pass. 보강안:

```yaml
- name: Static Dockerfile lint — forbid context boundary violation
  run: |
    set -e
    # 모든 lobby-web/cc-web Dockerfile 에서 COPY 명령에 ../ 가 있으면 fail
    if grep -E '^\s*COPY\s+[^/].*\.\./' \
         team1-frontend/docker/lobby-web/Dockerfile \
         team4-cc/docker/cc-web/Dockerfile; then
      echo "::error::Type A regression — COPY with .. detected"
      exit 1
    fi
    echo "Dockerfile context boundary OK"
```

또는 `hadolint` Dockerfile linter 통합.

### P2 (cheat-sheet 정확도)

cheat-sheet 의 L1 항목은 "Linux BuildKit 에서는 silent pass 되므로 grep 기반 lint 를 추가로" 명시 권장.

## 7. Cross-Ownership Notify

본 chaos test 는 conductor 권한 으로 의도적 회귀 PR 생성 → close. team1/team4 decision_owner 영향 없음 (직접 코드 수정 0).

발견된 cc-web Flutter pin 누락은 **team1 + team4 cross-team 의제** — 후속 PR 에서 team4 decision_owner 인지 권장.

## 8. Active Work Claims

본 chaos test 는 일회성 검증 — 별도 claim 등록 없음 (PR #20 의 #20 claim 범위 내 검증).
