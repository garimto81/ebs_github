# IMPL-03 State Management — CC Riverpod + Lobby 웹 상태 관리

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | CC Riverpod Provider 트리, 상태 범위, Lobby 웹 상태 관리 |

---

## 개요

이 문서는 EBS의 **상태 관리 전략**을 정의한다. Command Center(CC)는 Riverpod을 사용하고, Lobby(웹)는 **Zustand 5.x**를 사용한다 (IMPL-01 §2.4 확정). 두 앱은 Back Office(BO)를 경유하여 간접적으로 상태를 동기화한다.

> 참조: BS-00 §1 앱 아키텍처 용어, API-05 WebSocket 프로토콜, API-03 RFID HAL 인터페이스

---

## 1. 상태 범위 (Scope) 정의

### 1.1 3계층 상태 범위

| 범위 | 생명주기 | 예시 | 저장 위치 |
|------|---------|------|----------|
| **앱 전역** (App) | 앱 시작 ~ 종료 | 인증 토큰, 사용자 정보, BO 연결 상태, RFID 모드 | 메모리 + Secure Storage |
| **테이블 범위** (Table) | CC Launch ~ CC Close | 테이블 정보, 좌석 배치, 블라인드 레벨, RFID 상태 | 메모리 + BO DB |
| **핸드 범위** (Hand) | 핸드 시작 ~ 핸드 종료 | GameState, 카드, 액션 히스토리, 팟, 현재 Street | 메모리 (핸드 종료 시 BO에 영구 저장) |

### 1.2 상태 전이 흐름

```
App Scope (항상 존재)
  │
  └── Table Scope (CC Launch 시 생성)
        │
        └── Hand Scope (NEW HAND 시 생성, HAND_COMPLETE 시 소멸)
```

---

## 2. CC — Riverpod Provider 트리

### 2.1 앱 전역 Provider

| Provider | 타입 | 역할 | 갱신 트리거 |
|----------|------|------|-----------|
| `authStateProvider` | StateNotifier | JWT 토큰, 사용자 정보, 로그인 상태 | 로그인/로그아웃/토큰 갱신 |
| `boConnectionProvider` | StreamProvider | BO WebSocket 연결 상태 | 연결/끊김/재연결 |
| `rfidModeProvider` | StateProvider | RFID 모드 (real/mock) | BO Config 변경 |
| `rfidReaderProvider` | Provider | IRfidReader 인스턴스 (Real 또는 Mock) | rfidModeProvider 변경 |
| `rfidEventsProvider` | StreamProvider | RFID 이벤트 스트림 | rfidReaderProvider 변경 |
| `appConfigProvider` | FutureProvider | BO 글로벌 설정 | 앱 시작 시 1회 로드 |

### 2.2 테이블 범위 Provider

| Provider | 타입 | 역할 | 갱신 트리거 |
|----------|------|------|-----------|
| `currentTableProvider` | StateNotifier | 현재 테이블 정보 (TableFSM 상태 포함) | Lobby에서 설정 변경 시 WS 이벤트 |
| `seatListProvider` | StateNotifier | 좌석 0~9 배치 정보 | PlayerUpdated, SeatAssigned |
| `blindLevelProvider` | StateNotifier | 현재 블라인드 레벨 (SB/BB/Ante) | BlindStructureChanged |
| `deckStatusProvider` | StateNotifier | 덱 등록 상태 (DeckFSM) | DeckRegistered, 등록 진행 |
| `outputStatusProvider` | StateNotifier | NDI/HDMI 출력 상태 | OutputStatusChanged |

### 2.3 핸드 범위 Provider

| Provider | 타입 | 역할 | 갱신 트리거 |
|----------|------|------|-----------|
| `gameStateProvider` | StateNotifier | 현재 GameState (Event Sourcing 결과) | 모든 GameEvent 적용 |
| `handPhaseProvider` | Provider | 현재 HandFSM 상태 (IDLE~HAND_COMPLETE) | gameStateProvider에서 파생 |
| `currentPlayerProvider` | Provider | 현재 액션 대기 플레이어 | gameStateProvider에서 파생 |
| `potProvider` | Provider | 메인 팟 + 사이드 팟 | gameStateProvider에서 파생 |
| `boardCardsProvider` | Provider | 커뮤니티 카드 (0~5장) | CardDetected(보드) |
| `holeCardsProvider` | Provider | 좌석별 홀카드 | CardDetected(플레이어) |
| `actionHistoryProvider` | StateNotifier | 현재 핸드 액션 히스토리 | ActionPerformed |
| `equityProvider` | FutureProvider | 실시간 승률 계산 | 카드 변경 시 재계산 |

### 2.4 Provider 의존성 그래프

```
authStateProvider
    │
    └──→ boConnectionProvider
              │
              ├──→ currentTableProvider
              │         │
              │         ├──→ seatListProvider
              │         ├──→ blindLevelProvider
              │         └──→ deckStatusProvider
              │
              └──→ gameStateProvider
                        │
                        ├──→ handPhaseProvider
                        ├──→ currentPlayerProvider
                        ├──→ potProvider
                        ├──→ boardCardsProvider
                        ├──→ holeCardsProvider
                        └──→ equityProvider

rfidModeProvider
    │
    └──→ rfidReaderProvider
              │
              └──→ rfidEventsProvider
                        │
                        └──→ gameStateProvider (카드 이벤트 소비)
```

---

## 3. CC — GameState Event Sourcing

### 3.1 핵심 패턴

```
이벤트 발생 (CC 입력 / RFID 감지)
    │
    ▼
GameEvent 생성
    │
    ▼
engine.apply(currentState, event) → newState
    │
    ▼
gameStateProvider 갱신
    │
    ├──→ UI 자동 리빌드 (Riverpod watch)
    ├──→ BO WebSocket 전송 (영구 저장)
    └──→ Overlay 동기화
```

### 3.2 이벤트 → 상태 변환

| 이벤트 | 상태 변경 | 파생 Provider 영향 |
|--------|----------|-----------------|
| `HandStarted` | GameState 초기화, 딜러/블라인드 설정 | handPhase → SETUP_HAND |
| `CardDetected` (홀카드) | 해당 좌석 홀카드 추가 | holeCardsProvider 갱신 |
| `CardDetected` (보드) | 커뮤니티 카드 추가 | boardCardsProvider 갱신, equityProvider 재계산 |
| `ActionPerformed` | 스택/팟 갱신, 다음 플레이어 결정 | potProvider, currentPlayerProvider 갱신 |
| `HandCompleted` | 승자 결정, 팟 분배 | handPhase → HAND_COMPLETE |

### 3.3 오프라인 복원

| 시나리오 | 동작 |
|---------|------|
| BO 연결 끊김 중 핸드 진행 | GameState는 로컬 메모리에 유지. 이벤트를 로컬 버퍼에 저장 |
| BO 재연결 | 버퍼의 미전송 이벤트를 순서대로 BO에 전송 |
| CC 크래시 후 재시작 | BO에서 마지막 핸드 상태 복원. 진행 중 핸드는 HAND_COMPLETE로 강제 종료 |

---

## 4. CC — WebSocket 상태 동기화

### 4.1 BO → CC 이벤트 수신

| 이벤트 | 갱신 대상 Provider | 적용 시점 |
|--------|------------------|----------|
| `ConfigChanged` | appConfigProvider, 해당 설정 Provider | 즉시 또는 다음 핸드 |
| `PlayerUpdated` | seatListProvider | 즉시 |
| `TableAssigned` | currentTableProvider | 즉시 |
| `BlindStructureChanged` | blindLevelProvider | 다음 핸드 시작 시 |

### 4.2 CC → BO 이벤트 발행

| 이벤트 | 발행 조건 | 실패 시 |
|--------|----------|--------|
| `HandStarted` | 운영자 NEW HAND | 로컬 버퍼 저장, 재연결 후 전송 |
| `ActionPerformed` | 운영자 액션 입력 | 로컬 버퍼 저장 |
| `CardDetected` | RFID/수동 카드 입력 | 로컬 버퍼 저장 |
| `HandEnded` | 핸드 종료 | 로컬 버퍼 저장 |

---

## 5. Lobby — 웹 상태 관리

Lobby는 **Zustand 5.x**를 사용한다 (IMPL-01 §2.4). 서버 상태(REST 응답 캐시)와 클라이언트 상태(UI 로컬)는 별도 slice로 분리하고, WebSocket 이벤트는 전용 slice의 액션으로 전달한다.

### 5.1 상태 분류

| 범위 | 상태 | 저장 위치 |
|------|------|----------|
| **앱 전역** | 인증 토큰, 사용자 정보, 선택된 Series/Event | 메모리 + SessionStorage |
| **페이지 범위** | 테이블 목록, 플레이어 목록 (서버 데이터 캐시) | 메모리 (페이지 이동 시 재로드 또는 캐시) |
| **실시간** | CC 연결 상태, 핸드 진행 정보, RFID 상태 | WebSocket 스트림 |

### 5.2 서버 상태 vs 클라이언트 상태

| 구분 | 예시 | 관리 방식 |
|------|------|----------|
| 서버 상태 | 테이블 목록, 플레이어 DB, 핸드 기록 | REST API fetch → 로컬 캐시 |
| 클라이언트 상태 | 사이드바 열림/닫힘, 필터 선택, 모달 표시 | 로컬 상태 (useState/Context) |
| 실시간 상태 | CC 연결 여부, 현재 핸드 정보 | WebSocket 구독 |

### 5.3 WebSocket 구독 관리

| 동작 | 상세 |
|------|------|
| 연결 | 로그인 성공 후 `ws://{host}/ws/lobby` 연결, JWT 인증 |
| 구독 | `Subscribe` 메시지로 관심 테이블/이벤트 타입 등록 |
| 수신 | 이벤트 수신 → 해당 상태 갱신 → UI 리렌더 |
| 해제 | 페이지 이동 시 구독 필터 변경, 로그아웃 시 연결 종료 |

### 5.4 세션 복원

| 항목 | 저장 위치 | 복원 시점 |
|------|----------|----------|
| 선택된 Series/Event/Flight | SessionStorage | 탭 복원 |
| Access Token | JavaScript 메모리 | Refresh Token으로 갱신 |
| Refresh Token | HttpOnly Cookie | 브라우저 자동 전송 |
| 사이드바 상태 / 테마 | localStorage | 앱 시작 시 |

### 5.5 Zustand Slice 구조

Lobby는 관심사별 slice를 분리하고 `create()` 한 번으로 결합한다. `persist` 미들웨어 적용 여부는 slice마다 다르다.

| Slice | 책임 | Store 키 예시 | persist 대상 | 저장 미들웨어 |
|-------|------|---------------|--------------|--------------|
| `authSlice` | 인증/토큰/사용자 프로필 | `user`, `accessToken`, `isAuthenticated` | 부분 (`user`만) | `persist` → SessionStorage |
| `tableSlice` | 테이블 목록/상세/필터 상태 | `tables`, `selectedTableId`, `filters` | 아니오 (서버 캐시) | 없음 |
| `wsSlice` | WebSocket 연결·이벤트 버퍼·구독 상태 | `connectionStatus`, `subscriptions`, `lastEventSeq` | 아니오 | 없음 |
| `uiSlice` | 사이드바/모달/테마/토스트 | `sidebarOpen`, `theme`, `modals` | 예 (`theme`, `sidebarOpen`) | `persist` → localStorage |

**원칙**:
- 서버 상태(REST 캐시)는 `tableSlice`에서 관리하되, 재검증은 REST 호출 또는 WebSocket 이벤트로 수행 (React Query 병용 가능)
- Access Token은 **persist 제외** — JavaScript 메모리에만 유지 (XSS 완화), Refresh Token은 HttpOnly Cookie
- 실시간 이벤트는 `wsSlice` 액션으로 진입 → 필요한 slice에 setter 호출 (단방향 흐름 유지)
- 각 slice는 독립 파일(`store/auth.ts`, `store/table.ts` 등)로 분리하여 코드 오너십 명확화

---

## 6. CC ↔ Lobby 간접 동기화

### 6.1 동기화 원칙

- Lobby와 CC는 **직접 통신하지 않는다**
- 모든 상태 동기화는 BO DB/WebSocket을 경유한다
- 동일 데이터에 대해 최종 일관성(Eventual Consistency) 보장

### 6.2 동기화 흐름

```
Lobby (설정 변경)
    │
    ├── REST PUT /tables/{id} → BO DB 갱신
    │
    └── BO WebSocket → CC (ConfigChanged 이벤트)
                           │
                           └── CC Provider 갱신 → UI 업데이트

CC (핸드 데이터)
    │
    ├── WebSocket → BO DB 저장
    │
    └── BO WebSocket → Lobby (HandStarted/ActionPerformed 이벤트)
                          │
                          └── Lobby 대시보드 갱신
```

### 6.3 충돌 해결

| 시나리오 | 해결 방식 |
|---------|----------|
| Lobby에서 블라인드 변경 + CC에서 핸드 진행 중 | 변경은 **다음 핸드**에 적용 |
| Lobby에서 플레이어 수정 + CC에서 동일 플레이어 액션 중 | CC 액션 우선, 플레이어 정보는 핸드 종료 후 갱신 |
| 네트워크 파티션 후 재연결 | BO 서버 타임스탬프 기준 최신 데이터 우선 |

---

## 7. 상태 불변성 원칙

### 7.1 CC (Dart)

| 원칙 | 설명 |
|------|------|
| GameState는 불변 | `apply()` 결과는 항상 새 인스턴스. 기존 상태 수정 금지 |
| Provider 갱신은 state setter만 | `state = newState` 패턴. 직접 필드 수정 금지 |
| 컬렉션 불변 | `List.unmodifiable`, `Map.unmodifiable` 사용 |

### 7.2 Lobby (웹)

| 원칙 | 설명 |
|------|------|
| 상태 갱신은 새 객체 | 스프레드 연산자(`...`) 또는 immer 라이브러리 |
| 서버 데이터 캐시 무효화 | REST 요청 후 관련 캐시 무효화 또는 WebSocket 이벤트로 자동 갱신 |
