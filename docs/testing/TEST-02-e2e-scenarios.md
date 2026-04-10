# TEST-02: E2E 시나리오

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 방송 하루 순서 기반 10개 E2E 시나리오 |

---

## 개요

EBS 방송 하루의 전체 워크플로우를 10개 E2E 시나리오로 정의한다. 각 시나리오는 실제 운영 순서를 따르며, 모든 RFID 동작은 `MockRfidReader`로 수행한다.

> 참조: HandFSM — BS-06-01, 트리거 경계 — BS-06-00, Mock HAL — API-03 §6

---

## 시나리오 흐름 개요

```
S-01 로그인
  → S-02 대회 생성
    → S-03 테이블+플레이어
      → S-04 Settings
        → S-05 CC Launch+덱등록
          → S-06 핸드 1판
            → S-07 All-In+Side Pot
              → S-08 Undo+Miss Deal
                → S-09 Mix 게임 전환
                  → S-10 핸드 종료+통계
```

---

## S-01: Admin 로그인 → Lobby 진입

### 전제조건
- BO 서버 실행 중
- Lobby 웹 앱 접근 가능
- Admin 계정 존재 (`admin@ebs.local` / password)

### 단계

| # | 행위자 | 액션 | 기대 결과 |
|:-:|--------|------|----------|
| 1 | Admin | Lobby URL 접속 | 로그인 화면 표시 |
| 2 | Admin | Admin 계정으로 로그인 | JWT 토큰 발급, Lobby 메인 화면 진입 |
| 3 | 시스템 | RBAC 권한 확인 | Admin 역할 — 모든 메뉴 접근 가능 |
| 4 | Admin | 대시보드 확인 | 테이블 목록 (비어있음), 시스템 상태 표시 |

### 검증 포인트
- JWT 토큰이 응답 헤더/쿠키에 포함됨
- Admin 역할에서 Settings, Table 생성, CC Launch 메뉴 모두 활성
- Operator 계정 로그인 시 할당된 테이블만 표시 (음성 테스트)

---

## S-02: Series/Event/Flight 생성 (수동)

### 전제조건
- S-01 완료 (Admin 로그인 상태)

### 단계

| # | 행위자 | 액션 | 기대 결과 |
|:-:|--------|------|----------|
| 1 | Admin | Series 생성 ("2026 WSOP") | Series 목록에 표시 |
| 2 | Admin | Event 생성 ("Event #1: $10K NL Hold'em") | Event 목록에 표시, Series에 연결 |
| 3 | Admin | Flight 생성 ("Day 1A") | Flight 목록에 표시, Event에 연결 |
| 4 | 시스템 | BO DB 저장 확인 | Competition → Series → Event → Flight 계층 구조 정합 |

### 검증 포인트
- 계층 관계: Competition → Series → Event → Flight 정상 연결
- 필수 필드 누락 시 유효성 검증 에러 표시
- 중복 이름 허용 (같은 Event 내 Flight 이름은 고유)

---

## S-03: Table 생성 + Player 등록 + 좌석 배치

### 전제조건
- S-02 완료 (Flight 존재)

### 단계

| # | 행위자 | 액션 | 기대 결과 |
|:-:|--------|------|----------|
| 1 | Admin | Table 생성 ("Table 1 — Feature Table") | Table 상태 = EMPTY |
| 2 | Admin | Flight에 Table 할당 | Table이 Flight 하위에 표시 |
| 3 | Admin | Player 6명 등록 (이름, 국적, 프로필) | Player DB에 6명 저장 |
| 4 | Admin | 6명 좌석 배치 (Seat 0, 1, 3, 5, 7, 9) | Seat 상태: 6개 OCCUPIED, 4개 VACANT |
| 5 | 시스템 | Table 상태 전이 확인 | Table 상태 = SETUP |

### 검증 포인트
- Seat 번호 범위: 0~9 (10석)
- 동일 좌석에 2명 배치 시도 → 에러
- Player 이동(SeatMove): Seat 3 → Seat 4 정상 작동
- Table 상태가 EMPTY → SETUP으로 전이

---

## S-04: Settings 설정 (Output/Overlay/Game/Statistics)

### 전제조건
- S-03 완료 (Table + Player 설정 완료)

### 단계

| # | 행위자 | 액션 | 기대 결과 |
|:-:|--------|------|----------|
| 1 | Admin | Output 설정 — NDI 출력, 1080p, Security Delay 10초 | OutputPreset 저장 |
| 2 | Admin | Overlay 설정 — Skin 선택, 카드 스타일 | Skin 적용 확인 |
| 3 | Admin | Game 설정 — NL Hold'em, BB=100, SB=50, Ante=0 | BlindStructure 저장 |
| 4 | Admin | Statistics 설정 — VPIP/PfR/WTSD 표시 ON | 통계 표시 옵션 저장 |
| 5 | 시스템 | BO DB 확인 | 4개 Settings 영역 모두 저장됨 |

### 검증 포인트
- Settings 변경 시 `ConfigChanged` WebSocket 이벤트 발행 확인
- 잘못된 값 (BB < SB, 해상도 0×0) 입력 시 유효성 에러
- Settings 프리셋 저장/로드 작동

---

## S-05: CC Launch → 덱 등록 (Mock 자동)

### 전제조건
- S-04 완료 (Settings 설정 완료)
- RFID 모드 = Mock

### 단계

| # | 행위자 | 액션 | 기대 결과 |
|:-:|--------|------|----------|
| 1 | Admin | CC Launch 버튼 클릭 | CC 앱 실행, BO WebSocket 연결 |
| 2 | 시스템 | WebSocket 연결 확인 | `OperatorConnected` 이벤트, Lobby 모니터링 갱신 |
| 3 | 시스템 | MockRfidReader 초기화 | status = ready, AntennaStatusChanged(connected) |
| 4 | 운영자 | "자동 등록" 버튼 클릭 | `autoRegisterDeck()` 호출 |
| 5 | 시스템 | Mock 덱 등록 완료 | DeckRegistered 이벤트, 52장 매핑, Deck 상태 = REGISTERED |
| 6 | 시스템 | Table 상태 전이 | Table 상태 = LIVE |

### 검증 포인트
- Mock 모드: 덱 등록 즉시 완료 (0ms)
- 52장 cardMap 정합: suit 0~3 × rank 0~12 = 52장
- CC UI에 Deck 상태 "REGISTERED" 표시
- Lobby 모니터링에 Table 상태 "LIVE" 반영

---

## S-06: Hold'em 핸드 1판 전체 진행 (Pre-Flop → Showdown)

### 전제조건
- S-05 완료 (CC LIVE, 덱 등록, 6명 착석)
- 게임: NL Hold'em, BB=100, SB=50

### 단계

| # | 행위자 | 액션 | 기대 결과 |
|:-:|--------|------|----------|
| 1 | 운영자 | NEW HAND 버튼 | HandFSM: IDLE → SETUP_HAND, BlindsPosted |
| 2 | 시스템 | SB/BB 자동 수집 | SB(50) + BB(100) 팟 추가, 스택 차감 |
| 3 | 운영자 | Mock 홀카드 입력 (6명 × 2장 = 12장) | CardDetected × 12, HandFSM → PRE_FLOP |
| 4 | 운영자 | UTG Fold | player.status = folded, action_on 이동 |
| 5 | 운영자 | MP Call(100) | biggest_bet_amt 유지, 스택 차감 |
| 6 | 운영자 | CO Raise(300) | biggest_bet_amt = 300, min_raise_amt 갱신 |
| 7 | 운영자 | BTN Fold, SB Fold, BB Call(300) | 3명 폴드, BB 콜 |
| 8 | 운영자 | MP Call(300) | PRE_FLOP 베팅 완료 |
| 9 | 시스템 | BettingRoundComplete | HandFSM → FLOP 대기 |
| 10 | 운영자 | Mock 보드 카드 3장 입력 | CardDetected × 3, board_cards = 3, HandFSM → FLOP |
| 11 | 운영자 | BB Check, MP Bet(400), CO Raise(1000), BB Fold, MP Call(1000) | FLOP 베팅 완료 |
| 12 | 운영자 | Mock Turn 카드 1장 입력 | board_cards = 4, HandFSM → TURN |
| 13 | 운영자 | MP Check, CO Bet(2000), MP Call(2000) | TURN 베팅 완료 |
| 14 | 운영자 | Mock River 카드 1장 입력 | board_cards = 5, HandFSM → RIVER |
| 15 | 운영자 | MP Check, CO Check | RIVER 베팅 완료, final_betting_round = true |
| 16 | 시스템 | ShowdownStarted → WinnerDetermined | 핸드 평가, 우승자 결정 |
| 17 | 시스템 | HandCompleted | 팟 분배, 통계 업데이트, HandFSM → HAND_COMPLETE |

### 검증 포인트
- 각 상태 전이마다 HandFSM game_phase 값 정확
- 팟 금액 누적 정합: SB(50) + BB(100) + 베팅 합계
- Overlay에 보드 카드, 플레이어 카드, 팟 금액 표시
- Hand History에 모든 액션 기록됨

---

## S-07: 특수 상황 — All-In → Side Pot → Showdown

### 전제조건
- S-06 완료 후 다음 핸드 시작
- 3명 남음: P1(stack=1000), P2(stack=3000), P3(stack=5000)

### 단계

| # | 행위자 | 액션 | 기대 결과 |
|:-:|--------|------|----------|
| 1 | 운영자 | NEW HAND, 홀카드 딜 | SETUP_HAND → PRE_FLOP |
| 2 | 운영자 | P1 All-In(1000) | SidePotCreated, P1.status = allin |
| 3 | 운영자 | P2 All-In(3000) | 두 번째 SidePotCreated, P2.status = allin |
| 4 | 운영자 | P3 Call(3000) | PRE_FLOP 완료 |
| 5 | 시스템 | AllInRunout | 남은 보드 자동 공개 필요 |
| 6 | 운영자 | Mock 보드 5장 순차 입력 | board_cards = 5, SHOWDOWN 진입 |
| 7 | 시스템 | WinnerDetermined | 팟별 승자 결정 |
| 8 | 시스템 | HandCompleted | 팟 분배 완료 |

### 검증 포인트
- **Main Pot**: 1000 × 3 = 3000 (P1, P2, P3 참여)
- **Side Pot 1**: (3000 - 1000) × 2 = 4000 (P2, P3 참여)
- **Side Pot 2**: 5000 - 3000 = 2000 (P3만, 반환)
- 각 Pot별 독립 승자 결정
- P1 승리 시 Main Pot만 수령, Side Pot은 P2/P3 중 승자

---

## S-08: Undo 5단계 + Miss Deal 복구

### 전제조건
- 핸드 진행 중 (PRE_FLOP 이후)

### 단계

| # | 행위자 | 액션 | 기대 결과 |
|:-:|--------|------|----------|
| 1 | 운영자 | P1 Bet(200) | 정상 처리 |
| 2 | 운영자 | P2 Raise(500) | 정상 처리 |
| 3 | 운영자 | P3 Call(500) | 정상 처리 |
| 4 | 운영자 | UNDO 1회 | P3 Call 되돌림, action_on = P3 |
| 5 | 운영자 | UNDO 2회 | P2 Raise 되돌림, action_on = P2 |
| 6 | 운영자 | UNDO 3회 | P1 Bet 되돌림, action_on = P1 |
| 7 | 운영자 | P1 Bet(300) — 다른 금액으로 재입력 | 정상 처리 |
| 8 | 운영자 | Miss Deal 선언 | HandFSM → IDLE, 스택 복구 |
| 9 | 시스템 | 팟 복원 확인 | 모든 플레이어 스택 = 핸드 시작 시점 |

### 검증 포인트
- UNDO 최대 5단계 제한 — 6번째 UNDO 시도 시 거부
- UNDO 후 action_on 정확히 복원
- UNDO 후 biggest_bet_amt 정확히 복원
- Miss Deal 후 IDLE 상태, 모든 칩 원복

---

## S-09: Mix 게임 전환 (종목 변경)

### 전제조건
- Event 설정: Mix 게임 (HORSE — Hold'em, Omaha, Razz, Stud, Eight-or-Better)
- 현재 Hold'em 핸드 완료 상태

### 단계

| # | 행위자 | 액션 | 기대 결과 |
|:-:|--------|------|----------|
| 1 | 시스템 | 8핸드 완료 감지 | 게임 종목 전환 알림 |
| 2 | 운영자 | 다음 종목 확인 (Omaha) | CC UI에 "Omaha Hi-Lo" 표시 |
| 3 | 시스템 | `GameChanged` 이벤트 | BO → Lobby 모니터링 갱신 |
| 4 | 운영자 | Omaha 핸드 시작 | 홀카드 4장 (Hold'em은 2장), 게임 규칙 변경 적용 |

### 검증 포인트
- 종목 전환 시 블라인드 구조 자동 변경 (FL → NL 등)
- Overlay 게임명 표시 갱신
- Lobby 모니터링 종목 표시 갱신
- 이전 종목 통계와 현재 종목 통계 분리 기록

---

## S-10: 핸드 종료 → Hand History 확인 → 통계 검증

### 전제조건
- S-06~S-09 시나리오 실행 완료 (복수 핸드 진행됨)

### 단계

| # | 행위자 | 액션 | 기대 결과 |
|:-:|--------|------|----------|
| 1 | 운영자 | 마지막 핸드 HAND_COMPLETE 확인 | HandFSM 상태 정확 |
| 2 | Admin | Lobby에서 Hand History 조회 | 진행된 모든 핸드 목록 표시 |
| 3 | Admin | 특정 핸드 상세 보기 | 모든 액션, 카드, 팟, 승자 기록 확인 |
| 4 | Admin | 플레이어 통계 확인 | VPIP, PfR, WTSD, Aggression 수치 |
| 5 | 운영자 | Table Pause | Table 상태 = PAUSED |
| 6 | 운영자 | Table Close | Table 상태 = CLOSED |
| 7 | 시스템 | WebSocket 해제 확인 | `OperatorDisconnected` 이벤트 |

### 검증 포인트
- Hand History: 핸드 번호, 시작/종료 시간, 모든 액션 순서
- 통계 정합성:
  - VPIP = (자발적 팟 참여 핸드 수 / 전체 핸드 수) × 100%
  - PfR = (프리플롭 레이즈 핸드 수 / 전체 핸드 수) × 100%
- Table 상태 전이: LIVE → PAUSED → CLOSED
- Close 후 CC 앱에서 새 핸드 시작 불가

---

## 비활성 조건

- 물리 RFID 장비 연결 시나리오: 항상 비활성 (Mock만)
- 네트워크 장애 시나리오: 이 문서 범위 외 (별도 장애 테스트 계획 필요)

---

## 영향 받는 요소

| 요소 | 관계 |
|------|------|
| TEST-01 Test Plan | E2E 계층 10% 비율의 시나리오 상세 |
| TEST-04 Mock Data | 시나리오에서 사용하는 Mock 데이터 정의 |
| BS-06-01 Lifecycle | HandFSM 상태 전이 검증 기준 |
| BS-06-02 Betting | 베팅 유효성 검증 기준 |
| API-03 RFID HAL | MockRfidReader 이벤트 합성 규칙 |
