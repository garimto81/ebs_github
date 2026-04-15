---
title: CR-team2-20260413-seat-waiting-enum
owner: conductor
tier: internal
last-updated: 2026-04-15
---

# CCR-DRAFT: DATA-04에 Seat Status enum 정의 + waiting_list 테이블 신설

- **제안팀**: team2
- **제안일**: 2026-04-13
- **영향팀**: [team1, team4]
- **변경 대상 파일**: contracts/data/DATA-04-db-schema.md
- **변경 유형**: add + modify
- **변경 근거**: WSOP LIVE `Table Dealer Page` 및 `Staff App Live` Confluence 문서에서 좌석 상태(E/B/M/N/O)와 대기자 상태(Waiting/Front/Calling/Ready/Seated/Canceled)가 명시적 enum으로 운영됨. EBS DATA-04의 `table_seats.status`는 VARCHAR로 허용값 미정의, `waiting_list` 테이블 자체가 부재.

## 변경 요약

1. `table_seats.status` 에 허용값 CHECK 제약 추가 (6값)
2. `waiting_list` 테이블 신설 (7값 status enum)

## Diff 초안

```diff
 ### table_seats
 
-    status: str = Field(default="vacant")     # SeatFSM
+    status: str = Field(default="empty")      # SeatStatus enum (아래 참조)
+
+    # SeatStatus 허용값 (WSOP LIVE E/N/P/M/B/R 대응)
+    # CHECK(status IN ('empty','new','playing','moved','busted','reserved'))
+    __table_args__ = (
+        CheckConstraint("status IN ('empty','new','playing','moved','busted','reserved')", name="ck_seat_status"),
+    )

+### waiting_list (신규)
+
+대기열 관리. WSOP LIVE `Waiting API` 및 `Staff App Live §WaitingPlayerList` 대응.
+
+| 컬럼 | 타입 | 제약 | 설명 |
+|------|------|------|------|
+| `id` | INTEGER | PK AUTOINCREMENT | 대기열 항목 ID |
+| `event_flight_id` | INTEGER | NOT NULL, FK→event_flights | Flight |
+| `player_id` | INTEGER | NOT NULL, FK→players | 플레이어 |
+| `status` | VARCHAR(16) | NOT NULL DEFAULT 'waiting' | PlayerWaitingStatus |
+| `position` | INTEGER | NOT NULL | 대기 순번 (1부터) |
+| `priority` | BOOLEAN | NOT NULL DEFAULT false | 우선 배치 여부 |
+| `called_at` | TIMESTAMP | NULL | 호출 시각 |
+| `seated_at` | TIMESTAMP | NULL | 좌석 배정 시각 |
+| `canceled_at` | TIMESTAMP | NULL | 취소/만료 시각 |
+| `created_at` | TIMESTAMP | NOT NULL DEFAULT now() | 등록 시각 |
+
+CHECK(status IN ('waiting','front','calling','ready','seated','canceled','expired'))
+
+인덱스:
+- `(event_flight_id, position)` — 대기 순서 조회
+- `(event_flight_id, status)` — 상태별 필터
+- `(player_id)` — 플레이어별 대기 이력
```

## 영향 분석

- Team 1 (Lobby): Waiting List 화면 구현 시 PlayerWaitingStatus enum 참조.
- Team 4 (CC): 좌석 상태 6값으로 SeatGrid 위젯 색상/아이콘 매핑.
- 마이그레이션: Phase 1 SQLite ALTER TABLE 필요 (status 기본값 'vacant' → 'empty' 변경).

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 1 기술 검토 (Waiting List)
- [ ] Team 4 기술 검토 (SeatGrid)
