---
title: CR-team2-20260413-event-type-catalog
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team2-20260413-event-type-catalog
confluence-page-id: 3819177049
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819177049/EBS+CR-team2-20260413-event-type-catalog
mirror: none
---

# CCR-DRAFT: audit_events.event_type 카탈로그 35값 공식 정의

- **제안팀**: team2
- **제안일**: 2026-04-13
- **영향팀**: [team1, team4]
- **변경 대상 파일**: contracts/data/DATA-04-db-schema.md
- **변경 유형**: add
- **변경 근거**: WSOP LIVE Confluence 실데이터(`Action History` page, EventFlightActionType 70+ enum)와 EBS audit_events.event_type 대조 결과, EBS가 7개 예시만 정의하여 운영 추적 세분화 부족. WSOP 운영 범위 중 EBS에 해당하는 35값을 공식 카탈로그로 확정.

## 변경 요약

DATA-04 §5.2 `audit_events` 테이블의 `event_type` 컬럼에 허용값 카탈로그 섹션 추가.

## Diff 초안

```diff
 ### 5.2 `audit_events`
 
+#### event_type 카탈로그
+
+| 카테고리 | event_type | 설명 | WSOP 대응 |
+|---------|-----------|------|----------|
+| **Hand** | `hand_started` | 핸드 시작 | — |
+| | `hand_ended` | 핸드 종료 | — |
+| | `action_performed` | 플레이어 액션 (fold/call/raise) | — |
+| | `card_detected` | RFID 카드 감지 | — |
+| | `betting_round_complete` | 베팅 라운드 완료 | — |
+| | `all_folded` | 전원 폴드 | — |
+| | `all_in_runout` | 올인 런아웃 | — |
+| **Seat** | `seat_assigned` | 좌석 배정 | SeatAssigned(21) |
+| | `seat_vacated` | 좌석 비움 | — |
+| | `seat_moved` | 좌석 이동 | MovePlayer(22) |
+| | `seat_reserved` | 좌석 예약 | ReserveSeats(41) |
+| | `seat_released` | 좌석 예약 해제 | ReleaseSeats(42) |
+| | `player_eliminated_request` | 탈락 요청 | RequestEliminate(111) |
+| | `player_eliminated_confirm` | 탈락 확정 | Eliminate(113) |
+| | `chips_updated` | 칩 카운트 갱신 | UpdateChips(121) |
+| **Table** | `table_created` | 테이블 생성 | AddTables(3) |
+| | `table_setup` | 테이블 설정 완료 | — |
+| | `table_live` | 테이블 라이브 전환 | — |
+| | `table_paused` | 테이블 일시정지 | PauseTables(44) |
+| | `table_resumed` | 테이블 재개 | ResumeTables(45) |
+| | `table_closed` | 테이블 종료 | BreakTable(33) |
+| **Device** | `rfid_status_changed` | RFID 리더 상태 변경 | — |
+| | `output_status_changed` | 출력(NDI/HDMI) 상태 변경 | — |
+| | `game_changed` | 게임 타입 변경 | — |
+| | `config_changed` | 글로벌 설정 변경 | — |
+| | `blind_structure_changed` | 블라인드 구조 변경 | ChangeBlinds(401) |
+| **Ops** | `operator_connected` | CC 운영자 연결 | — |
+| | `operator_disconnected` | CC 운영자 해제 | — |
+| | `deck_registered` | 덱 등록 완료 | — |
+| | `player_updated` | 플레이어 정보 갱신 | — |
+| | `table_assigned` | CC에 테이블 할당 | — |
+| **Special** | `bomb_pot_set` | Bomb Pot 설정 | — |
+| | `run_it_times_set` | Run It Times 설정 | — |
+| | `chop_confirmed` | Chop 합의 | — |
+| **Overlay** | `skin_updated` | 스킨/오버레이 변경 | — |
+
+> 카탈로그는 **확장 가능**. 신규 event_type 추가 시 본 표에 행 추가 (삭제/이름변경 금지). WSOP 대응 열은 참조용이며 EBS 구현에 구속력 없음.
```

## 영향 분석

- Team 1 (Lobby): 이벤트 필터링 UI에서 카탈로그 참조. 하위 호환 (신규 추가만).
- Team 4 (CC): 이벤트 로깅 시 event_type 문자열 사용. 기존 7개 유지.
- 마이그레이션: 없음 (TEXT 컬럼, CHECK 제약은 Phase 3+에서 추가).

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 1 기술 검토
- [ ] Team 4 기술 검토
