---
title: V9.3 Intent-Execution Separation (governance evolution)
owner: conductor
tier: contract
last-updated: 2026-04-29
governance: v9.3
related: ["V9_2_Gate_Design.md", "Multi_Session_Workflow.md", "team-policy.json"]
---

# V9.3 Intent-Execution Separation

> **사용자 통찰 (2026-04-29)**: "비전문 사용자에게 PR merge 같은 실행 영역 confirm 요구 자체가 system 실패. 사용자는 의도/전체 개념만 제공, AI 가 코드/PR/머지까지 자율 판단."

## 🎯 핵심 원칙

이전 거버넌스의 결함: V9.0/V9.2 가 "Conductor (= 사용자) 단일 머지권" 을 단언하면서, 비전문 사용자에게 `gh pr merge` 같은 실행 영역 결정을 강요. 사용자가 답할 수 없는 질문 = 시스템 실패.

V9.3 는 결정 영역을 명시 분리:

| 영역 | 답변자 | 예시 |
|------|--------|------|
| **사용자 의도 영역** | 사용자 (비전문이라도 답 가능) | MVP 정의, 작업 보존/폐기, vendor 계약, prod 배포 결정 |
| **AI 실행 영역** | AI 자율 판단 | 코드 작성, PR 생성, 충돌 해결, 머지, branch 관리 |

## 🔀 결정 라우팅

```
사용자 메시지 수신
       │
       ▼
   의도 trigger 인가?
       │
   ┌───┴───┐
   │       │
  YES     NO (AI 자율 영역)
   │       │
   ▼       ▼
 의도 추출  AI 자율 진행
   │       (코드/PR/머지)
   ▼
 AI 가 실행 영역으로 변환
       │
       ▼
   AI 자율 진행
```

### AI 자율 진행 가능 (사용자 confirm 불필요)

- 코드 작성 / 수정
- PR 생성 (draft/ready 자율 결정)
- 본인 작성 PR 의 자체 리뷰
- **PR 머지** (조건 만족 시) — V9.3 의 핵심
- 충돌 해결 (의미적으로 명확한 경우)
- worktree / branch 관리
- 도구 / workflow 추가
- 거버넌스 정책 변경 (단, 사용자 의도 trigger 후)

### 사용자 의도 영역 질문이 필요한 경우

- 다중 PR 간 의미적 충돌 (예: 두 worktree 가 다른 기획 방향 표명)
- 의도 모호 (사용자 trigger 가 본 변경을 명시 포함하지 않음)
- destructive 시스템 변경 (DB drop, prod 배포)
- 외부 visible state (vendor 메일, 회사명 노출)
- 사용자 자신의 memory 결정 변경

## 🤖 AI Autonomous Merge 조건

`tools/v93_autonomous_merge.py` 가 자동 검증:

| 조건 | 검증 방법 |
|------|----------|
| **AI authored PR** | PR author = current AI session (또는 marker 매칭) |
| **No conflict** | `mergeable: MERGEABLE` |
| **CI green** | 모든 required check pass |
| **scope_check** | `governance-change` 라벨 시 사용자 의도 trigger 확인 |
| **No `needs-user-intent` label** | 명시적 사용자 의도 요구 라벨 없음 |

모두 만족 → `gh pr merge --squash --delete-branch` 자율 실행.
어느 조건이든 fail → 보고 + 의도 영역 질문 (사용자가 답할 수 있는 형태로 변환).

## 📐 V9.x 거버넌스 진화

| 버전 | 핵심 | 사용자 부담 |
|:---:|------|:---:|
| V8.0 | 자율 머지 (`auto-merge` 라벨) | 낮음 (적체 발생) |
| V9.0 | Conductor 단일 머지권 | 높음 (모든 PR confirm) |
| V9.2 | 충돌 없는 PR worker self-merge | 중간 (충돌만 confirm) |
| **V9.3** | **AI 자율 머지 + 의도/실행 분리** | **최저 (의도만)** |

## 🛡 critic 결함 해소

| ID | 결함 | V9.3 해소 |
|----|------|----------|
| **H3** | Conductor SPOF | AI 가 자율 머지 → SPOF 제거 |
| **H5** | Worker 자율 박탈 | 의도/실행 분리로 worker 자율 확보 |
| **H6** | 1인 ROI 0 | 사용자에게 실행 영역 confirm 요구 안 함 → ergonomic 회복 |

## 🚧 V9.3 한계 (정직한 disclosure)

- **AI 실수 risk**: AI 자율 머지 → broken main 가능성. 완화책:
  - CI green 필수 (실패 시 머지 안 함)
  - scope_check 필수 (governance 변경은 명시 라벨 + 의도 매칭)
  - main 동기화 후 `git revert` 자율 가능 — AI 가 직접 회복
- **의도-실행 경계 모호 case**: AI 가 "이건 의도 영역인가?" 판단 시 보수적으로 사용자 질문. False positive 보다 false negative 가 위험.
- **30일 측정 frame** (별도 후속 PR):
  - daily merge throughput
  - AI autonomous merge / total merge 비율
  - user intent question count (낮을수록 V9.3 성공)
  - broken main incident (높으면 V9.4 필요)

## 🔗 관련

- `team-policy.json` `governance_model.intent_execution_boundary`
- `team-policy.json` `governance_model.merge_authority.ai_autonomous_merge_conditions`
- `tools/v93_autonomous_merge.py`
- `docs/4. Operations/V9_2_Gate_Design.md` (3-gate enforcement, V9.3 도 동일 사용)
- `docs/4. Operations/Multi_Session_Workflow.md` (V9.3 SOP — 별도 update 후속 PR)
