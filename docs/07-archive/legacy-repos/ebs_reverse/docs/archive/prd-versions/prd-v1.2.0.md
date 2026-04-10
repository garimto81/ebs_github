# PokerGFX Clone 통합 개발 기획서

**Version**: 1.2.0
**Date**: 2026-02-14
**문서 유형**: 통합 개발 PRD
**대상 독자**: 개발팀 전원 (백엔드, 프론트엔드, 하드웨어, QA)

---

> 이 문서는 현재 운영 중인 PokerGFX Server v3.2.985.0의 역공학 분석 결과를 바탕으로, 동일한 시스템을 복제하고 개선하기 위한 통합 개발 기획서입니다.
> PokerGFX가 어떤 시스템인지, 왜 복제해야 하는지, 어떻게 최소 리소스로 완성할 수 있는지를 기획자 관점에서 설명합니다.
> 6개 분석 문서(아키텍처 분석, 기획 PRD, Wave 1-4 상세 명세)의 모든 기술 내용을 하나의 문서로 통합했습니다.

---

## Part 1. 프로젝트 비전

### 1.1 PokerGFX란 무엇인가

PokerGFX Server는 라이브 포커 방송에서 실시간 그래픽 오버레이를 생성하는 전문 시스템입니다.

방송 화면에 보이는 모든 포커 정보, 플레이어의 홀카드, 베팅 액션, 팟 금액, 승률 퍼센트, 커뮤니티 카드, 통계, 이 모든 것을 실시간으로 만들어내는 것이 PokerGFX입니다.

#### 시스템이 하는 일

| 기능 | 설명 |
|------|------|
| RFID 카드 인식 | 테이블에 내장된 RFID 리더 12대(좌석 10 + 보드 1 + Muck 1)가 딜링되는 카드를 자동 인식 |
| 실시간 그래픽 렌더링 | DirectX 기반 GPU 렌더링으로 카드, 칩, 액션 등을 방송 화면에 오버레이 |
| 승률 계산 | Monte Carlo 시뮬레이션으로 각 플레이어의 실시간 승률을 계산하여 표시 |
| 핸드 평가 | 22가지 포커 게임 규칙에 따른 핸드 랭킹 판정 |
| 다중 앱 연동 | 서버 1대 + 클라이언트 6대(Action Tracker, 해설자 부스, 타이머 등)가 실시간 통신 |
| 스킨 시스템 | 방송 브랜드에 맞는 그래픽 테마를 자유롭게 편집 |

#### 시스템 규모 (역공학으로 확인)

| 항목 | 수치 |
|------|------|
| 소프트웨어 버전 | v3.2.985.0 (.NET Framework 4.x, Windows 전용) |
| 코드 규모 | 2,602개 타입, 14,460개 메서드, 60개 DLL |
| 지원 게임 | 22가지 (Hold'em, Omaha, Stud, Draw, Badugi 등) |
| 프로토콜 | TCP/UDP 커스텀 프로토콜, 113+ 명령어 |
| 보안 | 4계층 DRM (Email + Offline Session + USB 동글 + 원격 라이선스) |
| 메인 바이너리 | 355MB (단일 God Class 329개 메서드) |

현재 이 시스템은 우리 방송 현장에서 실제로 운영되고 있으며, 모든 라이브 포커 방송의 그래픽을 담당하고 있습니다.

### 1.2 왜 복제하는가

이미 잘 동작하는 시스템이 있는데 왜 같은 것을 다시 만들어야 하는지, 세 가지 이유가 있습니다.

#### 이유 1: PokerGO의 PokerGFX 인수 — 비즈니스 리스크

PokerGFX가 경쟁사인 PokerGO 측에 인수되었습니다. 이는 우리에게 직접적인 비즈니스 위협이 됩니다.

| 리스크 | 구체적 영향 |
|--------|-----------|
| 서비스 중단 | PokerGO가 경쟁사에 대한 라이선스 갱신을 거부하거나 조건을 악화시킬 수 있음 |
| 기술 종속 | 핵심 방송 인프라가 경쟁사의 제품에 의존하는 구조가 됨 |
| 정보 노출 | 라이선스 계약, 사용 패턴, 방송 일정 등이 경쟁사에 노출될 가능성 |
| 가격 통제력 상실 | 인수 후 라이선스 비용이 일방적으로 인상될 수 있음 |

**핵심**: 방송의 생명줄인 그래픽 시스템이 경쟁사 손에 넘어간 상황에서, 자체 시스템 없이는 언제든 방송이 중단될 수 있습니다.

#### 이유 2: WSOP+ 플랫폼과의 시너지 — 비즈니스 기회

WSOP+ 개발을 통해 대회를 유연하게 연동할 수 있는 플랫폼이 만들어지고 있습니다. 자체 PokerGFX 시스템이 있으면 이 플랫폼과 직접 연동하여 훨씬 큰 가치를 만들 수 있습니다.

| 연동 가능성 | 효과 |
|------------|------|
| 대회 데이터 ↔ 방송 그래픽 | 대회 진행 상황이 실시간으로 방송 그래픽에 자동 반영 |
| 플레이어 DB 연동 | 등록 선수 정보, 통계, 프로필을 방송에서 즉시 활용 |
| 다중 대회 동시 운영 | 여러 테이블, 여러 대회를 하나의 시스템으로 통합 관리 |
| 커스텀 통계 | WSOP+ 고유의 분석 지표를 방송 화면에 표시 |

**핵심**: 자체 시스템이 있어야 WSOP+와 깊이 연동할 수 있고, 이는 방송과 대회 운영 모두에 큰 도움이 됩니다.

#### 이유 3: 최소 리소스 전략 — 실현 가능성

처음부터 새로 설계하는 것이 아닙니다. 이미 완성되어 운영 중인 PokerGFX를 역공학하여 복제한 뒤, 필요한 부분만 개선하는 전략입니다.

| 영역 | 전략 | 이유 |
|------|------|------|
| 하드웨어 (RFID 리더, 테이블) | 최대한 외주 | 하드웨어 제조는 전문 업체에 맡기는 것이 효율적 |
| 소프트웨어 (서버, 클라이언트) | PokerGFX 복제 후 개선 | 이미 동작하는 모델이 있으므로, 동일한 기능을 먼저 재현한 후 확장 |
| 프로토콜/데이터 모델 | 원본과 동일하게 구현 | 역공학으로 모든 명세가 확보되어 있음 |
| UI/UX | 원본 기반 + 현대화 | 원본의 화면 구성을 따르되 WPF/Avalonia로 재설계 |

**핵심**: "발명"이 아니라 "복제 + 개선"이므로, 불확실성이 낮고 개발 범위가 명확합니다.

### 1.3 개발 전략 요약

```
┌──────────────────────────────────────────────────────────────────┐
│                        개발 전략                                  │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  PokerGFX v3.2.985.0 (역공학 완료)                               │
│       │                                                          │
│       ├─── 소프트웨어 ──▶ 복제 후 개선 (자체 개발)               │
│       │    • 22개 게임 엔진 동일 구현                            │
│       │    • 113+ 프로토콜 동일 구현                             │
│       │    • 핸드 평가 알고리즘 동일 구현                        │
│       │    • UI 화면 구성 동일 → WPF/Avalonia 현대화             │
│       │    • DRM 간소화 (USB 동글 제거, JWT 대체)                │
│       │                                                          │
│       ├─── 하드웨어 ──▶ 최대한 외주                              │
│       │    • RFID 리더 (기존 호환 또는 커스텀 발주)              │
│       │    • 포커 테이블 내장 안테나                              │
│       │    • 네트워크 장비                                       │
│       │                                                          │
│       └─── WSOP+ 연동 ──▶ 확장 개발                             │
│            • 대회 데이터 실시간 연동 API                         │
│            • 플레이어 DB 통합                                    │
│            • 다중 대회 동시 운영                                 │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### 1.4 성공 기준

#### 정량 지표

| KPI | 목표 | 측정 방법 |
|-----|------|----------|
| 카드 인식 속도 | 200ms 미만 | RFID 태그 감지 시점 ~ 화면 표시 시점 타이머 |
| 카드 인식률 | 99% 이상 | 100회 연속 태그 테스트 |
| 무중단 운영 | 4시간 이상 | 에러 로그 0건 확인 |
| 기능 완성도 | 149/149 | Feature Checklist 전수 체크 |

#### 최종 완료 기준

> 현장 운영자 2명이 "PokerGFX와 차이 없음"에 서명

### 1.5 구현 범위

**MVP (Phase 1-2)**: Texas Hold'em + Omaha 2종으로 실제 방송 가능한 최소 시스템
- 게임 추적, Action Tracker, Viewer Overlay, 기본 RFID, 서버-화면 실시간 연결

**Full Product (Phase 3-5)**: 22개 게임 전체 + 프로덕션 하드웨어 + 고급 기능
- 전체 게임 지원, 다중 RFID, GPU 렌더링, Skin Editor, 분석 시스템

**WSOP+ 연동 (Phase 5+)**: 대회 플랫폼 통합
- 대회 데이터 연동, 플레이어 DB 통합, 다중 대회 동시 운영

### 1.6 명시적 제외 항목

| 제외 항목 | 이유 |
|----------|------|
| KEYLOK USB 동글 DRM | 경쟁사 제품의 복제 방지 장치, 자체 JWT 라이선스로 대체 |
| ConfuserEx 난독화 | 자체 코드이므로 역공학 방어 불필요 |
| Dotfuscator 변조 감지 | 동일 이유 |
| Newtonsoft.Json | System.Text.Json으로 교체 (성능 + .NET 8 네이티브) |
| WinForms UI | WPF/Avalonia로 전면 재설계 (현대화) |
| 하드웨어 자체 제조 | RFID 리더, 안테나 등은 외주 발주 |

---

## Part 2. 사용자와 워크플로우

### 2.1 사용자 정의

| 사용자 | 역할 | 주요 화면 | 사용 빈도 |
|--------|------|----------|----------|
| 방송 감독 | 전체 방송 흐름 제어, 카메라 전환 | Main Window, Outputs | 매 방송 |
| GFX 운영자 | 그래픽 오버레이 실시간 조작 | GFX1, GFX2, GFX3, Commentary | 매 방송 |
| 딜러 | 게임 진행, 카드 딜링 | Action Tracker (외부 앱) | 매 핸드 |
| 스킨 디자이너 | 방송 그래픽 테마 제작/수정 | Skin Editor, Graphic Editor | 시즌 변경 시 |
| 시스템 관리자 | 서버 설정, 라이선스 관리 | System Tab | 초기 설정 시 |

### 2.2 핵심 워크플로우

#### 워크플로우 1: 방송 준비 (매 방송 시작 전)

```
시스템 관리자              방송 감독                GFX 운영자
    │                        │                        │
    ├── 서버 시작 ──────────▶│                        │
    │                        ├── 게임 유형 선택 ─────▶│
    │                        │   (Hold'em/Omaha 등)   │
    │                        ├── 스킨 로드 ──────────▶│
    │                        ├── RFID 리더 연결 ─────▶│
    │                        │   (좌석 10 + 보드 1     │
    │                        │    + Muck 1 = 12대)    │
    │                        ├── 출력 설정 ──────────▶│
    │                        │   (NDI/HDMI/SDI)       │
    │                        └── Action Tracker 연결 ──┘
```

#### 워크플로우 2: 게임 진행 (매 핸드)

```
딜러 (Action Tracker)       GFX Server              방송 화면
    │                        │                        │
    ├── New Hand 시작 ──────▶│                        │
    │                        ├── 테이블 초기화 ──────▶│ (칩 카운트 표시)
    ├── 카드 딜 (RFID) ─────▶│                        │
    │                        ├── 카드 인식 + 표시 ───▶│ (홀카드 오버레이)
    ├── 베팅 액션 입력 ─────▶│                        │
    │   (Fold/Call/Raise)    ├── 액션 반영 + 팟 계산 ▶│ (팟 금액 업데이트)
    │                        ├── 승률 계산 (Monte) ──▶│ (Win% 바 표시)
    ├── 커뮤니티 카드 ──────▶│                        │
    │   (Flop/Turn/River)    ├── 보드 카드 표시 ────▶│
    ├── Showdown ───────────▶│                        │
    │                        ├── 핸드 랭크 판정 ────▶│ (승자 하이라이트)
    └── Hand 종료 ──────────▶│                        │
                             └── 통계 업데이트 ──────▶│ (VPIP, PFR 등)
```

#### 워크플로우 3: 스킨 편집 (비방송 시간)

```
스킨 디자이너
    │
    ├── Skin Editor 열기
    ├── 기존 스킨 로드 (.vpt/.skn)
    ├── Graphic Editor 진입
    │   ├── Board 요소 편집 (팟, 커뮤니티 카드 위치)
    │   └── Player 요소 편집 (이름, 칩, 홀카드 위치)
    ├── 애니메이션 설정 (FadeIn, SlideIn 등)
    ├── 미리보기 확인
    └── 스킨 저장 (AES 암호화)
```

---

## Part 3. 시스템 아키텍처

### 3.1 원본 시스템 규모

Part 1에서 설명한 PokerGFX Server의 역공학 분석 결과, 다음과 같은 규모가 확인되었습니다. 이것이 우리가 복제해야 할 대상의 실체입니다:

| 항목 | 수치 |
|------|------|
| TypeDef | 2,602개 |
| MethodDef | 14,460개 |
| Fields | 6,793개 |
| 내장 DLL | 60개 |
| 메인 바이너리 크기 | 355MB |
| main_form 메서드 | 329개 |
| main_form 필드 | 398개 |

### 3.2 원본 8대 모듈 구조

| 모듈 | 파일 | 크기 | 핵심 역할 |
|------|------|------|----------|
| vpt_server.exe | 메인 서버 | 355MB | God Class main_form 중심, 전체 오케스트레이션 |
| hand_eval.dll | 핸드 평가 | 330KB | 538개 lookup 배열, 17개 게임별 평가기 |
| net_conn.dll | 네트워크 | 118KB | TCP/UDP, AES-256 암호화, 113+ 커맨드 |
| mmr.dll | GPU 렌더링 | 149KB | DirectX 11, 5-Thread 파이프라인, Dual Canvas |
| RFIDv2.dll | RFID 리더 | 57KB | TCP/WiFi + USB HID, 22개 텍스트 커맨드 |
| PokerGFX.Common.dll | 공통 | 566KB | 설정, Enum, 데이터 모델 |
| analytics.dll | 통계 | 23KB | VPIP, PFR, AF 등 플레이어 통계 |
| boarssl.dll | TLS | 207KB | BearSSL 기반 TLS 1.2 (RFID WiFi 전용) |

### 3.3 7개 애플리케이션 생태계

원본 시스템은 서버 1개 + 클라이언트 6개로 구성됩니다.

| 앱 | 내부명 | 역할 | 통신 |
|----|--------|------|------|
| GfxServer | pgfx_server | 메인 서버, 모든 상태 관리 | - |
| ActionTracker | pgfx_action_tracker | 딜러용 게임 액션 입력 | TCP |
| HandEvaluation | hand_eval_wcf | 독립 핸드 평가 서비스 | WCF → gRPC |
| ActionClock | pgfx_action_clock | 플레이어 타이머 표시 | TCP |
| StreamDeck | pgfx_streamdeck | Elgato StreamDeck 연동 | TCP |
| Pipcap | pgfx_pipcap | 카드 이미지 캡처 유틸 | 파일 |
| CommentaryBooth | pgfx_commentary_booth | 해설자용 홀카드 뷰어 | TCP |

### 3.4 Clone 아키텍처: Clean Architecture 4계층

원본 PokerGFX의 God Class 구조(main_form 329개 메서드)를 그대로 복사하지 않습니다. 동일한 기능을 현대적 아키텍처로 재설계하여 구현합니다. 이것이 "복제 후 개선" 전략의 핵심입니다.

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                     │
│  WPF/Avalonia Views + ViewModels (MVVM)                  │
│  30개 View (원본 43개 WinForms 통합)                      │
├─────────────────────────────────────────────────────────┤
│                    Application Layer                      │
│  MediatR CQRS (Command/Query + Handler)                  │
│  Use Cases, DTOs, Validators                             │
├─────────────────────────────────────────────────────────┤
│                      Domain Layer                         │
│  Entities, Value Objects, Domain Events                   │
│  Game Engine, Hand Evaluator, State Machines              │
├─────────────────────────────────────────────────────────┤
│                   Infrastructure Layer                    │
│  RFID Drivers, GPU Renderer, Network, Persistence        │
│  External Services (ATEM, Twitch, NDI)                   │
└─────────────────────────────────────────────────────────┘
```

### 3.5 Clone 프로젝트 구조

```
src/
├── PokerGFX.Domain/              # 도메인 모델, 게임 엔진
│   ├── Games/                    # 22개 게임 규칙
│   ├── HandEval/                 # 핸드 평가 엔진
│   ├── Cards/                    # CardMask, Deck
│   └── Events/                   # 도메인 이벤트
├── PokerGFX.Application/         # CQRS, Use Cases
│   ├── Commands/                 # 상태 변경 커맨드
│   ├── Queries/                  # 조회 쿼리
│   └── Behaviors/                # 파이프라인 (Validation, Logging)
├── PokerGFX.Infrastructure/      # 외부 연동
│   ├── Rfid/                     # RFID 드라이버
│   ├── Rendering/                # DirectX 12 렌더러
│   ├── Network/                  # gRPC + TCP
│   └── Persistence/              # EF Core, 설정 저장
├── PokerGFX.Presentation/        # WPF/Avalonia UI
│   ├── Views/                    # 30개 View
│   ├── ViewModels/               # MVVM ViewModels
│   └── Controls/                 # 커스텀 컨트롤
├── PokerGFX.Server/              # 서버 호스트
├── PokerGFX.ActionTracker/       # 딜러 앱
└── PokerGFX.Commentary/          # 해설자 앱

tests/
├── PokerGFX.Domain.Tests/
├── PokerGFX.Application.Tests/
├── PokerGFX.Infrastructure.Tests/
├── PokerGFX.Integration.Tests/
└── PokerGFX.E2E.Tests/
```

### 3.6 원본 → Clone 모듈 매핑

| 원본 모듈 | Clone 위치 | 기술 교체 |
|----------|-----------|----------|
| vpt_server.exe (main_form) | Server + Presentation + Application | WinForms → WPF/Avalonia MVVM |
| hand_eval.dll | Domain/HandEval | 동일 알고리즘, Source Generator로 lookup 생성 |
| net_conn.dll | Infrastructure/Network | TCP+JSON → gRPC+Protobuf |
| mmr.dll | Infrastructure/Rendering | SharpDX (DX11) → Vortice.Windows (DX12) |
| RFIDv2.dll | Infrastructure/Rfid | BearSSL → SslStream (.NET 내장) |
| PokerGFX.Common.dll | Domain + Application | God Object 분해 → Record 타입 |
| analytics.dll | Domain/Statistics | 동일 수식, 성능 최적화 |
| boarssl.dll | (제거) | .NET SslStream으로 대체 |

### 3.7 데이터 흐름

```
RFID 리더 ──(TCP/USB)──▶ RFID Driver ──▶ Domain Event: CardDetected
                                              │
                                              ▼
Action Tracker ──(gRPC)──▶ Command Handler ──▶ Game Engine
                                              │
                                              ├──▶ Hand Evaluator (승률 계산)
                                              │
                                              ▼
                                         State Change
                                              │
                                              ├──▶ GPU Renderer (오버레이 생성)
                                              │         │
                                              │         ▼
                                              │    NDI/HDMI 출력
                                              │
                                              ├──▶ Commentary Booth (홀카드 전송)
                                              │
                                              └──▶ Analytics (통계 업데이트)
```

---

## Part 4. 화면별 기능 명세

> 원본 시스템은 메인 윈도우 1개 + 7개 설정 탭 + 3개 독립 편집 창 = 총 11개 화면으로 구성됩니다.
> 각 화면의 annotated 스크린샷과 함께 기능을 정의합니다.

### 4.1 Main Window (메인 윈도우)

![Main Window](images/annotated/01-main-window.png)

메인 윈도우는 서버의 진입점이며, 게임 선택/시작/종료와 전체 상태 모니터링을 담당합니다.

| ID | 기능 | 설명 | 우선순위 |
|----|------|------|:--------:|
| MW-001 | 게임 유형 선택 | 22개 포커 변형 중 선택 (드롭다운) | P0 |
| MW-002 | 게임 시작/종료 | Start/Stop Game 버튼 | P0 |
| MW-003 | 핸드 번호 표시 | 현재 진행 중인 핸드 번호 | P0 |
| MW-004 | 접속 클라이언트 목록 | 연결된 Action Tracker, Commentary 등 표시 | P0 |
| MW-005 | RFID 연결 상태 | 리더 12대 개별 상태 표시 | P0 |
| MW-006 | 서버 IP/포트 표시 | 클라이언트 접속 정보 | P1 |
| MW-007 | 라이선스 상태 | 활성/만료/체험판 표시 | P1 |
| MW-008 | 탭 네비게이션 | Sources, Outputs, GFX1-3, Commentary, System 탭 전환 | P0 |
| MW-009 | 로그 패널 | 실시간 서버 로그 표시 | P1 |
| MW-010 | 긴급 중지 | 모든 그래픽 즉시 숨김 | P0 |

**개발 노트**:
- 원본 main_form은 329개 메서드를 가진 God Class. Clone에서는 `MainViewModel` + `GameSessionViewModel` + `ConnectionViewModel`로 분리
- 탭 전환은 WPF `TabControl` 또는 Avalonia `TabStrip`으로 구현

### 4.2 Sources (소스 탭)

![Sources Tab](images/annotated/02-sources-tab.png)

비디오 입력 소스(카메라, 캡처 카드)를 관리하는 화면입니다.

| ID | 기능 | 설명 | 우선순위 |
|----|------|------|:--------:|
| SRC-001 | 비디오 소스 목록 | 사용 가능한 캡처 장치 나열 | P0 |
| SRC-002 | 소스 미리보기 | 선택한 소스의 실시간 미리보기 | P0 |
| SRC-003 | 해상도 설정 | 입력 해상도 선택 (1080p/4K) | P0 |
| SRC-004 | 프레임레이트 설정 | 30/60fps 선택 | P1 |
| SRC-005 | 소스 순서 변경 | 드래그앤드롭으로 소스 순서 조정 | P1 |
| SRC-006 | NDI 소스 감지 | 네트워크 NDI 소스 자동 감지 | P1 |
| SRC-007 | MFormats 캡처 | Medialooks MFormats SDK 기반 캡처 | P0 |
| SRC-008 | HDMI/SDI 입력 | 하드웨어 캡처 카드 지원 | P0 |
| SRC-009 | 소스 상태 표시 | 활성/비활성/에러 상태 아이콘 | P1 |
| SRC-010 | 소스별 색보정 | 밝기, 대비, 채도 조정 | P2 |
| SRC-011 | 크롭 설정 | 입력 영상 자르기 | P2 |
| SRC-012 | 오디오 소스 연결 | 비디오 소스에 오디오 채널 매핑 | P2 |

**개발 노트**:
- 원본은 MFormats SDK 사용 → Clone은 `FFmpeg.AutoGen`으로 교체
- NDI 지원은 NewTek NDI SDK (무료) 활용

### 4.3 Outputs (출력 탭)

![Outputs Tab](images/annotated/03-outputs-tab.png)

렌더링된 방송 화면의 출력 대상을 설정합니다.

| ID | 기능 | 설명 | 우선순위 |
|----|------|------|:--------:|
| OUT-001 | Dual Canvas 출력 | Live Canvas + Delayed Canvas 독립 출력 | P0 |
| OUT-002 | NDI 출력 | 네트워크 NDI 스트림 전송 | P0 |
| OUT-003 | HDMI 출력 | 물리 HDMI 포트 출력 | P0 |
| OUT-004 | SDI 출력 | SDI 출력 (방송 장비 연동) | P1 |
| OUT-005 | 해상도 설정 | 출력 해상도 (1080p/4K) | P0 |
| OUT-006 | Trustless 모드 | 홀카드를 지연 출력에서만 표시 (생방송 보안) | P0 |
| OUT-007 | 지연 시간 설정 | Delayed Canvas 지연 초 단위 설정 | P0 |
| OUT-008 | 크로마키 출력 | 배경 투명 출력 (그린/블루/매젠타) | P1 |
| OUT-009 | 미리보기 | 각 출력의 실시간 프리뷰 | P0 |
| OUT-010 | Cross-GPU 공유 | DXGI SharedHandle로 GPU 간 텍스처 공유 | P1 |
| OUT-011 | ATEM 스위처 연결 | Blackmagic ATEM 원격 제어 | P2 |
| OUT-012 | 녹화 | 출력 화면 파일 저장 | P2 |
| OUT-013 | 스냅샷 | 현재 프레임 이미지 캡처 | P2 |

**개발 노트**:
- **Trustless 모드**: 가장 중요한 보안 기능. Live Canvas에는 홀카드를 절대 표시하지 않고, Delayed Canvas에만 설정된 지연 시간 후 표시
- Cross-GPU 텍스처 공유: 원본의 `bridge` 클래스가 DXGI SharedHandle로 구현

### 4.4 GFX1 탭 (게임 그래픽 주 제어)

![GFX1 Tab](images/annotated/04-gfx1-tab.png)

게임 진행 중 가장 자주 사용하는 핵심 제어 화면입니다.

| ID | 기능 | 설명 | 우선순위 |
|----|------|------|:--------:|
| G1-001 | 10인 좌석 배치 | 원형 테이블 10개 좌석 위치 표시 | P0 |
| G1-002 | 플레이어 이름 입력 | 좌석별 플레이어 이름 설정 | P0 |
| G1-003 | 칩 카운트 입력 | 좌석별 칩 수량 입력 | P0 |
| G1-004 | 홀카드 표시/숨김 | 좌석별 홀카드 공개 토글 | P0 |
| G1-005 | 팟 금액 표시 | 메인팟 + 사이드팟 금액 | P0 |
| G1-006 | 커뮤니티 카드 | Flop/Turn/River 카드 표시 | P0 |
| G1-007 | 베팅 라운드 표시 | Pre-Flop/Flop/Turn/River 상태 | P0 |
| G1-008 | 승률 바 | 각 플레이어 승률 퍼센트 바 | P0 |
| G1-009 | 핸드 랭크 표시 | 현재 최고 핸드 (One Pair, Flush 등) | P0 |
| G1-010 | 폴드 표시 | 폴드한 플레이어 회색 처리 | P0 |
| G1-011 | 딜러 버튼 | D 마커 좌석 표시 | P0 |
| G1-012 | 블라인드 표시 | SB/BB 좌석 표시 | P0 |
| G1-013 | All-in 표시 | All-in 플레이어 강조 | P0 |
| G1-014 | 사이드팟 분리 | 다중 사이드팟 개별 표시 | P1 |
| G1-015 | 수동 카드 입력 | RFID 실패 시 마우스 클릭 카드 선택 | P0 |
| G1-016 | 카드 제거 | 잘못된 카드 인식 시 삭제 | P0 |
| G1-017 | Rabbit Hunt | 남은 커뮤니티 카드 공개 | P1 |
| G1-018 | Bounty 금액 | 바운티 토너먼트용 현상금 표시 | P1 |
| G1-019 | 국가 플래그 | 플레이어 국적 표시 | P1 |
| G1-020 | 단축키 연결 | F1-F10으로 좌석별 빠른 조작 | P1 |
| G1-021 | Ante 설정 | Ante 금액 표시 | P1 |
| G1-022 | Straddle 지원 | Straddle 베팅 처리 | P2 |
| G1-023 | 블라인드 타이머 | 토너먼트 블라인드 레벨 타이머 | P2 |
| G1-024 | 브레이크 타이머 | 방송 휴식 카운트다운 | P2 |
| G1-025 | 자동 핸드 번호 | 새 핸드 시 자동 증가 | P0 |
| G1-026 | Run It Twice | 보드를 2번 전개하는 모드 | P2 |
| G1-027 | 테이블 이미지 | 스킨에 따른 테이블 배경 교체 | P1 |
| G1-028 | 애니메이션 제어 | 카드/칩 애니메이션 On/Off | P1 |
| G1-029 | 밀리초 지연 설정 | 카드 표시 지연 (ms 단위) | P1 |

**개발 노트**:
- 이 탭이 GFX 운영자의 주 작업 공간. 반응 속도가 가장 중요
- 원본에서 `GameTypeData` (79개 필드)가 이 탭의 모든 상태를 관리 → Clone에서는 6개 Record로 분리 (3.8절 참조)

### 4.5 GFX2 탭 (통계 및 추가 정보)

![GFX2 Tab](images/annotated/05-gfx2-tab.png)

플레이어 통계, 토너먼트 정보 등 부가 그래픽을 제어합니다.

| ID | 기능 | 설명 | 우선순위 |
|----|------|------|:--------:|
| G2-001 | VPIP 통계 | 자발적 팟 참여율 표시 | P1 |
| G2-002 | PFR 통계 | Pre-Flop Raise 비율 | P1 |
| G2-003 | AF 통계 | Aggression Factor | P1 |
| G2-004 | 핸드 수 표시 | 플레이어별 참여 핸드 수 | P1 |
| G2-005 | WTSD 통계 | Went To Showdown 비율 | P2 |
| G2-006 | 연승/연패 | 플레이어 연속 결과 | P2 |
| G2-007 | 칩 그래프 | 시간대별 칩 변동 그래프 | P2 |
| G2-008 | 테이블 통계 | 전체 테이블 평균 팟 크기 등 | P2 |
| G2-009 | 플레이어 프로필 | 사진, 이름, 국적, 별명 | P1 |
| G2-010 | 우승 이력 | 과거 대회 수상 정보 | P2 |
| G2-011 | 토너먼트 순위 | 현재 칩 순위 | P1 |
| G2-012 | 남은 인원 | 토너먼트 잔여 참가자 수 | P1 |
| G2-013 | 총 상금 풀 | 토너먼트 전체 상금 | P1 |
| G2-014 | Payout 구조 | 입상 상금 분배표 | P2 |
| G2-015 | ICM 계산 | Independent Chip Model 계산 | P2 |
| G2-016 | Bubble 표시 | 입상권 직전 상황 강조 | P2 |
| G2-017 | 하이라이트 재생 | 최근 핸드 요약 그래픽 | P2 |
| G2-018 | 비교 통계 | 2인 Head-to-Head 통계 비교 | P2 |
| G2-019 | 플레이어 노트 | 운영자 메모 입력 | P2 |
| G2-020 | 통계 내보내기 | CSV/JSON 통계 데이터 내보내기 | P2 |
| G2-021 | 통계 초기화 | 선택적/전체 통계 리셋 | P1 |

### 4.6 GFX3 탭 (방송 연출)

![GFX3 Tab](images/annotated/06-gfx3-tab.png)

방송 연출용 하단 자막, 타이틀, 오프닝/엔딩 그래픽을 제어합니다.

| ID | 기능 | 설명 | 우선순위 |
|----|------|------|:--------:|
| G3-001 | 하단 자막 | 방송 하단 텍스트 크롤 | P0 |
| G3-002 | 뉴스 티커 | 연속 스크롤 텍스트 | P1 |
| G3-003 | 방송 제목 | 프로그램명 표시 | P0 |
| G3-004 | 에피소드 정보 | 시즌/에피소드 번호 | P1 |
| G3-005 | 스폰서 로고 | 스폰서 로고 이미지 삽입 | P1 |
| G3-006 | 오프닝 애니메이션 | 방송 시작 그래픽 | P2 |
| G3-007 | 엔딩 애니메이션 | 방송 종료 그래픽 | P2 |
| G3-008 | 타이머 그래픽 | 커스텀 카운트다운 타이머 | P1 |
| G3-009 | 슬라이드 쇼 | 이미지 순차 표시 | P2 |
| G3-010 | 텍스트 오버레이 | 임의 텍스트 화면 배치 | P1 |
| G3-011 | 이미지 오버레이 | 임의 이미지 화면 배치 | P1 |
| G3-012 | Picture-in-Picture | 작은 영상 삽입 | P2 |
| G3-013 | 시상식 그래픽 | 순위 발표 전용 레이아웃 | P2 |
| G3-014 | SNS 연동 표시 | Twitter/X 해시태그, 채팅 표시 | P2 |
| G3-015 | 배경 음악 제어 | 오디오 레벨 조정 | P2 |
| G3-016 | Twitch 채팅 | IRC 기반 채팅 오버레이 | P2 |
| G3-017 | 광고 시간 표시 | 광고 진행 카운트다운 | P2 |
| G3-018 | 멀티 레이어 | 그래픽 요소 z-order 관리 | P1 |
| G3-019 | 키프레임 제어 | 애니메이션 키프레임 편집 | P2 |
| G3-020 | 프리셋 저장/로드 | 자주 쓰는 레이아웃 저장 | P1 |
| G3-021 | 실시간 미리보기 | 편집 중 결과 실시간 확인 | P1 |
| G3-022 | Font 관리 | 사용 가능 폰트 목록 및 설정 | P1 |
| G3-023 | 색상 팔레트 | 빠른 색상 선택기 | P1 |

### 4.7 Commentary 탭 (해설자)

![Commentary Tab](images/annotated/07-commentary-tab.png)

해설자 전용 화면으로, 시청자에게 노출되지 않는 홀카드 정보를 제공합니다.

| ID | 기능 | 설명 | 우선순위 |
|----|------|------|:--------:|
| CM-001 | 전체 홀카드 뷰 | 모든 플레이어 홀카드 실시간 표시 | P0 |
| CM-002 | 승률 실시간 | 전체 플레이어 승률 동시 표시 | P0 |
| CM-003 | 핸드 랭크 표시 | 각 플레이어 현재 핸드 등급 | P0 |
| CM-004 | 보안 분리 | 방송 출력과 완전 분리된 별도 네트워크 전송 | P0 |
| CM-005 | 폴드 카드 히스토리 | 이미 폴드한 플레이어의 카드 표시 | P1 |
| CM-006 | 아웃 카운트 | 남은 유효 카드 수 표시 | P1 |
| CM-007 | 팟 오즈 | 현재 팟 대비 콜 금액 비율 | P1 |
| CM-008 | 이전 핸드 요약 | 직전 핸드 결과 요약 | P2 |

### 4.8 System 탭 (시스템 설정)

![System Tab](images/annotated/08-system-tab.png)

서버 설정, 라이선스, RFID, 네트워크 등 시스템 전반을 관리합니다.

| ID | 기능 | 설명 | 우선순위 |
|----|------|------|:--------:|
| SYS-001 | 서버 포트 설정 | TCP 리스닝 포트 | P0 |
| SYS-002 | UDP Discovery 포트 | 클라이언트 자동 검색용 (9000/9001/9002) | P0 |
| SYS-003 | 라이선스 관리 | 라이선스 키 입력/확인/갱신 | P0 |
| SYS-004 | RFID 리더 설정 | 리더별 IP/포트/좌석 매핑 | P0 |
| SYS-005 | RFID 상태 모니터 | 12대 리더 실시간 상태 | P0 |
| SYS-006 | 카드 인식 테스트 | 개별 리더 카드 읽기 테스트 | P0 |
| SYS-007 | 네트워크 상태 | 연결된 클라이언트 목록 + ping | P0 |
| SYS-008 | 암호화 설정 | AES 암호화 On/Off | P0 |
| SYS-009 | 출력 장치 설정 | GPU, 모니터, 캡처 카드 선택 | P0 |
| SYS-010 | 스킨 경로 설정 | 스킨 파일 디렉토리 지정 | P0 |
| SYS-011 | 로그 레벨 설정 | Debug/Info/Warn/Error | P1 |
| SYS-012 | 로그 파일 경로 | 로그 파일 저장 위치 | P1 |
| SYS-013 | 자동 저장 | 설정 변경 시 자동 저장 간격 | P1 |
| SYS-014 | 백업/복원 | 전체 설정 백업 및 복원 | P1 |
| SYS-015 | 언어 설정 | UI 언어 선택 (130개 lang_enum) | P1 |
| SYS-016 | Master/Slave 설정 | 다중 서버 Master-Slave 구성 | P1 |
| SYS-017 | Slave 동기화 항목 | 어떤 데이터를 동기화할지 선택 | P1 |
| SYS-018 | Slave 스로틀링 | 동기화 빈도 제한 설정 | P2 |
| SYS-019 | ATEM 스위처 설정 | Blackmagic ATEM IP/포트 | P2 |
| SYS-020 | Twitch 연결 | Twitch IRC 로그인 (→ EventSub 전환) | P2 |
| SYS-021 | 키보드 단축키 | 전역 단축키 커스터마이징 | P1 |
| SYS-022 | 성능 모니터 | CPU/GPU/메모리 사용량 표시 | P1 |
| SYS-023 | 진단 정보 | 시스템 정보 수집 (지원용) | P2 |
| SYS-024 | 자동 업데이트 | 업데이트 확인 및 적용 | P2 |
| SYS-025 | API 키 관리 | 외부 서비스 API 키 저장 | P2 |
| SYS-026 | 데이터베이스 설정 | 통계 DB 연결 설정 | P2 |
| SYS-027 | 알림 설정 | 에러/경고 알림 방식 (팝업/사운드) | P2 |
| SYS-028 | 원격 접속 설정 | 웹 기반 원격 모니터링 | P2 |

### 4.9 Skin Editor (스킨 편집기)

![Skin Editor](images/annotated/09-skin-editor.png)

방송 그래픽의 전체 시각 테마를 편집하는 독립 창입니다. 99개 이상의 설정 필드를 관리합니다.

| ID | 기능 | 설명 | 우선순위 |
|----|------|------|:--------:|
| SK-001 | 스킨 로드 | .vpt/.skn 파일 열기 (AES 복호화) | P0 |
| SK-002 | 스킨 저장 | .vpt/.skn 파일 저장 (AES 암호화) | P0 |
| SK-003 | 새 스킨 생성 | 빈 템플릿에서 시작 | P0 |
| SK-004 | 스킨 미리보기 | 변경사항 실시간 프리뷰 | P0 |
| SK-005 | 테이블 배경 | 배경 이미지/색상 설정 | P0 |
| SK-006 | 카드 스킨 | 카드 앞/뒷면 이미지 설정 | P0 |
| SK-007 | 칩 스킨 | 칩 이미지 교체 | P1 |
| SK-008 | 폰트 설정 | 글꼴, 크기, 색상, 굵기 | P0 |
| SK-009 | 색상 테마 | 전체 색상 팔레트 설정 | P0 |
| SK-010 | 좌석 위치 편집 | 10개 좌석 X/Y 좌표 조정 | P0 |
| SK-011 | 팟 영역 위치 | 팟 금액 표시 위치/크기 | P0 |
| SK-012 | 커뮤니티 카드 위치 | 보드 카드 5장 배치 | P0 |
| SK-013 | 승률 바 스타일 | 퍼센트 바 색상/높이/위치 | P1 |
| SK-014 | 애니메이션 속도 | 전환 애니메이션 시간 (ms) | P1 |
| SK-015 | 투명도 설정 | 요소별 알파 값 | P1 |
| SK-016 | 그림자 효과 | 텍스트/카드 그림자 | P1 |
| SK-017 | 테두리 설정 | 요소 테두리 색상/두께 | P1 |
| SK-018 | 하단 자막 스타일 | Lower Third 디자인 | P1 |
| SK-019 | 로고 배치 | 방송사/스폰서 로고 위치 | P1 |
| SK-020 | 해상도 프리셋 | 720p/1080p/4K 프리셋 | P1 |
| SK-021 | 내보내기 | 스킨을 다른 서버로 전달용 패키징 | P2 |
| SK-022 | 가져오기 | 외부 스킨 패키지 불러오기 | P2 |
| SK-023 | 버전 관리 | 스킨 수정 이력 | P2 |
| SK-024 | 요소 잠금 | 실수 방지 위치 고정 | P1 |
| SK-025 | 가이드라인 | 정렬 보조선 표시 | P2 |
| SK-026 | 스냅 정렬 | 그리드/요소 스냅 | P2 |
| SK-027 | 레이어 관리 | z-order 드래그 정렬 | P1 |
| SK-028 | 그룹화 | 여러 요소를 그룹으로 묶기 | P2 |
| SK-029 | 복사/붙여넣기 | 요소 복제 | P1 |
| SK-030 | 실행취소/다시실행 | Undo/Redo 스택 | P0 |
| SK-031 | 이미지 임포트 | PNG/JPG/SVG 이미지 삽입 | P0 |
| SK-032 | 딜러 버튼 스킨 | D 버튼 이미지 교체 | P1 |
| SK-033 | 블라인드 표시 스킨 | SB/BB 마커 스타일 | P1 |
| SK-034 | 핸드 랭크 스타일 | 승리 핸드 표시 디자인 | P1 |
| SK-035 | 폴드 스타일 | 폴드 플레이어 시각 처리 | P1 |
| SK-036 | All-in 스타일 | All-in 강조 효과 | P1 |
| SK-037 | 국가 플래그 크기 | 국기 아이콘 크기/위치 | P2 |

### 4.10 Graphic Editor - Board (보드 그래픽 편집기)

![Graphic Editor Board](images/annotated/10-graphic-editor-board.png)

테이블 중앙 영역(팟, 커뮤니티 카드, 타이틀)의 개별 그래픽 요소를 편집합니다.

| ID | 기능 | 설명 | 우선순위 |
|----|------|------|:--------:|
| GEB-001 | 요소 트리뷰 | 보드 요소 계층 구조 표시 | P0 |
| GEB-002 | 드래그 이동 | 마우스로 요소 위치 이동 | P0 |
| GEB-003 | 크기 조절 | 핸들로 요소 크기 변경 | P0 |
| GEB-004 | 속성 패널 | 선택 요소의 상세 속성 편집 | P0 |
| GEB-005 | X/Y 좌표 입력 | 정확한 위치 수치 입력 | P0 |
| GEB-006 | 너비/높이 입력 | 정확한 크기 수치 입력 | P0 |
| GEB-007 | 회전 | 요소 회전 각도 | P1 |
| GEB-008 | 이미지 요소 | 이미지 파일 배치 (image_element) | P0 |
| GEB-009 | 텍스트 요소 | 텍스트 배치 (text_element) | P0 |
| GEB-010 | pip 요소 | 카드 문양 표시 (pip) | P0 |
| GEB-011 | 테두리 요소 | 장식 테두리 (border) | P1 |
| GEB-012 | 폰트 선택 | 텍스트 요소 글꼴 설정 | P0 |
| GEB-013 | 폰트 크기 | 텍스트 크기 (pt) | P0 |
| GEB-014 | 폰트 색상 | 텍스트 색상 | P0 |
| GEB-015 | 텍스트 정렬 | 좌/중/우 정렬 | P0 |
| GEB-016 | 텍스트 줄바꿈 | 자동 줄바꿈 On/Off | P1 |
| GEB-017 | 그림자 설정 | 요소별 그림자 (offset, blur, color) | P1 |
| GEB-018 | 투명도 | 요소 알파값 (0-255) | P1 |
| GEB-019 | 가시성 토글 | 요소 표시/숨김 | P0 |
| GEB-020 | 잠금 토글 | 실수 방지 이동 잠금 | P1 |
| GEB-021 | 복제 | 요소 복사 생성 | P1 |
| GEB-022 | 삭제 | 요소 제거 | P0 |
| GEB-023 | z-order 변경 | 앞으로/뒤로 이동 | P0 |
| GEB-024 | 정렬 도구 | 다중 요소 정렬 (좌/우/중/상/하) | P1 |
| GEB-025 | 분배 도구 | 다중 요소 균등 분배 | P2 |
| GEB-026 | 커뮤니티 카드 영역 | Flop 3장 + Turn + River 위치/크기 | P0 |
| GEB-027 | 메인팟 영역 | 메인팟 금액 텍스트 위치 | P0 |
| GEB-028 | 사이드팟 영역 | 사이드팟별 위치 설정 | P1 |
| GEB-029 | 딜러 버튼 영역 | D 버튼 10개 좌석별 위치 | P0 |
| GEB-030 | 프로그램 타이틀 | 방송 프로그램명 위치/스타일 | P1 |
| GEB-031 | 로고 영역 | 방송사/스폰서 로고 위치 | P1 |
| GEB-032 | 라운드 표시 영역 | Pre-Flop ~ River 텍스트 위치 | P1 |
| GEB-033 | 승률 바 영역 | 전체 승률 바 위치/크기 | P1 |
| GEB-034 | 캔버스 크기 | 편집 캔버스 해상도 | P0 |
| GEB-035 | 배경색/이미지 | 캔버스 배경 설정 | P0 |
| GEB-036 | 그리드 표시 | 정렬 보조 그리드 | P1 |
| GEB-037 | 줌 제어 | 캔버스 확대/축소 | P1 |
| GEB-038 | 실행취소/다시실행 | Undo/Redo | P0 |
| GEB-039 | 미리보기 모드 | 실제 데이터로 미리보기 | P1 |

### 4.11 Graphic Editor - Player (플레이어 그래픽 편집기)

![Graphic Editor Player](images/annotated/11-graphic-editor-player.png)

개별 플레이어 좌석의 그래픽 요소(이름, 칩, 홀카드, 상태 표시)를 편집합니다.

| ID | 기능 | 설명 | 우선순위 |
|----|------|------|:--------:|
| GEP-001 | 플레이어 이름 영역 | 이름 텍스트 위치/스타일 | P0 |
| GEP-002 | 칩 카운트 영역 | 칩 수량 텍스트 위치/스타일 | P0 |
| GEP-003 | 홀카드 영역 | 카드 2장 위치/크기 | P0 |
| GEP-004 | 홀카드 3장 | Omaha용 3-4장 카드 레이아웃 | P0 |
| GEP-005 | 홀카드 4장 | PLO, Badugi용 4장 카드 레이아웃 | P0 |
| GEP-006 | 홀카드 5장 | 5-Card Draw용 5장 레이아웃 | P1 |
| GEP-007 | 베팅 금액 영역 | 현재 라운드 베팅액 위치 | P0 |
| GEP-008 | 액션 표시 영역 | Fold/Call/Raise/Check 텍스트 위치 | P0 |
| GEP-009 | 승률 표시 영역 | 개별 승률 % 위치 | P0 |
| GEP-010 | 핸드 랭크 영역 | 현재 핸드 등급 텍스트 | P0 |
| GEP-011 | 국가 플래그 영역 | 국기 아이콘 위치/크기 | P1 |
| GEP-012 | 프로필 사진 영역 | 플레이어 사진 위치/크기 | P1 |
| GEP-013 | 딜러 버튼 위치 | D 마커 좌석 상대 위치 | P0 |
| GEP-014 | SB/BB 마커 | 블라인드 마커 위치 | P0 |
| GEP-015 | All-in 효과 | All-in 시 시각 효과 | P1 |
| GEP-016 | Fold 효과 | Fold 시 시각 처리 (회색, 투명도) | P0 |
| GEP-017 | 승자 하이라이트 | Showdown 승자 강조 효과 | P0 |
| GEP-018 | Bounty 영역 | 바운티 금액 위치 | P1 |
| GEP-019 | 스트래들 표시 | Straddle 마커 | P2 |
| GEP-020 | 배경 박스 | 플레이어 정보 배경 | P0 |
| GEP-021 | 테두리 | 플레이어 박스 테두리 | P1 |
| GEP-022 | 폰트 설정 (이름) | 이름 전용 폰트/크기/색상 | P0 |
| GEP-023 | 폰트 설정 (칩) | 칩 카운트 전용 폰트 | P0 |
| GEP-024 | 폰트 설정 (액션) | 액션 텍스트 전용 폰트 | P0 |
| GEP-025 | 폰트 설정 (승률) | 승률 텍스트 전용 폰트 | P1 |
| GEP-026 | 카드 애니메이션 | 카드 등장 애니메이션 설정 | P1 |
| GEP-027 | 칩 애니메이션 | 칩 이동 애니메이션 | P1 |
| GEP-028 | 액션 애니메이션 | 액션 텍스트 등장 효과 | P1 |
| GEP-029 | 타임뱅크 표시 | 타임뱅크 잔여 시간 | P2 |
| GEP-030 | 시계 오버레이 | Action Clock 연동 표시 | P1 |
| GEP-031 | Stud 전용 레이아웃 | 7장 Stud 카드 배치 (up/down) | P1 |
| GEP-032 | Draw 전용 레이아웃 | Draw 게임 교환 카드 표시 | P1 |
| GEP-033 | Hi-Lo 분할 표시 | Hi-Lo 게임 승자 2인 표시 | P1 |
| GEP-034 | 요소 복제 | 그래픽 요소 복사 | P1 |
| GEP-035 | 요소 삭제 | 그래픽 요소 제거 | P0 |
| GEP-036 | z-order | 요소 순서 변경 | P0 |
| GEP-037 | 그룹 편집 | 연관 요소 그룹 편집 | P2 |
| GEP-038 | 미리보기 | 실제 데이터 기반 프리뷰 | P1 |

**Overlay 요소** (플레이어 위에 겹쳐 표시):

| ID | 기능 | 설명 | 우선순위 |
|----|------|------|:--------:|
| OVL-001 | 카드 하이라이트 | 승리 카드 강조 테두리 | P1 |
| OVL-002 | 베스트 핸드 마킹 | 5장 베스트 핸드 강조 | P1 |
| OVL-003 | 팟 획득 애니메이션 | 칩 이동 애니메이션 | P2 |
| OVL-004 | 카드 딜 애니메이션 | 덱에서 카드 이동 | P2 |
| OVL-005 | 사이드팟 라벨 | 사이드팟 귀속 플레이어 표시 | P1 |
| OVL-006 | Bubble 효과 | 토너먼트 버블 시 특수 효과 | P2 |
| OVL-007 | 채팅 말풍선 | 플레이어 발언 표시 | P2 |
| OVL-008 | 감정 이모지 | 플레이어 감정 아이콘 | P2 |

---

## Part 5. 게임 엔진

### 5.1 22개 포커 게임 변형

원본 시스템은 3개 계열, 22개 포커 변형을 지원합니다. 각 게임의 enum 값은 네트워크 프로토콜과 핸드 평가기에서 직접 사용되므로 정확히 일치해야 합니다.

#### game enum 정의

```csharp
enum game {
    holdem = 0,
    holdem_sixplus_straight_beats_trips = 1,    // Short Deck (Straight > Trips)
    holdem_sixplus_trips_beats_straight = 2,    // Short Deck (Trips > Straight)
    pineapple = 3,
    omaha = 4,
    omaha_hilo = 5,
    omaha5 = 6,                                 // Five Card Omaha
    omaha5_hilo = 7,
    omaha6 = 8,                                 // Six Card Omaha
    omaha6_hilo = 9,
    courchevel = 10,
    courchevel_hilo = 11,
    draw5 = 12,                                 // Five Card Draw
    deuce7_draw = 13,                           // 2-7 Single Draw
    deuce7_triple = 14,                         // 2-7 Triple Draw
    a5_triple = 15,                             // A-5 Triple Draw
    badugi = 16,
    badeucy = 17,
    badacey = 18,                               // Badeucey (원본 표기: badacey)
    stud7 = 19,                                 // 7-Card Stud
    stud7_hilo8 = 20,                           // 7-Card Stud Hi-Lo
    razz = 21
}
```

#### game_class enum

```csharp
enum game_class {
    flop = 0,    // Community Card 계열
    draw = 1,    // Draw 계열
    stud = 2     // Stud 계열
}
```

#### 계열별 게임 분류 및 구현 우선순위 (원본 enum 값 기준)

**Community Card 계열 (game_class = flop)**: 13개

| game enum | 게임명 | 홀카드 | 보드 | 특수 규칙 | Phase |
|:---------:|--------|:------:|:----:|----------|:-----:|
| 0 | Texas Hold'em | 2장 | 5장 | 표준 | 1 |
| 1 | 6+ Hold'em (Straight > Trips) | 2장 | 5장 | 2-5 제거, Straight > Trips | 2 |
| 2 | 6+ Hold'em (Trips > Straight) | 2장 | 5장 | 2-5 제거, Trips > Straight | 2 |
| 3 | Pineapple | 3장→2장 | 5장 | Flop 전 1장 버림 | 3 |
| 4 | Omaha | 4장 | 5장 | 반드시 2장 사용 | 1 |
| 5 | Omaha Hi-Lo | 4장 | 5장 | Hi/Lo 분할 | 2 |
| 6 | Five Card Omaha | 5장 | 5장 | 반드시 2장 사용 | 3 |
| 7 | Five Card Omaha Hi-Lo | 5장 | 5장 | Hi/Lo | 3 |
| 8 | Six Card Omaha | 6장 | 5장 | 반드시 2장 사용 | 4 |
| 9 | Six Card Omaha Hi-Lo | 6장 | 5장 | Hi/Lo | 4 |
| 10 | Courchevel | 5장 | 5장 | 첫 Flop 1장 미리 공개 | 3 |
| 11 | Courchevel Hi-Lo | 5장 | 5장 | Hi/Lo + 미리 공개 | 3 |

**Draw 계열 (game_class = draw)**: 6개

| game enum | 게임명 | 카드 | 교환 | 특수 규칙 | Phase |
|:---------:|--------|:----:|:----:|----------|:-----:|
| 12 | Five Card Draw | 5장 | 1회 | 기본 Draw | 3 |
| 13 | Single Draw 2-7 | 5장 | 1회 | Lowball | 3 |
| 14 | Triple Draw 2-7 | 5장 | 3회 | Lowball | 3 |
| 15 | A-5 Triple Draw | 5장 | 3회 | A-5 Lowball | 4 |
| 16 | Badugi | 4장 | 3회 | 4장 Lowball, 무늬 다른 게 유리 | 4 |
| 17 | Badeucy | 5장 | 3회 | Badugi + 2-7 혼합 | 5 |
| 18 | Badacey | 5장 | 3회 | Badugi + A-5 혼합 | 5 |

**Stud 계열 (game_class = stud)**: 3개

| game enum | 게임명 | 카드 | 라운드 | 특수 규칙 | Phase |
|:---------:|--------|:----:|:------:|----------|:-----:|
| 19 | 7-Card Stud | 7장 | 5 | 3 down + 4 up | 3 |
| 20 | 7-Card Stud Hi-Lo | 7장 | 5 | Hi/Lo 분할 | 3 |
| 21 | Razz | 7장 | 5 | Lowball Stud | 3 |

### 5.2 핸드 평가 엔진

#### 카드 표현: 64-bit Bitmask

원본 시스템은 52장 카드를 64-bit unsigned long 비트마스크로 표현합니다.

```
비트 위치:
  0-12:  Clubs    (2♣=0, 3♣=1, ..., A♣=12)
 13-25:  Diamonds (2♦=13, 3♦=14, ..., A♦=25)
 26-38:  Hearts   (2♥=26, 3♥=27, ..., A♥=38)
 39-51:  Spades   (2♠=39, 3♠=40, ..., A♠=51)
```

Clone에서의 구현:

```csharp
public readonly record struct CardMask
{
    private readonly ulong _mask;

    public CardMask(ulong mask) => _mask = mask;

    public static CardMask FromCard(int rank, int suit)
        => new(1UL << (suit * 13 + rank));

    public CardMask Add(CardMask other)
        => new(_mask | other._mask);

    public int PopCount()
        => BitOperations.PopCount(_mask);

    public bool Contains(CardMask card)
        => (_mask & card._mask) != 0;
}
```

#### card_type enum (53개 값)

```csharp
enum card_type {
    card_back = 0,       // 카드 뒷면
    clubs_two = 1,       // 2♣
    clubs_three = 2,     // 3♣
    // ... 순서대로
    spades_ace = 52      // A♠
}
```

#### hand_class enum (핸드 등급)

```csharp
enum hand_class {
    high_card = 0,
    one_pair = 1,
    two_pair = 2,
    three_of_a_kind = 3,
    straight = 4,
    flush = 5,
    full_house = 6,
    four_of_a_kind = 7,
    straight_flush = 8,
    royal_flush = 9      // straight_flush의 특수 케이스
}
```

#### HandValue 인코딩

```
[31-28] 미사용
[27-24] HandType (0-8, hand_class에 대응)
[23-0]  Sub-rank (동일 핸드 내 세부 순위)
```

비교 시 `HandValue` 값을 정수로 직접 비교하면 됩니다. 큰 값이 더 강한 핸드.

#### Lookup Table 아키텍처

원본 hand_eval.dll은 538개의 static lookup 배열을 내장합니다.

| 배열 크기 | 개수 | 용도 |
|----------|:----:|------|
| 32 bytes | 2 | 소형 변환 테이블 |
| 512 bytes | 8 | 카드-비트 매핑 |
| 1,024 bytes | 5 | 랭크 추출 |
| 4,096 bytes | 4 | Flush 판정 |
| 8,192 bytes | 4 | Straight 판정 |
| 16,384 bytes | 3 | 복합 핸드 판정 |
| 32,768 bytes | 3 | 최종 핸드 등급 |

총 29가지 크기, 약 2.1MB의 lookup 데이터.

**주요 Lookup Table 상세**:
- `TWO_PLUS_TWO`: 32.5MB (7-card 평가 핵심, 133,784,560 엔트리)
- `DAG_TABLE`: Directed Acyclic Graph 기반 평가
- `FLUSH_TABLE`: Flush 핸드 빠른 판정
- `STRAIGHT_TABLE`: Straight 패턴 매칭

Clone에서는 C# Source Generator로 빌드 타임에 lookup 배열을 자동 생성합니다.

```csharp
[GeneratedLookupTable]
public static partial class HandTables
{
    // Source Generator가 538개 배열을 ReadOnlySpan<byte>로 생성
}
```

#### 17개 게임별 평가기

| 평가기 | 대상 게임 | 알고리즘 핵심 |
|--------|----------|--------------|
| evaluate_holdem | Hold'em (0) | 7장 중 최강 5장 조합 |
| evaluate_omaha | Omaha (1) | 홀카드 2장 + 보드 3장 강제 |
| evaluate_omaha_hilo | Omaha Hi-Lo (2) | Hi/Lo 동시 평가, 8-or-better |
| evaluate_courchevel | Courchevel (3) | 5장 홀카드 중 2장 + 보드 3장 |
| evaluate_fivecard_omaha | 5-Card Omaha (5) | 5장 중 2장 선택 + 보드 3장 |
| evaluate_sixcard_omaha | 6-Card Omaha (7) | 6장 중 2장 선택 + 보드 3장 |
| evaluate_irish | Irish (8) | Flop 후 2장 버림 → Hold'em |
| evaluate_pineapple | Pineapple (20) | 3장 중 Flop 전 1장 버림 |
| evaluate_showtime | Showtime (21) | 폴드 카드 공개 정보 반영 |
| evaluate_sixplus | 6+ Hold'em (18) | Flush > Full House 규칙 |
| evaluate_draw | 5-Card Draw (9) | 최종 5장 평가 |
| evaluate_27_lowball | 2-7 Draw (10,11) | Lowball (A는 High) |
| evaluate_badugi | Badugi (12) | 4장, 무늬 모두 다른 조합 |
| evaluate_badeucy | Badeucy (13) | Badugi + 2-7 복합 |
| evaluate_badeucey | Badeucey (14) | Badugi + A-5 복합 |
| evaluate_stud | 7-Card Stud (15) | 7장 중 최강 5장 |
| evaluate_razz | Razz (17) | A-5 Lowball Stud |

#### 승률 계산: Monte Carlo 시뮬레이션

원본 시스템은 적응형 임계값 Monte Carlo를 사용합니다.

```
전체 조합 수 < 5,000     → 전수 열거 (Exhaustive)
전체 조합 수 < 100,000   → Monte Carlo 10,000회
전체 조합 수 >= 100,000  → Monte Carlo 5,000회
```

Clone에서는 TPL + SIMD를 활용하여 병렬 Monte Carlo를 구현합니다.

```csharp
public class MonteCarloEvaluator
{
    public async Task<WinProbability[]> CalculateAsync(
        GameState state,
        int iterations = 10_000,
        CancellationToken ct = default)
    {
        // TPL Parallel.ForEach로 코어 분산
        // SIMD Vector<ulong>로 비트 연산 가속
        // CardMask 기반 중복 없는 랜덤 카드 생성
    }
}
```

### 5.3 핵심 데이터 구조: GameTypeData 분해

원본 `GameTypeData`는 79개 이상의 필드를 가진 God Object입니다. Clone에서는 6개의 도메인 Record로 분해합니다.

| Clone Record | 필드 수 | 원본 필드 예시 |
|-------------|:-------:|--------------|
| `GameSession` | ~15 | hand_number, game_type, blind_level |
| `TableState` | ~12 | pot_size, side_pots[], community_cards[] |
| `PlayerState` | ~10 (x10) | name, chip_count, hole_cards[], is_folded |
| `BettingState` | ~8 | current_bet, min_raise, betting_round |
| `DisplayState` | ~15 | show_holecards[], animation_flags |
| `TournamentState` | ~12 | blind_timer, payout_structure, bounties[] |

```csharp
public sealed record GameSession(
    int HandNumber,
    game GameType,
    game_class GameClass,
    decimal SmallBlind,
    decimal BigBlind,
    int DealerSeat);

public sealed record PlayerState(
    int Seat,
    string Name,
    decimal ChipCount,
    CardMask HoleCards,
    bool IsFolded,
    bool IsAllIn,
    string Country,
    decimal? Bounty);
```

### 5.4 설정 구조: config_type 분해

원본 `config_type`은 282개 필드를 가진 단일 클래스입니다. Clone에서는 11개 도메인 Record로 분해합니다.

| Clone Record | 필드 수 | 관리 영역 |
|-------------|:-------:|----------|
| `ServerConfig` | ~25 | 서버 포트, IP, 라이선스 |
| `RfidConfig` | ~30 | 리더 IP, 포트, 좌석 매핑 |
| `RenderConfig` | ~25 | GPU, 해상도, 프레임레이트 |
| `NetworkConfig` | ~20 | TCP/UDP 포트, 암호화 설정 |
| `GameConfig` | ~30 | 게임 규칙, 블라인드, 타이머 |
| `OutputConfig` | ~25 | NDI, HDMI, SDI, 크로마키 |
| `SkinConfig` | ~20 | 스킨 경로, 기본 스킨, 테마 |
| `AnalyticsConfig` | ~20 | 통계 DB, 추적 항목 |
| `SecurityConfig` | ~15 | 암호화, Trustless 모드 |
| `ExternalConfig` | ~20 | ATEM, Twitch, StreamDeck |
| `UiConfig` | ~15 | 언어, 단축키, 레이아웃 |

---

## Part 6. 핵심 기술 컴포넌트

### 6.1 RFID 카드 리더 시스템

#### 하드웨어 구성

| 위치 | 수량 | 역할 |
|------|:----:|------|
| 좌석별 리더 | 10대 | 플레이어 홀카드 인식 |
| 보드 리더 | 1대 | 커뮤니티 카드 인식 |
| Muck 리더 | 1대 | 폴드 카드 확인 |
| **합계** | **12대** | 동시 운용 |

#### 이중 전송 프로토콜

| 프로토콜 | 인터페이스 | 보안 | 대상 장비 |
|----------|----------|------|----------|
| RFID v2 | TCP/WiFi | BearSSL TLS 1.2 | 신형 WiFi 리더 |
| SkyeTek | USB HID | 없음 | 기존 USB 리더 |

Clone에서는 BearSSL 대신 .NET SslStream을 사용합니다.

#### reader_state 상태 머신

```csharp
enum reader_state {
    disconnected = 0,
    connected = 1,
    negotiating = 2,
    ok = 3
}
```

```
[disconnected] ──connect──▶ [connected] ──TLS──▶ [negotiating] ──auth──▶ [ok]
      ▲                                                                    │
      └────────────────────error/timeout───────────────────────────────────┘
```

#### wlan_state 상태 머신

```csharp
enum wlan_state {
    off = 0,
    on = 1,
    connected_reset = 2,
    ip_acquired = 3,
    not_installed = 4
}
```

#### 22개 텍스트 커맨드 (원본 역공학 코드)

RFID 리더와의 통신은 텍스트 기반 커맨드로 이루어집니다. 아래는 원본 RFIDv2.dll에서 추출한 실제 명령어 목록입니다.

| 커맨드 | 설명 |
|--------|------|
| `TI` | Tag Inventory - 태그 목록 조회 |
| `TR` | Tag Read - 태그 읽기 |
| `TW` | Tag Write - 태그 쓰기 |
| `AU` | Authentication - 인증 |
| `FW` | Firmware - 펌웨어 업데이트 |
| `GM` | Get 모듈 - 모듈 정보 조회 |
| `GN` | Get Name - 리더 이름 조회 |
| `GP` | Get Password - 비밀번호 조회 |
| `SM` | Set 모듈 - 모듈 설정 |
| `SN` | Set Name - 리더 이름 설정 |
| `SP` | Set Password - 비밀번호 설정 |
| `GH` | Get Hardware - 하드웨어 버전 조회 |
| `GF` | Get Firmware - 펌웨어 버전 조회 |
| `GV` | Get Version - 전체 버전 정보 |
| `GO` | Get WLAN - 무선랜 설정 조회 |
| `SO` | Set WLAN - 무선랜 설정 변경 |
| `GI` | Get IP - IP 주소 조회 |
| `SI` | Set IP - IP 주소 설정 |
| `GS` | Get SSID - WiFi SSID 조회 |
| `SS` | Set SSID - WiFi SSID 설정 |
| `GW` | Get WiFi Password - WiFi 비밀번호 조회 |
| `SW` | Set WiFi Password - WiFi 비밀번호 설정 |

#### Clone RFID 드라이버 구조

```csharp
public interface IRfidReader : IAsyncDisposable
{
    reader_state State { get; }
    IAsyncEnumerable<CardDetectedEvent> ReadCardsAsync(CancellationToken ct);
    Task ConnectAsync(RfidReaderConfig config, CancellationToken ct);
    Task DisconnectAsync();
}

// WiFi 리더 구현
public class TcpRfidReader : IRfidReader
{
    private SslStream? _sslStream;  // BearSSL → .NET SslStream
    // ...
}

// USB 리더 구현
public class UsbHidRfidReader : IRfidReader
{
    // HID API를 통한 SkyeTek 프로토콜
}

// 통합 관리자
public class RfidManager
{
    private readonly IRfidReader[] _readers = new IRfidReader[12];

    public IAsyncEnumerable<CardDetectedEvent> MonitorAllAsync(CancellationToken ct)
    {
        // 12대 리더를 동시 모니터링
        // Channel<T>로 이벤트 통합
    }
}
```

### 6.2 GPU 렌더링 엔진

#### 원본 아키텍처: 5-Thread Producer-Consumer

```
Thread 1: Input Thread
    │  비디오 소스 캡처 (MFormats)
    ▼
Thread 2: Mixer Thread
    │  그래픽 요소 합성 (90+ 필드)
    │  image_element, text_element, pip, border 처리
    ▼
Thread 3: Live Canvas Thread
    │  실시간 출력 (홀카드 표시 여부 제어)
    ▼
Thread 4: Delayed Canvas Thread
    │  지연 출력 (설정된 초만큼 지연)
    ▼
Thread 5: Output Thread
       NDI/HDMI/SDI 출력
```

#### Dual Canvas 시스템

| Canvas | 용도 | 홀카드 표시 | 대상 |
|--------|------|:----------:|------|
| Live Canvas | 경기장 모니터 | Trustless 시 숨김 | 선수, 관객 |
| Delayed Canvas | 방송 송출 | 지연 후 표시 | 시청자 |

Trustless 모드에서는 Live Canvas에 홀카드를 절대 표시하지 않습니다. 이것은 게임 무결성을 위한 핵심 보안 기능입니다.

#### 4가지 그래픽 요소 타입

**image_element** (이미지 요소, 41개 필드):

| 필드 | 타입 | 설명 |
|------|------|------|
| x, y | float | 위치 |
| width, height | float | 크기 |
| source_path | string | 이미지 파일 경로 |
| opacity | float | 투명도 (0-1) |
| rotation | float | 회전 각도 |
| visible | bool | 표시 여부 |
| z_order | int | 렌더링 순서 |
| animation_state | AnimationState | 현재 애니메이션 상태 |
| crop_rect | Rect | 자르기 영역 |
| flip_h, flip_v | bool | 좌우/상하 반전 |
| tint_color | Color | 색상 틴트 |
| shadow_offset | Vector2 | 그림자 오프셋 |
| shadow_blur | float | 그림자 블러 |
| shadow_color | Color | 그림자 색상 |

**text_element** (텍스트 요소, 52개 필드):

| 필드 | 타입 | 설명 |
|------|------|------|
| x, y | float | 위치 |
| width, height | float | 영역 크기 |
| text | string | 표시할 텍스트 |
| font_family | string | 글꼴 이름 |
| font_size | float | 글꼴 크기 |
| font_color | Color | 글자 색상 |
| font_weight | FontWeight | 굵기 |
| font_style | FontStyle | 이탤릭 등 |
| text_align | TextAlignment | 좌/중/우 정렬 |
| vertical_align | VerticalAlignment | 상/중/하 정렬 |
| word_wrap | bool | 줄바꿈 |
| max_lines | int | 최대 줄 수 |
| outline_color | Color | 외곽선 색상 |
| outline_width | float | 외곽선 두께 |
| shadow_offset | Vector2 | 그림자 |
| background_color | Color | 배경색 |
| padding | Thickness | 내부 여백 |
| border_color | Color | 테두리 색상 |
| border_width | float | 테두리 두께 |
| animation_state | AnimationState | 애니메이션 상태 |

**pip** (카드 문양, 12개 필드):

| 필드 | 타입 | 설명 |
|------|------|------|
| x, y | float | 위치 |
| size | float | 크기 |
| suit | int | 문양 (0=Club, 1=Diamond, 2=Heart, 3=Spade) |
| rank | int | 숫자 (0=2, 12=A) |
| face_up | bool | 앞면/뒷면 |
| highlighted | bool | 강조 표시 |
| animation_state | AnimationState | 애니메이션 |

**border** (테두리, 필드 수 적음):
- x, y, width, height, color, thickness, corner_radius, visible

#### AnimationState enum (16개 상태, 원본 역공학 값)

```csharp
enum AnimationState {
    FadeIn = 0,
    Glint = 1,
    GlintGrow = 2,
    GlintRotateFront = 3,
    GlintShrink = 4,
    PreStart = 5,
    ResetRotateBack = 6,
    ResetRotateFront = 7,
    Resetting = 8,
    RotateBack = 9,
    Scale = 10,
    SlideAndDarken = 11,
    SlideDownRotateBack = 12,
    SlideUp = 13,
    Stop = 14,
    Waiting = 15
}
```

#### 11개 애니메이션 클래스

| 클래스 | 설명 | 일반적 용도 |
|--------|------|------------|
| FadeAnimation | 투명도 전환 | 카드 등장/퇴장 |
| SlideAnimation | 위치 이동 | 하단 자막 슬라이드 |
| ScaleAnimation | 크기 변환 | 승자 확대 |
| RotateAnimation | 회전 | 카드 뒤집기 |
| ColorAnimation | 색상 전환 | 강조 효과 |
| BlinkAnimation | 깜빡임 | 주의 끌기 |
| BounceAnimation | 튕김 | 칩 이동 |
| WipeAnimation | 닦아내기 | 장면 전환 |
| FlipAnimation | 뒤집기 | 카드 공개 |
| ShakeAnimation | 흔들림 | All-in 효과 |
| SequenceAnimation | 연속 재생 | 복합 애니메이션 |

#### Clone GPU 렌더링 구현

```csharp
// SharpDX (DX11) → Vortice.Windows (DX12) 교체

public class DirectX12Renderer : IDisposable
{
    private ID3D12Device _device;
    private ID3D12CommandQueue _commandQueue;
    private IDXGISwapChain4 _swapChain;

    // 5-Thread 파이프라인 유지
    // BlockingCollection<T> → Channel<T> 교체 (성능 향상)

    private readonly Channel<RenderFrame> _mixerToLive;
    private readonly Channel<RenderFrame> _mixerToDelayed;
}
```

#### Cross-GPU 텍스처 공유

Dual Canvas가 서로 다른 GPU에서 렌더링될 수 있으므로, DXGI SharedHandle을 통한 Cross-GPU 텍스처 공유가 필요합니다.

```csharp
public class GpuTextureBridge
{
    public SharedTextureHandle Share(ID3D12Resource texture)
    {
        // 1. 텍스처에서 SharedHandle 생성
        // 2. 다른 GPU의 Device에서 OpenSharedHandle
        // 3. 공유 텍스처로 렌더링
        return new SharedTextureHandle(handle);
    }
}
```

### 6.3 네트워크 프로토콜

#### 4계층 프로토콜 스택

```
┌─────────────────────────────────────────┐
│  Application Layer                       │
│  113+ 커맨드 (IRemoteRequest/Response)   │
├─────────────────────────────────────────┤
│  Serialization Layer                     │
│  원본: JSON (Newtonsoft.Json)            │
│  Clone: Protobuf + System.Text.Json     │
├─────────────────────────────────────────┤
│  Security Layer                          │
│  AES-256 Rijndael + PBKDF1              │
├─────────────────────────────────────────┤
│  Transport Layer                         │
│  TCP (메인) + UDP (Discovery)            │
└─────────────────────────────────────────┘
```

#### 원본 TCP Wire Format

```
[Base64(AES(JSON))][0x01]
```

- 메시지를 JSON으로 직렬화
- AES-256으로 암호화
- Base64로 인코딩
- SOH (0x01) 구분자로 메시지 끝 표시

#### 원본 AES 암호화 파라미터 (net_conn)

```csharp
// 역공학으로 추출한 원본 하드코딩 값 (참조용, Clone에서는 사용 금지)
Password = "45389rgjkonlgfds90439r043rtjfewp9042390j4f"
Salt     = "dsafgfdagtds4389tytgh"
IV       = "4390fjrfvfji9043"
Algorithm = Rijndael (AES-256-CBC)
Key Derivation = PBKDF1
```

Clone에서는 이 하드코딩 값 대신, 서버 시작 시 안전한 키를 생성하고 TLS를 통해 교환합니다.

#### Clone 네트워크 전환: TCP+JSON → gRPC+Protobuf

| 항목 | 원본 | Clone |
|------|------|-------|
| 전송 | Raw TCP | gRPC (HTTP/2) |
| 직렬화 | Newtonsoft.Json | Protobuf (+ System.Text.Json fallback) |
| 암호화 | AES-256 수동 | TLS 1.3 내장 |
| 구분자 | SOH (0x01) | HTTP/2 프레이밍 |
| 검색 | UDP Broadcast | mDNS/DNS-SD |
| 커맨드 라우팅 | Reflection (RemoteRegistry) | Source Generator |

#### UDP Discovery 프로토콜

원본은 UDP 포트 9000/9001/9002에서 서버 검색을 지원합니다.

```
Client                          Server
  │                               │
  ├── UDP Broadcast ──────────▶  │  (포트 9000)
  │   "DISCOVER_SERVER"          │
  │                               │
  │  ◀──── UDP Response ─────── │
  │   ServerInfo {               │
  │     ip, port, name,          │
  │     version, game_type       │
  │   }                          │
  │                               │
  ├── TCP Connect ───────────▶  │  (응답받은 포트)
  │                               │
  ├── Login Request ─────────▶  │
  │  ◀──── Login Response ───── │
  │   { session_id, permissions } │
  └────────────────────────────── │
```

Clone에서는 UDP Broadcast 대신 mDNS/DNS-SD를 사용하되, 레거시 호환을 위해 UDP Discovery도 병행합니다.

#### 113+ 커맨드 카테고리 (전체 명령어 상세)

원본 프로토콜의 전체 커맨드 목록은 다음과 같이 구성됩니다.

**Connection (연결 관리) - 9개**
- `CONNECT`, `DISCONNECT`, `AUTH`, `KEEPALIVE`, `IDTX`, `GAME_STATE`, `GAME_VARIANT_LIST`, `COUNTRY_LIST`, `MEDIA_LIST`

**Game (게임 제어) - 10개**
- `GAME_INFO`, `NEW_HAND`, `END_HAND`, `NIT_GAME`, `GAME_TYPE`, `GAME_VARIANT`, `GAME_CLEAR`, `GAME_TITLE`, `GAME_SAVE_BACK`, `GAME_STATE`

**Player (플레이어 관리) - 21개**
- `PLAYER_INFO`, `PLAYER_CARDS`, `PLAYER_BET`, `PLAYER_BLIND`, `PLAYER_ADD`, `PLAYER_DELETE`, `PLAYER_COUNTRY`, `PLAYER_DEAD_BET`, `PLAYER_PICTURE`, `DELAYED_PLAYER_INFO`
- 기타 11개: PLAYER_STATUS, PLAYER_ACTION, PLAYER_STACK, PLAYER_POSITION, PLAYER_STATS 등

**Cards & Board (카드/보드) - 6개**
- `BOARD_CARD`, `CARD_VERIFY`, `FORCE_CARD_SCAN`, `DRAW_DONE`, `EDIT_BOARD`, `CARD_REVEAL`

**Display (디스플레이/UI) - 13개**
- `FIELD_VISIBILITY`, `FIELD_VAL`, `GFX_ENABLE`, `ENH_MODE`, `SHOW_PANEL`, `STRIP_DISPLAY`, `BOARD_LOGO`, `PANEL_LOGO`, `ACTION_CLOCK`, `DELAYED_FIELD_VISIBILITY`, `DELAYED_GAME_INFO`
- 기타 2개: SHOW_ANIMATION, HIDE_ANIMATION

**Media (미디어/카메라) - 9개**
- `MEDIA_LIST`, `MEDIA_PLAY`, `MEDIA_LOOP`, `CAM`, `PIP`, `CAP`, `GET_VIDEO_SOURCES`, `VIDEO_SOURCES`, `SOURCE_MODE`

**RFID (리더 상태) - 1개**
- `READER_STATUS`

**Betting (베팅/재무) - 5개**
- `PAYOUT`, `MISS_DEAL`, `CHOP`, `FORCE_HEADS_UP`, `FORCE_HEADS_UP_DELAYED`

**Data Transfer (데이터 전송) - 4개**
- `SKIN_CHUNK`, `COMM_DL`, `AT_DL`, `VTO`

**History (기록/로그) - 4개**
- `HAND_HISTORY`, `HAND_LOG`, `GAME_LOG`, `COUNTRY_LIST`

> **상세 명세**: 각 커맨드의 파라미터, 응답 구조, 사용 시나리오는 `docs/01-plan/clone-prd-wave3.md` 섹션 9.6 참조

#### GameInfoResponse (75+ 필드, 카테고리별)

게임 상태 동기화의 핵심 메시지입니다.

| 카테고리 | 필드 수 | 주요 필드 |
|----------|:-------:|----------|
| 핸드 정보 | 8 | hand_number, game_type, game_class, betting_round |
| 블라인드 | 6 | small_blind, big_blind, ante, straddle |
| 플레이어 | 20 | players[10] { name, chips, cards, status } |
| 팟 | 5 | main_pot, side_pots[], total_pot |
| 보드 | 7 | board_cards[5], board_count |
| 승률 | 10 | win_pct[10], equity[10] |
| 타이머 | 5 | shot_clock, time_bank |
| 상태 플래그 | 14 | is_paused, is_break, show_cards_flags |

#### PlayerInfoResponse (20 필드)

| 필드 | 타입 | CSV Index |
|------|------|:---------:|
| seat | int | 0 |
| name | string | 1 |
| chip_count | decimal | 2 |
| hole_card_1 | card_type | 3 |
| hole_card_2 | card_type | 4 |
| hole_card_3 | card_type | 5 |
| hole_card_4 | card_type | 6 |
| is_folded | bool | 7 |
| is_all_in | bool | 8 |
| current_bet | decimal | 9 |
| total_bet | decimal | 10 |
| action | string | 11 |
| country | string | 12 |
| bounty | decimal | 13 |
| hand_rank | hand_class | 14 |
| win_pct | float | 15 |
| vpip | float | 16 |
| pfr | float | 17 |
| af | float | 18 |
| hands_played | int | 19 |

#### IClientNetworkListener (16개 콜백)

클라이언트가 구현해야 하는 네트워크 이벤트 인터페이스입니다.

```csharp
public interface IClientNetworkListener
{
    void OnConnected(ConnectionInfo info);
    void OnDisconnected(DisconnectReason reason);
    void OnGameStarted(GameStartedEvent e);
    void OnGameStopped();
    void OnNewHand(NewHandEvent e);
    void OnHandComplete(HandCompleteEvent e);
    void OnPlayerAction(PlayerActionEvent e);
    void OnCardDealt(CardDealtEvent e);
    void OnBoardCardDealt(BoardCardEvent e);
    void OnPotUpdated(PotUpdateEvent e);
    void OnWinProbabilityUpdated(WinProbEvent e);
    void OnOverlayChanged(OverlayEvent e);
    void OnConfigChanged(ConfigChangeEvent e);
    void OnError(ErrorEvent e);
    void OnSyncState(SyncStateEvent e);
    void OnChatMessage(ChatEvent e);
}
```

### 6.4 보안 시스템

#### 원본 4계층 DRM (참조)

```
Layer 1: Email/Password 로그인
    ▼
Layer 2: Offline Session 토큰
    ▼
Layer 3: KEYLOK USB 동글 (하드웨어 검증)
    ▼
Layer 4: Remote License Server (온라인 검증)
```

#### Clone 3계층 라이선스 (재설계)

```
Layer 1: Email/Password 로그인 (유지)
    ▼
Layer 2: JWT Access + Refresh Token (신규)
    ▼
Layer 3: 자체 라이선스 서버 (신규)
```

KEYLOK USB 동글은 제거합니다. 이는 원본 PokerGFX의 복제 방지 장치이므로, 자체 시스템에서는 불필요합니다. JWT 기반 라이선스로 대체합니다.

#### 원본 3중 AES 암호화 시스템 (참조)

| 시스템 | 용도 | 알고리즘 | 키 유도 |
|--------|------|----------|--------|
| net_conn | 네트워크 통신 | AES-256-CBC (Rijndael) | PBKDF1 |
| Common | 일반 데이터 | AES-256-CBC | Zero IV |
| Skin | 스킨 파일 | AES-256-CBC | SKIN_PWD |

Clone에서는 네트워크 암호화를 TLS 1.3으로 대체하고, 스킨 파일 암호화는 AES-256-GCM으로 현대화합니다.

#### 원본 LicenseType enum

```csharp
enum LicenseType {
    Basic = 1,
    Professional = 4,
    Enterprise = 5
}
```

### 6.5 스킨 시스템

#### 스킨 파일 포맷

| 확장자 | 용도 | 암호화 |
|--------|------|:------:|
| .vpt | 기본 스킨 포맷 | AES |
| .skn | 대안 스킨 포맷 | AES |

#### 스킨 구조

```
Skin File (.vpt)
├── Header (SKIN_HDR)
├── Metadata (이름, 버전, 작성자)
├── ConfigurationPreset (99+ 필드)
│   ├── 테이블 배경
│   ├── 좌석 위치 (10개)
│   ├── 카드 스킨
│   ├── 폰트 설정
│   ├── 색상 테마
│   ├── 애니메이션 설정
│   └── 레이아웃 정보
├── Board Elements (Graphic Editor Board 요소)
├── Player Elements (Graphic Editor Player 요소)
└── Embedded Assets (이미지, 폰트 파일)
```

#### ConfigurationPreset (99+ 필드, 카테고리별)

| 카테고리 | 필드 수 | 주요 설정 |
|----------|:-------:|----------|
| 테이블 | 15 | 배경 이미지, 크기, 색상 |
| 좌석 | 20 | 10개 좌석 X/Y 좌표 |
| 카드 | 10 | 앞/뒷면 이미지, 크기, 간격 |
| 폰트 | 15 | 이름, 크기, 색상 (요소별) |
| 색상 | 12 | 기본, 강조, 경고, 배경 |
| 애니메이션 | 10 | 속도, 종류, easing |
| 레이아웃 | 10 | 팟 위치, 보드 위치, 로고 |
| 기타 | 7 | 해상도, 여백, 투명도 |

#### skin_auth_result enum (원본 역공학 값)

```csharp
enum skin_auth_result {
    no_network = 0,
    permit = 1,
    deny = 2
}
```

### 6.6 외부 연동 서비스

#### ATEM Switcher 연동

Blackmagic ATEM 비디오 스위처를 원격 제어합니다.

```csharp
enum atem_state {
    NotInstalled = 0,
    Disconnected = 1,
    Connected = 2,
    Paused = 3,
    Reconnect = 4,
    Terminate = 5
}
```

Clone에서는 BMD Switcher SDK를 사용하며, 상태 머신은 동일하게 유지합니다.

#### Twitch 연동

원본은 IRC 기반 Twitch 채팅을 사용합니다. Clone에서는 EventSub으로 전환합니다.

| 항목 | 원본 | Clone |
|------|------|-------|
| 프로토콜 | IRC (TMI) | EventSub (WebSocket) |
| 인증 | OAuth Token | OAuth Token |
| 채팅 읽기 | PRIVMSG 파싱 | EventSub 구독 |
| 채팅 쓰기 | PRIVMSG 전송 | Helix API |

#### Master-Slave 아키텍처

다중 서버 구성으로 대규모 방송을 지원합니다.

```
Master Server
    │
    ├── 게임 상태 원본 보유
    ├── RFID 리더 직접 제어
    │
    ├──sync──▶ Slave Server 1 (다른 카메라 앵글)
    ├──sync──▶ Slave Server 2 (해설자 전용)
    └──sync──▶ Slave Server 3 (온라인 스트리밍)
```

Slave 동기화 항목:
- 게임 상태 (핸드, 카드, 팟)
- 플레이어 정보 (이름, 칩)
- 통계 데이터
- 스킨 설정 (선택적)

#### lang_enum (130개 값)

UI 다국어 지원을 위한 언어 목록입니다. 130개 언어 코드가 정의되어 있으나, 실제 번역은 영어 + 한국어를 우선 지원합니다.

---

## Part 7. 기술 스택

Part 1에서 설명한 "복제 후 개선" 전략에 따라, 원본 PokerGFX의 기술을 현대적 대안으로 교체합니다. 기능은 동일하게 유지하되, 기반 기술만 바꾸는 것이 핵심입니다.

### 7.1 원본 → Clone 기술 교체 전체 표

| 영역 | 원본 기술 | Clone 기술 | 교체 이유 |
|------|----------|-----------|----------|
| **프레임워크** | .NET Framework 4.x | .NET 8+ | LTS, 성능, 크로스플랫폼 |
| **UI** | WinForms (43개 Form) | WPF/Avalonia (30개 View) | MVVM, 데이터 바인딩, 현대적 UI |
| **GPU** | SharpDX (DirectX 11) | Vortice.Windows (DirectX 12) | 최신 API, 성능 향상 |
| **비디오 캡처** | MFormats SDK | FFmpeg.AutoGen | 오픈소스, 라이선스 비용 제거 |
| **네트워크** | Raw TCP + Newtonsoft.Json | gRPC + Protobuf | 타입 안전, 코드 생성, HTTP/2 |
| **암호화** | AES-256 수동 + BearSSL | TLS 1.3 (.NET SslStream) | 표준 프로토콜, 키 관리 자동 |
| **서비스 간 통신** | WCF | gRPC | WCF deprecated, 성능 |
| **직렬화** | Newtonsoft.Json + CSV | System.Text.Json + Protobuf | 성능, .NET 내장 |
| **ORM** | 없음 (파일 기반) | EF Core 8 | 구조적 데이터 관리 |
| **로깅** | Console.WriteLine | Serilog | 구조화 로깅, 다중 싱크 |
| **DI** | 없음 (God Class) | Microsoft.Extensions.DI | 테스트 용이, 결합도 감소 |
| **CQRS** | 없음 | MediatR | 명령/쿼리 분리, 파이프라인 |
| **테스트** | 없음 | xUnit + FluentAssertions | 품질 보증 |
| **DRM** | KEYLOK USB + 자체 서버 | JWT + 자체 라이선스 서버 | 하드웨어 의존 제거 |
| **난독화** | ConfuserEx + Dotfuscator | 없음 (자체 소유) | 불필요 |
| **큐/채널** | BlockingCollection<T> | Channel<T> | 성능, 비동기 지원 |
| **RFID TLS** | BearSSL (네이티브) | SslStream (.NET 내장) | 관리 코드, 유지보수 용이 |
| **서버 검색** | UDP Broadcast (9000-9002) | mDNS/DNS-SD + UDP (호환) | 표준 프로토콜 |
| **Twitch** | IRC (TMI) | EventSub (WebSocket) | IRC deprecated 예정 |

### 7.2 NuGet 패키지 목록

| 패키지 | 버전 | 용도 |
|--------|------|------|
| Vortice.Windows | 최신 | DirectX 12 바인딩 |
| FFmpeg.AutoGen | 최신 | 비디오 캡처/인코딩 |
| Grpc.Net.Client | 최신 | gRPC 클라이언트 |
| Grpc.AspNetCore | 최신 | gRPC 서버 |
| Google.Protobuf | 최신 | Protobuf 직렬화 |
| MediatR | 최신 | CQRS 파이프라인 |
| FluentValidation | 최신 | 입력 검증 |
| Serilog | 최신 | 구조화 로깅 |
| Serilog.Sinks.File | 최신 | 파일 로그 |
| Microsoft.EntityFrameworkCore | 8.x | ORM |
| Microsoft.EntityFrameworkCore.Sqlite | 8.x | 로컬 DB |
| xUnit | 최신 | 단위 테스트 |
| FluentAssertions | 최신 | 테스트 어서션 |
| NSubstitute | 최신 | 모킹 |
| BenchmarkDotNet | 최신 | 성능 벤치마크 |
| System.IO.Pipelines | 최신 | 고성능 IO |
| CommunityToolkit.Mvvm | 최신 | MVVM 유틸리티 |
| Avalonia | 최신 (또는 WPF) | UI 프레임워크 |

### 7.3 개발 도구

| 도구 | 용도 |
|------|------|
| Visual Studio 2022 | 메인 IDE |
| JetBrains Rider | 대안 IDE |
| Git + GitHub | 소스 관리 |
| GitHub Actions | CI/CD |
| Docker | 테스트 환경 |
| Playwright | E2E 테스트 |
| BenchmarkDotNet | 성능 측정 |

---

## Part 8. 구현 로드맵

### 8.1 6-Phase 로드맵 (복제 16주 + 연동 4주+)

```
Phase 1 (4주)    Phase 2 (3주)    Phase 3 (4주)    Phase 4 (3주)    Phase 5 (2주)
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Core     │    │ Network  │    │ Rendering│    │ Hardware │    │ Polish   │
│ Engine   │───▶│ + Proto  │───▶│ + UI     │───▶│ + Ext    │───▶│ + QA     │
│          │    │          │    │          │    │          │    │          │
│ 게임엔진  │    │ gRPC     │    │ DirectX  │    │ RFID     │    │ 통합테스트│
│ 핸드평가  │    │ 프로토콜  │    │ 스킨     │    │ ATEM     │    │ 성능최적화│
│ 도메인    │    │ 검색     │    │ 애니메이션│    │ Twitch   │    │ 문서화   │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
                                                                      │
                PokerGFX 복제 완료 (16주) ◀──────────────────────────────┘
                                                                      │
                                                                      ▼
                                                               Phase 6 (4주+)
                                                               ┌──────────┐
                                                               │ WSOP+    │
                                                               │ 연동     │
                                                               │          │
                                                               │ 대회 API │
                                                               │ 선수 DB  │
                                                               │ 다중 대회│
                                                               └──────────┘
```

### 8.2 Phase 1: Core Engine (4주)

**목표**: 게임 로직과 핸드 평가가 정확히 동작하는 서버 코어

#### Week 1: 프로젝트 구조 + 도메인 모델

| 작업 | 산출물 |
|------|--------|
| Solution 구조 생성 (7 프로젝트 + 5 테스트) | `.sln` 파일 |
| CardMask 구현 + 테스트 | `Domain/Cards/CardMask.cs` |
| card_type enum 정의 (53값) | `Domain/Cards/CardType.cs` |
| game enum 정의 (22값) | `Domain/Games/GameType.cs` |
| game_class enum 정의 (3값) | `Domain/Games/GameClass.cs` |
| hand_class enum 정의 (10값) | `Domain/HandEval/HandClass.cs` |
| GameSession Record | `Domain/Games/GameSession.cs` |
| PlayerState Record | `Domain/Games/PlayerState.cs` |
| TableState Record | `Domain/Games/TableState.cs` |

#### Week 2: 핸드 평가 엔진

| 작업 | 산출물 |
|------|--------|
| Source Generator로 538개 lookup 배열 생성 | `HandEval/LookupGenerator/` |
| evaluate_holdem 구현 + 테스트 | 1,000+ 테스트 케이스 |
| evaluate_omaha 구현 + 테스트 | Omaha 강제 2장 규칙 검증 |
| HandValue 인코딩 구현 | bits 24-27 HandType, bits 0-23 Sub-rank |
| Monte Carlo 기본 구현 | 10,000회 시뮬레이션 200ms 이내 |

#### Week 3: 게임 상태 머신

| 작업 | 산출물 |
|------|--------|
| Hold'em 게임 상태 머신 | Pre-Flop → Flop → Turn → River → Showdown |
| Omaha 게임 상태 머신 | 동일 구조, 다른 평가 규칙 |
| 베팅 로직 (Fold/Call/Raise/Check/AllIn) | BettingEngine 클래스 |
| 팟 계산 (메인팟 + 사이드팟) | PotCalculator 클래스 |
| 딜러 버튼/블라인드 자동 배치 | 포지션 관리 |

#### Week 4: CQRS + Application Layer

| 작업 | 산출물 |
|------|--------|
| MediatR 설정 + DI 구성 | `Application/` 전체 |
| NewHandCommand + Handler | 새 핸드 시작 |
| DealCardsCommand + Handler | 카드 딜 처리 |
| PlayerActionCommand + Handler | 베팅 액션 처리 |
| GetGameStateQuery + Handler | 게임 상태 조회 |
| Domain Event 발행 | 카드 인식, 액션, 상태 변경 |

**Phase 1 완료 기준**:
- Hold'em, Omaha 게임 진행이 정확히 동작
- 핸드 평가 결과가 원본과 100% 일치 (1,000+ 테스트 케이스)
- Monte Carlo 승률 계산 200ms 이내
- 단위 테스트 커버리지 90% 이상

### 8.3 Phase 2: Network + Protocol (3주)

**목표**: 서버-클라이언트 통신이 동작하고 Action Tracker가 연결 가능

#### Week 5: gRPC 서버 + 기본 프로토콜

| 작업 | 산출물 |
|------|--------|
| Protobuf 메시지 정의 (핵심 20개) | `.proto` 파일 |
| gRPC 서버 구현 | `Infrastructure/Network/GrpcServer.cs` |
| 인증 (Login/Logout) | JWT 토큰 발급 |
| GameInfoResponse Protobuf 변환 | 75+ 필드 매핑 |
| PlayerInfoResponse Protobuf 변환 | 20 필드 매핑 |

#### Week 6: Action Tracker + Commentary

| 작업 | 산출물 |
|------|--------|
| Action Tracker gRPC 클라이언트 | 딜러 앱 기본 |
| 게임 액션 커맨드 전송 | Fold/Call/Raise/Check |
| Commentary Booth 클라이언트 | 해설자 홀카드 뷰어 |
| 서버 검색 (mDNS + UDP) | 자동 서버 발견 |
| 실시간 상태 동기화 | gRPC Streaming |

#### Week 7: 전체 프로토콜 + 테스트

| 작업 | 산출물 |
|------|--------|
| 113+ 커맨드 중 핵심 50개 구현 | 게임 진행 필수 커맨드 |
| IClientNetworkListener 16개 콜백 | 이벤트 기반 알림 |
| 네트워크 통합 테스트 | 서버-클라이언트 E2E |
| 에러 처리 + 재연결 로직 | 안정성 보장 |
| Master-Slave 기본 동기화 | 상태 전파 기본 |

**Phase 2 완료 기준**:
- Action Tracker에서 게임 진행 가능 (Hold'em + Omaha)
- Commentary Booth에서 홀카드 실시간 확인 가능
- 네트워크 연결/해제/재연결 안정적
- Protobuf 직렬화 성능 < 1ms

### 8.4 Phase 3: Rendering + UI (4주)

**목표**: 방송 품질의 그래픽 출력과 운영자 UI 완성

#### Week 8: DirectX 12 렌더러 기본

| 작업 | 산출물 |
|------|--------|
| Vortice.Windows DX12 초기화 | Device, SwapChain, CommandQueue |
| 2D 렌더링 파이프라인 | 이미지, 텍스트, 도형 렌더링 |
| Dual Canvas 구현 | Live + Delayed 독립 출력 |
| 5-Thread 아키텍처 (Channel<T>) | Producer-Consumer 파이프라인 |

#### Week 9: 그래픽 요소 + 애니메이션

| 작업 | 산출물 |
|------|--------|
| image_element 구현 (41 필드) | 이미지 배치 + 변환 |
| text_element 구현 (52 필드) | 텍스트 렌더링 |
| pip 구현 (12 필드) | 카드 문양 |
| 11개 애니메이션 클래스 | Fade, Slide, Scale 등 |
| AnimationState 16개 상태 처리 | 상태 머신 |

#### Week 10: WPF/Avalonia UI

| 작업 | 산출물 |
|------|--------|
| Main Window + 탭 네비게이션 | 7개 탭 전환 |
| GFX1 탭 (핵심 게임 제어) | 10인 좌석, 카드, 팟 |
| GFX2 탭 (통계) | VPIP, PFR, AF 표시 |
| GFX3 탭 (방송 연출) | 자막, 타이틀, 오버레이 |
| Sources + Outputs 탭 | 입출력 설정 |

#### Week 11: 스킨 시스템 + 편집기

| 작업 | 산출물 |
|------|--------|
| 스킨 파일 로드/저장 (AES-256-GCM) | .vpt 포맷 호환 |
| ConfigurationPreset 99+ 필드 매핑 | 스킨 설정 전체 |
| Skin Editor UI | 스킨 편집기 창 |
| Graphic Editor Board | 보드 요소 편집 |
| Graphic Editor Player | 플레이어 요소 편집 |

**Phase 3 완료 기준**:
- Hold'em 게임이 방송 품질로 렌더링 출력
- 10인 테이블 카드/칩/승률 실시간 표시
- 스킨 로드/저장/편집 동작
- Trustless 모드 (Dual Canvas) 동작
- 60fps 렌더링 유지

### 8.5 Phase 4: Hardware + External (3주)

**목표**: RFID, ATEM, NDI 등 실제 하드웨어 연동 완성

> Part 1.3 전략에 따라, RFID 리더 등 하드웨어는 외주 발주합니다.
> 이 Phase에서는 외주 납품된 하드웨어의 **소프트웨어 드라이버 통합**에 집중합니다.
> 하드웨어 발주는 Phase 2 시작 시점에 병행하여, Phase 4까지 납품 완료되도록 합니다.

#### Week 12: RFID 통합

| 작업 | 산출물 |
|------|--------|
| TCP RFID 드라이버 (SslStream) | WiFi 리더 연결 |
| USB HID RFID 드라이버 | USB 리더 연결 |
| 12대 동시 모니터링 | RfidManager |
| 카드 인식 → 게임 상태 반영 | End-to-End 파이프라인 |
| 인식 실패 시 수동 입력 fallback | 안정성 |

#### Week 13: NDI + ATEM + 출력

| 작업 | 산출물 |
|------|--------|
| NDI 출력 구현 | NewTek NDI SDK |
| HDMI/SDI 출력 | FFmpeg 기반 |
| ATEM 스위처 연동 | BMD Switcher SDK |
| 크로마키 출력 | 그린/블루/매젠타 |
| Cross-GPU 텍스처 공유 | DXGI SharedHandle |

#### Week 14: 추가 게임 + 외부 서비스

| 작업 | 산출물 |
|------|--------|
| 6+ Hold'em, Omaha Hi-Lo 추가 | Phase 2 게임 |
| 7-Card Stud, Razz 추가 | Stud 계열 |
| 5-Card Draw, Triple Draw 추가 | Draw 계열 |
| Twitch EventSub 연동 | 채팅 오버레이 |
| StreamDeck 연동 | 물리 버튼 매핑 |

**Phase 4 완료 기준**:
- RFID 12대 동시 운용, 카드 인식 200ms 이내
- NDI + HDMI 출력 정상
- ATEM 스위처 원격 제어
- 7개 이상 게임 변형 동작

### 8.6 Phase 5: Polish + QA (2주)

**목표**: 프로덕션 수준 안정성 확보와 배포 준비

#### Week 15: 통합 테스트 + 성능

| 작업 | 산출물 |
|------|--------|
| 4시간 무중단 운영 테스트 | 에러 0건 확인 |
| 성능 프로파일링 + 최적화 | CPU/GPU/메모리 |
| 메모리 누수 점검 | 장시간 운영 안정성 |
| 네트워크 장애 복구 테스트 | 재연결, 상태 복원 |
| 전체 22개 게임 테스트 | 모든 변형 정상 동작 |

#### Week 16: 배포 + 문서

| 작업 | 산출물 |
|------|--------|
| MSIX 패키징 | 설치 프로그램 |
| Single-file Publish | 단일 실행 파일 |
| 운영자 매뉴얼 작성 | 사용 가이드 |
| 시스템 관리자 매뉴얼 | 설정/유지보수 가이드 |
| 최종 운영자 검증 | **"PokerGFX와 차이 없음" 서명** |

**Phase 5 완료 기준**:
- 4시간 무중단 운영 성공
- 운영자 2명 서명 획득
- 모든 149개 기능 체크리스트 완료
- 배포 패키지 준비 완료

### 8.7 Phase 6: WSOP+ 연동 (4주+)

**목표**: 자체 PokerGFX를 WSOP+ 플랫폼과 연동하여 대회-방송 통합 운영

> Phase 5 완료 후 착수합니다. PokerGFX 복제가 완전히 검증된 상태에서 확장 개발을 진행합니다.

#### Week 17-18: 연동 API 설계 + 플레이어 DB

| 작업 | 산출물 |
|------|--------|
| WSOP+ API 인터페이스 설계 | REST/gRPC API 스펙 |
| 플레이어 DB 연동 모듈 | 선수 정보 자동 로드 |
| 대회 상태 실시간 수신 | 대회 진행 현황 → 방송 그래픽 |
| 대회 테이블 자동 매핑 | 테이블 번호 ↔ GFX 인스턴스 |

#### Week 19-20: 다중 대회 + 통합 테스트

| 작업 | 산출물 |
|------|--------|
| 다중 대회 동시 운영 | N개 테이블 동시 방송 |
| 대회별 커스텀 통계 | WSOP+ 고유 분석 지표 |
| 대회 브랜딩 스킨 자동 적용 | 대회명 → 스킨 자동 선택 |
| 연동 통합 테스트 | WSOP+ ↔ GFX E2E |

**Phase 6 완료 기준**:
- WSOP+ 대회 데이터가 방송 그래픽에 실시간 반영
- 플레이어 정보 자동 로드 (수동 입력 불필요)
- 다중 테이블 동시 방송 가능
- 대회 브랜딩 스킨 자동 적용

### 8.8 팀 구성

| 역할 | 인원 | 주요 담당 Phase |
|------|:----:|:-------------:|
| 리드 개발자 | 1명 | 전 Phase 아키텍처 |
| 백엔드 개발자 | 2명 | Phase 1-2 (게임엔진, 네트워크) |
| GPU/렌더링 개발자 | 1명 | Phase 3 (DirectX, 애니메이션) |
| UI/프론트엔드 개발자 | 1명 | Phase 3 (WPF/Avalonia) |
| 하드웨어/임베디드 개발자 | 1명 | Phase 4 (RFID, ATEM) |
| QA 엔지니어 | 1명 | Phase 1-5 (테스트 전반) |

---

## Part 9. 기능 우선순위와 검증

이 프로젝트의 검증 기준은 명확합니다: **원본 PokerGFX와 동일한 결과를 내는가**.
모든 기능은 원본 시스템의 동작을 기준으로 검증하며, "차이 없음"이 최종 합격 기준입니다.

### 9.1 우선순위 정의

| 등급 | 정의 | 기준 |
|:----:|------|------|
| **P0** | 필수 | 이것 없이 방송 진행 불가 |
| **P1** | 중요 | 프로덕션 품질에 필요 |
| **P2** | 향후 | 향후 릴리스에서 추가 가능 |

### 9.2 P0 기능 집계 (방송 필수)

| 화면 | P0 기능 수 | 핵심 항목 |
|------|:---------:|----------|
| Main Window | 6 | 게임 선택, 시작/종료, RFID, 탭 네비게이션, 긴급 중지 |
| Sources | 4 | 소스 목록, 미리보기, 해상도, HDMI/SDI |
| Outputs | 5 | Dual Canvas, NDI, HDMI, Trustless, 미리보기 |
| GFX1 | 16 | 좌석, 이름, 칩, 카드, 팟, 승률, 핸드 랭크 |
| GFX2 | 0 | (통계는 P1) |
| GFX3 | 2 | 하단 자막, 방송 제목 |
| Commentary | 4 | 홀카드 뷰, 승률, 핸드 랭크, 보안 분리 |
| System | 10 | 포트, RFID, 네트워크, 암호화, 출력, 스킨 |
| Skin Editor | 10 | 로드/저장, 배경, 폰트, 좌석 위치, Undo |
| GE Board | 12 | 트리뷰, 이동, 속성, 이미지/텍스트/pip, 캔버스 |
| GE Player | 10 | 이름, 칩, 카드, 베팅, 배경, z-order |
| **합계** | **79** | |

### 9.3 시나리오별 기능 분류

| 시나리오 | 기능 수 | 주요 내용 |
|----------|:-------:|----------|
| 게임 추적 | 26 | 카드 인식, 베팅, 팟 계산, 핸드 평가 |
| 방송 출력 | 14 | Dual Canvas, NDI, HDMI, Trustless |
| 방송 준비 | 13 | 게임 선택, 스킨 로드, RFID 연결 |
| 보안 | 11 | Trustless, 암호화, 라이선스, 보안 분리 |
| 통계 분석 | 55 | VPIP, PFR, AF, 그래프, 히스토리 |
| 방송 품질 | 21 | 애니메이션, 하단 자막, 오버레이 |
| 확장 | 9 | ATEM, Twitch, StreamDeck, Master-Slave |

### 9.4 검증 체크리스트

#### 핸드 평가 검증 (P0)

```
□ Hold'em: AA vs KK 올인, AA 승률 ~81% 확인
□ Hold'em: AKs vs QQ, AKs 승률 ~46% 확인
□ Omaha: 반드시 홀카드 2장 사용 규칙 확인
□ Omaha Hi-Lo: 8-or-better Lo 판정 확인
□ 6+ Hold'em: Flush > Full House 규칙 확인
□ Razz: A-5 Lowball 순위 정확성 확인
□ Stud: 7장 중 최강 5장 조합 확인
□ Badugi: 4장 모두 다른 무늬 판정 확인
□ 1,000+ 테스트 케이스 전수 통과
□ 원본 hand_eval.dll 결과와 100% 일치
```

#### RFID 검증 (P0)

```
□ 12대 리더 동시 연결
□ 카드 인식 200ms 이내
□ 인식률 99% 이상 (100회 연속)
□ WiFi 리더 TLS 연결 안정성
□ USB 리더 HID 연결 안정성
□ 인식 실패 시 수동 입력 fallback
□ 리더 연결 해제/재연결 자동 복구
```

#### 렌더링 검증 (P0)

```
□ 10인 테이블 60fps 유지
□ Dual Canvas 독립 출력
□ Trustless 모드 홀카드 분리
□ NDI 출력 정상
□ HDMI 출력 정상
□ 애니메이션 부드러움 (프레임 드랍 없음)
□ 스킨 교체 시 실시간 반영
□ Cross-GPU 텍스처 공유 정상
```

#### 네트워크 검증 (P0)

```
□ Action Tracker 연결/해제/재연결
□ Commentary Booth 실시간 홀카드 전송
□ gRPC Streaming 안정성 (1시간)
□ 서버 검색 (mDNS + UDP) 동작
□ 동시 접속 5개 클라이언트
□ 네트워크 장애 후 자동 복구
```

#### 통합 검증 (최종)

```
□ 4시간 무중단 운영 (에러 0건)
□ Hold'em 풀 게임 10핸드 진행
□ Omaha 풀 게임 5핸드 진행
□ 운영자 2명 "차이 없음" 서명
□ 149개 기능 전수 체크
□ 메모리 누수 없음 (4시간 기준)
□ CPU 사용률 50% 이하 유지
```

#### WSOP+ 연동 검증 (Phase 6)

```
□ WSOP+ API 연결/인증 정상
□ 플레이어 정보 자동 로드 (5초 이내)
□ 대회 상태 실시간 반영 (지연 < 1초)
□ 다중 테이블 동시 방송 (2개 이상)
□ 대회 브랜딩 스킨 자동 적용
□ 대회-방송 통합 4시간 운영 테스트
```

---

## Appendix A. Enum 카탈로그

프로토콜과 도메인 로직에서 사용되는 62개 이상의 Enum 정의입니다. 정확한 정수 값이 네트워크 호환에 중요합니다.

### 핵심 Enum (정수 값 포함)

| Enum | 값 수 | 사용처 | 정의 위치 |
|------|:-----:|--------|----------|
| game | 22 | 게임 유형 | Part 5.1 참조 |
| game_class | 3 | 게임 계열 | Part 5.1 참조 |
| card_type | 53 | 카드 식별 | Part 5.2 참조 |
| hand_class | 10 | 핸드 등급 | Part 5.2 참조 |
| reader_state | 4 | RFID 상태 | Part 6.1 참조 |
| wlan_state | 5 | WiFi 상태 | Part 6.1 참조 |
| AnimationState | 16 | 애니메이션 | Part 6.2 참조 |
| LicenseType | 3 | 라이선스 | Part 6.4 참조 |
| skin_auth_result | 3 | 스킨 인증 | Part 6.5 참조 |
| atem_state | 6 | ATEM 상태 | Part 6.6 참조 |

### 추가 Enum 목록

| Enum | 값 수 | 설명 |
|------|:-----:|------|
| GfxMode | 4 | none=0, gfx1=1, gfx2=2, gfx3=3 |
| betting_round | 5 | preflop=0, flop=1, turn=2, river=3, showdown=4 |
| player_action | 7 | fold=0, check=1, call=2, raise=3, allin=4, bet=5, post=6 |
| player_status | 5 | active=0, folded=1, allin=2, sitting_out=3, eliminated=4 |
| output_type | 4 | ndi=0, hdmi=1, sdi=2, virtual=3 |
| chroma_key | 4 | none=0, green=1, blue=2, magenta=3 |
| text_align | 3 | left=0, center=1, right=2 |
| font_weight | 4 | normal=0, bold=1, light=2, extra_bold=3 |
| log_level | 4 | debug=0, info=1, warn=2, error=3 |
| sync_item | 8 | game_state, players, cards, pot, stats, skin, config, all |
| DongleType | 3 | none=0, keylok=1, custom=2 |
| lang_enum | 130 | 언어 코드 (en=0, ko=1, ...) |

---

## Appendix B. 용어 정의

| 용어 | 설명 |
|------|------|
| **Trustless 모드** | Live Canvas에서 홀카드를 숨기고 Delayed Canvas에만 지연 표시하는 보안 모드 |
| **Dual Canvas** | 동시에 2개의 독립적인 렌더링 출력을 유지하는 구조 |
| **God Class** | 너무 많은 책임을 가진 단일 클래스 (원본 main_form: 329 메서드) |
| **CardMask** | 52장 카드를 64-bit 비트마스크로 표현하는 구조체 |
| **Lookup Table** | 미리 계산된 결과를 저장한 배열, 실행 시 O(1) 조회 |
| **Monte Carlo** | 랜덤 시뮬레이션으로 승률을 근사 계산하는 방법 |
| **SOH** | Start Of Header, 0x01 바이트, TCP 메시지 구분자 |
| **NDI** | Network Device Interface, IP 기반 비디오 전송 프로토콜 |
| **ATEM** | Blackmagic 비디오 스위처 제품군 |
| **VPIP** | Voluntarily Put money In Pot, 자발적 팟 참여율 |
| **PFR** | Pre-Flop Raise, 프리플롭 레이즈 비율 |
| **AF** | Aggression Factor, 공격성 지표 |
| **WTSD** | Went To ShowDown, 쇼다운 진출 비율 |
| **ICM** | Independent Chip Model, 토너먼트 칩 가치 환산 모델 |
| **CQRS** | Command Query Responsibility Segregation, 명령/쿼리 분리 패턴 |
| **MVVM** | Model-View-ViewModel, UI 아키텍처 패턴 |
| **Source Generator** | C# 컴파일 타임 코드 생성 기능 |
| **gRPC** | Google Remote Procedure Call, HTTP/2 기반 RPC 프레임워크 |
| **Protobuf** | Protocol Buffers, 이진 직렬화 포맷 |

---

## Appendix C. 원본 → Clone 마이그레이션 맵

### God Class main_form 분해

| 원본 (main_form 내부) | Clone ViewModel | 메서드 수 |
|-----------------------|----------------|:---------:|
| 게임 제어 로직 | GameSessionViewModel | ~50 |
| UI 이벤트 핸들러 | MainViewModel | ~30 |
| RFID 관리 | RfidViewModel | ~25 |
| 네트워크 관리 | ConnectionViewModel | ~35 |
| 스킨 관리 | SkinViewModel | ~40 |
| 통계 | StatisticsViewModel | ~20 |
| 설정 | SettingsViewModel | ~30 |
| 나머지 | 서비스 계층으로 이동 | ~100 |

### WinForms → WPF/Avalonia View 매핑

| 원본 WinForm (43개) | Clone View (30개 통합) |
|---------------------|----------------------|
| frmMain | MainWindow |
| frmSources | SourcesView |
| frmOutputs | OutputsView |
| frmGfx1 | GameControlView |
| frmGfx2 | StatisticsView |
| frmGfx3 | BroadcastView |
| frmCommentary | CommentaryView |
| frmSystem | SystemSettingsView |
| frmSkinEditor | SkinEditorWindow |
| frmGraphicEditorBoard | BoardEditorView |
| frmGraphicEditorPlayer | PlayerEditorView |
| frmLogin | LoginDialog |
| frmAbout | AboutDialog |
| frmLicense | LicenseDialog |
| frmRfidTest | RfidTestDialog |
| frmColorPicker | ColorPickerControl (통합) |
| frmFontPicker | FontPickerControl (통합) |
| frmCardSelector | CardSelectorControl (통합) |
| 나머지 25개 | 13개 View + 커스텀 컨트롤 |

### 서비스 인터페이스 매핑

| 원본 인터페이스 | Clone 서비스 | 역할 |
|---------------|------------|------|
| IGameManager | IGameService | 게임 상태 관리 |
| IHandEvaluator | IHandEvaluationService | 핸드 평가 |
| INetworkManager | INetworkService | 네트워크 통신 |
| IRfidManager | IRfidService | RFID 리더 관리 |
| IRenderer | IRenderingService | GPU 렌더링 |
| ISkinManager | ISkinService | 스킨 관리 |
| IStatsTracker | IStatisticsService | 통계 추적 |
| IConfigManager | IConfigurationService | 설정 관리 |
| ILicenseManager | ILicenseService | 라이선스 |
| IExternalService | IExternalIntegrationService | 외부 연동 |

---

## Appendix D. 참조 문서

| 문서 | 경로 | 내용 |
|------|------|------|
| 아키텍처 분석 | `analysis/architecture_overview.md` | 원본 시스템 전체 역공학 결과 |
| 기획 PRD | `docs/01-plan/pokergfx-clone-prd.md` | 11개 화면 기획 명세 |
| Wave 1 상세 | `docs/01-plan/clone-prd-wave1.md` | 게임 엔진, 핸드 평가 상세 |
| Wave 2 상세 | `docs/01-plan/clone-prd-wave2.md` | GPU 렌더링, 스킨, RFID 상세 |
| Wave 3 상세 | `docs/01-plan/clone-prd-wave3.md` | 네트워크, 데이터 모델, 서비스 상세 |
| Wave 4 상세 | `docs/01-plan/clone-prd-wave4.md` | 보안, 스레딩, UI, 배포 상세 |
| Annotated 스크린샷 | `docs/01-plan/images/annotated/` | 11개 화면 번호 매핑 이미지 |

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.2.0 | 2026-02-14 | Part 7-9 내러티브 정합성 업데이트: Part 7 도입부 추가, Phase 6 WSOP+ 연동 로드맵 신설, Phase 4 하드웨어 외주 전략 명시, Part 9 검증 철학 추가 + WSOP+ 연동 검증 항목 |
| 1.1.0 | 2026-02-14 | Part 1 전면 재작성: PokerGFX 시스템 설명 추가, 비즈니스 동기 3가지(PokerGO 인수 리스크, WSOP+ 시너지, 최소 리소스 전략) 반영, 개발 전략 섹션 신설 |
| 1.0.1 | 2026-02-14 | Architect 검증 반영: game/AnimationState/skin_auth_result/atem_state enum 원본 값 복원, RFID 명령어 원본 코드 복원 (22개 텍스트 커맨드), 프로토콜 명령어 상세 추가 (113+ 카테고리별 전체 목록), Lookup Table 상세 추가 (TWO_PLUS_TWO 등) |
| 1.0.0 | 2026-02-14 | 초기 작성. 6개 분석 문서 통합 |
