---
title: CR-team4-20260410-bs03-graphic-settings-tab
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team4-20260410-bs03-graphic-settings-tab
---

# CCR-DRAFT: BS-03-02 Graphic Settings Tab 세부화 (team4 담당 영역)

- **제안팀**: team4
- **제안일**: 2026-04-10
- **영향팀**: [team1]
- **변경 대상 파일**: contracts/specs/BS-03-settings/BS-03-02-gfx.md
- **변경 유형**: modify
- **변경 근거**: `team4-cc/CLAUDE.md` §계약 참조에 "BS-03 Settings | Overlay/Skin 탭 (시각 설정 부분)"이 Team 4의 읽기 참조 대상으로 명시되어 있지만, 실제 BS-03-02-gfx.md의 Graphic Settings 탭 내용이 Team 4 관점(Overlay/Skin 편집 흐름)에서 어떤 필드를 설정할 수 있어야 하는지 불명확하다. CCR-025(BS-08 Graphic Editor 신규)와 CCR-024(BS-07 CC-Overlay 시각 일관성)에서 정의한 시각 자산(포지션 마커 색상, 좌석 배경, action-glow, Skin 팔레트 등)이 BS-03-02 Settings 탭에서 어떻게 노출되고 수정되는지 경계가 없어 Team 1이 Lobby Settings 구현 시 참조할 계약이 부족하다. 본 CCR은 BS-03-02의 **Graphic Settings 섹션을 team4 관점에서 확장**한다.

## 변경 요약

BS-03-02-gfx.md에 다음 섹션 추가:

1. **§Active Skin 관리**: 현재 활성 스킨 조회, 스킨 목록, 스킨 전환 (BS-08 Preview/Apply와 연동)
2. **§Overlay 색상 Override**: BS-07-01 §시각 규격의 색상을 테이블별로 override
3. **§Action-Glow 설정**: 주기/색상/효과 변경
4. **§Security Delay 설정**: BS-07-07 참조 + 필드 목록
5. **§Audio Layer 설정**: BS-07-05 참조 + 볼륨/매너모드 토글

## 변경 내용

### 1. BS-03-02-gfx.md §Active Skin 관리 (신규 섹션)

```markdown
## Active Skin 관리

> **참조**: BS-08-05-preview-apply, BS-07-03-skin-loading

Admin이 현재 테이블/글로벌의 활성 스킨을 조회하고 전환.

### UI

```
┌────────────────────────────────────────────────────┐
│ Graphic Settings > Active Skin                     │
│                                                    │
│ Current Active: [WSOP 2026 Final Table v3]   ▼    │
│                                                    │
│ Available Skins:                                   │
│  ○ WSOP 2026 Final Table v3  (active)             │
│  ○ WSOP 2026 Day 1 v1                             │
│  ○ EPT 2026 Prague v2                             │
│  ○ Default                                         │
│                                                    │
│ [Preview]  [Open in Graphic Editor]  [Apply]      │
└────────────────────────────────────────────────────┘
```

### 동작

- **Current Active 드롭다운**: 현재 이 테이블에 적용된 스킨 표시
- **Available Skins 리스트**: Backend `GET /skins` 결과를 표시 (이름, 작성자, 버전)
- **Preview**: 별도 창에서 선택 스킨을 미리보기 (BS-08-05 §Broadcast Preview 재사용)
- **Open in Graphic Editor**: BS-08 Graphic Editor 앱을 Launch하여 선택 스킨 편집
- **Apply**: 선택 스킨을 이 테이블의 Active로 설정 → `PATCH /tables/{id}/active_skin`

### 서버 프로토콜

| 동작 | API | 응답 |
|------|-----|------|
| 목록 조회 | GET /skins | `{ skins: [{ id, name, version, author }, ...] }` |
| 활성 조회 | GET /tables/{id}/active_skin | `{ skin_id, skin_name }` |
| 활성 설정 | PATCH /tables/{id}/active_skin | `{ skin_id }` → WebSocket `SkinChanged` |

### 권한

- Admin: 전체
- Operator: 조회만
- Viewer: 조회만
```

### 2. BS-03-02-gfx.md §Overlay 색상 Override (신규 섹션)

```markdown
## Overlay 색상 Override

> **참조**: BS-07-01-elements §시각 규격, BS-05-03-seat-management §시각 규격 (CC 일관성)

### 배경

BS-07-01 §시각 규격은 CC와 Overlay에서 **동일한 색상 체계**를 사용하도록 규정한다
(CCR-024). 그러나 특정 테이블에서 브랜딩 목적으로 색상을 override해야 할 경우가 있다
(예: 스폰서 로고 색상에 맞춤).

### UI (Admin 전용)

```
┌─────────────────────────────────────────────────┐
│ Graphic Settings > Color Override               │
│                                                 │
│ Position Markers:                               │
│   Dealer  [#E53935] 🔴                          │
│   SB      [#FDD835] 🟡                          │
│   BB      [#1E88E5] 🔵                          │
│   UTG     [#43A047] 🟢                          │
│                                                 │
│ Seat Backgrounds:                               │
│   Active  [#2E7D32] 🟢                          │
│   Folded  [#616161] ⚫ (40% opacity)            │
│   All-In  [#000000] ⬛                          │
│                                                 │
│ [Reset to BS-07 defaults]   [Apply to Table]   │
└─────────────────────────────────────────────────┘
```

### 동작

- **각 색상**: ColorPicker로 hex 값 편집
- **Reset**: BS-07-01 §시각 규격의 기본값으로 되돌리기
- **Apply to Table**: 현재 테이블에만 override 적용 (다른 테이블 영향 없음)

### 제약

- **CC와 Overlay는 동일 override 공유 필수** (CCR-024의 "Skin 오버라이드 정책")
- Override 저장은 스킨 파일(.gfskin) 수준이 아닌 **테이블 설정 수준**
- 스킨 교체 시 override 유지됨 (스킨 위에 override가 overlay)

### 서버 프로토콜

| 동작 | API |
|------|-----|
| 조회 | GET /tables/{id}/configs?keys=color_override |
| 설정 | PATCH /tables/{id}/configs `{ color_override: {...} }` |
| WebSocket | `ConfigChanged { config_keys: ["color_override"] }` → CC와 Overlay 동시 반영 |
```

### 3. BS-03-02-gfx.md §Action-Glow 설정 (신규 섹션)

```markdown
## Action-Glow 설정

> **참조**: BS-05-03-seat-management §시각 규격, BS-07-01-elements §action-glow

### 필드

| 필드 | 타입 | 기본값 | 범위 |
|------|------|:------:|------|
| `glow_enabled` | bool | true | true/false |
| `glow_duration_sec` | float | 0.8 | 0.3 ~ 2.0 |
| `glow_color` | hex | `#FDD835` | 임의 |
| `glow_intensity` | float | 1.0 | 0.5 ~ 2.0 (alpha multiplier) |

### UI

```
┌────────────────────────────────────────┐
│ Graphic Settings > Action Glow         │
│                                        │
│ [✓] Enable Action Glow                 │
│                                        │
│ Duration: ────●──── 0.8s               │
│          (0.3)         (2.0)           │
│                                        │
│ Color:    [#FDD835] 🟡                 │
│                                        │
│ Intensity: ────●──── 1.0               │
│           (0.5)       (2.0)            │
│                                        │
│ [Preview on Seat 1]                    │
└────────────────────────────────────────┘
```

### Preview on Seat 1

- 현재 테이블의 Seat 1에 5초간 action-glow 효과 적용
- 운영자가 실제 강도/색상 확인 가능
- 5초 후 자동 해제

### 경고

- `glow_duration_sec < 0.3`: "너무 빠른 펄스는 시각 피로 유발" 경고
- `glow_duration_sec > 1.5`: "느린 펄스는 주의 환기 효과 감소" 경고
```

### 4. BS-03-02-gfx.md §Security Delay 설정 (신규 섹션)

```markdown
## Security Delay 설정

> **상세 명세**: BS-07-07-security-delay

### 필드

| 필드 | 타입 | 기본값 | 범위 |
|------|------|:------:|------|
| `delay_enabled` | bool | false | true/false |
| `delay_seconds` | int | 30 | 0 ~ 600 |
| `delay_holecards_only` | bool | false | true/false |

### UI

```
┌─────────────────────────────────────────────┐
│ Graphic Settings > Security Delay           │
│                                             │
│ [ ] Enable Security Delay                   │
│                                             │
│ Delay:       [30]  seconds (0 ~ 600)        │
│                                             │
│ [ ] Delay holecards only (other elements    │
│     show immediately)                       │
│                                             │
│ ⚠️ WARNING: Changing delay during operation  │
│    may cause buffer discontinuity.          │
│                                             │
│ [Apply]                                     │
└─────────────────────────────────────────────┘
```

### 동작

- `delay_enabled=false`: Backstage와 Broadcast 모두 즉시 송출
- `delay_enabled=true, delay_seconds=30`: Broadcast만 30초 지연
- Apply 시 `PATCH /tables/{id}/configs` + WebSocket `ConfigChanged` 전파
- Overlay가 `ConfigChanged` 수신 → BS-07-07 §버퍼 아키텍처의 delay 값 업데이트

### 운영 중 변경 경고

`delay_seconds`를 0 → N 또는 N → 0으로 변경 시:

- **0 → N**: 즉시 버퍼 시작. 새 이벤트만 delayed.
- **N → 0**: 기존 버퍼 flush 필요 → 운영자 확인 다이얼로그 필수
```

### 5. BS-03-02-gfx.md §Audio Layer 설정 (신규 섹션)

```markdown
## Audio Layer 설정

> **상세 명세**: BS-07-05-audio

### 필드

| 필드 | 타입 | 기본값 | 범위 |
|------|------|:------:|------|
| `audio_enabled` | bool | true | true/false |
| `master_volume` | float | 0.7 | 0.0 ~ 1.0 |
| `bgm_volume_mix` | float | 0.3 | 0.0 ~ 1.0 |
| `effect_volume_mix` | float | 0.8 | 0.0 ~ 1.0 |
| `silent_mode` | bool | false | true/false |

### UI

```
┌────────────────────────────────────────┐
│ Graphic Settings > Audio               │
│                                        │
│ [✓] Enable Audio Layer                 │
│                                        │
│ Master Volume:  ────●──── 0.7          │
│ BGM Mix:        ──●────── 0.3          │
│ Effect Mix:     ────●●─── 0.8          │
│                                        │
│ [ ] Silent Mode (M key toggle)         │
│                                        │
│ [Test Sound]                           │
└────────────────────────────────────────┘
```

### Test Sound

- 각 Channel에 샘플 사운드 순차 재생
- BGM 3초 → Effect #1 1초 → Effect #2 1초

### Silent Mode

- Overlay 전체 사운드 즉시 mute (fade 없음)
- M 키 단축키로 즉시 토글 (BS-07-05 참조)
```

## Diff 초안

```diff
 # BS-03-02-gfx.md

 ## 기존 섹션...

+## Active Skin 관리
+
+BS-08-05 참조. 드롭다운 + Preview + Open in Graphic Editor + Apply.
+
+## Overlay 색상 Override
+
+CCR-024 참조. Position Markers + Seat Backgrounds를 테이블별 override.
+
+## Action-Glow 설정
+
+duration_sec / color / intensity 슬라이더. Preview on Seat 1.
+
+## Security Delay 설정
+
+BS-07-07 참조. delay_enabled / delay_seconds / delay_holecards_only.
+
+## Audio Layer 설정
+
+BS-07-05 참조. master_volume / bgm_mix / effect_mix / silent_mode.
```

## 영향 분석

### Team 1 (Lobby/Frontend)
- **영향**:
  - BS-03-02-gfx Settings 탭에 5개 섹션 UI 구현
  - ColorPicker, Slider 등 컴포넌트 재사용
  - Preview 기능 (Seat 1에 action-glow 5초 표시) 구현
  - BS-08 Graphic Editor Launch 링크
- **예상 작업 시간**: 20시간

### Team 4 (self)
- **영향**:
  - CC와 Overlay가 `ConfigChanged` 수신 시 `color_override` 적용
  - Action-Glow preview 트리거 API 수신 (`PreviewGlow { seat_no, duration_sec }`)
  - Audio/Security Delay 설정 변경 감지 및 반영
- **예상 작업 시간**: 8시간

### 마이그레이션
- 없음 (신규 Settings 필드)

## 대안 검토

### Option 1: BS-03-02를 현행 유지 (추상 설명만)
- **단점**: 
  - Team 1이 Lobby Settings UI 구현 시 필드 목록 없음 → 임의 결정
  - CC/Overlay가 어떤 설정 변경을 반영해야 하는지 불명확
- **채택**: ❌

### Option 2: 5개 섹션 상세화 (본 제안)
- **장점**: 
  - Team 1이 UI 구현 범위 명확
  - Team 4는 `ConfigChanged` 이벤트에서 어떤 key를 수신할지 명확
  - BS-07/BS-08과 양방향 참조로 SSOT 유지
- **채택**: ✅

### Option 3: BS-03-02를 Team 4 관할로 이관
- **단점**: 
  - BS-03 Settings 전체는 Team 1 관할 (Lobby UI)
  - 소유권 혼재로 관리 비용 증가
- **채택**: ❌

## 검증 방법

### 1. Settings 저장/조회
- [ ] Admin이 모든 필드 변경 후 Apply → `PATCH /tables/{id}/configs` 호출
- [ ] 변경된 값이 DB에 저장 및 다음 연결 시 복원 확인

### 2. ConfigChanged 전파
- [ ] Admin 변경 → BO가 `ConfigChanged` WebSocket 이벤트 발행
- [ ] CC와 Overlay가 동시 수신 + 즉시 반영

### 3. Preview 기능
- [ ] "Preview on Seat 1" 클릭 → Seat 1에 5초간 action-glow 표시
- [ ] 5초 후 자동 해제

### 4. Security Delay 변경
- [ ] 0 → 30 변경 → 이후 이벤트만 delayed
- [ ] 30 → 0 변경 → 확인 다이얼로그 + 버퍼 flush

### 5. Color Override
- [ ] Dealer 색상 변경 → CC와 Overlay에 동일하게 반영
- [ ] 스킨 교체 후에도 override 유지

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 1 기술 검토 (UI 5개 섹션 구현)
- [ ] Team 4 기술 검토 (ConfigChanged 반영 로직)
