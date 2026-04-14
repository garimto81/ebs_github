# Team 3 — Game Engine 백로그

> 이 파일은 해당 팀이 소유합니다. 다른 팀은 수정 금지 (hook 차단).
> 크로스팀 항목은 `teams` 필드로 표기하고, 기록팀 파일에만 작성합니다.

## PENDING

### ~~[B-310] ReduceResult 아키텍처 전환~~ ✅ DONE (2026-04-13)
- Engine.applyFull() → ReduceResult 반환. apply()는 thin wrapper 유지 (기존 테스트 무변경)

### ~~[B-301] OutputEvent 발행 시스템 구현~~ ✅ DONE (2026-04-13)
- 14 핸들러 모두 ReduceResult 반환 + OutputEvent 발행. 18 테스트 추가. 628 PASS

### ~~[B-302] Under-raise Rule 95 구현~~ ✅ DONE (2026-04-13)
- Raise <50% → Call 변환, ≥50% → minRaiseTotal 보정. TC 3건.

### ~~[B-303] Short All-in Rule 96 구현~~ ✅ DONE (2026-04-13)
- Incomplete all-in → minRaise/lastAggressor/actedThisRound 불변. TC 3건.

### ~~[B-304] Missed Blind 처리 구현~~ ✅ DONE (2026-04-13)
- Seat에 missedSb/missedBb 필드 추가. 핸드 시작 시 감지 + 복귀 시 dead/live blind 포스팅. TC 5건.

### ~~[B-305] Dead Button Rule 구현~~ ✅ DONE (2026-04-13)
- 기존 activeSeatIndices 로직이 이미 sittingOut skip 처리. 추가 코드 변경 불필요. TC 4건으로 검증.

### ~~[B-306] Showdown Reveal Order 완성~~ ✅ DONE (2026-04-13)
- ShowdownSeatInfo + canMuck() + getShowdownInfo() 추가. All-in 자동 공개, 패자 muck 허용. TC 8건.
  - TC 3건 (일반 showdown, all-in 자동, muck 선택)
- **관련 문서**: BS-06-07 §카드 공개 순서

### ~~[B-307] Coalescence (RFID Burst 처리) 구현~~ ✅ DONE (2026-04-13)
- CoalescenceWindow (Hold'em 100ms / Draw 200ms / Stud 3rd 18장), DrawCoalescenceValidator, 오버플로우 자동 분할. TC 12건.

### ~~[B-308] Draw 게임 변종 7종 구현~~ ✅ DONE (2026-04-13)
- Five Card Draw, 2-7 Single/Triple Draw, A-5 Triple Draw, Badugi, Badeucy, Badacey. Lowball 2-7/A-5 + BadugiEvaluator + DrawVariant 추상 클래스 + Deck.reshuffle(). TC 33건.

### ~~[B-309] Stud 게임 변종 3종 구현~~ ✅ DONE (2026-04-13)
- 7-Card Stud, 7-Card Stud Hi-Lo, Razz. StudVariant 추상 클래스 + BringIn 유틸 + bestLow8() evaluator. TC 26건.



### [NOTIFY-LEGACY-CCR-023] [LEGACY] 검토 요청: BS-07 Overlay 오디오 레이어 추가 (WSOP 1 BGM + 2 Effect 채널)
> ⚠ **LEGACY NOTIFY** — 2026-04-10 CCR 일괄 적용 이전 세션 항목. 현재 CCR 번호 체계와 불일치. 현재 유효 CCR: `docs/05-plans/ccr-inbox/promoting/CCR-*.md`.

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/CCR-023-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-07-overlay/BS-07-05-audio.md, contracts/specs/BS-07-overlay/BS-07-02-animations.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-016] 검토 요청: Tech Stack SSOT를 BS-00에 명시하고 team2 IMPL 시리즈 동기화

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-016-*.md`
- **제안팀**: team1
- **변경 대상**: `contracts/specs/BS-00-definitions.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-024] 검토 요청: API-05 WriteGameInfo 프로토콜 22+ 필드 스키마 완전 명세

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-024-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/api/API-05-websocket-events.md, contracts/specs/BS-05-command-center/BS-05-02-action-buttons.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-033] 검토 요청: BS-07 Overlay 오디오 레이어 추가 (WSOP 1 BGM + 2 Effect 채널)

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-033-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-07-overlay/BS-07-05-audio.md, contracts/specs/BS-07-overlay/BS-07-02-animations.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-035] 검토 요청: BS-07 Overlay Layer 1/2/3 경계 및 자동화 범위 명시

- **알림일**: 2026-04-10
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-035-*.md`
- **제안팀**: team4
- **변경 대상**: `contracts/specs/BS-07-overlay/BS-07-06-layer-boundary.md, contracts/specs/BS-07-overlay/BS-07-00-overview.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-042] 검토 요청: API-05에 EventFlightSummary 이벤트 + Clock FSM 행동 명세 신설
- **알림일**: 2026-04-13
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-042-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/api/API-05-websocket-events.md, contracts/specs/`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-049] 검토 요청: BlindStructure 관리 엔드포인트 추가 (WSOP LIVE 정렬)
- **알림일**: 2026-04-14
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-049-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/api/API-01-backend-api.md, contracts/data/DATA-02-entities.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기


### [NOTIFY-CCR-054] 검토 요청: WebSocket 이벤트 카탈로그 WSOP LIVE SignalR 정렬
- **알림일**: 2026-04-14
- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-054-*.md`
- **제안팀**: team2
- **변경 대상**: `contracts/api/API-05-websocket-events.md`
- **조치**: 영향 범위 검토 후 승인 또는 이의 제기

## IN_PROGRESS

_현재 진행 중인 항목 없음_
