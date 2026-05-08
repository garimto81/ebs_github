---
title: CR-team4-20260410-bs07-audio-layer
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team4-20260410-bs07-audio-layer
confluence-page-id: 3818947653
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818947653/EBS+CR-team4-20260410-bs07-audio-layer
---

# CCR-DRAFT: BS-07 Overlay 오디오 레이어 추가 (WSOP 1 BGM + 2 Effect 채널)

- **제안팀**: team4
- **제안일**: 2026-04-10
- **영향팀**: [team3]
- **변경 대상 파일**: contracts/specs/BS-07-overlay/BS-07-05-audio.md, contracts/specs/BS-07-overlay/BS-07-02-animations.md
- **변경 유형**: add
- **변경 근거**: 현재 BS-07 Overlay는 시각 요소(8종)와 Rive 애니메이션만 정의하며 **오디오 레이어가 전무**하다. WSOP LIVE Fatima.app의 Audio Player Provider는 **1 BGM Channel + 2 Effect Channels + 임시 Channel 동적 생성** 패턴으로 프로덕션 운영 중이며(출처: `wsoplive/.../Mobile-Dev/Refactoring/Audio Player Provider (2023.md`), 이 자산을 EBS에 재사용하면 방송 사운드(카드 딜 효과음, 승자 등장, 올인 경고, Run It 전환 BGM 등) 구현 비용이 크게 감소한다. 또한 Rive 애니메이션 내부의 사운드 트리거와 Flutter AudioPlayer의 통합 경계가 필요하다.

## 변경 요약

BS-07에 오디오 레이어 명세 2건 추가:

1. **BS-07-05-audio.md (신규)**: Multi-channel AudioPlayer 아키텍처, 이벤트→사운드 매핑, 볼륨 정책, 매너모드
2. **BS-07-02-animations.md (수정)**: Rive State Machine 내부의 사운드 트리거가 Flutter AudioPlayer로 라우팅되는 경계 명시

## 변경 내용

### 1. BS-07-05-audio.md (신규 파일)

```markdown
# BS-07-05 Overlay Audio Layer

> **참조**: wsoplive Fatima.app `Audio Player Provider (2023.md`, BS-07-02-animations

## 배경

Overlay는 시각 요소 외에 **방송 사운드**가 필요하다:

- 카드 딜 효과음 (5장 보드, 20장 홀카드 × 10좌석)
- 플레이어 액션 사운드 (Fold / Check / Bet / Call / Raise / All-In)
- 핸드 종료 연출 (Winner 등장 팡파르)
- Run It 전환 SFX
- 시간 경고 (Action Clock 10초 이하 Tick)
- 배경음악 (Intermission, Final Table)

WSOP LIVE Fatima.app의 Audio Player Provider를 재사용한다.

## Multi-channel 아키텍처

```
AudioPlayerProvider (Riverpod)
├── BGM Channel (1개)
│    └── 배경음악 (loop, fade in/out)
│    └── 동시 재생 불가 (교체 시 crossfade 0.5s)
├── Effect Channel #1 (1개)
│    └── 주 효과음 (카드 딜, 액션)
├── Effect Channel #2 (1개)
│    └── 보조 효과음 (UI 피드백, 경고)
└── Temp Channels (동적 생성)
     └── 모든 Effect Channel이 재생 중일 때 임시 생성
     └── 재생 완료 시 자동 dispose
```

## Channel 별 정책

| Channel | 용도 | 최대 동시 | Fade |
|---------|------|:-------:|:----:|
| BGM | 배경음악 | 1 (교체만) | crossfade 0.5s |
| Effect #1 | 카드/액션 효과음 | 1 | fade-out 0.1s |
| Effect #2 | UI/경고 효과음 | 1 | fade-out 0.1s |
| Temp | 동적 overflow | 무제한 | fade-out 0.1s |

## 이벤트 → 사운드 매핑

| Overlay 이벤트 | Channel | Asset | 우선순위 |
|-------------|:-------:|-------|:-------:|
| CardDealt (hole) | Effect #1 | `assets/audio/card_deal_hole.wav` | Low |
| CardDealt (board) | Effect #1 | `assets/audio/card_deal_board.wav` | Low |
| PlayerFold | Effect #2 | `assets/audio/fold.wav` | Low |
| PlayerCheck | Effect #2 | `assets/audio/check.wav` | Low |
| PlayerBet/Raise | Effect #1 | `assets/audio/bet.wav` | Medium |
| PlayerAllIn | Effect #1 + Temp | `assets/audio/allin_dramatic.wav` | High |
| WinnerRevealed | Effect #1 | `assets/audio/winner_fanfare.wav` | High |
| ActionClock ≤10s | Effect #2 (loop) | `assets/audio/clock_tick.wav` | Medium |
| ActionClock expired | Effect #2 | `assets/audio/clock_expired.wav` | High |
| RunItMultiple start | Temp | `assets/audio/run_it_transition.wav` | High |
| Intermission | BGM | `assets/audio/bgm_intermission.mp3` | — |
| FinalTable | BGM | `assets/audio/bgm_final_table.mp3` | — |

## 볼륨 제어

### Master Volume
- 0.0 ~ 1.0 (Skin Settings에서 설정)
- 기본값: 0.7

### Channel 별 Mix
| Channel | 기본 Mix | 최소 | 최대 |
|---------|:-------:|:---:|:---:|
| BGM | 0.3 (master의 30%) | 0 | 1.0 |
| Effect #1 | 0.8 | 0 | 1.0 |
| Effect #2 | 0.6 | 0 | 1.0 |
| Temp | 0.7 | 0 | 1.0 |

### 최종 볼륨 = Master × Channel Mix × Event Priority

## 매너모드 (Silent Mode)

- **글로벌 Silent 토글**: `M` 단축키 또는 M-01 Toolbar 버튼
- 토글 ON 시:
  - 모든 Channel 볼륨 0
  - BGM은 fade-out 후 pause (재개 시 이어서 재생)
  - Effect는 즉시 중단

- **기기 무음 모드 감지 (Phase 2)**:
  - 운영 머신의 시스템 무음 모드 감지 시 자동 Silent
  - 정책 미정 (WSOP Fatima.app 기획 단계)

## Rive 애니메이션과의 통합

Rive State Machine 내부에 `trigger_sound` Input을 두고, Flutter 측에서 이를 감시하여 AudioPlayer로 라우팅한다. 상세는 `BS-07-02-animations.md §Rive-Audio Bridge` 참조.

## 파일 포맷

- **Effect**: WAV (무손실), 22050Hz, mono, 16-bit
- **BGM**: MP3 (압축), 44100Hz, stereo, 192kbps
- **Max duration**: Effect 3초 / BGM 10분 (loop)

## Skin에 포함

- .gfskin 아카이브의 `assets/audio/` 폴더에 번들
- Skin 교체 시 모든 사운드 asset 교체

## 구현 위치

- `team4-cc/src/lib/foundation/audio_player/audio_player_provider.dart`
- `team4-cc/src/lib/foundation/audio_player/channel_pool.dart`
- `team4-cc/src/lib/features/overlay/services/overlay_audio_router.dart`

## 참조

- BS-07-02-animations §Rive-Audio Bridge
- BS-07-03-skin-loading §assets/audio/ 폴더
- `Overlay_Output_Events.md` (legacy-id: API-04) §OutputEvent (사운드 트리거가 포함되는 이벤트)
- wsoplive Fatima.app Audio Player Provider 원본
```

### 2. BS-07-02-animations.md §Rive-Audio Bridge (신규 섹션)

```markdown
## Rive-Audio Bridge

> **참조**: BS-07-05-audio

Rive 애니메이션 내부에서 사운드를 재생해야 할 경우, Rive 자체의 오디오 기능을 사용하지 않고 Flutter AudioPlayer로 위임한다. 이유:

- Rive 오디오는 asset 번들에 포함되지만 볼륨/매너모드 제어 불가
- AudioPlayer Provider의 Channel 관리, 볼륨 정책 일관성 유지
- Overlay 전체 사운드 타임라인을 한 곳에서 제어

### 브릿지 메커니즘

```
Rive State Machine
  │
  ├─ Input: trigger_sound (Trigger 타입)
  │   └─ Rive 내부 이벤트에서 이 Input을 fire
  │
  └─ Flutter Listener
      ├─ AnimationController.onInputChange("trigger_sound")
      ├─ Rive Input metadata 파싱 (어떤 사운드?)
      ├─ AudioPlayer Provider로 라우팅
      │   └─ channel: "effect_1" | "effect_2" | "temp"
      │   └─ asset: "assets/audio/xxx.wav"
      │   └─ volume: priority 기반
      └─ AudioPlayer 재생
```

### Rive Input 네이밍 규약

- `trigger_sound_card_deal`
- `trigger_sound_bet`
- `trigger_sound_allin`
- `trigger_sound_winner`

각 이름에 대응하는 asset은 `BS-07-05-audio §이벤트→사운드 매핑` 표에서 정의.

### Graphic Editor에서의 편집

Graphic Editor(BS-08-04 Rive Import)에서 Rive .riv 파일을 Import할 때, `trigger_sound_*` Input을 자동 감지하여 Audio 매핑 UI를 제공한다. Admin은 각 Input에 대응하는 사운드 asset을 선택하거나 "None (mute)"을 지정할 수 있다.
```

## Diff 초안

```diff
+++ contracts/specs/BS-07-overlay/BS-07-05-audio.md (신규)
  (전체 내용 위 §1 참조)

 # contracts/specs/BS-07-overlay/BS-07-02-animations.md

+## Rive-Audio Bridge
+
+Rive 애니메이션 내부에서 사운드가 필요할 경우, Rive 자체 오디오 대신
+Flutter AudioPlayer Provider로 위임. 상세는 BS-07-05-audio §Rive-Audio Bridge.
+
+Rive Input 네이밍 규약: trigger_sound_{event}
```

## 영향 분석

### Team 3 (Game Engine)
- **영향**: 
  - Game Engine이 `OutputEvent`(API-04)를 발행할 때 사운드 트리거 힌트를 포함해야 할 수도 있음
  - 예: `PlayerAllIn` 이벤트에 `sound_hint: "allin_dramatic"` 필드
  - 단, Overlay가 이벤트 타입만으로 사운드를 결정해도 충분하므로 **필수는 아님**
- **예상 리뷰 시간**: 1시간

### Team 4 (self)
- **영향**:
  - `just_audio: ^0.9` 또는 동등 패키지 의존성 추가 (pubspec.yaml)
  - `lib/foundation/audio_player/` 모듈 신규 구현
  - Overlay 이벤트 리스너에서 사운드 라우팅 통합
  - Skin 포맷 확장 (`assets/audio/` 폴더)
- **예상 작업 시간**:
  - AudioPlayer Provider 구현: 10시간
  - Channel Pool: 6시간
  - 이벤트 매핑: 4시간
  - Rive-Audio Bridge: 6시간
  - 사운드 asset 샘플 준비: 4시간
  - 총 약 30시간

### 마이그레이션
- 없음 (신규 기능)

## 대안 검토

### Option 1: 오디오 레이어 생략 (시각만 Overlay)
- **장점**: 구현 부담 없음
- **단점**: 
  - 방송 품질 저하 (카드 딜 효과음, 승자 등장 등이 없음)
  - 경쟁사(PokerGFX) 대비 열세
  - WSOP Fatima.app의 Audio Provider 자산을 버림
- **채택**: ❌

### Option 2: Rive 내부 오디오만 사용
- **장점**: Flutter 측 구현 최소화
- **단점**: 
  - 볼륨/매너모드 제어 불가
  - BGM과 Effect 채널 분리 불가
  - 동적 우선순위 무시
- **채택**: ❌

### Option 3: WSOP Fatima.app 패턴 그대로 채택 (본 제안)
- **장점**: 
  - 조직 자산 재사용
  - Multi-channel + 동적 Temp 생성으로 복잡한 방송 상황 대응
  - BGM/Effect 분리 + 매너모드로 완성도
- **단점**: 30시간 구현 비용
- **채택**: ✅

## 검증 방법

### 1. 아키텍처 검증
- [ ] BGM / Effect #1 / Effect #2 / Temp Channel 4종 구조 확인
- [ ] 동시 재생 10개 시 메모리/CPU 프로파일링

### 2. 이벤트 매핑 테스트
- [ ] 표의 각 이벤트가 올바른 Channel과 우선순위로 라우팅
- [ ] All-In 시 Effect #1 + Temp 동시 재생 (드라마틱 효과)

### 3. 매너모드
- [ ] `M` 키 토글 시 모든 사운드 즉시 중단
- [ ] BGM 재개 시 이전 재생 위치 유지
- [ ] Skin 재로드 시 Silent 상태 유지

### 4. Rive 통합
- [ ] Rive Input `trigger_sound_*` 감지 및 라우팅 확인
- [ ] Graphic Editor에서 Rive Import 시 Audio 매핑 UI 정상 표시

### 5. 볼륨 계산
- [ ] 최종 볼륨 = Master × Channel Mix × Event Priority 공식 검증
- [ ] Master 0.0일 때 모든 Channel 무음 확인

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 3 기술 검토 (OutputEvent에 sound_hint 필드 추가 여부)
- [ ] Team 4 기술 검토 (just_audio 패키지, 30시간 일정 적합성)
