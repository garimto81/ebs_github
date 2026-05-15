---
title: Team 2 Backend SSOT Compliance Audit
owner: conductor
tier: internal
last-updated: 2026-04-17
confluence-page-id: 3818685131
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818685131/EBS+Team+2+Backend+SSOT+Compliance+Audit
mirror: none
---

# Team 2 Backend SSOT 전수 감사 — 2026-04-17

> **트리거**: Frontend에서 `GET /api/v1/tables?event_flight_id=0` 404. 원인 추적 중 Backend_HTTP.md L402 `GET /tables (?flight_id=)` 가 구현되지 않고 nested `GET /flights/{id}/tables` 만 존재함을 발견. 전수 감사 지시.

**감사 범위**: REST · WebSocket · Auth · Database + Back Office
**방법**: 4개 architect(read-only) 에이전트 병렬, SSOT 문서 ↔ 구현(`src/**`) 대조
**결과**: 221+ 항목 중 ~38% 정합. 구조적 이탈 패턴 6개 확인.

---

## 1. Compliance Scorecard

| 영역 | 항목 | ✅ 정합 | ⚠️ 부분 | ❌ 미구현 | 🚫 spec외 | 준수율 |
|------|---:|:------:|:------:|:------:|:------:|:-----:|
| REST (Backend_HTTP.md) | 75 endpoints | 35 | 14 | 26 | 10 | **47%** |
| WebSocket (WebSocket_Events.md) | 58 items | 26 | 11 | 20 | 1 | **45%** |
| Auth (Auth_and_Session.md + BS-01) | 68 items | 22 | 14 | 28 | 4 | **32%** |
| DB + BO (Schema + Sync_Protocol) | 25 tables + 20 findings | — | 5 | 15 | — | **~40%** |
| **합계** | **221+** | **83** | **44** | **89** | **15** | **~38%** |

---

## 2. Top 10 차단급 위험

| # | 영역 | 현상 | 근거 | 영향 |
|:-:|:----:|------|------|------|
| 1 | DB | `event_flights.status` **TEXT 잔존** (CCR-047은 INT enum) | `init.sql:300`, `competition.py:85` | WSOP LIVE 동기화 시 silent cast / UPSERT 실패 — **데이터 부패** |
| 2 | BO | `wsop_game_type.map_to_ebs` 호출 지점 0 | grep 결과 | 게임타입 22종↔9종 silent 왜곡 |
| 3 | Auth | **Live refresh cookie 미발행** | `auth.py:164-170,266,422-427` | live 배포 시 refresh token 클라이언트 전달 안 됨 |
| 4 | Auth | Refresh TTL **7d** (SSOT=48h, CCR-048) | `jwt.py:17-22` | 세션 노출 창 3.5배 확대 |
| 5 | WS | CC 커맨드(`WriteGameInfo/WriteDeal/WriteAction`) **전면 미처리** | `cc_handler.py` 브랜치 부재 | CC 입력이 서버 계약 없이 동작 → 게임 플로우 불가 |
| 6 | WS | RBAC 미집행 (Operator 테이블 가드 없음) | `manager.py:45-50` | 어떤 Operator든 임의 table_id로 CC 붙음 — 월권 |
| 7 | REST | `GET /tables?flight_id=`, `GET /flights?event_id=` 미구현 | `tables.py`, `series.py` | **현재 404의 직접 원인** |
| 8 | REST | BlindStructure/PayoutStructure 시리즈 스코프 15개 전부 누락 | L758-821 | 플랫만 존재 (SSOT "레거시 호환") |
| 9 | REST | Sync 엔드포인트 네임스페이스 전면 불일치 | `sync.py` vs L965-967 | 운영 UI 연동 불가 |
| 10 | DB | `init.sql` vs Alembic baseline users 컬럼 불일치 | init.sql ↔ `0001_baseline:88-89` | 부트스트랩 경로 분기 |

---

## 3. 패턴 관찰 — 구조적 이탈

**P1. Flat-list 공백**: 백엔드가 nested parent-scoped 리스트(`/events/{id}/flights`)를 채택, SSOT가 요구한 flat filter(`/flights?event_id=`)를 계통적 누락. REST 26 missing 중 절반 이상이 이 패턴. **현재 프론트 404의 근본 원인**.

**P2. CCR-050 (토너먼트 라이프사이클 확장) 미반영**: Flight complete/cancel · Clock detail/reload-page/adjust-stack · WS 이벤트(`tournament_status_changed`, `stack_adjusted`) 등 REST 5 + WS 6개가 한 덩이로 누락. 2026-04-15 SSOT 업데이트 반영 안 됨.

**P3. CCR-048/052/053 보안 정책 미반영**: Refresh TTL · lockout(10회/영구) · rate limiting · suspend vs lock 이원화 · permission bit flag — Auth 4개 대형 정책이 통째로 구식.

**P4. Spec외 구현 15건**: `/audit-logs/download`, `/sync/mock/*`, `/skins/active`, `GET /auth/me` 등. SSOT 업데이트 없이 추가 → 문서-코드 drift 누적.

**P5. 스키마 이중 권위**: `init.sql`과 Alembic baseline이 다른 컬럼 세트 생성. CLAUDE.md 명시 "SQLModel 12 + init.sql 12" 이중 체계가 실제로 drift 발생.

**P6. 상태 머신 가드 미집행**: SeatFSM 전이 누락(`EMPTY→MOVED`, `MOVED→PLAYING`), event_flights/tables/decks status 모두 CHECK 제약 없음. FSM이 "문서상만" 존재.

---

## 4. 근본 원인

> **계약 검증 게이트 부재.** pytest 95/95 통과에도 불구하고 SSOT 대조 단계가 CI에 없어 26 missing REST + 28 missing Auth가 런타임까지 흘러옴. 개별 커밋의 누락이 아니라 파이프라인의 구조적 맹점.

---

## 5. 영역별 상세 (각 감사 에이전트 원본)

### 5.1 REST (75 endpoints)

SSOT: `docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md`

| 섹션 | SSOT | ✅ | ⚠️ | ❌ | 주요 결함 |
|------|---:|:--:|:--:|:--:|-----------|
| 5.2 Users | 5 | 5 | 0 | 0 | — |
| 5.3 Competitions | 5 | 5 | 0 | 0 | — |
| 5.4 Series | 5 | 5 | 0 | 0 | — |
| 5.5 Events | 6 | 5 | 1 | 0 | POST /events 플랫 없음 (nested만) |
| 5.6 Flights | 7 | 3 | 1 | 3 | GET /flights?event_id=, complete/cancel 없음 |
| 5.6.1 Clock | 9 | 1 | 5 | 3 | CCR-050 3개 누락, Admin-only 월권 |
| 5.7 Tables | 9 | 4 | 2 | 2 | **GET /tables?flight_id= 없음 (404 원인)**, /status 없음 |
| 5.8 Seats | 2 | 2 | 0 | 0 | — |
| 5.9 Players | 6 | 6 | 0 | 0 | — |
| 5.10 Hands | 4 | 3 | 1 | 0 | GET /hands table_id required (SSOT는 optional) |
| 5.11 Configs | 2 | 0 | 2 | 0 | 응답/요청 shape 불일치 |
| 5.12 Skins | 9 | 3 | 2 | 3 | upload/download/duplicate 없음, PATCH≠PUT |
| 5.13 BlindStructures | 8 | 1 | 0 | 7 | 시리즈 스코프 전부 없음 |
| 5.13.1 PayoutStructures | 7 | 0 | 0 | 7 | 시리즈·Flight 스코프 전부 없음 |
| 5.14 AuditLogs | 1 | 0 | 1 | 0 | 필터 누락 |
| 5.15 Reports | 1 | 0 | 1 | 0 | 필터 무시 |
| 5.16 Sync | 3 | 0 | 1 | 2 | 네임스페이스 전면 불일치 |

### 5.2 WebSocket (58 items)

SSOT: `docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md`

**Top 5 치명 결함**:
1. CC 커맨드 프로토콜 전면 미구현 — `WriteGameInfo/WriteDeal/WriteAction` + Ack/Rejected 브랜치 0개
2. RBAC 미집행 — `role` 캡처만, Operator 테이블 가드 없음
3. Lobby-only 이벤트 publisher 0 호출 — `event_flight_summary`/`clock_tick`/`clock_level_changed` 헬퍼만 존재, 스케줄러 없음
4. CCR-050/054 이벤트 11종 publisher 부재 — `clock_detail_changed`, `tournament_status_changed`, `skin_updated` 등
5. Envelope 일관성 깨짐 — Ack에 `server_time`/`seq` 누락, 파싱 에러 시 `type:"Error"` 대신 `Ack` 반환

### 5.3 Auth (68 items, 10 categories)

SSOT: `docs/2. Development/2.2 Backend/APIs/Auth_and_Session.md` + `docs/2. Development/2.5 Shared/Authentication.md`

**보안 영향순 Top 5**:
1. **Live refresh cookie 미발행** — `delivery="cookie"` 분기에 `Set-Cookie` 헤더 설정 없음
2. **Refresh TTL 7d (SSOT 48h)** — CCR-048 위반, 세션 노출 3.5배
3. **Lockout 5회/30분 (SSOT 10회/영구)** — 구식 정책. 2FA·refresh 이상치 전무
4. **Rate Limiting 전면 부재** — BS-01 §CCR-052 카테고리별 한계 미구현
5. **Operator 테이블 가드 없음 + Permission Bit Flag 미구현** — Operator 월권 가능

**추가**: `DELETE /auth/session` (SSOT) ↔ `POST /auth/logout` (impl) 메서드 불일치. `/auth/exchange` (CC Lobby-Only Launch 핵심) 부재. Suspend vs Lock 이원화 없음. `PERMISSION_DENIED` ≠ SSOT `AUTH_FORBIDDEN`.

### 5.4 Database + Back Office (25 tables + 20 findings)

SSOT: `Database/Schema.md`, `Database/State_Machines.md`, `Back_Office/Sync_Protocol.md`

**심각도순 Top 5**:
1. **`event_flights.status` TEXT 잔존 (CCR-047 INT 미반영)** — Schema.md와 정반대
2. **`wsop_game_type.map_to_ebs` 호출 지점 0** — silent corruption 경계 비활성
3. **`sync_cursors` in-memory only** — 재시작 시 full resync 강제, CB OPEN 위험
4. **init.sql ↔ Alembic baseline users 불일치** — 부트스트랩 경로별 스키마 분기
5. **SeatFSM `EMPTY→MOVED`, `MOVED→PLAYING` 전이 누락** — SeatMove 처리 차단

**추가 갭**: CCR-049 blind_structures 필드 6종. CCR-053 users suspend/lock 이원화. Fallback Queue(Redis Stream, dead letter) 전무. Mock seed 수량 drift(Series 3→2, Events 30→3). `/sync/verify`, `/sync/force` 미구현. output_presets 필드 3종. events/tables/decks status CHECK 없음. payout_structures Schema 괴리. `cards` 테이블 Schema.md 미정의. table_seats CHECK 중복 선언.

---

## 6. 권고 실행 순서

| Phase | 내용 | 규모 | 트리거 |
|:-----:|------|:----:|--------|
| **A. 즉시** | Top10 중 #1(event_flights.status INT) · #3(live cookie) · #5(WS CC commands) · #7(flat list) · #10(init.sql↔Alembic) | 2~3일 | 현재 404/월권/데이터 부패 |
| **B. 단기** | CCR-050 block(REST 5 + WS 6), CCR-048 보안 정책, Sync 네임스페이스, Skin file I/O | 1주 | 프론트 연동 연쇄 문제 |
| **C. 중기** | BlindStructure/PayoutStructure 시리즈 스코프, Permission Bit Flag, Rate Limiting, FSM CHECK 제약 | 2~3주 | MVP 전 필수 |
| **D. 게이트** | CI에 SSOT 파서 + 라우트 추출 + diff 실패 게이트. `integration-tests/scenarios/` SSOT 경로별 `.http` | 3일 | **재발 방지 (최우선)** |

---

## 7. Phase A/B/D 실행 결과 (2026-04-17 당일)

Conductor 세션에서 자율 실행. 브랜치: `work/team2/20260417-ssot-recovery`.

### 변경 요약

| Phase | 내용 | 상태 | 신규 테스트 |
|:-----:|------|:----:|:---------:|
| A.1 | Flat REST (`GET/POST /tables`, `/flights`, `POST /events`) + SSOT 경고 메시지 | ✅ | 7 |
| A.2 | Refresh TTL 48h (CCR-048) + live Set-Cookie 실제 발행 | ✅ | 7 |
| A.3 | WS Operator 테이블 가드 (`AUTH_TABLE_NOT_ASSIGNED`), JWT `assigned_tables` claim | ✅ | 5 |
| A.4 | `wsop_game_type.map_to_ebs` UPSERT 경로 연결 (`upsert_events`) | ✅ | 4 |
| A.5 | `event_flight_status` 어댑터 (silent corruption 방지) | ✅ (부분) | 9 |
| A.6 | `init.sql ↔ Alembic` users 컬럼 정렬 | ✅ | — |
| A.7 | WS CC 커맨드 (`WriteGameInfo/Deal/Action` + `*Ack`/`*Rejected`) | ✅ | 7 |
| B.1 | CCR-050 Flight complete/cancel + Clock detail/reload-page/adjust-stack | ✅ | 8 |
| B.2 | `/sync/wsop-live`, `/sync/wsop-live/status`, `/sync/conflicts` (legacy 유지) | ✅ | 5 |
| D | `tools/ssot_route_diff.py` + CI 워크플로우 (exit 0 blocker, B-066 planned-gap 격리) | ✅ | — |
| C | BlindStructure/PayoutStructure 시리즈 스코프, Skin 파일 I/O | ⏳ B-066 이관 | — |

### 수치 변화

- **pytest**: 154 → **210 pass** (+56 신규, 회귀 0)
- **REST SSOT 준수**: 26 missing → **16 missing (B-066 planned)** — 38% 개선
- **CI SSOT gate**: unexpected drift **0건** 보장
- **브랜치**: `work/team2/20260417-ssot-recovery` (ff-merge 대기)

### Phase C 잔여 (B-066)

- BlindStructure 시리즈 스코프 8개 endpoint + CCR-049 컬럼 6종
- PayoutStructure 시리즈/Flight 스코프 7개 endpoint + Schema §4 재설계
- Skin 파일 I/O 3개 (upload/download/duplicate) + GFSkin 스키마
- DB 스키마 마무리 (event_flights INT 완전 전환, CCR-053 suspend/lock, sync_cursors 영속화, Fallback Queue, SeatFSM 전이)
- Auth 보안 정책 (CCR-052 rate limiting, 10회/영구 lockout, Permission Bit Flag, `/auth/exchange`)

## 8. 백로그

- **B-066**: `docs/2. Development/2.2 Backend/Backlog/B-066-SSOT-compliance-recovery.md`

## 9. 결정 로그

| 결정 | 내역 | 근거 |
|------|------|------|
| Nested endpoints 운명 | **deprecated 유지 (B 방안)** | 프론트 무변경 + `{*}` 와일드카드 allow-list 로 CI gate 통과 |
| Spec외 구현 15건 | **allow-list 유지 (운영 도구)** | `/sync/mock/*`, `/audit-logs/download` 등은 운영/디버그용 |
| event_flights.status | **어댑터 먼저 (silent corruption 차단)** + INT 컬럼 전환은 B-066 | Clock FSM 의 "paused" 상태 분리가 선행되어야 안전 |
| CI gate 엄격도 | **unexpected drift 0, planned gap 별도 추적** | 의도적 미구현과 silent drift 구분 필요 |
