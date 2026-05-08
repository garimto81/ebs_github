---
title: NOTIFY-Conductor — PR #176 CI 차단 main drift 위임
owner: stream:S2 (Lobby) → conductor
tier: notify
status: ESCALATED
created: 2026-05-08
trigger: PR #176 mergeStateStatus=UNSTABLE (CI 3 fail, 모두 본 PR scope 외)
github-issue: https://github.com/garimto81/ebs_github/issues/192
github-pr: https://github.com/garimto81/ebs_github/pull/176
related:
  - AUDIT-S2-lobby-v3-cascade-2026-05-08.md (본 NOTIFY 의 trigger 가 된 PR 의 AUDIT)
---

# NOTIFY-Conductor — main drift 정정 위임

> S2 (Lobby) 워크트리에서 PR #176 작업 중 main 의 pre-existing drift 가 CI 차단으로 누적됨을 발견.
> S2 scope hook 이 정정을 차단하므로 Conductor 위임. GitHub Issue #192 로 정식 등록.

## 차단 영향

PR #176 (`docs(s2-lobby): consistency audit 2026-05-08`) 가 ready 상태로 대기.
- mergeStateStatus: UNSTABLE
- 본 PR 의 변경 3 파일 (Lobby scope) 자체 검증 모두 PASS (12 checks)
- 차단 원인 = main 에 이미 존재한 drift 가 PR check 에서 누적 검출

## 위임 작업 명세 (Conductor 책임)

### 작업 1 — frontmatter `owner` 누락 10 파일

| 영역 | 파일 |
|------|------|
| Archive | `docs/_archive/governance-2026-05/INDEX.md` |
| Orchestration | `docs/4. Operations/orchestration/2026-05-08-consistency-audit/conductor-spec.md` |
| Stream specs | `docs/4. Operations/orchestration/2026-05-08-consistency-audit/stream-specs/{S1-foundation, S2-lobby, S3-cc, S4-rive, S5-index, S6-prototype, S7-backend, S8-engine}.md` (8 파일) |

정정: 각 파일 frontmatter 에 `owner: conductor` (또는 stream 명) 추가.

### 작업 2 — 깨진 링크 정정 7건

#### 2-A: `docs/2. Development/2.1 Frontend/2.1 Frontend.md` line 87/88/90/92/94 (5건)
실재 X 5 파일 — 정정 옵션:
- (A) 링크 5줄 제거
- (B) `Graphic_Editor/References/skin-editor/archive/` 경로 재지정
- (C) Graphic_Editor stream 에 파일 복원 요청

#### 2-B: `docs/1. Product/RIVE_Standards.md` line 207/214 (2건)
잘못된 상대경로 `../../1. Product/images/foundation/{wsop-2025-paradise-overlay.png, overlay-anatomy.png}` — 정정:
- 절대 경로 또는 정확한 상대경로로
- (S1 Foundation 영역 — Conductor 가 S1 에 재위임 가능)

## 차단 여부

🔴 **PR #176 머지 차단** — 본 NOTIFY 가 처리될 때까지 대기.
또한 추후 모든 PR 가 동일 CI 실패 누적 (drift 가 누적 차단).

## 권장 처리 흐름

```
[Conductor] Issue #192 처리 시작
  ├─ 작업 1 (frontmatter owner) — 10 파일 일괄 한 줄 추가
  ├─ 작업 2-A (Graphic_Editor 링크 5건) — Graphic_Editor stream 결정 (제거 vs 재지정 vs 복원)
  └─ 작업 2-B (RIVE_Standards 링크 2건) — S1 stream 재위임 (Foundation 영역)
[main] 정정 PR merge → CI green
[S2] PR #176 rebase + 재CI → 자연 머지
```

## Cross-Reference

- GitHub Issue: #192 (정식 위임)
- 본 PR: #176 (대기 상태)
- AUDIT 보고서: `AUDIT-S2-lobby-v3-cascade-2026-05-08.md` §K (CI 실패 진단)

## 의도

S2 scope hook 이 main drift 정정을 차단하는 것은 **의도된 분권 메커니즘** — 다른 stream 의 책임 영역 침범 방지. 따라서 본 NOTIFY 는 Bug 가 아니라 **multi-session orchestration 의 정상 협업 패턴**.
