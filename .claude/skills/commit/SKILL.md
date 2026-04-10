---
name: commit
description: Conventional Commit 형식으로 git 커밋 생성 및 push
version: 2.0.0
triggers:
  keywords:
    - "commit"
    - "커밋"
    - "git commit"
    - "/commit"
---

# /commit - Conventional Commit & Push

## ⚠️ 필수 실행 규칙 (CRITICAL)

**이 스킬이 활성화되면 반드시 아래 워크플로우를 실행하세요!**

### Step 1: 상태 확인 (병렬 실행)

```bash
# 동시에 실행
git status                    # unstaged/untracked 파일 확인
git diff --stat              # 변경 통계
git log --oneline -5         # 최근 커밋 스타일 확인
```

### Step 2: 스테이징

- staged 변경사항이 없으면 사용자에게 **무엇을 커밋할지 질문**
- 민감한 파일 (.env, credentials) 경고
- `git add` 로 선택적 스테이징

### Step 3: 커밋 메시지 생성

**Conventional Commit 형식:**

```
<type>(<scope>): <subject> <emoji>

<body>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

**타입:**

| Type | 설명 | Emoji |
|------|------|-------|
| feat | 새 기능 | ✨ |
| fix | 버그 수정 | 🐛 |
| docs | 문서 | 📝 |
| refactor | 리팩토링 | ♻️ |
| test | 테스트 | ✅ |
| chore | 유지보수 | 🔧 |
| perf | 성능 개선 | ⚡ |
| style | 포맷팅 | 💄 |

### Step 4: 커밋 실행

```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <subject> <emoji>

<body>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

### Step 5: Push (--no-push 없는 경우)

```bash
git push origin <current-branch>
```

- 새 브랜치면 `git push -u origin <branch>`
- diverged 상태면 사용자에게 확인

### Step 6: 결과 출력

```
✅ Committed and pushed: feat(auth): 로그인 기능 추가 ✨
   Branch: feat/login
   Remote: https://github.com/user/repo/commit/abc1234
```

## 옵션

| 옵션 | 설명 |
|------|------|
| `--no-push` | 커밋만 하고 push 생략 |

## 금지 사항

- ❌ main/master에 force push (명시적 요청 없이)
- ❌ .env, credentials 파일 커밋
- ❌ pre-commit hook 실패 시 --no-verify 사용

## 관련 커맨드

- `/create pr` - 커밋 후 PR 생성
- `/session changelog` - 커밋 전 changelog 업데이트
