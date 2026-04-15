---
title: Overview
owner: team4
tier: internal
legacy-id: BS-04-00
last-updated: 2026-04-15
---

# BS-04-00 Overview — RFID 서브시스템 전체 흐름

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | RFID 전체 흐름, Real/Mock 모드, Feature/General Table, 이벤트 요약 |

---

## 개요

이 문서는 EBS RFID 서브시스템의 **전체 흐름과 모드 선택 기준**을 정의한다. RFID는 물리적 카드를 디지털 이벤트로 변환하는 계층이며, Mock 모드는 "하드웨어 없이 동일한 이벤트 스트림을 생성하는 일급 경로"다.

> **참조**: 용어·상태 정의는 `BS-00-definitions.md`, 트리거 경계는 `BS-06-00-triggers.md`, HAL 인터페이스 계약은 `API-03-rfid-hal-interface.md`

---

## 1. RFID 데이터 흐름

### 1.1 전체 파이프라인

```
물리적 카드 (RFID 태그 내장)
    │
    ▼
안테나 (좌석별 2개 + 보드 4개, 최대 24개/테이블)
    │
    ▼
RFID 리더 (ST25R3911B + ESP32, Serial UART)
    │
    ▼
HAL (IRfidReader 인터페이스)
    ├── Real HAL: 물리 하드웨어 통신
    └── Mock HAL: 소프트웨어 에뮬레이션
    │
    ▼
CC (Command Center) — 이벤트 수신 + UI 표시
    │
    ▼
Game Engine — 카드 정보로 게임 상태 전이
    │
    ▼
Overlay — 시청자 화면 카드 표시
```

### 1.2 계층별 책임

| 계층 | 책임 | 변경 대상 |
|------|------|----------|
| **안테나** | 물리적 RFID 신호 수신 | 하드웨어 (EBS 범위 외) |
| **RFID 리더** | 신호 → UID 변환, Serial 통신 | 펌웨어 (EBS 범위 외) |
| **HAL** | 하드웨어 추상화, 이벤트 스트림 생성 | `IRfidReader` 구현체 |
| **CC** | 이벤트 소비, 수동 입력, UI 표시 | CC Flutter 앱 |
| **Game Engine** | 카드 정보로 게임 규칙 처리 | 순수 Dart 패키지 |
| **Overlay** | 카드 그래픽 출력 | Flutter + Rive |

> **핵심 원칙**: HAL 위의 모든 계층(CC, Engine, Overlay)은 Real/Mock을 구분하지 않는다. 바뀌는 것은 HAL 구현체 1개뿐이다.

---

## 2. Real/Mock 모드 선택

### 2.1 모드 정의

| 모드 | HAL 구현체 | 카드 감지 방식 | 사용 시점 |
|------|-----------|-------------|----------|
| **Real** | `RealRfidReader` | 안테나가 물리적 카드 UID를 읽음 | 실제 방송 프로덕션 |
| **Mock** | `MockRfidReader` | CC에서 수동 카드 입력 → `CardDetected` 합성 | 개발, 테스트, 데모, POC |

### 2.2 Mock이 "primary dev mode"인 이유

Mock 모드는 fallback이 아니다. **Phase 1 POC에서 하드웨어 없이 전체 기능을 검증하기 위한 기본 개발 경로**다.

| 근거 | 설명 |
|------|------|
| **하드웨어 독립** | RFID 리더/안테나/카드가 없어도 CC, Engine, Overlay 전체 기능 개발 가능 |
| **결정적 테스트** | Mock HAL은 결정적 타이밍을 보장하여 E2E 테스트 재현성 확보 |
| **에러 시나리오** | `injectError()` API로 하드웨어 장애 시나리오를 손쉽게 재현 |
| **시나리오 재생** | YAML 시나리오 파일로 사전 정의된 핸드를 자동 재생 |
| **팀 병렬 개발** | 하드웨어 팀과 소프트웨어 팀이 독립적으로 병렬 개발 |
| **데모** | 고객/투자자 데모 시 물리 장비 없이 전체 시스템 시연 |

### 2.3 모드 전환

BO Config의 `rfid_mode` 설정으로 전환한다. Riverpod DI가 자동으로 구현체를 교체한다.

| 설정 | 값 | 효과 |
|------|:--:|------|
| `rfid_mode` | `"mock"` | `MockRfidReader` 인스턴스 생성 (기본값) |
| `rfid_mode` | `"real"` | `RealRfidReader` 인스턴스 생성 |

> **전환 시점**: 핸드 진행 중에는 모드 전환 불가. 핸드 종료(HAND_COMPLETE 또는 IDLE) 후 적용.

---

## 3. Feature Table vs General Table

### 3.1 정의

| 테이블 유형 | RFID 장비 | 카드 입력 방식 | 용도 |
|------------|:---------:|-------------|------|
| **Feature Table** | 있음 | RFID 자동 감지 (Real) 또는 수동 입력 (Mock) | 메인 방송 테이블, 홀카드 노출 필요 |
| **General Table** | 없음 | **항상 수동 입력** | 비방송 테이블, 베팅 액션만 기록 |

### 3.2 운영 흐름 차이

| 항목 | Feature Table (Real) | Feature Table (Mock) | General Table |
|------|---------------------|---------------------|---------------|
| 덱 등록 | 52장 실물 스캔 (3~5분) | "자동 등록" 1클릭 (즉시) | 불필요 |
| 홀카드 감지 | RFID 자동 | CC 수동 입력 | CC 수동 입력 |
| 보드 카드 감지 | RFID 자동 | CC 수동 입력 | CC 수동 입력 |
| 카드 제거 감지 | RFID 자동 (정보 전용) | 미지원 | 해당 없음 |
| Overlay 카드 표시 | 자동 표시 | 수동 입력 후 표시 | 수동 입력 후 표시 |
| Equity 계산 | 카드 감지 즉시 | 수동 입력 즉시 | 수동 입력 즉시 |

> **General Table은 RFID와 무관하게 항상 수동 입력이다.** RFID 장비가 없으므로 Mock/Real 모드 설정이 의미 없다.

---

## 4. RFID 이벤트 요약

> 참조: BS-06-00-triggers §2.2

| 이벤트 | 발동 조건 | payload 핵심 필드 | 설명 |
|--------|----------|------------------|------|
| `CardDetected` | 안테나 위에 카드 배치 | antennaId, cardUid, suit, rank, confidence | 카드 인식됨 |
| `CardRemoved` | 안테나에서 카드 제거 | antennaId, cardUid | 카드 제거됨 (정보 전용) |
| `DeckRegistered` | 52장 전수 스캔 완료 | deckId, cardMap[52] | 덱 등록 완료 |
| `DeckRegistrationProgress` | 스캔 진행 중 | scannedCount, totalCount | 등록 진행률 |
| `AntennaStatusChanged` | 안테나 연결/해제 | antennaId, status | 안테나 상태 변경 |
| `ReaderError` | 하드웨어 오류 | errorCode, message | RFID 오류 |

### 4.1 Mock 모드에서의 이벤트 합성

| Real 이벤트 | Mock 합성 방법 | 차이점 |
|------------|--------------|--------|
| `CardDetected` | CC 수동 카드 선택 → `injectCard()` | antennaId=0, uid="MOCK-XX", confidence=1.0 |
| `CardRemoved` | 미지원 (테스트 시 `injectRemoval()`) | — |
| `DeckRegistered` | "자동 등록" 버튼 → 52장 즉시 생성 | 스캔 시간 0ms |
| `DeckRegistrationProgress` | 1회 100% 이벤트 | Real은 1장씩 52회 |
| `AntennaStatusChanged` | 초기화 시 1회 `CONNECTED` | 안테나 1개만 가상 존재 |
| `ReaderError` | `injectError()` API | 테스트/데모용 |

---

## 5. 카드 데이터 모델

> 참조: BS-06-00-REF §2 Data Model

| 필드 | 타입 | 범위 | 설명 |
|------|------|------|------|
| `suit` | int | 0=Club, 1=Diamond, 2=Heart, 3=Spade | 수트 |
| `rank` | int | 0=Two ~ 12=Ace | 랭크 |
| `uid` | string | 16자 16진 문자열 또는 null | RFID 태그 UID |
| `display` | string | "2c", "As", "Kh" 등 | 표시 문자 |

**표시 형식**: 랭크('2'-'9', 'T', 'J', 'Q', 'K', 'A') + 수트('c', 'd', 'h', 's')

---

## 비활성 조건

- Table 상태가 EMPTY 또는 CLOSED일 때 RFID 이벤트 무시
- CC가 BO와 WebSocket 미연결 상태여도 RFID 로컬 처리는 계속 동작
- `MockRfidReader`가 `initialize()` 호출 전이면 이벤트 미발생

---

## 영향 받는 요소

| 영향 대상 | 이 문서와의 관계 |
|----------|----------------|
| `BS-04-01-deck-registration.md` | 덱 등록 프로세스 상세 |
| `BS-04-02-card-detection.md` | 게임 중 카드 감지 상세 |
| `BS-04-03-manual-fallback.md` | 수동 입력 — Mock 기본 경로 + Real 폴백 |
| `BS-04-04-hal-contract.md` | HAL 동작의 운영자 관점 기술 |
| `BS-06-00-triggers.md` | RFID 이벤트의 트리거 경계 정의 |
| `API-03-rfid-hal-interface.md` | HAL 인터페이스 계약 정본 |
