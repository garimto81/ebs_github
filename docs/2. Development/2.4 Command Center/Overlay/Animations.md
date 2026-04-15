---
title: Animations
owner: team4
tier: internal
legacy-id: BS-07-02
last-updated: 2026-04-15
---

# BS-07-02 Animations — Rive 애니메이션 상세

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | Rive 애니메이션 발동 조건, 핸드 단계별 시퀀스, 속도 설정 |

---

## 개요

이 문서는 Overlay의 **Rive 애니메이션 발동 조건과 시퀀스**를 정의한다. 각 오버레이 요소가 언제, 어떤 애니메이션으로 등장/퇴장/강조되는지 모든 경우의 수를 기술한다.

> **참조**: AnimationState 16개, transition_type 4종 Enum 값은 `BS-06-00-REF-game-engine-spec.md §1.6`에 정의. 이 문서는 해당 Enum이 **언제, 왜 발동하는가**를 기술한다.

---

## 1. 핵심 AnimationState 매핑

> 참조: BS-06-00-REF §1.6.1 AnimationState (16개)

### 카드 등장/퇴장

| AnimationState | 값 | 대상 | 발동 조건 | 시각 효과 |
|:-------------:|:--:|------|----------|----------|
| **FadeIn** | 0 | 홀카드 | `CardDetected` (첫 등장) | 투명 → 불투명 (~300ms) |
| **SlideUp** | 13 | 커뮤니티 카드 | `CardDetected` (보드) | 아래에서 위로 슬라이드 등장 (~300ms) |
| **SlideAndDarken** | 11 | 폴드 카드 | `Fold` → `ActionPerformed` | 아래로 슬라이드 + 어두워지며 사라짐 (~400ms) |

### 승자 강조 시퀀스

| AnimationState | 값 | 순서 | 시각 효과 |
|:-------------:|:--:|:----:|----------|
| **Glint** | 1 | 1단계 | 카드 반짝임 시작 (~200ms) |
| **GlintGrow** | 2 | 2단계 | 카드 확대 + 반짝임 (~500ms) |
| **GlintRotateFront** | 3 | 3단계 | 카드 회전 (앞면 강조) (~400ms) |
| **GlintShrink** | 4 | 4단계 | 원래 크기로 축소 (~300ms) |

### 리셋/전환

| AnimationState | 값 | 대상 | 발동 조건 | 시각 효과 |
|:-------------:|:--:|------|----------|----------|
| **Resetting** | 8 | 전체 | `HandCompleted` | 모든 요소 원위치 (~500ms) |
| **ResetRotateBack** | 6 | 카드 | 핸드 종료 리셋 | 카드 뒷면으로 회전 (~400ms) |
| **ResetRotateFront** | 7 | 카드 | 쇼다운 공개 | 카드 앞면으로 회전 (~400ms) |
| **PreStart** | 5 | 전체 | `StartHand` 직전 | 사전 준비 상태 (~100ms) |
| **Scale** | 10 | 배지/팟 | 값 변경 시 | 크기 변환 강조 (~200ms) |
| **Stop** | 14 | 전체 | 정지 상태 | 애니메이션 없음 (무한) |
| **Waiting** | 15 | action_on 표시 | 플레이어 차례 대기 | 은은한 펄스 (~600ms 반복) |

---

## 2. transition_type 4종

> 참조: BS-06-00-REF §1.6.3 transition_type

화면 요소의 등장/퇴장 전환 효과. `DisplayConfig.transition_type`에서 설정.

| 값 | 이름 | 효과 | 지속 시간 | 용도 |
|:--:|------|------|:-------:|------|
| 0 | **fade** | 페이드 인/아웃 | ~300ms | 카드, 배지 기본 전환 |
| 1 | **slide** | 슬라이드 진입 | ~400ms | 보드 카드, 패널 진입 |
| 2 | **pop** | 튀어나옴 | ~200ms | 액션 배지, 알림 |
| 3 | **expand** | 확장 | ~250ms | 팟 카운터, 승률 바 |

---

## 3. 핸드 진행 단계별 애니메이션 시퀀스

### 3.1 IDLE → SETUP_HAND

| 순서 | 이벤트 | 대상 | AnimationState | 설명 |
|:----:|--------|------|:-------------:|------|
| 1 | `StartHand` | 전체 | PreStart(5) | 이전 핸드 잔여 요소 정리 |
| 2 | `BlindsPosted` | 칩 스택, 팟 | Scale(10) | SB/BB/Ante 차감 + 팟 증가 |
| 3 | — | 딜러 버튼 | fade 전환 | 딜러 좌석으로 이동 |

### 3.2 PRE_FLOP

| 순서 | 이벤트 | 대상 | AnimationState | 설명 |
|:----:|--------|------|:-------------:|------|
| 1 | `CardDetected` × N | 홀카드 | **FadeIn**(0) | 각 좌석 카드 순차 등장 (~300ms 간격) |
| 2 | `EquityUpdated` | 승률 바 | expand 전환 | 초기 승률 표시 |
| 3 | `ActionPerformed` | 액션 배지 | pop 전환 | CHECK/BET/FOLD 등 배지 등장 |
| 4 | `ActionPerformed`(Fold) | 홀카드 | **SlideAndDarken**(11) | 폴드 카드 퇴장 |

### 3.3 FLOP

| 순서 | 이벤트 | 대상 | AnimationState | 설명 |
|:----:|--------|------|:-------------:|------|
| 1 | `CardDetected` × 3 | 보드 카드 1 | **SlideUp**(13) | 첫 번째 카드 (0ms) |
| 2 | — | 보드 카드 2 | **SlideUp**(13) | 두 번째 카드 (+50ms) |
| 3 | — | 보드 카드 3 | **SlideUp**(13) | 세 번째 카드 (+100ms) |
| 4 | `EquityUpdated` | 승률 바 | expand 전환 | 승률 재계산 |
| 5 | `EquityUpdated` | 핸드 랭킹 | fade 전환 | 핸드 등급 표시 |

### 3.4 TURN / RIVER

| 순서 | 이벤트 | 대상 | AnimationState | 설명 |
|:----:|--------|------|:-------------:|------|
| 1 | `CardDetected` × 1 | 보드 카드 | **SlideUp**(13) | 카드 1장 등장 |
| 2 | `EquityUpdated` | 승률 바 | expand 전환 | 승률 재계산 |
| 3 | `EquityUpdated` | 핸드 랭킹 | fade 전환 | 핸드 등급 갱신 |

### 3.5 SHOWDOWN

| 순서 | 이벤트 | 대상 | AnimationState | 설명 |
|:----:|--------|------|:-------------:|------|
| 1 | `ShowdownStarted` | 미공개 홀카드 | **ResetRotateFront**(7) | 카드 앞면으로 회전 공개 |
| 2 | `WinnerDetermined` | 승자 카드 | **Glint**(1) | 반짝임 시작 |
| 3 | — | 승자 카드 | **GlintGrow**(2) | 카드 확대 |
| 4 | — | 승자 카드 | **GlintRotateFront**(3) | 회전 강조 |
| 5 | — | 승자 카드 | **GlintShrink**(4) | 원래 크기로 복귀 |
| 6 | `WinnerDetermined` | 팟 | Scale(10) | 팟 → 승자 스택 이동 |
| 7 | `WinnerDetermined` | 패자 카드 | **SlideAndDarken**(11) | 패자 카드 어두워짐 |

### 3.6 HAND_COMPLETE → IDLE

| 순서 | 이벤트 | 대상 | AnimationState | 설명 |
|:----:|--------|------|:-------------:|------|
| 1 | `HandCompleted` | 전체 | **Resetting**(8) | 모든 요소 리셋 시작 |
| 2 | — | 보드 카드 | **ResetRotateBack**(6) | 보드 카드 뒷면 → 사라짐 |
| 3 | — | 홀카드 | **ResetRotateBack**(6) | 홀카드 뒷면 → 사라짐 |
| 4 | — | 배지/팟/승률 | fade 전환 | 모든 보조 요소 페이드 아웃 |
| 5 | — | 전체 | **Stop**(14) | IDLE 대기 상태 |

---

## 4. 특수 시나리오 애니메이션

### 4.1 All-In Runout

모든 플레이어가 올인한 경우, 남은 보드 카드가 자동 공개된다.

| 이벤트 | 대상 | 동작 |
|--------|------|------|
| `AllInRunout` | 남은 보드 카드 | SlideUp 순차 공개 (50ms 간격) |
| — | 승률 바 | 실시간 갱신 (각 카드 공개마다) |

### 4.2 Run It Multiple

Run It Twice/Thrice 시 보드를 여러 번 깐다.

| 이벤트 | 대상 | 동작 |
|--------|------|------|
| `SetRunItTimes` | 보드 | 이전 보드 ResetRotateBack → 새 보드 SlideUp |
| — | 팟 | 분할 팟 각각 Scale 표시 |

### 4.3 Misdeal

카드 불일치 감지 시 전체 리셋.

| 이벤트 | 대상 | 동작 |
|--------|------|------|
| `MisdealDetected` | 전체 | Resetting(8) → IDLE 상태 |

---

## 5. 애니메이션 속도 설정

> **참조**: Settings 상세는 `BS-03-settings/` 참조

| 설정 | 범위 | 기본값 | 설명 |
|------|------|:------:|------|
| animation_speed | 0.5x ~ 2.0x | 1.0x | 전체 애니메이션 속도 배율 |
| card_fade_duration | 100~500ms | 300ms | 카드 FadeIn 지속 시간 |
| board_slide_duration | 100~600ms | 300ms | 보드 카드 SlideUp 지속 시간 |
| board_stagger_delay | 0~200ms | 50ms | Flop 3장 순차 등장 간격 |
| glint_sequence_duration | 500~2000ms | 1400ms | 승자 Glint 시퀀스 전체 시간 |
| reset_duration | 200~1000ms | 500ms | 핸드 종료 리셋 시간 |

> **핵심**: 모든 지속 시간은 `animation_speed` 배율이 곱해진다. 예: card_fade_duration=300ms × animation_speed=1.5x → 실제 200ms.

---

## 6. 애니메이션 비활성화

| 조건 | 동작 |
|------|------|
| `animation_speed` = 0 | 모든 애니메이션 즉시 전환 (지속 시간 0) |
| 개별 요소 visibility OFF | 해당 요소 애니메이션 미실행 |
| Table PAUSED | 진행 중 애니메이션 정지 (Resume 시 이어서) |

---

## 영향 받는 문서

| 문서 | 관계 |
|------|------|
| `BS-06-00-REF-game-engine-spec.md §1.6` | AnimationState/transition_type Enum 정의 |
| `BS-07-01-elements.md` | 요소별 트리거 조건 |
| `BS-07-03-skin-loading.md` | 스킨별 애니메이션 파라미터 오버라이드 |
| `BS-03-settings/` | 애니메이션 속도 설정 UI |

---

## Rive 사운드 경계 (CCR-033)

Rive Artboard의 State Machine에서 사운드 트리거가 필요한 시점(예: Winner 애니메이션 내부 fanfare)은 **Input 변수**(`soundTrigger: string`)로 외부에 노출하며, Rive가 직접 `audio` 태그로 재생하지 않는다.

```
Rive State Machine
  │
  ├─ animation reaches "fanfare_cue" keyframe
  │
  ├─ Input "soundTrigger" = "winner_fanfare"
  │
  ├─ Flutter 코드 (Input listener)
  │   └─ AudioPlayerProvider.play("winner_fanfare")
  │
  └─ Rive는 사운드를 직접 재생하지 않음
```

**경계 규칙**:
- Rive 내부에서 사운드 재생 금지 — 모든 사운드는 `AudioPlayerProvider` 중앙 관리
- Rive는 `soundTrigger` Input만 변경, 실제 재생은 Flutter 코드 책임
- Volume/Mute/Channel 정책이 Rive 안에 있으면 일관성이 깨지므로 중앙 관리 필수

상세는 `BS-07-05-audio §5 Rive 애니메이션 내부 사운드` 참조.

---

## CC-Overlay 일관성 (CCR-032, CCR-034)

Overlay 애니메이션은 CC(`BS-05-03-seat-management §6`)의 시각 규격과 **동일한 색상 체계와 주기**를 유지한다. 운영자(CC)와 시청자(Overlay)가 서로 다른 시각 언어를 보지 않도록 강제한다.

- **action-glow**: CC는 `#FDD835` box-shadow 0.8s alternate. Overlay는 Rive 애니메이션으로 재현하되 같은 색상·주기.
- **포지션 마커 색상**: Dealer `#E53935`, SB `#FDD835`, BB `#1E88E5`, UTG `#43A047` (CC와 동일)
- **좌석 배경**: Active `#2E7D32`, Folded 40% opacity, All-In `#000000` (CC와 동일)

Table별 색상 Override가 있는 경우 CC와 Overlay가 **동일 override를 공유**한다 (BS-03-02-gfx §7).
