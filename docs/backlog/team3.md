# Team 3 — Game Engine 백로그

> 이 파일은 해당 팀이 소유합니다. 다른 팀은 수정 금지 (hook 차단).
> 크로스팀 항목은 `teams` 필드로 표기하고, 기록팀 파일에만 작성합니다.

## PENDING

### ~~[B-310] ReduceResult 아키텍처 전환~~ ✅ DONE (2026-04-13)
- Engine.applyFull() → ReduceResult 반환. apply()는 thin wrapper 유지 (기존 테스트 무변경)

### ~~[B-301] OutputEvent 발행 시스템 구현~~ ✅ DONE (2026-04-13)
- 14 핸들러 모두 ReduceResult 반환 + OutputEvent 발행. 18 테스트 추가. 628 PASS

### [B-302] Under-raise Rule 95 구현
- **날짜**: 2026-04-13
- **teams**: [team3]
- **우선순위**: P1 — WSOP 규정 준수
- **설명**: Raise 금액이 min_raise의 50% 미만이면 Call로 변환, 50% 이상이면 min_raise_total로 보정
- **수락 기준**:
  - betting_rules.dart applyAction Raise case에 검증 로직 추가
  - amount < currentBet + minRaise × 0.5 → Call로 변환
  - amount >= 50% threshold → min_raise_total로 자동 보정
  - TC 3건+ (정상 raise, 50% 미만 → call, 50% 이상 → 보정)
- **관련 문서**: BS-06-02 §5.1, BS-06-09 IT-16, WSOP Rule 95

### [B-303] Short All-in Rule 96 구현
- **날짜**: 2026-04-13
- **teams**: [team3]
- **우선순위**: P1 — WSOP 규정 준수
- **설명**: All-in 금액이 full raise에 미달하면 minRaise/lastAggressor/actedThisRound를 갱신하지 않음 (reopen 불가)
- **수락 기준**:
  - engine.dart AllIn case에서 raise_increment < minRaise 시 분기
  - incomplete all-in: minRaise 불변, actedThisRound reset 미발생, lastAggressor 불변
  - complete all-in: 기존 로직 유지
  - TC 2건+ (incomplete vs complete all-in)
- **관련 문서**: BS-06-02 §6.1, BS-06-09 IT-15, WSOP Rule 96

### [B-304] Missed Blind 처리 구현
- **날짜**: 2026-04-13
- **teams**: [team3]
- **우선순위**: P2 — 캐시 게임 필수
- **설명**: sit-out 후 복귀 시 missed blind 포스팅 의무. Seat에 missed_sb/missed_bb 플래그 추가
- **수락 기준**:
  - Seat에 missedSb/missedBb bool 필드 추가
  - sitOut → sitIn 시 missed blind 금액 자동 포스팅
  - Dead blind (SB) + Live blind (BB) 구분 처리
  - TC 3건 (SB miss, BB miss, 둘 다 miss)
- **관련 문서**: BS-06-03 §의도적 회피 처벌, WSOP Rule 86

### [B-305] Dead Button Rule 구현
- **날짜**: 2026-04-13
- **teams**: [team3]
- **우선순위**: P2
- **설명**: 딜러 포지션 플레이어 탈락 시 버튼 유지 (Dead Button), SB/BB 위치 재조정
- **수락 기준**:
  - Dealer seat이 빈 자리일 때 button 유지
  - SB/BB 위치가 빈 자리를 건너뛰어 올바르게 배정
  - "한 플레이어가 2연속 BB를 내지 않도록" 보장
  - TC 3건 (dealer 탈락, SB 탈락, 연속 탈락)
- **관련 문서**: BS-06-08, BS-06-10 TC-ROTATION-01

### [B-306] Showdown Reveal Order 완성
- **날짜**: 2026-04-13
- **teams**: [team3]
- **우선순위**: P2
- **설명**: 카드 공개 순서(last aggressor first → clockwise), muck 선택 로직, CardRevealConfig 적용
- **수락 기준**:
  - showdown_order.dart에 reveal 순서 리스트 반환 함수
  - lastAggressor 기반 순서 결정
  - All-in 시 자동 공개 (muck 불가)
  - CardRevealConfig의 revealType/showType/foldHideType 적용
  - TC 3건 (일반 showdown, all-in 자동, muck 선택)
- **관련 문서**: BS-06-07 §카드 공개 순서

### [B-307] Coalescence (RFID Burst 처리) 구현
- **날짜**: 2026-04-13
- **teams**: [team3, team4]
- **우선순위**: P3 — Team 4 HAL 의존
- **설명**: RFID 리더의 복수 카드 동시 감지 → coalescence window 내 burst를 단일 이벤트로 병합
- **수락 기준**:
  - CoalescenceWindow 클래스 (configurable duration, 기본 500ms)
  - 윈도우 내 복수 CardDetected → 단일 DealHoleCards 이벤트로 병합
  - 큐 오버플로우 방지 (최대 burst size 제한)
  - TC 3건 (정상 burst, 윈도우 초과, 오버플로우)
- **관련 문서**: BS-06-04

### [B-308] Draw 게임 변종 7종 구현
- **날짜**: 2026-04-13
- **teams**: [team3]
- **우선순위**: P3 — Phase 3 (2027 H1)
- **설명**: Five Card Draw, 2-7 Triple Draw, 2-7 Single Draw, A-5 Triple/Single Draw, Badugi, Badeucy
- **수락 기준**:
  - `lib/core/variants/` 에 각 variant 클래스 추가
  - DrawRound 상태 관리 (교환 횟수, 카드 수 제한)
  - Low 평가 (2-7, A-5, Badugi 4장)
  - 각 variant별 TC 2건+
- **관련 문서**: PRD-GAME-02, BS-06-21~22

### [B-309] Stud 게임 변종 3종 구현
- **날짜**: 2026-04-13
- **teams**: [team3]
- **우선순위**: P3 — Phase 3 (2027 H1)
- **설명**: 7-Card Stud, 7-Card Stud Hi-Lo, Razz. 3rd~7th Street, Bring-in, 공개/비공개 카드
- **수락 기준**:
  - `lib/core/variants/` 에 각 variant 클래스 추가
  - StudStreetMachine (3rd~7th Street 전이, Bring-in)
  - 공개 카드 기반 betting order 재계산
  - 각 variant별 TC 2건+
- **관련 문서**: PRD-GAME-03, BS-06-31~32



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

## IN_PROGRESS

_현재 진행 중인 항목 없음_
