---
title: "S2 Lobby Cascade Plan — Lobby_PRD v3.0.0 → 정본/feature 전면 정합"
owner: stream:S2 (Lobby)
tier: internal
status: ACTIVE
last_updated: 2026-05-07
trigger: 사용자 인텐트 "S2/S3 기준 문서 토대로 인과 관련 문서 전면 정합"
worktree: C:/claude/ebs-lobby-stream
branch: work/s2/2026-05-07-work-2026-05-07
---

# S2 Lobby Cascade — 정본 + Feature 전면 정합

## 기준 문서 (SSOT, 변경 금지)

`docs/1. Product/Lobby_PRD.md` v3.0.0 — 5분 게이트웨이 + WSOP LIVE 거울 + 25 PNG self-contained.

**핵심 정체성** (이전 v2.0.x "관제탑" 정정 → v3.0.0):

```
Lobby = CC 로 들어가기 위한, 거기서 나오기 위한,
        어긋났을 때 돌아오기 위한 - 잠깐 거치는 게이트웨이
        + WSOP LIVE 정보 허브
```

**4 진입 시점**:
1. 처음 진입 (운영 시작)
2. 어긋났을 때 (예외 처리)
3. 게임이 바뀔 때 (transition)
4. 모든 것이 끝날 때 (운영 종료)

**5 화면 시퀀스** (운영자 통과 동선):
- Series → Events → Flights → Tables → Players (+ Hand History / Settings)

---

## Cascade 영향 매트릭스

| 우선순위 | 대상 | 변경 유형 | 변경 범위 |
|:--:|------|----------|----------|
| **P0** | `docs/2. Development/2.1 Frontend/Lobby/Overview.md` (정본 1273줄) | 정체성 정합 | §개요 / §Lobby-CC 관계 / §화면 구조 (5 화면 시퀀스 + 4 진입 시점 명시) |
| **P0** | `docs/2. Development/2.1 Frontend/Lobby/UI.md` | 정체성 정합 | 게이트웨이 정체성 반영 |
| **P1** | `docs/2. Development/2.1 Frontend/Lobby/Event_and_Flight.md` | 진입 시점 매핑 | 4 진입 중 ②③ 시점에 해당 |
| **P1** | `docs/2. Development/2.1 Frontend/Lobby/Table.md` | 진입 시점 매핑 | 4 진입 중 ② 시점 (어긋났을 때) |
| **P1** | `docs/2. Development/2.1 Frontend/Lobby/Session_Restore.md` | 진입 시점 매핑 | 4 진입 중 ① ② 시점 (처음 진입 / 어긋났을 때) |
| **P2** | `docs/2. Development/2.1 Frontend/Lobby/Clock_Control.md` | derive 정합 | "WSOP LIVE 거울" 컨텍스트 반영 |
| **P2** | `docs/2. Development/2.1 Frontend/Lobby/Registration.md` | derive 정합 | 정보 허브 역할 명시 |
| **P2** | `docs/2. Development/2.1 Frontend/Lobby/Prize_Pool.md` | derive 정합 | 정보 허브 역할 명시 |
| **P2** | `docs/2. Development/2.1 Frontend/Lobby/Reports.md` | derive 정합 | 정보 허브 역할 명시 |
| **P2** | `docs/2. Development/2.1 Frontend/Lobby/Staff_Management.md` | derive 정합 | 게이트웨이 컨텍스트 반영 |
| **P2** | `docs/2. Development/2.1 Frontend/Lobby/Structure_Templates.md` | derive 정합 | 정보 허브 컨텍스트 |
| **P2** | `docs/2. Development/2.1 Frontend/Lobby/Operations.md` | derive 정합 | 4 진입 시점 컨텍스트 |
| **P2** | `docs/2. Development/2.1 Frontend/Lobby/Chip_Management.md` | derive 정합 | 운영자 게이트웨이 흐름 |
| **P2** | `docs/2. Development/2.1 Frontend/Lobby/Hand_History.md` | derive 정합 | 정보 허브 역할 |
| **P3** | `docs/2. Development/2.1 Frontend/Lobby/References/EBS_Lobby_Design/README.md` | 디자인 SSOT 정합 | v3.0.0 정체성 반영 |
| **P4** | Foundation §Lobby (있다면) | NOTIFY-S1 | S1 stream에 위임 |

---

## 작업 순서 (Map-Reduce)

### Phase 1 — 정본 정합 (P0)

`Overview.md` + `UI.md`에 PRD v3.0.0 정체성 반영. **추가 전용 (additive)** 원칙 — 기존 §개요/§Lobby-CC 관계/§화면 구조 섹션을 갱신하되, 기존 changelog 보존.

핵심 추가 내용:
- §개요 첫 단락에 "5분 게이트웨이 + WSOP LIVE 거울" 정체성 명시
- §Lobby-CC 관계에 "운영자가 머무는 화면 = CC, 거치는 게이트웨이 = Lobby" 정정
- §화면 구조에 "4 진입 시점" 카탈로그 신설
- changelog: `2026-05-07 | v3 정체성 정합 | Lobby_PRD v3.0.0 cascade — 5분 게이트웨이 + WSOP LIVE 거울 정체성 반영`

### Phase 2 — Feature 정합 (P1, P2)

각 feature 문서의 도입부 (§개요 또는 첫 2~3줄)에 게이트웨이 컨텍스트 1~2줄 추가. **본문 변경 최소화** — 도입부 framing만.

P1 (3 문서, 진입 시점 직접 매핑):
- `Event_and_Flight.md`: "②(어긋났을 때) ③(게임 바뀔 때) 진입 시점에 운영자가 거치는 화면" 명시
- `Table.md`: "② 진입 시점 — 어긋났을 때 다시 잡는 화면"
- `Session_Restore.md`: "① ② 진입 — 처음 진입 + 어긋났을 때"

P2 (9 문서, derive framing):
- 각 문서 §개요에 "WSOP LIVE 정보 허브 역할 — 운영자가 5분 게이트웨이 동안 확인하는 [기능명]" 1줄 추가

### Phase 3 — 디자인 SSOT 정합 (P3)

`References/EBS_Lobby_Design/README.md`에 v3.0.0 정체성 cross-reference. PRD 의 25 PNG 와 디자인 SSOT 의 React prototype 매핑 명확화.

### Phase 4 — Cross-Cutting Notify (P4)

Foundation 에 Lobby 정체성 변경 영향 있을 시 `docs/2. Development/2.1 Frontend/Lobby/Backlog/NOTIFY-S1-lobby-identity-cascade.md` 신설.

### Phase 5 — Verify + PR

- `python tools/doc_discovery.py --impact-of "docs/1. Product/Lobby_PRD.md"` 실행 — frontmatter 정합 확인
- 정본/feature 모든 변경 commit (단일 또는 phase별 여러 commit)
- `python tools/orchestrator/team_session_end.py --message="S2 Lobby cascade — Lobby_PRD v3.0.0 → 정본 + 12 feature + 디자인 SSOT 전면 정합"` 실행

---

## 검증 체크리스트 (PR 머지 전)

- [ ] Lobby_PRD v3.0.0 변경 0 (기준 문서 보존)
- [ ] Overview.md §개요에 "5분 게이트웨이" 정체성 명시
- [ ] Overview.md changelog에 v3 정체성 정합 항목 추가
- [ ] UI.md 정체성 정합
- [ ] P1 3 문서 진입 시점 매핑 명시
- [ ] P2 9 문서 도입부 framing 추가
- [ ] frontmatter `derivative-of` / `legacy-id` 변경 0 (구조 보존)
- [ ] `tools/doc_discovery.py` 0 error
- [ ] PR 단일 (모든 cascade가 한 PR에)

---

## 자율 권한 (Mode A — Conductor 위임)

S2 sub-agent 는 다음 영역에 자율 결정 권한:
- Lobby/** 모든 문서 편집
- Lobby_PRD 변경은 금지 (기준 문서)
- Foundation / Architecture / 다른 팀 영역 편집 금지 (NOTIFY 만)

**판단 모호 시**: SSOT 우선. PRD v3.0.0 narrative 톤 따라 caption 추가. 사용자 질문 금지.
