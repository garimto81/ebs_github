# BS-05-10 Multi-Table Operator Scenarios

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | 다중 테이블 운영 패턴 3가지 + 키보드 포커스 정책 (CCR-030, W7 해소) |

---

## 개요

EBS는 **"1 CC = 1 Table = 1 Overlay"** 인스턴스 관계를 유지한다. 그러나 **1명의 운영자는 여러 테이블을 동시에 관리**할 수 있으며, 이 경우 **다중 CC 인스턴스**가 독립 실행된다.

- **1:1:1** = CC : Table : Overlay (기술적 인스턴스)
- **1:N** = Operator : CC 인스턴스 (운영 관계)

> **참조**: `BS-05-00 §10 운영 패턴`, `BS-02-lobby §운영자 할당`.

---

## 1. 운영 패턴 3가지

### 1.1 Pattern A — 단일 테이블 전담 (Single Table Operator)

**설명**: 1명 = 1 테이블 전담. 대규모 대회의 Feature Table(방송 메인 테이블) 운영.

| 항목 | 값 |
|------|---|
| CC 인스턴스 | 1개 |
| 키보드 포커스 | 항상 단일 CC |
| 장점 | 집중도 최고, 실수 최소 |
| 단점 | 운영자 수 = 테이블 수 (비용 高) |
| 사용 | WSOP 메인 이벤트 파이널 테이블, EPT 메인 테이블 |

### 1.2 Pattern B — 다중 테이블 순회 (Rotating Multi-Table)

**설명**: 1명 = 2~4 테이블 관리. 운영자가 Alt+Tab으로 전환.

| 항목 | 값 |
|------|---|
| CC 인스턴스 | 2~4개 (같은 머신 또는 인접 머신) |
| 키보드 포커스 | 활성 CC만 단축키 수신 |
| 장점 | 인건비 절감 |
| 단점 | 전환 오버헤드, 액션 놓침 가능성 |
| 사용 | 서브 대회, 예선, Day 1 단계 |

### 1.3 Pattern C — 원격 Supervisor

**설명**: Lobby 모니터링 뷰만 보고, 개입 필요 시 해당 테이블 CC를 Launch.

| 항목 | 값 |
|------|---|
| CC 인스턴스 | 0개 (상시) → 필요 시 N개 |
| 키보드 포커스 | Lobby (대부분) |
| 장점 | 최대 효율, 저수준 문제만 개입 |
| 단점 | 응답 속도 느림, 라이브 방송 부적합 |
| 사용 | 사전 설정, 예선 감독, 문제 해결 |

---

## 2. 권장 모드

| 대회 단계 | 권장 패턴 |
|-----------|-----------|
| Feature Table (방송) | **Pattern A** |
| Day 1~2 예선 | Pattern B (2~4 테이블) |
| 사전 설정 / 감독 | Pattern C |

---

## 3. 키보드 포커스 정책

### 3.1 단일 CC (Pattern A)

- 단축키 모두 활성 (N=NEW HAND, F=FOLD, C=CHECK/CALL, R=RAISE, B=BET, A=ALL-IN, U=UNDO)

### 3.2 다중 CC (Pattern B)

- **활성 CC만** 단축키 수신
- OS 레벨 Alt+Tab으로 포커스 전환
- 비활성 CC는 **단축키 무시**
- 각 CC 창 제목에 Table 번호 + 상태 표시 ("Table 5 - PRE_FLOP")

### 3.3 포커스 오인식 방지

운영자가 "잘못된 테이블"에 키를 눌러 실수할 위험이 있다. 방지책:
- **포커스 진입 시 애니메이션** (노란 배너 "Table 5 active for 0.5s")
- **핫키 FOCUS_MISMATCH_GUARD**: 포커스 전환 직후 200ms간 단축키 입력 무시 (오토 키 충돌 방지)
- **설정 옵션** (BS-05-06): "Show table number overlay when focused" 토글

---

## 4. 알림 / 경고 정책

다중 CC 환경에서 비활성 CC에서 이벤트가 발생하면 운영자에게 알림이 필요하다.

| 이벤트 | 알림 | 장소 |
|--------|------|------|
| ActionOn (액션 요청) | 오디오 beep + 창 flash | 비활성 CC에서 |
| BO 연결 끊김 | 오디오 alert + OS notification | 모든 비활성 CC |
| 핸드 종료 | 창 title 업데이트 (Hand # 증가) | 해당 CC |
| 에러 (RFID/WS) | 오디오 alert + 창 flash | 해당 CC |

**오디오 알림 볼륨**: `BS-03-settings §Audio` 에서 조정 가능.

---

## 5. RBAC와 테이블 할당

- **Operator**는 `assigned_tables` 배열(JWT payload)에 있는 테이블만 CC Launch 가능
- Admin은 제한 없음
- Viewer는 모든 CC Launch 불가

Lobby의 테이블 할당은 `BS-02-lobby §운영자 할당` 참조.

---

## 6. 연관 문서

- `BS-05-00 §10` — 운영 패턴 개요
- `BS-05-06-keyboard-shortcuts` — 단축키 상세
- `BS-01-auth §Permission Bit Flag` — Permission Bit Flag (CCR-017, BS-01-02-rbac 통합됨)
- `BS-02-lobby` — 운영자 할당 UI
