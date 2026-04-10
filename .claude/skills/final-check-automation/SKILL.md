---
name: final-check-automation
description: >
  FINAL_CHECK 워크플로우 자동화. E2E 테스트, Phase 3-5 자동 진행.
version: 2.0.0

triggers:
  keywords:
    - "E2E"
    - "최종 검증"
    - "Phase 5"
    - "FINAL_CHECK"
    - "배포 전"
    - "playwright"
  file_patterns:
    - "tests/e2e/**/*"
    - "**/*.spec.ts"
  context:
    - "배포 전 검증"
    - "E2E 테스트 실행"

capabilities:
  - run_final_check
  - e2e_test
  - security_audit
  - version_decision

model_preference: sonnet

phase: [5]
auto_trigger: true
dependencies:
  - test-engineer
  - security-auditor
token_budget: 2000
---

# FINAL_CHECK Automation

구현 완료 후 최종 검증 워크플로우입니다.

## Quick Start

```bash
# 전체 FINAL_CHECK 실행
python .claude/skills/final-check-automation/scripts/run_final_check.py

# E2E만 실행
python .claude/skills/final-check-automation/scripts/run_final_check.py --e2e-only

# 보안 스캔만 실행
python .claude/skills/final-check-automation/scripts/run_final_check.py --security-only
```

## 워크플로우

```
Phase 2 완료
    ↓
FINAL_CHECK 시작
    ↓
┌──────────────────────────────────────┐
│ Step 1: E2E 테스트                   │
│   npx playwright test                │
│   실패 시 → 자동 수정 (최대 3회)      │
└──────────────────────────────────────┘
    ↓ (100% 통과)
┌──────────────────────────────────────┐
│ Step 2: Phase 3 (버전 결정)          │
│   Conventional Commits 분석          │
│   MAJOR/MINOR/PATCH 결정             │
└──────────────────────────────────────┘
    ↓
┌──────────────────────────────────────┐
│ Step 3: Phase 4 (PR 생성)            │
│   gh pr create                       │
│   validate-phase-4.ps1               │
└──────────────────────────────────────┘
    ↓
┌──────────────────────────────────────┐
│ Step 4: Phase 5 (보안 검증)          │
│   Security scan                      │
│   Performance check                  │
│   validate-phase-5.ps1               │
└──────────────────────────────────────┘
    ↓
┌──────────────────────────────────────┐
│ Step 5: Phase 6 (배포)               │
│   ⚠️ 사용자 확인 필수                │
└──────────────────────────────────────┘
```

## Step 1: E2E 테스트

### 실행 방법

```powershell
# 전체 E2E 테스트
npx playwright test

# UI 모드 (디버깅)
npx playwright test --ui

# 단일 파일
npx playwright test tests/e2e/flow.spec.ts

# 스크린샷 저장
npx playwright test --screenshot=on
```

### 실패 처리

| 시도 | 동작 |
|------|------|
| 1회 실패 | 스크린샷/로그 분석 → 자동 수정 |
| 2회 실패 | selector 재검증 → 수정 |
| 3회 실패 | ⏸️ `/issue-failed` → 수동 개입 |

### webapp-testing 스킬 활용

```bash
# 서버 자동 관리
python .claude/skills/webapp-testing/scripts/with_server.py \
  --server "npm run dev" --port 3000 \
  -- npx playwright test
```

## Step 2: Phase 3 (버전 결정)

### Conventional Commits 분석

```bash
# 커밋 분석
git log --oneline <base>..HEAD

# 버전 결정 규칙
feat!: BREAKING CHANGE → MAJOR
feat:  새 기능        → MINOR
fix:   버그 수정      → PATCH
```

### 버전 태그

```bash
# 현재 버전 확인
git describe --tags --abbrev=0

# 새 버전 태그
git tag -a v1.2.3 -m "Release v1.2.3"
```

## Step 3: Phase 4 (PR 생성)

### PR 생성

```bash
gh pr create \
  --title "feat(scope): Description" \
  --body "## Summary
- Change 1
- Change 2

## Test Plan
- [ ] E2E passed
- [ ] Security scan passed

🤖 Generated with Claude Code"
```

### 검증

```powershell
.\scripts\validate-phase-4.ps1
```

## Step 4: Phase 5 (보안 검증)

### 보안 스캔

```bash
# Python 의존성 취약점
pip-audit

# npm 의존성 취약점
npm audit

# 시크릿 스캔
trufflehog git file://. --only-verified
```

### 성능 체크

```bash
# Lighthouse (웹)
npx lighthouse http://localhost:3000 --output=json

# pytest 성능 (Python)
pytest --benchmark-only
```

### 검증

```powershell
.\scripts\validate-phase-5.ps1
```

## Step 5: Phase 6 (배포)

⚠️ **사용자 확인 필수**

### 자동 진행 중지 조건

| 조건 | 중지 |
|------|------|
| MAJOR 버전 업그레이드 | ⏸️ |
| Critical 보안 취약점 | ⏸️ |
| 배포 단계 | ⏸️ |
| 3회 연속 실패 | ⏸️ |

### 배포 체크리스트

- [ ] 모든 테스트 통과
- [ ] 보안 스캔 통과
- [ ] PR 승인됨
- [ ] 릴리스 노트 작성
- [ ] 배포 환경 확인

## 에이전트 활용

| 단계 | 에이전트 |
|------|----------|
| E2E 테스트 | `playwright-engineer` |
| 보안 스캔 | `security-auditor` |
| 코드 리뷰 | `code-reviewer` |
| 성능 체크 | `performance-engineer` |

### 병렬 실행 (Agent Teams 패턴)

```
# Step 1: 팀 생성
TeamCreate(team_name="final-check")

# Step 2: 병렬 검증 에이전트 스폰
Agent(
  subagent_type="qa-tester",
  name="e2e-checker",
  description="E2E 최종 검증",
  team_name="final-check",
  model="sonnet",
  prompt="E2E 최종 검증을 실행하세요: npx playwright test"
)

Agent(
  subagent_type="security-reviewer",
  name="security-checker",
  description="보안 점검",
  team_name="final-check",
  model="sonnet",
  prompt="보안 점검을 실행하세요: pip-audit, npm audit, trufflehog"
)

Agent(
  subagent_type="architect",
  name="perf-checker",
  description="성능 테스트",
  team_name="final-check",
  model="sonnet",
  prompt="성능 테스트를 실행하세요: Lighthouse, pytest --benchmark-only"
)

# Step 3: 완료 후 정리
SendMessage(to="e2e-checker", message={type: "shutdown_request"})
SendMessage(to="security-checker", message={type: "shutdown_request"})
SendMessage(to="perf-checker", message={type: "shutdown_request"})
TeamDelete()
```

## 관련 도구

| 도구 | 용도 |
|------|------|
| `scripts/run_final_check.py` | 전체 자동화 |
| `webapp-testing` Skill | E2E 테스트 |
| `validate-phase-*.ps1` | Phase 검증 |
| `/final-check` | 기존 Command (deprecated) |

---

> 관련: CLAUDE.md 섹션 4 Phase Pipeline
