---
stream: S7
name: Backend
worktree: C:/claude/ebs-backend-stream
phase: P2 (정합성 감사 — 활성화)
blocked_by: S1
audit_basis: docs/4. Operations/orchestration/2026-05-08-consistency-audit/foundation_ssot.md
note: "future_streams 에서 정합성 감사용으로 일시 활성화. 코드 작업은 별도 phase."
---

# S7 Backend — 정합성 감사 작업 spec

## 🎯 미션

**2.2 Backend 전 영역 ↔ Back_Office_PRD ↔ Foundation 3-way 정합 + 정본 Back_Office/Overview.md 보증**.

## 📂 영향 파일 (104)

| 영역 | 패턴 |
|------|------|
| 정본 | `docs/2. Development/2.2 Backend/Back_Office/**` (`Back_Office_PRD.md` derivative-of) |
| APIs | `docs/2. Development/2.2 Backend/APIs/**` |
| Authentication | `docs/2. Development/2.2 Backend/Authentication/**` |
| Database | `docs/2. Development/2.2 Backend/Database/**` |
| Engineering | `docs/2. Development/2.2 Backend/Engineering/**` |
| Backlog | `docs/2. Development/2.2 Backend/Backlog/**` |

> **Note**: `Back_Office_PRD.md` 자체는 S1 owner (interim). S7 은 정본 Overview.md 만 owner.

## ✅ 검증 항목

1. **Foundation Ch.5 §B 일치**: 3 핵심 임무 (외부 동기화 / 권한 검증 / 데이터 보관소)
2. **Foundation §11 통신 매트릭스 일치**: REST + WS 채널 정확
3. **Foundation §B.4 일치**: DB SSOT + WS push 정책
4. **Foundation §B.3 일치**: CC = Orchestrator, Engine = SSOT, BO ack = audit
5. **스택 정합**: FastAPI + SQLite/PostgreSQL
6. **NFR 표기 (Foundation §12)**: 운영 메트릭이지 핵심 가치 아님 명시
7. **APIs/** REST + WS 카탈로그 일관
8. **Authentication = RBAC (Foundation §15)**: Admin / Operator / Viewer

## 🔄 자율 Iteration

```
1. python tools/doc_discovery.py --impact-of "docs/2. Development/2.2 Backend/Back_Office/Overview.md"
2. Back_Office/Overview.md ↔ Foundation Ch.5 §B 검증
3. 2.2 Backend/** 전수 → Foundation cascade
4. APIs/ 카탈로그 self-consistency
5. drift 정정
6. PR ready (S1 = Back_Office_PRD frontmatter last-synced 동시 갱신은 cross-stream NOTIFY)
```

## 🚫 금지

- `Back_Office_PRD.md` 직접 수정 → S1 영역
- 다른 Stream 영역 수정
- meta files 수정

## 📋 PR 체크리스트

- [ ] Back_Office/Overview.md ↔ Foundation Ch.5 §B 일치
- [ ] APIs/ + Database/ + Authentication/ Foundation cascade 통과
- [ ] last-synced 갱신은 NOTIFY-S1 backlog 발행
- [ ] PR title: `docs(s7-backend): consistency audit 2026-05-08`
- [ ] PR label: `stream:s7`, `consistency-audit`
