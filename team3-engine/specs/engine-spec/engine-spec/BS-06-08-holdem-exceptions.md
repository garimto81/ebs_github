# BS-06-08: Hold'em 예외 처리 흐름

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-06 | 신규 작성 | 7가지 예외 유형 + 추가 예외 처리 흐름 정의 |
| 2026-04-07 | 구조 → 번호 변경 | BS-06-09 → BS-06-10으로 재배치 |
| 2026-04-06 | 구조 → Hold'em 전용 변환 | 제목 변경, Hold'em 전용 예외만 유지 확인 |
| 2026-04-09 | Miss Deal → ante 반환 절차 추가 | GAP-GE-002: ante type별 반환 주체 명시 |

---

> **이 문서에서 사용하는 용어**
>
> | 용어 | 설명 |
> |------|------|
> | RFID | 무선 주파수를 이용해 카드를 자동으로 인식하는 기술. 카드에 내장된 IC를 테이블의 센서가 읽는다 |
> | CC | Command Center, 운영자가 게임을 제어하는 화면 |
> | Muck | 패를 공개하지 않고 버리는 것 |
> | Pseudocode | 실제 프로그래밍 언어가 아닌 참고용 가상 코드 |

## 개요

정상적인 핸드 진행에서 벗어나는 **예외 상황**이 발생한다: 전원 폴드, 올인 런아웃, Bomb Pot 특수 처리, Run It Twice, Miss Deal(미스딜), RFID 장애, 카드 불일치. 이 문서는 7가지 예외의 **감지 조건, 즉시 대응, 복구 절차**를 명시하여, 게임 엔진과 운영자가 **예외 상황을 투명하고 안전하게 처리**할 수 있도록 한다.

---

## 정의

**예외 상황**은 정상 핸드 진행의 **제어 흐름을 벗어나는 모든 경우**이다.

- **All Fold**: 액티브 플레이어가 1명으로 감소
- **All-in Runout**: 모든 액티브 플레이어 올인 → 보드 자동 완성
- **Bomb Pot Exception**: PRE_FLOP 스킵, 전원 contribution 미달
- **Run It Twice**: all-in 후 복수 보드 전개
- **Miss Deal**: 카드 불일치 → 핸드 무효화
- **RFID Failure**: 카드 감지 실패 → 재시도 또는 수동 입력
- **Card Mismatch**: 감지 카드 ≠ 예상 카드 → 경고 및 복구

---

## 트리거

### 트리거 소스

| 소스 | 발동 주체 | 처리 시간 | 신뢰도 | 예시 |
|------|---------|---------|--------|------|
| **게임 엔진** | 자동 | 결정론적 | 최고 | All fold 감지, all-in 감지, 보드 완성 감지 |
| **RFID 센서** | 자동 | 50~150ms | 높음 | 카드 감지 성공, 카드 감지 실패, 카드 불일치 |
| **운영자 (CC)** | 수동 | <50ms | 낮음 | UNDO, 미스딜 선언, 수동 카드 입력 |
| **네트워크** | 자동 | 변동 | 낮음 | 연결 단절, 재연결 |

---

## 전제조건

### 예외 감지 전제조건

| 필드 | 조건 | 설명 |
|------|------|------|
| **game_state** | ANY | 어떤 상태에서든 예외 가능 |
| **num_active_players** | 0+ | 0명 = 모두 폴드 (불가능), 1명 = all fold (예외) |
| **hand_in_progress** | true | 핸드 진행 중일 때만 예외 처리 |

---

## 유저 스토리

| # | As a | When | Then | Exception Type |
|:-:|------|------|------|----------------|
| 1 | 게임 엔진 | PRE_FLOP에서 모두 폴드 (1명 남음) | 상태 = HAND_COMPLETE, 1인에게 팟 즉시 지급, 카드 미공개 | All Fold |
| 2 | 게임 엔진 | FLOP에서 모두 올인 + 보드 완성 불가능 | 상태 = SHOWDOWN, 남은 보드(TURN+RIVER) 자동 딜, 핸드 평가 실행 | All-in Runout |
| 3 | 운영자 | NEW HAND (Bomb Pot 활성화) | 모든 플레이어에게서 bomb_pot_amount 자동 수납, PRE_FLOP 스킵, FLOP 직행 | Bomb Pot |
| 4 | 운영자 | Bomb Pot + 일부 플레이어 스택 < bomb_pot_amount | Short contribution: 최대 스택만 수납, 남은 금액은 Dead money로 각 팟에 분배 | Bomb Pot Short |
| 5 | 게임 엔진 | FLOP에서 모든 플레이어 올인 (보드 미완) + run_it_times 동의 | run_it_times=2 설정, 첫 번째 런 보드 완성, 승자 1회차 판정, run_it_times_remaining=1 | Run It Twice |
| 6 | 운영자 | Run It Twice 1회차 완료 | 1회차 결과 저장, 보드 리셋, 2회차 보드 자동 딜, 승자 2회차 판정 | Run It Twice Iteration |
| 7 | 게임 엔진 | Run It Twice 최종 완료 (run_it_times_remaining=0) | 1회차+2회차 결과 합산, 최종 팟 분배 | Run It Twice Complete |
| 8 | 운영자 | 핸드 진행 중 미스딜 선언 | 상태 = IDLE, 모든 팟 복귀, 모든 플레이어 스택 restore, 블라인드 반환, NEW HAND 재시작 | Miss Deal |
| 9 | 시스템 (RFID) | 카드 감지 시도 5회 실패 | RFID_FAILURE 경고, 수동 입력 그리드 활성화, 운영자가 카드 수동 입력 | RFID Failure |
| 10 | 시스템 (RFID) | 카드 감지 성공 BUT 예상 카드와 불일치 | WRONG_CARD 경고, 이전 상태 유지, UNDO 또는 재스캔 선택지 제시 | Card Mismatch |
| 11 | 운영자 | Card Mismatch 발생 후 UNDO 선택 | 이전 상태로 복귀 (카드 미감지 상태), 재스캔 대기 | Card Mismatch UNDO |
| 12 | 운영자 | Card Mismatch 발생 후 수동 입력 선택 | 수동 입력 그리드 활성화, 카드 재입력, 게임 계속 | Card Mismatch Manual |
| 13 | 시스템 | 네트워크 단절 (연결 loss) | 현재 state 보존, 모든 플레이어 action_on 일시 중지, 자동 재연결 시도 | Network Disconnect |
| 14 | 시스템 | 네트워크 재연결 성공 | 이전 state 복구, 게임 계속 (action_on 플레이어에게 재요청) | Network Reconnect |
| 15 | 운영자 | overrideButton 또는 수동 "강제 상태 전이" | 현재 상태에서 임의의 상태로 전이 (위험 작업, 로그 필수) | Manual Override |

---

## 경우의 수 매트릭스

### 매트릭스 1: All Fold 감지

| game_state | num_active | remaining | 결과 | 액션 |
|-----------|:----------:|:-------:|------|------|
| PRE_FLOP | 2 | 1 (fold) | All fold | HAND_COMPLETE, 1인 팟 수령 |
| FLOP | 3 | 1 (fold) | All fold | HAND_COMPLETE, 1인 팟 수령 |
| TURN | 4 | 1 (fold) | All fold | HAND_COMPLETE, 1인 팟 수령 |
| RIVER | 2 | 1 (fold) | All fold | HAND_COMPLETE, 1인 팟 수령 |
| SHOWDOWN | — | — | 불가능 | — |

### 매트릭스 2: All-in Runout 감지

| game_state | num_active | all_in_count | board_cards | 결과 | 액션 |
|-----------|:----------:|:----------:|:----------:|------|------|
| PRE_FLOP | 2 | 2 | 0 | Runout 불필요 (아직 카드 딜 중) | 계속 진행 |
| FLOP | 3 | 3 | 3 | Runout 필요 | TURN+RIVER 자동 딜 → SHOWDOWN |
| FLOP | 3 | 2 | 3 | Runout 가능 (1인 계속) | 계속 진행 (side pot 생성) |
| TURN | 2 | 2 | 4 | Runout 필요 | RIVER 자동 딜 → SHOWDOWN |
| RIVER | 2 | 2 | 5 | Runout 불필요 (보드 완성) | 직접 SHOWDOWN → HAND_COMPLETE |

### 매트릭스 3: Bomb Pot 예외

| Bomb Pot Enabled | bomb_pot_amount | num_active | All Stack ≥ | 결과 |
|:--------:|:--------:|:--------:|:--------:|------|
| ✅ | 2BB | 2+ | ✅ | 전원 수납, PRE_FLOP 스킵, FLOP 직행 |
| ✅ | 2BB | 2+ | ❌ (A<2BB) | A: short contribution (max stack), 정상 진행 |
| ✅ | 2BB | 2+ | ❌ (A,B<2BB) | A,B: short contribution, 일부 dead money, 정상 진행 |
| ✅ | 2BB | 1 | — | 1명만 남음, 즉시 HAND_COMPLETE |
| ❌ | — | — | — | Bomb Pot 미활성화, 표준 진행 |

### 매트릭스 4: Run It Twice 예외

| State | all_in | board | run_it_times | run_it_times_remaining | 액션 |
|------|:------:|:-----:|:----------:|:-----:|------|
| SHOWDOWN | 2+ | 3-4 | 0 | — | run_it_times 선택 메뉴 제시 |
| SHOWDOWN | 2+ | 3-4 | 2 | 2 | 1회차 실행, remaining=1 |
| SHOWDOWN | 2+ | 3-4 | 2 | 1 | 2회차 실행, remaining=0 → HAND_COMPLETE |
| SHOWDOWN | 2+ | 5 | — | — | 보드 완성됨, Run It Twice 불가능 |

### 매트릭스 5: Miss Deal 복구

| game_state | 원인 | 감지 주체 | 복구 액션 |
|-----------|:---:|:-------:|---------|
| ANY | Card 불일치 | 운영자 또는 RFID | pot 복귀, stacks restore, 블라인드 반환, state=IDLE |
| ANY | Card 중복 감지 | RFID | 동일 복구 |
| ANY | 잘못된 card 딜 | 운영자 | 동일 복구 |

### 매트릭스 6: RFID Failure 재시도

| 시도 | 상태 | RFID 응답 | 액션 |
|:---:|------|:-------:|------|
| 1 | Detecting... | fail | 2초 대기 후 재시도 |
| 2 | Detecting... | fail | 2초 대기 후 재시도 |
| 3 | Detecting... | fail | 2초 대기 후 재시도 |
| 4 | Detecting... | fail | 2초 대기 후 재시도 |
| 5 | Detecting... | fail | 수동 입력 그리드 활성화, 운영자 수동 입력 대기 |

### 매트릭스 7: Card Mismatch 처리

| RFID 감지 | 예상 카드 | 경고 | Venue | Broadcast |
|:--------:|:--------:|:---:|-------|----------|
| 7♠ | A♠ | ✅ WRONG_CARD | 공개 안 함 | 공개 안 함 (이전 상태 유지) |
| A♠ | A♠ | ❌ 일치 | 정상 공개 | 정상 공개 |
| (미감지) | A♠ | ✅ TIMEOUT | 수동 입력 대기 | 수동 입력 대기 |

---

## 비활성 조건

### 예외 처리 미실행 조건

- **game_state == IDLE** → 핸드 미진행, 예외 불필요
- **num_remaining_players ≥ 2 (All Fold 제외)** → 정상 진행
- **All card detected successfully + 일치** → Miss Deal/Card Mismatch 미발생
- **RFID 정상 작동** → RFID Failure 미발생
- **네트워크 정상 연결** → Network Disconnect 미발생

---

## 영향 받는 요소

### 1. All Fold 영향

1. **hand_lifecycle.md**: HAND_COMPLETE 즉시 전이
2. **Overlay**: "All Fold → [1인 이름] Wins" 표시
3. **Statistics**: hand_stats.all_fold=true, hand_stats.winner=seat

### 2. All-in Runout 영향

1. **hand_evaluation.md**: 보드 자동 완성 후 핸드 평가 실행
2. **showdown_reveal.md**: 모든 플레이어 카드 강제 공개 (ALL_IN_RUNOUT)
3. **Overlay**: "ALL-IN RUNOUT" 표시, 보드 자동 딜 애니메이션
4. **Statistics**: hand_stats.all_in_runout=true

### 3. Bomb Pot 예외 영향

1. **hand_lifecycle.md**: PRE_FLOP 스킵, FLOP 직행
2. **side_pot_algebra.md**: Short contribution 시 dead money 추적
3. **chip_collection.md**: 전원 contribution 자동 수납
4. **Overlay**: "BOMB POT" 표시, 금액 표시
5. **Statistics**: hand_stats.is_bomb_pot=true

### 4. Run It Twice 예외 영향

1. **hand_evaluation.md**: 각 런별 보드 전개, 독립적 평가
2. **side_pot_algebra.md**: 각 런별 팟 분배 (비율 계산)
3. **showdown_reveal.md**: 각 런별 카드 공개
4. **Overlay**: "RUN 1", "RUN 2" 표시, 보드 변경 애니메이션
5. **Statistics**: hand_stats.run_it_times, run_it_results

### 5. Miss Deal 영향

1. **hand_lifecycle.md**: state=IDLE로 즉시 복귀
2. **chip_collection.md**: 팟 복귀, 블라인드 반환
3. **Stack tracking**: 모든 플레이어 스택 restore
4. **Overlay**: "MISDEAL" 경고, "Redealing..." 표시
5. **Statistics**: hand_stats.is_misdeal=true, hand_count 증가 안 함

### 6. RFID Failure 영향

1. **card_detection.md**: 5회 재시도 후 수동 입력 모드 전환
2. **UI (CC)**: 수동 입력 그리드 활성화 (52장 선택 인터페이스)
3. **State preservation**: 현재 게임 상태 유지
4. **Overlay**: "Manual Card Input" 표시
5. **Statistics**: card_detection_failure_count 증가

### 7. Card Mismatch 영향

1. **hand_lifecycle.md**: 공개 중지, 상태 유지
2. **showdown_reveal.md**: Venue=공개 안 함, Broadcast=이전 상태 유지
3. **UI (CC)**: UNDO 또는 수동 입력 선택지 제시
4. **Overlay**: "WRONG CARD" 경고, "Please Rescan or Input Manually" 표시
5. **Statistics**: card_mismatch_count 증가

---

## 데이터 모델 (Pseudo-code)

> 아래는 개발자 참고용 코드입니다.

### ExceptionState 구조

```python
class ExceptionState:
    exception_type: str  # "all_fold", "all_in_runout", "bomb_pot", "run_it_twice", 
                         # "miss_deal", "rfid_failure", "card_mismatch", "network_disconnect"
    triggered_at_state: str  # 예외 발생 당시 game_state
    triggered_at_time: float  # 타임스탬프
    recovery_actions: list[str]  # 복구 액션 히스토리
    is_resolved: bool = False  # 복구 완료 여부
    
class HandState:
    # ... 기존 필드 ...
    
    # Exception 관련
    exception_state: ExceptionState = None
    saved_state_for_undo: HandState = None  # UNDO용 이전 상태 백업
```

### RFIDFailureRetry 구조

```python
class RFIDFailureRetry:
    attempt_count: int = 0  # 1-5
    max_attempts: int = 5
    retry_interval: float = 2.0  # 초
    last_retry_time: float = None
    
    def should_retry(self) -> bool:
        return self.attempt_count < self.max_attempts
    
    def should_fallback_to_manual(self) -> bool:
        return self.attempt_count >= self.max_attempts
```

---

## 알고리즘: 예외 감지 및 처리 순서

```
1. 게임 엔진 루프 (매 액션 후)
   ├─ num_active_players == 1? → All Fold 처리
   ├─ all_in_count == num_active && board < max? → All-in Runout 처리
   ├─ card_mismatch 감지? → Card Mismatch 처리
   ├─ network_disconnect 감지? → Network Disconnect 처리
   └─ 정상 진행

2. All Fold 처리
   ├─ state = HAND_COMPLETE
   ├─ pot → 남은 1인 플레이어
   ├─ 카드 미공개
   └─ next_hand 대기

3. All-in Runout 처리
   ├─ 보드 완성 (TURN+RIVER 또는 RIVER)
   ├─ run_it_times > 0? → Run It Twice 처리
   ├─ 아니면 → 직접 SHOWDOWN
   └─ 핸드 평가 실행

4. Run It Twice 처리
   ├─ run_it_times=2, run_it_times_remaining=2
   ├─ 1회차 보드 딜, 평가
   ├─ 1회차 결과 저장
   ├─ 보드 리셋
   ├─ 2회차 보드 딜, 평가
   ├─ run_it_times_remaining=0
   └─ 전체 결과 합산, HAND_COMPLETE

5. RFID Failure 처리
   ├─ attempt_count < 5? → retry
   ├─ attempt_count >= 5? → manual_input_grid 활성화
   └─ 운영자 수동 입력 대기

6. Card Mismatch 처리
   ├─ Canvas=Venue? → 공개 중지
   ├─ Canvas=Broadcast? → 이전 상태 유지
   ├─ UNDO 또는 재스캔 선택지 제시
   └─ 운영자 선택 대기

7. Miss Deal 처리
   ├─ pot 복귀
   ├─ stacks restore (블라인드 포함)
   ├─ **ante 반환**: 각 플레이어가 포스팅한 ante 금액을 스택으로 반환
   │   ├─ type 0 (std_ante): 전원 → 각자 반환
   │   ├─ type 1 (button_ante): 딜러 → 딜러 반환
   │   ├─ type 2 (bb_ante): BB → BB 반환
   │   └─ type 3~6: 해당 포스팅 주체에게 반환
   ├─ state = IDLE
   └─ NEW HAND 재시작

8. Network Disconnect 처리
   ├─ state 보존
   ├─ action_on 일시 중지
   ├─ 자동 재연결 시도 (exponential backoff(재시도 간격을 점점 늘리는 방식, 예: 2초→4초→8초))
   └─ 재연결 성공 시 state 복구, 게임 계속
```

---

## 특수 케이스

### 케이스 1: All Fold + All-in (PRE_FLOP)

```
상황: 플레이어 A raise, B call, C all-in, D fold, A fold, B fold
→ C만 남음 (All Fold)
→ HAND_COMPLETE, C가 팟 수령
→ All-in runout 미실행 (이미 올인이지만 오직 1인 남음)
```

### 케이스 2: Bomb Pot + Run It Twice

```
상황: Bomb Pot 모드 + 모든 플레이어 올인 FLOP
→ FLOP 자동 딜 (Bomb Pot)
→ 보드 TURN+RIVER 자동 완성 (all-in)
→ run_it_times 선택? → 2회차 진행
→ 각 런별 TURN+RIVER 다시 딜
```

### 케이스 3: RFID Failure + Manual Input

```
상황: RFID 5회 실패 → 수동 입력 그리드 활성화
→ 운영자가 52장 카드 중 맞는 카드 선택
→ 게임 상태 유지, 다음 카드 감지 진행
→ 모든 카드 수동 입력 완료 후 정상 진행
```

### 케이스 4: Card Mismatch + Canvas

```
상황: RFID 7♠ / 예상 A♠ (불일치)
Canvas=Venue:
  → 공개 안 함 (신뢰성 중심)
  → UNDO 또는 재스캔만 선택지

Canvas=Broadcast:
  → 이전 상태 유지 (A♠ 표시 계속)
  → UNDO 또는 수동 입력 선택지
```

### 케이스 5: Network Disconnect + State Restore

```
상황: 네트워크 단절 → action_on 일시 중지
→ 30초 자동 재연결 시도
→ 재연결 실패 → 60초 재시도 (exponential backoff)
→ 재연결 성공 → 이전 state 복구, action_on 플레이어에게 재요청
```

### 케이스 6: Multiple Exceptions (Run It Twice 중 RFID Failure)

```
상황: Run It Twice 2회차 진행 중 RFID 감지 실패
→ RFID Failure 처리 (5회 재시도)
→ 수동 입력 또는 UNDO
→ UNDO 선택 시 2회차 처음부터 재시작
→ 수동 입력 선택 시 게임 계속
```
