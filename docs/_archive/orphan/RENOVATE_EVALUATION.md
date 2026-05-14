---
title: Renovate vs Dependabot Evaluation
owner: conductor
tier: internal
last-updated: 2026-04-28
status: DECISION — Stay on Dependabot for now (revisit Q4 2026)
related-pr: "#26 (Dependabot 6 ecosystem 도입), #27 (P6 확장 + 본 평가)"
confluence-page-id: 3819602516
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819602516/EBS+Renovate+vs+Dependabot+Evaluation
---

# Renovate vs Dependabot — 결정 매트릭스

## TL;DR

**Dependabot 유지** (PR #26/#27 구성 그대로). Renovate 의 grouping/scheduled-rebase 장점은 인지하나, EBS 의 현 7 ecosystem × 요일 stagger 구성은 Dependabot 으로 충분히 cover 됨. GitHub App install 오버헤드와 config 복잡도가 현 시점에서는 ROI 부족. **Q4 2026 재평가** 트리거: (a) Dependabot PR 주간 평균 5건+ 도달, (b) 동일 의존성 그룹의 cascade 회귀가 dependabot 의 monorepo grouping 부재로 반복 발생, (c) actions/checkout 같은 한 PR 단위 bump 가 6개+ workflow 에 동시 영향.

## 평가 매트릭스

| 항목 | Dependabot (현 사용) | Renovate (대안) | 본 프로젝트 영향 |
|------|----------------------|-----------------|-----------------|
| **License** | GitHub-native (free) | Open source / WhiteSource (free for OSS) | 동일 |
| **설치 오버헤드** | `.github/dependabot.yml` 1 파일 | GitHub App install + `renovate.json` config | Dependabot 우세 (zero-friction) |
| **Manifest 지원** | pub, pip, docker, github-actions, npm, gradle 등 표준 | Dependabot + 추가 (helm, terraform, regex custom 등) | EBS 사용 ecosystem 모두 cover (양쪽 동일) |
| **Schedule 유연성** | weekly + day-of-week 만 (hour 1단위) | cron syntax (분 단위, hour 윈도우, etc.) | EBS 요일 stagger 충분 (Dependabot OK) |
| **Grouping** | open-pull-requests-limit 만 (그룹 PR 없음) | `groupName` + `packagePatterns` 로 minor/patch 묶음 | 향후 평가 항목 — Flutter SDK + intl 같은 cascade 묶음 가능 |
| **Auto-merge** | label 기반 (PR #26 사용 중) | `automerge: true` + 조건 매트릭스 (테스트 통과 시 등) | EBS 의 v5 free-tier auto-merge workflow 와 호환성 — Dependabot label 기반이 단순 |
| **Scheduled rebase** | 수동 또는 새 PR | `rebaseSchedule` 자동 | Dependabot 은 conflict 시 사용자 개입 필요 |
| **Vulnerability alerts** | 강함 (GitHub Security 통합) | 동등 (CVE 데이터베이스 연동) | 양쪽 동일 |
| **Monorepo path filter** | `directory:` 단일 경로 만 | `matchPaths` glob | EBS 7 ecosystem × 단일 경로 — Dependabot OK |
| **PR 노이즈 제어** | `versioning-strategy` 만 | `ignoreUnstable`, `internalChecksFilter` 등 다양 | EBS 의 `increase-if-necessary` 로 충분 |
| **Versioning 전략** | major/minor/patch separation 없음 | `separateMajorMinor`, `separateMinorPatch` | 향후 major bump 분리 시 평가 가치 |
| **Custom regex** | 미지원 | `regexManagers` 로 임의 파일 의존성 추적 | EBS 의 Dockerfile FROM 자동 추적은 native — 미사용 |
| **CI run cost (PR 당)** | 동일 (CI 가 본질) | 동일 | Renovate의 grouping이 PR 수 절감 → CI minutes 절감 가능 |

## 현 Dependabot 구성 강점 (PR #26/#27 기준)

1. **요일 stagger (7 ecosystem × 7 day)** — 일요일 신규 추가 후 매일 1-2 ecosystem PR 만 생성. CI flood 0건.
2. **3-tier CI gate (PR #20/#22/#26)** — Dependabot PR 도 `dockerfile-lint + hadolint + docker-build-gate` 통과해야 머지. cascade 회귀 자동 차단.
3. **auto-merge label segregation** — pub/github-actions 는 자동, docker (Flutter SDK) 는 수동. 위험도 별 정책 분리.
4. **PR #21 (chaos test) 검증** — gate 가 의도된 회귀를 정확히 catch. dependabot 의 자동 PR 도 동일 gate 통과.

## Renovate 채택 시 추가 가치 (현재 미발현)

1. **Grouping**: `freezed + freezed_annotation + json_serializable + json_annotation` 같은 codegen 묶음을 한 PR 로 → minor 버전 동기화 보장.
2. **Major separation**: Flutter SDK major bump (3 → 4) 같은 high-impact 변경을 별도 PR 로 분리 → review 우선순위 명확화.
3. **Scheduled rebase**: stale dependabot PR 이 main 과 conflict 발생 시 수동 rebase 부담 → renovate 자동.
4. **Custom managers**: `production.json` 같은 비표준 파일의 의존성 (e.g., Sentry DSN 버전) 추적.

## 결정 근거

**현 시점 Dependabot 유지** 이유:
- (1) 7 ecosystem × 주 1회 = 평균 PR 7건/주. Grouping 없이도 review 부담 적정.
- (2) 3-tier CI gate 가 cascade 차단 핵심. Renovate 의 grouping 으로 묶어도 본질적 안전망은 gate 자체.
- (3) GitHub App install 오버헤드 (사용자 권한 부여, 설정 마이그레이션) 가 현 ROI 정당화 안 됨.
- (4) Dependabot 의 native GitHub Security 통합이 Renovate 보다 약간 우세 (CVE 알림 + dependency graph).

## 재평가 트리거 (Q4 2026 또는 아래 조건 시)

- [ ] **PR 주간 평균 5건+ 도달**: review 부담이 grouping 정당화하기 시작 (현재 ~7건 예상이지만 실측 후 판단)
- [ ] **동일 cascade 회귀가 dependabot grouping 부재로 반복**: 예) 매주 Flutter SDK + intl PR 이 같이 와야 하는데 따로 와서 첫 PR 만 머지하면 회귀 발생
- [ ] **actions/checkout 같은 단일 bump 가 6개+ workflow 에 영향**: 한 PR 로 묶여야 의미 있음 (현재는 workflow 1개 = team1-e2e.yml + flutter-checks.yml 2개. 그러나 향후 증가 가능)
- [ ] **Dependabot 의 PR 가 main 과 stale 되어 수동 rebase 시간 비용이 누적**: scheduled-rebase 가 핵심 가치 됨

재평가 시 측정 항목:
- Dependabot PR 평균 머지까지 시간 (PR open → merge)
- Manual rebase 발생 빈도
- Review 시 반려/수정 비율 (auto-merge 적합도)

## 마이그레이션 경로 (참고용 — 채택 결정 시)

1. Renovate GitHub App install (`https://github.com/apps/renovate`)
2. `renovate.json` 작성 — 본 dependabot.yml 의 7 ecosystem 을 `packageRules` 로 변환
3. `auto-merge` workflow 호환성 검증 — Renovate 의 `automerge: true` vs label-based
4. 1주일 shadow mode (둘 다 활성, 결과 비교) 후 dependabot 제거

## 관련 PR

- **#26** — Dependabot 6 ecosystem 도입 (Mon~Sat)
- **#27** — P6 확장 (team3 pub + team2 pip on Sun) + 본 평가 문서
- 향후 — 재평가 트리거 도달 시 신규 PR 로 Renovate 채택 또는 본 결정 갱신

## Cross-references

- `.github/dependabot.yml` — 현 7 ecosystem 구성
- `.github/workflows/team1-e2e.yml` — 3-tier docker gate (PR #20/#22/#26)
- `.github/workflows/flutter-checks.yml` — analyze + test gate (PR #27)
- Renovate docs: https://docs.renovatebot.com/
- Dependabot docs: https://docs.github.com/en/code-security/dependabot
