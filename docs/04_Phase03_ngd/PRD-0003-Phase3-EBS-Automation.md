# Phase 3: 자동화 프로토콜

> **BRACELET STUDIO** | EBS Project

**완료 시점**: 2028년 Q4
**목표**: 자동화 프로토콜로 프로덕션 최적화 - 시스템이 일하고, 사람은 검증만
**전제조건**: Phase 1 Gate 100% 통과

---

## 1. Phase 3 개요

### 1.1 목표

> **"손이 아닌 시스템이 일한다. 운영자는 검증만 한다."**

Phase 3는 EBS만의 독창적인 자동화 시스템을 구현합니다.
팟 계산, 칩 추적, 액션 추론을 자동화하여 운영자의 입력을 최소화합니다.

### 1.2 핵심 원칙

| 원칙 | 설명 | 실패 시 처리 |
|------|------|-------------|
| **자동 우선** | 가능한 모든 것을 자동화 | - |
| **수동 폴백** | 자동화 실패 시 수동 입력 | 즉시 수동 모드 |
| **정확성 100%** | 팟 계산은 절대 틀리면 안 됨 | 오류 시 경고 + 수동 확인 |

### 1.3 성공 기준

| 기준 | 목표 | 검증 방법 |
|------|------|----------|
| 운영자 입력 감소 | 80% 이상 (Phase 0 대비) | 입력 횟수 비교 |
| 팟 계산 정확도 | 100% | 100핸드 무오류 테스트 |
| 칩 추적 정확도 | 99%+ | WSOP+ 비교 |
| 시스템 가동률 | 99.9% | 8시간 연속 운영 |

---

## 2. 자동화 영역

### 2.1 자동화 전후 비교

| 영역 | Phase 0 | Phase 1 | Phase 2 | 자동화율 |
|------|---------|---------|---------|:--------:|
| 플레이어 이름 | 수동 | 자동 | 자동 | 100% |
| 초기 칩 스택 | 수동 | 자동 | 자동 | 100% |
| 칩 카운트 | 수동 보정 | 동기화 | **실시간 추적** | 100% |
| 팟 사이즈 | 수동 계산 | 수동 계산 | **자동 계산** | 100% |
| 블라인드 레벨 | 수동 | 자동 | 자동 | 100% |
| 베팅 금액 | 수동 | 수동 | **자동 추론** | 80% |
| 플레이어 액션 | 수동 | 수동 | **제안 모드** | 50% |
| 보드 카드 | 수동 | 수동 | **자동 인식** | 95% |

### 2.2 입력 감소 계산

| 핸드당 입력 | Phase 0 | Phase 2 | 감소 |
|------------|:-------:|:-------:|:----:|
| 플레이어 설정 | 10회 | 0회 | -10 |
| 액션 입력 | 15회 | 3회 (확인만) | -12 |
| 베팅 금액 | 10회 | 2회 (오류 시) | -8 |
| 팟 계산 | 5회 | 0회 | -5 |
| 칩 보정 | 2회 | 0회 | -2 |
| **총계** | **42회** | **5회** | **-88%** |

---

## 3. 팟 사이즈 자동 계산

### 3.1 개요

모든 베팅 액션이 입력되면 팟 사이즈를 자동으로 계산합니다.
사이드 팟도 자동으로 분리됩니다.

### 3.2 계산 로직

```python
class PotCalculator:
    def __init__(self):
        self.main_pot = 0
        self.side_pots = []
        self.current_street_bets = {}  # seat -> amount

    def process_action(self, action: Action) -> int:
        """액션 처리 후 총 팟 반환"""

        if action.type == 'FOLD':
            # 폴드: 팟 변화 없음, 현재 베팅만 팟에 추가
            self._collect_bet(action.seat)
            return self.get_total_pot()

        elif action.type == 'CHECK':
            # 체크: 팟 변화 없음
            return self.get_total_pot()

        elif action.type == 'CALL':
            # 콜: 콜 금액만큼 베팅 추가
            call_amount = self._get_call_amount(action.seat)
            self.current_street_bets[action.seat] = (
                self.current_street_bets.get(action.seat, 0) + call_amount
            )
            return self.get_total_pot()

        elif action.type in ['BET', 'RAISE']:
            # 베팅/레이즈: 해당 금액으로 베팅
            self.current_street_bets[action.seat] = action.amount
            return self.get_total_pot()

        elif action.type == 'ALL_IN':
            # 올인: 플레이어 전체 스택
            self.current_street_bets[action.seat] = action.amount
            self._check_side_pot()
            return self.get_total_pot()

    def end_street(self):
        """스트릿 종료: 베팅을 팟에 수집"""
        for seat, amount in self.current_street_bets.items():
            self.main_pot += amount
        self.current_street_bets = {}

    def get_total_pot(self) -> int:
        """현재 총 팟 (메인 + 사이드 + 현재 스트릿 베팅)"""
        street_total = sum(self.current_street_bets.values())
        side_total = sum(sp['amount'] for sp in self.side_pots)
        return self.main_pot + side_total + street_total
```

### 3.3 사이드 팟 분리

```python
def _check_side_pot(self):
    """올인 상황에서 사이드 팟 분리"""

    # 베팅 금액 정렬
    sorted_bets = sorted(self.current_street_bets.items(), key=lambda x: x[1])

    if len(sorted_bets) < 2:
        return

    # 최소 올인 금액 기준으로 분리
    min_all_in = sorted_bets[0][1]
    eligible_players = [seat for seat, _ in sorted_bets]

    # 메인 팟에 추가
    main_contribution = min_all_in * len(eligible_players)
    self.main_pot += main_contribution

    # 사이드 팟 생성
    remaining_bets = {}
    for seat, amount in sorted_bets:
        remaining = amount - min_all_in
        if remaining > 0:
            remaining_bets[seat] = remaining

    if remaining_bets:
        self.side_pots.append({
            'amount': sum(remaining_bets.values()),
            'eligible': list(remaining_bets.keys())
        })

    self.current_street_bets = {}
```

---

## 4. 칩 카운트 실시간 추적

### 4.1 개요

Phase 1의 동기화 방식에서 더 나아가, 모든 베팅에서 칩을 실시간으로 차감/추가합니다.
브레이크 시 WSOP+와 보정하여 정확성을 유지합니다.

### 4.2 추적 로직

```python
class ChipTracker:
    def __init__(self, players: List[Player]):
        self.stacks = {p.seat: p.stack for p in players}
        self.history = []  # 롤백용 히스토리

    def process_action(self, action: Action):
        """액션에 따른 칩 차감/추가"""

        self.history.append({
            'seat': action.seat,
            'before': self.stacks[action.seat],
            'action': action
        })

        if action.type == 'FOLD':
            # 폴드: 변화 없음
            pass

        elif action.type in ['BET', 'RAISE', 'CALL']:
            # 베팅: 차감
            self.stacks[action.seat] -= action.amount

        elif action.type == 'ALL_IN':
            # 올인: 0으로
            self.stacks[action.seat] = 0

    def award_pot(self, seat: int, amount: int):
        """팟 수여"""
        self.history.append({
            'seat': seat,
            'before': self.stacks[seat],
            'award': amount
        })
        self.stacks[seat] += amount

    def undo_last(self):
        """마지막 액션 취소"""
        if not self.history:
            return False

        last = self.history.pop()
        self.stacks[last['seat']] = last['before']
        return True

    def get_display(self, seat: int) -> str:
        """표시용 스택 (콤마 포맷)"""
        return f"${self.stacks[seat]:,}"
```

### 4.3 실시간 업데이트 흐름

```
베팅 입력
    │
    ▼
┌─────────────────┐
│  칩 차감        │────▶ UI 즉시 업데이트
└─────────────────┘
    │
    ▼
┌─────────────────┐
│  히스토리 저장  │────▶ UNDO 가능
└─────────────────┘
    │
    ▼
┌─────────────────┐
│  WSOP+ 동기화   │────▶ 핸드 종료 시 Push
│  (Phase 1)      │
└─────────────────┘
```

### 4.4 보정 로직

```python
def reconcile_with_wsop(self, wsop_stacks: dict):
    """브레이크 시 WSOP+ 값으로 보정"""

    corrections = []

    for seat, ebs_stack in self.stacks.items():
        wsop_stack = wsop_stacks.get(seat, 0)
        diff = ebs_stack - wsop_stack

        if abs(diff) > 0:
            corrections.append({
                'seat': seat,
                'ebs': ebs_stack,
                'wsop': wsop_stack,
                'diff': diff,
                'percent': abs(diff) / max(ebs_stack, wsop_stack) * 100
            })

            # 자동 보정
            self.stacks[seat] = wsop_stack

    return corrections
```

---

## 5. 액션 자동 추론 (제안 모드)

### 5.1 개요

카드 움직임, 칩 움직임을 분석하여 플레이어 액션을 추론합니다.
추론된 액션은 **제안**으로 표시되고, 운영자가 확인/수정합니다.

### 5.2 추론 규칙

| 감지 신호 | 추론 액션 | 신뢰도 | 처리 |
|----------|----------|:------:|------|
| 카드 던짐 | FOLD | 90% | 자동 적용 |
| 칩 이동 없음 | CHECK | 85% | 자동 적용 |
| 콜 금액 칩 이동 | CALL | 80% | 제안 (확인 필요) |
| 콜 초과 칩 이동 | RAISE | 75% | 제안 (확인 필요) |
| 전체 칩 이동 | ALL-IN | 95% | 자동 적용 |

### 5.3 추론 엔진

```python
class ActionInferenceEngine:
    def __init__(self, pot_calculator: PotCalculator, chip_tracker: ChipTracker):
        self.pot = pot_calculator
        self.chips = chip_tracker

    def infer_action(self, seat: int, signal: Signal) -> Suggestion:
        """신호 기반 액션 추론"""

        if signal.type == 'CARDS_MUCKED':
            return Suggestion(
                action=Action('FOLD', seat),
                confidence=0.90,
                auto_apply=True
            )

        elif signal.type == 'NO_CHIP_MOVEMENT':
            call_amount = self.pot._get_call_amount(seat)
            if call_amount == 0:
                return Suggestion(
                    action=Action('CHECK', seat),
                    confidence=0.85,
                    auto_apply=True
                )

        elif signal.type == 'CHIP_MOVEMENT':
            detected_amount = signal.amount
            call_amount = self.pot._get_call_amount(seat)

            if detected_amount == call_amount:
                return Suggestion(
                    action=Action('CALL', seat, call_amount),
                    confidence=0.80,
                    auto_apply=False  # 확인 필요
                )

            elif detected_amount > call_amount:
                return Suggestion(
                    action=Action('RAISE', seat, detected_amount),
                    confidence=0.75,
                    auto_apply=False  # 확인 필요
                )

            elif detected_amount == self.chips.stacks[seat]:
                return Suggestion(
                    action=Action('ALL_IN', seat, detected_amount),
                    confidence=0.95,
                    auto_apply=True
                )

        return Suggestion(action=None, confidence=0, auto_apply=False)
```

### 5.4 제안 처리 흐름

```
신호 감지
    │
    ▼
┌─────────────────┐
│  액션 추론      │
└─────────────────┘
    │
    ├── 신뢰도 ≥ 85%: 자동 적용 (UI에 표시)
    │
    └── 신뢰도 < 85%: 제안 모드
            │
            ├── 운영자 확인 → 적용
            │
            └── 운영자 수정 → 수정 후 적용
```

---

## 6. 보드 카드 자동 인식

### 6.1 개요

딜러 위치의 RFID 리더가 보드 카드를 자동으로 인식합니다.
Flop(3장), Turn(1장), River(1장) 순서를 검증합니다.

### 6.2 인식 로직

```python
class BoardRecognizer:
    def __init__(self, dealer_reader_id: int):
        self.reader_id = dealer_reader_id
        self.board = []
        self.expected_count = {
            'preflop': 0,
            'flop': 3,
            'turn': 1,
            'river': 1
        }

    def on_card_detected(self, card: Card, street: str):
        """카드 감지 이벤트"""

        # 이미 인식된 카드인지 확인
        if card in self.board:
            return Warning(f"Duplicate card: {card.display}")

        # 현재 스트릿에 맞는 카드 수인지 확인
        current_count = len(self.board)
        expected = self._get_expected_count(street)

        if current_count >= expected:
            return Warning(f"Too many cards for {street}")

        # 보드에 추가
        self.board.append(card)

        return Success(f"Board: {[c.display for c in self.board]}")

    def _get_expected_count(self, street: str) -> int:
        if street == 'preflop':
            return 0
        elif street == 'flop':
            return 3
        elif street == 'turn':
            return 4
        elif street == 'river':
            return 5
```

### 6.3 검증 및 경고

| 상황 | 경고 | 처리 |
|------|------|------|
| 중복 카드 | "Card already on board" | 무시 |
| 초과 카드 | "Too many cards for street" | 경고 표시 |
| 순서 오류 | "Expected flop, got single card" | 경고 표시 |
| 플레이어 카드 | "Player card detected on board" | 경고 + 수동 확인 |

---

## 7. 개발 일정

### 7.1 분기별 마일스톤

| 분기 | 마일스톤 | 주요 기능 | 완료 기준 |
|------|----------|----------|----------|
| **Q1** (1-4월) | Alpha | 팟 자동 계산 | 정확도 100% (100핸드) |
| **Q2** (5-8월) | Beta | 칩 실시간 추적 | ±1% 오차 이내 |
| **Q3** (9-10월) | RC | 액션 추론 + 보드 인식 | 제안 모드 동작, 95%+ 정확도 |
| **Q4** (11-12월) | Release | 최적화 + 안정화 | 8시간 연속 운영 |

### 7.2 Q1 상세 (Alpha) - 팟 자동 계산

- [ ] PotCalculator 클래스 구현
- [ ] 사이드 팟 분리 로직
- [ ] 팟 표시 UI 컴포넌트
- [ ] 수동 오버라이드 기능
- [ ] 100핸드 정확도 테스트
- [ ] 엣지 케이스 처리 (올인, 사이드 팟 3개+)

### 7.3 Q2 상세 (Beta) - 칩 실시간 추적

- [ ] ChipTracker 클래스 구현
- [ ] 실시간 UI 업데이트
- [ ] UNDO 기능
- [ ] WSOP+ 보정 로직 연동
- [ ] 칩 표시 포맷팅 (콤마, 단위)

### 7.4 Q3 상세 (RC) - 액션 추론 + 보드 인식

- [ ] ActionInferenceEngine 구현
- [ ] 제안 UI 컴포넌트
- [ ] 신뢰도 기반 자동/수동 분기
- [ ] 딜러 RFID 리더 연동
- [ ] BoardRecognizer 구현
- [ ] 카드 순서 검증

### 7.5 Q4 상세 (Release)

- [ ] 성능 최적화 (메모리, CPU)
- [ ] 8시간 연속 운영 테스트
- [ ] 운영자 피드백 반영
- [ ] 문서화 및 교육 자료
- [ ] 최종 검수

---

## 8. 테스트 계획

### 8.1 단위 테스트

| 컴포넌트 | 테스트 항목 | 기대 결과 |
|----------|------------|----------|
| PotCalculator | 기본 베팅 | 정확한 팟 계산 |
| PotCalculator | 사이드 팟 | 올바른 분리 |
| ChipTracker | 차감/추가 | 정확한 스택 |
| ChipTracker | UNDO | 이전 상태 복원 |
| ActionInference | 폴드 감지 | 90%+ 정확도 |
| BoardRecognizer | 순서 검증 | 잘못된 순서 감지 |

### 8.2 통합 테스트

| 시나리오 | 단계 | 검증 |
|----------|------|------|
| **10핸드 세션** | 모든 자동화 활성화 | 오류 0건 |
| **올인 상황** | 3-way 올인 | 사이드 팟 정확 |
| **추론 실패** | 수동 입력 폴백 | 정상 동작 |
| **보드 오류** | 잘못된 카드 순서 | 경고 표시 |

### 8.3 성능 테스트

| 테스트 | 조건 | 통과 기준 |
|--------|------|----------|
| **8시간 연속** | 실제 환경 | 99.9% 가동률 |
| **CPU 사용률** | 8코어 기준 | < 30% |
| **메모리 사용** | 4시간 후 | < 500MB |
| **응답 시간** | 팟 계산 | < 100ms |

---

## 9. 위험 관리

| 위험 | 영향도 | 발생 확률 | 대응 방안 |
|------|:------:|:--------:|----------|
| 팟 계산 오류 | 높음 | 낮음 | 수동 오버라이드 + 경고 |
| 액션 추론 실패 | 중간 | 중간 | 제안 모드 (확인 필수) |
| 보드 인식 실패 | 중간 | 낮음 | 수동 입력 폴백 |
| 성능 저하 | 중간 | 낮음 | 비동기 처리 + 캐싱 |
| 칩 동기화 오류 | 높음 | 낮음 | WSOP+ 보정 |

---

## 10. Phase 3 완료 조건 (프로젝트 완료)

프로젝트 완료를 위해 다음 조건을 **모두** 충족해야 합니다:

| 조건 | 기준 | 검증 방법 | 담당 |
|------|------|----------|------|
| **자동화율** | 80% 이상 | 입력 횟수 비교 | 운영팀 |
| **팟 정확도** | 100% (100핸드) | 수동 검증 | QA |
| **칩 정확도** | 99%+ | WSOP+ 비교 | QA |
| **시스템 안정성** | 8시간 99.9% | 모니터링 | 개발팀 |
| **운영자 승인** | 3명 서명 | 서명 문서 | 운영팀 |

---

## 11. 미래 확장 (Post-Phase 2)

Phase 2 완료 후 고려 가능한 확장:

| 기능 | 설명 | 우선순위 | 예상 효과 |
|------|------|:--------:|----------|
| AI 해설 | 자동 생성 해설 텍스트 | P2 | 시청자 경험 향상 |
| 하이라이트 자동 생성 | 빅 팟 클립 자동 추출 | P2 | 편집 시간 단축 |
| 예측 분석 | 플레이어 행동 예측 | P3 | 방송 연출 개선 |
| 음성 인식 | 딜러 음성으로 액션 입력 | P3 | 입력 완전 자동화 |
| 멀티 테이블 | 여러 테이블 동시 관리 | P2 | 확장성 |

---

## 12. 부록

### 12.1 관련 문서

- [Phase 1 PRD](../02_Phase01/PRD-0003-Phase1-PokerGFX-Clone.md)
- [Phase 2 PRD](../03_Phase02_ngd/PRD-0003-Phase2-WSOP-Integration.md)
- [Phase Progression Guide](../05_Operations_ngd/PHASE-PROGRESSION.md)

### 12.2 용어 정의

| 용어 | 정의 |
|------|------|
| 자동 적용 | 신뢰도 높은 추론을 자동으로 적용 |
| 제안 모드 | 추론 결과를 제안하고 운영자 확인 대기 |
| 수동 오버라이드 | 자동 계산값을 수동으로 수정 |
| 사이드 팟 | 올인 상황에서 분리되는 별도 팟 |
| 보정 | WSOP+ 값으로 EBS 데이터 수정 |

### 12.3 알고리즘 복잡도

| 알고리즘 | 시간 복잡도 | 공간 복잡도 |
|----------|-----------|-----------|
| 팟 계산 | O(1) per action | O(n) side pots |
| 사이드 팟 분리 | O(n log n) | O(n) |
| 칩 추적 | O(1) | O(n) players |
| 액션 추론 | O(1) | O(1) |

---

**Version**: 3.0.0 | **Updated**: 2026-02-03
