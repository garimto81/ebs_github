---
owner: conductor
tier: internal
stream: S4
name: RIVE Standards
worktree: C:/claude/ebs-rive-standards
phase: P2 (정합성 감사)
blocked_by: S1
audit_basis: docs/4. Operations/orchestration/2026-05-08-consistency-audit/foundation_ssot.md
last-updated: 2026-05-08
confluence-page-id: 3818914472
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818914472/EBS+S4+RIVE+Standards+spec
mirror: none
---

# S4 RIVE Standards — 정합성 감사 작업 spec

## 🎯 미션

**RIVE_Standards.md self-consistency + 모든 Stream 의 RIVE 참조 일관성 advisory**.

## 📂 영향 파일

### Owned (수정 가능)

| 파일 | 작업 |
|------|------|
| `docs/1. Product/RIVE_Standards.md` | self-consistency + Foundation §7 cascade |

### Read-only (drift 발견 시 advisory only — 해당 stream 에 NOTIFY backlog)

| 패턴 | 비고 |
|------|------|
| `docs/2. Development/2.1 Frontend/Lobby/**` (rive 관련) | S2 영역 |
| `docs/2. Development/2.4 Command Center/Overlay/**` | S3 영역 |
| `docs/1. Product/Lobby.md` (rive-role frontmatter) | S2 영역 |
| `docs/1. Product/Command_Center.md` (rive 참조) | S3 영역 |
| `docs/1. Product/Back_Office.md` (rive-role) | S1 영역 |

## ✅ 검증 항목

1. **Foundation §7 일치**: 21 OutputEvent → Rive 애니메이션 트리거
2. **Lobby Web = "EBS DB 작가"** 일관 (Lobby frontmatter rive-role)
3. **CC + Overlay = "Rive 출력자"** 일관
4. **Back_Office = Rive 직접 사용 X, 데이터 공급자** 일관
5. **Rive Manager** 정의 일관 (Foundation §A.3)

## 🔄 자율 Iteration

```
1. RIVE_Standards.md 본문 self-consistency 검증
2. Foundation §7 (3그룹 6기능) 와 cascade 검증
3. 다른 Stream 의 rive 참조 grep → drift 발견 시
   → docs/2.1 Frontend/Backlog/NOTIFY-S{X}-2026-05-08-rive-drift.md 생성
   (해당 stream owner 에게 처리 위임)
4. 자기 영역 PR ready
```

## 🚫 금지

- 다른 Stream 영역 직접 수정 (NOTIFY 만 가능)
- meta files 수정

## 📋 PR 체크리스트

- [ ] RIVE_Standards.md self-consistency 통과
- [ ] Foundation §7 cascade 검증
- [ ] 다른 Stream rive drift = NOTIFY 만 (직접 수정 X)
- [ ] PR title: `docs(s4-rive): consistency audit 2026-05-08`
- [ ] PR label: `stream:s4`, `consistency-audit`
