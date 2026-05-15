---
title: CI Gate Integration + ebs_v2 Cleanup Handoff
owner: conductor
tier: internal
session: work/conductor/ci-docker-build-gate
last-updated: 2026-04-28
status: PARTIAL — CI gate + README done. ebs_v2 dir shell removal blocked by Windows handle.
confluence-page-id: 3818914412
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818914412/EBS+CI+Gate+Integration+ebs_v2+Cleanup+Handoff
mirror: none
---

# CI Pre-Merge Gate Integration + Documentation Sync

## TL;DR

PR #18 후속 4-action 처리:
- **B1 ✅** PR #18 머지 확인 (`2218db9` @ 2026-04-28T05:26Z)
- **B2 ⚠ DEFER** `C:\claude\ebs_v2\` 빈 dir shell 강제 삭제 시도 — 모든 방법 실패 (Windows 파일 시스템 lock). 데이터 영향 0 (콘텐츠 100% archive 완료, PR #18). 다음 세션 재시작 후 자연 해소.
- **B3 ✅** `.github/workflows/team1-e2e.yml` 신규 — docker compose build gate (Shift-Left)
- **B4 ✅** `team1-frontend/README.md` Architecture Decisions 섹션 추가 (AD-1/2/3)

## B1 — PR #18 Merge Verification

```
$ gh pr view 18 --json state,mergedAt,mergeCommit
{
  "state": "MERGED",
  "mergedAt": "2026-04-28T05:26:05Z",
  "mergeCommit": {"oid": "2218db92268c6cc6e93f0048db3ce19a1ac113fd"}
}
```

origin/main HEAD `2218db9` 에 P1 follow-up (Sentry sidecar + Flutter pin) 반영 완료.

## B2 — ebs_v2 Empty Dir Shell Removal (BLOCKED)

### 시도한 방법 (모두 실패)

| 방법 | 결과 |
|------|------|
| `Remove-Item -Recurse -Force` (PS) | `The process cannot access the file 'C:\claude\ebs_v2'` |
| `cmd /c "rd /s /q C:\claude\ebs_v2"` | 동일 오류 |
| `rm -rf /c/claude/ebs_v2` (Git Bash) | `Device or resource busy` |
| `[System.IO.Directory]::Delete($path, $true)` (.NET) | `The process cannot access the file` |
| `Rename-Item` 후 `Remove-Item` | rename 자체가 lock 으로 실패 |

### 진단

- 디렉토리는 **빈 상태** (4K, contents 0 — 모두 PR #18 archive 시 제거됨)
- `findmnt` / `lsof` / `handle.exe` 모두 환경에 없음 → 정확한 lock holder 식별 불가
- Docker mount, volume 모두 cleanup 완료 (volume `ebs_v2_bo-data` removed)
- 추정 holder: Windows Search indexer / Defender real-time scan / VS Code workspace cache / WSL2 cross-fs handle

### 데이터 영향

**0**. 모든 콘텐츠는 archive 보존:
- `C:\claude\_archive\ebs_v2_2026-04-28.zip` (184 MB, 7464 entries, SHA256 검증)
- `C:\claude\_archive\ebs_v2_2026-04-28.README.md`

### 해소 경로

| 옵션 | 권장도 |
|------|:------:|
| 다음 Claude Code 세션 재시작 후 `rmdir C:\claude\ebs_v2` | ★★★ |
| Windows 재로그인 후 동일 명령 | ★★ |
| Sysinternals `handle.exe` 설치 → lock holder 식별 → 종료 | ★ (overhead) |
| Process Explorer 로 manual unlock | ★ (사용자 개입) |

본 PR 은 **장애 차단 항목 아님** — handoff 에 명시 + 다음 세션 인수.

## B3 — CI Pre-Merge Gate (`.github/workflows/team1-e2e.yml`)

### 설계

```yaml
name: Team 1 E2E — Docker Build Verification (Shift-Left Gate)

on:
  pull_request:
    paths:
      - 'team1-frontend/**'
      - 'team4-cc/**'
      - 'shared/ebs_common/**'
      - 'docker-compose.yml'
      - '.github/workflows/team1-e2e.yml'

concurrency:
  group: team1-e2e-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

jobs:
  docker-build-gate:
    runs-on: ubuntu-latest
    timeout-minutes: 45

    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3

      - name: Build lobby-web (Type A gate)
        run: docker compose --profile web build lobby-web

      - name: Build cc-web (team4 cascade gate)
        run: docker compose --profile web build cc-web

      - name: Smoke probe — lobby-web nginx config
        run: |
          docker run --rm --entrypoint sh ebs/lobby-web:latest -c "
            grep -q 'listen *3000' /etc/nginx/conf.d/default.conf
            grep -q '/healthz' /etc/nginx/conf.d/default.conf
            ls /usr/share/nginx/html/flutter_bootstrap.js >/dev/null
          "

      - name: Smoke probe — cc-web nginx config
        run: |
          docker run --rm --entrypoint sh ebs/cc-web:latest -c "
            grep -q 'listen *3001' /etc/nginx/conf.d/default.conf
            grep -q '/healthz' /etc/nginx/conf.d/default.conf
            ls /usr/share/nginx/html/flutter_bootstrap.js >/dev/null
          "

      - name: Comment on failure
        if: failure() && github.event.pull_request != null
        uses: actions/github-script@v7
        # → cascade 갭 5-layer cheat-sheet 자동 코멘트
```

### 차단 시나리오 (5-layer cascade 회귀 자동 차단)

| Layer | 증상 | CI 결과 |
|:-----:|------|---------|
| L1 | Dockerfile COPY 경로 context 외부 참조 | `not found` build error → Exit 1 |
| L2 | pubspec intl ↔ Flutter SDK pin 충돌 | `pub get` version solve fail → Exit 1 |
| L3 | Dart SDK / patrol_finders 요구 불일치 | `requires SDK version >=X.Y` → Exit 1 |
| L4 | `--web-renderer` deprecated flag | `Could not find an option named` → Exit 1 |
| L5 | `--obfuscate` web 미지원 flag | 동일 → Exit 1 |

### 실패 시 자동 PR comment

`Comment on failure` step 이 5-layer cheat-sheet 를 PR comment 로 자동 게시. 다음 dev/세션이 동일 갭 디버깅 비용을 외부화하지 않게 함.

### Path filter rationale

Flutter 빌드는 무거움 (~20 min × 2 service). path filter 로 무관 PR 에는 비활성. 영향권:
- `team1-frontend/**` (lobby Dockerfile, source, pubspec)
- `team4-cc/**` (cc Dockerfile, source)
- `shared/ebs_common/**` (path 의존)
- `docker-compose.yml` (build context 정의)
- `.github/workflows/team1-e2e.yml` (self-modify 시 self-validate)

### Concurrency group

`team1-e2e-<pr_number>` 로 동일 PR head 에 새 commit push 시 이전 run 자동 취소 → CI 사용량 절감.

## B4 — `team1-frontend/README.md` Architecture Decisions

신규 섹션 (본문 위에 prepend):

| AD | 결정 | 핵심 |
|:--:|------|------|
| **AD-1** | Flutter SDK Pinning | `flutter:3.41.7` explicit (digest 명시), `:stable` 금지, 업그레이드 protocol 4-step 명시 |
| **AD-2** | Frontend Wiring | `EBS_BO_HOST` 단일 변수, `BO_URL/ENGINE_URL/CC_URL` 별도 env 금지, engine 직접 호출 금지 |
| **AD-3** | Build Context | compose `context: .` (root) + Dockerfile `team1-frontend/` prefix, CI gate 명시 |

추가로 README 본문이 v3 Quasar 잔재라는 경고 banner 명시 — 후속 PR 에서 본문 전체 재작성 가능.

## 변경 파일 (PR scope)

| 경로 | 변경 |
|------|------|
| `.github/workflows/team1-e2e.yml` | NEW — Docker build pre-merge gate (5-layer cascade 회귀 차단) |
| `team1-frontend/README.md` | Architecture Decisions (AD-1/2/3) prepend + v3 Quasar 잔재 경고 |
| `CI_GATE_INTEGRATION_HANDOFF.md` | NEW — 본 문서 |

> ebs_v2 빈 dir shell 은 git scope 외부 (`C:\claude\ebs_v2\`). 본 PR scope 무관.

## 다음 세션 후속 작업

### P3 (남은 cleanup, 재시작 후 즉시)

- [ ] `rmdir C:\claude\ebs_v2` (또는 `Remove-Item C:\claude\ebs_v2 -Recurse -Force`)
- [ ] `Get-ChildItem C:\claude -Directory | Where-Object Name -eq 'ebs_v2'` 로 확인

### P4 (CI gate 검증)

- [ ] 본 PR 머지 후 다음 lobby-web 변경 PR 에서 docker-build-gate workflow run 확인
- [ ] (의도적) 회귀 PR 작성 (예: Dockerfile COPY 경로 잘못 변경) → CI Exit 1 + PR comment 검증

### P5 (장기)

- [ ] team3 engine `/health` endpoint 추가 (현재 healthcheck `/`)
- [ ] team1-frontend/README.md 본문 전체 Quasar→Flutter 재작성
- [ ] dependabot 또는 renovate 로 pubspec ↔ Flutter SDK pin drift 자동 감지

## Active Work Claims

```
✅ #20 added (conductor): P2 CI docker build gate + P3 ebs_v2 cleanup + P4 README sync
   scope: .github/workflows/team1-e2e.yml, team1-frontend/README.md, CI_GATE_INTEGRATION_HANDOFF.md
```

## Cross-Ownership Notify

본 PR 은 conductor 권한 으로 team1 소유 파일 (`team1-frontend/README.md`) 직접 수정. team1 decision_owner 는 사후 review 후:
- AD-1/2/3 wording 조정 가능 (factual 변경 없음 전제)
- v3 Quasar 잔재 본문 재작성 후속 PR 진행 권장
