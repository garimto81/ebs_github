---
id: IMPL-006
title: "구현: WebSocket Ack/Reject 6 이벤트 publisher (SG-020)"
type: implementation
status: DONE
owner: team2  # publisher 주체 (team3 협업 불필요 — spec §1.1.1 SSOT 분석 결과 BO publisher 단독)
created: 2026-04-26
resolved: 2026-04-26
spec_ready: true
blocking_spec_gaps:
  - SG-020 (websocket ack/reject 6 D2 — DONE)
implements_chapters:
  - docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md §9-11
related_code:
  - team2-backend/src/websocket/publishers.py  (6 함수 추가, __all__ 26 등재)
  - team2-backend/tests/test_publishers.py     (test_ack_reject_publishers_payload 추가)
---

> ✅ **DONE** — Conductor 직접 구현. websocket scan PASS 복귀 (D2 6→0, D4 38→44). 6/6 pytest PASS.

# IMPL-006 — WebSocket Ack/Reject 6 publisher

## 배경

2026-04-26 fresh scan: websocket 계약 baseline (2026-04-21 PASS 0/0/0/44) → fresh (0/6/0/38) **regression**. 신규 6 이벤트가 기획에만 존재하고 publisher 미동기화. SG-020 default 채택 (publisher 구현 + Engine 트리거 wiring).

## 6 신규 이벤트 매핑

| Event | Publisher 함수 (team2) | 트리거 (team3 Engine 또는 team2) | 호출 시점 |
|-------|-----------------------|----------------------------------|----------|
| `ActionAck` | `publish_action_ack(table_id, action_id, accepted_state)` | Engine | CC ActionRequest 처리 성공 후 |
| `ActionRejected` | `publish_action_rejected(table_id, action_id, reason)` | Engine | CC ActionRequest validation 실패 시 |
| `DealAck` | `publish_deal_ack(table_id, hand_id, dealt_cards)` | Engine | Deal command 처리 성공 후 |
| `DealRejected` | `publish_deal_rejected(table_id, hand_id, reason)` | Engine | Deal validation 실패 시 |
| `GameInfoAck` | `publish_game_info_ack(table_id, config_diff)` | team2 (config 처리) | Set Game Info form submit 성공 |
| `GameInfoRejected` | `publish_game_info_rejected(table_id, reason)` | team2 | validation 실패 |

## 구현 단계

### Phase 1 (team2 — publisher 함수 6개)

`team2-backend/src/websocket/publishers.py` 에 6 함수 추가. 기존 J2 (20 event skeleton) 패턴 준수:
- 동기/비동기 mode 결정 (fan-out broadcaster 활용)
- payload schema (BS_Overview WebSocket 카탈로그 준수)
- 에러 처리 (publisher 실패 시 audit log)

### Phase 2 (team3 — Engine ack 트리거)

team3-engine 의 ActionRequest / Deal command 처리 로직에서:
- 성공 → BO REST 또는 WS callback 으로 ack push
- 실패 → reject 코드 + reason 반환

### Phase 3 (team2 — Game Info)

Game Info form 제출 처리에서 validation 결과 → ack/rejected 발행

## 수락 기준

- [ ] team2: publishers.py 6 함수 추가
- [ ] team3: Engine ActionRequest/Deal 처리 후 ack/reject trigger 발행
- [ ] team2: Game Info config 처리에서 ack/reject 발행
- [ ] team2: pytest 6 시나리오 (각 ack + reject)
- [ ] conductor: scan 재실행 → websocket D2 = 0, D4 = 44
- [ ] conductor: `Spec_Gap_Registry §4.1 websocket` 행 갱신 (PASS 복귀)
- [ ] conductor: SG-020 status DONE 전환

## 구현 메모

- ack/reject 패턴은 신뢰성 핵심 (네트워크 단절 시 retry 정책 결정 의존)
- 타임아웃 정책 미정 시 별도 SG 분리 (예: ack 미수신 시 client retry interval)
- BS_Overview WebSocket 카탈로그에 6 이벤트 누락이면 동시 추가
