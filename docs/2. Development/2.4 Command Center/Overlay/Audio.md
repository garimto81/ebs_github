---
title: Audio
owner: team4
tier: internal
legacy-id: BS-07-05
last-updated: 2026-04-15
---

# BS-07-05 Overlay Audio Layer

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | Multi-channel AudioPlayer 아키텍처 + 이벤트→사운드 매핑 (CCR-033) |

---

## 개요

Overlay는 시각 요소 외에 **방송 사운드**가 필요하다 — 카드 딜 효과음, 액션 사운드, 승자 등장 팡파르, Action Clock tick, Intermission BGM 등. WSOP LIVE Fatima.app의 **Audio Player Provider** 패턴(1 BGM + 2 Effect + 동적 Temp)을 재사용한다.

> **참조**: `wsoplive/.../Mobile-Dev/Refactoring/Audio Player Provider (2023).md`, `BS-07-02-animations`.

---

## 1. Multi-channel 아키텍처

```
AudioPlayerProvider (Riverpod)
├── BGM Channel (1개)
│    └── 배경음악 (loop, crossfade 0.5s 교체)
├── Effect Channel #1 (1개)
│    └── 주 효과음 (카드 딜, 액션)
├── Effect Channel #2 (1개)
│    └── 보조 효과음 (UI 피드백, 경고)
└── Temp Channels (동적 생성)
     └── 모든 Effect Channel 재생 중일 때 임시 생성
     └── 재생 완료 시 자동 dispose
```

### 1.1 Channel 별 정책

| Channel | 용도 | 최대 동시 | Fade |
|---------|------|:---------:|:----:|
| **BGM** | 배경음악 | 1 (교체만) | crossfade 0.5s |
| **Effect #1** | 카드 딜, 주 액션 | 1 | fade-out 0.1s |
| **Effect #2** | UI/경고 | 1 | fade-out 0.1s |
| **Temp** | 동적 overflow | 무제한 | fade-out 0.1s |

---

## 2. 이벤트 → 사운드 매핑

| Overlay 이벤트 | Channel | Asset | 우선순위 |
|----------------|:-------:|-------|:--------:|
| `CardDealt` (hole) | Effect #1 | `card_deal_hole.wav` | Low |
| `CardDealt` (board) | Effect #1 | `card_deal_board.wav` | Low |
| `PlayerFold` | Effect #2 | `fold.wav` | Low |
| `PlayerCheck` | Effect #2 | `check.wav` | Low |
| `PlayerBet` / `PlayerRaise` | Effect #1 | `bet.wav` | Medium |
| `PlayerAllIn` | Effect #1 + Temp | `allin_dramatic.wav` | High |
| `WinnerRevealed` | Effect #1 | `winner_fanfare.wav` | High |
| `ActionClock` ≤ 10s | Effect #2 (loop) | `clock_tick.wav` | Medium |
| `ActionClock` expired | Effect #2 | `clock_expired.wav` | High |
| `RunItMultiple` start | Temp | `run_it_transition.wav` | High |
| `Intermission` | BGM | `bgm_intermission.mp3` | — |
| `FinalTable` | BGM | `bgm_final_table.mp3` | — |

---

## 3. 볼륨 정책

| 설정 | 기본값 | 범위 | 설정 위치 |
|------|:------:|:----:|-----------|
| Master volume | 80% | 0~100 | `BS-03-02-gfx §8` |
| BGM volume | 60% | 0~100 | `BS-03-02-gfx §8` |
| Effect #1 volume | 100% | 0~100 | `BS-03-02-gfx §8` |
| Effect #2 volume | 90% | 0~100 | `BS-03-02-gfx §8` |

---

## 4. 매너모드 (Mute)

매너모드는 **전체 오디오를 즉시 음소거**한다 (BGM 포함). 핸드 진행은 계속되며 오디오만 정지.

- 토글 위치: `BS-03-02-gfx §8 Audio Layer` + 단축키 `M`
- 활성 시: 모든 재생 중 사운드 fade-out 0.1s 후 dispose
- 해제 시: 새 이벤트부터 재생 재개 (이전 사운드는 복원 안 함)
- **BGM은 재개 시 처음부터** 재생하지 않고 `pause`/`resume` 경로

---

## 5. Rive 애니메이션 내부 사운드

Rive Artboard는 State Machine에서 사운드 트리거를 내포할 수 있다 (예: Winner 애니메이션 내부 fanfare). 이 사운드는 **Rive 내부에서 재생되지 않고** Flutter AudioPlayer로 라우팅된다.

### 경계 규칙

- Rive State Machine에서 사운드가 필요한 지점은 **Input 변수**(`soundTrigger: string`)로 외부 노출
- Flutter 코드가 Input 변경을 감지하고 `AudioPlayerProvider.play(assetName)` 호출
- Rive가 직접 `audio` 태그로 재생하지 않음 — 모든 사운드는 AudioPlayerProvider 중앙 관리

**이유**: Volume/Mute/채널 정책을 Rive 안에서 구현하면 일관성이 깨진다. 중앙 관리로 단일 출처 유지.

상세는 `BS-07-02-animations §Rive 사운드 경계` 참조.

---

## 6. 에셋 저장 위치

```
skin.gfskin (ZIP)
└── assets/
    ├── audio/
    │   ├── card_deal_hole.wav
    │   ├── card_deal_board.wav
    │   ├── fold.wav
    │   ├── check.wav
    │   ├── bet.wav
    │   ├── allin_dramatic.wav
    │   ├── winner_fanfare.wav
    │   ├── clock_tick.wav
    │   ├── clock_expired.wav
    │   ├── run_it_transition.wav
    │   ├── bgm_intermission.mp3
    │   └── bgm_final_table.mp3
    └── ...
```

`.gfskin` ZIP 내부의 `assets/audio/` 폴더에서 로드한다. `DATA-07` 스키마는 오디오 에셋 파일명을 자유 형식으로 허용한다 (manifest에 파일 리스트 포함).

---

## 7. 연관 문서

- `BS-07-02-animations §Rive 사운드 경계` — Rive 내부 트리거 라우팅
- `BS-07-03-skin-loading` — `.gfskin` 로드 시 audio 에셋 파싱
- `BS-03-02-gfx §8` — 볼륨/매너모드 설정 UI
- `DATA-07-gfskin-schema` — `.gfskin` 포맷 정의
