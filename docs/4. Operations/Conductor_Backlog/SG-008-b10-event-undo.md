---
id: SG-008-b10
title: "POST /api/v1/events/{event_id}/undo 기능 범위 + 제약 판정"
type: spec_gap
sub_type: spec_drift_b_escalated
parent_sg: SG-008
status: PENDING
owner: conductor
decision_owners_notified: [team2]
created: 2026-04-20
affects_chapter:
  - docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md
  - docs/2. Development/2.5 Shared/EBS_Core.md
  - docs/1. Product/Foundation.md
protocol: Spec_Gap_Triage §7.2
reimplementability: UNKNOWN
reimplementability_checked: 2026-04-20
reimplementability_notes: "SG-008-b PENDING. decision_owner 판정 대기"
---

# SG-008-b10 — `POST /api/v1/events/{event_id}/undo` 기능 범위

## 배경

SG-008 §"b분류" 에서 승격. **기획 본문에 undo 개념 자체가 부재**. audit_events 는 append-only 설계(DATA-04) 와 충돌. 가장 큰 설계 결정 필요 항목.

## 대상 endpoint (code-only)

- `POST /api/v1/events/{event_id}/undo` — 특정 이벤트 취소/보상

## 논점

1. Undo 의미 — physical delete(append-only 위반) vs compensating event(원 이벤트 + 역 이벤트) vs soft delete flag
2. 허용 범위 — 모든 이벤트? 특정 타입(ActionPerformed 만)?
3. 시간 제약 — 마지막 이벤트만? N분 이내만?
4. seq 영향 — undo 이벤트도 새 seq 부여? 원 이벤트 seq 무효화?
5. RBAC — Admin? Operator of assigned table? TD?
6. WebSocket 브로드캐스트 — undo 발생 시 Lobby 에 `EventUndone` 이벤트?
7. Phase 1 MVP 범위 — Undo 는 Phase 2+ 로 미뤄야 하는가?

## 결정 옵션

| 옵션 | 장점 | 단점 |
|------|------|------|
| 1. Compensating event (append-only 유지), ActionPerformed 만, 마지막 액션 + 30초 이내, Operator+ | Event Sourcing 정합. 감사 추적 가능. 제한적 undo 로 복잡도 최소 | 복잡도 여전히 상당 (보상 이벤트 규약 + UI 흐름) |
| 2. Soft delete flag + seq 유지 + 브로드캐스트 | 구현 단순 | append-only 철학 훼손. replay 로직 복잡 |
| 3. Phase 1 에서는 미지원 — 본 endpoint 삭제 | Drift 해소 + 복잡도 0 | 운영자 실수 복구 불가 (테이블 오퍼레이션 신뢰도 하락) |

## Default 제안

**옵션 3 (Phase 1 미지원 — 코드 삭제)** + Phase 2+ 재도입 시 본 SG 재오픈. 이유:
- Undo 는 단순 기능이 아닌 **설계 철학 결정** (append-only vs mutable state)
- 현재 EBS 는 **개발팀 인계용 프로토타입** — 설계 철학이 흔들리는 기능은 인계 후 사용자 요구 확정 시 재설계
- WSOP LIVE 는 Undo 를 **Operator UI only** (로컬 상태) 로 구현, 서버 이벤트 무효화 없음 — 참조 가능 패턴
- Operator 실수 복구는 Phase 1 에서는 "다음 이벤트로 보정" (예: 잘못된 action 후 수정 action emit) 로 대체 가능

**스펙 제안 초안 (옵션 3 채택 시)**:
- team2 코드 삭제 PR: `POST /api/v1/events/{event_id}/undo` router + repository method 제거
- Backend_HTTP.md 에 undo 의도적 미지원 기록 (`§Explicit Non-Goals`)
- Foundation.md §Phase 1 범위 에 "Undo 는 Phase 2+" 명시
- Phase 2+ 재도입 시: 본 SG 재오픈하여 옵션 1 기반 재설계

## 수락 기준

- [ ] 옵션 선택
- [ ] 옵션 1: Backend_HTTP.md + EBS_Core.md + DATA-04 (compensating event 규약) 보강. 복잡도 큼 — 별도 implementation SG 파생
- [ ] 옵션 2: Schema.md 에 soft delete 컬럼 + repository 변경. append-only 파기 기록 필요
- [ ] 옵션 3: team2 코드 삭제 + Foundation.md §Non-Goals 기록

## Changelog

| 날짜 | 버전 | 변경 | 비고 |
|------|------|------|------|
| 2026-04-20 | v1.0 | SG-008 (b) 승격 신규 작성 | Conductor |
