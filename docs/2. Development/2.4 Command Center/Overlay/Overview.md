---
title: Overview
owner: team4
tier: internal
legacy-id: BS-07-00
last-updated: 2026-04-15
---

# BS-07-00 Overview — Overlay 시스템 개요

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | Overlay 앱 정의, 데이터 흐름, Layer 구조, 출력 채널 |
| 2026-04-14 | 프로세스 모델 정합 | §1 "별도 프로세스" → "동일 Flutter 앱 in-process" 수정 (API-04 §1.2 SSOT 정렬) |
| 2026-04-14 | 요소 카운트 정합 | §3 보조 요소 3→2 (Lower Third는 Admin 수동 요소로 분류). Layer 1 8 + 보조 2 = 10종으로 BS-07-01 총괄표와 통일 |

---

## 개요

Overlay는 **시청자가 보는 방송 화면의 그래픽 출력 앱**이다. RFID로 읽은 카드 정보, 운영자가 입력한 액션, Game Engine이 계산한 승률을 실시간으로 시각화하여 방송 화면 위에 겹쳐 표시한다.

> **참조**: 용어·상태 정의는 `BS-00-definitions.md`, Enum 값 상세는 `BS-06-00-REF-game-engine-spec.md`

---

## 1. 앱 정의

| 항목 | 내용 |
|------|------|
| **앱 이름** | Overlay |
| **기술 스택** | Flutter + Rive |
| **역할** | 시청자 방송 화면 그래픽 출력 |
| **인스턴스 관계** | CC 1개 = Table 1개 = **Overlay 1개** |
| **실행 환경** | CC와 동일 머신 또는 별도 머신 (NDI 네트워크 출력 시) |

> 참조: BS-00 §1 앱 아키텍처 용어

Overlay는 CC(Command Center)와 **동일한 Flutter 앱 내에서 in-process로 실행**된다 (API-04 §1.2 SSOT). CC가 운영자 입력 화면이라면, Overlay는 시청자 출력 화면으로, 같은 프로세스에서 별도 윈도우/뷰로 렌더링되어 네트워크 오버헤드 없이 Dart 함수 호출로 GameState를 공유한다.

---

## 2. 데이터 흐름

```
[RFID]  ─── CardDetected ──┐
                            ▼
[CC]  ── ActionPerformed ─→ [Game Engine] ─→ [Overlay]
                            ▲
[BO]  ── ConfigChanged ─────┘
```

### 흐름 상세

| 단계 | 발신 | 수신 | 데이터 | 설명 |
|:----:|------|------|--------|------|
| 1 | RFID / CC | Game Engine | CardDetected, Action | 카드 감지 또는 운영자 액션 입력 |
| 2 | Game Engine | Overlay | 게임 상태 스냅샷 | 핸드 FSM 상태, 플레이어 상태, 카드, 팟 등 |
| 3 | Game Engine | Overlay | EquityUpdated | 카드 변경 시 승률 재계산 결과 |
| 4 | BO | Overlay | ConfigChanged | 스킨, 출력 설정 등 Admin 변경 |

Game Engine은 이벤트가 발생할 때마다 **전체 게임 상태 스냅샷**을 Overlay에 전달한다. Overlay는 이 스냅샷을 받아 현재 화면을 갱신한다.

> **핵심 원칙**: Overlay는 자체 로직을 갖지 않는다. Game Engine이 계산한 결과를 **렌더링만** 한다.

---

## 3. EBS Layer 1 — Overlay 그래픽 8종

> 참조: Foundation PRD Ch.6 Layer 1

RFID가 카드를 읽거나, 운영자가 CC에서 액션을 입력하는 순간 **자동으로 즉시 생성**되는 그래픽이다.

| # | 그래픽 | 트리거 | 생성 방식 |
|:-:|--------|--------|----------|
| 1 | **홀카드 표시** (HoleCards) | RFID CardDetected | 자동 |
| 2 | **커뮤니티 카드** (Board) | RFID CardDetected (보드) | 자동 |
| 3 | **액션 배지** (Action Badge) | CC ActionPerformed | 반자동 |
| 4 | **팟 카운터** (Pot Display) | Engine 베팅 누적 계산 | 자동 |
| 5 | **승률 바** (Equity Bar) | Engine EquityUpdated | 자동 |
| 6 | **플레이어 정보** (Name, Stack, Photo) | BO PlayerUpdated / WSOP LIVE API | 자동 |
| 7 | **Outs** (남은 유리한 카드 수) | Engine 카드 데이터 계산 | 자동 |
| 8 | **플레이어 포지션** (Position) | CC SeatAssign / Engine StartHand | 반자동 |

### 추가 표시 요소

Layer 1 그래픽 8종 외에 Overlay가 **자동 트리거로 표시**하는 보조 요소 2종:

| 요소 | 트리거 | 설명 |
|------|--------|------|
| **핸드 랭킹** (Hand Rank Label) | Engine EquityUpdated | 보드 변경 시 현재 핸드 등급 표시 |
| **딜러 버튼** (Dealer Button) | Engine StartHand | 핸드 시작 시 딜러 위치 표시 |

> **요소 카운트**: Layer 1 8종 + 자동 보조 2종 = **총 10종 자동 트리거 요소** (BS-07-01 총괄표와 일치). **하단 자막(Lower Third)**은 Admin 수동 입력 요소로 Layer 1 자동 트리거 범주에서 제외하며, Overlay 렌더는 하지만 분류상 §5 출력 채널의 텍스트 요소로 다룬다.

---

## 4. Layer 경계 — EBS 범위 정의

| Layer | 생성 주체 | 생성 시점 | EBS 역할 |
|:-----:|----------|----------|----------|
| **Layer 1** | EBS (자동) | 실시간 (경기 중) | **직접 생성** |
| **Layer 2** | 프로덕션 팀 (수동) | 후편집 (경기 후 1~2시간) | 데이터 API 제공만 |
| **Layer 3** | 디자인 팀 (사전 제작) | 방송 전 | 관여 없음 |

Layer 2에는 VPIP indicator, Chip Flow chart, Tournament Leaderboard 등 12종이 포함된다. Layer 3에는 이벤트 배지, 스폰서 로고, 방송 프레임 등이 포함된다.

> **핵심**: Layer 1은 카드가 놓이는 **그 순간** 현장에서 자동 생성된다. Layer 2는 그 핸드가 끝난 후 서울에서 수동 삽입된다. **이 문서(BS-07)는 Layer 1만 다룬다.**

> **상세 (CCR-035)**: Layer 1 8종의 자동화 정도(완전 자동 vs 반자동), Layer 2 데이터 제공 API, 신규 요구사항 Layer 분류 기준은 `BS-07-06-layer-boundary.md` 참조.

---

## 5. 출력 채널

Overlay가 렌더링한 그래픽을 외부로 내보내는 3가지 채널:

| 채널 | 프로토콜 | 용도 | 지연 |
|------|---------|------|------|
| **NDI** | NewTek NDI | 네트워크 기반 비디오 전송. vMix/OBS에 소스로 입력 | <1 frame |
| **HDMI** | HDMI 2.0+ | 물리 모니터 또는 캡처 카드 직접 출력 | <1 frame |
| **크로마키** | NDI/HDMI + 단색 배경 | 배경 투명 처리용. 프로덕션 합성기에서 키잉 | <1 frame |

### 출력 설정

| 설정 | 값 | 설명 |
|------|-----|------|
| 해상도 | 1920×1080 (기본), 3840×2160 (4K) | Settings에서 변경 |
| Security Delay | 0~120초 | 홀카드 공개 지연 (방송 보안) |
| 크로마키 색상 | Green(기본), Blue, Black, Custom | 배경색 선택 |

> **참조**: 출력 설정 상세는 `BS-03-settings/` 참조. Feature Catalog OUT-001~012.

---

## 6. Overlay 생명주기

| 단계 | 조건 | Overlay 상태 |
|------|------|-------------|
| **대기** | CC 미실행 또는 Table EMPTY/SETUP | 빈 화면 (스킨 배경만 표시) |
| **활성** | Table LIVE, 핸드 진행 중 | 게임 데이터 실시간 렌더링 |
| **일시정지** | Table PAUSED | 마지막 상태 유지 (정적 화면) |
| **종료** | Table CLOSED 또는 CC 종료 | 빈 화면 → 프로세스 종료 |

---

## 영향 받는 문서

| 문서 | 관계 |
|------|------|
| `BS-07-01-elements.md` | 오버레이 요소 상세 |
| `BS-07-02-animations.md` | Rive 애니메이션 상세 |
| `BS-07-03-skin-loading.md` | 스킨 로드/전환 프로세스 |
| `BS-07-04-scene-schema.md` | 씬 JSON 스키마 |
| `BS-06-00-triggers.md` | 트리거 이벤트 정의 |
| `BS-06-00-REF-game-engine-spec.md` | Enum 값, DisplayConfig |
| `BS-03-settings/` | 출력·오버레이 설정 UI |
