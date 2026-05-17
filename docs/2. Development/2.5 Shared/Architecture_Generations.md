---
title: Architecture Generations Reference — PokerGFX vs EBS
owner: conductor
tier: internal
last-updated: 2026-05-17
version: 1.0.0
mirror: none
confluence-sync: none
derivative-of: ../../1. Product/Foundation.md (Ch.4 Scene 4 Gen 3 target)
related-docs:
  - ../../1. Product/Foundation.md (§Ch.4 Scene 3 7-Layer + Scene 4 Gen)
  - ../../1. Product/Command_Center.md (Ch.6 + Ch.9 Orchestrator)
  - ./Security_Posture.md (보안 모델 동시 cascade)
pokergfx-source: C:/claude/ebs-archive-backup/07-archive/legacy-repos/ebs_reverse/docs/02-design/pokergfx-reverse-engineering-complete.md (line 442-448, line 539-641)
---

# Architecture Generations Reference

> **본 문서의 위치**: PokerGFX 역공학 분석에서 발견된 **3-Generation 아키텍처 진화** 패턴을 EBS spec 에 매핑. Foundation §C.3 "1 단계 EBS = PokerGFX 패러다임의 자체 구현" 의 architecture 차원 명시.
>
> **mirror: none** — Confluence 업로드 제외 (역공학 자료 = 경쟁사 분석 영역).

---

## 1. PokerGFX 3-Generation Evolution

PokerGFX Server v3.2.985.0 의 역공학 분석 (88% 커버리지) 에서 발견된 architecture 진화 패턴.

### 1.1 Generation 매트릭스

| Generation | 특징 | 코드 규모 | 위치 |
|:----------:|------|----------|------|
| **Gen 1** God Class | `main_form` 329 methods + 398 fields, 거의 모든 비즈니스 로직 집중 | 단일 클래스 | WinForms Form |
| **Gen 2** Service Interface | GameTypes 디렉토리 26 파일, 10 interfaces + 11 implementations | 26 파일 | `GameTypes/` |
| **Gen 3** DDD/CQRS | Features 디렉토리 58 파일, FluentValidation + MediatR | 58 파일 | `Features/` |

### 1.2 Gen 2 — Service Interface 10 종

```csharp
IGameConfigurationService   // 게임 설정 관리
IGameVideoService           // 비디오 녹화/처리
IGamePlayersService         // 플레이어 CRUD
IGameCardsService           // 카드 딜/관리
IGameGfxService             // 그래픽 렌더링 제어
IGameSlaveService           // 슬레이브 동기화
IGameVideoLiveService       // 라이브 스트리밍
ITagsService                // RFID 태그 관리
IHandEvaluationService      // 핸드 강도 평가
ITimersService              // 타이머 관리
```

### 1.3 Gen 3 — Login CQRS Pipeline (예시)

```
LoginCommand (Email + Password + CurrentVersion)
       |
       v
LoginCommandValidator (FluentValidation)
       | <-- 검증 실패 시 ValidationResult 반환
       v
LoginHandler
       | <-- 의존성: IValidator, IOfflineSessionService, IAuthenticationService
       v
LoginResult (IsSuccess + ErrorMessage + ValidationResult + VersioningResult)
```

### 1.4 공존 증거 (Gen 1 + Gen 3 hybrid)

PokerGFX 정본 line 448 인용:
> "GameType.cs 가 ILicenseService(Phase 3)를 필드로 참조하고, Program.cs 가 IServiceProvider(Microsoft DI)와 Bugsnag.Client를 보유한다.
>  WinForms 앱에 엔터프라이즈 .NET Core 패턴이 적용된 하이브리드 구조이다."

→ PokerGFX = Gen 1/3 hybrid 공존. 점진적 마이그레이션 진행 중.

---

## 2. EBS Target = Gen 3 (DDD/CQRS)

### 2.1 EBS 의 implicit Gen 3 채택

Foundation §B.3 통신 매트릭스 (line 711-737) 의 표현:

> "CC = Orchestrator, 병행 dispatch.
>  Engine 응답이 게임 상태 SSOT, BO ack 은 audit 참고값."

→ **Orchestrator pattern = Gen 3 (DDD/CQRS) 의 핵심 패턴**. EBS 가 PRD 차원에서 implicit 채택.

### 2.2 Gen 3 채택 결정 기준

| 항목 | Gen 1 | Gen 2 | Gen 3 ★ EBS target |
|------|:----:|:----:|:--:|
| Testability | ❌ (God Class 분리 어려움) | △ (interface mock 가능) | ✅ (CQRS handler 격리) |
| 확장성 | ❌ | △ | ✅ |
| 외부 인계 | ❌ (학습 곡선 높음) | △ | ✅ (Feature 단위 모듈) |
| 마이그레이션 비용 | N/A (기존) | 중 | 높음 (but 일회성) |
| 운영 안정성 | △ | ✅ | ✅ |
| EBS 적합도 | ❌ | △ | **✅** |

### 2.3 EBS 컴포넌트별 Gen 매핑

| EBS 컴포넌트 | Gen | 이유 |
|------------|:--:|------|
| **Lobby** (Flutter Web + Rive) | Gen 3 | Riverpod provider + CQRS handler 가능 |
| **Command Center** (Flutter Desktop) | Gen 3 | Orchestrator pattern (Foundation §B.3) |
| **Game Engine** (Pure Dart) | Gen 3 | Stateless services + FSM (Ch.6) |
| **Backend (BO)** (FastAPI + DB) | Gen 3 | FastAPI = native DDD/CQRS 친화 |
| **Overlay View** (Rive + SDI/NDI) | Gen 3 | Renderer = pure function pattern |

---

## 3. 마이그레이션 가이드

### 3.1 Phase 마이그레이션 권고

```
   Phase 1: Service Interface 추출 (Gen 1 → Gen 2)
            ├─ 큰 클래스를 10 services 로 분해
            └─ 인터페이스 + 구현 분리
              ↓
   Phase 2: Command/Query 분리 (Gen 2 → Gen 3)
            ├─ Command = 상태 변경
            ├─ Query = 읽기 전용
            └─ Validator + Handler 도입
              ↓
   Phase 3: Feature 디렉토리 재구성
            ├─ Features/{FeatureName}/
            │   ├─ Models/ (Command, Result)
            │   ├─ Validators/
            │   ├─ Handlers/
            │   └─ Tests/
            └─ Common/ (Authentication, Licensing 등)
```

### 3.2 EBS 의 시작점 (현재 상태)

| 컴포넌트 | 현재 Gen | 마이그레이션 우선순위 |
|---------|:--:|:--:|
| Lobby (team1) | Gen 2 + 일부 Gen 3 | 중 |
| CC (team4) | Gen 2 | **높음** (Orchestrator 명시화) |
| Engine (team3) | Gen 3 (Pure Dart, stateless 가능) | 낮음 (이미 Gen 3) |
| BO (team2) | Gen 3 (FastAPI) | 낮음 (이미 Gen 3) |
| Overlay (team4) | Gen 3 | 낮음 |

### 3.3 Anti-Pattern 회피

EBS 가 의도적으로 회피하는 PokerGFX Gen 1 anti-pattern:

| Anti-Pattern | PokerGFX 사례 | EBS 회피 방법 |
|-------------|--------------|---------------|
| God Class | `main_form` 329 methods | 컴포넌트 분리 (Lobby/CC/Engine/BO/Overlay) |
| Tight Coupling | UI ↔ Business Logic | Riverpod provider + FastAPI router 분리 |
| Hidden Dependencies | 정적 클래스 ↔ Service 혼재 | DI 컨테이너 + freezed entity |
| Missing Validation | 직접 입력값 사용 | FluentValidation 또는 Pydantic |

---

## 4. 본 프로젝트 인텐트 부합

### 4.1 인텐트 ↔ Gen 3 채택

본 프로젝트 인텐트 (MEMORY.md): "개발 문서 + 프로토타입 100% 일관성 보장 프로젝트"

- **100% 일관성** = PRD 의 spec 이 코드와 1:1 매핑 가능해야 함
- Gen 3 (Feature-based) = PRD 의 spec 1 항목 ↔ Feature 디렉토리 1 개 직접 매핑 가능
- Gen 1 (God Class) = spec 흩어짐 → 100% 일관성 불가능

→ **Gen 3 채택 = 본 프로젝트 인텐트의 architecture 차원 자연 결과**.

### 4.2 외부 인계 시

- PokerGFX 의 Gen 1 = 외부 인계 시 학습 곡선 매우 높음 (329 methods + 398 fields)
- EBS Gen 3 = 외부 디자이너/개발자가 Feature 단위로 학습
- RIVE_Standards Ch.5 "다섯 작가" = Gen 3 의 자연 표현 (각 작가 = 1 Feature)

---

## 5. PokerGFX 정본 인용 위치

`C:/claude/ebs-archive-backup/07-archive/legacy-repos/ebs_reverse/docs/02-design/pokergfx-reverse-engineering-complete.md`:

| line | 내용 |
|------|------|
| 60 | "3세대 아키텍처 진화: God Class → Service Interface → DDD/CQRS" |
| 442-448 | 3 generation 공존 증거 |
| 539-573 | Gen 2 Service Interface 10 종 상세 |
| 575-641 | Gen 3 Features/CQRS Login pipeline 예시 |

---

## 6. 변경 이력

| 날짜 | 버전 | 변경 |
|------|------|------|
| 2026-05-17 | 1.0.0 | 본 doc 신규 작성 (Foundation v5.0 Ch.4 Scene 4 cascade) |
