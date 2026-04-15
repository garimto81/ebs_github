---
title: Coalescence
owner: team3
tier: internal
legacy-id: BS-06-04
last-updated: 2026-04-15
---

# BS-06-04: Hold'em 트리거 Coalescence

> **존재 이유**: `lib/core/rules/coalescence.dart` 구현 사양 (RFID 버스트 병합 알고리즘).

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-06 | 신규 작성 | 트리거 정의 총괄 및 우선순위 규칙, coalescence 알고리즘 |
| 2026-04-06 | v2.0 전면 보강 | 경계 조건 정의, 상태별 활성 매트릭스, 유저 스토리, Matrix, 구현 가이드 확장 |
| 2026-04-06 | 표기법 → 문서 작성 규칙 적용 | 테이블 4열 제한, 상태값 bold/API 필드 백틱 일관 적용 |
| 2026-04-07 | 구조 → 번호 변경 | BS-06-00 → BS-06-06으로 재배치 |
| 2026-04-07 | 구조 → 섹션 재배치 | Quick Reference 상단 이동, 트리거 소스 통합, 에러/예외 통합, 구현 가이드 통합 |
| 2026-04-06 | 구조 → Hold'em 전용 변환 | Draw/Stud/Pineapple/Courchevel 계열 전체 제거, Flop game_class=0만 유지 |
| 2026-04-09 | doc-critic 개선: 용어 해설 추가 | 문서 서두 용어 해설 테이블, no-op/inclusive/debounce/flush 괄호 설명 추가 |

---

> **이 문서에서 사용하는 용어**
>
> | 용어 | 설명 |
> |------|------|
> | coalescence | 여러 센서 신호가 동시에 들어올 때 하나로 합치는 처리 규칙 |
> | FSM | 게임 진행 단계를 정의한 상태 흐름도 (Finite State Machine) |
> | RFID | 무선 주파수로 카드를 자동 인식하는 기술. 카드에 내장된 IC를 테이블 센서가 읽는다 |
> | CC | Command Center, 운영자가 게임을 제어하는 화면 |

## 개요

EBS 게임 엔진의 **3가지 입력 소스** — CC 버튼, RFID 감지, 게임 엔진 자동 전이가 동시 발생할 때의 우선순위와 충돌 해결 규칙을 정의한다. 이 문서는 개발팀이 "어떤 이벤트가 먼저 처리되는가"를 30초 내에 파악할 수 있도록 작성되었다.

**적용 범위**: 핸드 진행 중, `hand_in_progress` == true인 복수 트리거 이벤트. 단일 트리거 또는 **IDLE** 상태는 coalescence 적용 불필요.

> **WSOP LIVE 미정의 — 독립 설계**: Coalescence 개념과 ±100ms/200ms 윈도우는 WSOP LIVE Confluence 에 대응 규정 없음. RFID 하드웨어(12 안테나 burst 특성) 기인 EBS 고유 구현이며 정당화된 발산(justified divergence).

---

## 정의

**트리거 Coalescence** — 병합: 복수의 이벤트 소스가 동일 시간 창 ±100ms 내에 발생했을 때, 우선순위 규칙에 따라 하나의 유효한 상태 전이로 통합하는 프로세스. 나머지 이벤트는 **큐잉**(나중에 처리)하거나 **폐기**(무시)한다.

**핵심 목표**: 운영자 UI 응답성을 해치지 않으면서도 RFID 감지 데이터의 신뢰도를 최우선으로 유지한다.

---

## 우선순위 테이블 — Quick Reference

**상황별 우선순위 1순위 결정, ±100ms 윈도우 내**

| 상황 | 우선 처리 | 이유 |
|------|---------|------|
| RFID + CC 동시 | **기본**: RFID 우선. **예외**: CC가 `state_applied` == true이면 CC 우선 | 상태 변경 완료 예외 |
| RFID + Engine 동시 | **기본**: RFID 우선. **예외**: `runout_in_progress` == true이면 Engine 우선 | 올인 런아웃 중 Engine 자동 진행 |
| CC + Engine 동시 | **Engine**, 상태 이미 변경 | 순차 실행이 이미 완료됨 |
| CC 전송 완료 + CC 대기 중 | **전송 완료** | 네트워크 우선순위 |
| RFID 중복 | **폐기** | 100ms 내 같은 UID = 신호 반사 제거 |
| CC 중복 | **먼저 도착** | 나중은 **INVALID** 상태 |

---

## 트리거 소스 정의

### 3가지 입력 소스

| 트리거 유형 | 발동 주체 | 레이턴시 | 신뢰도 |
|-----------|---------|---------|--------|
| **CC 버튼** | 운영자, 수동 | < 50ms | 낮음 |
| **RFID 카드** | 시스템, 자동 | 50~150ms | 높음 |
| **게임 엔진** | 게임 엔진, 자동 | 결정론적 | 최고 |

### CC 버튼 — Command Center

**8가지 액션 버튼**:
| 버튼 | 전제조건 | 게임 상태 제약 |
|------|--------|-----------|
| NEW HAND | — | **IDLE** 또는 **HAND_COMPLETE** |
| DEAL | `biggestBet` == 0 | **SETUP** 상태 정확히 |
| FOLD | 액션 턴, `currentActor` | **PRE_FLOP**~**RIVER** |
| CHECK | `biggestBet` == 0 && action turn | 게임 진행 중 |
| CALL | `biggestBet` > 0 && action turn | 게임 진행 중 |
| BET | `biggestBet` == 0 && action turn | 게임 진행 중 |
| RAISE | `biggestBet` > 0 && action turn | 게임 진행 중 |
| ALL-IN | action turn | 게임 진행 중 |

**전송 정확도**: 버튼 클릭 → 네트워크 전송 → 서버 게임 엔진 상태 업데이트 완료까지 ≤100ms

**특수 케이스**:
- **금액 입력 모달 활성 중**: 새 버튼 클릭 무시
- **UNDO 진행 중**: 모든 새 입력 대기, UNDO 완료까지
- **키보드 단축키**: 버튼 클릭과 동일한 우선순위 적용

---

### RFID 카드 감지

**카드 감지 타입**:

| 타입 | 안테나 | 시점 | 대기 시간 |
|------|------|------|---------|
| **홀카드** | 좌석 개별 seat[i] | **SETUP** 단계, DEAL 후 | 100-200ms |
| **보드 카드** | 중앙 디스플레이 board antenna | **FLOP**/**TURN**/**RIVER** 공개 후 | 50-150ms |
| **덱 카드** | 덱 스캐너 deck antenna | NEW HAND 전 등록 | 2-3초 |

**감지 정확도**:
- **정상**: UID 매칭 성공 → 즉시 카드 기록
- **미인식**: 안테나 간섭, 카드 손상 → RFID_MISSING_CARD 에러
- **중복 감지**: 같은 카드 다시 감지, 신호 반사 → 폐기
- **오카드**: 예상과 다른 카드 감지 → WRONG_CARD 에러

**에러 복구 모드**:
- RFID 연속 에러 3회 → 수동 입력 모드 전환
- 수동 입력 모드 중: CC 버튼 "MANUAL CARD" 활성화
- 수동 입력 후 RFID 신호 도착 → 자동으로 비교 검증

---

### 게임 엔진 자동 전이

**자동 전이 조건**:

> 참고: 아래 상태명은 BS-06-01 GamePhase와 매핑. `_PENDING`은 "베팅 완료 후 보드 카드 대기 중" 상태를 coalescence 관점에서 구분한 것이며, BS-06-01의 공식 상태는 괄호 안에 표기.

| 트리거 | 사전 상태 | 다음 상태 (BS-06-01 공식명) | 실행 시점 |
|-------|---------|--------------------------|---------|
| **베팅 완료** | **PRE_FLOP**, 모두 매칭 | 보드 대기 (→ **FLOP**) | 마지막 액션 처리 후 즉시 |
| **보드 카드 감지** | 보드 대기 | **FLOP** / **TURN** / **RIVER** | RFID 보드 감지 완료 후 |
| **올인 런아웃** | 모두 올인 | → **SHOWDOWN** | 자동 계산 시작, RFID 무관 |
| **쇼다운 진행** | **RIVER** 베팅 완료 | **SHOWDOWN** | CC "SHOWDOWN" 버튼 |
| **팟 분배** | **SHOWDOWN** 완료 | **HAND_COMPLETE** | 자동 실행 |

**제약**:
- 올인 런아웃: RFID 보드 감지 여부와 관계없이 자동 딜, 운영자 개입 불가
- 쇼다운: CC 버튼 필수, 자동 진행 불가, 운영자 의도 확인

---

## 적용 조건

### 전제조건

다음 모든 조건이 참일 때만 coalescence 규칙 적용:

1. **`hand_in_progress` == true** — 핸드 진행 중
2. **2개 이상의 서로 다른 소스 트리거 발생**
3. **시간 윈도우 ±100ms 내에 도착**
4. **게임 상태가 유효한 다음 액션 허용**

### 비활성 조건

1. **`hand_in_progress` == false** — 테이블 **IDLE**
2. **RFID 에러 모드 활성** — 수동 입력 모드 실행 중
3. **HAND_COMPLETE** 상태 — 모든 새 입력 거부
4. **모달 다이얼로그 활성** — RFID 감지 대기, CC 입력 모두 금지
5. **단일 트리거만 발생** — 충돌 없음, 즉시 처리

### 상태별 Coalescence 활성 매트릭스

| 상태 | 허용 입력 | 예상 RFID | 버퍼 동작 |
|------|---------|----------|----------|
| **IDLE** `coalescence_active` = false | NEW HAND | 없음, 버퍼 저장 | RFID 버퍼 저장, 다음 핸드 시 처리 |
| **SETUP_HAND** `coalescence_active` = true | DEAL | Hole card | 표준 100ms |
| **PRE_FLOP**~**RIVER** `coalescence_active` = true | FOLD, CHECK, BET, RAISE, CALL, ALL-IN | Board card | 표준 100ms — Engine 자동: 베팅 완료 → 다음 스트리트 |
| **SHOWDOWN** `coalescence_active` = true | **SHOWDOWN** | 없음 | 표준 100ms — Engine 자동: 핸드 평가 → **HAND_COMPLETE** |
| **HAND_COMPLETE** `coalescence_active` = false | NEW HAND | 없음, 폐기 | RFID 버퍼 flush(버퍼에 쌓인 데이터를 모두 비우기) |

> 참고: 이 매트릭스에 없는 조합은 해당 상태에 존재하지 않으므로 이벤트 수신 시 **STATE_CONFLICT** 에러를 발생시킨다.

---

## Coalescence 규칙

### Rule 1: 시간 창 정의

**이벤트 클러스터링 시간 창 = ±100ms**

- 첫 번째 이벤트 t₀에서 t₀-100ms ~ t₀+100ms 내에 도착한 모든 이벤트 = 동시 이벤트로 간주
- 이 윈도우 내의 이벤트들만 coalescence 규칙 적용
- 윈도우 외 도착 이벤트 = 순차 처리, 별도 큐

**근거**: RFID 리더 지연 50~150ms + 네트워크 지연 ≤50ms + UI 입력 지연 ≤50ms 고려

**경계 조건**:

| 조건 | 동작 | 상세 |
|------|------|------|
| t₀+100ms 시점 도착 | **윈도우 포함** — inclusive(경계값 포함) | t₀+100ms = 현재 윈도우 |
| 빈 윈도우 | **no-op(아무 동작도 하지 않음)** | 타이머 만료 시 처리 대상 없음 |
| 큐 오버플로우 | **최저 우선순위 폐기** | `MAX_QUEUE_SIZE` = 32 |
| 처리시간 > 100ms | **`processing_in_progress` 플래그** | 새 이벤트는 새 윈도우로 분리 |

### Rule 2: 우선순위 계층

**계층 1 — 가장 높음: RFID 카드 감지**
- 이유: 물리 증거, 운영자 입력보다 신뢰도 높음
- 조건: **새로운 미처리 카드 감지**만 적용

**계층 2: CC 버튼, 전송 완료**
- 이유: 사용자 의도 명시, 게임 상태 이미 업데이트됨
- 조건: **버튼 클릭이 이미 네트워크 전송 완료**한 경우만

**계층 3: 게임 엔진 자동 전이**
- 이유: 규칙 기반, 상태 이미 변경됨
- 조건: **베팅 완료 감지, 올인 런아웃, 쇼다운 진행** 등 자동 조건 충족

#### 상태 변경 완료 예외

| 예외 | 조건 | 결과 | 근거 |
|------|------|------|------|
| **CC 전송 완료** | `state_applied` == true | RFID보다 CC 우선, RFID는 큐잉 | 상태 롤백 비용이 높음 |
| **올인 런아웃** | `runout_in_progress` == true | RFID보다 Engine 우선, RFID는 검증용 | 런아웃은 RFID 무관 자동 진행 |

**판단 흐름**:
```
이벤트 A, B가 ±100ms 내 도착
  ├─ A 또는 B가 이미 state_applied? → YES → 이미 적용된 이벤트 우선
  ├─ A 또는 B가 runout_in_progress? → YES → Engine 런아웃 우선
  └─ 둘 다 미적용 → 계층 순서 적용: RFID > CC > Engine
```

> 참고: `state_applied`는 서버가 상태 변경 ACK를 반환한 시점에서 true가 된다.

**계층 4 — 가장 낮음: 동일 소스 내 순서**
- RFID 복수 카드 = 좌석 번호 오름차순
- CC 버튼 복수 = 타임스탬프 오름차순
- 게임 엔진 복수 전이 = 상태 머신 정의 순서

#### RFID 서브 우선순위

| 서브 우선순위 — 높음 → 낮음 | 근거 |
|--------------------------|------|
| Hole card > Board card | 좌석 배정 우선, 보드는 공유 카드 |

### Rule 3: Coalescence 동작

#### A. 동일 우선순위 내 충돌

**사례 1: RFID 2개 카드 동시 감지**
```
Event A: 좌석 3 홀카드 감지 @ t=100ms
Event B: 좌석 5 홀카드 감지 @ t=105ms
=> 좌석 3 먼저 처리, 좌석 5 100ms 후 처리
```

**사례 2: CC 버튼 2개 동시 클릭**
```
Event A: FOLD 버튼 @ t=500ms
Event B: CALL 버튼 @ t=510ms
=> 먼저 도착한 FOLD 처리, CALL은 INVALID 처리
```

#### B. 다른 우선순위 간 충돌 → Rule 2 적용

**사례 3: CC BET 버튼 vs RFID 보드 카드**
```
Event A (계층 2): CC BET @ t=1000ms [이미 전송됨]
Event B (계층 1): RFID Flop 카드 감지 @ t=1050ms
=> BET 우선 처리 (네트워크 전송 완료됨)
=> RFID 감지는 다음 사이클에서 처리
```

**사례 4: 게임 엔진 자동 전이 vs CC FOLD 버튼**
```
Event A (계층 3): 베팅 완료 → Flop 공개 @ t=2000ms
Event B (계층 2): 운영자 FOLD 클릭 @ t=2005ms [아직 전송 중]
=> Flop 공개 우선 (상태 이미 변경)
=> FOLD는 REJECTED (이미 스트리트 변경됨)
```

#### C. 대기 vs 폐기

**대기해야 할 이벤트**:
- RFID 감지 during CC 버튼 모달 → 모달 닫힐 때까지 RFID 버퍼 유지
- CC 버튼 during 게임 엔진 자동 전이 → 엔진 상태 안정화 후 큐 처리

**폐기해야 할 이벤트**:
- 중복 RFID 감지 (같은 카드 UID, 100ms 내)
- 이미 폴드한 플레이어 입력 추가
- NEW_HAND 직후 이전 핸드 RFID 신호

---

## 시나리오

### 유저 스토리

#### Category 1: RFID vs CC 충돌

| # | 상황 | 처리 | 엣지 케이스 |
|:-:|------|------|-----------|
| 1 | 운영자가 FOLD 버튼 클릭 중 RFID가 보드 카드 감지 | RFID 감지 먼저 처리. FOLD는 큐에 대기 | RFID 감지가 예상 카드가 아닐 시 **WRONG_CARD** |
| 2 | 운영자가 BET 버튼을 누른 후 전송 완료 시 RFID 홀카드 감지 | BET 처리 먼저 완료. RFID는 다음 사이클 | BET가 아직 pending이면 RFID 우선 |
| 3 | 운영자가 CALL 버튼 입력 시 상대방 카드 RFID 감지 | CALL 우선 처리. RFID는 100ms 후 | 네트워크 지연 100ms 초과 시 RFID 먼저 |
| 4 | 운영자가 RAISE 금액 입력 모달 활성 중 RFID 보드 카드 감지 | RFID 감지 대기, 모달 활성 중 기록 불가 | 모달 닫힌 후 RFID 버퍼에서 자동 처리 |
| 5 | 운영자가 ALL-IN 클릭 중 RFID가 홀카드 감지 | 올인 이미 처리됨 → RFID 먼저, 올인 모달 열림 → RFID 대기 | — |

#### Category 2: 게임 엔진 자동 전이 vs CC

| # | 상황 | 처리 | 엣지 케이스 |
|:-:|------|------|-----------|
| 6 | 운영자가 CHECK 직후 Flop 공개 | CHECK 먼저 처리. Flop 공개는 다음 사이클 | CHECK가 마지막 액션이면 즉시 발동 |
| 7 | 시스템이 모두 올인 후 RFID가 보드 감지 | 런아웃 자동 전이 우선. RFID는 검증용 | RFID 감지 카드 ≠ 자동 딜 카드 시 경고만 |
| 8 | 운영자가 FOLD 중 다음 스트리트 자동 전이 | FOLD 먼저 → 전이, 전이 먼저 → FOLD **REJECTED** | — |
| 9 | 운영자가 NEW HAND 버튼 클릭 | 이전 핸드 RFID 잔여 신호 전부 flush | — |
| 10 | 운영자가 UNDO 실행 중 RFID 새 카드 감지 | UNDO 완료까지 RFID 감지 대기 | UNDO 롤백 후 새 감지 처리 |

#### Category 3: RFID 내부 충돌

| # | 상황 | 처리 | 엣지 케이스 |
|:-:|------|------|-----------|
| 11 | 2개 안테나에서 동시 카드 감지 | 좌석 안테나 홀카드 우선 | — |
| 12 | 같은 카드 UID 중복 감지, 100ms 내 | 첫 감지만 기록, 두 번째 폐기 | — |
| 13 | **FLOP** 공개 후 보드 카드 한 번에 감지 | 카드 배치 순서로 처리 | 순서 섞이면 도착 순서 사용 |
| 14 | 홀카드 감지 중 다른 좌석 홀카드도 감지 | 좌석 번호 순서 처리 | — |

#### Category 4: CC 내부 충돌

| # | 상황 | 처리 | 엣지 케이스 |
|:-:|------|------|-----------|
| 15 | CALL 후 즉시 RAISE 클릭 | 먼저 도착한 CALL 처리, RAISE **INVALID** | — |
| 16 | CHECK와 FOLD 동시 클릭 | 타임스탬프 순서, 두 번째 **INVALID** | — |

#### Category 5: 특수 상황

| # | 상황 | 처리 | 엣지 케이스 |
|:-:|------|------|-----------|
| 17 | Run It Twice 합의 후 첫 보드 딜 | 엔진 보드 딜 우선, RFID는 선택사항 | — |
| 18 | Bomb Pot **PRE_FLOP** 스킵 + RFID 보드 감지 | 스킵 먼저 실행, RFID는 **FLOP** 상태에서 처리 | — |
| 19 | 2명 운영자가 동시에 ALL-IN | 네트워크 도착 순서, 동시 도착 시 seat index 낮은 쪽 | — |
| 20 | **HAND_COMPLETE** 직후 RFID 새 카드 감지 | 무시, 버퍼 flush | — |

#### Category 6: 복합 충돌

| # | 상황 | 처리 | 엣지 케이스 |
|:-:|------|------|-----------|
| 21 | CC BET + RFID board + Engine 자동 전이, 3-source 동시 | state_applied 먼저 확인. 미적용이면: RFID → CC → Engine | `runout_in_progress`면 Engine 우선 |
| 22 | UNDO 중 RFID + CC FOLD | UNDO 완료까지 모두 대기, 완료 후 폐기 | 롤백 상태에서 대기 이벤트가 무효 가능 |
| 23 | Miss Deal 후 RFID 버퍼 잔여 | 버퍼 전체 무효화, 새 **SETUP_HAND** 초기화 | flush 중 새 RFID 도착 시 새 윈도우 |
| 24 | RFID 에러 모드 전환 중 새 RFID 도착 | 전환 완료까지 무시 | 전환 중간 도착한 RFID 폐기 |
| 25 | 네트워크 단절 중 CC 로컬 큐잉 + RFID 정상 | RFID 로컬 처리, CC 로컬 큐 저장, 복구 후 순차 전송 | 복구 후 불일치면 **REJECTED** |
| 26 | 설정 변경 중 RFID 감지 | 모달 활성 중 RFID 대기 | 설정 변경이 상태 영향 시 RFID 유효성 재검증 |
| 27 | UI lag 중 CC 버튼 클릭 | Engine 상태 기준 유효성 판단 | **STATE_SYNC_WARNING** 표시 |
| 28 | 크로스 좌석 RFID 감지 | **WRONG_CARD** 에러, 폐기 | 올바른 좌석 재감지 시 정상 처리 |
| 29 | 연속 UNDO 3회 | 각 UNDO 사이 윈도우 초기화 | UNDO 중 다른 입력 차단 |
| 30 | 샷클록 만료와 CC FOLD 동시 도착 | 먼저 `state_applied`된 쪽 유효, 나머지 DUPLICATE_ACTION 폐기 | 결과 동일 (FOLD) |

#### Category 7: 다중 운영자

| # | 상황 | 처리 | 엣지 케이스 |
|:-:|------|------|-----------|
| 31 | 운영자 A가 좌석 2 FOLD, B가 좌석 5 CALL | 정상: 다른 좌석이므로 충돌 없음 | 같은 액션 턴이면 `currentActor` 기준 |
| 32 | A가 좌석 3 BET, B가 같은 좌석 3 RAISE | 먼저 도착 처리, 나중 **REJECTED** | 운영 에러, 에러 로그 기록 |
| 33 | A가 UNDO 중 B가 FOLD 입력 | UNDO 완료까지 차단 | 전체 핸드 상태 일관성 보호 |

### 경우의 수 매트릭스

#### Matrix 1: Trigger A x Trigger B x GamePhase → Resolution

##### Hold'em — **PRE_FLOP** 라운드

| 트리거 조합 | 시간차 | 처리 순서 | 결과 |
|-----------|-------|---------|------|
| CC DEAL + RFID hole | 50ms | A → B | 정상 DEAL 흐름 |
| RFID hole[0] + RFID hole[1] | 30ms | A → B | 좌석 순서 |
| RFID hole[1] + RFID hole[0] | 10ms | B → A | 작은 좌석 우선 |
| CC FOLD + RFID board | 80ms | B → A | A 큐잉 |
| CC CHECK + RFID hole | 60ms | A → B | CHECK 우선 |
| Engine FLOP + CC FOLD | 50ms | A → B | B **REJECTED** |
| Engine FLOP + RFID board | 40ms | B → A | RFID가 **FLOP** 상태에서 기록 |

##### Hold'em — **FLOP**/**TURN**/**RIVER** 라운드

| 트리거 조합 | 시간차 | 처리 순서 | 결과 |
|-----------|-------|---------|------|
| CC RAISE + RFID board | 120ms | A → B | CC 모달 모드면 B 우선 |
| Engine 다음 라운드 + CC 버튼 | 30ms | A → B | B **REJECTED** |
| RFID board[0] + RFID board[1] | 10ms | A → B | 보드 순서대로 |
| CC BET + CC CALL 다른 운영자 | 5ms | A → B | 순차 처리 |

##### All-In 시나리오

| 트리거 조합 | 시간차 | 처리 순서 | 결과 |
|-----------|-------|---------|------|
| CC ALL-IN + Engine **RUNOUT** | 10ms | A → B | 정상 |
| CC ALL-IN[seat1] + CC ALL-IN[seat2] | 30ms | A → B | 도착 순서 |
| Engine **RUNOUT** + RFID board | 50ms | A → B | RFID는 검증용 |
| Engine **RUNOUT** + CC FOLD | 20ms | A → B | B **REJECTED** |

##### Special — Run It Twice, Bomb Pot

| 트리거 조합 | 시간차 | 처리 순서 | 결과 |
|-----------|-------|---------|------|
| Engine Bomb Pot **PRE_FLOP** 스킵 + RFID board | 100ms | A → B | B는 **FLOP** 상태에서 처리 |
| Engine Run It Twice 1st + RFID board | 60ms | A → B | 1차 → 2차 순차 |
| CC **SHOWDOWN** + Engine eval | 40ms | A → B | CC 트리거 후 엔진 평가 |

---

## 에러 및 예외 처리

### 에러 유형별 coalescence 영향

| 에러 | 원인 | coalescence 처리 |
|------|------|----------------|
| **RFID_MISSING_CARD** | 카드 미감지 | 이벤트 폐기, 타임아웃 후 수동 입력 |
| **WRONG_CARD** | 예상 ≠ 감지 | 경고만, 게임 진행 |
| **CC_BUTTON_TIMEOUT** | 전송 실패 | CC 이벤트 폐기, RFID만 처리 |
| **DUPLICATE_RFID** | 신호 반사 | 이벤트 폐기 |
| **STATE_CONFLICT** | 유효성 오류 | **REJECTED**, 다음 유효 액션 대기 |

### 복구 절차

1. **RFID 연속 에러** — 3회 이상
   - 수동 입력 모드 전환, RFID 버퍼 flush

2. **CC 네트워크 에러**
   - 로컬 버튼 상태 유지, 재전송 3회, 실패 시 수동 입력

3. **Coalescence 윈도우 타임아웃**
   - 100ms 경과 후 처리 시작, 후속은 새 윈도우

### 핸드 간 전이 Coalescence

| 시점 | 동작 | 상세 |
|------|------|------|
| HAND_COMPLETE 진입 즉시 | **RFID 버퍼 전체 flush** | 이전 핸드 미처리 이벤트 폐기 |
| HAND_COMPLETE 진입 즉시 | **CC 이벤트 큐 clear** | 미처리 CC 이벤트 폐기 |
| HAND_COMPLETE 진입 즉시 | **debounce(같은 신호의 반복 입력을 일정 시간 차단) map 리셋** | 새 핸드에서 같은 UID 재사용 가능 |
| HAND_COMPLETE → NEW HAND | **새 윈도우 시작** | 첫 이벤트 NEW HAND가 t₀ |

#### 빠른 연속 핸드

1. **HAND_COMPLETE** flush 완료 전에 NEW HAND 도착 → flush 완료까지 **대기**
2. flush 완료 후 NEW HAND 처리 → **SETUP_HAND** 진입
3. 이전 핸드 잔여 RFID 신호 → **폐기**

#### 덱 스캔 오버랩

1. 덱 스캔 모드 중 `deck_scan_in_progress` = true
2. 좌석/보드 안테나 RFID → **폐기**, 덱 안테나만 처리
3. 덱 스캔 완료 후 정상 coalescence 재개

### 에러 복구 Coalescence

#### RFID 에러 모드 종료 후 재개

| 단계 | 동작 | 상세 |
|------|------|------|
| 수동 입력 완료 | `rfid_error_mode` = false | 수동 입력 카드 등록 완료 |
| RFID 재개 | 버퍼 flush 후 새 윈도우 | 에러 모드 중 도착 이벤트 전체 폐기 |
| 검증 | 수동 vs RFID 재감지 비교 | 불일치 시 **WRONG_CARD**, 수동 값 유지 |

#### Miss Deal 후 초기화

1. 모든 게임 상태 초기화 → **IDLE** 복귀
2. RFID 버퍼 전체 무효화
3. debounce map 리셋
4. Miss Deal 중 RFID/CC 이벤트 모두 **폐기**

#### 네트워크 재연결

| 단절 시간 | CC 로컬 큐 | RFID 버퍼 | 복구 동작 |
|-----------|-----------|----------|----------|
| < 30초 | **보존** | **보존** | 재연결 후 순차 전송, 유효성 검증 |
| ≥ 30초 | **폐기** | **폐기** | 전체 상태 동기화, **RESYNC_REQUIRED** |

---

## 구현 가이드

### 버퍼 관리 알고리즘

```
Event Q = []  # coalescence 윈도우 내 모든 이벤트

On EventArrival(event):
  if Event Q is empty:
    t_window_start = current_time
    t_window_end = t_window_start + 100ms
    Event Q.append(event)
    Schedule(process_coalesced_events, delay=100ms)
  else if current_time <= t_window_end:
    Event Q.append(event)
  else:
    ProcessWindow(Event Q)
    Event Q = [event]
    Reschedule(process_coalesced_events, delay=100ms)

On process_coalesced_events():
  SortByPriority(Event Q)  # Rule 2 우선순위 적용
  for event in Event Q:
    if ShouldDiscard(event):
      continue
    if ShouldQueue(event):
      Queue(event)
    else:
      Process(event)
```

### Debounce 구현

```
RFID_debounce_map = {}  # {card_uid: last_timestamp}

On RFID_detection(card_uid, timestamp):
  if card_uid in RFID_debounce_map:
    if timestamp - RFID_debounce_map[card_uid] < 100ms:
      return DISCARD
  RFID_debounce_map[card_uid] = timestamp
  return ADD_TO_QUEUE
```

### UNDO 버퍼 flush

```
On UNDO_requested():
  undo_in_progress = true
  for event in Event_Q:
    event.status = BLOCKED
  Execute_UNDO()
  Event_Q.clear()
  undo_in_progress = false
```

### RFID 에러 모드 전환

```
On RFID_error_count >= 3:
  rfid_error_mode = true
  RFID_buffer.flush()
  Enable_manual_card_input()

On Manual_card_input_complete():
  rfid_error_mode = false
  RFID_buffer.flush()
  RFID_debounce_map.clear()
  Resume_RFID_detection()
```

### HAND_COMPLETE flush

```
On HAND_COMPLETE():
  Event_Q.clear()
  RFID_buffer.flush()
  RFID_debounce_map.clear()
  processing_in_progress = false
  Log("HAND_COMPLETE: all buffers flushed")
```

### MAX_QUEUE_SIZE 보호

```
MAX_QUEUE_SIZE = 32

On EventArrival(event):
  if len(Event_Q) >= MAX_QUEUE_SIZE:
    lowest = find_lowest_priority(Event_Q)
    Event_Q.remove(lowest)
    Log("QUEUE_OVERFLOW: discarded", lowest)
  Event_Q.append(event)
```

### 영향 받는 요소

#### 게임 상태 머신
- **상태 전이 조건**: coalescence 규칙이 상태 진입 조건을 변경
- **액션 유효성**: **INVALID** 액션 큐잉 시 상태 머신 재확인

#### 오버레이 갱신
- **갱신 순서**: coalescence가 UI 렌더링 순서 결정

#### RFID 모듈
- **버퍼 관리**: coalescence 윈도우와 RFID 버퍼 동기화
- **에러 추적**: 중복/폐기 이벤트를 에러 로그에 기록

#### Command Center 버튼
- **모달 중 버튼 상태**: 금액 입력 모달 활성 중 다른 버튼 비활성화
- **UNDO 모드**: UNDO 진행 중 모든 새 액션 버튼 비활성

### 구현 체크리스트

- [ ] coalescence 100ms 윈도우 구현
- [ ] Rule 2 우선순위 정렬, 계층 1~4
- [ ] RFID 중복 제거, `card_uid` 기반
- [ ] CC 버튼 모달 중 RFID 대기 로직
- [ ] UNDO 진행 중 새 입력 차단
- [ ] 타임아웃 발생 시 버퍼 플러시
- [ ] 에러 로그: 폐기/큐잉 이벤트 기록
- [ ] 상태 머신 전이 조건: coalescence 확인
- [ ] 오버레이 갱신: 우선순위 반영
- [ ] 테스트: 시나리오 Matrix 커버
- [ ] 경계 조건: t₀+100ms inclusive 검증
- [ ] 경계 조건: 빈 윈도우 no-op 검증
- [ ] `MAX_QUEUE_SIZE` = 32 초과 시 최저 우선순위 폐기
- [ ] `processing_in_progress` 플래그 동작 검증
- [ ] RFID 서브 우선순위: Hole card > Board card
- [ ] **HAND_COMPLETE** 버퍼 flush — RFID + CC + debounce map
- [ ] 빠른 연속 핸드: flush 완료 전 NEW HAND 대기
- [ ] 덱 스캔 오버랩: `deck_scan_in_progress` 중 좌석/보드 RFID 폐기
- [ ] RFID 에러 모드 전환/복귀 시 버퍼 flush
- [ ] Miss Deal 후 전체 초기화
- [ ] 네트워크 재연결: 30초 미만 보존, 30초 이상 폐기
- [ ] 3-source 동시 충돌 우선순위 정렬
- [ ] UNDO 중 모든 새 입력 차단 + 완료 후 폐기
- [ ] 다중 운영자: 같은 좌석 중복 입력 **REJECTED**
