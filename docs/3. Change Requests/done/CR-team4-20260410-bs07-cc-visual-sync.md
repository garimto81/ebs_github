---
title: CR-team4-20260410-bs07-cc-visual-sync
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team4-20260410-bs07-cc-visual-sync
---

# CCR-DRAFT: BS-07 Overlay 시각 일관성 (CC 색상 체계 재사용)

- **제안팀**: team4
- **제안일**: 2026-04-10
- **영향팀**: [team1]
- **변경 대상 파일**: contracts/specs/BS-07-overlay/BS-07-01-elements.md, contracts/specs/BS-07-overlay/BS-07-04-scene-schema.md
- **변경 유형**: modify
- **변경 근거**: CCR-DRAFT-team4-20260410-bs05-visual-spec에서 BS-05-03에 포지션 마커 색상(Dealer 빨강, SB 노랑, BB 파랑, UTG 초록)과 좌석 상태 배경색(Active 녹색, Folded 40% 반투명, All-In 검정)을 명시했으나, **Overlay 쪽 BS-07-01-elements.md는 이 색상 체계를 참조하지 않는다**. CC(운영자 화면)와 Overlay(방송 시청자 화면)에서 좌석/포지션 색상이 다르면 운영자와 시청자가 **다른 시각 언어**를 보게 되어 혼란을 유발하며, Graphic Editor(BS-08)의 Skin 편집 시에도 기준이 두 개로 분열된다. 본 CCR은 BS-07을 BS-05-03의 색상 체계에 정렬한다.

## 변경 요약

BS-07-01-elements.md와 BS-07-04-scene-schema.md에 **"CC 시각 규격 준수" 섹션**을 추가하여:

1. Player Element의 포지션 마커가 BS-05-03 §시각 규격의 색상 코드를 사용
2. Player Element의 좌석 배경이 상태별 색상(Active/Folded/All-In)을 일치시킴
3. action-glow 애니메이션 주기(0.8s)와 색상을 BS-05-03과 통일
4. Scene Schema의 `player_state_colors` 필드가 BS-05-03 참조로 고정

## 변경 내용

### 1. BS-07-01-elements.md §Player Element §시각 규격 (신규 섹션)

```markdown
## Player Element §시각 규격

> **참조**: BS-05-03-seat-management §시각 규격 (CC 운영자 화면의 좌석 색상 체계)

Overlay의 Player Element(10좌석 각각)는 CC 화면과 **동일한 색상 체계**를 사용한다.
운영자(CC)와 시청자(Overlay)가 같은 시각 언어로 정보를 파악하도록 보장하기 위함.

### 포지션 마커 색상

| 포지션 | CSS / Dart Color | 출처 |
|--------|-----------------|------|
| Dealer | `#E53935` (Material Red 600) | BS-05-03 §포지션 마커 색상 |
| SB | `#FDD835` (Material Yellow 600) | 동일 |
| BB | `#1E88E5` (Material Blue 600) | 동일 |
| UTG | `#43A047` (Material Green 600) | 동일 |
| 일반 | `#FFFFFF` | 동일 |

### 좌석 상태 배경색

| Seat 상태 | 배경 | 투명도 | 추가 요소 |
|----------|------|:------:|----------|
| VACANT | `#616161` | 100% | "OPEN" 텍스트 (Overlay에서는 숨김 가능) |
| OCCUPIED + active | `#2E7D32` | 100% | — |
| OCCUPIED + active + action_on | `#2E7D32` + action-glow | 100% (펄스) | 노란 테두리 |
| OCCUPIED + folded | `#616161` | 40% | — |
| OCCUPIED + sitting_out | `#616161` | 60% | "AWAY" 텍스트 |
| OCCUPIED + all_in | `#000000` | 100% | "ALL-IN" 배지 (흰색) |

### action-glow 애니메이션

- 효과: box-shadow 펄스 (CSS) 또는 동등한 Rive State Machine
- 주기: **0.8초 (BS-05-03과 동일)**
- Rive 구현 시 `action_glow_intensity` Input (0.0~1.0)을 사인파로 구동
- 근거: Preattentive Processing (0.8s가 무의식 감지 범위)

### Skin 오버라이드 정책

Graphic Editor(BS-08)에서 Admin이 Skin마다 위 색상을 **커스터마이즈**할 수 있다.
단, 커스터마이즈 시에도 **CC와 Overlay는 동일 값을 공유**해야 한다.

- Skin의 `manifest.json`에 `player_state_colors` 섹션 1개만 유지
- CC 화면과 Overlay 화면이 모두 이 섹션을 참조
- CC 전용 색상 / Overlay 전용 색상 분리 **금지** (계약 위반)

## 상태 동기화 흐름

```
Game Engine (BS-06)
  │
  ├─ 상태 변경 (player_status: active → folded)
  │
  ├─ OutputEvent 발행 (API-04)
  │   └─ { seat_no, player_status, biggest_bet, ... }
  │
  ├─ Overlay 수신
  │   └─ Player Element 상태 업데이트
  │   └─ BS-07-01 §시각 규격에 따른 배경/펄스 렌더링
  │
  └─ CC 수신 (WebSocket, API-05)
      └─ Seat Cell 상태 업데이트
      └─ BS-05-03 §시각 규격에 따른 배경/펄스 렌더링
```

**중요**: 두 경로가 **동일 색상/애니메이션**으로 렌더링되도록 구현자가 공통 상수를 공유해야 한다.
권장 구현: `team4-cc/src/lib/foundation/theme/seat_colors.dart` 상수를 CC와 Overlay가 모두 import.
```

### 2. BS-07-04-scene-schema.md §player_state_colors (신규 필드)

```markdown
## Scene Schema: player_state_colors

Scene JSON에 다음 필드 추가:

```json
{
  "version": "1.0",
  "elements": [ ... ],
  "player_state_colors": {
    "position_markers": {
      "dealer": "#E53935",
      "sb": "#FDD835",
      "bb": "#1E88E5",
      "utg": "#43A047",
      "default": "#FFFFFF"
    },
    "seat_backgrounds": {
      "vacant": { "color": "#616161", "opacity": 1.0 },
      "active": { "color": "#2E7D32", "opacity": 1.0 },
      "folded": { "color": "#616161", "opacity": 0.4 },
      "sitting_out": { "color": "#616161", "opacity": 0.6 },
      "all_in": { "color": "#000000", "opacity": 1.0 }
    },
    "action_glow": {
      "duration_seconds": 0.8,
      "shadow_from": "rgba(253, 216, 53, 0.4)",
      "shadow_to": "rgba(253, 216, 53, 1.0)"
    }
  }
}
```

### 필드 설명

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `position_markers.*` | hex color | O | 포지션별 마커 색상 |
| `seat_backgrounds.*.color` | hex color | O | 상태별 배경색 |
| `seat_backgrounds.*.opacity` | 0.0~1.0 | O | 투명도 |
| `action_glow.duration_seconds` | float | O | 펄스 주기 (권장: 0.8) |
| `action_glow.shadow_from/to` | rgba | O | 펄스 box-shadow 색상 범위 |

### 기본값

Scene에 `player_state_colors`가 없으면 BS-05-03의 기본값을 사용. Skin 커스터마이즈 시에만 override.

### 검증

Scene 로드 시 `player_state_colors` 필드의 색상 값이 **CC와 일치**하는지 검증 (Unit test: `scene_loader_test.dart § validates color consistency`).
```

## Diff 초안

```diff
 # BS-07-01-elements.md

 ## Player Element

 Player Element는 10좌석 각각에 대한 시각 요소로...

+### 시각 규격 (CC 일관성)
+
+> 참조: BS-05-03-seat-management §시각 규격
+
+포지션 마커 색상:
+| 포지션 | Color |
+|--------|-------|
+| Dealer | #E53935 |
+| SB | #FDD835 |
+| BB | #1E88E5 |
+| UTG | #43A047 |
+
+좌석 배경색:
+| 상태 | Background | Opacity |
+|------|-----------|:-------:|
+| active | #2E7D32 | 100% |
+| folded | #616161 | 40% |
+| all_in | #000000 | 100% |
+
+action-glow: 0.8초 주기, #FDD835 계열 펄스
+
+**Skin 오버라이드 정책**: CC와 Overlay는 동일 색상 공유 필수.
```

```diff
 # BS-07-04-scene-schema.md

 ## Scene JSON 구조

 ```json
 {
   "version": "1.0",
-  "elements": [ ... ]
+  "elements": [ ... ],
+  "player_state_colors": {
+    "position_markers": { "dealer": "#E53935", ... },
+    "seat_backgrounds": { "active": { "color": "#2E7D32", "opacity": 1.0 }, ... },
+    "action_glow": { "duration_seconds": 0.8, ... }
+  }
 }
 ```
```

## 영향 분석

### Team 1 (Lobby/Frontend)
- **영향**: 
  - Lobby의 "활성 CC 모니터링" 뷰가 Overlay 썸네일을 표시한다면 동일 색상 체계 적용 필요
  - BS-02-lobby §CC 모니터링 섹션에 "색상 코드는 BS-05-03/BS-07-01 참조" 참조 추가
- **예상 리뷰 시간**: 1시간

### Team 4 (self)
- **영향**:
  - `team4-cc/src/lib/foundation/theme/seat_colors.dart` 단일 상수 모듈 생성
  - CC의 `features/command_center/widgets/seat_cell.dart`와 Overlay의 `features/overlay/widgets/player_element.dart`가 모두 이 상수 import
  - Scene Schema 로더에서 `player_state_colors` 필드 파싱
  - Unit test로 색상 일관성 검증
- **예상 작업 시간**:
  - 상수 모듈: 1시간
  - CC/Overlay 통합: 3시간
  - Scene Schema 로더 확장: 3시간
  - Unit test: 2시간
  - 총 9시간

### 마이그레이션
- 없음 (신규 시각 규격)

## 대안 검토

### Option 1: CC와 Overlay 각각 독립 색상 정의
- **장점**: 각 화면의 디자인 자유도 최대
- **단점**: 
  - 운영자-시청자 시각 언어 분열 → 혼란
  - 2배의 디자인 비용
  - Skin 1개로 CC+Overlay 공통 편집 불가
- **채택**: ❌

### Option 2: BS-05-03 기준으로 BS-07 정렬 (본 제안)
- **장점**: 
  - 단일 시각 언어
  - Skin 1개로 양쪽 적용
  - 상수 모듈 1개로 구현 간소화
- **단점**: Overlay 디자인 자유도 약간 제한 (브랜딩과 색상이 묶임)
- **채택**: ✅

### Option 3: BS-07 기준으로 BS-05-03 정렬 (역방향)
- **장점**: Overlay 중심 디자인
- **단점**: CCR-DRAFT-team4-20260410-bs05-visual-spec과 충돌 → 재작성 필요
- **채택**: ❌ (이미 BS-05-03 CCR이 먼저 제출되었으므로)

## 검증 방법

### 1. 상수 일관성
- [ ] `team4-cc/src/lib/foundation/theme/seat_colors.dart` 단일 SSOT
- [ ] CC `seat_cell.dart`와 Overlay `player_element.dart`가 동일 상수 import
- [ ] grep으로 하드코딩된 색상값 (`#E53935` 등) 중복 정의 없는지 확인

### 2. Scene Schema
- [ ] `player_state_colors` 필드가 Scene JSON에 유효하게 파싱됨
- [ ] 필드 누락 시 BS-05-03 기본값 fallback
- [ ] 색상 오버라이드 시 CC와 Overlay 양쪽 동시 반영

### 3. 시각 회귀 테스트
- [ ] CC 스크린샷과 Overlay 스크린샷의 좌석 색상 Pixel 비교 (Playwright 또는 Flutter integration test)
- [ ] 동일 HandFSM 상태에서 두 화면이 동일 시각 상태 표시 확인

### 4. Skin 교체 테스트
- [ ] Graphic Editor(BS-08)에서 Skin의 `player_state_colors` 수정 → Apply
- [ ] CC와 Overlay가 모두 새 색상으로 즉시 반영되는지 확인

### 5. action-glow 동기화
- [ ] CC와 Overlay의 펄스 주기가 정확히 0.8초로 동일
- [ ] 펄스 위상(phase)이 동기화될 필요는 없음 (각 화면 독립)

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 1 기술 검토 (Lobby CC 썸네일 색상 일관성)
- [ ] Team 4 기술 검토 (상수 모듈 공유, Scene Schema 확장)
