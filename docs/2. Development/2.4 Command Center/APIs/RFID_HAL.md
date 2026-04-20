---
title: RFID HAL — Operator Behavior
owner: team4
tier: internal
legacy-id: BS-04-04
references: API-03
last-updated: 2026-04-15
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "BS-04-04 RFID HAL Operator 동작 명세 완결"
---
# BS-04-04 HAL Contract — 운영자 관점 RFID HAL 동작 명세

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | HAL 초기화, 상태 표시, Real/Mock 전환, 에러 대응 가이드 |
| 2026-04-15 | 자매 문서 개명 반영 | 인터페이스 계약 문서가 `RFID_HAL_Legacy.md` → `RFID_HAL_Interface.md` (API-03) 로 변경됨. 본 문서의 모든 "API-03" 참조는 해당 파일로 연결 |

---

## 개요

이 문서는 `RFID_HAL_Interface.md` (API-03) 의 **운영자 관점 행동 명세**다. 운영자가 알아야 할 RFID HAL 동작(초기화, 상태 확인, 에러 대응, 모드 전환)을 기술한다. 인터페이스 계약의 기술 상세(`IRfidReader` 시그니처, 이벤트, 에러 코드)는 API-03 을 참조한다.

> **참조**: 인터페이스 계약 정본은 `RFID_HAL_Interface.md` (API-03), 모드 정의는 `BS-00-definitions.md §9`, 이벤트 합성은 `BS-06-00-triggers.md §4`

---

## 정의

| 용어 | 설명 |
|------|------|
| **HAL** | Hardware Abstraction Layer. RFID 하드웨어를 추상화하는 소프트웨어 계층 |
| **Real HAL** | 물리 RFID 리더(ST25R3911B + ESP32)와 Serial UART로 통신하는 구현체 |
| **Mock HAL** | 소프트웨어로 RFID 이벤트를 합성하는 구현체. 하드웨어 불필요 |
| **DI** | Dependency Injection. 런타임에 HAL 구현체를 교체하는 메커니즘 |

---

## 1. HAL 초기화

### 1.1 초기화 흐름

CC 앱 시작 시 HAL이 자동으로 초기화된다.

| 단계 | Real HAL | Mock HAL |
|:----:|----------|----------|
| 1 | Serial 포트 열기 | 가상 리더 생성 |
| 2 | 펌웨어 버전 확인 (1~3초) | 즉시 완료 |
| 3 | 안테나 스캔 (연결 확인) | 가상 안테나 1개 등록 |
| 4 | status → `ready` | status → `ready` |
| 5 | `AntennaStatusChanged(connected)` 발행 | `AntennaStatusChanged(connected)` 발행 |

### 1.2 초기화 실패

| 원인 | 시스템 반응 | 운영자 대응 |
|------|-----------|-----------|
| Serial 포트 없음 | `RfidInitializationException` → CC에 에러 표시 | 리더 USB 연결 확인 |
| 펌웨어 응답 없음 | 타임아웃 (5초) → 에러 표시 | 리더 전원 재시작 |
| 안테나 0개 감지 | 경고: "안테나 미감지" | 안테나 케이블 확인 |
| Mock 초기화 실패 | 발생 불가 (소프트웨어 전용) | — |

---

## 2. HAL 상태 UI 표시

### 2.1 상태 아이콘 (CC 상단 바)

CC 상단 바에 RFID HAL 상태를 아이콘으로 표시한다.

| 상태 | 아이콘 | 색상 | 의미 |
|------|:------:|:----:|------|
| **Connected** | 안테나 아이콘 | 녹색 | Real HAL 정상 연결, 카드 감지 가능 |
| **Mock** | 안테나 아이콘 + "M" 뱃지 | 파란색 | Mock HAL 활성, 수동 입력 모드 |
| **Disconnected** | 안테나 아이콘 + X | 회색 | HAL 미초기화 또는 연결 해제 |
| **Error** | 안테나 아이콘 + ! | 빨간색 | 하드웨어 오류 발생 |
| **Scanning** | 안테나 아이콘 + 회전 | 노란색 | 덱 등록 스캔 진행 중 |

### 2.2 상세 상태 패널

상태 아이콘 클릭 시 상세 패널이 열린다.

| 표시 항목 | 설명 | 예시 |
|----------|------|------|
| **모드** | Real 또는 Mock | "Mode: Mock" |
| **리더 상태** | ready/error/disconnected | "Status: Ready" |
| **안테나 수** | 연결된 안테나 개수 | "Antennas: 24/24 connected" |
| **장애 안테나** | 오류 상태 안테나 목록 | "Antenna 5: disconnected" |
| **덱 상태** | DeckFSM 현재 상태 | "Deck: REGISTERED (52/52)" |
| **마지막 이벤트** | 가장 최근 RFID 이벤트 | "Last: CardDetected As (2s ago)" |

### 2.3 Lobby 모니터링

Lobby에서 각 테이블의 RFID 상태를 한눈에 확인한다.

| 표시 | 의미 |
|------|------|
| 녹색 점 + "RFID" | Real 모드, 정상 |
| 파란색 점 + "MOCK" | Mock 모드 |
| 빨간색 점 + "RFID !" | Real 모드, 에러 |
| 회색 점 + "—" | RFID 미설정 (General Table) |

---

## 3. Real/Mock 전환 절차

### 3.1 전환 위치

Settings(Lobby 하위 다이얼로그) → System → RFID → Mode 선택

### 3.2 전환 단계

| 단계 | 동작 | 비고 |
|:----:|------|------|
| 1 | Settings에서 RFID Mode 변경 (Real ↔ Mock) | Admin 권한 필요 |
| 2 | BO Config에 `rfid_mode` 저장 | `ConfigChanged` 이벤트 발행 |
| 3 | CC가 `ConfigChanged` 수신 | — |
| 4 | **현재 핸드 종료 대기** | 핸드 중간 전환 불가 |
| 5 | HAL 구현체 교체 (Riverpod DI) | 이전 HAL dispose → 새 HAL initialize |
| 6 | 새 HAL 초기화 완료 | status → `ready` |
| 7 | 덱 상태 리셋 | DeckFSM → UNREGISTERED (재등록 필요) |

### 3.3 전환 시 주의사항

| 주의 | 설명 |
|------|------|
| **핸드 중간 전환 불가** | HandFSM ≠ IDLE/HAND_COMPLETE이면 전환 지연 |
| **덱 재등록 필요** | 모드 전환 시 기존 덱 매핑 폐기, 재등록 필요 |
| **Admin 전용** | Operator 권한으로는 모드 전환 불가 |
| **CC 재시작 불필요** | DI가 런타임에 구현체를 교체하므로 앱 재시작 없음 |

---

## 4. 에러 발생 시 운영자 대응 가이드

### 4.1 에러 분류별 대응

| 에러 코드 | 분류 | 증상 | 운영자 대응 |
|----------|------|------|-----------|
| 100 `connectionLost` | 연결 | 리더 연결 끊김, 상태 아이콘 빨간색 | USB 케이블 확인, 리더 재연결. 자동 재연결 3회 시도 |
| 101 `connectionTimeout` | 연결 | 리더 응답 없음 | 리더 전원 OFF → ON. 5초 대기 후 자동 재연결 |
| 102 `serialPortError` | 연결 | Serial 포트 오류 | CC 앱 재시작, 필요 시 OS 포트 재인식 |
| 200 `antennaDisconnected` | 안테나 | 특정 안테나 연결 해제 | 해당 안테나 케이블 확인. 해당 좌석만 수동 입력 전환 |
| 201 `antennaOverload` | 안테나 | 다수 태그 동시 감지 | 카드 정리 (겹친 카드 분리) |
| 300 `duplicateCard` | 카드 | 같은 카드 중복 감지 | 조치 불필요 (시스템이 자동 무시) |
| 301 `unknownCard` | 카드 | 미등록 카드 감지 | 등록된 덱의 카드인지 확인. 필요 시 덱 재등록 |
| 302 `readError` | 카드 | 카드 읽기 실패 | 카드 재배치 또는 수동 입력으로 전환 |
| 303 `cardConflict` | 카드 | RFID와 수동 입력 불일치 | RFID 결과 확인 후 수동 입력 수정 |
| 400 `deckRegistrationFailed` | 덱 | 덱 등록 실패 | 덱 등록 재시도 |
| 401 `deckIncomplete` | 덱 | 52장 미만 등록 | 누락 카드 추가 스캔 또는 카드 교체 |
| 500 `firmwareError` | 시스템 | 펌웨어 오류 | 리더 전원 OFF → ON. 지속 시 하드웨어 교체 |

### 4.2 에러 심각도 레벨

| 레벨 | 대응 | 게임 영향 | 예시 |
|------|------|----------|------|
| **Info** | 자동 처리, 로그만 | 없음 | duplicateCard, CardRemoved |
| **Warning** | 운영자 확인 권장 | 없음 (계속 진행 가능) | readError, antennaDisconnected (1개) |
| **Error** | 운영자 즉시 대응 필요 | 수동 모드 전환 필요 | connectionLost, 다수 안테나 장애 |
| **Critical** | 게임 중단 가능 | 게임 일시 중지 권장 | firmwareError, 전체 안테나 장애 |

### 4.3 자동 복구 메커니즘

| 에러 | 자동 복구 | 재시도 횟수 | 간격 |
|------|---------|:---------:|:----:|
| `connectionLost` | 자동 재연결 시도 | 3회 | 2초 |
| `connectionTimeout` | 자동 재연결 시도 | 3회 | 5초 |
| `antennaDisconnected` | 자동 재감지 | 무제한 (백그라운드) | 10초 |
| `readError` | 자동 재시도 | 2회 | 즉시 |

자동 복구 실패 시 운영자에게 수동 대응을 요청하는 경고 배너를 표시한다.

---

## 5. 운영 시나리오별 HAL 동작 요약

| 시나리오 | HAL 모드 | 초기화 | 덱 등록 | 카드 감지 | 에러 대응 |
|---------|---------|--------|---------|---------|---------|
| **프로덕션 방송** | Real | Serial 포트 연결 | 52장 실물 스캔 | RFID 자동 | 수동 폴백 |
| **개발/테스트** | Mock | 즉시 완료 | 자동 등록 1클릭 | CC 수동 입력 | 에러 주입 API |
| **고객 데모** | Mock | 즉시 완료 | 자동 등록 1클릭 | CC 수동 입력 | 에러 없음 |
| **E2E 테스트** | Mock | 즉시 완료 | 자동 등록 | YAML 시나리오 재생 | 시나리오 내 에러 주입 |
| **일부 RFID 장애** | Real (혼합) | 정상 | 기존 등록 유지 | RFID + 수동 혼합 | 장애 안테나만 수동 |

---

## 비활성 조건

- CC 앱 미시작 상태에서 HAL 초기화 불가
- Table 상태 EMPTY에서 RFID 이벤트 무시 (HAL은 초기화되어 있으나 이벤트 무처리)
- Viewer 권한으로 RFID 모드 전환 불가 (Settings 접근 차단)

---

## 영향 받는 요소

| 영향 대상 | 이 문서와의 관계 |
|----------|----------------|
| `API-03-rfid-hal-interface.md` | HAL 인터페이스 계약 정본 (기술 상세) |
| `BS-04-00-overview.md` | RFID 전체 흐름에서 HAL의 위치 |
| `BS-04-01-deck-registration.md` | HAL registerDeck() 동작 |
| `BS-04-02-card-detection.md` | HAL CardDetected 이벤트 발행 |
| `BS-04-03-manual-fallback.md` | Mock HAL injectCard() 동작 |
| `BS-03-settings/` | Settings에서 RFID 모드 전환 UI |
