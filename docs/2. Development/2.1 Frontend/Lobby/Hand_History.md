---
title: Hand History
owner: team1
tier: feature
legacy-id: BS-02-HH
last-updated: 2026-05-05
reimplementability: PASS
reimplementability_checked: 2026-04-21
reimplementability_notes: "Lobby 사이드바 Hand History 섹션 SSOT — 25개 분산 참조 통합 (Migration Plan 2026-04-21 Phase 1 산출물)"
related:
  - docs/4. Operations/Plans/Lobby_Sidebar_HandHistory_Migration_Plan_2026-04-21.md
  - docs/4. Operations/Critic_Reports/Lobby_IA_Sidebar_2026-04-21.md §7.2
  - docs/2. Development/2.2 Backend/Database/Schema.md (hands/hand_actions/hand_seats)
  - docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md §Hands
  - docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md §3.3 (HandStarted/HandEnded/ActionPerformed)
  - docs/2. Development/2.4 Command Center/Command_Center_UI/Statistics.md (계산식 공유)
  - docs/mockups/ebs-flow-hand-history.html
---
# BS-02-HH Hand History — Lobby 독립 섹션

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-21 | 신규 작성 | SG-016 revised — Lobby 사이드바 공식화 (Migration Plan Phase 1). EBS 고유 기능, WSOP LIVE 비포함, `hands`/`hand_actions`/`hand_seats` 테이블 + WebSocket 3종 + mockup 기반 |
| 2026-05-05 | 신 디자인 시각 자료 추가 | `visual/screenshots/ebs-lobby-06-hands.png` 인라인 추가 (split view: 좌측 hands 리스트 + 우측 hand detail). 디자인 SSOT: `Lobby/References/EBS_Lobby_Design/screens-extra.jsx:5` (`HandHistoryScreen`). |
| 2026-05-07 | v3 cascade | Lobby_PRD v3.0.0 정체성 정합 — 정보 허브 역할 framing 추가 (additive only). |

---

## 개요

> **WSOP LIVE 정보 허브 역할 (Lobby_PRD v3.0.0 cascade, 2026-05-07)**: 운영자가 5 분 게이트웨이 동안 확인하는 **Hand History** (4 진입 시점 ④ "모든 것이 끝날 때" + ② "어긋났을 때" 핸드 검증의 핵심 화면). EBS 고유 기능 — WSOP LIVE 거울이 아닌 EBS 자체 보강.

Hand History 는 Command Center 에서 기록된 포커 핸드(1판) 의 전체 이력을 Lobby 에서 조회·분석하는 EBS 고유 기능이다. 25개 문서에 분산되어 있던 참조를 본 문서가 SSOT 로 통합한다. EBS Core §1.2 경계 준수 — **라이브 운영 + 당일 기록** 범위. 장기 아카이브/편집은 포스트프로덕션 책임.

**EBS 시각 자료 (신 디자인 정합, 2026-05-05):**

![Hand History — split view (좌측 10 hands list + 우측 #47 detail with Board cards + Players 표 + Action Sequence)](visual/screenshots/ebs-lobby-06-hands.png)

| 영역 | 내용 |
|------|------|
| **상단 KPI 5** | Table (현재 ID + Featured) · Hands Played (since L1) · Showdowns (% of total) · Biggest Pot · Avg Pot (last 20 hands) |
| **필터 / 검색** | Search hand # / player · All Hands / Showdown Only / Big Pots seg · Export Hand / Replay 액션 |
| **좌측 hands 리스트** | Hand # · Game · Players · Winner · Pot · Time |
| **우측 hand detail** | Hand 헤더 (#id · Game (Limit) · Table · Pot · Blinds · time) · Board (community cards) · Players 표 (Seat/Player/Hole/Action/Result/P&L) · Action Sequence (Preflop/Flop/Turn/River pot 누적) · Replay ▶ 버튼 |

> 참조: BS-02-00 Overview "EBS 추가 기능" 표 (line 62), Foundation §Ch.6 (3입력→오버레이 파이프라인의 결과물).
> 디자인 SSOT: `Lobby/References/EBS_Lobby_Design/screens-extra.jsx:5` (`HandHistoryScreen`).

---

## 1. 진입 경로

| 진입점 | 동작 | 권한 |
|--------|------|------|
| Lobby 사이드바 `■ Hand History` | Hand Browser 기본 진입 | Admin / Operator / Viewer |
| Table 상세 화면 → `[Hand History (이 테이블)]` | Hand Browser, table_id 사전 필터 | 동상 |
| Command Center → `[Hand History]` 메뉴 | Hand Browser, table_id 사전 필터 | Operator (할당 테이블), Admin |
| 키보드 단축키 (TBD) | Hand Browser | Admin |

> **사이드바 SSOT**: `Lobby/UI.md §공통 레이아웃` 좌측 사이드바 표 row `■ Hand History`.

---

## 2. 서브메뉴 3종

### 2.1 Hand Browser

핸드 목록 검색·필터 화면.

#### 필터

| 필드 | 컴포넌트 | 바인딩 | 비고 |
|------|---------|--------|------|
| Event | Select | `filter.event_id` | Series/Event 계층에서 자동 채움 |
| Day / Flight | Select | `filter.day` | Event 선택 후 활성 |
| Table | Select | `filter.table_id` | Day 선택 후 활성, multi-select |
| Player | Search | `filter.player_id` | Players 섹션과 동일 검색 |
| Date range | Date range picker | `filter.date_from`, `filter.date_to` | 기본: 당일 |
| Hand # | Numeric | `filter.hand_number` | 정확 매칭 |

#### 컬럼

| 컬럼 | 데이터 | 정렬 |
|------|--------|------|
| Hand # | `hand_number` | 기본 desc |
| Start ts | `started_at` (UTC + Series timezone 표시) | desc |
| Table | `table.name` | — |
| Blind level | `blind_level` | — |
| Players (start) | `seat_count` | — |
| Winner seats | `winner_seats[]` (좌석 번호 칩) | — |
| Pot total | `pot_total` (Settings/Display 통화·정밀도) | desc |
| Duration | `end_ts - start_ts` (mm:ss) | — |

#### API

- `GET /api/v1/hands?event_id=&day=&table_id=&player_id=&date_from=&date_to=&hand_number=` (Backend_HTTP §Hands, 필터 확장은 Migration Plan Phase 3)
- 페이지네이션: `?page=&page_size=` (기본 20)

### 2.2 Hand Detail

단일 핸드의 액션 타임라인·카드·팟 전개 화면.

#### 구성

| 영역 | 내용 |
|------|------|
| Header | Hand # / Table / Blind level / Start–End ts / Game type (HOLDEM, PLO4 …) |
| Seat Grid | 좌석별 player 칩, hole card (권한별 마스킹), 시작 stack |
| Timeline | Preflop / Flop / Turn / River 4 단계 탭 또는 vertical timeline |
| Action Sequence | `hand_actions` PK `(hand_id, seq)` 순서. 각 row: seat, action_type, amount, pot_after |
| Pot Tracker | Main pot + side pot 전개. street 별 누적 |
| Winner Banner | `winner_seats[]` + 분배 금액 + 승리 카드 |

#### 데이터

- `GET /api/v1/Hands/{handId}` — 메타
- `GET /api/v1/Hands/{handId}/Actions` — `hand_actions` 시퀀스
- `GET /api/v1/Hands/{handId}/Players` — `hand_seats` (player_id, hole_card_1, hole_card_2)

### 2.3 Player Hand Stats

플레이어별 통계 (당일 한정 — EBS Core §1.2 경계).

#### 지표

| 지표 | 약어 | 정의 | SSOT |
|------|------|------|------|
| Voluntarily Put $ In Pot | VPIP | 자발적 콜/베팅 핸드 비율 | `Command Center/Statistics.md` |
| Pre-Flop Raise | PFR | 프리플랍 레이즈 비율 | 동상 |
| Aggression | AGR | (Bet+Raise) / Call | 동상 |
| Went To Showdown | WTSD | 쇼다운 도달 비율 | 동상 |
| Showdown Win % | W$SD | 쇼다운 승리 비율 | 동상 |

> **계산식 SSOT**: `2.4 Command Center/Command_Center_UI/Statistics.md`. 본 화면은 동일 계산식을 재사용한다 (중복 정의 금지). team4 publisher 가 calc 식을 변경하면 본 화면에도 반영된다.

#### 범위

- **시간**: 당일 한정 (00:00 Series timezone ~ 현재). 어제·과거 데이터는 포스트프로덕션 도구 책임.
- **공간**: 선택 Event 하위 테이블만. Cross-event 비교 미지원.

---

## 3. 데이터 바인딩

### 3.1 DB 테이블 (Schema.md §389~)

| 테이블 | 키 | 본 화면 사용 |
|--------|-----|-------------|
| `hands` | `hand_id` | Hand Browser 컬럼, Hand Detail header |
| `hand_actions` | `(hand_id, seq)` | Hand Detail timeline / Action sequence |
| `hand_seats` | `(hand_id, seat_no)` | Hand Detail Seat Grid + hole card |

### 3.2 인덱스 권고 (Migration Plan Phase 3, decision_owner team2)

```sql
-- Hand Browser 검색 성능
CREATE INDEX idx_hands_event_table_started
  ON hands (event_id, table_id, started_at DESC);

-- Player 필터 (cross-table)
CREATE INDEX idx_hand_seats_player
  ON hand_seats (player_id, hand_id);
```

### 3.3 WebSocket (실시간 갱신)

| 이벤트 | 트리거 | Hand Browser/Detail 동작 |
|--------|--------|------------------------|
| `HandStarted` | CC 가 새 핸드 시작 | Browser: 목록 prepend (현재 필터 매칭 시). Detail: 해당 hand_id 진입 시 stream 전환 |
| `ActionPerformed` | CC 가 액션 송신 | Detail: timeline 행 append, pot 갱신 |
| `HandEnded` | CC 가 팟 분배 완료 | Browser: 행의 `pot_total`/`winner_seats`/`duration` 갱신. Detail: Winner Banner 노출 |

> 정의: `2.2 Backend/APIs/WebSocket_Events.md §3.3.1` (publisher 실측 정합 3종).

---

## 4. RBAC

| 역할 | Hand Browser | Hand Detail | Player Hand Stats |
|------|:------------:|:-----------:|:----------------:|
| **Admin** | 전체 Event/Table 검색 | hole card 전체 공개 | 전체 player |
| **Operator** | 할당 테이블 한정 검색 | 할당 테이블의 hole card 공개. 그 외 마스킹 | 할당 테이블 내 player |
| **Viewer** | 읽기 전용 | hole card **마스킹** (★ 표기) | 전체 player (읽기) |

> **방송 안전**: Viewer 가 진행 중 핸드의 hole card 를 보면 방송 사고. Viewer 는 모든 hole card 마스킹.

---

## 5. 오프 쇼츠 (Overlay 와의 관계)

Hand History 화면 데이터는 **Overlay 출력 대상이 아니다**. 시청자에게 보이는 카드/액션은 Command Center → Game Engine → Overlay 파이프라인이 담당하며, Hand History 는 운영자/관리자용 사후 조회 도구다.

> 경계 명시: `2.4 Command Center/Overlay/Scene_Schema.md`, `Layer_Boundary.md` (Migration Plan Phase 4).

---

## 6. 비활성 조건

| 조건 | 영향 |
|------|------|
| BO 서버 미실행 | Hand Browser 빈 목록 + 배너 "BO 연결 끊김" |
| WebSocket 단절 | Browser/Detail 정적 표시 (실시간 갱신 중단), 배너 "실시간 갱신 일시 중지" |
| Event 미선택 | 필터 강제, 빈 결과 |
| 권한 부족 | 사이드바 미표시 (RBAC 표 참조) |

---

## 7. 영향 받는 요소

| 영향 대상 | 관계 |
|----------|------|
| BS-02 Lobby UI | 사이드바 진입점 (`UI.md §공통 레이아웃`) |
| BS-03 Settings/Stats | Player Hand Stats 의 표시 정밀도 설정 |
| BS-05 Command Center | Hand 데이터 publisher (HandStarted/Ended/ActionPerformed) |
| BS-07 Overlay | 명시적 분리 (§5) — Hand History 데이터는 Overlay 비대상 |
| BO-Hands API | `GET /Hands*` 4 엔드포인트 |
| BO-Database | `hands` / `hand_actions` / `hand_seats` 테이블 |

---

## 8. 유저 스토리

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| HH-1 | Admin | 사이드바 [Hand History] 클릭 | Hand Browser 진입, 당일 모든 Event 핸드 목록 표시 | Event 0개: 빈 결과 + 안내 |
| HH-2 | Operator | Hand Browser 에서 자기 테이블 필터 | 본인 할당 테이블 핸드만 표시 | 미할당 테이블: 결과 0 |
| HH-3 | Viewer | Hand Detail 진입 | Seat 별 hole card 모두 ★ 마스킹 | 종료된 핸드도 동일 |
| HH-4 | Admin | 진행 중 핸드를 Detail 진입 | WebSocket 으로 실시간 액션 추가 표시 | WS 단절: 정적 표시 + 배너 |
| HH-5 | Operator | Player Hand Stats 진입 | 당일 본인 테이블 player VPIP/PFR/AGR 표시 | 핸드 < 5: "표본 부족" 표기 |

---

## 9. 미해결 / 후속 작업

| 항목 | 상태 | 후속 |
|------|:----:|------|
| API 필터 확장 (event/day/player/date) | 대기 | Migration Plan Phase 3 (team2) |
| 인덱스 추가 | 대기 | 동상 |
| CC `Statistics.md` 계산식 공유 선언 | 대기 | Migration Plan Phase 4 (team4) |
| Overlay 경계 명시 | 대기 | Migration Plan Phase 4 (team4) |
| Integration test E2E 시나리오 | 대기 | 동상 |
| 키보드 단축키 정의 | TBD | team1 후속 |
