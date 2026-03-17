---
name: pr
description: >
  This skill should be used when the user requests PR review, improvement suggestions, or auto-merge workflow management.
version: 1.1.0
triggers:
  keywords:
    - "/pr"
    - "PR 리뷰"
    - "풀리퀘스트"
    - "PR 생성"
auto_trigger: false
---

# /pr — PR 리뷰 및 머지 관리

PR 리뷰 → 개선 제안 → 머지까지 통합 워크플로우입니다.

## Usage

```
/pr <action> [#PR번호] [options]

Actions:
  review [#N]     PR 코드 리뷰 실행
  merge [#N]      조건 확인 후 머지
  auto [#N]       리뷰 + 자동 머지 (전체 워크플로우)
  list            리뷰 대기 PR 목록
```

---

## /pr review

```bash
/pr review           # 현재 브랜치의 PR 리뷰
/pr review #42       # 특정 PR 리뷰
/pr review --strict  # 엄격 모드 (경고도 블로커)
```

### 리뷰 워크플로우

1. **병렬 검사** 실행:
   - 코드 품질 (lint, type check)
   - 테스트 검증 (coverage)
   - 보안 검사 (secrets, deps)

2. **결과 분류**:
   - Critical/High → 블로커 (머지 차단)
   - Medium → 개선 제안
   - Low → 참고 사항

3. **리뷰 코멘트 작성**: `gh pr comment --body "..."`

### 리뷰 체크리스트

| 카테고리 | 검사 항목 | 심각도 |
|----------|----------|--------|
| 코드 품질 | Lint/Type 오류 | High |
| 코드 품질 | 복잡도 초과 (>10) | Medium |
| 테스트 | 테스트 실패 | High |
| 테스트 | 커버리지 <80% | Medium |
| 보안 | 하드코딩된 시크릿 | Critical |
| 보안 | 취약한 의존성 | High |

---

## /pr merge

```bash
/pr merge            # 현재 브랜치 PR 머지
/pr merge #42        # 특정 PR 머지
/pr merge --force    # 조건 무시 머지 (위험)
```

### 머지 조건 (필수)

- CI 통과
- 충돌 없음
- Critical/High 블로커 없음

### 실행 명령어

```bash
# 기본: squash merge + 브랜치 삭제
gh pr merge #42 --squash --delete-branch

# 옵션
--merge     # 일반 머지 (커밋 유지)
--rebase    # 리베이스 머지
--no-delete # 브랜치 유지
```

---

## /pr auto

리뷰 + 머지를 한 번에 실행합니다.

```bash
/pr auto             # 현재 브랜치 PR
/pr auto #42         # 특정 PR
/pr auto --strict    # 엄격 모드
```

### 전체 흐름

1. **PR 정보 확인**: `gh pr view #N --json state,reviews,statusCheckRollup`
2. **리뷰 실행** (`/pr review`)
   - 블로커 발견 → 개선 제안 출력 + 종료
   - 블로커 없음 → 다음 단계
3. **머지 조건 검증**: CI, 충돌, 브랜치 상태
4. **사용자 확인**: "머지를 진행할까요?" (`--auto-approve` 시 생략)
5. **머지 실행**: `gh pr merge --squash --delete-branch`

---

## /pr list

```bash
/pr list             # 모든 Open PR
/pr list --mine      # 내가 생성한 PR
/pr list --review    # 리뷰 요청된 PR
```

실행 명령어:
```bash
gh pr list
gh pr list --author @me
gh pr list --search "review-requested:@me"
```

---

## 연동 에이전트

| 단계 | 에이전트 | 역할 |
|------|---------|------|
| 코드 리뷰 | `Agent(subagent_type="code-reviewer", description="PR 코드 리뷰")` | 병렬 검사 실행 |
| 보안 검사 | `Agent(subagent_type="qa-tester", description="보안/테스트 검증")` | 취약점 탐지 |

---

## 연동 워크플로우

```
/auto "기능 구현" → 구현 완료 → /commit → /pr auto → 리뷰 + 머지
```

---

상세: `.claude/commands/pr.md`
