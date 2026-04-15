# CCR-DRAFT: Competition 계층 WSOP LIVE 정렬 (Series→Event→EventFlight)

- **제안팀**: team2
- **제안일**: 2026-04-14
- **영향팀**: [team1, team4]
- **변경 대상 파일**: contracts/data/DATA-02-entities.md, contracts/data/DATA-04-db-schema.md, contracts/api/API-01-backend-api.md
- **변경 유형**: add
- **변경 근거**: WSOP LIVE Staff App 계층(Series→Event→EventFlight, Page 1599537917)에서 Competition은 Series 상위 실체가 아니라 Series 분류 태그(`CompetitionType` enum, Page 1960411325). EBS 현행 `competitions` 테이블 + §5.3 Competitions CRUD 5종은 불필요한 중간 계층. WSOP LIVE 패턴에 정렬 필요. 단, 기존 competitions 테이블은 Phase 1 호환용으로 deprecated 표기 유지, 신규 API 접근은 차단.

## 변경 요약

1. `contracts/data/DATA-02 §Series` 에 필드 2개 추가: `competition_type: enum(5)`, `competition_tag: enum(4)`
2. `contracts/data/DATA-02 §EventFlight` 에 `status: enum(6)` 명시 (Created/Announce/Registering/Running/Completed/Canceled)
3. `contracts/data/DATA-04 series` 테이블에 컬럼 2개 추가, `event_flights.status` 컬럼 enum 명시
4. `contracts/api/API-01 §5.3 Competitions` 를 deprecated 표기 (Phase 2 제거 예정). §5.4 Series POST/PUT 요청에 `competition_type`, `competition_tag` 필드 추가

## Diff 초안

### contracts/data/DATA-02-entities.md §Series

```diff
 | Field | Type | Description |
 |---|---|---|
 | series_id | int | PK |
 | competition_id | int | FK → competitions (Phase 1 호환, Phase 2 제거 예정) |
 | name | string | |
+| competition_type | enum | WSOP LIVE CompetitionType: `WSOP(0) \| WSOPC(1) \| APL(2) \| APT(3) \| WSOPP(4)` |
+| competition_tag | enum | WSOP LIVE CompetitionTag: `None(0) \| Bracelets(1) \| Circuit(2) \| SuperCircuit(3)` |
 | start_date | date | |
 | end_date | date | |
```

### contracts/data/DATA-02-entities.md §EventFlight

```diff
 | Field | Type | Description |
 |---|---|---|
 | event_flight_id | int | PK |
 | event_id | int | FK → events |
 | flight_label | string | e.g. "Day 1A" |
+| status | enum | WSOP LIVE EventFlightStatus: `Created(0) \| Announce(1) \| Registering(2) \| Running(4) \| Completed(5) \| Canceled(6)`. 기본값 `Created`. 3번(Unused)은 WSOP LIVE에서 미사용. |
 | start_time | timestamp | |
```

### contracts/data/DATA-04-db-schema.md

```diff
 CREATE TABLE series (
   series_id INTEGER PRIMARY KEY AUTOINCREMENT,
   competition_id INTEGER REFERENCES competitions(competition_id),
   name TEXT NOT NULL,
+  competition_type INTEGER NOT NULL DEFAULT 0 CHECK(competition_type BETWEEN 0 AND 4),
+  competition_tag INTEGER NOT NULL DEFAULT 0 CHECK(competition_tag BETWEEN 0 AND 3),
   start_date DATE,
   end_date DATE
 );
+CREATE INDEX idx_series_competition ON series(competition_type, competition_tag);

 CREATE TABLE event_flights (
   event_flight_id INTEGER PRIMARY KEY AUTOINCREMENT,
   event_id INTEGER NOT NULL REFERENCES events(event_id),
   flight_label TEXT,
+  status INTEGER NOT NULL DEFAULT 0 CHECK(status IN (0,1,2,4,5,6)),
   start_time TIMESTAMP
 );
+CREATE INDEX idx_event_flights_status ON event_flights(status);
```

### contracts/api/API-01-backend-api.md §5.3 Competitions (deprecated 표기)

```diff
 ### 5.3 Competitions — 대회 브랜드
+
+> **DEPRECATED (Phase 2 제거 예정)**: WSOP LIVE Staff App은 Competition을 Series의 `competition_type` enum 필드로 관리. 이 섹션은 Phase 1 호환용. 신규 구현은 §5.4 Series의 `competition_type`/`competition_tag` 필드 사용.

 | Method | Path | 설명 | 역할 제한 |
```

### contracts/api/API-01-backend-api.md §5.4 Series (POST/PUT 확장)

```diff
 **POST /series — Request:**

 ```json
 {
   "competition_id": 1,
   "name": "2026 WSOP Main Event",
+  "competition_type": 0,
+  "competition_tag": 1,
   "start_date": "2026-07-01",
   "end_date": "2026-07-15"
 }
 ```
+> `competition_type`: WSOP(0)/WSOPC(1)/APL(2)/APT(3)/WSOPP(4). `competition_tag`: None(0)/Bracelets(1)/Circuit(2)/SuperCircuit(3). 필터: `GET /series?competition_type=0&competition_tag=1`.
```

## Divergence from WSOP LIVE (Why)

1. **`competitions` 테이블 즉시 제거 안 함**: WSOP LIVE는 별도 테이블 없음.
   - **Why**: 기존 competitions 행/FK 참조 존재 추정. Phase 1에서 deprecated 표기, Phase 2에서 migration + drop. 급격한 breaking 회피.
2. **EventFlightStatus 값 `3`(Unused) 제외**: WSOP LIVE enum에 3이 정의 안 됨.
   - **Why**: 소스 그대로. 향후 추가 시 CCR.

## 영향 분석

- **Team 1**: Series 관리 UI에 competition_type/tag 드롭다운 추가 (2시간). EventFlight 상태 배지(6색) (2시간).
- **Team 4**: EventFlight 상태가 Canceled 되면 CC 세션 종료 처리 — S0-01 CCR과 통합.
- **Team 2**: Alembic revision. 기존 competitions 행이 있다면 Series.competition_type 역매핑 스크립트.
- **마이그레이션**: 기본값 존재로 서비스 중단 없음. 기존 Series 행은 competition_type=0, tag=0 (WSOP/None).

## 대안 검토

1. **competitions 테이블 즉시 삭제(drop)**: 탈락. Phase 1 데이터 손실 위험.
2. **`competition_type`을 문자열로**: 탈락. enum 정합성/필터 성능 저하.

## 검증

- WSOP LIVE Staff App Series 응답 JSON 과 EBS `/series/:id` 응답 필드 1:1 매핑 확인
- EventFlightStatus 6-state FSM 단위 테스트

## 승인 요청

- [ ] Team 1 검토
- [ ] Team 4 검토 (Canceled 전이)
- [ ] 리스크 판정: `python tools/ccr_validate_risk.py --draft <file>`

## 참고 출처

| Page ID | 제목 |
|---|---|
| 1599537917 | Staff App API / Tournament (Series/Event/EventFlight 계층) |
| 1960411325 | Enum (CompetitionType, CompetitionTag, EventFlightStatus) |
