---
owner: conductor
tier: internal
stream: S5
name: AI Track / Index
worktree: C:/claude/ebs-ai-track
phase: P3 (정합성 감사)
blocked_by: [S1, S2, S3, S4, S7, S8]
audit_basis: docs/4. Operations/orchestration/2026-05-08-consistency-audit/foundation_ssot.md
last-updated: 2026-05-08
---

# S5 AI Track / Index — 정합성 감사 작업 spec

## 🎯 미션

**모든 Stream PR 머지 후 자동 인덱스 재생성 + AI track 일관성**.

## 📂 영향 파일

| 패턴 | 작업 |
|------|------|
| `docs/_generated/full-index.md` | regenerate (`spec_aggregate.py`) |
| `docs/_generated/by-feature/**` | regenerate |
| `docs/_generated/by-topic/**` | regenerate |
| `tools/ai_track/**` (있을 시) | self-consistency |

## ✅ 검증 항목

1. **모든 .md 파일 인덱싱**: 누락 0건
2. **frontmatter 정상**: title / owner / tier 모두 채움
3. **legacy ID 매핑**: PRD-GAME-01~04 → Game_Rules/* 정합
4. **CI generated 표시**: tier=generated 명시
5. **owner 매트릭스**: team_assignment_v10_3.yaml 의 scope_owns 와 정합

## 🔄 자율 Iteration

```
1. 다른 Stream PR 모두 머지 확인 (gh pr list --state merged --label consistency-audit)
2. python tools/spec_aggregate.py 실행 → _generated/ 재생성
3. 인덱스 검증 (file count, owner matrix, legacy ID)
4. PR ready (자동 인덱스 갱신)
```

## 🚫 금지

- 정본 / PRD 영역 수정 (다른 Stream)
- meta files 수정

## 📋 PR 체크리스트

- [ ] `python tools/spec_aggregate.py` 무오류 실행
- [ ] `docs/_generated/full-index.md` 파일 수 = 본 audit total
- [ ] frontmatter 누락 0건
- [ ] PR title: `docs(s5-index): consistency audit 2026-05-08 - regenerate index`
- [ ] PR label: `stream:s5`, `consistency-audit`
