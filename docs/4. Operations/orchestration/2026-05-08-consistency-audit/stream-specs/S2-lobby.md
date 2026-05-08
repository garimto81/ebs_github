---
owner: conductor
tier: internal
stream: S2
name: Lobby
worktree: C:/claude/ebs-lobby-stream
phase: P2 (정합성 감사)
blocked_by: S1
audit_basis: docs/4. Operations/orchestration/2026-05-08-consistency-audit/foundation_ssot.md
last-updated: 2026-05-08
confluence-page-id: 3819275025
confluence-parent-id: 3811573898
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819275025/EBS+S2+Lobby+spec
---

# S2 Lobby — 정합성 감사 작업 spec

## 🎯 미션

**Lobby_PRD ↔ 정본 Overview.md ↔ Foundation 3-way 정합 + 2.1 Frontend 전 영역 cascade**.

## 📂 영향 파일 (116)

| 영역 | 패턴 | 파일 수 |
|------|------|--------|
| 외부 PRD | `docs/1. Product/Lobby_PRD.md` | 1 |
| 정본 | `docs/2. Development/2.1 Frontend/Lobby/**` | ~30 |
| 자매 영역 | `docs/2. Development/2.1 Frontend/Login/**` | ~10 |
| 자매 영역 | `docs/2. Development/2.1 Frontend/Settings/**` | ~5 |
| 자매 영역 | `docs/2. Development/2.1 Frontend/Graphic_Editor/**` | ~10 |
| Backlog | `docs/2. Development/2.1 Frontend/Backlog/**` | ~60 |

## ✅ 검증 항목

1. **derivative-of chain**: `Lobby_PRD.md` frontmatter `derivative-of` = `../2. Development/2.1 Frontend/Lobby/Overview.md`
2. **last-synced 일치**: `Lobby_PRD.md last-synced` = `Overview.md last-updated`
3. **정체성 정합 (Foundation §8)**: "5분 게이트웨이 + WSOP LIVE 거울" 명시
4. **4 진입 시점**: (a) 첫진입 (b) 비상진입 (c) 변경진입 (d) 종료진입 모두 언급
5. **구조 정합**: Series → Event → Flight → Table 4 단계
6. **배포 정합**: Flutter Web (Docker nginx, LAN 다중 클라이언트)
7. **비율 정합**: Lobby : CC = 1 : N
8. **Backlog 일관성**: B-* 항목 owner 누락 0건, 상태 표시 일관

## 🔄 자율 Iteration

```
1. python tools/doc_discovery.py --impact-of "docs/1. Product/Lobby_PRD.md"
2. Lobby_PRD ↔ Lobby/Overview.md 본문 비교 (derivative-of chain)
3. 2.1 Frontend/** 전수 → Foundation §8 cascade
4. drift 발견 → 정정 (단일 commit per file)
5. 모든 검증 통과 → PR ready
```

## 🚫 금지

- 다른 Stream 영역 수정 (S1, S3, S4, S5, S6, S7, S8)
- 정본 (`Overview.md`) 임의 수정 — Foundation 변경이 원인이면 S1 escalate
- meta files 수정

## 📋 PR 체크리스트

- [ ] Lobby_PRD ↔ Overview.md 본문 일치
- [ ] frontmatter `last-synced` 갱신
- [ ] `tools/doc_discovery.py --impact-of` 결과 = 0 drift
- [ ] PR title: `docs(s2-lobby): consistency audit 2026-05-08`
- [ ] PR label: `stream:s2`, `consistency-audit`
