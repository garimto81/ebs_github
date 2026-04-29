---
title: Dependabot Governance — Label / Major Gate / Recreate Guard
owner: conductor
tier: internal
last-updated: 2026-04-28
related-pr: "#26 (dependabot 6 ecosystem), #41 (P5+P6 7 ecosystem), #28 (본 governance), #33 (첫 dependabot PR 사례)"
status: ACTIVE
---

# Dependabot 거버넌스 정책 (post-#28)

## TL;DR

PR #33 (web_socket_channel 2.x→3.x) 이 라벨 누락 + CI 미트리거 + major bump auto-merge 패턴을 노출. 본 문서는 다음 dependabot PR 자동화의 3 가지 가드를 정의한다:

1. **label-guard** (`pull_request_target`) — title prefix 분석 → 누락 라벨 자동 보정
2. **major-gate** (`pull_request_target`) — semver-major auto-merge 차단, `approved-major` 라벨로 override
3. **recreate-guard** (scheduled) — CI 미트리거 PR detect → `@dependabot recreate` 댓글

모두 `github.actor == 'dependabot[bot]'` 가드로 한정.

## 정책 1 — Label Guard

### 목적
`.github/dependabot.yml` 의 `labels:` 명시는 dependabot 이 PR 작성 시 적용한다. 다만 config 갱신 직후 봇이 갱신 전 cached 정책으로 PR 작성 가능 (실증: PR #33). 본 가드 가 누락 라벨 자동 부착.

### Title prefix → 의도 라벨 매핑

| PR title prefix | team 라벨 | docker | auto-merge | needs-manual-review |
|------------------|:---------:|:------:|:----------:|:-------------------:|
| `chore(deps:team1)`     | team1 | ✗ | ✓ | ✗ |
| `chore(deps:team2)`     | team2 | ✗ | **✗** (Python ABI 위험) | ✗ |
| `chore(deps:team3)`     | team3 | ✗ | ✓ | ✗ |
| `chore(deps:team4)`     | team4 | ✗ | ✓ | ✗ |
| `chore(deps:ci)`        | ci    | ✗ | ✓ | ✗ |
| `chore(docker:lobby)`   | team1 | ✓ | **✗** (Flutter SDK cascade 위험) | ✗ |
| `chore(docker:cc)`      | team4 | ✓ | **✗** | ✗ |
| `chore(docker:engine)`  | team3 | ✓ | **✗** | ✗ |

### 워크플로 파일
`.github/workflows/dependabot-label-guard.yml`

### 검증 기준
- [ ] 다음 3 개 dependabot PR 에서 `labels` 자동 부착 100%
- [ ] 누락 시 1 분 내 자동 보정
- [ ] 타 작성자 PR 영향 0 건

## 정책 2 — Semver Major Gate

### 목적
PR #33 (web_socket_channel 2.4.5→3.0.3) 같은 major bump 가 CI 통과만으로 auto-merge 되는 것을 차단. 사람 review 강제.

### 정책

| update-type | auto-merge | 자동 액션 |
|-------------|:----------:|----------|
| `version-update:semver-major` (default) | ✗ | `auto-merge` 라벨 제거 + `needs-manual-review` 부착 + 댓글 |
| `version-update:semver-major` + `approved-major` 라벨 | ✓ | 통과 (사람 명시 승인) |
| `version-update:semver-minor` | ✓ | 변화 없음 — 3-tier gate 통과 시 자동 머지 |
| `version-update:semver-patch` | ✓ | 변화 없음 |

### Override 절차

major bump PR 에 사람이 review 후 의도된 변경이라고 판단:
1. PR diff + release notes + transitive lockfile 변화 확인
2. 직접 사용 사이트 (`grep -rn <package>`) 영향 확인
3. 관련 테스트 통과 확인 (3-tier CI gate)
4. **`approved-major` 라벨 부착** → major-gate 가 자동 감지 후 통과 → 기존 auto-merge workflow 가 머지

### 워크플로 파일
`.github/workflows/dependabot-major-gate.yml`

### 검증 기준
- [ ] semver-major PR 이 자동으로 머지 안 됨 (`approved-major` 부재 시)
- [ ] `approved-major` + `auto-merge` 라벨 동시 부착 시 정상 머지
- [ ] minor/patch 는 정책 변화 없음

### Future: CODEOWNERS 통합
major bump 시 자동 reviewer 배정 — 본 PR scope 외, 별도 PR 로 도입 검토.

## 정책 3 — Recreate Guard (CI Trigger Stabilization)

### 목적
PR #33 첫 push 시 GitGuardian 외 CI 미실행 — `@dependabot recreate` 후 정상 트리거. 산발적 패턴이지만 운영자 수동 개입 필요. 본 가드가 자동 detect + recreate.

### 동작 시퀀스 (10분 간격 scheduled)

1. open 상태 dependabot[bot] PR 목록 조회
2. 각 PR 의 head SHA 에 대한 check_runs 조회
3. PR 생성 5 분 경과 + meaningful checks 0 (GitGuardian 외) 인 경우:
   - 최근 30 분 내 본 가드의 recreate 댓글 있으면 skip (anti-spam)
   - 없으면 `@dependabot recreate` 댓글 작성
4. dependabot 봇이 PR 재생성 → CI 정상 트리거

### 워크플로 파일
`.github/workflows/dependabot-recreate-guard.yml`

### 검증 기준
- [ ] 다음 10 개 dependabot PR 에서 CI 착수 p95 < 60 초
- [ ] 미트리거 발생 시 자동 recreate 5 분 내 수행
- [ ] 일반 기여자 PR 영향 0 건

## 보안 고려

### `pull_request_target` trigger 의 위험

GitHub Actions `pull_request_target` 은 **base repo context** 로 실행됨 → secrets 접근 + write permissions. PR HEAD 코드를 checkout 하거나 실행하면 supply-chain attack 가능.

본 워크플로 모두 다음 원칙 준수:
- ✅ `if: github.actor == 'dependabot[bot]'` 가드 — 타 작성자 PR 차단
- ✅ `actions/checkout` 미사용 OR `ref: ${{ github.event.pull_request.base.sha }}` (base 사용)
- ✅ only API operations (label/comment/fetch-metadata)
- ❌ PR HEAD 코드 실행 금지

## 라벨 사전 (post-#28)

| 라벨 | 색상 | 의미 |
|------|------|------|
| `auto-merge` | green (#0E8A16) | 3-tier CI 통과 시 자동 머지 |
| `dependencies` | blue (#0366d6) | dependabot/renovate 의존성 PR |
| `team1` ~ `team4` | yellow (#fbca04) | 팀 소유 |
| `docker` | cyan (#0db7ed) | Docker base image 업데이트 |
| `ci` | purple (#5319e7) | CI/CD workflow 업데이트 |
| **`needs-manual-review`** | **red (#B60205)** | **major bump 차단됨, 사람 review 필요** |
| **`approved-major`** | **green (#0E8A16)** | **major bump 사람 승인됨, auto-merge 허용** |

## 메트릭 (관측 권장)

| 지표 | 목표 | 측정 |
|------|------|------|
| Dependabot PR labels 부착율 | 100% | label-guard log |
| semver-major 자동 머지율 | 0% (default) | major-gate notice log |
| Dependabot PR 최초 CI 착수 p50 | < 60 초 | recreate-guard notice log |
| Dependabot PR 최초 CI 착수 p95 | < 5 분 | 동상 |

dashboarding 은 별도 PR 에서 (예: GitHub Insights API + Grafana 또는 simple weekly report).

## 변경 이력

| 날짜 | PR | 변경 |
|------|-----|------|
| 2026-04-28 | #28 (본 PR) | label-guard + major-gate + recreate-guard 도입 |
| (이전) | #33 | 첫 dependabot PR — 본 governance 의 동기 |
| (이전) | #41 | P5+P6 — 7 ecosystem dependabot 완성 |
| (이전) | #26 | P3 — dependabot 6 ecosystem 도입 |

## 관련 PR / 문서

- `.github/dependabot.yml` — 7 ecosystem 정의
- `.github/workflows/pr-auto-merge.yml` — v5.0 free-tier auto-merge
- `.github/workflows/team1-e2e.yml` — 3-tier CI gate (dockerfile-lint + hadolint + build)
- `.github/workflows/flutter-checks.yml` — flutter analyze + test (alpha mode)
- `docs/4. Operations/RENOVATE_EVALUATION.md` — Dependabot vs Renovate 결정
- `docs/4. Operations/CI_CHAOS_TEST_HANDOFF.md` — chaos test 결과 (PR #21)

## Note: claim system 부재

PR #63 (`feat(governance): v8.0 복원 — selective restore`) 시점에 `tools/active_work_claim.py` 가 제거됨 (v8.0 거버넌스 변경). 본 PR 은 claim 없이 진행. 향후 dependabot 거버넌스 변경 시 v8.0 후속 메커니즘 (예: `team-policy.json` decision_owner 직접 update) 사용.
