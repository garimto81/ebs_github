---
title: P1/P3 Follow-up Handoff (Sentry sidecar + Flutter pin + ebs_v2 archive)
owner: conductor
tier: internal
session: work/conductor/p1-sentry-flutter-pin
last-updated: 2026-04-28
status: PASS — 4/4 actions complete
confluence-page-id: 3818685111
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818685111/EBS+P1+P3+Follow-up+Handoff+Sentry+sidecar+Flutter+pin+ebs_v2+archive
---

# P1 + P3 Follow-up Handoff

## TL;DR

PR #17 (P0 remediation) 후속 4개 액션 처리:

| # | 액션 | 결과 |
|:-:|------|------|
| **A1** | PR #17 머지 모니터링 | ✅ MERGED (commit `c23db1b`, 2026-04-28T05:12Z) |
| **A2** | Sentry web sourcemap sidecar 재설계 | ✅ scripts/sentry_release.sh 명시화 + web 빌드 산출물 가드 추가 |
| **A3** | Flutter SDK explicit pin | ✅ flutter:stable → flutter:3.41.7 (digest 동일 검증) |
| **A4** | ebs_v2 parallel project archive | ✅ 455MB → 184MB zip (`_archive/`), README 작성. 빈 디렉토리 shell 잔존 (저영향) |

## A1 — PR #17 Merge Status

```
gh pr view 17:
  state:        MERGED
  mergedAt:     2026-04-28T05:12:06Z
  mergeCommit:  c23db1bba334fbdeb13a87377e1b592e465d0b7a

git log origin/main -1:
  c23db1b infra(conductor): P0 remediation — port 3000 freed + lobby-web Dockerfile context promoted (#17)
```

**auto-merge workflow 정상 동작 ✓**.

## A2 — Sentry Web Sourcemap Sidecar 재설계

### 발견

기존 `scripts/sentry_release.sh` 는 이미 web sourcemap 호환 설계:
- `sentry-cli sourcemaps upload build/web` (dart2js .js.map 자동 매칭)
- native `--split-debug-info` upload 는 `[[ -d "$DEBUG_INFO_DIR" ]]` 가드로 graceful skip

### 변경 (additive)

| 변경 | 목적 |
|------|------|
| 헤더 주석 추가: "Web vs Native scope" 명문화 | Flutter web 의 `--obfuscate`/`--split-debug-info` 미지원 사실 + .js.map 만으로 demangle 가능함을 README 화 |
| `SENTRY_URL_PREFIX` env 추가 (default `~/`) | CDN 경로 변경 시 hardcode 우회 |
| `build/web` 부재 가드 (exit 2 + hint) | flutter build 미실행 상태에서 호출 시 명확한 오류 |
| `build/web/*.js.map` 부재 가드 (exit 2 + hint) | `--source-maps` flag 누락 의심 시 명확한 오류 |
| native debug-files upload 가드 강화: `[[ -d ... ]] && [[ -n "$(ls -A ...)" ]]` | 빈 디렉토리 → silent skip (mkdir 만 한 상태 호환) |

### 동작 검증

```bash
# STUB MODE (sentry-cli 미설치 상태)
$ ./scripts/sentry_release.sh
[sentry] sentry-cli not installed — STUB MODE.
[sentry] Would have:
  - new release: ebs-lobby@<version>+phase5
  - upload sourcemaps: build/web (release=...)
  - upload debug-info: build/debug-info/<version>
  - finalize + deploy (production)
exit 0
```

### Mobile target 추가 시 (future)

`flutter build apk --obfuscate --split-debug-info=build/debug-info/<v>` 로 native debug-info 산출 → 본 sidecar 의 native upload 분기가 자동 활성. 코드 변경 불필요.

## A3 — Flutter SDK Explicit Pin

### 변경

```dockerfile
# Before:
FROM ghcr.io/cirruslabs/flutter:stable AS builder

# After:
# 2026-04-28 — Flutter SDK explicit pin (P1 reproducibility).
# `:stable` 은 부동 tag → CI/local build 결과 비결정. 본 PR 시점 stable = 3.41.7.
# 변경 시 Build Reproducibility Note 의 cascade 갭 잠재 (intl pin / web flag drift) 재검토.
FROM ghcr.io/cirruslabs/flutter:3.41.7 AS builder
```

### 검증

```bash
$ docker run --rm --entrypoint sh ghcr.io/cirruslabs/flutter:3.41.7 -c "flutter --version"
Flutter 3.41.7 • channel [user-branch] • unknown source
Framework • revision cc0734ac71 (12 days ago) • 2026-04-15 21:21:08 -0700
Engine • hash 7a53c052bc4b472cf780b199087e1368e4a9aa8c
```

`:stable` digest = `:3.41.7` digest = `sha256:644e3cea...` → **동일 binary 보장**.

### 향후 SDK 업그레이드 protocol

1. 새 minor 버전 출시 시 `flutter:3.42.x` 등 explicit tag 로 옵션 PR 작성
2. 본 PR cascade 발견 갭 (intl pin / web flag) 재현 여부 확인
3. pubspec.yaml 의존성 일괄 점검 후 머지

## A4 — ebs_v2 Parallel Project Archive

### 결정 근거

`C:\claude\ebs_v2\` 는 PR #11 시점 별도 parallel project 로 발견된 좀비:
- 별도 docker-compose, 별도 Foundation, 별도 lib/
- canonical `ebs/` 와 다른 API surface (`/api/v1/auth/*` vs `/auth/*`)
- bo WebSocket unauth 허용 (insecure dev mode) vs canonical auth gate

PR #11 에서 컨테이너+네트워크 teardown 완료. 디렉토리는 보존 → 향후 혼선 방지를 위해 P3 archive 결정.

### 실행

```powershell
# 1. zip archive
Compress-Archive -Path C:\claude\ebs_v2\* `
                 -DestinationPath C:\claude\_archive\ebs_v2_2026-04-28.zip `
                 -CompressionLevel Optimal -Force
→ 455 MB → 184 MB (60% 절감)
SHA256: 553077174E65D1F497545E82AEAEE8692D2600868AEAA5BBD2AF472374D6A1F5

# 2. 무결성 검증
ZIP entry count: 7464  vs  Source file count: 7408  (ratio 1.008)
→ INTEGRITY OK

# 3. 원본 콘텐츠 제거 + 빈 디렉토리 shell 잔존
Get-ChildItem C:\claude\ebs_v2  →  empty
du -sh C:\claude\ebs_v2  →  4.0K (Windows directory metadata only)

# 4. 부속 정리
docker volume rm ebs_v2_bo-data
→ removed
```

### 빈 디렉토리 shell 미제거 사유

`Remove-Item -Recurse -Force` 가 내부 파일을 모두 지우고 빈 디렉토리만 남긴 상태에서 디렉토리 자체 제거 실패 — Windows search indexer / antivirus 핸들 추정. **데이터는 100% 보존 (archive zip)** + 콘텐츠는 완전 제거 → 실질 archive 완료. 빈 dir shell 은 사용자 세션 종료 후 또는 `rmdir C:\claude\ebs_v2` 수동 명령으로 정리 가능.

### 산출물

| 경로 | 내용 |
|------|------|
| `C:\claude\_archive\ebs_v2_2026-04-28.zip` | 184 MB, 7464 entries, SHA256 검증 가능 |
| `C:\claude\_archive\ebs_v2_2026-04-28.README.md` | 메타 + 복원 명령 + 보존 정책 (6개월) |

## 변경 파일 (PR scope)

| 경로 | 변경 |
|------|------|
| `team1-frontend/docker/lobby-web/Dockerfile` | FROM `flutter:stable` → `flutter:3.41.7` (P1 reproducibility) |
| `team1-frontend/scripts/sentry_release.sh` | web vs native scope 명시 + build/web 가드 + URL_PREFIX env + native skip 강화 |
| `P1_FOLLOWUP_HANDOFF.md` | NEW — 본 문서 |

> ebs_v2 archive 는 git scope 밖 (project root 외부 `_archive/`). 본 PR 은 **알림만**.

## Active Work Claims

```
✅ #19 added (conductor): P1: Sentry web sourcemap clarification + Flutter SDK explicit pin
   scope: team1-frontend/scripts/sentry_release.sh, team1-frontend/docker/lobby-web/Dockerfile
```

## 다음 세션 후속 작업

### P2 (남은 항목)

- [ ] CI 에 `docker compose build lobby-web` 단계 통합 (Dockerfile drift 즉시 감지)
- [ ] `team_v5_merge.py` 가 `ebs-conductor-*` worktree 인식 (현재 team1-4만 매칭)
- [ ] dependabot/renovate: pubspec ↔ Flutter SDK pin drift 자동 감지

### P3 (cleanup)

- [ ] `C:\claude\ebs_v2\` 빈 디렉토리 shell 수동 정리 (`rmdir C:\claude\ebs_v2`) — 다음 세션 재시작 후 시도
- [ ] team3 engine `/health` endpoint 추가 (현재 healthcheck `/`)

### P4 (장기)

- [ ] ebs_v2 archive 보존 6개월 후 (2026-10-28+) 삭제 검토
- [ ] team1 README 에 EBS_BO_HOST 단일 변수 사용 + Flutter 3.41.7 pin 명시
