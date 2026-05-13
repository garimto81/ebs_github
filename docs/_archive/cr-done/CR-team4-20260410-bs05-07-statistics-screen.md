---
title: CR-team4-20260410-bs05-07-statistics-screen
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team4-20260410-bs05-07-statistics-screen
confluence-page-id: 3820553400
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3820553400/EBS+CR-team4-20260410-bs05-07-statistics-screen
---

# CCR-DRAFT: BS-05-07 Statistics 화면 (AT-04) 신규 작성

- **제안팀**: team4
- **제안일**: 2026-04-10
- **영향팀**: [team2]
- **변경 대상 파일**: contracts/specs/BS-05-command-center/BS-05-07-statistics.md, contracts/specs/BS-05-command-center/BS-05-00-overview.md
- **변경 유형**: add
- **변경 근거**: CCR-017(BS-05에 AT 화면 체계 도입)에서 AT-04 Statistics 화면을 "BS-05-07-stats.md (신규 예정)"로 dangling reference 처리했으나 실제 파일이 존재하지 않아 계약 참조 체인이 끊긴 상태다. WSOP 원본(`EBS UI Design Action Tracker.md` §6.4)은 AT-04 Statistics 화면을 "10좌석 통계 테이블 + 방송 GFX 제어"로 정의하며, 운영자가 실시간으로 각 플레이어의 VPIP/PFR/핸드 수 등을 확인하고 방송 송출 여부를 결정할 수 있어야 한다. 본 CCR은 이 dangling reference를 해소한다.

## 변경 요약

1. `BS-05-07-statistics.md` 신규 작성: AT-04 화면의 UI, 통계 카탈로그, 방송 제어 정책
2. `BS-05-00-overview.md` 화면 카탈로그에서 AT-04 참조를 `BS-05-07-statistics.md`로 고정 (기존 "신규 예정" 제거)

## 변경 내용

### 1. BS-05-07-statistics.md (신규 파일)

```markdown
# BS-05-07 Statistics Screen (AT-04)

> **참조**: BS-05-00 §AT 화면 카탈로그, BS-02-lobby §테이블 통계, API-01 §통계 엔드포인트

## 역할

AT-04는 운영자가 현재 테이블의 플레이어 통계와 핸드 히스토리를 실시간 확인하고,
방송용 통계 GFX의 송출 여부를 제어하는 화면이다.

- 페르소나: Operator 이상
- 사용 시점: 핸드 진행 중 수시 확인, 방송 중 GFX Push 트리거
- 갱신 주기: 핸드 완료 시 (WebSocket `HandCompleted` 이벤트 기반)

## 진입 경로

- AT-01 Main M-01 Toolbar → Menu → "Statistics"
- 키보드 단축키: 미지정 (키 충돌 방지)

## 화면 구성

```
┌──────────────────────────────────────────────────────┐
│ ← Back                                  Statistics   │
│                                                      │
│ Table: [WSOP FT 2026] Hand#: 248 / 1500              │
│                                                      │
│ ┌────────────────────────────────────────────────┐   │
│ │ Seat │ Player    │ VPIP │ PFR │ 3Bet │ AF │ Gfx │   │
│ ├──────┼───────────┼──────┼─────┼──────┼────┼─────┤   │
│ │ 1    │ Alice     │ 24%  │ 18% │ 7%   │2.1 │ [▶] │   │
│ │ 2    │ Bob       │ 32%  │ 22% │ 9%   │3.4 │ [▶] │   │
│ │ ... (10seats)                                  │   │
│ └────────────────────────────────────────────────┘   │
│                                                      │
│ [Refresh] [Export CSV]   [Push Table Stats to GFX]   │
└──────────────────────────────────────────────────────┘
```

## 통계 카탈로그 (6종)

| 통계 | 약어 | 계산 | 표시 |
|------|------|------|------|
| Voluntary Put in Pot | VPIP | `(voluntary_hands / total_hands) × 100` | % |
| Pre-Flop Raise | PFR | `(pfr_hands / total_hands) × 100` | % |
| 3-Bet Percentage | 3Bet | `(three_bet_hands / pfr_chances) × 100` | % |
| Aggression Factor | AF | `(bets + raises) / calls` | 소수 1자리 |
| Total Hands Played | Hands | `count(hands_with_action)` | 정수 |
| Current Session Profit | P/L | `current_stack - buy_in` | 금액 |

추가 통계는 Phase 2:
- WTSD (Went to Showdown)
- W$SD (Won at Showdown)
- Steal Attempt %
- Fold to 3-Bet %

## 갱신 정책

- **실시간 갱신 금지**: 핸드 진행 중 통계가 바뀌면 운영자 혼란 유발
- **핸드 완료 후 갱신**: `HandCompleted` WebSocket 이벤트 수신 시 1회 갱신
- **수동 Refresh**: Operator가 강제로 갱신 가능 (Backend에 재조회 요청)

## 방송 GFX Push

운영자가 특정 통계를 방송 Overlay에 송출:

### Individual Push (좌석별)
- 각 좌석의 `[▶]` 버튼 클릭 → 해당 플레이어의 통계만 Overlay에 8초간 표시
- 동일 플레이어의 기존 통계 GFX가 있으면 교체
- API: `POST /ws/cc ActionPerformed { type: "push_player_stats", seat_no, duration_sec: 8 }`

### Table Push (전체)
- `[Push Table Stats to GFX]` 버튼 → 10좌석 통계 테이블 전체를 Overlay에 15초간 표시
- 동일 Push가 활성 중이면 교체
- API: `POST /ws/cc ActionPerformed { type: "push_table_stats", duration_sec: 15 }`

### Push 취소
- Overlay는 duration 경과 후 자동 숨김
- 운영자가 즉시 취소하려면 동일 버튼 재클릭 → `type: "hide_stats"` 발송

## Export

- `[Export CSV]` 버튼 → 현재 10좌석 통계를 CSV 다운로드
- 파일명: `stats-{table_id}-{hand_number}-{timestamp}.csv`

## 권한

| Role | 조회 | Push | Export |
|------|:----:|:----:|:------:|
| Admin | ✅ | ✅ | ✅ |
| Operator | ✅ | ✅ | ✅ |
| Viewer | ✅ | ❌ | ❌ |

## 서버 프로토콜

| 동작 | API | 응답 |
|------|-----|------|
| 조회 | `GET /tables/{id}/stats?scope=current_session` | `{ seats: [{seat_no, player_id, stats: {...}}], hand_count }` |
| Push | `POST /ws/cc ActionPerformed` | WebSocket (Overlay에 `PushStats` 이벤트 전파) |
| Export | `GET /tables/{id}/stats/export?format=csv` | CSV binary |

## 구현 위치

- `team4-cc/src/lib/features/stats/screens/stats_screen.dart`
- `team4-cc/src/lib/features/stats/providers/stats_provider.dart`
- `team4-cc/src/lib/features/stats/services/stats_api_client.dart`

## 참조

- BS-05-00-overview §AT 화면 카탈로그
- BS-07-01-elements §Stats Overlay Element (Push 수신 측)
- `Backend_HTTP.md` (legacy-id: API-01) §Stats 엔드포인트
- `WebSocket_Events.md` (legacy-id: API-05) §PushStats 이벤트
```

### 2. BS-05-00-overview.md §화면 카탈로그 수정

CCR-017에서 추가한 AT 화면 카탈로그의 AT-04 행을 업데이트:

```diff
-| AT-04 | Statistics | — | 메뉴 | BS-05-07-stats.md (신규 예정) |
+| AT-04 | Statistics | — | 메뉴 | BS-05-07-statistics.md |
```

## 영향 분석

### Team 2 (Backend)
- **영향**:
  - `GET /tables/{id}/stats` 엔드포인트가 API-01에 이미 있는지 확인. 없으면 별도 Cross-reference CCR 필요
  - `POST /tables/{id}/stats/export` CSV 변환 로직 구현
  - `HandCompleted` 이벤트 발행 시점에 통계 캐시 갱신
  - `PushStats` WebSocket 이벤트가 API-05에 정의되어 있는지 확인
- **예상 리뷰/구현 시간**: 8시간

### Team 4 (self)
- **영향**:
  - `team4-cc/src/lib/features/stats/` 모듈 신규
  - 통계 테이블 UI (10좌석 × 6통계)
  - CSV export 로직 (Flutter `csv` 패키지)
  - Mock 통계 데이터로 개발
- **예상 작업 시간**: 14시간

### 마이그레이션
- 없음

## 대안 검토

### Option 1: AT-04 미채택, dangling reference 유지
- **단점**: 계약 참조 깨진 채 방치 → CCR-017의 신뢰도 훼손
- **채택**: ❌

### Option 2: BS-05-07-statistics.md 신규 작성 (본 제안)
- **장점**: dangling reference 해소 + WSOP 원본 AT-04 기능 반영
- **채택**: ✅

### Option 3: BS-03-05-stats.md로 통합
- **단점**: 
  - BS-03-05는 이미 존재하며 BO 관점(관리자 설정)
  - AT-04는 CC 관점(운영자 조회/Push)
  - 관점 혼재로 가독성 저하
- **채택**: ❌

## 검증 방법

### 1. 계약 참조 일관성
- [ ] BS-05-00의 AT-04 행이 BS-05-07-statistics.md를 올바르게 참조
- [ ] BS-05-07과 API-01/API-05 사이 양방향 참조

### 2. API 존재 확인
- [ ] API-01 `GET /tables/{id}/stats` 존재
- [ ] API-05 `PushStats` 이벤트 스키마 존재 (없으면 team2 Cross-ref CCR)

### 3. Mock 시나리오
- [ ] Mock WSOP LIVE가 10좌석 샘플 통계 제공
- [ ] 핸드 완료 시 WebSocket으로 갱신 시뮬레이션
- [ ] Individual Push / Table Push 시나리오 E2E

### 4. 권한 검증
- [ ] Viewer는 Push 버튼 비활성
- [ ] Operator는 Push/Export 가능
- [ ] Admin 전체 권한

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 2 기술 검토 (Stats API, PushStats 이벤트)
- [ ] Team 4 기술 검토 (Mock 통계, UI 구현)
