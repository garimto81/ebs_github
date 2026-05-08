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
| 2026-05-07 | v4 cascade | CC_PRD v4.0 정체성 정합 — Rive 애니메이션은 5-Act 시퀀스의 각 Act 전환 시 trigger (Act 2 PreFlop = HoleCard 분배 / Act 3a Flop = 3 카드 동시 / Act 4 Showdown = 핸드 공개 / Act 5 Settlement = 팟 분배). SSOT: `Sequences.md §"v4.0 5-Act → Overlay 매핑"`. |

---

## 개요

이 문서는 Overlay의 **Rive 애니메이션 발동 조건과 시퀀스**를 정의한다. 각 오버레이 요소가 언제, 어떤 애니메이션으로 등장/퇴장/강조되는지 모든 경우의 수를 기술한다.

> **v4.0 컨텍스트** (2026-05-07): 본 문서의 Rive 애니메이션은 v4.0 5-Act 시퀀스의 Act 전환 trigger 에서 발동 — Act 2 PreFlop (HoleCard 분배), Act 3 Flop/Turn/River (커뮤니티 카드), Act 4 Showdown (핸드 공개), Act 5 Settlement (팟 분배). 자세한 Act 별 trigger 매핑: `Sequences.md §"v4.0 5-Act → Overlay 매핑"`.

> **참조**: AnimationState 16개, transition_type 4종 Enum 값은 `Behavioral_Specs/Overview.md §1.6` (legacy-id: BS-06-00)에 정의. 이 문서는 해당 Enum이 **언제, 왜 발동하는가**를 기술한다.

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
| `Behavioral_Specs/Overview.md §1.6` (legacy-id: BS-06-00) | AnimationState/transition_type Enum 정의 |
| `Elements.md` (legacy-id: BS-07-01) | 요소별 트리거 조건 |
| `Skin_Loading.md` (legacy-id: BS-07-03) | 스킨별 애니메이션 파라미터 오버라이드 |
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

상세는 `Audio.md §5 Rive 애니메이션 내부 사운드` (legacy-id: BS-07-05) 참조.

---

## CC-Overlay 일관성 (CCR-032, CCR-034)

Overlay 애니메이션은 CC(`Seat_Management.md §6` (legacy-id: BS-05-03))의 시각 규격과 **동일한 색상 체계와 주기**를 유지한다. 운영자(CC)와 시청자(Overlay)가 서로 다른 시각 언어를 보지 않도록 강제한다.

- **action-glow**: CC는 `#FDD835` box-shadow 0.8s alternate. Overlay는 Rive 애니메이션으로 재현하되 같은 색상·주기.
- **포지션 마커 색상**: Dealer `#E53935`, SB `#FDD835`, BB `#1E88E5`, UTG `#43A047` (CC와 동일)
- **좌석 배경**: Active `#2E7D32`, Folded 40% opacity, All-In `#000000` (CC와 동일)

Table별 색상 Override가 있는 경우 CC와 Overlay가 **동일 override를 공유**한다 (`Settings/Graphics.md` (legacy-id: BS-03-02) §7).

---

## PokerGFX 애니메이션 참조

> **PokerGFX 역설계 기반**: `ebs_reverse/docs/02-design/pokergfx-reverse-engineering-complete.md §7` 의 DirectX 기반 애니메이션 체계를 Rive 기술 스택으로 재해석한 참조표. EBS는 **구조적 아이디어** (상태 머신·Z-order·스레드 분리) 는 계승하되 구현은 Flutter/Rive 로 대체한다.

### 1. 11개 애니메이션 클래스 → Rive 매핑

| # | PokerGFX 클래스 | 역할 | Rive 매핑 (BS-07-02 §1) |
|:-:|-----------------|------|-------------------------|
| 1 | `BoardCardAnimation` | 보드 카드 등장 (Flop/Turn/River) | §1 카드 등장/퇴장 `board_card_reveal` |
| 2 | `PlayerCardAnimation` | 플레이어 홀카드 등장 | §1 카드 등장/퇴장 `hole_card_deal` |
| 3 | `CardBlinkAnimation` | 카드 깜빡임 하이라이트 | §1 승자 강조 `winning_card_blink` |
| 4 | `CardUnhiliteAnimation` | 카드 하이라이트 해제 | §1 리셋/전환 `card_unhilite` |
| 5 | `CardFace` | 카드 면 전환 (뒷면↔앞면) | `card_flip` state transition |
| 6 | `GlintBounceAnimation` | 그래픽 반짝임·바운스 | §1 승자 강조 `pot_sweep_glint` |
| 7 | `OutsCardAnimation` | 아웃츠 카드 등장 (Equity 연계) | Equity bar 보조 애니메이션 (TBD) |
| 8 | `PanelImageAnimation` | 패널 이미지 전환 (스킨 swap) | Skin transition (BS-07-03) |
| 9 | `PanelTextAnimation` | 패널 텍스트 전환 | §2 `trans_in/out` 4종 매핑 |
| 10 | `FlagHideAnimation` | 국기 표시/숨김 | Player nametag 국적 표시 토글 |
| 11 | `AnimationState` | 전체 상태머신 enum | Rive State Machine root |

### 2. AnimationState enum 16값 → Rive State

> PokerGFX `AnimationState` 는 모든 애니메이션 클래스가 공유하는 통합 상태 머신. Rive 에서는 각 클래스별 State Machine 으로 분리하되 명명 규칙을 계승.

| 값 | 명명 | Rive 권장 State 이름 |
|:-:|------|---------------------|
| 0 | `FadeIn` | `fade_in` |
| 1 | `Glint` | `glint` |
| 2 | `GlintGrow` | `glint_grow` |
| 3 | `GlintRotateFront` | `glint_rotate_front` |
| 4 | `GlintShrink` | `glint_shrink` |
| 5 | `PreStart` | `pre_start` |
| 6 | `ResetRotateBack` | `reset_rotate_back` |
| 7 | `ResetRotateFront` | `reset_rotate_front` |
| 8 | `Resetting` | `resetting` |
| 9 | `RotateBack` | `rotate_back` |
| 10 | `Scale` | `scale` |
| 11 | `SlideAndDarken` | `slide_darken` |
| 12 | `SlideDownRotateBack` | `slide_down_rotate_back` |
| 13 | `SlideUp` | `slide_up` |
| 14 | `Stop` | `stop` |
| 15 | `Waiting` | `waiting` |

### 3. 5-Thread 파이프라인 (구조 참조만, EBS 는 Flutter 단일 이벤트 루프)

| PokerGFX 스레드 | 역할 | EBS 대응 |
|-----------------|------|----------|
| `thread_worker` (Main Live) | `BlockingCollection<MFFrame> live_frames` → Direct2D 렌더 | Flutter 위젯 rebuild (반응형) |
| `thread_worker_audio` | `AutoResetEvent` 동기 → `ext_audio_buffer` | Flutter `audioplayers` 플러그인 (BS-07-05) |
| `thread_worker_delayed` | `MDelayClass` 타임시프트 → `canvas_delayed` | OutputEventBuffer (§API-04 §3.6, Team 4 소유) |
| `thread_worker_write` | `MFWriterClass` 파일 기록 | 녹화 기능 (Phase 2+ TBD) |
| `thread_worker_process_delay` | 딜레이 버퍼 처리 | Security Delay 버퍼 (API-04 §3) |

> **EBS 차이**: PokerGFX 는 DirectX 11 + 5 스레드 Producer-Consumer. EBS 는 Flutter 단일 이벤트 루프 + Isolate 필요 시 분리. 직접 계승 대상은 **delay 버퍼 역할 분리** 뿐.

### 4. Z-order 렌더링 레이어

| Z-order | PokerGFX 계층 | 내용 | EBS 위젯 계층 |
|:-:|---------------|------|---------------|
| 최상 | `border_elements` | 테두리·프레임 | Overlay 루트 Border widget |
| 중상 | `pip_elements` | Picture-in-Picture 카메라 | (Phase 2+ TBD) |
| 중 | `text_elements` (52필드) | DirectWrite 텍스트 (Ticker, Reveal, Static, Shadow) | Flutter Text + RichText |
| 하 | `image_elements` (41필드) | Direct2D Effects (Crop→Transform→Brightness→Alpha→ColorMatrix→HueRotation) | Flutter Image + ColorFilter |

### 비정렬

- **Direct2D Effects Pipeline**: EBS 는 Flutter `ColorFiltered` / `ShaderMask` 로 부분 대체.
- **DirectWrite**: Flutter `TextStyle` 로 대체.
- **MFFormats SDK (비디오 프레임 포맷)**: EBS 는 NDI 텍스처 캡처만 필요 (API-04 §2.3).
