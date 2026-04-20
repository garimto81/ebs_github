---
id: SG-008
title: "Spec Drift: Backend HTTP D3 대량 endpoint 문서화"
type: spec_gap
sub_type: spec_drift
status: PENDING
owner: team2  # decision_owner (publisher)
conductor_escalation: false
created: 2026-04-20
affects_chapter:
  - docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md
  - docs/2. Development/2.2 Backend/APIs/Auth_and_Session.md
protocol: Spec_Gap_Triage §7 (Type D3)
---

# SG-008 — Backend HTTP D3 대량 endpoint 문서화

## 공백 서술

`tools/spec_drift_check.py --api` 결과, 코드에는 존재하지만 `Backend_HTTP.md` / `Auth_and_Session.md` 에 명세가 없는 REST 엔드포인트가 **89개** 존재한다. 대부분 다음 카테고리:

| 카테고리 | 개수 | 예시 |
|---------|:--:|------|
| CRUD DELETE (자동 생성) | ~12 | `DELETE /api/v1/series/{series_id}`, `DELETE /api/v1/events/{event_id}` |
| CRUD PATCH | 3 | `PATCH /api/v1/decks/{deck_id}` |
| Audit endpoints | 3 | `GET /api/v1/audit-events`, `/audit-logs`, `/audit-logs/download` |
| Auth sub-paths | 9 | `POST /auth/2fa/setup`, `POST /auth/password/reset/send` |
| Sync mock | 3 | `POST /api/v1/sync/mock/seed`, `DELETE /api/v1/sync/mock/reset` |
| 기타 (CRUD 기본 GET/POST/PUT) | ~60 | `GET /api/v1/hands/{hand_id}/actions`, `POST /api/v1/decks/import` |

## 발견 경위

- 2026-04-20 Conductor 세션의 `spec_drift_check.py --api` 최초 실행 결과
- 실패 분류: Type D3 (기획 無 / 코드 有)
- 상세 리포트: `logs/drift_report.md` §api D3

## 영향

- 외부 개발팀 인계 시 이 89 개 엔드포인트 재구현 불가 (명세가 없으므로)
- 현재 Frontend / E2E 테스트는 코드 직독으로 사용 중

## 결정 방안 후보

| 대안 | 장점 | 단점 |
|------|------|------|
| 1. team2 가 Backend_HTTP.md 에 전량 추가 (publisher Fast-Track) | 기획 PASS 복구 | 1-2일 작업 |
| 2. OpenAPI 스펙 자동 생성 후 markdown 변환 | 자동 동기화 | 초기 인프라 필요 |
| 3. 코드 삭제 (실수로 추가된 endpoint) | 간단 | 실제 사용 여부 조사 필수 |

## 수락 기준

- [ ] 89 개 endpoint 중 사용 중인 것 목록화 (grep/ test coverage)
- [ ] 사용 중 endpoint 전량 `Backend_HTTP.md` 또는 `Auth_and_Session.md` 명세 추가
- [ ] 미사용 endpoint 는 코드 삭제 PR 생성
- [ ] `python tools/spec_drift_check.py --api` D3 = 0

## 결정 (team2 채택 시 기입)

- 채택: [대안 번호]
- 이유:
- 영향 챕터 업데이트 PR:
- 후속 구현 Backlog:
