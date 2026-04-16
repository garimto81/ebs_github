---
title: Reports & Statistics
owner: team1
tier: feature
last-updated: 2026-04-16
---

# Reports & Statistics

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-16 | 신규 작성 | WSOP LIVE "09. Reports" (Confluence p1728938527) — Unique Player Report (p1931707281) + WSOP Vegas Report (p2432073931) + History 탭 강화 (p1876394154) 기반 |

---

## 개요

Tournament 통계 및 리포트 화면. Players Count, Tournament History, Prize Pool Report, Unique Player Report, Action History 제공. WSOP LIVE Staff App §09 Reports 구조를 채택하되 EBS 운영 규모에 맞게 간소화한다.

---

## 1. 기능 범위

| 기능 | 설명 |
|------|------|
| **Players Count** | 실시간 Active Players, Total Entries, Unique Players 카운트 |
| **Tournament History** | Action History — Staff/Player별 이벤트 이력 검색 |
| **Prize Pool Report** | 이벤트별 Prize Pool 요약 (Total Entries, Buy-in, Prize, Fee) |
| **Unique Player Report** | Daily / Tournament 기준 Unique Player 집계 |
| **Export** | CSV / PDF 다운로드 |

---

## 2. 화면 구조

### 2.1 Players Count (실시간)

| 필드 | 컨트롤 | 비고 |
|------|--------|------|
| Active Players | 읽기 전용 (큰 숫자) | 현재 착석 중 |
| Total Entries | 읽기 전용 | 전체 등록 수 |
| Unique Players | 읽기 전용 | 중복 제거 플레이어 수 |
| Tables Active | 읽기 전용 | LIVE 상태 테이블 수 |

WebSocket `flight_stats_updated` 이벤트로 실시간 갱신

### 2.2 Tournament History (Action History)

| 필드 | 컨트롤 | 비고 |
|------|--------|------|
| Date/Time | 읽기 전용 | |
| Action Category | Badge | Player / Tournament Info / Clock / Structure / Table & Seat |
| Action Type | 읽기 전용 | Registration, Sit-in, Seat Assigned, Edit Event, Clock Start 등 |
| Staff Name | 읽기 전용 | null 가능 |
| Player Name | 읽기 전용 | null 가능 |
| Detail | 읽기 전용 | 추가 정보 (테이블#, 좌석# 등) |

필터: Action Category Dropdown, Staff Name (text + multi-select), Player Name (text)

### 2.3 Prize Pool Report

| 필드 | 컨트롤 | 비고 |
|------|--------|------|
| Event ID | 읽기 전용 | |
| Event Name | 링크 | 상세 이동 |
| Event Date | 읽기 전용 | 가장 빠른 Flight 시작일 |
| Entries | 읽기 전용 | 전체 Entry 수 |
| Buy-in | 읽기 전용 | |
| Admin Fee | 읽기 전용 | |
| Staff Fee | 읽기 전용 | |
| Total Prize Fund | 읽기 전용 | |

필터: 날짜 범위, Event Type (Bracelet/Side/Satellite)

### 2.4 Unique Player Report

**Daily 뷰:**

| 필드 | 컨트롤 | 비고 |
|------|--------|------|
| Total Unique Players | 상단 카운트 | |
| Player 목록 | 읽기 전용 테이블 | Name, Player ID, Entry Count |

**Tournament 뷰:**

| 필드 | 컨트롤 | 비고 |
|------|--------|------|
| Event Name | 링크 | 이벤트별 Unique Player 페이지 이동 |
| Start Time | 읽기 전용 | |
| Buy-in | 읽기 전용 | |
| Players (Unique) | 읽기 전용 | |
| Entries (Total) | 읽기 전용 | |

이벤트 상세: Flight Dropdown 필터 (All / 개별 Flight)

Export: CSV (전체 리포트), PDF (Prize Pool Report Print 용도)

---

## 3. 데이터 흐름

| 동작 | API | 비고 |
|------|-----|------|
| 핸드 통계 | `GET /reports/hands-summary` | Backend_HTTP §5.15 |
| 플레이어 통계 | `GET /reports/player-stats` | Backend_HTTP §5.15 |
| 테이블 활동 | `GET /reports/table-activity` | Backend_HTTP §5.15 |
| 세션 로그 | `GET /reports/session-log` | Backend_HTTP §5.15 |
| 감사 로그 | `GET /audit-logs` | Backend_HTTP §5.14 |
| Unique Player Report | 미정의 | 미결: CCR 필요 |
| Prize Pool Summary | 미정의 | 미결: CCR 필요 |
| 실시간 Players Count | WebSocket `flight_stats_updated` | API-05 |

---

## 4. RBAC

| 동작 | Admin | Operator | Viewer |
|------|:-----:|:--------:|:------:|
| Players Count 조회 | O | O | O |
| Tournament History 조회 | O | O (본인 Flight) | X |
| Prize Pool Report | O | O | O (읽기) |
| Unique Player Report | O | O | O (읽기) |
| Audit Log 조회 | O | X | X |
| CSV/PDF Export | O | O | X |

---

## 5. WSOP LIVE Parity

| WSOP LIVE 기능 | EBS 적용 | 비고 |
|---------------|:-------:|------|
| Unique Player Report (Daily/Tournament) | Apply | |
| Action History + 필터 강화 | Apply | |
| Financial Tournament Report | Remove | EBS에 Cashier/Settlement 없음 |
| Expected Settlement Report | Remove | EBS에 Payment Gateway 없음 |
| Daily Settlement | Remove | EBS에 Caesars 정산 없음 |
| Registration List (Alpha) | Apply (간소화) | WSOP Payment 컬럼 제외 |
| Tournament Financial Summary by Date | Remove | |
| CSV/PDF Export | Apply | |
| Tableau 연동 | Remove | EBS 규모에 해당 없음 |

---

## 6. 미결 사항

- 미결: CCR 필요 — Unique Player Report API 엔드포인트 (Daily/Tournament)
- 미결: CCR 필요 — Prize Pool Summary Report API 엔드포인트
- 미결: CCR 필요 — Leaderboard (Series/Season 누적 순위) 상세 기획
- 미결: CCR 필요 — PDF Export 서버렌더링 vs 클라이언트렌더링 결정
