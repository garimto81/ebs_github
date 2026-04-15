---
title: Project Structure
owner: team2
tier: internal
legacy-id: IMPL-02
last-updated: 2026-04-15
---

# IMPL-02 Project Structure — 레포 분리 전략 + 패키지 레이아웃

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 5개 레포 분리, 디렉토리 트리, 공유 패키지, 의존성 그래프 |

---

## 개요

이 문서는 EBS의 **레포(Repository) 분리 전략**과 각 레포의 **디렉토리 레이아웃**을 정의한다. 5개 앱/패키지를 독립 레포로 관리하며, 공유 코드는 Dart 패키지로 분리한다.

> 참조: BS-00 §1 앱 아키텍처 용어, IMPL-01 기술 스택 선정

---

## 1. 레포 분리 전략

### 1.1 레포 목록

| 레포명 | 기술 | 역할 | 빌드 산출물 |
|--------|------|------|-----------|
| **ebs_lobby** | React / Next.js | 웹 관제 허브 | 정적 파일 (dist/) |
| **ebs_cc** | Flutter | Command Center 앱 | Windows/macOS/Linux 실행 파일 |
| **ebs_bo** | Python / FastAPI | Back Office API 서버 | Docker 이미지 |
| **ebs_engine** | 순수 Dart | Game Engine 패키지 | Dart 패키지 (pub) |
| **ebs_overlay** | Flutter + Rive | 방송 오버레이 앱 | Windows 실행 파일 |

### 1.2 공유 패키지

| 패키지명 | 위치 | 역할 | 소비자 |
|---------|------|------|--------|
| **ebs_models** | ebs_engine 내 또는 별도 레포 | 공유 데이터 모델 (GameState, Card, Player 등) | ebs_cc, ebs_overlay, ebs_engine |
| **ebs_api_client** | 별도 레포 또는 ebs_cc 내 | BO REST API + WebSocket 클라이언트 | ebs_cc, ebs_overlay |

### 1.3 분리 근거

| 근거 | 설명 |
|------|------|
| 독립 배포 | 각 앱을 독립적으로 빌드/배포. CC 업데이트가 BO에 영향 없음 |
| 기술 이질성 | Lobby(웹), CC(Flutter), BO(Python) — 언어/빌드 시스템이 다름 |
| 팀 분업 | 프론트엔드(Lobby), 앱(CC/Overlay), 백엔드(BO), 엔진(Engine) 독립 작업 |
| CI/CD | 레포별 독립 파이프라인. 변경 범위 최소화 |

### 1.4 모노레포 기각 사유

| 항목 | 모노레포 | 멀티레포 (선정) |
|------|---------|---------------|
| 빌드 복잡도 | Python + Dart + Node 통합 빌드 설정 복잡 | 각 레포 독립 빌드 |
| CI 시간 | 전체 빌드 필요 | 변경된 레포만 빌드 |
| 접근 제어 | 세분화 어려움 | 레포별 권한 설정 |
| 의존성 관리 | 버전 충돌 리스크 | 패키지 버전 명시 |

---

## 2. ebs_lobby — 웹 앱

```
ebs_lobby/
├── public/
│   ├── favicon.ico
│   └── assets/
├── src/
│   ├── app/                      # 라우팅 (Next.js App Router 기준)
│   │   ├── layout.tsx
│   │   ├── page.tsx              # 로그인
│   │   ├── series/
│   │   │   └── [id]/
│   │   │       ├── page.tsx      # Series 상세
│   │   │       └── events/
│   │   │           └── [id]/
│   │   │               ├── page.tsx
│   │   │               └── flights/
│   │   │                   └── [id]/
│   │   │                       ├── page.tsx
│   │   │                       └── tables/
│   │   │                           └── [id]/
│   │   │                               └── page.tsx
│   │   └── admin/
│   │       ├── users/
│   │       ├── settings/
│   │       └── audit/
│   ├── components/
│   │   ├── common/               # Button, Modal, Table 등
│   │   ├── lobby/                # 테이블 카드, 대시보드
│   │   ├── settings/             # Settings 다이얼로그
│   │   └── auth/                 # 로그인 폼
│   ├── hooks/                    # useAuth, useWebSocket, useTable
│   ├── services/
│   │   ├── api.ts                # BO REST API 클라이언트
│   │   └── websocket.ts          # WebSocket 연결 관리
│   ├── store/                    # Zustand 5.x slices (auth/table/ws/ui)
│   ├── types/                    # TypeScript 타입 정의
│   └── utils/                    # 포매팅, 상수
├── package.json
├── tsconfig.json
└── README.md
```

---

## 3. ebs_cc — Command Center Flutter 앱

```
ebs_cc/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart              # MaterialApp + ProviderScope
│   │   ├── router.dart           # go_router 설정
│   │   └── theme.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── presentation/     # LoginPage, widgets
│   │   │   └── providers/        # authProvider, sessionProvider
│   │   ├── game/
│   │   │   ├── presentation/     # GamePage, ActionPanel, HandInfo
│   │   │   └── providers/        # gameStateProvider, handProvider
│   │   ├── table/
│   │   │   ├── presentation/     # TablePage, SeatGrid
│   │   │   └── providers/        # tableProvider, seatProvider
│   │   └── rfid/
│   │       ├── presentation/     # RfidStatusWidget, DeckRegistration
│   │       └── providers/        # rfidReaderProvider, rfidEventsProvider
│   ├── core/
│   │   ├── di/                   # 의존성 주입 설정
│   │   ├── network/
│   │   │   ├── api_client.dart   # BO REST API
│   │   │   └── ws_client.dart    # WebSocket 연결
│   │   ├── error/                # 에러 핸들링
│   │   ├── logging/              # 로그 서비스
│   │   └── storage/              # 로컬/보안 저장소
│   └── shared/
│       ├── widgets/              # 공유 위젯
│       └── constants/
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
├── integration_test/
│   └── app_test.dart
├── pubspec.yaml
└── README.md
```

### 3.1 의존성 (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  ebs_engine:                     # Game Engine 패키지
    path: ../ebs_engine           # 개발: 로컬 경로 / 배포: git ref
  ebs_models:
    path: ../ebs_engine/packages/ebs_models
  flutter_riverpod: ^2.0.0
  go_router: ^14.0.0
  rive: ^0.13.0
  flutter_secure_storage: ^9.0.0
  web_socket_channel: ^2.4.0
```

---

## 4. ebs_bo — Back Office FastAPI 서버

```
ebs_bo/
├── src/
│   ├── main.py                   # uvicorn 엔트리포인트
│   ├── app/
│   │   ├── __init__.py
│   │   ├── config.py             # 환경 변수, 설정
│   │   ├── database.py           # SQLModel 엔진, 세션
│   │   └── deps.py               # FastAPI Depends
│   ├── models/                   # SQLModel 테이블 정의
│   │   ├── competition.py
│   │   ├── series.py
│   │   ├── event.py
│   │   ├── table.py
│   │   ├── player.py
│   │   ├── hand.py
│   │   ├── user.py
│   │   └── config.py
│   ├── routers/                  # API 엔드포인트
│   │   ├── auth.py
│   │   ├── series.py
│   │   ├── events.py
│   │   ├── tables.py
│   │   ├── players.py
│   │   ├── hands.py
│   │   ├── configs.py
│   │   ├── users.py
│   │   └── sync.py               # WSOP LIVE 동기화
│   ├── services/                 # 비즈니스 로직
│   │   ├── auth_service.py
│   │   ├── table_service.py
│   │   ├── hand_service.py
│   │   └── wsop_sync_service.py
│   ├── websocket/                # WebSocket 허브
│   │   ├── manager.py            # 연결 관리, 라우팅
│   │   ├── cc_handler.py         # CC 이벤트 수신
│   │   └── lobby_handler.py      # Lobby 구독 관리
│   ├── middleware/
│   │   ├── auth.py               # JWT 검증
│   │   └── rbac.py               # 역할 기반 접근 제어
│   └── utils/
│       ├── security.py           # JWT 생성/검증, 비밀번호
│       └── logging.py
├── alembic/
│   ├── alembic.ini
│   ├── env.py
│   └── versions/                 # 마이그레이션 스크립트
├── tests/
│   ├── conftest.py
│   ├── test_auth.py
│   ├── test_tables.py
│   ├── test_hands.py
│   └── test_websocket.py
├── Dockerfile
├── pyproject.toml
├── requirements.txt
└── README.md
```

---

## 5. ebs_engine — Game Engine 순수 Dart 패키지

```
ebs_engine/
├── lib/
│   ├── ebs_engine.dart           # 패키지 배럴 파일
│   ├── src/
│   │   ├── engine.dart           # apply(GameState, Event) → GameState
│   │   ├── state/
│   │   │   ├── game_state.dart   # 불변 게임 상태
│   │   │   ├── player_state.dart
│   │   │   └── pot_state.dart
│   │   ├── events/
│   │   │   ├── game_event.dart   # sealed class 이벤트 계층
│   │   │   ├── action_event.dart
│   │   │   └── card_event.dart
│   │   ├── rules/
│   │   │   ├── holdem.dart       # Hold'em 규칙
│   │   │   ├── omaha.dart
│   │   │   ├── stud.dart
│   │   │   └── draw.dart
│   │   ├── evaluator/
│   │   │   ├── hand_evaluator.dart
│   │   │   └── equity_calculator.dart
│   │   └── fsm/
│   │       ├── hand_fsm.dart     # HandFSM 상태 전이
│   │       └── table_fsm.dart    # TableFSM 상태 전이
├── packages/
│   └── ebs_models/               # 공유 데이터 모델 서브 패키지
│       ├── lib/
│       │   ├── ebs_models.dart
│       │   └── src/
│       │       ├── card.dart
│       │       ├── deck.dart
│       │       ├── player.dart
│       │       └── enums.dart
│       └── pubspec.yaml
├── test/
│   ├── engine_test.dart
│   ├── holdem_test.dart
│   ├── omaha_test.dart
│   ├── evaluator_test.dart
│   └── scenarios/                # YAML 시나리오 테스트
│       ├── holdem_basic.yaml
│       └── omaha_hilo.yaml
├── bin/
│   └── simulator.dart            # Interactive Simulator CLI
├── pubspec.yaml
└── README.md
```

### 5.1 패키지 의존성

```yaml
# pubspec.yaml
name: ebs_engine
environment:
  sdk: '>=3.0.0 <4.0.0'
# Flutter 의존성 없음 — 순수 Dart
dependencies:
  yaml: ^3.1.0                    # 시나리오 파일 로드
dev_dependencies:
  test: ^1.25.0
```

---

## 6. ebs_overlay — 방송 오버레이 Flutter 앱

```
ebs_overlay/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   └── theme.dart
│   ├── features/
│   │   ├── board/                # 보드 카드 표시
│   │   ├── player_card/          # 플레이어 홀카드, 이름, 스택
│   │   ├── pot/                  # 팟 표시
│   │   ├── action/               # 액션 애니메이션
│   │   ├── timer/                # 타이머, 블라인드 레벨
│   │   └── lower_third/          # L-Bar, 자막
│   ├── core/
│   │   ├── rive/                 # Rive 컨트롤러, 스킨 로더
│   │   ├── network/              # BO WebSocket 구독
│   │   └── output/               # NDI 출력, 크로마키 설정
│   └── shared/
├── assets/
│   └── rive/                     # .riv 스킨 파일
│       ├── default_skin.riv
│       └── wsop_skin.riv
├── test/
├── pubspec.yaml
└── README.md
```

---

## 7. 의존성 그래프

```
ebs_models (공유 데이터 모델)
    │
    ├──→ ebs_engine (게임 로직)
    │        │
    │        ├──→ ebs_cc (Command Center)
    │        │       │
    │        │       └──→ ebs_api_client (BO 통신)
    │        │
    │        └──→ ebs_overlay (오버레이)
    │                │
    │                └──→ ebs_api_client
    │
    └──→ ebs_api_client

ebs_bo (Back Office) ← 독립 (Python, Dart 의존성 없음)
ebs_lobby (웹) ← 독립 (TypeScript, Dart 의존성 없음)
```

### 7.1 의존 방향 규칙

| 규칙 | 설명 |
|------|------|
| ebs_models → 어디에도 의존하지 않음 | 최하위 계층 |
| ebs_engine → ebs_models만 의존 | 순수 로직, UI 의존 없음 |
| ebs_cc, ebs_overlay → ebs_engine + ebs_models + ebs_api_client | 앱 계층 |
| ebs_bo → 독립 | Python 생태계. Dart 코드와 직접 의존 없음 |
| ebs_lobby → 독립 | TypeScript 생태계. BO REST API만 참조 |

---

## 8. 버전 관리 전략

| 항목 | 정책 |
|------|------|
| 브랜치 | main + feature 브랜치 |
| 버전 | Semantic Versioning (semver) |
| 태그 | `v{major}.{minor}.{patch}` |
| 공유 패키지 버전 | ebs_models, ebs_api_client는 CC/Overlay와 버전 동기화 |
| BO API 버전 | URL prefix: `/api/v1/` |

### 8.1 레포 간 동기화

| 시나리오 | 절차 |
|---------|------|
| ebs_models 변경 | 1. ebs_models 업데이트 → 2. ebs_engine 테스트 → 3. ebs_cc/overlay 업데이트 |
| BO API 변경 | 1. ebs_bo 배포 → 2. ebs_api_client 업데이트 → 3. ebs_cc/overlay 업데이트 |
| Game Engine 규칙 변경 | 1. ebs_engine 업데이트 → 2. ebs_cc/overlay 의존성 갱신 |
