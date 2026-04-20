---
id: SG-008
title: "Spec Drift: Backend HTTP D3 — 89 code-only endpoints 3분류 (기획이 진실)"
type: spec_gap
sub_type: spec_drift
status: PENDING
owner: conductor  # 1차 분류. (c) 코드 삭제는 team2 세션 집행
conductor_escalation: true
created: 2026-04-20
redefined: 2026-04-20  # 원래 "team2 역방향 문서화" 플랜 → "기획이 진실" 원칙으로 전면 재작성
affects_chapter:
  - docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md
  - docs/2. Development/2.2 Backend/APIs/Auth_and_Session.md
protocol: Spec_Gap_Triage §7 (Type D3)
---

# SG-008 — Backend HTTP D3: 89 code-only endpoints 3분류

## 공백 서술 (재정의 배경)

`tools/spec_drift_check.py --api` 결과, 코드에만 존재하는 REST 엔드포인트가 **89개**. `logs/drift_report.md §api §D3` 참조.

### ❌ 폐기된 계획 (2026-04-20 이전)

> "team2 가 code → doc 역방향 문서화하여 D3 = 0 달성"

**오류 원인**: 본 프로젝트는 **개발팀 인계용 기획서 완결 프로토타입**이며, 현재 앱은 에러가 난무하는 불안정 상태. 이 상태에서 "코드가 진실"로 판정하여 문서를 역방향 생성하면 **잘못된 코드를 기획에 영구 각인**. 사용자 지적:

> "에러 난무하는 앱의 코드를 문서로 역방향 구현한다고? 앱이 문제 없어야 정립하는 소리"

### ✅ 재정의된 계획 (2026-04-20)

Type D3 해소의 기본 판정은 **"기획이 진실"**. 89개 endpoint 를 아래 3분류로 처리.

## 3분류 기준

| 분류 | 정의 | 처리 주체 | 처리 방법 |
|------|------|----------|----------|
| **(a) 기획 추가** | CRUD 완결성상 당연히 필요 (예: DELETE가 없으면 row 삭제 불가). 기획 문서에 누락된 것이 실수. | Conductor | Backend_HTTP.md / Auth_and_Session.md 에 즉시 추가 PR |
| **(b) 판정 필요** | 설계 결정이 필요한 것 (예: audit-logs 공개 범위, mock endpoint 운영 노출, undo 등 특수 액션). 기획이 "필요/불필요" 를 결정해야 함. | Conductor | 개별 SG 승격 (SG-008-a / SG-008-b / ...) |
| **(c) 코드 삭제** | 기획에 없고 필요성 모호, 실수로 추가됐거나 legacy. | team2 세션 | 코드 삭제 PR + Backlog 등재 |

### "당연히 필요 (a)" 판정 휴리스틱

- GET/POST/PUT/PATCH/DELETE 가 동일 리소스에 **쌍**으로 존재 → CRUD 완결성 (기획 누락)
- 기획이 이미 GET/POST 를 명시 → DELETE/PATCH 는 대칭 맞춤
- 명시적 use case 가 기획 본문에 있음 (예: "tables/{id} 삭제 가능") → endpoint 문서화만 누락

### "판정 필요 (b)" 판정 휴리스틱

- audit / sync / mock / reports 등 **운영 자동화/관측성** 관련 → RBAC/공개 범위/내부 전용 여부 결정 필요
- undo / launch / adjust-stack 등 **파생 액션** → 기획에 action 정의 자체가 없음
- `/auth/*` 서브 엔드포인트 중 기획에 명시되지 않은 것 → 보안 플로우 결정 필요

### "코드 삭제 (c)" 판정 휴리스틱

- 기획 본문에서 해당 리소스가 언급조차 없음 + CRUD 대칭도 무의미
- 프로토타입 초기 실험 코드로 남아 있음 (구현자 메모로 확인)

## 상위 30개 샘플 분류

아래는 89개 중 Conductor 1차 분류 샘플. **나머지 ~59개는 team2 세션이 동일 패턴으로 처리**.

| # | Method & Path | 분류 | 근거 |
|:-:|---------------|:--:|------|
| 1 | `DELETE /api/v1/series/{series_id}` | a | Series CRUD 완결 (GET/POST/PUT 이미 기획) |
| 2 | `DELETE /api/v1/events/{event_id}` | a | Event CRUD 완결 |
| 3 | `DELETE /api/v1/flights/{flight_id}` | a | Flight CRUD 완결 |
| 4 | `DELETE /api/v1/tables/{table_id}` | a | Table CRUD 완결 |
| 5 | `DELETE /api/v1/users/{user_id}` | a | User CRUD 완결 |
| 6 | `DELETE /api/v1/players/{player_id}` | a | Player CRUD 완결 |
| 7 | `DELETE /api/v1/competitions/{competition_id}` | a | Competition (deprecated Phase 2 지만 Phase 1 유지) |
| 8 | `DELETE /api/v1/blind-structures/{bs_id}` | a | BlindStructure CRUD 완결 |
| 9 | `DELETE /api/v1/payout-structures/{ps_id}` | a | PayoutStructure CRUD 완결 |
| 10 | `DELETE /api/v1/decks/{deck_id}` | a | Deck CRUD 완결 |
| 11 | `DELETE /api/v1/skins/{skin_id}` | a | Skin CRUD 완결 (기획엔 DELETE 도 있지만 response 포맷만 `/skins/{id}` 로 표기) |
| 12 | `PATCH /api/v1/decks/{deck_id}` | a | Deck 부분 수정 — PUT 전체 교체보다 안전 |
| 13 | `PATCH /api/v1/decks/{deck_id}/cards/{card_code}` | a | 단일 카드 상태 변경 (RFID 매핑) |
| 14 | `PATCH /api/v1/skins/{skin_id}/metadata` | a | Skin metadata 수정 (기획 §skins 참조) |
| 15 | `GET /api/v1/audit-events` | **b** | 감사 이벤트 공개 범위 결정 필요 (운영자 전용? API 공개?) |
| 16 | `GET /api/v1/audit-logs` | **b** | 감사 로그 공개 범위. RBAC 정의 필요 |
| 17 | `GET /api/v1/audit-logs/download` | **b** | 로그 다운로드 포맷/RBAC 결정 필요 |
| 18 | `POST /api/v1/sync/mock/seed` | **b** | Mock seed endpoint — 운영 환경 노출 여부 결정. 개발 전용이면 삭제 후보 |
| 19 | `DELETE /api/v1/sync/mock/reset` | **b** | Mock reset — #18 과 동일 판정 |
| 20 | `GET /api/v1/sync/status` | **b** | Sync 상태 — WSOP LIVE 연동 관측 endpoint. 기획 누락. |
| 21 | `POST /api/v1/sync/trigger/{source}` | **b** | Sync 수동 트리거 — 관리자 도구인지 아닌지 결정 |
| 22 | `POST /api/v1/events/{event_id}/undo` | **b** | Undo 기능 자체가 기획에 없음. 범위/제약 결정 필요 |
| 23 | `POST /api/v1/tables/{table_id}/launch-cc` | **b** | CC 앱 원격 launch — 기획상 Lobby UI 만 있음. 백엔드 endpoint 필요성 재검토 |
| 24 | `POST /api/v1/flights/{flight_id}/clock/pause` | a | Clock 제어는 기획 §clock 에 이미 존재. endpoint 명시만 누락 |
| 25 | `POST /api/v1/flights/{flight_id}/clock/resume` | a | 동상 |
| 26 | `POST /api/v1/flights/{flight_id}/clock/restart` | a | 동상 |
| 27 | `POST /api/v1/flights/{flight_id}/clock/start` | a | 동상 |
| 28 | `PUT /api/v1/flights/{flight_id}/clock/adjust-stack` | a | WebSocket_Events §4.2 `stack_adjusted` 이벤트에 대응하는 REST. 기획에 명시됨 |
| 29 | `PUT /api/v1/flights/{flight_id}/clock/detail` | a | WebSocket §4.2 `clock_detail_changed` 대응 |
| 30 | `PUT /api/v1/flights/{flight_id}/clock/reload-page` | a | WebSocket §4.2 `clock_reload_requested` 대응 |

### 1차 분류 잠정 집계

| 분류 | 개수 (샘플 30 / 추정 89) | 처리 방향 |
|------|:---:|----------|
| (a) 기획 추가 | 샘플 22 → 추정 **60~70** | Conductor Backend_HTTP.md 보강 PR |
| (b) 판정 필요 | 샘플 8 → 추정 **15~20** | SG-008-a/b/c 개별 승격 |
| (c) 코드 삭제 | 샘플 0 → 추정 **0~5** | team2 세션 (드물 것으로 예상) |

> 상위 30개 샘플은 대부분 (a) 로 분류. 실제로 **"역방향 문서화 89개"** 가 아니라 **"기획 누락을 기획에 반영 60~70개"** 로 재정립된다. 방향은 같지만 주어가 뒤집힌다 — **기획이 먼저, 코드는 대조 대상**.

## team2 세션 후속 지침 (나머지 ~59개)

team2 세션이 받아서 동일 3분류로 처리:

1. **(a) 추가**: 해당 endpoint 를 `Backend_HTTP.md` 관련 섹션에 **이미 있는 기획 흐름과 정합하게** 추가. 임의 응답 스펙 생성 금지 — 관련 데이터 모델·event 소스에 근거.
2. **(b) 승격**: 판정 필요 항목은 `SG-008-b-<slug>.md` 로 개별 파일 생성. 결정 owner 를 Conductor 로 에스컬레이션.
3. **(c) 삭제**: 확실히 불필요한 것만 코드 삭제 PR. 판정 불명이면 (b) 승격.

처리 순서:
1. `logs/drift_report.json` 에서 api.d3 배열 추출 (89개)
2. 본 문서 §상위 30개 분류 샘플 제외 (29개 = 60개 남음. #11 중복 처리 1개 제외)
3. 60개 각각에 분류 라벨 (a/b/c) 부여. 휴리스틱은 §"3분류 기준" 참조.
4. (a) 는 Backend_HTTP.md 에 보강 PR 1건으로 묶음. (b) 는 개별 SG. (c) 는 team2 삭제 PR.

## 수락 기준

- [ ] 상위 30개 샘플 분류 결과가 Conductor 승인
- [ ] (a) 기획 추가분의 1차 Backend_HTTP.md 보강 PR 머지
- [ ] (b) 판정 필요 항목이 SG-008-a/b/c 등 개별 파일로 승격
- [ ] team2 세션이 나머지 ~59개 분류 완료
- [ ] 최종 `python tools/spec_drift_check.py --api` 의 D3 = (c) 삭제분 + (b) 미결정분 만 남음
- [ ] 본 SG 종결 시 `Spec_Gap_Registry.md §4.4` 상태 DONE 갱신

## 결정 (재정의 후)

- 채택: **"기획이 진실" 원칙 (Spec_Gap_Triage §7.2.1)**
- 이유: 불안정 프로토타입의 코드 = 역방향 문서화 원본 부적격. 기획을 주어로 하는 3분류가 유일하게 안전
- 영향 챕터: `Backend_HTTP.md`, `Auth_and_Session.md` 보강 (분류 a 분)
- 후속 SG: SG-008-a (audit RBAC), SG-008-b (sync 공개 범위), SG-008-c (undo 설계) 등 (b) 분류 각각

## Changelog

| 날짜 | 변경 | 비고 |
|------|------|------|
| 2026-04-20 | v1.0 초기 안 | "team2 역방향 문서화 89개" 플랜 |
| 2026-04-20 | **v2.0 전면 재작성** | 사용자 지적으로 "기획이 진실" 원칙 복구. 3분류 (a/b/c) 로 재정의 |
