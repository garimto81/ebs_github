# EBS - 라이브 포커 방송 그래픽 시스템

> **⚠️ Archived**: 본 문서는 PRD v2(`docs/01-plan/pokergfx-prd-v2.md`) + Design Doc(`docs/02-design/features/pokergfx.design.md`)으로 대체되었다.
> 4개 고유 콘텐츠는 해당 문서에 이관 완료.

> **Version**: 1.0.0
> **Date**: 2026-02-15
> **Status**: Draft
> **문서 유형**: Product Requirements Document
> **대상 독자**: 개발팀, 기획팀, 하드웨어팀, QA팀

---

## 목차

### Part I: 제품 소개
1. [제품 개요](#1-제품-개요)
2. [대상 사용자](#2-대상-사용자)
3. [핵심 워크플로우](#3-핵심-워크플로우)

### Part II: 시스템 구조
4. [전체 아키텍처](#4-전체-아키텍처)
5. [7개 애플리케이션 생태계](#5-7개-애플리케이션-생태계)
6. [기술 스택](#6-기술-스택)

### Part III: 핵심 기능 상세
7. [22개 포커 게임 엔진](#7-22개-포커-게임-엔진)
8. [핸드 평가 엔진](#8-핸드-평가-엔진)
9. [RFID 카드 인식 시스템](#9-rfid-카드-인식-시스템)
10. [GPU 렌더링 파이프라인](#10-gpu-렌더링-파이프라인)
11. [네트워크 프로토콜](#11-네트워크-프로토콜)

### Part IV: 화면 및 부가 기능
12. [화면별 기능 명세](#12-화면별-기능-명세)
13. [스킨 및 테마 시스템](#13-스킨-및-테마-시스템)
14. [외부 서비스 연동](#14-외부-서비스-연동)
15. [보안 및 라이선스](#15-보안-및-라이선스)

### Part V: 기술 명세
16. [데이터 모델](#16-데이터-모델)
17. [성능 요구사항](#17-성능-요구사항)
18. [Enum 레퍼런스](#18-enum-레퍼런스)

---

# Part I: 제품 소개

## 1. 제품 개요

### 1.1 EBS란

EBS(Event Broadcasting System)는 라이브 포커 방송에서 실시간 그래픽 오버레이를 생성하는 전문 시스템이다. 테이블에 내장된 RFID 리더로 플레이어의 홀카드를 자동 인식하고, GPU 가속 렌더링으로 방송 화면에 그래픽을 합성하며, 네트워크를 통해 다수의 출력 장치 및 클라이언트 앱과 실시간 동기화한다.

방송 화면에 보이는 모든 포커 정보 -- 플레이어의 홀카드, 베팅 액션, 팟 금액, 승률 퍼센트, 커뮤니티 카드, 통계 -- 를 실시간으로 만들어내는 것이 EBS의 역할이다.

시스템이 수행하는 핵심 기능은 다음과 같다.

| 기능 | 설명 |
|------|------|
| RFID 카드 인식 | 테이블에 내장된 RFID 리더 12대가 딜링되는 카드를 자동 인식 |
| 실시간 그래픽 렌더링 | DirectX 기반 GPU 렌더링으로 카드, 칩, 액션 등을 방송 화면에 오버레이 |
| 승률 계산 | Monte Carlo 시뮬레이션으로 각 플레이어의 실시간 승률을 계산하여 표시 |
| 핸드 평가 | 22가지 포커 게임 규칙에 따른 핸드 랭킹 판정 |
| 다중 앱 연동 | 서버 1대 + 클라이언트 6대가 실시간 통신하는 완전한 방송 생태계 |
| 스킨 시스템 | 방송 브랜드에 맞는 그래픽 테마를 자유롭게 편집하고 적용 |

### 1.2 제품 목표

| 목표 | 정량 기준 |
|------|----------|
| 22개 포커 게임 변형 지원 | 3계열(Community Card 13개, Draw 6개, Stud 3개) 전체 |
| RFID 12대 동시 운용 | 좌석 10 + 보드 1 + Muck 1 |
| 카드 인식 200ms 이내 | RFID 태그 감지 ~ 화면 표시 전구간 |
| 4시간 무중단 운영 | 에러 로그 0건 |
| 60fps 렌더링 유지 | 10인 테이블 풀 그래픽 기준 |
| 핸드 평가 완전 정확 | 1,000+ 테스트 케이스 통과 |
| Monte Carlo 승률 200ms 이내 | 10,000회 시뮬레이션 기준 |
| Protobuf 직렬화 1ms 미만 | GameInfoResponse 75+ 필드 기준 |
| 7개 앱 생태계 | 서버 1 + 클라이언트 6 |

### 1.3 시스템 규모

| 항목 | 수치 |
|------|------|
| 지원 포커 게임 | 22개 변형 (3계열) |
| RFID 리더 | 12대 (듀얼 트랜스포트: TCP/WiFi + USB HID) |
| 프로토콜 명령어 | 113+ (9개 카테고리) — *역공학 초기 분류. PRD v2에서 외부 99개 + 내부 ~31개로 재분류* |
| UI 화면 | 11개 (메인 1 + 탭 7 + 편집기 3) |
| 그래픽 요소 | 4가지 타입 (image 41필드, text 52필드, pip 12필드, border 8필드) |
| 애니메이션 | 16개 상태, 11개 애니메이션 클래스 |
| 스킨 설정 | 99+ 필드 (ConfigurationPreset) |
| 외부 연동 | ATEM 스위처, Twitch, StreamDeck, NDI, HDMI/SDI |
| 게임 상태 데이터 | 79+ 필드 (GameTypeData, 6개 Record 분해) |
| 시스템 설정 데이터 | 282개 필드 (config_type, 11개 Record 분해) |

### 1.4 성공 기준

#### 정량 지표

| KPI | 목표 | 측정 방법 |
|-----|------|----------|
| 카드 인식 속도 | 200ms 미만 | RFID 태그 감지 시점 ~ 화면 표시 시점 타이머 |
| 카드 인식률 | 99% 이상 | 100회 연속 태그 테스트 |
| 무중단 운영 | 4시간 이상 | 에러 로그 0건 확인 |
| 렌더링 프레임레이트 | 60fps 유지 | 10인 풀 그래픽 부하 상태 |
| 핸드 평가 속도 | 1ms 미만 | 단일 핸드 평가 소요 시간 |
| UI 응답 시간 | 100ms 미만 | 사용자 클릭 ~ UI 반영 |
| 메모리 사용량 | 2GB 이내 | 4시간 운영 후 측정 |
| 기능 완성도 | 151/151 | Feature Checklist 전수 체크 |

#### 정성적 완료 기준

> 현장 운영자 2명이 "방송 운영에 문제 없음"에 서명

### 1.5 제외 항목

다음 항목은 설계 결정에 의해 이번 제품 범위에서 제외한다.

| 제외 항목 | 설계 결정 근거 |
|----------|---------------|
| 물리 USB 동글 DRM | JWT 기반 라이선스 시스템으로 대체하여 하드웨어 의존 제거 |
| WinForms UI | WPF/Avalonia MVVM으로 설계하여 데이터 바인딩, 현대적 UI 패턴 적용 |
| Newtonsoft.Json | System.Text.Json으로 설계하여 성능 향상 + .NET 8 네이티브 통합 |
| 자체 TLS 구현 | .NET 내장 SslStream으로 설계하여 표준 프로토콜 준수 + 유지보수 비용 제거 |
| 코드 난독화 | 자체 개발 코드이므로 불필요. JWT 라이선스로 기능 게이팅 |
| 바이너리 변조 감지 | 자체 개발 코드이므로 불필요. 서버 인증으로 무결성 보장 |

---

## 2. 대상 사용자

### 2.1 사용자 정의

| 사용자 | 역할 | 주요 화면 | 사용 빈도 |
|--------|------|----------|----------|
| **방송 감독** | 전체 방송 흐름 제어, 카메라 전환 지시 | Main Window, Outputs 탭 | 매 방송 |
| **GFX 운영자** | 그래픽 오버레이 실시간 조작, 카드/통계 표시 제어 | GFX1, GFX2, GFX3, Commentary 탭 | 매 방송 |
| **딜러** | 게임 진행, 카드 딜링, 베팅 액션 입력 | Action Tracker (외부 앱) | 매 핸드 |
| **스킨 디자이너** | 방송 그래픽 테마 제작/수정 | Skin Editor, Graphic Editor | 시즌 변경 시 |
| **시스템 관리자** | 서버 설정, 라이선스 관리, RFID 구성 | System 탭 | 초기 설정 시 |

### 2.2 사용자별 주요 작업

**방송 감독**
- 게임 유형 선택 (Hold'em, Omaha 등 22개 중 택 1)
- 스킨 로드 및 출력 장치 설정 (NDI/HDMI/SDI)
- RFID 리더 연결 상태 확인 (12대 전체)
- Trustless 모드 설정 (Live Canvas 홀카드 숨김)
- 긴급 중지 (모든 그래픽 즉시 숨김)

**GFX 운영자**
- 매 핸드 플레이어 이름/칩 카운트 입력
- 홀카드 표시/숨김 토글 (좌석별)
- 베팅 액션 반영 및 팟 금액 관리
- 승률 바, 핸드 랭크, 통계 표시 제어
- 방송 자막, 로고, 티커 조작

**딜러**
- New Hand 시작 / Hand 종료
- 카드 딜링 (RFID 자동 인식 + 수동 보정)
- 베팅 액션 입력 (Fold / Call / Raise / All-in)
- 커뮤니티 카드 공개 (Flop / Turn / River)
- Showdown 선언

**스킨 디자이너**
- 스킨 파일(.vpt/.skn) 로드/저장
- Board 요소 편집 (팟 위치, 커뮤니티 카드 영역, 로고)
- Player 요소 편집 (이름, 칩, 홀카드, 승률 영역)
- 폰트/색상/애니메이션 설정 (99+ 필드)
- 미리보기 및 내보내기

**시스템 관리자**
- 서버 포트/네트워크 설정
- 라이선스 키 입력 및 갱신
- RFID 리더별 IP/포트/좌석 매핑 (12대)
- Master/Slave 서버 구성
- 로그 레벨 설정, 백업/복원

### 2.3 사용자별 핵심 관심사

| 사용자 | 핵심 관심사 | 불편사항 |
|--------|-----------|---------|
| 방송 감독 | 안정적인 무중단 운영, 빠른 게임 전환 | 서버 크래시로 방송 중단, 설정 변경 시 재시작 필요 |
| GFX 운영자 | 빠른 UI 응답, 직관적인 조작 | 반복적 수동 입력, 실수 시 되돌리기 어려움 |
| 딜러 | 카드 인식 정확성, 터치 인터페이스 반응 | RFID 미인식 시 수동 입력 불편, 네트워크 지연 |
| 스킨 디자이너 | 자유로운 레이아웃 편집, 실시간 미리보기 | 요소 위치 미세 조정 어려움, 스킨 호환성 이슈 |
| 시스템 관리자 | 원클릭 설정, 명확한 상태 모니터링 | RFID 리더 개별 재연결 번거로움, 로그 분석 어려움 |

---

## 3. 핵심 워크플로우

### 3.1 방송 준비 워크플로우

매 방송 시작 전 시스템 관리자, 방송 감독, GFX 운영자가 순차적으로 준비 작업을 수행한다.

```
시스템 관리자              방송 감독                GFX 운영자
    |                        |                        |
    +-- 서버 시작 ---------->|                        |
    |   (라이선스 인증)      |                        |
    |                        +-- 게임 유형 선택 ----->|
    |                        |   (Hold'em/Omaha 등)   |
    |                        +-- 스킨 로드 ---------->|
    |                        |   (.vpt/.skn 파일)     |
    |                        +-- RFID 리더 연결 ----->|
    |                        |   (좌석 10 + 보드 1     |
    |                        |    + Muck 1 = 12대)    |
    |                        +-- 출력 설정 ---------->|
    |                        |   (NDI/HDMI/SDI)       |
    |                        +-- Trustless 모드 ----->|
    |                        |   (Live: 카드 숨김     |
    |                        |    Delayed: N초 지연)  |
    |                        +-- Action Tracker 연결 --+
    |                        |                        |
    |                        +-- 테스트 카드 스캔 --->|
    |                        |   (RFID 동작 확인)     |
    |                        +-- "방송 준비 완료" ---->|
```

주요 검증 항목:
- RFID 리더 12대 전체 `reader_state.ok` 확인
- 네트워크 클라이언트(Action Tracker, Commentary Booth) 연결 상태 확인
- Dual Canvas(Live + Delayed) 출력 정상 확인
- 스킨 로드 완료 및 미리보기 정상 확인

### 3.2 게임 진행 워크플로우

매 핸드마다 반복되는 핵심 루프이다. 딜러가 Action Tracker를 통해 게임을 진행하면, GFX Server가 실시간으로 그래픽을 생성하여 방송 화면에 출력한다.

```
딜러 (Action Tracker)       GFX Server              방송 화면
    |                        |                        |
    +-- New Hand 시작 ------>|                        |
    |                        +-- 테이블 초기화 ------>| (칩 카운트 표시)
    |                        |   핸드 번호 자동 증가  |
    +-- 카드 딜 (RFID) ----->|                        |
    |   (RFID 자동 인식)     +-- 카드 인식 + 표시 --->| (홀카드 오버레이)
    |                        |   200ms 이내 완료      |
    +-- 베팅 액션 입력 ----->|                        |
    |   (Fold/Call/Raise)    +-- 액션 반영 + 팟 계산 >| (팟 금액 업데이트)
    |                        +-- 승률 계산 (Monte) -->| (Win% 바 표시)
    |                        |   200ms 이내 완료      |
    +-- 커뮤니티 카드 ------>|                        |
    |   (Flop/Turn/River)    +-- 보드 카드 표시 ---->| (커뮤니티 카드)
    |                        +-- 승률 재계산 -------->| (Win% 업데이트)
    +-- Showdown ----------->|                        |
    |                        +-- 핸드 랭크 판정 ---->| (승자 하이라이트)
    |                        |   핸드 평가 1ms 미만   |
    +-- Hand 종료 ---------->|                        |
                             +-- 통계 업데이트 ------>| (VPIP, PFR 등)
                             |   다음 핸드 대기       |
```

상태 전이 흐름: `IDLE -> NEW_HAND -> PRE_FLOP -> FLOP -> TURN -> RIVER -> SHOWDOWN -> HAND_COMPLETE -> IDLE`

특수 분기:
- **Run It Twice**: RIVER 이후 추가 보드 딜 -> 별도 팟 분배
- **Draw 게임**: PRE_FLOP 대신 DRAW_ROUND 진입 -> 교환/베팅 반복
- **Stud 게임**: 보드 카드 없음, 각 라운드마다 개인 카드 추가

### 3.3 스킨 편집 워크플로우

비방송 시간에 스킨 디자이너가 방송 그래픽 테마를 제작/수정한다.

```
스킨 디자이너
    |
    +-- Skin Editor 열기
    +-- 기존 스킨 로드 (.vpt/.skn, AES-256-GCM 복호화)
    +-- Graphic Editor 진입
    |   +-- Board 요소 편집
    |   |   (팟 위치, 커뮤니티 카드 영역, 딜러 버튼 10좌석)
    |   +-- Player 요소 편집
    |   |   (이름, 칩, 홀카드 2~6장, 베팅액, 승률 영역)
    |   +-- 폰트/색상 설정 (요소별 개별 지정)
    +-- 애니메이션 설정 (FadeIn, SlideIn, Glint 등 16 상태)
    +-- 미리보기 확인 (실시간 렌더링 프리뷰)
    +-- 스킨 저장 (AES-256-GCM 암호화)
```

스킨 파일 구조:
- Header + Metadata (이름, 버전, 작성자)
- ConfigurationPreset (99+ 필드: 테이블, 좌석, 카드, 폰트, 색상, 애니메이션)
- Board Elements (Graphic Editor Board 요소 배치 정보)
- Player Elements (Graphic Editor Player 요소 배치 정보)
- Embedded Assets (이미지, 폰트 파일)

### 3.4 긴급 상황 복구 워크플로우

방송 중 장애 발생 시의 대응 흐름이다.

```
장애 감지                   복구 조치                     결과
    |                        |                           |
    +-- RFID 미인식 -------->+-- 수동 카드 입력 (G1-015) -> 정상 진행
    |                        |   (마우스 클릭 카드 선택) |
    +-- 네트워크 끊김 ------>+-- 자동 재연결 시도 ------>| 30초 이내 복구
    |                        |   (3초 KeepAlive 기반)    |
    +-- 렌더링 오류 -------->+-- 긴급 중지 (MW-010) ---->| 모든 GFX 숨김
    |                        |   -> 서버 재시작          |
    +-- 잘못된 카드 인식 --->+-- 카드 제거 (G1-016) ---->| 올바른 카드 재입력
    |                        |                           |
    +-- 서버 크래시 -------->+-- 게임 상태 자동 복원 --->| 마지막 저장 상태
                             |   (GAME_SAVE_BACK 명령)   |   로부터 재개
```

---

# Part II: 시스템 구조

## 4. 전체 아키텍처

### 4.1 Clean Architecture 4계층

시스템은 Clean Architecture 원칙에 따라 4개 계층으로 구성한다. 각 계층은 내부 계층만 참조할 수 있으며, 외부 계층으로의 의존은 인터페이스를 통해 역전한다.

```
+---------------------------------------------------------------+
|                      Presentation Layer                        |
|  WPF/Avalonia Views + ViewModels (MVVM)                        |
|  30개 View (메인 1 + 탭 7 + 편집기 3 + 다이얼로그)              |
|  CommunityToolkit.Mvvm 기반 데이터 바인딩                       |
+---------------------------------------------------------------+
|                      Application Layer                         |
|  MediatR CQRS (Command/Query + Handler)                        |
|  Use Cases, DTOs, Validators (FluentValidation)                |
|  파이프라인 Behavior (Validation, Logging, Performance)         |
+---------------------------------------------------------------+
|                        Domain Layer                            |
|  Entities, Value Objects, Domain Events                        |
|  22개 Game Engine, Hand Evaluator, State Machines              |
|  CardMask, GameSession, PlayerState, BettingState              |
+---------------------------------------------------------------+
|                     Infrastructure Layer                       |
|  RFID Drivers (TCP/WiFi + USB HID)                             |
|  GPU Renderer (Vortice.Windows DirectX 12, Dual Canvas)        |
|  Network (gRPC + Protobuf, 113+ 명령)                          |
|  Persistence (EF Core SQLite, 설정 저장)                        |
|  External Services (ATEM, Twitch, NDI, StreamDeck)              |
+---------------------------------------------------------------+
```

프로젝트 구조:

```
src/
+-- PokerGFX.Domain/              # 도메인 모델, 게임 엔진
|   +-- Games/                    # 22개 게임 규칙
|   +-- HandEval/                 # 핸드 평가 엔진 (538개 lookup table)
|   +-- Cards/                    # CardMask, Deck
|   +-- Statistics/               # VPIP, PFR, AF 통계
|   +-- Events/                   # 도메인 이벤트
+-- PokerGFX.Application/         # CQRS, Use Cases
|   +-- Commands/                 # 상태 변경 커맨드
|   +-- Queries/                  # 조회 쿼리
|   +-- Behaviors/                # 파이프라인 (Validation, Logging)
+-- PokerGFX.Infrastructure/      # 외부 연동
|   +-- Rfid/                     # RFID 드라이버 (듀얼 트랜스포트)
|   +-- Rendering/                # DirectX 12 렌더러 (Dual Canvas)
|   +-- Network/                  # gRPC + TCP (113+ 명령)
|   +-- Persistence/              # EF Core SQLite, 설정 저장
+-- PokerGFX.Presentation/        # WPF/Avalonia UI
|   +-- Views/                    # 30개 View
|   +-- ViewModels/               # MVVM ViewModels
|   +-- Controls/                 # 커스텀 컨트롤
+-- PokerGFX.Server/              # GFX 서버 호스트
+-- PokerGFX.ActionTracker/       # 딜러 앱
+-- PokerGFX.Commentary/          # 해설자 앱
+-- PokerGFX.ActionClock/         # 타이머 앱
+-- PokerGFX.StreamDeck/          # StreamDeck 앱
+-- PokerGFX.Pipcap/              # 카드 캡처 앱

tests/
+-- PokerGFX.Domain.Tests/
+-- PokerGFX.Application.Tests/
+-- PokerGFX.Infrastructure.Tests/
+-- PokerGFX.Integration.Tests/
+-- PokerGFX.E2E.Tests/
```

### 4.2 핵심 모듈 구조도

시스템은 8개 핵심 모듈로 구성된다. 각 모듈은 명확한 책임 영역을 가진다.

```
+-------------------------+    +-------------------------+
|      Core 모듈 (4개)     |    |      Infra 모듈 (4개)    |
+-------------------------+    +-------------------------+
|                         |    |                         |
| [GameEngine]            |    | [RfidService]           |
|  22개 게임 규칙          |    |  TCP/WiFi + USB HID     |
|  상태 머신 관리          |    |  12대 리더 동시 운용     |
|  베팅/팟 계산            |    |  TLS 1.3 보안           |
|                         |    |                         |
| [HandEvaluator]         |    | [GpuRenderer]           |
|  538개 lookup table     |    |  DirectX 12 렌더링      |
|  17개 게임별 평가기      |    |  5-Thread 파이프라인    |
|  Monte Carlo 승률 계산   |    |  Dual Canvas           |
|                         |    |  (Live + Delayed)       |
| [StateManager]          |    |                         |
|  GameTypeData 79+ 필드  |    | [NetworkServer]         |
|  6개 Record 분해        |    |  gRPC + Protobuf        |
|  도메인 이벤트 발행      |    |  113+ 프로토콜 명령     |
|                         |    |  TLS 1.3 암호화         |
| [ConfigManager]         |    |                         |
|  config_type 282 필드   |    | [SkinManager]           |
|  11개 Record 분해       |    |  .vpt/.skn 파일 관리    |
|  AES-256-GCM 암호화     |    |  AES-256-GCM 암호화     |
|                         |    |  99+ 필드 프리셋        |
+-------------------------+    +-------------------------+
```

| 모듈 | 프로젝트 위치 | 핵심 역할 |
|------|-------------|----------|
| **GameEngine** | Domain/Games | 22개 게임 상태 머신, 베팅/블라인드/앤티 계산, 팟 분배 |
| **HandEvaluator** | Domain/HandEval | 538개 lookup 배열, 17개 게임별 평가기, Monte Carlo |
| **StateManager** | Domain + Application | GameTypeData 79+ 필드를 6개 Record로 관리, 이벤트 발행 |
| **ConfigManager** | Application + Infrastructure | config_type 282 필드를 11개 Record로 관리, 암호화 저장 |
| **RfidService** | Infrastructure/Rfid | TCP/WiFi + USB HID 듀얼 트랜스포트, 22개 텍스트 커맨드 |
| **GpuRenderer** | Infrastructure/Rendering | DirectX 12, 5-Thread 파이프라인, Dual Canvas |
| **NetworkServer** | Infrastructure/Network | gRPC + Protobuf, 113+ 명령, Master-Slave 동기화 |
| **SkinManager** | Infrastructure/Persistence | 스킨 파일 I/O, ConfigurationPreset 99+ 필드 직렬화 |

### 4.3 모듈 간 의존성 다이어그램

```
RFID 리더 하드웨어 (12대)
       |
       | (TCP/WiFi + USB HID)
       v
  RfidService ---------> Domain Event: CardDetected
                                |
                                v
Action Tracker ----(gRPC)----> Command Handler ------> GameEngine
                                |                        |
                                |                   StateManager
                                |                        |
                                +-----> HandEvaluator    |
                                |       (승률 계산)       |
                                v                        v
                          State Change             Domain Events
                                |
                  +-------------+-------------+
                  |             |             |
                  v             v             v
           GpuRenderer    NetworkServer    Statistics
           (Dual Canvas)  (gRPC 브로드)    (VPIP, PFR)
                  |             |
                  v             v
           NDI/HDMI/SDI   Commentary Booth
           방송 출력       Action Clock
                          StreamDeck
                          Pipcap

  ConfigManager
       |
       +---> AES-256-GCM 암호화/복호화
       +---> 11개 설정 Record 관리
       +---> 서버/RFID/렌더/네트워크 설정

  SkinManager
       |
       +---> .vpt/.skn 파일 로드/저장
       +---> ConfigurationPreset 99+ 필드
       +---> Board/Player 그래픽 요소
```

---

## 5. 7개 애플리케이션 생태계

서버 1개와 클라이언트 6개로 구성되는 완전한 방송 생태계이다. 모든 클라이언트는 서버를 통해 게임 상태를 동기화한다.

```
                    +---------------------------+
                    |        GfxServer           |
                    |   메인 서버 (pgfx_server)   |
                    |   모든 상태의 단일 원본     |
                    +-----------+---------------+
                                |
          +---------------------+---------------------+
          |          |          |          |           |
   +------+--+ +----+----+ +---+---+ +----+----+ +---+----+
   | Action  | | Hand    | | Action| | Stream  | | Comment|
   | Tracker | | Eval    | | Clock | | Deck    | | Booth  |
   +----+----+ +---------+ +-------+ +---------+ +--------+
        |
   +----+----+
   | Pipcap  |
   +---------+
```

| 앱 | 내부명 | 역할 | 통신 방식 | 핵심 기능 |
|----|--------|------|----------|----------|
| **GfxServer** | `pgfx_server` | 메인 서버, 모든 상태 관리의 단일 원본 | - | 게임 엔진, RFID, GPU 렌더링, 스킨, 모든 클라이언트 관리 |
| **ActionTracker** | `pgfx_action_tracker` | 딜러용 터치스크린 게임 액션 입력 | gRPC | New Hand, 베팅 액션, 카드 딜, Showdown 입력 |
| **HandEvaluation** | `hand_eval_wcf` | 독립 핸드 평가 서비스 | gRPC | 서버와 분리된 핸드 평가 연산 (부하 분산용) |
| **ActionClock** | `pgfx_action_clock` | 플레이어 타이머 표시용 외부 디스플레이 | gRPC | Shot Clock, Time Bank 카운트다운 표시 |
| **StreamDeck** | `pgfx_streamdeck` | Elgato StreamDeck 물리 버튼 연동 | gRPC | 게임 시작/종료, 카드 토글, 긴급 중지 물리 버튼 매핑 |
| **Pipcap** | `pgfx_pipcap` | 카드 이미지 캡처 유틸리티 | 파일 | 원격 서버 PIP 영역 캡처, 카드 이미지 자동 수집 |
| **CommentaryBooth** | `pgfx_commentary_booth` | 해설자용 홀카드 뷰어 | gRPC | 모든 플레이어 홀카드 + 승률 + 핸드 랭크 실시간 표시 |

**통신 프로토콜**: 모든 클라이언트-서버 간 통신은 gRPC(HTTP/2) + Protobuf를 사용한다. 서버 검색은 mDNS/DNS-SD를 기본으로 하고, UDP Broadcast(포트 9000/9001/9002)를 하위 호환용으로 병행 지원한다.

**Master-Slave 구성**: 다중 테이블 방송 시 Master 서버가 게임 상태를 보유하고, Slave 서버들이 동기화하여 다른 카메라 앵글, 해설자 전용 피드, 온라인 스트리밍 피드를 독립 출력한다.

```
Master Server
    |
    +-- 게임 상태 원본 보유
    +-- RFID 리더 직접 제어
    |
    +--sync--> Slave Server 1 (다른 카메라 앵글)
    +--sync--> Slave Server 2 (해설자 전용 피드)
    +--sync--> Slave Server 3 (온라인 스트리밍 피드)
```

동기화 항목: 게임 상태 전체, 플레이어 정보, 통계 데이터, 스킨 설정(선택적)

---

## 6. 기술 스택

### 6.1 런타임 및 언어

| 항목 | 선택 | 근거 |
|------|------|------|
| 런타임 | .NET 8+ (LTS) | 장기 지원, 성능, AOT 컴파일 지원 |
| 언어 | C# 12 | record struct, required members, pattern matching |
| 대상 OS | Windows 10/11 (x64) | DirectX 12 필수 |

### 6.2 UI 프레임워크

| 항목 | 선택 | 근거 |
|------|------|------|
| UI 프레임워크 | WPF 또는 Avalonia | MVVM 데이터 바인딩, 풍부한 컨트롤 |
| MVVM 도구 | CommunityToolkit.Mvvm | ObservableProperty, RelayCommand 소스 생성 |
| View 수 | 30개 | 메인 1 + 탭 7 + 편집기 3 + 다이얼로그 |

### 6.3 GPU 렌더링

| 항목 | 선택 | 근거 |
|------|------|------|
| DirectX 바인딩 | Vortice.Windows | DirectX 12 최신 API, 오픈소스 |
| 2D 그래픽 | Direct2D (Vortice) | 텍스트/이미지/도형 렌더링 |
| 텍스트 렌더링 | DirectWrite (Vortice) | 고품질 글리프 렌더링, 커스텀 폰트 |
| GPU 코덱 | NVENC / AMF / QSV / x264 | 하드웨어 인코딩 우선, 소프트웨어 폴백 |
| 비디오 캡처 | FFmpeg.AutoGen | 오픈소스, HDMI/SDI/NDI 캡처 |
| 렌더링 구조 | 5-Thread Producer-Consumer | 입력/합성/Live/Delayed/출력 파이프라인 |
| 캔버스 | Dual Canvas (Live + Delayed) | Trustless 모드 지원 |

### 6.4 네트워크

| 항목 | 선택 | 근거 |
|------|------|------|
| RPC 프레임워크 | gRPC (HTTP/2) | 타입 안전, 코드 생성, 멀티플렉싱 |
| 직렬화 | Protobuf + System.Text.Json 폴백 | 바이너리 효율, JSON 호환성 |
| 서버 검색 | mDNS/DNS-SD + UDP Broadcast | 표준 프로토콜 + 하위 호환 |
| 명령 수 | 113+ (9개 카테고리) | Connection, Game, Player, Cards, Display, Media, Betting, Data, History |
| 커맨드 라우팅 | Source Generator 기반 자동 등록 | 컴파일 타임 검증, Reflection 제거 |

### 6.5 직렬화

| 항목 | 선택 | 근거 |
|------|------|------|
| 네트워크 메시지 | Protobuf | 바이너리, 고성능, 타입 안전 |
| 설정/스킨 파일 | System.Text.Json | .NET 8 내장, Source Generator 지원 |
| 게임 상태 동기화 | Protobuf (GameInfoResponse 75+ 필드) | 1ms 미만 직렬화 목표 |

### 6.6 DI 및 미들웨어

| 항목 | 선택 | 근거 |
|------|------|------|
| DI 컨테이너 | Microsoft.Extensions.DependencyInjection | .NET 표준, 테스트 용이 |
| CQRS | MediatR | Command/Query 분리, 파이프라인 Behavior |
| 검증 | FluentValidation | 선언적 검증 규칙, MediatR 파이프라인 통합 |
| 로깅 | Serilog (8개 LogTopic) | 구조화 로깅, 토픽별 필터링, 다중 싱크 |

8개 로그 토픽:

| LogTopic | 대상 |
|----------|------|
| General | 서버 핵심 운영, UI 상호작용 |
| Startup | 초기화, 하드웨어 체크, 타이머, 성능 측정 |
| MultiGFX | Primary/Secondary 동기화, 라이선스 검증 |
| AutoCamera | 자동 카메라 전환, 순환, 보드 팔로우 |
| Devices | Stream Deck, Action Tracker, 해설 부스 연결 |
| RFID | 리더 모듈, 태그 감지, 중복 모니터링, 캘리브레이션 |
| Updater | 업데이트 부트스트랩, 설치 관리 |
| GameState | 게임 저장/복원, 평가 폴백, 테이블 상태 전환 |

### 6.7 미디어

| 항목 | 선택 | 근거 |
|------|------|------|
| 이미지 처리 | SkiaSharp | 2D 이미지 로드/변환, 크로스플랫폼 |
| 비디오 캡처/인코딩 | FFmpeg.AutoGen 또는 MediaFoundation | HDMI/SDI/NDI 소스 캡처, 녹화 |
| NDI | NewTek NDI SDK | 네트워크 기반 비디오 입출력 |
| ATEM 스위처 | BMD Switcher SDK | Blackmagic ATEM 원격 제어 |

### 6.8 빌드 및 배포

| 항목 | 선택 | 근거 |
|------|------|------|
| 빌드 | `dotnet publish` | AOT 컴파일 지원, 자체 포함 배포 |
| 배포 | MSIX 패키지 | Windows 표준 설치, 자동 업데이트 |
| CI/CD | GitHub Actions | 자동 빌드, 테스트, 배포 |
| 테스트 | xUnit + FluentAssertions + NSubstitute | 단위/통합/E2E 테스트 |
| 벤치마크 | BenchmarkDotNet | 핸드 평가, Monte Carlo, 렌더링 성능 측정 |
| IDE | Visual Studio 2022 / JetBrains Rider | .NET 개발 환경 |
| 비동기 큐 | Channel\<T\> | 고성능 비동기 Producer-Consumer |
| IO | System.IO.Pipelines | 고성능 네트워크 IO |

---

# Part III: 핵심 기능 상세 (전반)

## 7. 22개 포커 게임 엔진

### 7.1 게임 분류 체계

22개 포커 게임 변형은 3개 계열로 분류된다. 계열에 따라 카드 딜링 방식, 보드 카드 유무, 핸드 평가 방법이 달라진다.

```csharp
enum game_class {
    flop = 0,    // Community Card 계열 - 공유 보드 카드 사용 (13개)
    draw = 1,    // Draw 계열 - 카드 교환 라운드 존재 (6개)
    stud = 2     // Stud 계열 - 개인 카드만 사용, 일부 공개 (3개)
}
```

| 계열 | 게임 수 | 특징 | 대표 게임 |
|------|:-------:|------|----------|
| Community Card (flop) | 13 | 커뮤니티 보드 카드 5장 공유, 홀카드 2~6장 | Hold'em, Omaha |
| Draw (draw) | 6 | 카드 교환 1~3회, 보드 카드 없음, 4~5장 핸드 | Badugi, 2-7 Triple Draw |
| Stud (stud) | 3 | 개인 카드 7장, 일부 오픈, 5개 베팅 라운드 | 7-Card Stud, Razz |

### 7.2 전체 22개 게임 카탈로그

```csharp
enum game {
    holdem = 0,                                  // Texas Hold'em
    holdem_sixplus_straight_beats_trips = 1,     // 6+ Hold'em (Straight > Trips)
    holdem_sixplus_trips_beats_straight = 2,     // 6+ Hold'em (Trips > Straight)
    pineapple = 3,                               // Pineapple
    omaha = 4,                                   // Omaha
    omaha_hilo = 5,                              // Omaha Hi-Lo
    omaha5 = 6,                                  // Five Card Omaha
    omaha5_hilo = 7,                             // Five Card Omaha Hi-Lo
    omaha6 = 8,                                  // Six Card Omaha
    omaha6_hilo = 9,                             // Six Card Omaha Hi-Lo
    courchevel = 10,                             // Courchevel
    courchevel_hilo = 11,                        // Courchevel Hi-Lo
    draw5 = 12,                                  // Five Card Draw
    deuce7_draw = 13,                            // 2-7 Single Draw
    deuce7_triple = 14,                          // 2-7 Triple Draw
    a5_triple = 15,                              // A-5 Triple Draw
    badugi = 16,                                 // Badugi
    badeucy = 17,                                // Badeucy
    badacey = 18,                                // Badacey
    stud7 = 19,                                  // 7-Card Stud
    stud7_hilo8 = 20,                            // 7-Card Stud Hi-Lo
    razz = 21                                    // Razz
}
```

#### Community Card 계열 (13개)

| game enum | 게임명 | 홀카드 | 보드 카드 | 특수 규칙 |
|:---------:|--------|:------:|:---------:|----------|
| 0 | Texas Hold'em | 2장 | 5장 | 표준 포커 |
| 1 | 6+ Hold'em (Straight > Trips) | 2장 | 5장 | 36장 덱(2-5 제거), Straight가 Trips보다 강함 |
| 2 | 6+ Hold'em (Trips > Straight) | 2장 | 5장 | 36장 덱(2-5 제거), Trips가 Straight보다 강함 |
| 3 | Pineapple | 3장 -> 2장 | 5장 | Flop 전 1장 버림 |
| 4 | Omaha | 4장 | 5장 | 반드시 홀카드 2장 + 보드 3장 사용 |
| 5 | Omaha Hi-Lo | 4장 | 5장 | Hi/Lo 분할 (8-or-better) |
| 6 | Five Card Omaha | 5장 | 5장 | 반드시 홀카드 2장 + 보드 3장 사용 |
| 7 | Five Card Omaha Hi-Lo | 5장 | 5장 | Hi/Lo 분할 |
| 8 | Six Card Omaha | 6장 | 5장 | 반드시 홀카드 2장 + 보드 3장 사용 |
| 9 | Six Card Omaha Hi-Lo | 6장 | 5장 | Hi/Lo 분할 |
| 10 | Courchevel | 5장 | 5장 | 첫 Flop 카드 1장을 Pre-Flop에 미리 공개 |
| 11 | Courchevel Hi-Lo | 5장 | 5장 | Hi/Lo 분할 + 첫 카드 미리 공개 |

**Short Deck(6+) 특수 처리**: 2, 3, 4, 5 카드를 제거한 36장 덱을 사용한다. Dead cards 상수는 `8247343964175`(16장 bitmask)이다. Wheel(가장 낮은 Straight)은 A-6-7-8-9(bitmask 4336)으로 대체된다. 2개 별도 변형이 존재하는 이유는 카지노마다 Straight와 Trips의 상대적 강도 규칙이 다르기 때문이다.

**Pineapple**: 홀카드 3장을 받은 후 Flop 공개 전에 1장을 버려 2장으로 만든다. 이후 Hold'em과 동일하게 진행하고 동일한 평가기를 사용한다.

**Omaha 변형**: 반드시 홀카드에서 정확히 2장, 보드에서 정확히 3장을 사용해야 한다. Omaha Hi-Lo는 Hi 핸드와 Lo 핸드(8-or-better)를 동시에 평가하여 팟을 분할한다.

**Courchevel**: 5장 Omaha와 동일하나, Pre-Flop 단계에서 Flop의 첫 번째 카드가 미리 공개된다.

#### Draw 계열 (6개)

| game enum | 게임명 | 카드 | 교환 횟수 | 특수 규칙 |
|:---------:|--------|:----:|:---------:|----------|
| 12 | Five Card Draw | 5장 | 1회 | 기본 Draw 게임 |
| 13 | 2-7 Single Draw | 5장 | 1회 | Lowball (Ace는 High, Straight/Flush 불리) |
| 14 | 2-7 Triple Draw | 5장 | 3회 | Lowball, 3회 교환 기회 |
| 15 | A-5 Triple Draw | 5장 | 3회 | A-5 Lowball (Ace는 Low) |
| 16 | Badugi | 4장 | 3회 | 4장 Lowball, 4개 suit 모두 다른 조합이 유리 |
| 17 | Badeucy | 5장 | 3회 | Badugi + 2-7 혼합 (2개 핸드 동시 평가) |
| 18 | Badacey | 5장 | 3회 | Badugi + A-5 혼합 (2개 핸드 동시 평가) |

Draw 계열은 보드 카드가 없으며, 플레이어가 원하는 카드를 교환할 수 있다. 교환 횟수는 게임 규칙에 따라 1회 또는 3회이다.

#### Stud 계열 (3개)

| game enum | 게임명 | 카드 | 베팅 라운드 | 특수 규칙 |
|:---------:|--------|:----:|:----------:|----------|
| 19 | 7-Card Stud | 7장 | 5 | 3장 비공개 + 4장 공개, SevenCards 평가기 |
| 20 | 7-Card Stud Hi-Lo | 7장 | 5 | Hi/Lo 분할 (8-or-better) |
| 21 | Razz | 7장 | 5 | A-5 Lowball Stud, King이 최고 (불리) |

Stud 계열은 커뮤니티 보드 카드가 없다. 각 라운드마다 개인 카드가 추가되며, 일부는 다른 플레이어에게 공개된다. Razz는 랭크 리맵(`shl 1` + `shr 12`)으로 King을 최고값으로 변환하여 Lowball 평가한다.

### 7.3 게임 상태 머신

모든 게임은 다음 상태 머신을 따라 진행된다. 게임 계열에 따라 일부 상태에서 분기가 발생한다.

```
IDLE (대기)
  |
  v
SETUP_HAND  <--- hand_num 증가, 플레이어 좌석 확인, 블라인드/앤티 수납
  |
  v
PRE_FLOP  <--- 홀카드 딜, 첫 베팅 라운드
  |               |
  |               +--- [Draw 계열] ---> DRAW_ROUND
  |               |                      교환 + 베팅 반복
  |               |                      draws_completed가 최대에 도달할 때까지
  |               |
  |               +--- [Stud 계열] ---> THIRD_STREET
  |                                      -> FOURTH_STREET
  |                                      -> FIFTH_STREET
  |                                      -> SIXTH_STREET
  |                                      -> SEVENTH_STREET
  |                                      각 스트릿마다 개인 카드 추가 + 베팅
  v
FLOP  <--- 커뮤니티 카드 3장 공개 + 베팅 라운드
  |
  v
TURN  <--- 4번째 카드 공개 + 베팅 라운드
  |
  v
RIVER  <--- 5번째 카드 공개 + 최종 베팅 라운드
  |
  +---[run_it_times > 1]---> RUN_IT_TWICE
  |                              |
  |                              v
  |                         추가 보드 딜 + 별도 팟 분배
  |                         run_it_times_remaining이 0이 될 때까지 반복
  |                              |
  v                              v
SHOWDOWN  <--- 핸드 평가 엔진으로 승자 결정, 팟 분배
  |
  v
HAND_COMPLETE  <--- 통계 업데이트 (VPIP, PFR, AF 등), 다음 핸드 대기
  |
  v
IDLE (loop)
```

각 상태에서 허용되는 액션:

| 상태 | 허용 액션 |
|------|----------|
| IDLE | New Hand 시작 |
| SETUP_HAND | 플레이어 추가/제거, 좌석 변경, 블라인드 레벨 변경 |
| PRE_FLOP ~ RIVER | Fold, Call, Raise, All-in, Check |
| DRAW_ROUND | 카드 교환 (0~5장 선택), Fold, Call, Raise |
| SHOWDOWN | 카드 공개, Muck |
| HAND_COMPLETE | 칩 분배 확인, 다음 핸드 진행, Chop |

### 7.4 베팅 구조

```csharp
enum BetStructure {
    NoLimit = 0,      // 무제한 - 최소 BB 이상 어떤 금액이든 레이즈 가능
    FixedLimit = 1,   // 고정 - 정해진 단위로만 베팅/레이즈
    PotLimit = 2      // 팟 리밋 - 현재 팟 크기 이하로만 레이즈
}
```

모든 22개 게임 변형은 3가지 베팅 구조와 조합 가능하다. `GameTypeData.bet_structure` 필드에 저장된다.

| 베팅 구조 | 최소 베팅 | 최대 베팅 | 주 사용 게임 |
|----------|----------|----------|-------------|
| No Limit | Big Blind | 전 칩 (All-in) | Hold'em, Omaha |
| Fixed Limit | Small/Big Bet | 고정 단위 (cap 적용) | Stud, Draw |
| Pot Limit | Big Blind | 현재 팟 크기 | Omaha, Courchevel |

관련 필드: `min_raise_amt`(최소 레이즈 금액), `cap`(베팅 캡), `num_raises_this_street`(현재 스트릿 레이즈 횟수)

### 7.5 Ante 유형

7가지 Ante 유형을 지원하며, `GameTypeData._ante_type` 필드에 저장된다.

```csharp
enum AnteType {
    std_ante = 0,        // 표준 앤티 - 모든 플레이어가 동일 금액 납부
    button_ante = 1,     // 버튼 앤티 - 딜러(버튼)만 납부
    bb_ante = 2,         // 빅블라인드 앤티 - BB 위치 플레이어가 납부
    bb_ante_bb1st = 3,   // BB 앤티 (BB 먼저) - BB가 앤티를 먼저 수납
    live_ante = 4,       // 라이브 앤티 - 팟에 라이브로 참여
    tb_ante = 5,         // Third Blind 앤티 - 서드 블라인드 위치 납부
    tb_ante_tb1st = 6    // TB 앤티 (TB 먼저) - TB가 앤티를 먼저 수납
}
```

| 유형 | 납부자 | 납부 순서 | 사용 상황 |
|------|--------|----------|----------|
| `std_ante` | 모든 활성 플레이어 | 블라인드 수납 전 | 전통적 방식 |
| `button_ante` | 딜러(버튼) 위치만 | 블라인드 수납 전 | 현대 토너먼트 표준 |
| `bb_ante` | Big Blind 위치만 | 블라인드 수납 후 | WSOP 공식 규칙 |
| `bb_ante_bb1st` | Big Blind 위치만 | 블라인드 수납 전 | BB가 앤티 먼저 |
| `live_ante` | 모든 활성 플레이어 | 팟에 라이브 포함 | Stud 계열 기본 |
| `tb_ante` | Third Blind 위치 | 블라인드 수납 전 | 특수 토너먼트 |
| `tb_ante_tb1st` | Third Blind 위치 | TB 앤티 먼저 | TB 앤티 선수납 |

### 7.6 특수 규칙

#### Short Deck (6+ Hold'em)

- 36장 덱 사용 (2, 3, 4, 5 카드 16장 제거)
- Dead cards bitmask: `8247343964175`
- Wheel: A-6-7-8-9 (bitmask 4336)
- 2개 변형 존재: Straight > Trips vs Trips > Straight
- 핸드 랭킹 사후 교환: `6THOLDEM` 변형에서는 Trips와 Straight 값, Flush와 Full House 값을 사후 교환

#### Bomb Pot

- 모든 플레이어가 사전 합의된 금액(`bomb_pot` 필드)을 팟에 납부
- Pre-Flop 베팅 없이 바로 Flop 공개
- Flop 이후 정상 베팅 진행
- `GameTypeData.bomb_pot` 필드로 금액 설정

#### Run It Twice

- All-in 발생 후, RIVER 이전이면 남은 보드를 2번(또는 그 이상) 전개
- 각 보드에 대해 독립적으로 팟 분배
- `run_it_times` 필드: 실행 횟수 (기본 1)
- `run_it_times_remaining` 필드: 남은 보드 수
- `run_it_times_num_board_cards` 필드: 각 보드의 카드 수

#### 7-2 Side Bet

- 7-2 오프슈트(최약 핸드)로 팟을 이기면 각 플레이어에게서 사이드벳 수취
- `seven_deuce_amt` 필드: 사이드벳 금액

#### Straddle

- 자발적 블라인드 추가 (일반적으로 2 x BB)
- `_third` 필드: Straddle 금액
- `pl_third`: Straddle 위치 플레이어

---

## 8. 핸드 평가 엔진

### 8.1 설계 목표

| 목표 | 기준 |
|------|------|
| 정확성 | 100% - 모든 게임 변형에서 정확한 핸드 랭킹 보장 |
| 단일 평가 속도 | 1μs/핸드 이내 - Lookup Table O(1) 평가 |
| Monte Carlo 속도 | 200ms 이내 - 10,000회 시뮬레이션 |
| 메모리 사용 | ~2.1MB - 538개 정적 배열 |
| 게임 지원 | 17개 평가기 - 22개 게임 변형 전체 커버 |
| 스레드 안전 | 전체 - 순수 함수 + 읽기 전용 테이블 |

### 8.2 카드 표현: 64-bit Bitmask (CardMask)

모든 카드는 64비트 `ulong`의 단일 비트로 표현된다. 52장이 4개 suit 영역에 각 13비트씩 배치된다.

```
비트 레이아웃 (64비트 중 52비트 사용):

[--- Spades ---][--- Hearts ---][--- Diamonds ---][--- Clubs ---]
 bits 39-51       bits 26-38       bits 13-25        bits 0-12

각 suit 내 (13비트):
bit 0  = 2 (Deuce, 최저)
bit 1  = 3 (Trey)
bit 2  = 4 (Four)
bit 3  = 5 (Five)
bit 4  = 6 (Six)
bit 5  = 7 (Seven)
bit 6  = 8 (Eight)
bit 7  = 9 (Nine)
bit 8  = 10 (Ten)
bit 9  = J (Jack)
bit 10 = Q (Queen)
bit 11 = K (King)
bit 12 = A (Ace, 최고)
```

Suit offset 상수:

```csharp
CLUB_OFFSET    = 13 * 0 = 0     // bits 0-12
DIAMOND_OFFSET = 13 * 1 = 13    // bits 13-25
HEART_OFFSET   = 13 * 2 = 26    // bits 26-38
SPADE_OFFSET   = 13 * 3 = 39    // bits 39-51
```

카드 마스크 생성 공식: `mask |= (1UL << (rank + suit * 13))`

CardMask 구현:

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

정적 테이블:
- `CardMasksTable[52]`: `ulong[]` - 각 카드의 단일 비트 마스크
- `CardTable[52]`: `string[]` - `["2c","3c",...,"Ac","2d",...,"As"]` 순서

### 8.3 핸드 등급 체계

```csharp
enum hand_class {
    high_card = 0,        // 하이카드 - 아무 조합 없음
    one_pair = 1,         // 원페어 - 같은 랭크 2장
    two_pair = 2,         // 투페어 - 같은 랭크 2장이 2조
    three_of_a_kind = 3,  // 쓰리카드 - 같은 랭크 3장
    straight = 4,         // 스트레이트 - 연속 5장
    flush = 5,            // 플러시 - 같은 suit 5장
    full_house = 6,       // 풀하우스 - 쓰리카드 + 원페어
    four_of_a_kind = 7,   // 포카드 - 같은 랭크 4장
    straight_flush = 8,   // 스트레이트 플러시 - 같은 suit 연속 5장
    royal_flush = 9       // 로열 플러시 - 10-J-Q-K-A 같은 suit (straight_flush 특수 케이스)
}
```

숫자가 클수록 강한 핸드이다. `royal_flush`는 `straight_flush`의 특수 케이스로, 최고 랭크(A)로 시작하는 straight flush를 별도 분류한다.

### 8.4 핸드 값 인코딩 (HandValue 32-bit)

핸드 값은 단일 `uint`에 packed되어, 숫자 비교만으로 즉시 승패를 판정할 수 있다.

```
HandValue (32-bit uint) 구조:

  [31-28]      [27-24]         [23-16]        [15-12]      [11-8]       [7-0]
  (unused)   HandType(0-8)   Top Card Rank   2nd Card    3rd Card    Kicker Bits

HANDTYPE_SHIFT     = 24
TOP_CARD_SHIFT     = 16
SECOND_CARD_SHIFT  = 12
THIRD_CARD_SHIFT   = 8
CARD_WIDTH         = 4
```

| HandType 값 | 이름 | HANDTYPE_VALUE (계산식) |
|:-----------:|------|:----------------------:|
| 0 | HighCard | `0 << 24 = 0` |
| 1 | Pair | `1 << 24 = 16,777,216` |
| 2 | TwoPair | `2 << 24 = 33,554,432` |
| 3 | Trips | `3 << 24 = 50,331,648` |
| 4 | Straight | `4 << 24 = 67,108,864` |
| 5 | Flush | `5 << 24 = 83,886,080` |
| 6 | FullHouse | `6 << 24 = 100,663,296` |
| 7 | FourOfAKind | `7 << 24 = 117,440,512` |
| 8 | StraightFlush | `8 << 24 = 134,217,728` |

비교 원칙:
- 상위 HandType이 항상 우선한다 (Flush > Straight, 항상)
- 동일 HandType 내에서는 하위 비트(kicker)로 타이를 해결한다
- `handValueA > handValueB` 한 번의 비교로 승패 판정 완료

### 8.5 Lookup Table 아키텍처

모든 핵심 lookup table은 8192 엔트리 배열(2^13)이다. 13비트 랭크 패턴의 모든 가능한 조합을 사전 계산하여 O(1) 조회를 보장한다.

| 테이블 | 타입 | 크기 | 설명 |
|--------|------|:----:|------|
| `nBitsTable[8192]` | `ushort[]` | 8,192 | 13비트 값의 popcount (셋 비트 수) |
| `straightTable[8192]` | `ushort[]` | 8,192 | Straight 포함 시 최고 카드 랭크, 없으면 0 |
| `topFiveCardsTable[8192]` | `uint[]` | 8,192 | 상위 5개 비트의 packed 표현 |
| `topCardTable[8192]` | `ushort[]` | 8,192 | 최상위 셋 비트의 랭크 |
| `nBitsAndStrTable[8192]` | `ushort[]` | 8,192 | bitcount + straight 결합 정보 |
| `bits[256]` | `byte[]` | 256 | 바이트 단위 popcount |
| `CardMasksTable[52]` | `ulong[]` | 52 | 단일 카드 bitmask |
| `CardTable[52]` | `string[]` | 52 | 카드 이름 문자열 |

총 538개 정적 배열, 약 2.1MB 메모리 사용. C# Source Generator로 빌드 타임에 `ReadOnlySpan<byte>`로 생성하여 GC 부담을 제거한다.

성능 최적화 옵션: `topFiveCards.bin`, `topCard.bin` memory-mapped 파일에서 로드 가능. 파일 없거나 인덱스 범위 초과 시 인메모리 배열로 자동 fallback. Double-checked locking으로 thread-safe lazy 초기화를 수행한다.

핵심 평가 알고리즘 (Evaluate):

```csharp
static uint Evaluate(ulong cards, int numberOfCards, bool ignore_wheel)
{
    // Step 1: 각 suit의 13비트 마스크 추출
    int clubs    = (int)((cards >> CLUB_OFFSET) & 0x1FFF);
    int diamonds = (int)((cards >> DIAMOND_OFFSET) & 0x1FFF);
    int hearts   = (int)((cards >> HEART_OFFSET) & 0x1FFF);
    int spades   = (int)((cards >> SPADE_OFFSET) & 0x1FFF);

    // Step 2: 결합 랭크 정보 계산
    int ranks = clubs | diamonds | hearts | spades;    // 존재하는 모든 랭크
    int uniqueRanks = nBitsTable[ranks];               // 고유 랭크 수
    int duplicates = numberOfCards - uniqueRanks;       // 중복 카드 수

    // Step 3: Flush 감지 (5개 이상 고유 랭크 존재 시)
    if (uniqueRanks >= 5) {
        // 각 suit에서 5장 이상인 것을 찾아 Flush/StraightFlush 판정
        foreach (int suitMask in [clubs, diamonds, hearts, spades]) {
            if (nBitsTable[suitMask] >= 5) {
                if (straightTable[suitMask] != 0)
                    return HANDTYPE_VALUE_STRAIGHTFLUSH
                         + (straightTable[suitMask] << TOP_CARD_SHIFT);
                retval = HANDTYPE_VALUE_FLUSH + TopFive(suitMask);
                break;
            }
        }
    }

    // Step 4: Straight 체크
    if (retval == 0 && straightTable[ranks] != 0)
        retval = HANDTYPE_VALUE_STRAIGHT + (straightTable[ranks] << TOP_CARD_SHIFT);

    // Step 5: Flush/Straight가 있고 중복 < 3이면 조기 반환
    if (retval != 0 && duplicates < 3)
        return retval;

    // Step 6: 중복 수에 따른 분기 (Pair, TwoPair, Trips, FullHouse, Quads)
    switch (duplicates) {
        case 0: return HANDTYPE_VALUE_HIGHCARD + TopFive(ranks);
        case 1: // ONE PAIR - XOR로 페어 랭크 추출
        case 2: // TWO PAIR 또는 TRIPS
        default: // FOUR_OF_A_KIND, FULL_HOUSE
    }
}
```

XOR 기반 중복 감지 기법:
- `clubs XOR diamonds XOR hearts XOR spades`: 홀수 번 등장하는 랭크만 SET
- `singles = ranks XOR (c XOR d XOR h XOR s)`: 페어 랭크 추출
- `(c AND d) OR (h AND s) OR (c AND h) OR (d AND s)`: Trips/Quads 감지
- `c AND d AND h AND s`: Quads 전용 (4개 suit 모두에 등장)

### 8.6 17개 게임별 평가기 라우팅 테이블

`core.evaluate_hand()`와 `core.calc_odds()`가 게임 유형에 따라 적절한 평가기로 라우팅한다.

| 게임 키 | 평가기 | 대상 게임 | 입력 | 특수 처리 |
|---------|--------|----------|------|----------|
| `HOLDEM` | `Hand.Evaluate` | Texas Hold'em | 홀카드 2 + 보드 5 | 표준 7장 평가 |
| `PINEAPPL` | `Hand.Evaluate` | Pineapple | 홀카드 2 + 보드 5 | Hold'em과 동일 |
| `6THOLDEM` | `holdem_sixplus.eval` | 6+ (Trips > Straight) | 홀카드 2 + 보드 5 | Trips/Straight 값 사후 교환 |
| `6PHOLDEM` | `holdem_sixplus.eval` | 6+ (Straight > Trips) | 홀카드 2 + 보드 5 | 표준 6+ 랭킹 |
| `OMAHA` | `OmahaEvaluator.EvaluateHigh` | Omaha | 홀카드 4 + 보드 5 | C(4,2)×C(5,3) = 60 조합 |
| `OMAHAHL` | `OmahaEvaluator` + `EvaluateLow` | Omaha Hi-Lo | 홀카드 4 + 보드 5 | Hi + Lo 동시 평가 |
| `OMAHA5` | `Omaha5Evaluator.EvaluateHigh` | Five Card Omaha | 홀카드 5 + 보드 5 | C(5,2)×C(5,3) = 100 조합 |
| `COUR` | `Omaha5Evaluator` | Courchevel | 홀카드 5 + 보드 5 | Omaha5와 동일 |
| `OMAHA6` | `Omaha6Evaluator.EvaluateHigh` | Six Card Omaha | 홀카드 6 + 보드 5 | Memory-mapped 파일 사용 |
| `5DRAW` | `draw.HandOdds` | Five Card Draw | 5장 | 표준 5장 평가 |
| `27DRAW` | `draw.HandOdds(seven_deuce_lowball=true)` | 2-7 Single Draw | 5장 | Lowball, A=High |
| `27TRIPLE` | `draw.HandOdds(seven_deuce_lowball=true)` | 2-7 Triple Draw | 5장 | Lowball, A=High |
| `A5TRIPLE` | `draw.a5_HandOdds` | A-5 Triple Draw | 5장 | A-5 Lowball |
| `BADUGI` | `draw.badugi` | Badugi | 4장 | 4 suit 다른 조합 평가 |
| `BADEUCY` | `draw.badugi` | Badeucy | 5장 | Badugi + 2-7 혼합 |
| `BADACEY` | `draw.badugi` | Badacey | 5장 | Badugi + A-5 혼합 |
| `7STUD` / `7STUDHL` / `RAZZ` | `stud.odds` | Stud 계열 | 7장 | SevenCards/Razz evaluator |

**IPokerEvaluator 인터페이스**:

```csharp
interface IPokerEvaluator
{
    void Evaluate(ref ulong HiResult, ref short LowResult,
                  ulong Hand, ulong OpenCards);
    bool IsHighLow { get; }
}
```

구현체:
- `SevenCards` - 7-Card Stud 평가
- `Razz` - A-5 Lowball Stud 평가 (King high 리맵)
- `Badugi` - 4장 다른 suit Lowball 평가

**Omaha 조합 사전 계산**:

| 평가기 | 사전 계산 조합 수 | 메모리 방식 |
|--------|:----------------:|-----------|
| `OmahaEvaluator` | C(52,4) = 270,725 | 인메모리 배열 |
| `Omaha5Evaluator` | C(52,5) = 2,598,960 | 인메모리 배열 |
| `Omaha6Evaluator` | C(52,6) = 20,358,520 | Memory-mapped file (`omaha6.vpt`, 128B/레코드) |

### 8.7 Monte Carlo 승률 계산

적응형 임계값 기반 Monte Carlo 시뮬레이션으로 실시간 승률을 계산한다. 전체 조합 수가 임계값(MC_NUM) 미만이면 전수 열거하여 정확한 확률을 계산하고, 이상이면 랜덤 샘플링으로 전환한다.

| 게임 | MC_NUM 임계값 | 조합 특성 | 방식 |
|------|:------:|----------|------|
| Hold'em | 100,000 | 전수 조사 가능 범위 넓음 | 대부분 전수 열거 |
| Omaha 4/5 | 10,000 | 조합 수 급증 | Monte Carlo 전환 빈번 |
| Omaha 6 | 1,000 | Memory-mapped 조합 사용 | 거의 항상 Monte Carlo |

처리 흐름:
1. 모든 pocket 카드와 dead 카드를 `ulong` bitmask로 변환
2. 남은 board 카드 조합 열거: `Hands(board, allUsedCards, 5)`
3. 열거 수 > MC_NUM이면 `RandomHands()`로 Monte Carlo 전환
4. 각 시뮬레이션에서 핸드 평가 -> 승/무/패 카운트
5. 승률 = 승 / 총 시뮬레이션 수

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
        // 200ms 이내 완료 보장 (적응형 조기 종료)
    }
}
```

**Outs 계산**: `Hand.OutsMask`가 모든 단일 카드 추가를 열거하여, 해당 카드가 추가되었을 때 플레이어가 모든 상대를 이기는 카드의 bitmask를 반환한다. 이를 통해 방송 화면에 "Outs: 9장" 같은 정보를 표시한다.

### 8.8 PocketHand169 분류 (Sklansky 그룹핑)

Texas Hold'em의 Pre-Flop 핸드를 169개 전략적 타입으로 분류한다.

| 분류 | 수량 | 예시 |
|------|:----:|------|
| Pocket Pair | 13개 | AA, KK, QQ, JJ, ..., 22 |
| Suited | 78개 | AKs, AQs, AJs, ..., 32s |
| Offsuit | 78개 | AKo, AQo, AJo, ..., 32o |
| None | 1개 | 빈 값 (값 0) |
| **합계** | **170** | |

```csharp
enum PocketHand169Enum {
    None = 0,
    AA = 1, KK = 2, QQ = 3, ..., 22 = 13,
    AKs = 14, AQs = 15, ..., 32s = 91,
    AKo = 92, AQo = 93, ..., 32o = 169
}
```

사전 계산 확률 테이블:
- `PreCalcPlayerOdds[169][9]`: 169개 핸드 타입 x 1~9명 상대에 대한 승률
- `PreCalcOppOdds[169][9]`: 상대 관점 승률

`PocketHand169Type(ourcards)` 함수로 홀카드 2장을 169개 canonical 타입 중 하나에 매핑하여, 사전 계산 테이블에서 Pre-Flop 승률을 O(1)로 즉시 조회한다. 이를 통해 방송 화면에 "AA vs KK: 80% vs 20%" 같은 Pre-Flop 확률을 Monte Carlo 연산 없이 즉시 표시할 수 있다.

---

## 9. RFID 카드 인식 시스템

### 9.1 하드웨어 구성

라이브 포커 방송에서 카드 정보를 자동으로 획득하기 위해 테이블에 RFID 리더를 내장한다. 각 리더는 NTAG215 규격의 NFC 태그가 내장된 카드를 비접촉 방식으로 인식한다.

**리더 배치 구성:**

| 위치 | 수량 | 역할 | 안테나 수 |
|------|:----:|------|:---------:|
| 좌석별 리더 | 10대 | 플레이어 홀카드 인식 | 좌석당 2개 |
| 보드 리더 | 1대 | 커뮤니티 카드 인식 | 4개 |
| Muck 리더 | 1대 | 폴드 카드 확인 | 2개 |
| **합계** | **12대** | 동시 운용 | **최대 26개** |

좌석 리더는 플레이어 앞에 배치된 2개의 안테나로 홀카드 2장(또는 Omaha/Draw의 다장 카드)을 감지한다. 보드 리더는 커뮤니티 카드 영역에 4개 안테나를 배치하여 Flop 3장 + Turn/River를 순차 인식한다. Muck 리더는 딜러 옆에 배치되어 폴드된 카드를 추적한다.

**카드 태그 사양:**

| 항목 | 사양 |
|------|------|
| 태그 규격 | NTAG215 (NFC Forum Type 2) |
| 주파수 | 13.56 MHz |
| 총 카드 수 | 52장 + 조커 (53개 태그) |
| 메모리 | 504 bytes (사용자 데이터) |
| UID | 7 bytes (고유 식별자) |
| 인식 거리 | 최대 5cm (테이블 매립 기준) |

### 9.2 듀얼 트랜스포트 프로토콜

리더는 두 가지 통신 방식을 지원하며, 환경에 따라 자동 전환된다.

```
reader_module (통합 관리)
    +-- v2_module (신형 WiFi 리더)
    |   +-- TCP/WiFi 모드: TLS 1.3 암호화 무선 연결
    |   +-- USB 모드: 유선 폴백
    +-- skye_module (SkyeTek USB 리더)
        +-- USB HID 모드: SkyeTek 프로토콜
```

| 프로토콜 | 인터페이스 | 보안 | 대상 장비 | 우선순위 |
|----------|----------|------|----------|:--------:|
| **TCP/WiFi** | 네트워크 소켓 | TLS 1.3 (.NET SslStream) | v2 WiFi 리더 | 기본 |
| **USB HID** | HID API | 없음 (물리 연결) | SkyeTek 리더 / v2 폴백 | 폴백 |

**자동 폴백 로직:**

```
1. WiFi 연결 시도 (v2_module)
   +-- 성공 -> TLS 핸드셰이크 -> 정상 운영
   +-- 실패 (타임아웃 / 신호 불량)
       +-- USB 연결 시도
           +-- 성공 -> USB HID 프로토콜로 운영
           +-- 실패 -> reader_state.disconnected, 재시도 루프
```

### 9.3 텍스트 커맨드 프로토콜

리더와 ASCII 텍스트 기반으로 통신한다. 모든 명령은 줄바꿈(`\n`)으로 구분되며, 응답은 `OK` 접두어로 시작한다.

**형식:** `COMMAND [ARGS]\n` -> `OK COMMAND [DATA]\n`

**전수 명령 테이블 (22개):**

| 커맨드 | 카테고리 | 설명 | 방향 |
|--------|---------|------|:----:|
| `TI` | 태그 | Tag Inventory - 태그 목록 조회 | -> Reader |
| `TR` | 태그 | Tag Read - 태그 데이터 읽기 | -> Reader |
| `TW` | 태그 | Tag Write - 태그 데이터 쓰기 | -> Reader |
| `AU` | 인증 | Authentication - 리더 인증 | -> Reader |
| `FW` | 펌웨어 | Firmware Update - 펌웨어 업데이트 | -> Reader |
| `GM` | 모듈 조회 | Get Module - 모듈 정보 조회 | -> Reader |
| `GN` | 모듈 조회 | Get Name - 리더 이름 조회 | -> Reader |
| `GP` | 모듈 조회 | Get Password - 비밀번호 조회 | -> Reader |
| `SM` | 모듈 설정 | Set Module - 모듈 설정 변경 | -> Reader |
| `SN` | 모듈 설정 | Set Name - 리더 이름 설정 | -> Reader |
| `SP` | 모듈 설정 | Set Password - 비밀번호 설정 | -> Reader |
| `GH` | 버전 | Get Hardware - 하드웨어 버전 조회 | -> Reader |
| `GF` | 버전 | Get Firmware - 펌웨어 버전 조회 | -> Reader |
| `GV` | 버전 | Get Version - 전체 버전 정보 | -> Reader |
| `GO` | WiFi | Get WLAN - 무선랜 설정 조회 | -> Reader |
| `SO` | WiFi | Set WLAN - 무선랜 설정 변경 | -> Reader |
| `GI` | WiFi | Get IP - IP 주소 조회 | -> Reader |
| `SI` | WiFi | Set IP - IP 주소 설정 | -> Reader |
| `GS` | WiFi | Get SSID - WiFi SSID 조회 | -> Reader |
| `SS` | WiFi | Set SSID - WiFi SSID 설정 | -> Reader |
| `GW` | WiFi | Get WiFi Password - WiFi 비밀번호 조회 | -> Reader |
| `SW` | WiFi | Set WiFi Password - WiFi 비밀번호 설정 | -> Reader |

### 9.4 카드 인식 흐름

태그 감지부터 화면 표시까지의 End-to-End 흐름이다.

```
RFID 안테나 (태그 감지)
    |  [~50ms]
    v
리더 펌웨어 (TI 응답 생성)
    |  [~30ms]
    v
TCP/USB 전송
    |  [~20ms]
    v
RfidManager (CardDetectedEvent 생성)
    |  [~10ms]
    v
카드 ID -> card_type 변환
    |  [~5ms]
    v
유효성 검증 (중복 카드, 활성 카드 확인)
    |  [~5ms]
    v
게임 엔진 전달 (Domain Event)
    |  [~10ms]
    v
GPU 렌더러 (화면 표시)
    |  [~70ms (1 frame @60fps)]
    v
방송 화면 출력
    총: 200ms 이내 End-to-End 보장
```

**유효성 검증 규칙:**

| 검증 항목 | 설명 | 실패 시 |
|----------|------|---------|
| 중복 카드 | 동일 카드가 다른 리더에서 이미 인식됨 | `card_scan_warning` 활성화 |
| 활성 카드 | card_type이 1~52 범위 내 | 무시 |
| 태그 인증 | `card_auth_package_crc` 검증 | 리더 경고 |
| 좌석 매핑 | 리더 번호 -> 좌석 번호 매핑 유효 | 재설정 요청 |

### 9.5 상태 관리

리더의 연결 상태는 reader_state로 관리된다.

```
[disconnected] --TCP 연결--> [connected] --TLS 핸드셰이크--> [negotiating] --인증 완료--> [ok]
      ^                                                                                     |
      +----------------------------에러 / 타임아웃-------------------------------------------+
```

| 상태 | 값 | 설명 | 전이 조건 |
|------|:--:|------|----------|
| disconnected | 0 | 연결 해제 | 초기 상태 / 에러 발생 |
| connected | 1 | TCP 연결 완료 | 소켓 연결 성공 |
| negotiating | 2 | TLS 핸드셰이크 진행 중 | TLS 협상 시작 |
| ok | 3 | 정상 동작 | 인증 성공, Keepalive 유지 |

**콜백 인터페이스:**

| 콜백 | 이벤트 | 설명 |
|------|--------|------|
| `on_tag_event` | 카드 감지 | 태그 ID, 안테나 번호, 타임스탬프 |
| `on_calibrate` | 칼리브레이션 | 안테나 감도 조정 결과 |
| `on_state_changed` | 상태 변경 | reader_state 전이 |
| `on_firmware_update_event` | 펌웨어 | 업데이트 진행률 |

### 9.6 WiFi 관리

WiFi 연결은 wlan_state로 별도 관리된다.

| 상태 | 값 | 설명 |
|------|:--:|------|
| off | 0 | WiFi 꺼짐 |
| on | 1 | WiFi 켜짐 |
| connected_reset | 2 | 연결 후 리셋 |
| ip_acquired | 3 | IP 획득 완료 (정상) |
| not_installed | 4 | WiFi 미설치 |

WiFi 리더는 `KEEPALIVE_INTERVAL` 간격으로 Keepalive 패킷을 전송하며, `NEGOTIATE_INTERVAL` 내에 TLS 핸드셰이크가 완료되지 않으면 연결을 재시도한다. TLS 세션 재개 (SSLSessionParameters)를 지원하여 재연결 시 핸드셰이크 오버헤드를 줄인다.

---

## 10. GPU 렌더링 파이프라인

### 10.1 설계 목표

| 목표 | 정량 기준 |
|------|----------|
| 프레임레이트 | 60fps 유지 (10인 테이블 풀 그래픽) |
| 해상도 | 1080p / 4K 지원 |
| GPU API | DirectX 11 (SharpDX 바인딩) |
| 렌더링 지연 | 16.7ms/frame 이내 |
| GPU 메모리 | 512MB 이내 |
| 동시 출력 | Live + Delayed 두 캔버스 독립 렌더링 |
| 코덱 | 하드웨어 인코딩 우선 (NVENC, AMF, QSV) |

### 10.2 5-Thread Producer-Consumer 아키텍처

GPU 렌더링 파이프라인은 5개의 전용 워커 스레드가 Producer-Consumer 패턴으로 동작한다.

```
+-------------------------------------------------------------------+
|                        mixer (핵심 합성 엔진)                       |
|                          90개 필드 관리                              |
+-------------------------------------------------------------------+
         |              |              |              |              |
         v              v              v              v              v
+-------------+ +-------------+ +-------------+ +-------------+ +-------------+
| Live Thread | | Delayed     | | Audio       | | Write       | | ProcessDelay|
|             | | Thread      | | Thread      | | Thread      | | Thread      |
| 실시간 합성  | | 지연 합성    | | 오디오 믹싱  | | 파일 녹화    | | 딜레이 버퍼 |
| (30/60fps)  | | (보안 딜레이)| | (캡처/합성)  | | (MP4 저장)  | | 관리        |
+------+------+ +------+------+ +------+------+ +------+------+ +------+------+
       |               |               |               |               |
       v               v               v               v               v
  live_frames    delayed_frames    AudioBuffer    write_frames     딜레이 큐
  Channel<T>     Channel<T>       AutoResetEvent  Channel<T>     AutoResetEvent
```

**각 스레드의 역할:**

| 스레드 | 입력 큐 | 동기화 | 출력 |
|--------|--------|--------|------|
| **Live Thread** | `live_frames` (Channel) | `live_lock_obj` | Live Canvas -> NDI/HDMI |
| **Delayed Thread** | `delayed_frames` (Channel) | `delay_lock_obj` | Delayed Canvas -> 방송 |
| **Audio Thread** | `ext_audio_buffer` | `are_audio` (AutoResetEvent) | 오디오 믹싱 결과 |
| **Write Thread** | `write_frames` (Channel) | - | 녹화 파일 (.mp4) |
| **ProcessDelay Thread** | 딜레이 버퍼 | `are_delay` (AutoResetEvent) | delayed_frames 큐 |

각 `Channel<T>`에 대응하는 `CancellationTokenSource`가 존재하며, 종료 시 토큰 취소로 스레드를 안전하게 종료한다.

### 10.3 Dual Canvas 시스템

두 개의 독립 캔버스를 동시에 운영하여 라이브 모니터링과 방송 송출을 분리한다.

```
Video Input --> [Live Canvas] --> Live Output (실시간, 경기장 모니터)
                    |
              [Delay Buffer]  <-- _delay_period (TimeSpan)
                    |
             [Delayed Canvas] --> Delayed Output (N초 지연, 방송 송출)
```

| Canvas | 용도 | 홀카드 표시 | 대상 |
|--------|------|:----------:|------|
| **Live Canvas** | 경기장 모니터 | Trustless 시 숨김 | 선수, 현장 관객 |
| **Delayed Canvas** | 방송 송출 | 설정된 지연 시간 후 표시 | TV/인터넷 시청자 |

**Trustless 모드:** Live Canvas에 홀카드를 절대 표시하지 않는 핵심 보안 기능이다. 게임 무결성 보호를 위해 Live Output에서는 플레이어 카드가 노출되지 않으며, Delayed Canvas에서만 설정된 지연 시간 후에 표시한다. `_sync_live_delay` 플래그가 true이면 Live/Delayed 프레임을 동기화한다.

### 10.4 GPU 벤더별 코덱 설정

GPU 하드웨어 인코딩을 자동 감지하여 최적 코덱을 선택한다.

| GPU 벤더 | 코덱 | API | 우선순위 |
|----------|------|-----|:--------:|
| NVIDIA | NVENC | NvAPIWrapper | 1 |
| AMD | AMF/VCE | AMF SDK | 2 |
| Intel | QSV | Intel Media SDK | 3 |
| Software | x264 | FFmpeg | 폴백 |

**자동 감지 로직:**

```
시스템 GPU 열거
    |
    +-- NVIDIA GPU 감지 -> NVENC 활성화
    +-- AMD GPU 감지 -> AMF 활성화
    +-- Intel GPU 감지 -> QSV 활성화
    +-- 감지 실패 -> Software x264 폴백
```

`_force_sw_encode` 플래그로 소프트웨어 인코딩을 강제할 수 있다. `_rec_hw_encode`는 녹화 시 하드웨어 인코딩 사용 여부를 별도 제어한다.

### 10.5 Cross-GPU 텍스처 공유

두 독립 GPU 컨텍스트 간 텍스처를 공유하는 DXGI SharedHandle 기반 메커니즘을 제공한다.

```
Asset GPU (원본 텍스처)          Canvas GPU (렌더링 대상)
        |                              |
        +-- Texture2D 생성 ----------->|
        |   (SharedResource 플래그)     |
        +-- DXGI SharedHandle 추출 --->|
        |                              +-- OpenSharedResource
        |                              +-- SharedHandle -> Canvas Texture
        |                              +-- Canvas Bitmap 생성
        v                              v
  asset_d2d_bitmap            canvas_d2d_bitmap
```

`prev_bitmap` 캐싱으로 동일 비트맵이 반복될 때 bridge 재생성을 방지한다. 비트맵 크기가 변경될 때만 dispose -> create_new를 호출한다.

### 10.6 4가지 그래픽 요소 타입

#### image_element (41개 필드)

이미지 기반 그래픽 요소이다. GPU Effects Chain으로 실시간 효과를 적용한다.

| 카테고리 | 필드 | 타입 | 설명 |
|----------|------|------|------|
| **위치** | x, y | float | 캔버스 상 좌표 |
| **크기** | width, height | float | 요소 크기 |
| **소스** | source_path | string | 이미지 파일 경로 |
| **표시** | opacity | float | 투명도 (0.0 ~ 1.0) |
| | visible | bool | 표시 여부 |
| | z_order | int | 렌더링 순서 (깊이) |
| **변환** | rotation | float | 회전 각도 |
| | flip_h, flip_v | bool | 좌우/상하 반전 |
| | scale | Size2F | 스케일 |
| **효과** | tint_color | Color | 색상 틴트 |
| | brightness | float | 밝기 |
| | hue | float | 색조 회전 |
| **그림자** | shadow_offset | Vector2 | 그림자 오프셋 |
| | shadow_blur | float | 그림자 블러 |
| | shadow_color | Color | 그림자 색상 |
| **애니메이션** | animation_state | AnimationState | 현재 애니메이션 상태 |
| | seq_num, frame_num | int | 시퀀스/프레임 번호 |
| **자르기** | crop_rect | Rect | 자르기 영역 |

GPU Effects Chain: `Crop -> Transform -> Brightness -> Alpha -> ColorMatrix -> HueRotation`

#### text_element (52개 필드)

DirectWrite 기반 텍스트 렌더링 요소이다.

| 카테고리 | 필드 | 타입 | 설명 |
|----------|------|------|------|
| **위치** | x, y | float | 좌표 |
| **영역** | width, height | float | 텍스트 영역 크기 |
| **텍스트** | text | string | 표시할 텍스트 |
| **폰트** | font_family | string | 글꼴 이름 |
| | font_size | float | 글꼴 크기 |
| | font_color | Color | 글자 색상 |
| | font_weight | FontWeight | 굵기 |
| **정렬** | text_align | TextAlignment | 좌/중/우 정렬 |
| | word_wrap | bool | 줄바꿈 |
| **외곽선** | outline_color | Color | 외곽선 색상 |
| | outline_width | float | 외곽선 두께 |
| **배경** | background_color | Color | 배경색 |
| | padding | Thickness | 내부 여백 |
| **그림자** | shadow_offset | Vector2 | 그림자 |
| **애니메이션** | animation_state | AnimationState | 애니메이션 상태 |

**텍스트 효과:** Ticker (수평 스크롤), Reveal (글자별 등장), Static, Shadow. `custom_text_renderer`로 아웃라인/그림자를 렌더링한다.

#### pip_element (12개 필드)

카드 문양 표시 또는 카메라 PIP 배치를 위한 요소이다.

| 필드 | 타입 | 설명 |
|------|------|------|
| x, y | float | 위치 |
| size | float | 크기 |
| suit | int | 문양 (0=Club, 1=Diamond, 2=Heart, 3=Spade) |
| rank | int | 숫자 (0=2, 12=A) |
| face_up | bool | 앞면/뒷면 |
| highlighted | bool | 강조 표시 |
| opacity | float | 투명도 |
| z_pos | int | Z-order |
| src_rect | Rect | 소스 영역 |
| dst_rect | Rect | 대상 영역 |
| dev_index | int | 캡처 디바이스 인덱스 |
| animation_state | AnimationState | 애니메이션 |

#### border_element (8개 필드)

테두리 장식 요소이다.

| 필드 | 타입 | 설명 |
|------|------|------|
| x, y | float | 위치 |
| width, height | float | 크기 |
| color | Color | 테두리 색상 |
| thickness | float | 테두리 두께 |
| corner_radius | float | 모서리 라운드 |
| visible | bool | 표시 여부 |

### 10.7 애니메이션 시스템

#### AnimationState (16개 상태)

| 값 | 상태 | 용도 |
|:--:|------|------|
| 0 | FadeIn | 페이드 인 |
| 1 | Glint | 반짝임 |
| 2 | GlintGrow | 반짝임 + 확대 |
| 3 | GlintRotateFront | 반짝임 + 앞면 회전 |
| 4 | GlintShrink | 반짝임 + 축소 |
| 5 | PreStart | 시작 준비 |
| 6 | ResetRotateBack | 리셋 + 뒷면 회전 |
| 7 | ResetRotateFront | 리셋 + 앞면 회전 |
| 8 | Resetting | 리셋 중 |
| 9 | RotateBack | 뒷면 회전 |
| 10 | Scale | 스케일 변경 |
| 11 | SlideAndDarken | 슬라이드 + 어두워짐 |
| 12 | SlideDownRotateBack | 하단 슬라이드 + 뒷면 회전 |
| 13 | SlideUp | 상단 슬라이드 |
| 14 | Stop | 정지 |
| 15 | Waiting | 대기 |

#### 11개 애니메이션 클래스

| 클래스 | 대상 | 효과 | 용도 |
|--------|------|------|------|
| BoardCardAnimation | 보드 카드 | 등장 | 커뮤니티 카드 공개 |
| PlayerCardAnimation | 플레이어 카드 | 등장 | 홀카드 공개 |
| CardBlinkAnimation | 카드 | 깜빡임 | 하이라이트 |
| CardUnhiliteAnimation | 카드 | 하이라이트 해제 | 포커스 이동 |
| CardFace | 카드 | 면 전환 (앞/뒤) | 카드 뒤집기 |
| GlintBounceAnimation | 그래픽 | 반짝임 바운스 | 강조 효과 |
| OutsCardAnimation | 아웃츠 | 카드 등장 | Outs 표시 |
| PanelImageAnimation | 패널 | 이미지 전환 | 로고 전환 |
| PanelTextAnimation | 패널 | 텍스트 전환 | 자막 전환 |
| FlagHideAnimation | 국기 | 숨김 | 국기 퇴장 |
| SequenceAnimation | 전체 | 연속 재생 | 복합 애니메이션 |

**Easing 함수:** Linear, EaseIn, EaseOut, EaseInOut을 지원한다. 애니메이션 타이밍 상수(`IMAGE_LOOP`, `IMAGE_INTRO`, `IMAGE_OUTRO`, `ANIM_IN_FADE_START_POS` 등)로 세밀한 타이밍을 제어한다.

---

## 11. 네트워크 프로토콜

### 11.1 프로토콜 스택 4계층

서버와 클라이언트 간 통신은 4계층 프로토콜 스택으로 구성된다.

```
+-------------------------------------------------------+
|  Layer 4: Application                                   |
|  113+ 커맨드 (IRemoteRequest/Response)                  |
|  Source Generator 기반 자동 등록                         |
+-------------------------------------------------------+
|  Layer 3: Serialization                                 |
|  Protobuf + System.Text.Json fallback                  |
+-------------------------------------------------------+
|  Layer 2: Security                                      |
|  TLS 1.3 (.NET SslStream)                              |
+-------------------------------------------------------+
|  Layer 1: Transport                                     |
|  gRPC (HTTP/2) + mDNS/DNS-SD Discovery                 |
+-------------------------------------------------------+
```

| 계층 | 기술 | 역할 |
|------|------|------|
| Application | 113+ Request/Response 쌍 | 비즈니스 로직 커맨드 |
| Serialization | Protobuf (System.Text.Json 폴백) | 바이너리 직렬화 |
| Security | TLS 1.3 (.NET SslStream) | 전송 암호화 |
| Transport | gRPC HTTP/2 + UDP Discovery | 양방향 스트리밍 + 서버 검색 |

### 11.2 gRPC 서비스 정의

| 서비스 | 역할 | 주요 RPC 메서드 |
|--------|------|----------------|
| **GameService** | 게임 상태 스트리밍 | `GetGameInfo`, `NewHand`, `EndHand`, `SetGameType`, `StreamGameState` |
| **PlayerService** | 플레이어 정보 CRUD | `GetPlayerInfo`, `AddPlayer`, `DeletePlayer`, `SetBet`, `SetBlind` |
| **CardService** | 카드 이벤트 스트리밍 | `SetBoardCard`, `VerifyCard`, `ForceCardScan`, `DrawDone`, `StreamCards` |
| **DisplayService** | 디스플레이 제어 | `SetFieldVisibility`, `EnableGfx`, `ShowPanel`, `SetStripDisplay` |
| **MediaService** | 미디어 제어 | `GetMediaList`, `PlayMedia`, `LoopMedia`, `SetCamera`, `SetPip` |

### 11.3 핵심 메시지 타입

#### GameInfoResponse (75+ 필드)

게임 상태 동기화의 핵심 메시지이다. 테이블의 전체 상태를 단일 메시지로 전달한다.

| 카테고리 | 필드 수 | 주요 필드 |
|----------|:-------:|----------|
| **블라인드** | 8 | Ante, Small, Big, Third, ButtonBlind, BringIn, BlindLevel, NumBlinds |
| **좌석** | 7 | PlDealer, PlSmall, PlBig, PlThird, ActionOn, NumSeats, NumActivePlayers |
| **베팅** | 6 | BiggestBet, SmallestChip, BetStructure, Cap, MinRaiseAmt, PredictiveBet |
| **게임** | 4 | GameClass, GameType, GameVariant, GameTitle |
| **보드** | 5 | OldBoardCards, CardsOnTable, NumBoards, CardsPerPlayer, ExtraCardsPerPlayer |
| **상태** | 6 | HandInProgress, EnhMode, GfxEnabled, Streaming, Recording, ProVersion |
| **디스플레이** | 7 | ShowPanel, StripDisplay, TickerVisible, FieldVisible, PlayerPicW/H |
| **특수** | 6 | RunItTimes, RunItTimesRemaining, BombPot, SevenDeuce, CanChop, IsChopped |
| **드로우** | 4 | DrawCompleted, DrawingPlayer, StudDrawInProgress, AnteType |
| **승률** | 10 | win_pct[10], equity[10] |
| **타이머** | 5 | shot_clock, time_bank |
| **플레이어** | 20 | players[10] { name, chips, cards, status } |

#### PlayerInfoResponse (20 필드)

| 필드 | 타입 | 설명 |
|------|------|------|
| Player | int | 좌석 번호 (0-9) |
| Name | string | 표시 이름 |
| LongName | string | 풀 네임 |
| HasCards | bool | 카드 보유 여부 |
| Folded | bool | 폴드 상태 |
| AllIn | bool | 올인 상태 |
| SitOut | bool | 자리비움 |
| Bet | int | 현재 베팅액 |
| DeadBet | int | 데드 베팅 |
| Stack | int | 칩 스택 |
| NitGame | int | Nit 금액 |
| HasPic | bool | 프로필 사진 여부 |
| Country | string | 국가 코드 |
| Vpip | int | VPIP (자발적 팟 참여율) |
| Pfr | int | PFR (프리플롭 레이즈) |
| Agr | int | AGR (공격성) |
| Wtsd | int | WTSD (쇼다운 진행률) |
| CumWin | int | 누적 수익 |

### 11.4 프로토콜 명령 (113+, 9개 카테고리)

#### Connection (연결 관리) - 9개

| 명령 | 방향 | 주요 필드 |
|------|------|----------|
| `CONNECT` | Req/Resp | License(ulong) |
| `DISCONNECT` | Req/Resp | - |
| `AUTH` | Req/Resp | Password, Version |
| `KEEPALIVE` | Req | - |
| `IDTX` | Req/Resp | IdTx(string) |
| `HEARTBEAT` | Req/Resp | - |
| `GAME_STATE` | Resp | GameType, InitialSync |
| `GAME_VARIANT_LIST` | Req/Resp | - |
| `COUNTRY_LIST` | Req/Resp | - |

#### Game (게임 제어) - 10개

`GAME_INFO`, `NEW_HAND`, `END_HAND`, `NIT_GAME`, `GAME_TYPE`, `GAME_VARIANT`, `GAME_CLEAR`, `GAME_TITLE`, `GAME_SAVE_BACK`, `GAME_STATE`

#### Player (플레이어 관리) - 21개

| 명령 | 방향 | 주요 필드 |
|------|------|----------|
| `PLAYER_INFO` | Req/Resp | Player, Name, Stack, Stats (20 필드) |
| `PLAYER_CARDS` | Req/Resp | Player, Cards(string) |
| `PLAYER_BET` | Req/Resp | Player, Amount |
| `PLAYER_BLIND` | Req | Player, Amount |
| `PLAYER_ADD` | Req | Seat, Name |
| `PLAYER_DELETE` | Req | Seat |
| `PLAYER_COUNTRY` | Req | Player, Country |
| `PLAYER_DEAD_BET` | Req | Player, Amount |
| `PLAYER_PICTURE` | Resp | Player, Picture |
| `DELAYED_PLAYER_INFO` | Req/Resp | - |

+ PLAYER_STATUS, PLAYER_ACTION, PLAYER_STACK, PLAYER_POSITION, PLAYER_STATS 등 11개

#### Cards & Board (카드/보드) - 6개

`BOARD_CARD`, `CARD_VERIFY`, `FORCE_CARD_SCAN`, `DRAW_DONE`, `EDIT_BOARD`, `CARD_REVEAL`

#### Display (디스플레이/UI) - 13개

`FIELD_VISIBILITY`, `FIELD_VAL`, `GFX_ENABLE`, `ENH_MODE`, `SHOW_PANEL`, `STRIP_DISPLAY`, `BOARD_LOGO`, `PANEL_LOGO`, `ACTION_CLOCK`, `DELAYED_FIELD_VISIBILITY`, `DELAYED_GAME_INFO`, `SHOW_ANIMATION`, `HIDE_ANIMATION`

#### Media (미디어/카메라) - 9개

`MEDIA_LIST`, `MEDIA_PLAY`, `MEDIA_LOOP`, `CAM`, `PIP`, `CAP`, `GET_VIDEO_SOURCES`, `VIDEO_SOURCES`, `SOURCE_MODE`

#### Betting (베팅/재무) - 5개

`PAYOUT`, `MISS_DEAL`, `CHOP`, `FORCE_HEADS_UP`, `FORCE_HEADS_UP_DELAYED`

#### Data Transfer (데이터 전송) - 4개

`SKIN_CHUNK`, `COMM_DL`, `AT_DL`, `VTO`

#### History & RFID (기록/RFID) - 5개

`HAND_HISTORY`, `HAND_LOG`, `GAME_LOG`, `COUNTRY_LIST`, `READER_STATUS`

### 11.5 실시간 이벤트 콜백 (16개)

클라이언트가 구현해야 하는 네트워크 이벤트 인터페이스이다.

| 콜백 | 이벤트 |
|------|--------|
| `NetworkQualityChanged` | 네트워크 품질 변경 (Good / Fair / Poor) |
| `OnConnected` | 서버 연결 성공 |
| `OnDisconnected` | 연결 해제 |
| `OnAuthReceived` | 인증 응답 |
| `OnReaderStatusReceived` | RFID 리더 상태 |
| `OnHeartBeatReceived` | Heartbeat 응답 |
| `OnDelayedGameInfoReceived` | 지연 게임 정보 |
| `OnGameInfoReceived` | 게임 정보 업데이트 (75+ 필드) |
| `OnMediaListReceived` | 미디어 목록 |
| `OnCountryListReceived` | 국가 목록 |
| `OnPlayerPictureReceived` | 플레이어 사진 |
| `OnGameVariantListReceived` | 게임 변형 목록 |
| `OnPlayerInfoReceived` | 플레이어 정보 업데이트 |
| `OnDelayedPlayerInfoReceived` | 지연 플레이어 정보 |
| `OnVideoSourcesReceived` | 비디오 소스 목록 |
| `OnSourceModeReceived` | 소스 모드 변경 |

### 11.6 UDP Discovery 프로토콜

로컬 네트워크에서 서버를 자동 검색하기 위한 UDP Broadcast 프로토콜이다.

```
Client                          Server
  |                               |
  +-- UDP Broadcast ------------->|  (포트 9000)
  |   "DISCOVER_SERVER"          |
  |                               |
  |<---- UDP Response ------------|
  |   ServerInfo {               |
  |     ip, port, name,          |
  |     version, game_type       |
  |   }                          |
  |                               |
  +-- gRPC Connect -------------->|  (응답받은 포트)
  |                               |
  +-- Login Request ------------->|
  |<---- Login Response ----------|
  |   { session_id, permissions } |
  +-------------------------------+
```

- 서버 UDP 포트: 9000 (수신 버퍼 10,000 bytes)
- 보조 포트: 9001, 9002 (멀티서버 환경)
- 클라이언트: 1초 간격 Broadcast
- Keepalive: 서버 10초, 클라이언트 3초

### 11.7 암호화

| 통신 구간 | 암호화 방식 |
|----------|------------|
| gRPC 전체 | TLS 1.3 (.NET SslStream) 내장 |
| UDP Discovery | 평문 (검색 단계만, 서버 위치 정보만 포함) |
| RFID WiFi 리더 | TLS 1.3 (별도 인증서) |
| Master-Slave | TLS 1.3 (gRPC 내장) |

### 11.8 세션 흐름

```
Client (Remote)                           Server
     |                                        |
     +---- UDP Broadcast (id_tx) ------------>| :9000
     |<---- UDP Response (id_tx) -------------|
     |                                        |
     |==== gRPC Connect =====================>| :9001
     |                                        |
     |<---- ConnectResponse(License) ---------|
     |<---- IdtxResponse(IdTx="...") ---------|
     |                                        |
     |---- IdtxRequest(IdTx="...") ---------->|
     |---- ConnectRequest ------------------->|
     |                                        |
     |---- AuthRequest(Password,Version) ---->|
     |<---- AuthResponse ---------------------|
     |                                        |
     |<---- GameStateResponse(HOLDEM,true) ---|  <- 초기 동기화
     |<---- GameInfoResponse(75+ fields) -----|  <- 전체 상태
     |<---- PlayerInfoResponse x N -----------|  <- 각 플레이어
     |<---- PlayerCardsResponse x N ----------|  <- 각 홀카드
     |                                        |
     | - - - KeepAlive (3초 간격) - - - - - ->|
     |                                        |
     |<---- [실시간 업데이트 스트림] ----------|
     |      GameInfoResponse (변경시)          |
     |      PlayerInfoResponse (변경시)        |
     |      BoardCardResponse (보드 변경)       |
     |                                        |
     |---- DisconnectRequest ----------------->|
     |<---- DisconnectResponse ----------------|
```

---

## 12. 화면별 기능 명세

시스템은 11개 화면에 걸쳐 총 151개 기능으로 구성된다. 각 기능에 P0(핵심), P1(확장), P2(고급) 우선순위를 부여한다.

### 12.1 Main Window (MW-001 ~ MW-010)

메인 윈도우는 서버의 진입점이며, 게임 선택/시작/종료와 전체 상태 모니터링을 담당한다.

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

### 12.2 Sources 탭 (SRC-001 ~ SRC-010)

비디오 입력 소스(카메라, 캡처 카드)를 관리하는 화면이다.

| ID | 기능 | 설명 | 우선순위 |
|----|------|------|:--------:|
| SRC-001 | 비디오 소스 목록 | 사용 가능한 캡처 장치 나열 | P0 |
| SRC-002 | 소스 미리보기 | 선택한 소스의 실시간 미리보기 | P0 |
| SRC-003 | 해상도 설정 | 입력 해상도 선택 (1080p/4K) | P0 |
| SRC-004 | 프레임레이트 설정 | 30/60fps 선택 | P1 |
| SRC-005 | NDI 소스 감지 | 네트워크 NDI 소스 자동 감지 | P1 |
| SRC-006 | 캡처 카드 지원 | HDMI/SDI 입력 | P0 |
| SRC-007 | 소스 상태 표시 | 활성/비활성/에러 상태 아이콘 | P1 |
| SRC-008 | 소스별 색보정 | 밝기, 대비, 채도 조정 | P2 |
| SRC-009 | 크롭 설정 | 입력 영상 자르기 | P2 |
| SRC-010 | 오디오 소스 연결 | 비디오 소스에 오디오 채널 매핑 | P2 |

### 12.3 Outputs 탭 (OUT-001 ~ OUT-012)

렌더링된 방송 화면의 출력 대상을 설정한다.

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

### 12.4 GFX1 탭 (G1-001 ~ G1-024)

게임 진행 중 GFX 운영자가 가장 자주 사용하는 핵심 제어 화면이다.

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
| G1-014 | 수동 카드 입력 | RFID 실패 시 마우스 클릭 카드 선택 | P0 |
| G1-015 | 자동 핸드 번호 | 새 핸드 시 자동 증가 | P0 |
| G1-016 | 사이드팟 분리 | 다중 사이드팟 개별 표시 | P1 |
| G1-017 | Rabbit Hunt | 남은 커뮤니티 카드 공개 | P1 |
| G1-018 | Bounty 금액 | 바운티 토너먼트용 현상금 표시 | P1 |
| G1-019 | 국가 플래그 | 플레이어 국적 표시 | P1 |
| G1-020 | 단축키 연결 | F1-F10으로 좌석별 빠른 조작 | P1 |
| G1-021 | Ante 설정 | Ante 금액 표시 | P1 |
| G1-022 | 애니메이션 제어 | 카드/칩 애니메이션 On/Off | P1 |
| G1-023 | Run It Twice | 보드를 2번 전개하는 모드 | P2 |
| G1-024 | 블라인드 타이머 | 토너먼트 블라인드 레벨 타이머 | P2 |

### 12.5 GFX2 탭 (G2-001 ~ G2-013)

플레이어 통계, 토너먼트 정보 등 부가 그래픽을 제어한다.

| ID | 기능 | 설명 | 우선순위 |
|----|------|------|:--------:|
| G2-001 | VPIP 통계 | 자발적 팟 참여율 표시 | P1 |
| G2-002 | PFR 통계 | Pre-Flop Raise 비율 | P1 |
| G2-003 | AF 통계 | Aggression Factor | P1 |
| G2-004 | 핸드 수 표시 | 플레이어별 참여 핸드 수 | P1 |
| G2-005 | 플레이어 프로필 | 사진, 이름, 국적, 별명 | P1 |
| G2-006 | 토너먼트 순위 | 현재 칩 순위 | P1 |
| G2-007 | 남은 인원 | 토너먼트 잔여 참가자 수 | P1 |
| G2-008 | 총 상금 풀 | 토너먼트 전체 상금 | P1 |
| G2-009 | 통계 초기화 | 선택적/전체 통계 리셋 | P1 |
| G2-010 | 칩 그래프 | 시간대별 칩 변동 그래프 | P2 |
| G2-011 | Payout 구조 | 입상 상금 분배표 | P2 |
| G2-012 | ICM 계산 | Independent Chip Model 계산 | P2 |
| G2-013 | 통계 내보내기 | CSV/JSON 통계 데이터 내보내기 | P2 |

### 12.6 GFX3 탭 (G3-001 ~ G3-013)

방송 연출용 하단 자막, 타이틀, 오프닝/엔딩 그래픽을 제어한다.

| ID | 기능 | 설명 | 우선순위 |
|----|------|------|:--------:|
| G3-001 | 하단 자막 | 방송 하단 텍스트 크롤 | P0 |
| G3-002 | 방송 제목 | 프로그램명 표시 | P0 |
| G3-003 | 뉴스 티커 | 연속 스크롤 텍스트 | P1 |
| G3-004 | 스폰서 로고 | 스폰서 로고 이미지 삽입 | P1 |
| G3-005 | 텍스트 오버레이 | 임의 텍스트 화면 배치 | P1 |
| G3-006 | 이미지 오버레이 | 임의 이미지 화면 배치 | P1 |
| G3-007 | 멀티 레이어 | 그래픽 요소 z-order 관리 | P1 |
| G3-008 | 프리셋 저장/로드 | 자주 쓰는 레이아웃 저장 | P1 |
| G3-009 | 타이머 그래픽 | 커스텀 카운트다운 타이머 | P1 |
| G3-010 | 오프닝 애니메이션 | 방송 시작 그래픽 | P2 |
| G3-011 | 엔딩 애니메이션 | 방송 종료 그래픽 | P2 |
| G3-012 | Twitch 채팅 | 채팅 오버레이 | P2 |
| G3-013 | Picture-in-Picture | 작은 영상 삽입 | P2 |

### 12.7 Commentary 탭 (CM-001 ~ CM-007)

해설자 전용 화면으로, 시청자에게 노출되지 않는 홀카드 정보를 제공한다.

| ID | 기능 | 설명 | 우선순위 |
|----|------|------|:--------:|
| CM-001 | 전체 홀카드 뷰 | 모든 플레이어 홀카드 실시간 표시 | P0 |
| CM-002 | 승률 실시간 | 전체 플레이어 승률 동시 표시 | P0 |
| CM-003 | 핸드 랭크 표시 | 각 플레이어 현재 핸드 등급 | P0 |
| CM-004 | 보안 분리 | 방송 출력과 완전 분리된 별도 네트워크 전송 | P0 |
| CM-005 | 폴드 카드 히스토리 | 이미 폴드한 플레이어의 카드 표시 | P1 |
| CM-006 | 아웃 카운트 | 남은 유효 카드 수 표시 | P1 |
| CM-007 | 팟 오즈 | 현재 팟 대비 콜 금액 비율 | P1 |

### 12.8 System 탭 (SYS-001 ~ SYS-016)

서버 설정, 라이선스, RFID, 네트워크 등 시스템 전반을 관리한다.

| ID | 기능 | 설명 | 우선순위 |
|----|------|------|:--------:|
| SYS-001 | 서버 포트 설정 | TCP 리스닝 포트 | P0 |
| SYS-002 | UDP Discovery 포트 | 클라이언트 자동 검색용 (9000/9001/9002) | P0 |
| SYS-003 | 라이선스 관리 | 라이선스 키 입력/확인/갱신 | P0 |
| SYS-004 | RFID 리더 설정 | 리더별 IP/포트/좌석 매핑 | P0 |
| SYS-005 | RFID 상태 모니터 | 12대 리더 실시간 상태 | P0 |
| SYS-006 | 카드 인식 테스트 | 개별 리더 카드 읽기 테스트 | P0 |
| SYS-007 | 네트워크 상태 | 연결된 클라이언트 목록 + ping | P0 |
| SYS-008 | 암호화 설정 | TLS 1.3 On/Off | P0 |
| SYS-009 | 출력 장치 설정 | GPU, 모니터, 캡처 카드 선택 | P0 |
| SYS-010 | 스킨 경로 설정 | 스킨 파일 디렉토리 지정 | P0 |
| SYS-011 | 로그 레벨 설정 | Debug/Info/Warn/Error | P1 |
| SYS-012 | Master/Slave 설정 | 다중 서버 Master-Slave 구성 | P1 |
| SYS-013 | 키보드 단축키 | 전역 단축키 커스터마이징 | P1 |
| SYS-014 | 성능 모니터 | CPU/GPU/메모리 사용량 표시 | P1 |
| SYS-015 | 언어 설정 | UI 언어 선택 (130개 lang_enum) | P1 |
| SYS-016 | 백업/복원 | 전체 설정 백업 및 복원 | P1 |

### 12.9 Skin Editor (SK-001 ~ SK-016)

방송 그래픽의 전체 시각 테마를 편집하는 독립 창이다. 99개 이상의 설정 필드를 관리한다.

| ID | 기능 | 설명 | 우선순위 |
|----|------|------|:--------:|
| SK-001 | 스킨 로드 | .vpt/.skn 파일 열기 (AES 복호화) | P0 |
| SK-002 | 스킨 저장 | .vpt/.skn 파일 저장 (AES 암호화) | P0 |
| SK-003 | 새 스킨 생성 | 빈 템플릿에서 시작 | P0 |
| SK-004 | 스킨 미리보기 | 변경사항 실시간 프리뷰 | P0 |
| SK-005 | 테이블 배경 | 배경 이미지/색상 설정 | P0 |
| SK-006 | 카드 스킨 | 카드 앞/뒷면 이미지 설정 | P0 |
| SK-007 | 좌석 위치 편집 | 10개 좌석 X/Y 좌표 조정 | P0 |
| SK-008 | 폰트 설정 | 글꼴, 크기, 색상, 굵기 | P0 |
| SK-009 | 색상 테마 | 전체 색상 팔레트 설정 | P0 |
| SK-010 | 실행취소/다시실행 | Undo/Redo 스택 | P0 |
| SK-011 | 이미지 임포트 | PNG/JPG/SVG 이미지 삽입 | P0 |
| SK-012 | 애니메이션 속도 | 전환 애니메이션 시간 (ms) | P1 |
| SK-013 | 투명도 설정 | 요소별 알파 값 | P1 |
| SK-014 | 레이어 관리 | z-order 드래그 정렬 | P1 |
| SK-015 | 복사/붙여넣기 | 요소 복제 | P1 |
| SK-016 | 내보내기/가져오기 | 스킨 패키징 | P2 |

### 12.10 Graphic Editor - Board (GEB-001 ~ GEB-015)

테이블 중앙 영역(팟, 커뮤니티 카드, 타이틀)의 개별 그래픽 요소를 편집한다.

| ID | 기능 | 설명 | 우선순위 |
|----|------|------|:--------:|
| GEB-001 | 요소 트리뷰 | 보드 요소 계층 구조 표시 | P0 |
| GEB-002 | 드래그 이동 | 마우스로 요소 위치 이동 | P0 |
| GEB-003 | 크기 조절 | 핸들로 요소 크기 변경 | P0 |
| GEB-004 | 속성 패널 | 선택 요소의 상세 속성 편집 | P0 |
| GEB-005 | X/Y 좌표 입력 | 정확한 위치 수치 입력 | P0 |
| GEB-006 | 이미지 요소 | 이미지 파일 배치 (image_element) | P0 |
| GEB-007 | 텍스트 요소 | 텍스트 배치 (text_element) | P0 |
| GEB-008 | pip 요소 | 카드 문양 표시 | P0 |
| GEB-009 | 커뮤니티 카드 영역 | Flop 3장 + Turn + River 위치/크기 | P0 |
| GEB-010 | 메인팟 영역 | 메인팟 금액 텍스트 위치 | P0 |
| GEB-011 | 딜러 버튼 영역 | D 버튼 10개 좌석별 위치 | P0 |
| GEB-012 | z-order 변경 | 앞으로/뒤로 이동 | P0 |
| GEB-013 | 가시성 토글 | 요소 표시/숨김 | P0 |
| GEB-014 | 실행취소/다시실행 | Undo/Redo | P0 |
| GEB-015 | 캔버스 크기 | 편집 캔버스 해상도 | P0 |

### 12.11 Graphic Editor - Player (GEP-001 ~ GEP-015)

개별 플레이어 좌석의 그래픽 요소를 편집한다.

| ID | 기능 | 설명 | 우선순위 |
|----|------|------|:--------:|
| GEP-001 | 플레이어 이름 영역 | 이름 텍스트 위치/스타일 | P0 |
| GEP-002 | 칩 카운트 영역 | 칩 수량 텍스트 위치/스타일 | P0 |
| GEP-003 | 홀카드 영역 | 카드 2장 위치/크기 | P0 |
| GEP-004 | 홀카드 3-6장 | Omaha/Badugi/Draw용 다장 카드 레이아웃 | P0 |
| GEP-005 | 베팅 금액 영역 | 현재 라운드 베팅액 위치 | P0 |
| GEP-006 | 액션 표시 영역 | Fold/Call/Raise/Check 텍스트 위치 | P0 |
| GEP-007 | 승률 표시 영역 | 개별 승률 % 위치 | P0 |
| GEP-008 | 핸드 랭크 영역 | 현재 핸드 등급 텍스트 | P0 |
| GEP-009 | Fold 효과 | Fold 시 시각 처리 (회색, 투명도) | P0 |
| GEP-010 | 승자 하이라이트 | Showdown 승자 강조 효과 | P0 |
| GEP-011 | 배경 박스 | 플레이어 정보 배경 | P0 |
| GEP-012 | 카드 애니메이션 | 카드 등장 애니메이션 설정 | P1 |
| GEP-013 | 칩 애니메이션 | 칩 이동 애니메이션 | P1 |
| GEP-014 | Stud/Draw 전용 레이아웃 | 7장 Stud 카드 배치, Draw 교환 표시 | P1 |
| GEP-015 | Hi-Lo 분할 표시 | Hi-Lo 게임 승자 2인 표시 | P1 |

### 12.12 기능 수량 요약

| 화면 | P0 | P1 | P2 | 합계 |
|------|:--:|:--:|:--:|:----:|
| Main Window | 6 | 4 | 0 | 10 |
| Sources | 4 | 3 | 3 | 10 |
| Outputs | 6 | 2 | 4 | 12 |
| GFX1 | 15 | 7 | 2 | 24 |
| GFX2 | 1 | 8 | 4 | 13 |
| GFX3 | 2 | 7 | 4 | 13 |
| Commentary | 4 | 3 | 0 | 7 |
| System | 10 | 6 | 0 | 16 |
| Skin Editor | 11 | 4 | 1 | 16 |
| GE Board | 15 | 0 | 0 | 15 |
| GE Player | 11 | 4 | 0 | 15 |
| **합계** | **85** | **48** | **18** | **151** |

---

## 13. 스킨 및 테마 시스템

### 13.1 파일 포맷

| 확장자 | 용도 | 암호화 |
|--------|------|:------:|
| `.vpt` | 기본 스킨 포맷 | AES-256-GCM (필수) |
| `.skn` | 대안 스킨 포맷 | AES-256-GCM (필수) |
| `.pgfxconfig` | 설정 프리셋 파일 | AES-256-GCM (선택적) |

스킨 파일과 설정 프리셋은 동일한 ConfigurationPreset 데이터를 기반으로 하되, 스킨은 항상 AES 암호화가 적용되고 프리셋은 `UseEncryption` 플래그에 따라 선택적으로 적용된다.

### 13.2 스킨 구조

```
Skin File (.vpt / .skn)
+-- Header (SKIN_HDR)           <- 매직 바이트 (파일 식별)
+-- Metadata                    <- Preset 래퍼 (Name, Author, CreatedAtUtc)
+-- ConfigurationPreset         <- 99+ 필드 (레이아웃, 전환, 통계 등)
|   +-- 테이블 배경
|   +-- 좌석 위치 (10개)
|   +-- 카드 스킨
|   +-- 폰트 설정
|   +-- 색상 테마
|   +-- 애니메이션 설정
|   +-- 레이아웃 정보
+-- Board Elements              <- Graphic Editor Board 요소
+-- Player Elements             <- Graphic Editor Player 요소
+-- Embedded Assets             <- 이미지, 폰트 파일 (panel_logo, board_logo, strip_logo)
+-- CRC32                       <- skin_crc 무결성 검증
```

### 13.3 ConfigurationPreset (99+ 필드)

| 카테고리 | 필드 수 | 주요 설정 |
|----------|:-------:|----------|
| **테이블 레이아웃** | 15 | board_pos, gfx_vertical, gfx_bottom_up, gfx_fit, heads_up_layout_mode, x_margin, y_margin_top/bot |
| **좌석/플레이어 표시** | 20 | at_show(show_type), fold_hide(fold_hide_type), show_rank, show_seat_num, show_eliminated, order_players_type |
| **카드/핸드 표시** | 10 | card_reveal(card_reveal_type), rabbit_hunt, dead_cards, hilite_winning_hand_type, equity_show_type, outs_show_type |
| **폰트/색상** | 15 | 플레이어명, 스택, 블라인드 등 각 요소별 폰트 설정 |
| **애니메이션/전환** | 10 | trans_in(transition_type), trans_in_time, trans_out, trans_out_time, indent_action |
| **통계 자동 표시** | 15 | auto_stats, auto_stats_time, auto_stats_first_hand, VPIP/PFR/AGR/WTSD/CumWin 각 auto_stat_*/ticker_stat_* |
| **칩 표시 정밀도** | 8 | cp_leaderboard, cp_pl_stack, cp_pl_action, cp_blinds, cp_pot, cp_twitch, cp_ticker, cp_strip |
| **통화/금액** | 4 | currency_symbol, show_currency, trailing_currency_symbol, divide_amts_by_100 |
| **로고** | 3 | panel_logo(byte[]), board_logo(byte[]), strip_logo(byte[]) |
| **기타** | 7 | vanity_text, game_name_in_vanity, media_path, action_clock_count, nit_display, leaderboard_pos_enum, strip_display_type |

### 13.4 스킨 로딩/저장 흐름

```
스킨 파일 읽기 (로컬 또는 네트워크 청크 수신)
    |
    v
SKIN_HDR 매직 바이트 검증
    |
    v
AES-256-GCM 복호화
    |
    v
CRC32 무결성 검증 (skin_crc 비교)
    |
    v
서버 인증 (네트워크 가용 시)
    +-- permit -> 사용 허가
    +-- deny -> 사용 차단
    +-- no_network -> 기존 스킨 지속 사용
    |
    v
ConfigurationPreset 역직렬화
    |
    v
그래픽 요소에 설정 적용
```

저장 흐름은 역순이다: ConfigurationPreset 직렬화 -> CRC32 계산 -> AES-256-GCM 암호화 -> SKIN_HDR 추가 -> 파일 저장.

### 13.5 CRC32 무결성 검증

스킨 파일에 CRC32 체크섬이 내장되어 파일 무결성을 보장한다. 로드 시 계산된 CRC와 파일 내 저장된 `skin_crc` 값을 비교하여, 불일치 시 파일 손상으로 판단하고 로드를 거부한다.

**skin_auth_result:**

| 값 | 이름 | 설명 |
|:--:|------|------|
| 0 | no_network | 네트워크 불가 (기존 스킨 지속 사용 허용) |
| 1 | permit | 인증 성공 |
| 2 | deny | 인증 실패 (사용 차단) |

---

## 14. 외부 서비스 연동

### 14.1 ATEM 비디오 스위처 연동

Blackmagic ATEM 비디오 스위처를 원격 제어하여 카메라 전환과 트랜지션을 자동화한다.

**atem_state (6개 상태):**

| 값 | 이름 | 설명 |
|:--:|------|------|
| 0 | NotInstalled | ATEM SDK 미설치 |
| 1 | Disconnected | 연결 해제 |
| 2 | Connected | 연결됨 |
| 3 | Paused | 일시 중지 |
| 4 | Reconnect | 재연결 중 |
| 5 | Terminate | 종료 |

**event_type (3개 이벤트):**

| 값 | 이름 | 설명 |
|:--:|------|------|
| 0 | State | 상태 변경 |
| 1 | NameChange | 입력 이름 변경 |
| 2 | InputChange | 입력 소스 변경 |

자동 카메라 전환 시스템이 ATEM 입력 전환과 연동되어, 보드 카드 공개나 플레이어 액션에 따라 카메라가 자동 전환된다.

### 14.2 Twitch 라이브 연동

| 항목 | 사양 |
|------|------|
| 프로토콜 | EventSub (WebSocket) |
| 인증 | OAuth Token |
| 채팅 읽기 | EventSub 구독 |
| 채팅 쓰기 | Helix API |
| 오버레이 | GFX3 탭에서 채팅 표시 |

**지원 봇 명령:** `!event`, `!chipcount`, `!players`, `!blinds`, `!payouts`, `!cashwin`, `!delay`, `!vpip`, `!pfr`

시청자가 채팅에 명령을 입력하면 현재 게임 정보를 자동 응답한다.

### 14.3 NDI 네트워크 비디오 출력

NewTek NDI 프로토콜로 네트워크 기반 비디오 입출력을 지원한다.

| 항목 | 설명 |
|------|------|
| NDI 이름 | `NDI_PokerGFX` prefix |
| 입력 | NDI 소스 자동 감지 및 캡처 |
| 출력 | Live/Delayed Canvas를 NDI 스트림으로 전송 |
| 지연 | `NDI_WAIT_PERIOD_MS` 상수로 대기 시간 설정 |

### 14.4 StreamDeck 물리 버튼 연동

Elgato StreamDeck의 물리 버튼에 기능을 매핑한다.

**streamdeck_type:**

| 값 | 이름 | 설명 |
|:--:|------|------|
| 0 | off | 비활성화 |
| 1 | live | 라이브 모드 |
| 2 | delayed | 딜레이 모드 |

딜러가 물리 버튼으로 게임 시작/종료, 카드 표시 토글, 긴급 중지 등 빈번한 조작을 수행할 수 있다. StreamDeck 앱(`pgfx_streamdeck`)이 net_conn TCP 프로토콜로 GfxServer와 통신한다.

### 14.5 Master-Slave 다중 서버 구성

하나의 마스터 서버가 다수의 슬레이브 디스플레이를 관리하는 구조이다.

```
Master Server (원본 게임 상태 보유, RFID 직접 제어)
    |
    +--Delta sync--> Slave Server 1 (다른 카메라 앵글)
    +--Delta sync--> Slave Server 2 (해설자 전용)
    +--Delta sync--> Slave Server 3 (온라인 스트리밍)
```

**동기화 항목:**

| 항목 | 동기화 방식 |
|------|------------|
| 게임 상태 | Delta sync (변경분만 전송) |
| 플레이어 정보 | 변경 시 즉시 동기화 |
| 통계 데이터 | 핸드 완료 시 동기화 |
| 스킨 설정 | 블록 단위 청크 전송 (선택적) |
| ATEM 주소 | 마스터에서 슬레이브로 전파 |
| Twitch 채널 | 마스터에서 슬레이브로 전파 |

**상태 모니터링:** client_ping(슬레이브 -> 마스터)으로 CPU/GPU 사용률, 스트리밍 상태, RFID 연결 상태를 주기적으로 보고한다. server_ping(마스터 -> 슬레이브)으로 카드 인증 패키지, 라이브 데이터 내보내기 설정을 전파한다.

### 14.6 Analytics 데이터 수집

Store-and-Forward 패턴으로 텔레메트리를 수집한다.

```
이벤트 발생 (TrackFeature / TrackClick / TrackSession)
    |
    v
SQLite 큐에 저장 (WAL mode, 오프라인 내구성)
    |
    v
백그라운드 루프 (주기적 플러시)
    |
    v
API 서버 전송 (HTTPS POST)
    |
    v
스크린샷 캡처 (15분 간격, S3 업로드)
```

---

## 15. 보안 및 라이선스

### 15.1 인증 시스템

3계층 인증 구조를 제공한다.

```
Layer 1: Email/Password 로그인
    |
    v
Layer 2: JWT Access + Refresh Token
    |
    v
Layer 3: 자체 라이선스 서버 (기능 게이팅)
```

**LicenseType:**

| 값 | 타입 | 기본 게임 | 전체 22개 게임 | Master-Slave | 라이브 데이터 내보내기 | 스크린 캡처 |
|:--:|------|:---------:|:-------------:|:------------:|:--------------------:|:-----------:|
| 1 | Basic | O | - | - | - | - |
| 4 | Professional | O | O | - | O | - |
| 5 | Enterprise | O | O | O | O | O |

**인증 흐름:**

```
LoginCommand(Email, Password, CurrentVersion)
    -> LoginCommandValidator (입력 검증)
    -> LoginHandler
    -> AuthenticationService.RemoteLoginRequest(Email, Password)
    -> RemoteLoginResponse { Token, ExpiresIn, Email, UserType }
    -> LoginResult { IsSuccess, ErrorMessage }
```

**Offline Session:** 네트워크 정상 시 온라인 인증 후 로컬 캐시 갱신. 네트워크 장애 시 로컬 캐시 조회하여, 자격증명이 존재하고 미만료인 경우 로그인 성공을 허용한다.

| 상태 | 값 | 설명 |
|------|:--:|------|
| LoginSuccess | 0 | 로그인 성공 |
| LoginFailure | 1 | 로그인 실패 |
| CredentialsExpired | 2 | 자격증명 만료 |
| CredentialsFound | 3 | 캐시 자격증명 발견 |
| CredentialsNotFound | 4 | 캐시 자격증명 없음 |

### 15.2 통신 보안

| 구간 | 암호화 | 프로토콜 |
|------|--------|---------|
| 서버 <-> 클라이언트 | TLS 1.3 | .NET SslStream (gRPC 내장) |
| 서버 <-> RFID 리더 | TLS 1.3 | .NET SslStream |
| Master <-> Slave | TLS 1.3 | gRPC 내장 |
| UDP Discovery | 없음 | 서버 위치 정보만 (보안 불필요) |

### 15.3 스킨 파일 보안

| 보안 계층 | 설명 |
|----------|------|
| AES-256-GCM 암호화 | 스킨 파일 전체를 암호화하여 무단 수정 방지 |
| CRC32 무결성 검증 | 파일 손상/변조 감지 |
| 서버 인증 (skin_auth_result) | 네트워크 가용 시 라이선스 서버에서 스킨 사용 권한 확인 |

### 15.4 방송 보안

| 보안 기능 | 설명 |
|----------|------|
| **Trustless 모드** | Live Canvas에 홀카드를 절대 표시하지 않아 현장 유출 방지 |
| **Commentary 분리** | 해설자 모니터는 별도 네트워크 채널로 분리하여 방송 화면과 격리 |
| **지연 출력** | Delayed Canvas를 통해 N초 지연으로 실시간 정보 노출 차단 |
| **Logging** | 8개 LogTopic 기반 선택적 로깅으로 모든 액션 추적 |

---

## 16. 데이터 모델

### 16.1 GameTypeData Record (79개 필드)

게임의 전체 상태를 담는 핵심 데이터 구조이다. 79개 이상의 필드를 6개 논리 그룹으로 분해한다.

| Record | 필드 수 | 관리 영역 |
|--------|:-------:|----------|
| `GameSession` | ~15 | hand_number, game_type, blind_level |
| `TableState` | ~12 | pot_size, side_pots[], community_cards[] |
| `PlayerState` | ~10 (x10) | name, chip_count, hole_cards[], is_folded |
| `BettingState` | ~8 | current_bet, min_raise, betting_round |
| `DisplayState` | ~15 | show_holecards[], animation_flags |
| `TournamentState` | ~12 | blind_timer, payout_structure, bounties[] |

**GameSession 주요 필드:**

| 필드 | 타입 | 설명 |
|------|------|------|
| `_game_variant` | game (enum, 22값) | 게임 종류 |
| `bet_structure` | BetStructure (enum, 3값) | 베팅 구조 |
| `_ante_type` | AnteType (enum, 7값) | 앤티 유형 |
| `_gfxMode` | GfxMode (enum) | 그래픽 모드 (Live/Delay/Comm) |
| `hand_num` | int | 현재 핸드 번호 |
| `hand_in_progress` | bool | 핸드 진행 중 |
| `num_boards` | int | 보드 수 (Run It Twice) |

**TableState 주요 필드:**

| 필드 | 타입 | 설명 |
|------|------|------|
| `_small` / `_big` / `_third` | int | 스몰/빅/서드 블라인드 |
| `_ante` | int | 앤티 금액 |
| `cap` | int | 베팅 캡 |
| `bomb_pot` | int | 봄팟 금액 |
| `seven_deuce_amt` | int | 7-2 사이드벳 금액 |
| `smallest_chip` | int | 최소 칩 단위 |

**PlayerState 주요 필드 (좌석당):**

| 필드 | 타입 | 설명 |
|------|------|------|
| `action_on` | int | 현재 액션 플레이어 |
| `pl_dealer` / `pl_small` / `pl_big` | int | 딜러/SB/BB 위치 |
| `starting_players` | int | 시작 플레이어 수 |

### 16.2 Player Record

| 카테고리 | 필드 | 설명 |
|----------|------|------|
| **기본 정보** | Name, LongName, Country, HasPic | 플레이어 식별 |
| **칩/베팅** | Stack, Bet, DeadBet, NitGame | 재정 상태 |
| **상태** | HasCards, Folded, AllIn, SitOut | 게임 내 상태 |
| **통계 (VPIP)** | Vpip | 자발적 팟 참여율 |
| **통계 (PFR)** | Pfr | 프리플롭 레이즈 비율 |
| **통계 (AF)** | Agr | 공격성 지수 |
| **통계 (WTSD)** | Wtsd | 쇼다운 진행률 |
| **통계 (누적)** | CumWin | 누적 수익 |

### 16.3 Hand Record

| 필드 | 타입 | 설명 |
|------|------|------|
| hand_num | int | 핸드 번호 |
| game_type | game enum | 게임 종류 |
| players[] | PlayerState[] | 참여 플레이어 |
| community_cards | CardMask | 커뮤니티 카드 (bitmask) |
| pot_size | int | 팟 금액 |
| side_pots[] | int[] | 사이드팟 배열 |
| winners[] | int[] | 승자 좌석 번호 |
| hand_class | hand_class enum | 승리 핸드 등급 |
| run_it_times | int | Run It 횟수 |

### 16.4 GraphicElement Record

4가지 타입의 공통 필드와 타입별 고유 필드로 구성된다.

**공통 필드:**

| 필드 | 타입 | 설명 |
|------|------|------|
| x, y | float | 위치 |
| z_order | int | 렌더링 순서 |
| visible | bool | 표시 여부 |
| animation_state | AnimationState | 애니메이션 상태 |

**타입별 고유 필드 수:**

| 타입 | 고유 필드 수 | 주요 고유 필드 |
|------|:----------:|--------------|
| image_element | 41 | source_path, opacity, rotation, crop, effects chain |
| text_element | 52 | font_family, font_size, text_align, outline, shadow |
| pip_element | 12 | suit, rank, face_up, src_rect, dst_rect |
| border_element | 8 | color, thickness, corner_radius |

### 16.5 SkinConfiguration Record

스킨 파일의 메타데이터와 설정 데이터를 포함한다.

| 필드 | 타입 | 설명 |
|------|------|------|
| Name | string | 스킨 이름 |
| Description | string | 스킨 설명 |
| Author | string | 제작자 |
| CreatedAtUtc | DateTime | 생성 시각 |
| Content | ConfigurationPreset | 99+ 필드 설정 데이터 |
| skin_crc | uint | CRC32 무결성 검증값 |

---

## 17. 성능 요구사항

### 17.1 렌더링 성능

| 항목 | 목표 | 조건 |
|------|------|------|
| 프레임레이트 | 60fps 유지 | 10인 테이블 풀 그래픽 |
| GPU 메모리 | 512MB 이내 | Dual Canvas 동시 운영 |
| 렌더링 지연 | 16.7ms/frame | 60fps 기준 |
| GPU 인코딩 | 하드웨어 가속 | NVENC / AMF / QSV |

### 17.2 네트워크 지연

| 항목 | 목표 | 조건 |
|------|------|------|
| RTT | 100ms 이내 | LAN 환경 |
| Protobuf 직렬화 | 1ms 미만 | GameInfoResponse 75+ 필드 |
| Keepalive 간격 | 3초 (클라이언트) / 10초 (서버) | - |
| UDP Discovery | 1초 이내 응답 | LAN Broadcast |

### 17.3 RFID 인식

| 항목 | 목표 | 조건 |
|------|------|------|
| End-to-End | 200ms 이내 | 태그 감지 ~ 화면 표시 |
| 인식률 | 99% 이상 | 100회 연속 테스트 |
| 동시 리더 | 12대 | 좌석 10 + 보드 1 + Muck 1 |

### 17.4 핸드 평가

| 항목 | 목표 | 조건 |
|------|------|------|
| 단일 핸드 평가 | 1us (마이크로초) | Lookup table O(1) 조회 |
| Monte Carlo 10,000회 | 200ms 이내 | TPL + SIMD 가속 |
| Omaha6 조합 처리 | 메모리 맵 파일 | 20,358,520개 조합 |
| Lookup Table 메모리 | ~2.1MB | 538개 정적 배열 |

### 17.5 메모리

| 항목 | 목표 | 조건 |
|------|------|------|
| 총 메모리 | 4GB 이내 | 4시간 운영 후 |
| 메모리 누수 | 0 | 핸드 반복 테스트 |

### 17.6 디스크

| 항목 | 목표 |
|------|------|
| 설치 크기 | 500MB 이내 |
| 스킨 파일 | 개당 50MB 이내 |
| 로그 보관 | 최근 7일, 자동 로테이션 |

---

## 18. Enum 레퍼런스

시스템 전반에서 사용되는 핵심 enum의 정의와 정수 값이다.

### 18.1 게임 Enum

**game (22값):**

| 값 | 이름 | 계열 |
|:--:|------|:----:|
| 0 | holdem | flop |
| 1 | holdem_sixplus_straight_beats_trips | flop |
| 2 | holdem_sixplus_trips_beats_straight | flop |
| 3 | pineapple | flop |
| 4 | omaha | flop |
| 5 | omaha_hilo | flop |
| 6 | omaha5 | flop |
| 7 | omaha5_hilo | flop |
| 8 | omaha6 | flop |
| 9 | omaha6_hilo | flop |
| 10 | courchevel | flop |
| 11 | courchevel_hilo | flop |
| 12 | draw5 | draw |
| 13 | deuce7_draw | draw |
| 14 | deuce7_triple | draw |
| 15 | a5_triple | draw |
| 16 | badugi | draw |
| 17 | badeucy | draw |
| 18 | badacey | draw |
| 19 | stud7 | stud |
| 20 | stud7_hilo8 | stud |
| 21 | razz | stud |

**game_class (3값):** flop = 0, draw = 1, stud = 2

### 18.2 핸드 Enum

**hand_class (10값):**

| 값 | 이름 |
|:--:|------|
| 0 | high_card |
| 1 | one_pair |
| 2 | two_pair |
| 3 | three_of_a_kind |
| 4 | straight |
| 5 | flush |
| 6 | full_house |
| 7 | four_of_a_kind |
| 8 | straight_flush |
| 9 | royal_flush |

**card_type (53값):** card_back = 0, clubs_two = 1, clubs_three = 2, ... spades_ace = 52

### 18.3 상태 Enum

**AnimationState (16값):**

| 값 | 이름 | 값 | 이름 |
|:--:|------|:--:|------|
| 0 | FadeIn | 8 | Resetting |
| 1 | Glint | 9 | RotateBack |
| 2 | GlintGrow | 10 | Scale |
| 3 | GlintRotateFront | 11 | SlideAndDarken |
| 4 | GlintShrink | 12 | SlideDownRotateBack |
| 5 | PreStart | 13 | SlideUp |
| 6 | ResetRotateBack | 14 | Stop |
| 7 | ResetRotateFront | 15 | Waiting |

**reader_state (4값):** disconnected = 0, connected = 1, negotiating = 2, ok = 3

**wlan_state (5값):** off = 0, on = 1, connected_reset = 2, ip_acquired = 3, not_installed = 4

### 18.4 베팅 Enum

**BetStructure (3값):** NoLimit = 0, FixedLimit = 1, PotLimit = 2

**AnteType (7값):**

| 값 | 이름 | 설명 |
|:--:|------|------|
| 0 | std_ante | 표준 앤티 - 모든 플레이어 동일 금액 |
| 1 | button_ante | 버튼 앤티 - 딜러만 납부 |
| 2 | bb_ante | BB 앤티 - 빅블라인드 위치 납부 |
| 3 | bb_ante_bb1st | BB 앤티 (BB 먼저) |
| 4 | live_ante | 라이브 앤티 - 팟에 라이브 참여 |
| 5 | tb_ante | TB 앤티 - 서드 블라인드 위치 납부 |
| 6 | tb_ante_tb1st | TB 앤티 (TB 먼저) |

### 18.5 보안 Enum

**LicenseType (3값):** Basic = 1, Professional = 4, Enterprise = 5

**OfflineLoginStatus (5값):** LoginSuccess = 0, LoginFailure = 1, CredentialsExpired = 2, CredentialsFound = 3, CredentialsNotFound = 4

**skin_auth_result (3값):** no_network = 0, permit = 1, deny = 2

### 18.6 렌더링 및 레이아웃 Enum

**transition_type (4값):** fade = 0, slide = 1, pop = 2, expand = 3

**show_type (4값):** immediate = 0, action_on = 1, after_bet = 2, action_on_next = 3

**card_reveal_type (6값):** immediate = 0, after_action = 1, end_of_hand = 2, never = 3, showdown_cash = 4, showdown_tourney = 5

**fold_hide_type (2값):** immediate = 0, delayed = 1

**hilite_winning_hand_type (4값):** never = 0, immediate = 1, showdown_or_winner_all_in = 2, showdown = 3

**board_pos_type (3값):** left = 0, centre = 1, right = 2

**GfxMode (3값):** Live = 0, Delay = 1, Comm = 2

**GfxPanelType (20값):** None = 0, ChipCount = 1, VPiP = 2, PfR = 3, Blinds = 4, Agr = 5, WtSd = 6, Position = 7, CumulativeWin = 8, Payouts = 9, PlayerStat1~10 = 10~19

### 18.7 미디어/장치 Enum

**atem_state (6값):** NotInstalled = 0, Disconnected = 1, Connected = 2, Paused = 3, Reconnect = 4, Terminate = 5

**streamdeck_type (3값):** off = 0, live = 1, delayed = 2

**NetworkQuality (3값):** Good, Fair, Poor

**timeshift (2값):** Live, Delayed

**record (4값):** None, Live, Delayed, Both

**platform (2값):** DirectX, Software

**chipcount_precision_type (3값):** full = 0, smart = 1, smart_ext = 2

**chipcount_disp_type (3값):** amount = 0, bb_multiple = 1, both = 2

**equity_show_type (2값):** start_of_hand = 0, after_first_betting_round = 1

**outs_show_type (3값):** never = 0, heads_up = 1, heads_up_all_in = 2
