---
title: Plan — Lobby 사이드바 Hand History 섹션 공식화 + Insights 제거
owner: conductor
tier: internal
last-updated: 2026-04-21
reimplementability: PASS
reimplementability_checked: 2026-04-21
reimplementability_notes: "Migration plan — SSOT 위치 + 25개 참조 통합 + 팀별 작업 분해"
related:
  - docs/4. Operations/Critic_Reports/Lobby_IA_Sidebar_2026-04-21.md §7 revision 1
  - docs/4. Operations/Spec_Gap_Registry.md SG-016 revised
---

# Plan — Lobby 사이드바 Hand History 섹션 공식화

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-21 | 신규 작성 | 사용자 지시(/team insights 제거 / handhistory 추가 / 수정 계획 수립) |

## 1. 배경

2026-04-21 사용자 지시로 `Critic_Reports/Lobby_IA_Sidebar_2026-04-21.md` §7 권고안에서:
- **Insights 섹션 제거** — EBS Core §1.2 경계 위험 해소
- **Hand History 독립 섹션 승격** — 기존 25개 분산 참조를 SSOT 로 통합

Hand History 는 이미 EBS 구성요소로 존재 (Foundation §Ch.6, `hands`/`hand_actions` 테이블, WebSocket 이벤트 3종, mockup 1개) 하지만 **Lobby 사이드바 진입점이 없고 기능 문서(`Hand_History.md`) 가 부재**.

## 2. 영향 문서 맵 (25개 + 신규 1개)

### 2.1 Tier A — 직접 수정 필수 (SSOT 영향)

| # | 경로 | 유형 | 변경 내용 |
|:-:|------|------|-----------|
| A1 | `docs/2. Development/2.1 Frontend/Lobby/Hand_History.md` (**신규**) | 기능 SSOT | Lobby/Reports.md 와 동격의 기능 문서 신설 (아래 §3.1 목차 준수) |
| A2 | `docs/2. Development/2.1 Frontend/Lobby/UI.md` §공통 레이아웃 | 사이드바 구조 | `■ Hand History` 섹션 표 row 추가 (line 435~447 사이) + ASCII 다이어그램 갱신 |
| A3 | `docs/2. Development/2.1 Frontend/Lobby/Overview.md` §화면 번호 재배정 | Lobby 개요 | Hand History 를 "독립 레이어" 목록에 포함 (line 281~286 표 갱신) |

### 2.2 Tier B — 참조/정렬 갱신

| # | 경로 | 유형 | 변경 내용 |
|:-:|------|------|-----------|
| B1 | `docs/2. Development/2.1 Frontend/Lobby/Operations.md` | Operations 연동 | Hand History 진입점 링크 추가 (테이블 Operations 흐름에서 Hand History 연결) |
| B2 | `docs/2. Development/2.1 Frontend/Settings/UI.md` | Settings 영향 | Stats 탭 (VPIP/PFR etc.) 설정이 Hand History Player Stats 에 적용됨을 명시 |
| B3 | `docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md` §Hands | API | 현재 `?table_id=` 필터만 존재 → Event/Day/Player/Date 필터 확장 권고 (SG-b 로 승격) |
| B4 | `docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md` | WebSocket | HandStarted/HandEnded/ActionPerformed 가 Hand History 실시간 갱신 트리거임을 명시 |
| B5 | `docs/2. Development/2.2 Backend/Database/Schema.md` | DB 스키마 | hands/hand_actions/hand_seats 인덱스 검토 — Hand History 검색 성능 대비 (event_id, table_id, start_ts 복합) |
| B6 | `docs/2. Development/2.2 Backend/Back_Office/Overview.md` | BO 언급 | BO → Hand History 권한 정책 매트릭스 |
| B7 | `docs/2. Development/2.4 Command Center/Command_Center_UI/Statistics.md` | CC 통계 | Hand History Player Stats 와 동일 계산식 사용 — decision_owner: team2 publisher |
| B8 | `docs/2. Development/2.4 Command Center/Command_Center_UI/UI.md` | CC UI | CC → Hand History 진입 링크 (운영자 시점) |
| B9 | `docs/2. Development/2.4 Command Center/Integration_Test_Plan.md` | 통합 테스트 | Hand History E2E 시나리오 추가 |
| B10 | `docs/2. Development/2.4 Command Center/Overlay/Scene_Schema.md` | Overlay 경계 | Hand History 데이터는 Overlay 출력 아님 (Lobby 내부) 명시 |
| B11 | `docs/2. Development/2.4 Command Center/Overlay/Layer_Boundary.md` | 경계 | 위 B10 과 동일 |
| B12 | `docs/2. Development/2.1 Frontend/Engineering.md` | FE 엔지니어링 | Hand History 화면/컴포넌트 구현 가이드 링크 |
| B13 | `docs/1. Product/References/WSOP-Production-Structure-Analysis.md` | 참조 | Hand History 가 WSOP LIVE 에는 없는 EBS 고유 기능임을 재확인 |

### 2.3 Tier C — 역사 문서 (읽기 전용, 수정 불필요)

| # | 경로 | 비고 |
|:-:|------|------|
| C1-4 | `docs/2. Development/2.1 Frontend/Graphic_Editor/References/skin-editor/**` (4건) | GE 역사 참조만 |
| C5-6 | `docs/3. Change Requests/done/CR-team4-20260410-*.md` (2건) | 완료된 CR (역사) |
| C7 | `docs/mockups/ebs-flow-hand-history.html` | 기존 mockup — 신규 `Hand_History.md` 에서 참조로만 사용 |
| C8 | `docs/mockups/ebs-flow-data-sync.html` | 데이터 연동 흐름 — 언급만 |
| C9 | `docs/4. Operations/Multi_Session_Handoff.md` | 이관 기준 — 언급만 |

## 3. 단계별 실행 계획

### 3.1 Phase 1 — SSOT 신설 (신규 `Lobby/Hand_History.md`)

**decision_owner**: team1 (Lobby 기능 문서 규약)

**필수 목차** (Lobby/Reports.md 규약 정렬):

```
---
title: Hand_History
owner: team1
tier: internal
legacy-id: BS-02-HH
---
# BS-02-HH Hand History — Lobby 독립 섹션

| 날짜 | 항목 | 내용 |
| 2026-04-21 | 신규 작성 | SG-016 revised — Lobby 사이드바 공식화 |

## 개요
EBS 고유 기능. 25개 문서 참조 통합 SSOT.

## 1. 진입 경로
- Lobby 사이드바 [Hand History]
- Table 상세 → [Hand History (이 테이블)] 바로가기
- CC → [Hand History] (운영자)

## 2. 서브메뉴 3종
### 2.1 Hand Browser
필터: Event / Day / Table / Player / Date range
컬럼: Hand # / Start ts / Table / Winner seats / Pot / Duration

### 2.2 Hand Detail
타임라인: Preflop / Flop / Turn / River
Action 시퀀스 (hand_actions PK hand_id+seq)
Seat 별 hole card (권한별 masking — Admin/Operator 공개, Viewer 마스킹)
팟 전개 (side pot 포함)

### 2.3 Player Hand Stats
당일 한정 (EBS Core §1.2 경계)
집계: VPIP / PFR / AGR / WTSD / showdown win %
Settings/Stats 탭 (Settings/UI.md) 의 통계 설정이 여기에 적용됨

## 3. 데이터 바인딩
- `hands` (Schema.md §389~) — 핸드 메타
- `hand_actions` — 액션 시퀀스
- `hand_seats` — 좌석/hole card
- `GET /api/v1/hands?...` (Backend_HTTP §Hands)
- WebSocket HandStarted/HandEnded/ActionPerformed (WebSocket_Events §3.3.1)

## 4. RBAC
| 역할 | Hand Browser | Hand Detail | Player Stats |
| Admin | O | 전체 공개 | O |
| Operator | O (할당 테이블) | hole card 공개 | O |
| Viewer | O (읽기) | hole card 마스킹 | O |

## 5. 비활성 조건 / 영향 요소
(Reports.md 스타일 정렬)
```

### 3.2 Phase 2 — UI 레이아웃 갱신 (Tier A2, A3)

**decision_owner**: team1

1. **`UI.md` §공통 레이아웃 line 435 주변** 사이드바 섹션 표에 row 추가:
   ```
   | **Hand History** | Hand Browser | BS-02-HH §2.1 |
   |                  | Hand Detail | BS-02-HH §2.2 |
   |                  | Player Hand Stats | BS-02-HH §2.3 |
   ```
2. **`UI.md` ASCII 다이어그램** (line 395~412) 에 `■ Hand History` 블록 추가:
   ```
   ■ Hand History
     Hand Browser
     Hand Detail
     Player Stats
   ```
3. **`Overview.md` 화면 목록** (line 281~286) 에 "Hand History (독립 레이어)" 추가.

### 3.3 Phase 3 — Backend 계약 정렬 (Tier B3, B4, B5)

**decision_owner**: team2 (publisher, Fast-Track 권한)

1. **`Backend_HTTP.md` §Hands**: 필터 확장 — `GET /api/v1/hands?event_id=&day=&player_id=&date_from=&date_to=`. Backend_HTTP_Status.md 반영.
2. **`WebSocket_Events.md`**: Hand History 실시간 갱신이 HandStarted/HandEnded 소비자임을 §3.3 Lobby 소비자 state 테이블에 명시.
3. **`Schema.md`**: hands 테이블 검색 성능 인덱스 검토 (복합 `(event_id, table_id, started_at DESC)` 권고).

> 파괴적 변경 아님 (필드 추가 only). subscriber 사전 합의 불필요.

### 3.4 Phase 4 — 팀별 정렬 (Tier B2, B6~B13)

**decision_owner**: 각 팀 (Fast-Track within own path)

- team1: `Engineering.md` 에 Hand History 컴포넌트 가이드 링크
- team2: `Back_Office/Overview.md` 권한 매트릭스
- team4: `Statistics.md` (CC) 에 Hand History Player Stats 와 계산식 공통 선언
- team4: `Overlay/Scene_Schema.md`, `Layer_Boundary.md` 에 "Overlay 출력 아님" 명시
- team4: `Integration_Test_Plan.md` 에 Hand History E2E 시나리오 추가

### 3.5 Phase 5 — Insights 제거 추적

Critic 리포트 §7 (revision 1) 에서 Insights 삭제 완료. 추가 파급:
- `Spec_Gap_Registry.md` SG-016 업데이트 완료 (2026-04-21)
- MEMORY 내 "Insights" 라벨 사용처 없음 (확인 완료)
- 다른 팀 문서에 Insights 참조 **없음** (grep 결과 — 기존 사이드바 v1 은 main 에 밀리지 않은 critic 리포트 내부에만 존재)

## 4. 작업 승인 체크리스트

| 항목 | 상태 |
|------|:----:|
| Insights 제거 완료 (critic §7) | ✓ |
| Hand History 섹션 정의 (critic §7.2) | ✓ |
| SG-016 갱신 | ✓ |
| 신규 `Hand_History.md` 작성 | 대기 (team1) |
| `UI.md` 사이드바 반영 | 대기 (team1) |
| `Overview.md` 목록 반영 | 대기 (team1) |
| Backend 필터 확장 | 대기 (team2) |
| CC 통계 계산식 공유 선언 | 대기 (team4) |
| Integration test 시나리오 | 대기 (team4) |

## 5. 리스크

| 리스크 | 영향 | 완화 |
|--------|------|------|
| Player Hand Stats 가 장기 통계로 확장되어 포스트프로덕션 경계 위반 | Core §1.2 위반 | "당일 한정" 을 `Hand_History.md` §2.3 에 명문화. team4 `Statistics.md` 와 경계 정렬 |
| hole card 권한 정책 불일치 | 보안/방송 사고 | §4 RBAC 표 SSOT 로 Foundation §RBAC 와 cross-check |
| hands 테이블 대용량 시 검색 성능 | UX 저하 | Phase 3 인덱스 권고 (event_id, table_id, started_at DESC) |
| 25개 참조 동기화 drift | 문서↔코드 gap 재발 | `tools/spec_drift_check.py --all` 주기 스캔 유지 |

## 6. 예상 산출물 (PR 후보)

| PR | 팀 | 파일 수 | 규모 |
|----|----|:------:|:----:|
| PR-1 | team1 | 3 (Hand_History.md + UI.md + Overview.md) | M |
| PR-2 | team2 | 3 (Backend_HTTP.md + Backend_HTTP_Status.md + Schema.md + WebSocket_Events.md) | S |
| PR-3 | team4 | 4 (Statistics.md + UI.md + Scene_Schema.md + Layer_Boundary.md + Integration_Test_Plan.md) | S |

**총 ≈ 10 파일. Parallel 진행 가능 (충돌 경로 없음 — v7 free_write + team-scoped paths)**.

## 7. 다음 /team 실행 권고

사용자 승인 후 후속 3 트랜잭션:

```
/team "team1: Hand_History.md 신설 + UI.md 사이드바 + Overview.md 반영"
/team "team2: Hand History API 필터 확장 (event/day/player/date)"
/team "team4: CC Statistics Hand History 계산식 공유 + Integration test"
```

본 문서가 승인 대기 SSOT. 사용자 confirm 후 3 PR 병렬 착수.
