# TEST-05: QA 체크리스트

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 소프트웨어 수동 QA 체크리스트 56항목 (7개 카테고리) |

---

## 개요

EBS 소프트웨어 수동 QA 체크리스트. **물리 하드웨어 테스트는 제외** — 모든 RFID 항목은 MockRfidReader로만 검증한다.

> 참조: Mock 모드 — BS-00 §9, RFID HAL — API-03, E2E 시나리오 — TEST-02

### 사용 방법

각 항목의 Pass/Fail을 기록한다. Fail 항목은 이슈 트래커에 등록한다.

---

## 1. Auth (5항목)

| # | 테스트 항목 | 테스트 조건 | 기대 결과 | Pass/Fail |
|:-:|-----------|-----------|----------|:---------:|
| A-01 | Admin 로그인 성공 | 유효한 Admin 계정으로 Lobby 로그인 | JWT 발급, Lobby 메인 화면 진입, 모든 메뉴 접근 가능 | |
| A-02 | Operator 로그인 + 권한 제한 | Operator 계정으로 로그인 | 할당된 테이블만 표시, Settings 수정 불가 | |
| A-03 | 잘못된 비밀번호 | 유효 계정 + 잘못된 비밀번호 | 로그인 실패, "Invalid credentials" 에러 표시 | |
| A-04 | 세션 만료 | JWT 만료 후 API 호출 | 401 응답, 로그인 페이지로 리다이렉트 | |
| A-05 | Viewer 읽기 전용 | Viewer 계정으로 로그인 | 모든 데이터 조회 가능, 생성/수정/삭제 불가 | |

---

## 2. Lobby (10항목)

| # | 테스트 항목 | 테스트 조건 | 기대 결과 | Pass/Fail |
|:-:|-----------|-----------|----------|:---------:|
| L-01 | Series 생성 | 이름, 기간 입력 후 생성 | Series 목록에 표시, DB 저장 확인 | |
| L-02 | Event 생성 | Series 하위에 Event 생성 | 계층 구조 정상, game_type 설정 | |
| L-03 | Flight 생성 | Event 하위에 Flight 생성 | 시작 시간, 상태 설정 정상 | |
| L-04 | Table 생성 + Flight 할당 | Table 생성 후 Flight에 할당 | Table 상태 = EMPTY, Flight 하위 표시 | |
| L-05 | Player 등록 (수동) | 이름, 국적 입력 후 등록 | Player DB 저장, 검색 가능 | |
| L-06 | 좌석 배치 (SeatAssign) | Player를 특정 Seat에 배치 | Seat 상태 = OCCUPIED, Table 상태 → SETUP | |
| L-07 | 좌석 이동 (SeatMove) | Player를 다른 Seat으로 이동 | 원래 Seat = VACANT, 새 Seat = OCCUPIED | |
| L-08 | 중복 좌석 배치 거부 | 이미 OCCUPIED인 Seat에 다른 Player 배치 | 에러 표시, 배치 거부 | |
| L-09 | 필수 필드 유효성 | Event 생성 시 이름 미입력 | 유효성 에러 표시, 저장 거부 | |
| L-10 | 테이블 모니터링 대시보드 | CC 연결 후 Lobby 대시보드 확인 | 테이블 상태(LIVE), 현재 핸드 번호, RFID 상태 실시간 갱신 | |

---

## 3. Command Center (15항목)

| # | 테스트 항목 | 테스트 조건 | 기대 결과 | Pass/Fail |
|:-:|-----------|-----------|----------|:---------:|
| C-01 | CC Launch + WebSocket 연결 | Lobby에서 CC Launch | CC 앱 실행, BO WebSocket 연결, `OperatorConnected` 이벤트 | |
| C-02 | NEW HAND 시작 | IDLE 상태 + precondition 충족 | HandFSM → SETUP_HAND, 블라인드 자동 수집 | |
| C-03 | NEW HAND 전제조건 미충족 | pl_dealer == -1 (딜러 미지정) | StartHand 거부, 에러 메시지 표시 | |
| C-04 | 홀카드 딜 (Mock 수동 입력) | Mock 모드에서 각 플레이어 카드 2장 입력 | CardDetected 이벤트 합성, HandFSM → PRE_FLOP | |
| C-05 | Fold 액션 | 활성 플레이어에서 FOLD 버튼 | player.status = folded, action_on 다음 이동 | |
| C-06 | Check 액션 (유효) | biggest_bet == current_bet 상태에서 CHECK | action_on 다음 이동, 베팅액 불변 | |
| C-07 | Check 액션 (거부) | biggest_bet > current_bet 상태에서 CHECK | "베팅이 있습니다" 경고, 액션 거부 | |
| C-08 | Bet/Raise 금액 입력 | NL에서 금액 직접 입력 후 확인 | 금액 유효성 검증 통과, biggest_bet_amt 갱신 | |
| C-09 | 최소 레이즈 미달 거부 | NL에서 min_raise 미만 금액 입력 | "최소 레이즈 금액은 X" 에러, 재입력 요청 | |
| C-10 | All-In 처리 | 스택 전액 베팅 | player.status = allin, SidePotCreated (해당 시) | |
| C-11 | 보드 카드 입력 (Flop 3장) | Mock 모드에서 보드 카드 3장 입력 | CardDetected × 3, board_cards = 3, HandFSM → FLOP | |
| C-12 | UNDO 1단계 | 마지막 액션 후 UNDO | 이전 상태 복원, action_on/biggest_bet 복원 | |
| C-13 | UNDO 6단계 거부 | 5단계 UNDO 후 추가 시도 | "Undo limit reached" 에러 | |
| C-14 | Miss Deal | 핸드 중 Miss Deal 선언 | HandFSM → IDLE, 스택 복구, 팟 반환 | |
| C-15 | Bomb Pot 모드 | Bomb Pot 설정 후 NEW HAND | 전원 고정액 납부, PRE_FLOP 스킵, FLOP 직행 | |

---

## 4. Settings (8항목)

| # | 테스트 항목 | 테스트 조건 | 기대 결과 | Pass/Fail |
|:-:|-----------|-----------|----------|:---------:|
| S-01 | Output 설정 저장 | NDI, 1080p, Security Delay 10초 | OutputPreset DB 저장 확인 | |
| S-02 | Overlay 설정 변경 | Skin 변경, card_style 변경 | `ConfigChanged` WebSocket 이벤트 발행, CC 반영 | |
| S-03 | Game 설정 변경 | NL Hold'em → PL Omaha 변경 | bet_structure, game_type 변경 적용 | |
| S-04 | BlindStructure 레벨 변경 | 레벨 1 → 레벨 2 수동 변경 | `BlindStructureChanged` 이벤트, CC에 새 SB/BB 표시 | |
| S-05 | Statistics 옵션 ON/OFF | VPIP 표시 OFF | Overlay에서 VPIP 숨김 | |
| S-06 | 잘못된 값 거부 | BB=0 또는 해상도 0×0 입력 | 유효성 에러 표시, 저장 거부 | |
| S-07 | 설정 프리셋 저장/로드 | 현재 설정을 프리셋으로 저장 후 다른 설정 적용 후 프리셋 로드 | 원래 설정 복원 | |
| S-08 | 핸드 중 설정 변경 지연 | 핸드 진행 중 Config 변경 | 핸드 완료 후 적용 (즉시 적용 안 됨) | |

---

## 5. Overlay (8항목)

| # | 테스트 항목 | 테스트 조건 | 기대 결과 | Pass/Fail |
|:-:|-----------|-----------|----------|:---------:|
| O-01 | 홀카드 표시 | 홀카드 딜 후 Overlay 확인 | 각 플레이어 위치에 2장 카드 표시 | |
| O-02 | 보드 카드 표시 | Flop/Turn/River 공개 | 보드 영역에 카드 순차 표시 | |
| O-03 | 팟 금액 표시 | 베팅 발생 시 | 팟 금액 실시간 갱신 | |
| O-04 | 플레이어 스택 표시 | 베팅/승리 후 | 스택 금액 실시간 갱신 | |
| O-05 | Equity 표시 | 홀카드 공개 후 | 각 플레이어 승률(%) 표시 | |
| O-06 | 폴드 플레이어 표시 | FOLD 액션 후 | 해당 플레이어 카드 회색 처리 또는 숨김 | |
| O-07 | 승자 하이라이트 | HAND_COMPLETE 진입 | 승자 플레이어 + 승리 핸드 하이라이트 | |
| O-08 | Security Delay 적용 | Security Delay=10초 설정 | Overlay 출력이 실제 게임보다 10초 지연 | |

---

## 6. RFID Mock (5항목)

| # | 테스트 항목 | 테스트 조건 | 기대 결과 | Pass/Fail |
|:-:|-----------|-----------|----------|:---------:|
| R-01 | MockRfidReader 초기화 | CC 시작 시 Mock 모드 | status = ready, AntennaStatusChanged(connected) | |
| R-02 | 자동 덱 등록 | "자동 등록" 버튼 클릭 | 52장 매핑 즉시 완료, DeckRegistered 이벤트 | |
| R-03 | 수동 카드 입력 → CardDetected | CC에서 suit/rank 선택 후 카드 입력 | CardDetected 이벤트 합성, uid="MOCK-{suit}{rank}", confidence=1.0 | |
| R-04 | 에러 주입 (테스트용) | injectError(connectionLost) 호출 | ReaderError 이벤트 발행, CC에 에러 표시 | |
| R-05 | YAML 시나리오 재생 | loadScenario("basic-headsup.yaml") | 사전 정의된 이벤트 순서대로 발행, 결정적 타이밍 |  |

---

## 7. Data Sync (5항목)

| # | 테스트 항목 | 테스트 조건 | 기대 결과 | Pass/Fail |
|:-:|-----------|-----------|----------|:---------:|
| D-01 | CC → BO 핸드 기록 동기화 | 핸드 완료 후 | HandStarted/HandEnded 이벤트 → BO DB에 Hand History 저장 | |
| D-02 | Lobby → BO → CC 설정 전달 | Lobby에서 Settings 변경 | ConfigChanged 이벤트 → CC에서 새 설정 적용 | |
| D-03 | 플레이어 정보 동기화 | Lobby에서 Player 이름 수정 | PlayerUpdated 이벤트 → CC 표시 갱신, Overlay 갱신 | |
| D-04 | WebSocket 재연결 | CC WebSocket 끊김 후 재연결 | OperatorDisconnected → 자동 재연결 시도 → OperatorConnected | |
| D-05 | 통계 업데이트 동기화 | 핸드 종료 후 | StatisticsUpdated → Lobby에서 플레이어 통계 조회 시 최신값 반영 | |

---

## 합계

| 카테고리 | 항목 수 |
|---------|:------:|
| Auth | 5 |
| Lobby | 10 |
| Command Center | 15 |
| Settings | 8 |
| Overlay | 8 |
| RFID Mock | 5 |
| Data Sync | 5 |
| **합계** | **56** |

---

## 비활성 조건

- 물리 RFID 하드웨어 테스트: 항상 비활성 (6. RFID Mock 카테고리는 소프트웨어 Mock만)
- 네트워크 인프라 테스트: 범위 외
- 성능/부하 테스트: 범위 외 (별도 계획 필요)

---

## 영향 받는 요소

| 요소 | 관계 |
|------|------|
| TEST-01 Test Plan | 수동 QA로 자동화 테스트 보완 |
| TEST-02 E2E Scenarios | E2E 시나리오의 수동 검증 버전 |
| BS-00 Definitions | 상태값, FSM 정의 기준 |
| BS-06-00 Triggers | 트리거 경계, Mock 합성 규칙 |
| API-03 RFID HAL | MockRfidReader 테스트 기준 |
