---
owner: conductor
tier: internal
stream: S6
name: Prototype
worktree: C:/claude/ebs-prototype
phase: P3 (정합성 감사)
blocked_by: [S2, S3, S4, S7, S8]
audit_basis: docs/4. Operations/orchestration/2026-05-08-consistency-audit/foundation_ssot.md
last-updated: 2026-05-08
---

# S6 Prototype — 정합성 감사 작업 spec

## 🎯 미션

**프로토타입 빌드 plan + 통합 테스트 시나리오 ↔ Foundation/PRD 정합**.

## 📂 영향 파일

| 영역 | 패턴 |
|------|------|
| Plan | `docs/4. Operations/Plans/**` (Game Engine plan, Back_Office plan, etc.) |
| 통합 테스트 | `integration-tests/**` (worktree 내 .http 파일들) |
| Spec_Gap | `docs/4. Operations/Spec_Gap_Triage.md` 참조 |

## ✅ 검증 항목

1. **Prototype_Build_Plan ↔ Foundation §7 (3 그룹 6 기능)**: 빌드 순서 정합
2. **integration-tests/** 시나리오 ↔ PRD APIs**: 엔드포인트 일관
3. **WebSocket 시나리오 ↔ Foundation §11**: 통신 매트릭스 정합
4. **Plans/ 의 phase 정합**: Foundation §6 (운영) 와 일치

## 🔄 자율 Iteration

```
1. 다른 Stream PR 머지 확인
2. Prototype_Build_Plan ↔ 갱신된 PRD 본문 cascade 검증
3. integration-tests/ HTTP/WS 시나리오 ↔ APIs 정합
4. drift 정정
5. PR ready
```

## 🚫 금지

- 다른 Stream 영역 수정
- 정본 PRD 수정 (S2, S3, S7, S8 영역)
- meta files 수정

## 📋 PR 체크리스트

- [ ] Prototype_Build_Plan cascade 통과
- [ ] integration-tests/ 시나리오 일관
- [ ] PR title: `docs(s6-prototype): consistency audit 2026-05-08`
- [ ] PR label: `stream:s6`, `consistency-audit`
