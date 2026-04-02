---
name: kickoff
description: "킥오프 — working 브랜치를 생성하고 backlog-agent를 호출하여 일감을 만드는 스킬. /kickoff vX.Y.Z 형태로 실행. 사용자가 킥오프, 일감 생성, 백로그 생성, 작업 시작을 언급할 때 트리거."
---

# /kickoff

working 브랜치를 생성하고, backlog-agent를 호출하여 기획 문서 기반 백로그를 만듭니다.

## 사용법

```
/kickoff v0.1.0
```

## 실행 순서

### Step 1. 버전 인자 확인

- 인자가 없으면 사용자에게 버전 입력 요청
- 형식: `vX.Y.Z` (semantic versioning)

### Step 2. 버전 검증

기존 release/, working/ 브랜치를 조회하여 버전을 검증합니다.

```bash
git branch -a | grep -E '(release|working)/'
```

#### 검증 규칙

| 상황 | 결과 |
|------|------|
| 동일 버전의 working 브랜치 존재 | **abort** — 이미 작업 중 |
| 동일 버전의 release 브랜치 존재 | **abort** — 이미 딜리버리됨 |
| 입력 버전의 Major.Minor가 기존 release보다 낮음 | **abort** — 더 높은 릴리즈가 존재 |
| 입력 버전의 Major.Minor가 기존 working보다 낮음 | **abort** — 더 높은 버전이 작업 중 |
| 입력 버전이 Patch (예: v0.2.1)이고, 해당 Major.Minor의 release가 존재 (release/v0.2.0) | **허용** — 최신 릴리즈의 핫픽스 |
| 입력 버전이 Patch이고, 해당 Major.Minor보다 높은 release가 존재 | **abort** — 옛 버전의 핫픽스 불가 |

#### 예시

```
기존: release/v0.1.0, release/v0.2.0, working/v0.3.0

/kickoff v0.1.0  → abort (release/v0.2.0 보다 낮음)
/kickoff v0.2.0  → abort (이미 릴리즈됨)
/kickoff v0.2.1  → OK (최신 릴리즈 v0.2.0의 핫픽스)
/kickoff v0.1.1  → abort (더 높은 릴리즈 v0.2.0 존재)
/kickoff v0.3.0  → abort (이미 working 중)
/kickoff v0.3.1  → abort (working 안에서 패치하면 됨)
/kickoff v0.4.0  → OK
```

### Step 3. 현재 브랜치 확인

- main 브랜치에서 실행해야 함
- main이 아닌 경우 사용자에게 경고 후 확인

### Step 4. working 브랜치 생성

```bash
git checkout main
git pull origin main  # remote가 있는 경우
git checkout -b working/{version}
```

### Step 5. Backlog Agent 호출

`.claude/agents/backlog-agent.md`를 호출하여 백로그 생성을 위임합니다.

에이전트에게 전달하는 정보:
- 버전: `{version}`
- 브랜치: `working/{version}`

에이전트가 이후 모든 작업을 수행합니다:
- 저장소 기획 문서 탐색
- Confluence 페이지 매칭
- Epic/Story 백로그 생성
- 백로그 인덱스 생성
- 결과 보고

## 주의사항

- 기존 backlogs/가 이미 있는 경우 덮어쓰지 않고 사용자에게 확인
- 문서가 없거나 부족한 경우 사용자에게 알림
