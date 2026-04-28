---
title: Conflict Registry (v7.5 Autonomous Triage Audit Trail)
owner: conductor
tier: contract
last-updated: 2026-04-28
---

# Conflict Registry

자율 충돌 판정 (v7.5 SG-028) 의 audit trail. 모든 결정 (자동 적용 + abort + ci-only) 이 여기 누적된다.

## 사용 규칙

- **읽기 전용 인덱스**: 사람이 직접 행 추가하지 않는다. `tools/conflict_resolver.py` 가 자동 갱신.
- **수동 행은 issue 링크 보강**용으로만 허용 (4번째 컬럼). 수동 추가 시 `request_id` 컬럼은 비워둘 것.
- 100건 누적 또는 12 weeks 경과 시 SG-028b 사후 평가 트리거.

## 컬럼 의미

- `timestamp`: UTC 결정 시각
- `branch`: 충돌이 발생한 work 브랜치
- `files`: 충돌 파일 수
- `decision summary`: `use_ours:N, use_theirs:N, use_merged:N, abort_branch:N, global=continue|abort` 또는 `GLOBAL ABORT` / `VERIFY FAIL: ...` / `CI-DEFERRED`
- `issue`: 자동 생성된 GitHub issue URL
- `req_id`: `.conflict_request.json` 의 request_id 앞 8자

## 결정 이력

| timestamp (UTC) | branch | files | decision summary | issue | req_id |
|-----------------|--------|-------|------------------|-------|--------|

## 관련 문서

- `docs/4. Operations/Conductor_Backlog/SG-028-autonomous-conflict-triage.md` — 거버넌스 결정 근거
- `docs/4. Operations/Multi_Session_Workflow.md` §v7.5 — 워크플로우 사양
- `docs/2. Development/2.5 Shared/team-policy.json` `conflict_triage` — 4-Step Decision Logic SSOT
- `tools/conflict_resolver.py` — 엔진 구현
