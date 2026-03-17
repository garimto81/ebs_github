---
name: issue
description: >
  This skill should be used when the user requests GitHub issue management including listing, creating, fixing, or triaging issues.
version: 1.1.0
triggers:
  keywords:
    - "/issue"
    - "이슈 관리"
    - "github issue"
    - "버그 리포트"
auto_trigger: false
---

# /issue — GitHub Issue 통합 관리

이슈의 전체 생명주기를 관리합니다: 조회, 생성, 수정, 해결, 실패 분석

## Usage

```
/issue <action> [args]

Actions:
  list [filter]     이슈 목록 조회
  create [title]    새 이슈 생성
  edit <number>     이슈 수정 (상태, 라벨, 담당자)
  fix <number>      이슈 해결 (브랜치 → 구현 → PR)
  failed [number]   실패 분석 및 새 솔루션 제안
```

---

## /issue list

```bash
/issue list              # 열린 이슈 전체
/issue list mine         # 내게 할당된 이슈
/issue list label:bug    # 라벨별 필터
/issue list 123          # 특정 이슈 상세
```

실행 명령어:
```bash
gh issue list                          # 기본
gh issue list --assignee @me           # 내 이슈
gh issue list --label bug              # 라벨 필터
gh issue view <number> --comments      # 상세 + 코멘트
```

---

## /issue create

```bash
/issue create "로그인 타임아웃 버그"
/issue create "새 기능 요청" --labels=enhancement
```

1. 제목, 유형(bug/feature/docs/refactor), 설명, 라벨 수집
2. 유형별 템플릿 적용 (Bug: 재현방법+기대동작, Feature: 배경+제안구현)
3. 실행: `gh issue create --title "[제목]" --body "[본문]" --label "[라벨]"`

---

## /issue edit

```bash
/issue edit 123 --close              # 이슈 닫기
/issue edit 123 --label bug          # 라벨 추가
/issue edit 123 --assignee @me       # 담당자 할당
/issue edit 123 --milestone v1.0     # 마일스톤 설정
```

실행 명령어:
```bash
gh issue close <number>
gh issue reopen <number>
gh issue edit <number> --add-label "bug,high-priority"
gh issue edit <number> --add-assignee @me
gh issue edit <number> --milestone "v1.0"
```

---

## /issue fix

이슈를 분석하고 브랜치 생성 → 구현 → PR까지 자동 실행합니다.

### Workflow

1. **Fetch**: `gh issue view <number>` — 요구사항 추출
2. **Analyze**: 관련 코드 리뷰, 근본 원인 파악
   - confidence >= 80% → 직접 수정
   - confidence < 80% → `/debug` 자동 트리거
3. **Branch**: `git checkout -b fix/issue-<number>-<description>`
4. **Implement**: 수정 + 테스트 작성
5. **PR**: `Fixes #<number>` 참조로 PR 생성 (GitHub 자동 연결)

### 연동 에이전트

| 단계 | 에이전트 | 역할 |
|------|---------|------|
| 원인 분석 | `Agent(subagent_type="architect", description="근본 원인 분석")` | 근본 원인 파악 |
| 원인 불명확 | `/debug` | 가설-검증 사이클 |
| 코드 수정 | `Agent(subagent_type="executor", description="이슈 수정 구현")` | 구현 |
| 테스트 | `Agent(subagent_type="qa-tester", description="수정 검증")` | 테스트 작성 |

---

## /issue failed

이전 해결 시도가 실패한 경우, 분석 후 새 솔루션을 제안합니다.

```bash
/issue failed 123
/issue failed         # 대화형 정보 수집
```

### 실행 절차

1. **정보 수집**: 이슈 번호, 시도한 솔루션, 실패 증상, 에러 로그
2. **분석**: 1차 원인 + 근본 원인 파악, 검토 영역 체크
3. **솔루션 제안**: 3개 대안 (수정된 접근/대안적 접근/우회 방법) + 예상 성공률
4. **GitHub 업데이트**:
   ```bash
   gh issue comment <number> --body "## 해결 시도 실패 보고 ..."
   gh issue edit <number> --add-label "blocked,needs-investigation"
   ```

---

## 워크플로우 예시

```bash
/issue list                # 이슈 목록 확인
/issue list 123            # 특정 이슈 상세
/issue fix 123             # 이슈 해결 시작
/issue failed 123          # 실패 시 분석
```

---

상세: `.claude/commands/issue.md`
