# CCR-DRAFT: BS-05 Multi-Table 운영자 시나리오 명시

- **제안팀**: team4
- **제안일**: 2026-04-10
- **영향팀**: [team1]
- **변경 대상 파일**: contracts/specs/BS-05-command-center/BS-05-10-multi-table-ops.md, contracts/specs/BS-05-command-center/BS-05-00-overview.md
- **변경 유형**: add
- **변경 근거**: 이전 critic 분석에서 W7(다중 테이블 운영자 시나리오 없음)으로 식별된 공백. WSOP LIVE 등 대형 대회는 **1명의 운영자가 여러 테이블을 동시에 관리**하는 경우가 일반적이지만, 현재 BS-05는 "1 CC = 1 Table = 1 Overlay"의 1:1:1 대응만 정의하고 운영자 측면의 다중 테이블 관리는 미정의다. 이로 인해 (1) 운영자가 다중 CC 인스턴스를 어떻게 전환하는지, (2) 핸드 충돌 시 어느 테이블을 우선하는지, (3) 키보드 단축키 포커스 처리 등이 불명확하다. 본 CCR은 이 공백을 명시적으로 해소한다.

## 변경 요약

1. `BS-05-10-multi-table-ops.md` 신규: 다중 테이블 운영 패턴 3가지와 권장 모드, 단축키 충돌 해결, 알림/경고 정책
2. `BS-05-00-overview.md` §운영 패턴 섹션 추가: 1:1:N(운영자) 및 1:1:1(테이블) 관계 명시

## 변경 내용

### 1. BS-05-10-multi-table-ops.md (신규 파일)

```markdown
# BS-05-10 Multi-Table Operator Scenarios

> **참조**: BS-05-00-overview §앱 정의, BS-02-lobby §운영자 할당

## 원칙

EBS는 "1 CC = 1 Table = 1 Overlay" 인스턴스 관계를 유지한다. 그러나 **1명의 운영자**는 
여러 테이블을 동시에 관리할 수 있으며, 이 경우 **다중 CC 인스턴스**를 띄운다.

- 1:1:1 = CC : Table : Overlay (기술적 인스턴스)
- 1:N = Operator : CC 인스턴스 (운영 관계)

## 운영 패턴 3가지

### Pattern A: 단일 테이블 전담 (Single Table Operator)

**설명**: 1명 = 1 테이블 전담. 대규모 대회의 Feature Table(방송 메인 테이블) 운영.

- CC 인스턴스: 1개
- 키보드 포커스: 항상 단일 CC
- 장점: 집중도 최고, 실수 최소
- 단점: 운영자 수 = 테이블 수 (비용 高)

**사용**: WSOP 메인 이벤트 파이널 테이블, EPT 메인 테이블

### Pattern B: 다중 테이블 순회 (Rotating Multi-Table)

**설명**: 1명 = 2~4 테이블 관리. 운영자가 테이블 간 Alt+Tab으로 전환.

- CC 인스턴스: 2~4개 (같은 머신 또는 인접 머신)
- 키보드 포커스: 활성 CC만 단축키 수신
- 장점: 인건비 절감
- 단점: 전환 오버헤드, 액션 놓침 가능성

**사용**: 서브 대회, 예선, Day 1 단계

### Pattern C: 원격 Supervisor (Remote Supervisor)

**설명**: Lobby 모니터링 뷰만 보고, 개입 필요 시 해당 CC Launch.

- CC 인스턴스: 0개 (상시) → 필요 시 N개
- 키보드 포커스: Lobby
- 장점: 대규모 동시 감시 (10+ 테이블)
- 단점: 즉각 대응 불가

**사용**: Tournament Director 역할, 분쟁 조정

## 본 계약의 범위

**Phase 1**: Pattern A, B 지원. Pattern C는 BS-02 Lobby 모니터링 뷰와 연계 (BS-02 범위).

## CC 인스턴스 관리

### 식별자

각 CC 인스턴스는 다음으로 식별:

- `cc_instance_id`: UUID (앱 시작 시 생성)
- `table_id`: 담당 테이블 ID
- `operator_id`: 로그인한 운영자 ID

### 동일 운영자, 다중 CC

동일 `operator_id`로 여러 CC 인스턴스가 BO에 연결 가능.
BO는 `operator_id × table_id` 조합이 유일함을 보장 (동일 운영자가 같은 테이블에 2개 CC 띄우기 금지).

### 운영자 권한 전환

운영자 A가 Table 5를 담당하다가 B에게 인계:

```
1. A가 CC Table 5에서 "Transfer to..." 메뉴 → B 선택
2. BO가 B에게 "Take over Table 5" 알림 전송
3. B가 Lobby에서 Table 5 Launch → B의 CC 인스턴스 생성
4. A의 CC 인스턴스는 "Read-Only" 모드로 전환 (10초 후 자동 종료)
5. B는 A의 인계 시점 상태부터 이어서 운영
```

## 키보드 포커스 처리

### Pattern B에서의 포커스

- 운영 체제(Windows/macOS/Linux)가 각 CC 창의 포커스를 관리
- 활성 CC만 키보드 이벤트 수신 (Flutter `FocusNode` 표준 동작)
- 비활성 CC는 WebSocket 이벤트 계속 수신 (상태 갱신은 지속)

### 포커스 전환 시 상태 유지

- 운영자가 Alt+Tab으로 CC A → CC B 전환
- CC A의 진행 중 액션 입력(BET amount 중)은 Local State 유지
- 포커스 복귀 시 입력 이어서 계속
- 주의: CC A가 "BET 중"이면 AT-01에 경고 표시 ("Pending input in Table 5")

## 핸드 충돌 시 우선순위

**시나리오**: CC A(Table 5)와 CC B(Table 7)가 동시에 액션 발생.

- **원칙**: 각 CC는 독립 WebSocket 연결이므로 충돌 없음. BO가 각각 처리.
- **알림**: Engine이 각 테이블의 상태를 독립 관리 (Game Engine은 테이블별 인스턴스)

**충돌 가능성**: 없음 (서로 다른 테이블). BO의 `table_id` 기반 라우팅으로 격리.

## 알림 및 경고

### 활성 알림

운영자가 CC B를 보고 있는 동안 CC A에서 액션 필요 발생 시:

```
CC A (백그라운드)
  │
  ├─ ActionOnResponse 수신 (action_on = Seat 3)
  │
  ├─ Window Title에 빨간 느낌표 (!) 표시
  │
  ├─ 시스템 알림 (OS 레벨)
  │   └─ "Table 5: Action required on Seat 3"
  │
  └─ Sound 알림 (Effect Channel #2, 짧은 beep)
      (설정에서 비활성 가능)
```

### 알림 우선순위

| 이벤트 | 우선순위 | 알림 방식 |
|-------|:-------:|---------|
| ActionOnResponse (내 차례) | HIGH | Title + OS 알림 + Sound |
| CardDetected (RFID) | LOW | Title만 |
| BO 연결 끊김 | CRITICAL | OS 알림 + 배너 + Sound |
| RFID 리더 오류 | HIGH | OS 알림 + Sound |
| Hand Complete | MEDIUM | Title만 |

### Do Not Disturb 모드

Pattern B 운영자가 짧은 시간 집중이 필요할 때:

- M-01 Toolbar → "DND" 토글
- 활성화 시: 모든 비활성 CC의 OS 알림/사운드 비활성
- 해제 시: 즉시 복구
- 최대 지속: 10분 (자동 해제)

## 권장 사항

### 최대 권장 동시 관리 수

- Pattern A: 1 (전담)
- Pattern B: 4 (이보다 많으면 오류 증가)
- Pattern C: 20 (Lobby 모니터링만)

### 해상도 권장

Pattern B에서 다중 CC를 동시에 띄우려면:
- 최소: 1920×1080 (2 CC 가능, 각각 720×auto)
- 권장: 2560×1440 또는 3840×2160 (4 CC 가능)
- 대화면: 다중 모니터 지원 (각 모니터에 1~2 CC)

### Pattern B 베스트 프랙티스

- CC 창은 반드시 Full Visible (최소화 금지 권장)
- 타이틀 바 색상 차별화 (테이블별 고유 색)
- 사운드 알림 활성 유지

## 구현 위치

- `team4-cc/src/lib/features/command_center/services/focus_manager.dart`
- `team4-cc/src/lib/features/command_center/services/notification_service.dart`
- `team4-cc/src/lib/foundation/configs/dnd_config.dart`

## 참조

- BS-05-00-overview §운영 패턴 (본 CCR에서 추가)
- BS-02-lobby §운영자 할당
- BS-02-lobby §활성 CC 모니터링 (Pattern C 연계)
- BS-05-06-keyboard-shortcuts §포커스 처리
```

### 2. BS-05-00-overview.md §운영 패턴 (신규 섹션)

```markdown
## 운영 패턴

> **참조**: BS-05-10-multi-table-ops.md

EBS는 "1 CC = 1 Table = 1 Overlay"의 **기술적 인스턴스 관계**를 유지하지만,
**1명의 운영자**는 여러 CC 인스턴스를 동시 관리할 수 있다.

### 지원 패턴

| 패턴 | 운영자 : 테이블 | Phase 1 지원 | 사용 사례 |
|------|:-------------:|:----------:|---------|
| A. 단일 전담 | 1:1 | ✅ | 파이널 테이블 |
| B. 다중 순회 | 1:2~4 | ✅ | 예선, Day 1 |
| C. 원격 Supervisor | 1:N (모니터링) | ⚠️ BS-02 Lobby 담당 | Tournament Director |

### 다중 CC 관리 원칙

- 동일 운영자 × 동일 테이블 = 1 CC 인스턴스 (중복 금지)
- 각 CC는 독립 WebSocket 연결, 독립 상태 관리
- 알림/포커스는 BS-05-10 §알림 및 경고 참조
```

## 영향 분석

### Team 1 (Lobby/Frontend)
- **영향**:
  - Pattern C (원격 Supervisor)는 Lobby 모니터링 뷰와 연계 → BS-02-lobby에 해당 섹션 추가 필요 (후속 CCR)
  - BS-02의 "활성 CC 모니터링" 섹션과 Cross-reference
- **예상 리뷰 시간**: 2시간

### Team 4 (self)
- **영향**:
  - `lib/features/command_center/services/focus_manager.dart` 구현
  - OS 알림 (Windows: Toast, macOS: NSNotification, Linux: libnotify)
  - DND 토글 UI (M-01 Toolbar)
  - 다중 CC 인스턴스 간 독립성 확인 (Riverpod scoping)
- **예상 작업 시간**:
  - Focus Manager: 4시간
  - OS 알림: 8시간 (플랫폼별)
  - DND: 2시간
  - 통합 테스트: 4시간
  - 총 18시간

### 마이그레이션
- 없음

## 대안 검토

### Option 1: 다중 테이블 패턴 미정의 (현행)
- **단점**: W7 공백 유지, 운영자별 자의적 관리 방식
- **채택**: ❌

### Option 2: BS-05-10 신규 작성 (본 제안)
- **장점**: Pattern A/B 지원 명시 + 알림/포커스 표준화
- **채택**: ✅

### Option 3: 다중 CC 금지 (1 운영자 1 CC 강제)
- **단점**: 
  - 대규모 대회 인건비 비현실적
  - WSOP/PokerGFX 표준 운영 방식과 불일치
- **채택**: ❌

## 검증 방법

### 1. 다중 인스턴스 독립성
- [ ] 동일 머신에 CC Table 5 + CC Table 7 동시 실행
- [ ] 각각 독립 Riverpod ProviderScope 유지
- [ ] 한 CC의 상태 변경이 다른 CC에 전파되지 않음

### 2. 포커스 관리
- [ ] CC A 활성 → 단축키 F 입력 → CC A만 FOLD 처리, CC B 영향 없음
- [ ] Alt+Tab 전환 후 단축키 → 새 활성 CC에 적용

### 3. 알림 E2E
- [ ] CC B 활성 중 CC A에 ActionOnResponse 수신
- [ ] CC A의 Window Title에 (!) 표시
- [ ] OS 알림 발생
- [ ] DND 활성 시 OS 알림 suppress

### 4. 동일 테이블 중복 방지
- [ ] 운영자 X가 Table 5로 Launch 후 다시 Launch 시도 → BO가 거부 ("이미 연결됨")

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 1 기술 검토 (BS-02 Lobby 모니터링과의 경계)
- [ ] Team 4 기술 검토 (OS 알림 플랫폼별 구현)
