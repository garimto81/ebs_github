---
title: SG-024 거버넌스 확장 — Conductor 단일 세션 전권 (broadcast)
owner: conductor
tier: internal
type: notify-broadcast
recipients: [team1, team2, team3, team4]
broadcast-date: 2026-04-27
linked-sg: SG-024
linked-decision: user B-Q5 ㉠ 2026-04-27
status: ACTIVE
last-updated: 2026-04-27
confluence-page-id: 3819078346
confluence-parent-id: 3811573898
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819078346/EBS+SG-024+Conductor+broadcast
---

## 공식 선언

> **EBS 거버넌스가 확장되었습니다 (SG-024, 2026-04-27 사용자 결정 B-Q5 ㉠).**
>
> Conductor 세션이 team1~4 코드 영역 직접 진입 + decision_owner override 가능. **단, 멀티세션 모드는 옵션으로 유지**.

## 1. 새 거버넌스 모드 (v7.1)

### Mode A — 단일 세션 (Conductor 전권, B-Q5 ㉠ default)
- Conductor 세션 단독으로 활동 시
- team1~4 코드 영역 직접 진입 + 작성 가능
- decision_owner override 가능 (Conductor = 최종 결정자)
- **단일 turn cascade 자율 진행 가능**

### Mode B — 멀티 세션 (각 팀 자체 세션, 옵션)
- 각 팀 세션 (team1, team2, team3, team4) 자체 활동 시
- 그 팀의 decision_owner 권한 자동 회복
- Conductor 는 통합 검증 / 충돌 escalation 만
- **기존 v7 모델 그대로 유지**

### 자동 모드 전환
- 팀 세션 (예: `cd team1-frontend` + Claude Code) 활성화 → Mode B 자동 회복
- Conductor 세션 단독 → Mode A default

## 2. 즉시 영향

### Conductor 세션 (현재)
- team1~4 코드 영역 진입 자유 — `team1-frontend/lib/`, `team2-backend/src/` 등
- 단일 turn 에 cross-team 변경 가능 (예: Foundation 갱신 + team1 UI + team2 API 동시)
- 단, 점진 진행 권장 (검증 부담 + 1주 내 3건 reversal 우려)

### 각 팀 세션 (team1~4)
- 자체 CLAUDE.md / 자체 Backlog 진행 패턴 그대로 유효 (Mode B)
- 단, Conductor 가 동일 영역 작업 시 commit history 에서 확인 (rebase / conflict resolution)
- **team-policy.json contract_ownership 의 publisher 권한 보존** — 의미적 결정 권한 유지

### B-Q3 재해석
이전 NOTIFY-ALL-PHASE2-START 의 "B-Q3 team1 위임" 항목은 **Mode B 가정**. Mode A 로 전환 시 Conductor 가 직접 처리 가능. 단 본 turn 에는 처리 X (점진 진행 + B-Q3 의 due 2026-05-04 유지).

## 3. NOTIFY-ALL-PHASE2-START + NOTIFY-ALL-SG023-INTENT-PIVOT 와의 관계

| NOTIFY | 상태 | 영향 |
|--------|:----:|------|
| `NOTIFY-ALL-PHASE2-START.md` | 일부 갱신 필요 | §3 "팀별 진입 가능 작업" — Mode A 에서는 Conductor 자율 진행 가능 (현재 STANDBY 권고는 Mode B 가정) |
| `NOTIFY-ALL-SG023-INTENT-PIVOT.md` | 일부 갱신 필요 | §1 "모든 팀 작업 일시 STANDBY" — Mode A 에서는 Conductor 가 STANDBY 항목 자율 처리 가능 |

→ 본 NOTIFY 가 위 두 NOTIFY 의 **거버넌스 컨텍스트 갱신** 역할.

## 4. 후속 결정 cascade

### Conductor 자율 처리 (본 turn 또는 후속 turn)
- B-Q9: Type 분류 의 production 의미 재해석 (Spec_Gap_Triage callout) — **본 turn 처리**
- 각 팀 CLAUDE.md (team1~4) 자체 갱신 — **후속 turn** (Mode A 활용)

### 사용자 명시 결정 필요 (Backlog 등재)
- **B-Q6**: timeline / MVP / 런칭 일정 — 구체 일자 사용자 명시 필요
- **B-Q7**: 품질 기준 (prototype-grade vs production-grade 측정) — 사용자 명시 필요
- **B-Q8**: vendor RFI/RFQ reactivate — 외부 발송 destructive, 사용자 명시 필요

## 5. 거버넌스 보호 (Conductor 자율 한계)

Mode A 에서도 다음은 **사용자 명시 필요**:

- ❌ vendor 외부 메일 발송 (RFI/RFQ — Slack/Gmail)
- ❌ destructive 시스템 변경 (DB drop, prod 배포, 거대 dependency 변경)
- ❌ git config 자율 변경 (예: remote URL 변경 — B-Q4 는 사용자 명시 후 처리됨)
- ❌ 사용자 인텐트 변경 (SG-023 같은 큰 결정 — Conductor 자율 시도 금지)
- ❌ memory 의 사용자 본인 결정 메모 임의 폐기

Mode A 권한 = 코드/문서 자율 작성 + decision_owner override. 그 외는 여전히 사용자 결정.

## 6. 검증 (broadcast 도착 확인)

각 팀 세션 합류 시:

- [ ] 본 NOTIFY 읽기 완료
- [ ] team-policy.json v7.1 모드 확인
- [ ] 자체 작업 영역에 Conductor 변경 commit 있는지 `git log` 확인
- [ ] 동일 파일 동시 작업 발생 시 rebase 또는 사용자 escalation
- [ ] Mode B (자체 세션) 활성화 시 decision_owner 회복 인지

## 참조

- `docs/4. Operations/Conductor_Backlog/SG-024-governance-expansion.md` (백로그 항목)
- `docs/4. Operations/Spec_Gap_Registry.md` SG-024
- `docs/4. Operations/Phase_1_Decision_Queue.md` Group F
- `docs/2. Development/2.5 Shared/team-policy.json` v7.1
- `docs/4. Operations/Multi_Session_Workflow.md` L0 (단일 세션 모드)
- `CLAUDE.md` (project) "Claude Code 세션 분리" 섹션 갱신
- 이전 broadcasts: NOTIFY-ALL-PHASE2-START, NOTIFY-ALL-SG023-INTENT-PIVOT (거버넌스 컨텍스트 변경 영향)

## Changelog

| 날짜 | 버전 | 변경 내용 | 결정 근거 |
|------|------|-----------|----------|
| 2026-04-27 | v1.0 | broadcast 발행 (SG-024 거버넌스 확장 — B-Q5 ㉠ 채택) | 사용자 단일 세션 권한 명시 |
