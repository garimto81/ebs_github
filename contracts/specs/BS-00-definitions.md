# BS-00 Definitions — 용어·상태·트리거 총괄 정의서

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 모든 BS/BO/IMPL/API/DATA 문서의 용어 기반 확립 |

---

## 개요

이 문서는 EBS의 **용어·상태값·트리거·FSM·이벤트·ID 체계를 한곳에 정의**하는 단일 출처(Single Source of Truth)다. 모든 행동 명세(BS-01~07), 백오피스 기획(BO-01~11), 기술 문서(IMPL/API/DATA)가 이 문서의 정의를 참조한다.

> **참고**: Enum 값(정수 코드), 데이터 모델 필드 상세, 게임별 파라미터는 `docs/04-rules-games/games/engine-spec/BS-06-00-REF-game-engine-spec.md`에 정의되어 있다. 이 문서는 "의미"를, BS-06-00-REF는 "값"을 정의한다.

---

## 1. 앱 아키텍처 용어

EBS는 **3개 별도 앱 + 1개 독립 패키지**로 구성된다. WSOP LIVE(Staff Page + Flutter 앱) 구조를 따른다.

| 용어 | 정의 | 기술 | 비고 |
|------|------|------|------|
| **Lobby** | 모든 테이블의 관제·설정 허브. 웹 브라우저 앱 | 웹 (React/Next.js TBD) | 구 WSOP LIVE Staff Page 대응 |
| **Command Center (CC)** | 게임 진행 커맨드 입력 화면. 테이블당 1개 인스턴스 | Flutter 앱 (별도 실행) | 구 PokerGFX Action Tracker |
| **Back Office (BO)** | Lobby와 CC 사이 간접 데이터 공유 계층. REST API + WebSocket + DB | FastAPI + SQLite → PostgreSQL | Lobby↔CC 직접 연동 없음 |
| **Game Engine** | 게임 규칙·상태 관리 순수 패키지. CC에 import됨 | 순수 Dart (Flutter 의존 없음) | Event Sourcing |
| **Overlay** | 시청자 방송 화면 그래픽 출력 | Flutter + Rive | CC와 동일 기술 스택 |
| **Settings** | 오버레이·출력·게임 규칙·통계 설정. Lobby의 하위 다이얼로그 | Lobby 웹 내 구현 | ~~Console~~ 독립 앱 아님 |

**관계**:
- Lobby : CC = **1 : N** (1개 Lobby에서 N개 테이블의 CC 관리)
- Lobby ↔ CC **직접 연동 없음** — Back Office DB를 통한 간접 공유
- CC 1개 = Table 1개 = Overlay 1개

> **금지**: "단일 Flutter 앱의 2개 화면" 표현. Lobby(웹)와 CC(Flutter)는 별도 앱이다.

---

## 2. 엔티티 용어

### 2.1 대회 계층 (WSOP LIVE 동일)

```
Competition → Series → Event → Flight → Table → Seat → Player
```

| 엔티티 | 정의 | 예시 |
|--------|------|------|
| **Competition** | 최상위 대회 브랜드 | WSOP, WSOPC, APL |
| **Series** | 대회 시리즈 (연간) | 2026 WSOP |
| **Event** | 개별 토너먼트/이벤트 | Event #1: $10K NL Hold'em |
| **Flight** | Event의 진행 구간 | Day 1A, Day 1B, Day 2 |
| **Table** | 물리적 포커 테이블 | Table 1 (Feature Table) |
| **Seat** | 테이블 내 좌석 (0~9) | Seat 3 |
| **Player** | 좌석에 배치된 참가자 | John Doe, Seat 3 |

### 2.2 게임 엔티티

| 엔티티 | 정의 | 생명주기 |
|--------|------|----------|
| **Hand** | 게임 1판. 딜부터 승자 결정까지 | IDLE → ... → HAND_COMPLETE |
| **Round** (Street) | Hand 내 베팅 단계 | Pre-Flop, Flop, Turn, River |
| **Action** | 플레이어의 1회 결정 | Fold, Check, Bet, Call, Raise, All-In |
| **Card** | 52장 중 1장. RFID UID 매핑 가능 | suit(0~3) + rank(0~12) |
| **Deck** | 52장 카드 세트. RFID 등록 대상 | 등록/미등록/부분등록 |
| **Pot** | 현재 Hand에 베팅된 총액 | 메인 팟 + 사이드 팟 0~N개 |
| **Bet** | 1회 베팅 금액 | 최소 BB ~ 최대 All-In (NL) |
| **Stack** | 플레이어의 현재 보유 칩 | 0+ (칩 단위, 화폐 아님) |

### 2.3 설정 엔티티

| 엔티티 | 정의 |
|--------|------|
| **BlindStructure** | 블라인드 레벨 진행표 (SB/BB/Ante × 레벨) |
| **Skin** | 오버레이 그래픽 테마 (배경, 카드, 좌석, 폰트, 색상) |
| **OutputPreset** | NDI/HDMI 출력 설정 프리셋 (해상도, Security Delay, 크로마키) |
| **Config** | BO 글로벌 설정 (RFID 모드, 로그 레벨, 시스템 기본값) |

---

## 3. 상태값 정의

### 3.1 Table 상태 (TableFSM)

| 상태 | 의미 | 진입 조건 | 퇴장 조건 |
|------|------|----------|----------|
| **EMPTY** | 미설정 — 게임 유형, 플레이어 없음 | 테이블 생성 시 | 게임 설정 완료 |
| **SETUP** | 설정 중 — 게임·좌석 배치 진행 | 게임 설정 시작 | CC Launch 시 |
| **LIVE** | 방송 중 — CC가 활성화되어 핸드 진행 | CC Launch 완료 | Pause 또는 Close |
| **PAUSED** | 일시 중단 — 휴식, 테이블 브레이크 | 운영자 Pause | Resume → LIVE |
| **CLOSED** | 종료 — 해당 Flight/Event 내 테이블 폐쇄 | 운영자 Close | 재사용 시 EMPTY |

### 3.2 Hand 상태 (HandFSM / game_phase)

| 상태 | 값 | 의미 |
|------|:--:|------|
| **IDLE** | 0 | 핸드 대기. CC에서 NEW HAND 대기 |
| **SETUP_HAND** | 1 | 핸드 준비. 블라인드 수집, 딜러 이동 |
| **PRE_FLOP** | 2 | 프리플롭 베팅. 홀카드 배분 후 |
| **FLOP** | 3 | 플롭 공개 + 베팅 |
| **TURN** | 4 | 턴 공개 + 베팅 |
| **RIVER** | 5 | 리버 공개 + 베팅 |
| **SHOWDOWN** | 6 | 카드 공개, 승패 결정 |
| **HAND_COMPLETE** | 7 | 핸드 종료, 팟 분배 완료 |
| **RUN_IT_MULTIPLE** | 17 | 런잇타임 진행 (특수) |

> 상세 enum 값: `BS-06-00-REF §1.9 game_phase`

### 3.3 Seat 상태 (SeatFSM)

| 상태 | 의미 |
|------|------|
| **VACANT** | 비어있음 — 플레이어 미배치 |
| **OCCUPIED** | 플레이어 착석 — 게임 참여 가능 |
| **RESERVED** | 예약됨 — 특정 플레이어에게 배정됨 |

### 3.4 Player 상태 (Hand 내)

| 상태 | 값 | 의미 | 전환 조건 |
|------|:--:|------|----------|
| **active** | 0 | 활성, 액션 가능 | 핸드 시작 |
| **folded** | 1 | 폴드됨, 해당 핸드 제외 | FOLD 액션 |
| **allin** | 2 | 올인, 스택 0 | BET/CALL/RAISE로 스택 전부 소진 |
| **eliminated** | 3 | 탈락 (토너먼트) | 스택 0 + 재입금 불가 |
| **sitting_out** | 4 | 관전, 현재 핸드 불참 | 플레이어 자발적 이탈 |

> 상세: `BS-06-00-REF §1.5.2 PlayerStatus`

### 3.5 Deck 상태 (DeckFSM)

| 상태 | 의미 |
|------|------|
| **UNREGISTERED** | RFID 등록 전 — 카드-UID 매핑 없음 |
| **REGISTERING** | 등록 진행 중 — 52장 전수 스캔 진행 |
| **REGISTERED** | 등록 완료 — 52장 매핑 확인, 게임 투입 가능 |
| **PARTIAL** | 부분 등록 — 일부 카드 매핑 실패 (에러 상태) |
| **MOCK** | Mock 모드 — RFID 없이 소프트웨어 가상 매핑 |

---

## 4. 트리거 3소스

모든 행동 명세에서 트리거는 반드시 **발동 주체**를 명시한다.

| 소스 | 주체 | 설명 | 예시 |
|------|------|------|------|
| **CC** | 운영자 (수동) | Command Center에서 운영자가 버튼/키보드로 입력 | NEW HAND, DEAL, FOLD, BET, RAISE |
| **RFID** | 시스템 (자동) | RFID 리더가 카드를 감지/제거 | CardDetected, CardRemoved, DeckRegistered |
| **Engine** | 시스템 (자동) | Game Engine이 규칙에 따라 자동 실행 | 블라인드 수집, 팟 계산, 승자 결정 |
| **BO** | 시스템 (자동) | Back Office에서 데이터 변경 통지 | ConfigChanged, PlayerUpdated, TableAssigned |

> **우선순위**: CC와 RFID가 동시 발생 시 경계 규칙은 `BS-06-00-triggers.md`에서 정의한다.

### Mock 모드에서의 트리거 변환

| 실제 모드 트리거 | Mock 모드 대체 | 변환 주체 |
|----------------|--------------|----------|
| RFID CardDetected | CC 수동 카드 입력 → `CardDetected` 이벤트 합성 | Mock HAL |
| RFID DeckRegistered | CC "자동 등록" 버튼 → `DeckRegistered` 이벤트 합성 | Mock HAL |
| RFID CardRemoved | 없음 (Mock에서 미지원) | — |

> **핵심 원칙**: Mock HAL은 Real HAL과 동일한 이벤트 스트림을 생성한다. 상위 계층(CC, Engine)은 Real/Mock을 구분하지 않는다.

---

## 5. FSM 이름 규약

| FSM | 관리 대상 | 정의 위치 |
|-----|----------|----------|
| **TableFSM** | Table 상태 (EMPTY → ... → CLOSED) | 이 문서 §3.1 |
| **HandFSM** | Hand 상태 (IDLE → ... → HAND_COMPLETE) | 이 문서 §3.2, BS-06-01 상세 |
| **SeatFSM** | Seat 상태 (VACANT/OCCUPIED/RESERVED) | 이 문서 §3.3 |
| **DeckFSM** | Deck 상태 (UNREGISTERED → ... → REGISTERED) | 이 문서 §3.5, BS-04-01 상세 |
| **EventFSM** | Event 진행 상태 (Created → Running → Completed) | BS-06-00-REF §1.2.5 |

---

## 6. 이벤트 명명 규약

모든 시스템 이벤트는 **PascalCase** + **동사 과거분사** 패턴을 따른다.

| 패턴 | 예시 | 발행 주체 |
|------|------|----------|
| `{Entity}{Action}` | `HandStarted`, `HandCompleted` | Engine |
| `{Entity}{Action}` | `CardDetected`, `CardRemoved`, `DeckRegistered` | RFID HAL |
| `{Entity}{Action}` | `ActionSubmitted`, `SeatAssigned` | CC |
| `{Entity}{Action}` | `ConfigChanged`, `PlayerUpdated`, `TableAssigned` | BO |
| `{Entity}{Action}` | `OperatorConnected`, `OperatorDisconnected` | BO (WebSocket) |

> **WebSocket 이벤트 상세**: `contracts/api/API-05-websocket-events.md`

---

## 7. ID 체계

### 7.1 Feature Catalog ID (144개)

`docs/01-strategy/EBS-Feature-Catalog.md`에서 정의된 캐노니컬 ID를 모든 BS 문서에서 참조한다.

| Prefix | 범주 | 개수 |
|--------|------|:----:|
| **MW-** | Main Window (Lobby + CC 공통) | 10 |
| **SRC-** | Sources (OBS/vMix 위임, EBS 범위 외) | 10 |
| **OUT-** | Outputs (NDI/HDMI 출력) | 12 |
| **G1-** | GFX1 게임 제어 (CC 오버레이 핵심) | 24 |
| **G2-** | GFX2 통계 (플레이어 통계) | 13 |
| **G3-** | GFX3 방송 연출 (자막, 타이머 등) | 13 |
| **SYS-** | System (RFID, 네트워크, 보안, 백업) | 16 |
| **SK-** | Skin Editor | 16 |
| **GEB-** | Graphic Editor Board | 15 |
| **GEP-** | Graphic Editor Player | 15 |

### 7.2 BS 문서 번호

| ID | 영역 | 문서 위치 |
|----|------|----------|
| BS-00 | 정의서 (이 문서) | `02-behavioral/BS-00-definitions.md` |
| BS-01 | Auth (로그인·세션·RBAC) | `02-behavioral/BS-01-auth/` |
| BS-02 | Lobby (테이블 관리) | `02-behavioral/BS-02-lobby/` |
| BS-03 | Settings (출력·오버레이·게임·통계) | `02-behavioral/BS-03-settings/` |
| BS-04 | RFID (카드 인식·수동 폴백) | `02-behavioral/BS-04-rfid/` |
| BS-05 | Command Center (게임 진행) | `02-behavioral/BS-05-command-center/` |
| BS-06 | Game Engine (내부 처리) | `04-rules-games/games/engine-spec/` |
| BS-07 | Overlay (시청자 화면 출력) | `02-behavioral/BS-07-overlay/` |

### 7.3 BO 문서 번호

| ID | 영역 | 문서 위치 |
|----|------|----------|
| BO-01~11 | Back Office 기획 | `back-office/` |

---

## 8. 시간·수치·단위

| 값 | 단위 | 설명 |
|----|------|------|
| 칩 수량 | **칩** (정수) | 화폐 아닌 게임 내 칩 단위. `chips` 단어 사용 시 반도체 칩과 혼동 주의 → **베팅 토큰** 권장 |
| 확률 | **0.0 ~ 1.0** (float) | Equity 표시 시 × 100 = % 변환 |
| 시간 | **ms** (밀리초) | 애니메이션, 지연, 타임아웃 |
| 해상도 | **px** (1080p = 1920×1080, 4K = 3840×2160) | 출력 해상도 |
| RFID UID | **16자 16진 문자열** | 예: `"04A3B2C1D5E6F7A8"` |
| 카드 표시 | **랭크+수트 2자** | 예: `"As"` (Ace of Spades), `"Th"` (Ten of Hearts) |

---

## 9. Mock 모드 정의

Mock 모드는 RFID 하드웨어 없이 EBS 전체 기능을 사용하기 위한 **개발·테스트·데모 모드**다.

### 무엇이 Real과 다른가

| 계층 | Real 모드 | Mock 모드 |
|------|----------|----------|
| **RFID HAL** | ST25R3911B + ESP32 Serial UART | `MockRfidReader` — 소프트웨어 에뮬레이션 |
| **카드 감지** | 안테나가 물리적으로 카드 UID를 읽음 | CC에서 수동 카드 입력 → `CardDetected` 이벤트 합성 |
| **덱 등록** | 52장 실물 카드를 리더에 스캔 | "자동 등록" 1클릭 → 52장 가상 매핑 |
| **카드 제거** | 안테나 신호 소실 | Mock에서 미지원 (필요 시 수동 이벤트 주입) |
| **에러** | 하드웨어 장애 (안테나 오류, UID 중복 등) | 에러 주입 API로 테스트 가능 |

### 무엇이 동일한가

| 계층 | 동작 |
|------|------|
| **CC UI** | 동일 — Real/Mock 구분 없이 같은 화면 |
| **Game Engine** | 동일 — 이벤트 소스와 무관하게 같은 규칙 적용 |
| **Overlay** | 동일 — 같은 그래픽 출력 |
| **BO** | 동일 — 같은 API, 같은 DB 스키마 |
| **이벤트 스트림** | 동일 — `IRfidReader.events` 스트림의 이벤트 타입/페이로드가 같음 |

> **핵심 원칙**: Mock 모드에서 바뀌는 것은 **RFID HAL 구현체 1개**뿐이다. 나머지 모든 계층은 Real 모드와 100% 동일하다.

> **인터페이스 계약 상세**: `contracts/api/API-03-rfid-hal-interface.md`

---

## 10. 문서 참조 규약

### 이 문서를 참조하는 방법

모든 BS/BO/IMPL/API/DATA 문서에서 용어를 처음 사용할 때:

```markdown
> 참조: BS-00 §3.1 Table 상태
```

### 이 문서에서 참조하는 문서

| 참조 대상 | 경로 |
|----------|------|
| Enum 값 상세 | `docs/04-rules-games/games/engine-spec/BS-06-00-REF-game-engine-spec.md` |
| Feature Catalog 144 ID | `docs/01-strategy/EBS-Feature-Catalog.md` |
| 트리거 경계 상세 | `contracts/specs/BS-06-game-engine/BS-06-00-triggers.md` |
| RFID HAL 인터페이스 | `contracts/api/API-03-rfid-hal-interface.md` |
| WebSocket 이벤트 상세 | `contracts/api/API-05-websocket-events.md` |
