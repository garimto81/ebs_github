# BS-07-03 Skin Loading — 스킨 로드/전환 프로세스

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 스킨 정의, 로드 프로세스, 전환 규칙, 파일 구조, 폴백 |

---

## 개요

이 문서는 Overlay의 **스킨 로드 및 전환 프로세스**를 정의한다. 스킨은 Overlay의 시각적 테마를 결정하는 Rive 파일 + 메타데이터 JSON 패키지다.

> **참조**: 스킨 엔티티 정의는 `BS-00-definitions.md §2.3`. Feature Catalog SK-001~016. DisplayConfig는 `BS-06-00-REF-game-engine-spec.md Ch6`.

---

## 1. 스킨 정의

| 항목 | 내용 |
|------|------|
| **구성** | Rive 파일 (.riv) + 메타데이터 JSON (.skin.json) |
| **역할** | Overlay의 배경, 카드 이미지, 좌석 레이아웃, 폰트, 색상 팔레트 정의 |
| **단위** | 1 스킨 = 1개 .riv + 1개 .skin.json |
| **저장 위치** | 로컬 파일 시스템 (SYS 설정의 스킨 경로) |

---

## 2. 스킨 파일 구조

### 2.1 배포 포맷: `.gfskin` ZIP (CCR-012)

스킨은 `.gfskin` 확장자의 ZIP 컨테이너로 배포된다. 상세 스키마는 `contracts/data/DATA-07-gfskin-schema.md` 참조.

```
my-skin.gfskin (ZIP)
├── skin.json          ← 메타데이터 (필수, 루트)
├── skin.riv           ← Rive 애니메이션 파일 (필수)
├── cards/             ← 카드 이미지 (선택, 52장 + back)
│   └── As.png ... back.png
└── assets/            ← 기타 에셋 (선택)
    ├── background.png
    └── dealer-button.png
```

Overlay 로드 시에는 `.gfskin`을 in-memory 압축 해제 후 `skin.json` + `skin.riv`를 읽는다. 로컬 캐시(`skins/` 디렉토리)는 구현 세부사항이며 계약 범위가 아니다.

> **이전 디렉토리 기반 포맷**(`skin.skin.json` + 별도 `.riv`)은 폐기되었다. Team 1 Lobby GE가 `.gfskin`을 생성하고 Team 2가 저장, Team 4 Overlay가 in-memory로 해제해 소비한다.

### 2.2 메타데이터 JSON 구조 (.skin.json)

```json
{
  "skin_name": "wsop-2026-default",
  "version": "1.0.0",
  "author": "EBS Design Team",
  "resolution": { "width": 1920, "height": 1080 },
  "background": {
    "type": "image",
    "file": "assets/background.png",
    "chromakey_color": "#00FF00"
  },
  "seats": [
    {
      "seat_index": 0,
      "position": { "x": 160, "y": 600 },
      "holecards_offset": { "x": 0, "y": -80 },
      "badge_offset": { "x": 0, "y": 40 },
      "equity_offset": { "x": 0, "y": 60 }
    }
  ],
  "board": {
    "position": { "x": 760, "y": 300 },
    "card_spacing": 80,
    "card_size": { "width": 60, "height": 84 }
  },
  "pot": {
    "position": { "x": 960, "y": 420 }
  },
  "dealer_button": {
    "icon": "assets/dealer-button.png",
    "size": { "width": 32, "height": 32 }
  },
  "lower_third": {
    "position": { "x": 0, "y": 980 },
    "height": 100
  },
  "fonts": {
    "player_name": { "family": "Roboto", "size": 18, "weight": "bold" },
    "chip_stack": { "family": "Roboto Mono", "size": 16, "weight": "regular" },
    "pot": { "family": "Roboto Mono", "size": 20, "weight": "bold" },
    "action_badge": { "family": "Roboto", "size": 14, "weight": "bold" },
    "equity": { "family": "Roboto", "size": 12, "weight": "regular" },
    "hand_rank": { "family": "Roboto", "size": 12, "weight": "italic" }
  },
  "colors": {
    "background": "#1A1A2E",
    "text_primary": "#FFFFFF",
    "text_secondary": "#B0B0B0",
    "badge_check": "#4CAF50",
    "badge_fold": "#F44336",
    "badge_bet": "#FFC107",
    "badge_call": "#2196F3",
    "badge_allin": "#FF5722",
    "equity_bar": "#4FC3F7",
    "pot_text": "#FFD700"
  },
  "animations": {
    "card_fade_duration_ms": 300,
    "board_slide_duration_ms": 300,
    "board_stagger_delay_ms": 50,
    "glint_sequence_duration_ms": 1400,
    "reset_duration_ms": 500
  }
}
```

> **핵심**: 스킨 JSON의 `animations` 섹션은 `BS-07-02-animations.md` §5의 기본값을 **오버라이드**한다.

---

## 3. 스킨 로드 프로세스

### 3.1 정상 로드 흐름

```
Overlay 시작
  │
  ├─ 1. 스킨 경로 확인 (BO Config → skin_path)
  │
  ├─ 2. .skin.json 파일 읽기
  │     ├─ 성공 → 파싱
  │     └─ 실패 → 폴백 스킨 로드 (§4)
  │
  ├─ 3. .riv 파일 읽기
  │     ├─ 성공 → Rive 렌더러 초기화
  │     └─ 실패 → 폴백 스킨 로드 (§4)
  │
  ├─ 4. 에셋 로드 (카드 이미지, 배경, 아이콘)
  │     ├─ 전부 성공 → 렌더러에 바인딩
  │     └─ 일부 실패 → 실패 에셋만 기본 대체, 경고 로그
  │
  └─ 5. 렌더링 시작
```

### 3.2 로드 타이밍

| 시점 | 동작 |
|------|------|
| Overlay 앱 시작 | BO Config에서 마지막 사용 스킨 로드 |
| Admin 스킨 변경 | `ConfigChanged` (BO) → 새 스킨 리로드 |
| 스킨 파일 손상 발견 | 폴백 스킨 자동 전환 + 에러 로그 |

---

## 4. 폴백 스킨 (Fallback)

| 항목 | 내용 |
|------|------|
| **이름** | `ebs-default` |
| **위치** | 앱 내장 (APK/번들에 포함) |
| **특징** | 최소한의 기본 테마. 모든 요소 표시 가능 |
| **발동 조건** | 지정 스킨 로드 실패 시 자동 전환 |

폴백 스킨은 삭제/수정 불가. 앱 업데이트 시에만 변경된다.

---

## 5. 스킨 전환 프로세스

### 5.1 전환 흐름

```
Admin이 Settings에서 스킨 변경
  │
  ├─ BO → ConfigChanged 이벤트 발행
  │
  ├─ Overlay 수신
  │     │
  │     ├─ skin_transition_type에 따라 전환 효과 적용
  │     │
  │     ├─ 새 스킨 로드 (§3.1 프로세스)
  │     │
  │     └─ 렌더러 교체 완료
  │
  └─ 렌더링 재개
```

### 5.2 전환 효과

`skin_transition_type` enum (BS-06-00-REF §6.1):

| 값 | 이름 | 효과 |
|:--:|------|------|
| 0 | cut | 즉시 교체 (전환 효과 없음) |
| 1 | fade | 기존 스킨 페이드 아웃 → 새 스킨 페이드 인 |
| 2 | slide | 기존 스킨 슬라이드 아웃 → 새 스킨 슬라이드 인 |
| 3 | dissolve | 기존 + 새 스킨 크로스 디졸브 |
| 4 | black | 기존 → 검정 → 새 스킨 |

### 5.3 핸드 진행 중 스킨 전환

| 규칙 | 설명 |
|------|------|
| **즉시 적용** | 핸드 진행 중에도 스킨 전환 가능 |
| **확인 다이얼로그 없음** | Admin이 변경하면 Overlay가 즉시 반영 |
| **게임 데이터 유지** | 스킨만 교체, 게임 상태(카드/팟/스택)는 그대로 |
| **애니메이션 리셋** | 진행 중 애니메이션은 중단, 새 스킨 기준 재시작 |

---

## 6. 스킨 검증

### 6.1 필수 검증 항목 (CCR-012)

스킨 로드 시 다음 항목을 검증한다. 실패 시 폴백 전환. 전체 검증 순서는 `DATA-07-gfskin-schema.md §4` 참조.

| 검증 항목 | 조건 | 실패 시 |
|----------|------|--------|
| ZIP 구조 | `.gfskin` 내부에 `skin.json` + `skin.riv`가 루트에 존재 | 폴백 전환 |
| JSON Schema | `skin.json`이 DATA-07 스키마(`$id: gfskin-1.0.json`)를 통과 | 폴백 전환 |
| Rive 파싱 | `skin.riv` 파싱 성공 | 폴백 전환 |
| 해상도 일치 | skin resolution == output resolution | 경고 로그 (스케일링 적용) |
| 카드 이미지 | `cards/` 엔트리가 존재할 경우 52장 + back 검증 | 누락분만 기본 대체 |

### 6.2 에러 처리

| 에러 | 심각도 | 시스템 반응 |
|------|:------:|-----------|
| 스킨 파일 없음 | CRITICAL | 폴백 스킨 전환 + 에러 로그 |
| JSON 파싱 실패 | CRITICAL | 폴백 스킨 전환 + 에러 로그 |
| Rive 파싱 실패 | CRITICAL | 폴백 스킨 전환 + 에러 로그 |
| 카드 이미지 누락 | WARNING | 기본 카드 이미지 대체 + 경고 로그 |
| 해상도 불일치 | WARNING | 자동 스케일링 + 경고 로그 |

---

## 7. 스킨과 DisplayConfig 관계

스킨은 **시각적 테마**(위치, 색상, 폰트)를 정의한다. DisplayConfig는 **동작 설정**(공개 시점, 표시 조건)을 정의한다. 둘은 독립이다.

| 설정 주체 | 예시 | 변경 주체 |
|----------|------|----------|
| **스킨** (.skin.json) | 카드 위치, 배지 색상, 폰트 크기 | Skin Editor (SK-001~016) |
| **DisplayConfig** | card_reveal_type, show_rank, equity_show_type | Settings (Admin) |

> **핵심**: 스킨 A에서 스킨 B로 전환해도 DisplayConfig(공개 시점, 가시성 토글 등)는 변하지 않는다.

---

## 영향 받는 문서

| 문서 | 관계 |
|------|------|
| `BS-07-01-elements.md` | 스킨이 정의하는 요소 위치/스타일 |
| `BS-07-02-animations.md` | 스킨의 animations 섹션이 기본 속도 오버라이드 |
| `BS-06-00-REF-game-engine-spec.md §6` | DisplayConfig, skin_transition_type |
| `BS-03-settings/` | 스킨 선택 UI |
| Feature Catalog SK-001~016 | Skin Editor 기능 |
