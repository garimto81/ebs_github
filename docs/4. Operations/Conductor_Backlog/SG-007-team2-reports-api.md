---
id: SG-007
title: "team2 Reports API 통합 — Dashboard/Table Activity/Player Stats/Hand Distribution/RFID Health/Operator"
type: spec_gap
sub_type: spec_gap_major
status: RESOLVED
owner: conductor
decision_owners_notified: [team2, team1]
created: 2026-04-20
resolved: 2026-04-20
affects_chapter:
  - docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md §7 Reports (현재 미완)
  - docs/2. Development/2.1 Frontend/Settings/Statistics.md  (SG-003 §Tab 5)
  - team2-backend/src/routers/reports.py
protocol: Spec_Gap_Triage
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "status=RESOLVED, Reports API 통합 확정"
---
# SG-007 — team2 Reports API 통합 기획

## 공백 서술

`team2-backend/src/routers/reports.py` 라우터 모듈은 존재하나 `Backend_HTTP.md §7 Reports` 섹션이 전반적으로 미완. Backlog 6건 (B-037~050) 모두 기획 미확정:

| Backlog | 리포트 | 용도 |
|:---:|--------|------|
| B-037 | Dashboard | 전체 운영 현황 개요 |
| B-038 | Table Activity | 테이블별 활동 지표 |
| B-039 | Player Statistics | 플레이어 통계 (VPIP/PFR/AF/3bet%) |
| B-048 | Hand Distribution | 핸드 랭킹 분포 |
| B-049 | RFID Health Report | RFID 읽기 오류율·카드 상태 |
| B-050 | Operator Activity Report | 운영자 작업 이력 |

## 결정 (default, 통합 스펙)

### 공통 계약

**Base URL**: `/api/v1/reports/*`  
**Auth**: JWT Bearer (API-06)  
**RBAC**:
- `admin`: 모든 리포트 접근
- `operator`: Table Activity + RFID Health + 자기 Operator Activity
- `viewer`: Dashboard 요약 + 자기 관련 데이터만

**공통 쿼리 파라미터**:

| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|:---:|------|
| `scope` | enum(global, series, event, table) | ○ | 집계 범위 |
| `scope_id` | UUID | △ | scope=global 이면 생략 |
| `from` | ISO 8601 datetime | ○ | 시작 시점 |
| `to` | ISO 8601 datetime | ○ | 종료 시점 |
| `granularity` | enum(minute, hour, day, hand) | ○ | 시계열 집계 단위 |
| `format` | enum(json, csv) | × | 기본 json. csv 는 Accept 헤더 대체 가능 |
| `timezone` | IANA TZ | × | 기본 Asia/Seoul |

**공통 응답 구조**:

```json
{
  "report_type": "dashboard",
  "scope": {"level": "event", "id": "..."},
  "range": {"from": "...", "to": "..."},
  "granularity": "hour",
  "generated_at": "2026-04-20T15:00:00Z",
  "data": { /* 리포트별 상세 */ },
  "pagination": {"cursor": null, "has_more": false}
}
```

### 1. Dashboard (B-037)

**엔드포인트**: `GET /api/v1/reports/dashboard`

**data 필드**:

```json
{
  "tables": {"active": 8, "paused": 2, "closed_today": 3},
  "players": {"seated": 64, "sitting_out": 4, "registered_total": 120},
  "hands": {"in_progress": 5, "completed_today": 287, "avg_duration_sec": 92},
  "rfid_health": {"readers_online": 10, "readers_offline": 0, "error_rate_1h": 0.02},
  "operators_online": 6,
  "wsop_sync": {"last_success_at": "...", "conflicts_pending": 2}
}
```

### 2. Table Activity (B-038)

**엔드포인트**: `GET /api/v1/reports/table-activity`

**data 필드** (시계열 배열):

```json
[
  {
    "bucket": "2026-04-20T14:00:00Z",
    "table_id": "...",
    "hands_completed": 42,
    "avg_pot": 12500,
    "vpip_avg": 0.31,
    "time_per_hand_sec": 87,
    "flops_seen_pct": 0.44
  }
]
```

### 3. Player Statistics (B-039)

**엔드포인트**: `GET /api/v1/reports/player-stats?player_id=...`

**data 필드**:

```json
{
  "player_id": "...",
  "metrics": {
    "vpip": 0.28,
    "pfr": 0.22,
    "af": 2.4,
    "threebet_pct": 0.08,
    "wtsd": 0.31,
    "won_at_showdown": 0.52,
    "total_hands": 1240,
    "net_chips": 450000
  },
  "by_position": {
    "button": {"vpip": 0.45, "pfr": 0.38},
    "sb": {"vpip": 0.18, "pfr": 0.12}
  },
  "time_series": [...]
}
```

### 4. Hand Distribution (B-048)

**엔드포인트**: `GET /api/v1/reports/hand-distribution`

**data 필드**: 169 Holdem 시작패 매트릭스 (AA~72o) × 빈도·승률

```json
{
  "matrix": {
    "AA": {"count": 18, "won_pct": 0.83},
    "KK": {"count": 21, "won_pct": 0.77},
    // ...169 combos (suited/offsuit/pair)
    "72o": {"count": 43, "won_pct": 0.28}
  },
  "total_hands": 3200,
  "showdown_only": false
}
```

### 5. RFID Health Report (B-049)

**엔드포인트**: `GET /api/v1/reports/rfid-health`

**data 필드**:

```json
{
  "readers": [
    {
      "reader_id": "...",
      "table_id": "...",
      "status": "online",
      "error_rate_1h": 0.015,
      "last_error_at": "2026-04-20T14:55:00Z",
      "last_error_code": "ANTENNA_TIMEOUT"
    }
  ],
  "cards": {
    "registered": 260,
    "missing": 1,
    "damaged": 2
  },
  "decks": [
    {"deck_id": "...", "status": "active", "last_verified_at": "..."}
  ]
}
```

### 6. Operator Activity (B-050)

**엔드포인트**: `GET /api/v1/reports/operator-activity?user_id=...`

**data 필드**:

```json
{
  "user_id": "...",
  "sessions": [{"login_at": "...", "logout_at": "...", "duration_sec": 14400}],
  "actions": {
    "total": 1240,
    "by_type": {
      "new_hand": 287,
      "reveal_holecards": 12,
      "undo": 5,
      "settings_change": 3
    }
  },
  "audit_trail_link": "/api/v1/audit?user_id=..."
}
```

### 집계 구현 가이드

- **집계 저장소**: PostgreSQL `reports_aggregated` MV (materialized view) + Redis cache 1h TTL
- **실시간 쿼리 vs 배치**: Dashboard/Table Activity = MV 30초 refresh / Player Stats = on-demand / Hand Distribution = 1h 배치
- **Export (CSV)**: `Accept: text/csv` 지원. 스트리밍 응답 (B-051 연계)
- **Pagination**: cursor-based. `time_series` 또는 `matrix` 가 5000 row 초과 시 분할

## 영향 챕터 업데이트

- [x] 본 SG-007 문서
- [ ] `Backend_HTTP.md §7` 신규 작성 — 6 엔드포인트 full spec (team2 세션)
- [ ] `Backend_HTTP_Status.md` Reports 행 FAIL → PASS 전환 (team2)
- [ ] `reports.py` 라우터 구현 (team2)
- [ ] `team1 Settings/Statistics.md` 에 Reports API 연동 명시 (team1)

## 수락 기준

- [ ] 6 엔드포인트 contract 완전 명세 (request params + response schema + error codes)
- [ ] RBAC 매트릭스 적용 (admin/operator/viewer)
- [ ] pytest 시 6 엔드포인트 × 3 RBAC = 18 시나리오 통과
- [ ] CSV export 스트리밍 지원
- [ ] MV refresh 30초 간격 정상 동작

## 재구현 가능성

- SG-007: **PASS** (본 문서 자립)
- team2 Reports 섹션: FAIL → PASS (6 엔드포인트 spec 완성 후)
- team1 Settings §Tab 5 Stats: UNKNOWN → PASS (SG-007 연동 후)
