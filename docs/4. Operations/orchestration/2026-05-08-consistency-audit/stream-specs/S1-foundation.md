---
stream: S1
name: Foundation
worktree: C:/claude/ebs-foundation
phase: P1 (정합성 감사)
audit_basis: docs/4. Operations/orchestration/2026-05-08-consistency-audit/foundation_ssot.md
priority: HIGHEST (다른 모든 Stream 의 blocking gate)
---

# S1 Foundation — 정합성 감사 작업 spec

## 🎯 미션

**Foundation v4.5 자체 self-consistency + Game_Rules 4 + Back_Office_PRD 정합 (interim)**.
S1 PR 머지 = S2~S8 unblock signal.

## 📂 영향 파일 (6)

| 파일 | 작업 |
|------|------|
| `docs/1. Product/Foundation.md` | self-consistency 검증 (16 fact 표 cross-ref) |
| `docs/1. Product/Back_Office_PRD.md` | Foundation Ch.5 §B + B.4 와 cascade |
| `docs/1. Product/Game_Rules/Flop_Games.md` | Foundation §10 (12 공유카드 종) cascade |
| `docs/1. Product/Game_Rules/Draw.md` | Foundation §10 (7 카드교환 종) cascade |
| `docs/1. Product/Game_Rules/Seven_Card_Games.md` | Foundation §10 (3 부분공개 종) cascade |
| `docs/1. Product/Game_Rules/Betting_System.md` | Foundation §3 (CC 6키) + Mixed Game §10 cascade |

## ✅ 검증 항목

1. **숫자 정합**: 22 게임, 12 안테나, 8 그래픽, 6 키, 5 Act, 4 진입시점, 3 Trinity
2. **명칭 정합**: HORSE / 8-Game / NLHE / PLO / Razz / Stud
3. **정의 정합**: 5분 게이트웨이, WSOP LIVE 거울, 1×10+6키, Engine SSOT, 1단계 입력
4. **Game_Rules 4종 → Foundation §10**: 22 게임 = 12+7+3 합 일치
5. **Back_Office_PRD ↔ Foundation Ch.5 §B**: 3 핵심 임무 + 통신 매트릭스

## 🔄 자율 Iteration

```
1. doc_discovery --impact-of foundation_ssot.md → 영향 list 확보
2. Foundation.md 읽기 → 본 spec 의 16 fact 와 self-consistency 검증
3. Game_Rules 4 + BO_PRD 읽기 → Foundation 사실 cascade 검증
4. drift 발견 → 정정 (단일 commit per file)
5. 모든 검증 통과 → PR ready (auto-merge)
6. drift 없으면 close (no-op PR)
```

## 🚫 금지

- S2~S8 영역 수정 (PreToolUse hook 차단)
- meta files 수정 (CLAUDE.md, MEMORY.md, team_assignment_v10_3.yaml)
- References/, archive/ 수정 (frozen)

## 📋 PR 체크리스트

- [ ] 본 spec 의 16 fact 표 모두 Foundation 과 일치
- [ ] Game_Rules 4 + BO_PRD frontmatter `last-synced` 갱신
- [ ] `python tools/doc_discovery.py --impact-of "docs/1. Product/Foundation.md"` 통과
- [ ] PR title: `docs(s1-foundation): consistency audit 2026-05-08`
- [ ] PR label: `stream:s1`, `consistency-audit`
