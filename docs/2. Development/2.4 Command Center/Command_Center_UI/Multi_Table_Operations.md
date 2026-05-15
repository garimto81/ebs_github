---
title: Multi Table Operations
owner: team4
tier: internal
legacy-id: BS-05-10
last-updated: 2026-04-15
confluence-page-id: 3834151023
confluence-parent-id: 3811901565
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3834151023/Operations
---

# BS-05-10 Multi-Table Operator Scenarios

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | 다중 테이블 운영 패턴 3가지 + 키보드 포커스 정책 (CCR-030, W7 해소) |
| 2026-05-07 | v4 cascade | CC_PRD v4.0 정체성 정합 — 각 CC 인스턴스가 **1×10 가로 그리드** PlayerGrid 를 사용. multi-table 모드에서 N 개의 1×10 그리드가 화면을 차지하므로 인지 부담이 v1.x 타원형 대비 변화 (가로 정렬 ↑, 공간 매핑 ↓). MiniDiagram (TopStrip 좌측) 이 multi-table 비교 시 핵심 보조 위젯. |

---

## 개요

EBS는 **"1 CC = 1 Table = 1 Overlay"** 인스턴스 관계를 유지한다. 그러나 **1명의 운영자는 여러 테이블을 동시에 관리**할 수 있으며, 이 경우 **다중 CC 인스턴스**가 독립 실행된다.

- **1:1:1** = CC : Table : Overlay (기술적 인스턴스)
- **1:N** = Operator : CC 인스턴스 (운영 관계)

> **참조**: `BS-05-00 §10 운영 패턴`, `BS-02-lobby §운영자 할당`.

---

## v4.0 컨텍스트 (2026-05-07 신설)

> **트리거**: `docs/1. Product/Command_Center.md` v4.0 — 1×10 가로 그리드 채택. multi-table 운영자가 화면을 분할할 때의 영향.

### 1×10 그리드 multi-table 적용

각 CC 인스턴스 (1 table) 는 화면 폭 720px+ 의 **1×10 가로 PlayerGrid** 를 차지. multi-table 모드 (1 운영자 : N CC) 에서 N 개의 그리드가 화면을 분할 또는 모니터 다중 사용.

```
┌─ Monitor A ─────────────────────────┐  ┌─ Monitor B ─────────────────────────┐
│ CC #1 (Table F1)                    │  │ CC #2 (Table F2)                    │
│ StatusBar (52px)                    │  │ StatusBar (52px)                    │
│ TopStrip (158px) — MiniDiagram 핵심│  │ TopStrip (158px) — MiniDiagram 핵심│
│ PlayerGrid 1×10                     │  │ PlayerGrid 1×10                     │
│ ActionPanel (124px) — 6 키          │  │ ActionPanel (124px) — 6 키          │
└─────────────────────────────────────┘  └─────────────────────────────────────┘
```

| 측면 | v1.x (oval) | v4.0 (1×10) |
|------|-------------|--------------|
| 화면 분할 효율 | 정사각형 oval로 폭 낭비 | **가로 길쭉, 모니터 가로 분할 친화** |
| 좌석 비교 | oval 외주 따라 시선 | **가로 정렬로 즉시 비교** |
| 공간 매핑 | 실 oval 과 1:1 | **MiniDiagram 의존 ↑** (V3) |
| ACTING 좌석 식별 | oval 위치 + glow | **가로 위치 + glow + ACTING 박스** (V6+V9) |

### 운영자 인지 부담

multi-table 모드에서 6 키는 *현재 포커스된 CC* 만 활성. 키 매핑은 모든 CC 동일 (N·F·C·B·A·M) — 운영자가 CC 간 전환해도 *같은 손가락 위치 = 같은 의미* 유지. 자세한 키보드 포커스 정책은 본 문서 하단 §"키보드 포커스 정책" 참조.

> **참조**: `Overview.md §3.0` (4 영역 위계), `Action_Buttons.md §"v4.0 6 키 매핑"`.

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
- **포커스 진입 시 애니메이션** — 노란 배너 `"Table 5 active"` 를 **500ms (FOCUS_BANNER_DURATION_MS)** 동안 표시 후 페이드 아웃.
- **핫키 FOCUS_MISMATCH_GUARD** — 아래 §3.3.1 명세.
- **설정 옵션** (BS-05-06): "Show table number overlay when focused" 토글.

#### 3.3.1 FOCUS_MISMATCH_GUARD 상세 명세

- **구현 위치**: Flutter 레벨. OS 레벨 훅 사용 안 함.
  - 최상위 `FocusScope` 의 `onFocusChange` 콜백 + `ShortcutManager` 가드 로직.
  - `AppLifecycleState.resumed` 리스너로 창 전환(Alt+Tab, OS 창 클릭) 감지.
- **발동 조건** (OR): 창 포커스 획득 직후 어느 하나라도 true 면 가드 시작.
  1. `AppLifecycleState` 가 `inactive`/`paused` → `resumed` 로 전이.
  2. `Window.onFocus` 가 true 로 재진입.
  3. Flutter `FocusScope` 가 `hasFocus: false → true` 전이 감지.
- **가드 동작**: 발동 시점부터 `FOCUS_MISMATCH_GUARD_MS = 200ms` 동안 `ShortcutManager.handleKeypress` 가 모든 액션 키(N/D/F/C/B/R/A, Ctrl+Z 포함)를 **no-op 으로 소비**. 시각 피드백 없음(가드 발동 자체는 운영자에게 보이지 않음 — 노란 배너가 상위 피드백).
- **해제 조건** (OR): 가장 먼저 발생하는 것:
  1. 가드 시작 이후 200ms 경과.
  2. 운영자가 **마우스 클릭** 으로 포커스를 의도적으로 확인 (마우스 이벤트는 가드 대상 아님).
- **적용 제외 키**: ESC, F-keys 는 가드 대상이 아님 (취소·도움말 등 파괴 위험 없는 키).
- **로그**: 가드 시간 동안 억제된 키는 `debugPrint('[FOCUS_GUARD] suppressed: $keyLabel')` 로 기록, Sentry 전송 안 함(정상 동작).

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
- `Keyboard_Shortcuts.md` (legacy-id: BS-05-06) — 단축키 상세
- `BS-01-auth §Permission Bit Flag` — Permission Bit Flag (CCR-017, BS-01-02-rbac 통합됨)
- `BS-02-lobby` — 운영자 할당 UI
