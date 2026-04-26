---
id: SG-020
title: "WebSocket Ack/Reject 6 이벤트 신규 D2 (publisher 미동기화)"
type: spec_gap
sub_type: spec_drift
drift_type: D2
status: DONE
owner: team2  # publisher = team2 (websocket/publishers.py)
created: 2026-04-26
resolved: 2026-04-26
affects_chapter:
  - docs/2. Development/2.5 Shared/BS_Overview.md (WebSocket 이벤트 카탈로그)
  - team2-backend/src/websocket/publishers.py
protocol: Spec_Gap_Triage §7 Type D2
related:
  - logs/drift_report_2026-04-26.json
  - docs/4. Operations/Reports/2026-04-26-Spec_Gap_Audit_Phase1.md §1.2
  - J2 (publisher 20 event skeleton) 후속
---

# SG-020 — WebSocket Ack/Reject 6 이벤트 신규 D2

## 공백 서술

2026-04-26 fresh scan 에서 WebSocket 계약이 baseline (2026-04-21 PASS 0/0/0/44) → fresh (0/6/0/38) **regression** 발견.

기획에만 존재하고 publisher 코드에 없음:

| Identifier | 추정 발행자 | 추정 트리거 |
|------------|-------------|-------------|
| `ActionAck` / `ActionRejected` | team3 (Engine) → team1/4 | CC ActionRequest 처리 결과 |
| `DealAck` / `DealRejected` | team3 (Engine) → team1/4 | Deal command 처리 결과 |
| `GameInfoAck` / `GameInfoRejected` | team2 (Backend) → team4 | Set Game Info 제출 결과 |

## 발견 경위

- 2026-04-26 `tools/spec_drift_check.py --websocket` D2 +6
- baseline (2026-04-21 Multi_Session_Handoff §2) 에서는 D4=44 PASS 였음
- 2026-04-21~26 사이 commit 들에서 기획 카탈로그만 추가, publisher 미동기화

**handoff drop 신호** — J2 (`src/websocket/publishers.py` 20 event skeleton) 작업 후 ack/reject 카탈로그가 추가되었으나 publisher 가 동시 동기화되지 않음.

## 영향받는 챕터 / 구현

- `BS_Overview.md` 또는 `2.5 Shared/WebSocket_Events.md` (있다면): 6 신규 이벤트 카탈로그 행
- `team2-backend/src/websocket/publishers.py`: 6 publisher 함수 미구현
- `team3-engine/`: ActionAck/Rejected, DealAck/Rejected 발행 트리거 (Engine 결과 → BO push)

## 결정 방안 후보 (Triage §7.2 기준)

기획 진실 default 적용 (2026-04-20 §7.2.1 — 본 프로젝트 불안정 상태):

| 대안 | 장점 | 단점 |
|------|------|------|
| 1. publisher 6 함수 구현 + 트리거 wiring (default — D2 → D4 PASS) | 기획 완결 + 작업 단절 해소 | team2 + team3 협업 필요 |
| 2. 기획에서 6 이벤트 제거 (롤백) | 구현 비용 ↓ | 설계 의도 미확인 + ack/reject 누락 시 재시도 정책 불명 |

## 결정 (decision_owner team2 판정 시 기입)

- **default 권고**: 대안 1 (publisher 구현)
- 이유: ack/reject 패턴은 신뢰성 핵심 (네트워크 단절 시 retry 결정 의존). 기획 진실 default + 작업 단절 해소.
- decision_owner: team2 (publisher)

## 후속 작업 (IMPL-006 으로 등재 예정)

- [ ] team2: `publishers.py` 에 6 함수 추가 (publish_action_ack / publish_action_rejected / publish_deal_ack / publish_deal_rejected / publish_game_info_ack / publish_game_info_rejected)
- [ ] team3: Engine 처리 결과 → BO push 트리거 (ActionAck / DealAck)
- [ ] team2: Game Info form 제출 → ack/rejected 트리거
- [ ] team2: pytest 6 시나리오 (success + validation_failure)
- [ ] conductor: scan 재실행 후 drift PASS 확인 → SG-020 DONE 전환

## 검증

```bash
python tools/spec_drift_check.py --websocket
# 기대: 0/0/0/44 (D2=0 / D4=44)
```
