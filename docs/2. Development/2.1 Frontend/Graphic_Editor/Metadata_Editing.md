---
title: Metadata Editing
owner: team1
tier: internal
legacy-id: BS-08-02
last-updated: 2026-04-15
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "BS-08-02 메타데이터 편집 기획 완결"
---
# BS-08-02 Metadata Editing — `skin.json` 편집 매트릭스 + PATCH

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | GEM-01~25 편집 매트릭스 + PATCH + ETag 낙관적 동시성 (CCR-011) |
| 2026-04-15 | Element ID 매핑 | §1.1 GEM ↔ Skin Editor Element ID (S-## / GE-##) ↔ 폼 위젯 매핑 신설. team1 발신, Round 2 Phase F. |

---

## 개요

업로드 완료된 스킨의 `skin.json` 메타데이터를 Lobby GE에서 편집하는 흐름을 정의한다. 편집 가능한 필드는 DATA-07 §3에 명시된 25개 키(`GEM-01` ~ `GEM-25`)로 **제한**된다. 그 외 필드(`seats` position 등)는 Rive artboard 소유이며 편집 불가능.

> **범위**: GEM-01~25 (BS-00 §7.4).

---

## 1. 편집 가능 필드 매트릭스

상세 매트릭스는 `DATA-07 §3` + `BS-00 §7.4` GEM-* 표 참조. 요약:

| 카테고리 | 필드 수 | GEM 범위 |
|----------|:-------:|----------|
| Skin 식별 (name/version/author) | 3 | GEM-01~03 |
| 해상도/배경 | 2 | GEM-04~05 |
| 색상 (9 키) | 9 | GEM-06~14 |
| 폰트 (6 키, family+size+weight) | 6 | GEM-15~20 |
| 애니메이션 duration (5 키) | 5 | GEM-21~25 |

**편집 불가 (읽기 전용)**:
- `seats[*]` 배열 — Rive artboard 소유
- `created_at` / `modified_at` — 서버 자동 갱신
- `.riv` 파일 내부 구조 — Rive 공식 에디터 영역

### 1.1 GEM ↔ Skin Editor Element ID ↔ 폼 위젯 매핑

본 표는 GEM 필드 25개를 Skin Editor 설계의 Element ID (`References/skin-editor/EBS-Skin-Editor_v3.prd.md`) 와 1:1 대응시켜 **폼 구현 시 어느 Flutter widget 을 쓸지** 를 고정한다 (2026-04-21 Flutter Desktop 전환).

| GEM | 필드 | Element ID | 폼 위젯 | 제약 |
|-----|------|-----------|---------|------|
| **GEM-01** | `skin_name` | S-01 | `QInput` | 1~100자, `^[\w가-힣\-\s]+$` |
| **GEM-02** | `version` | S-02 | `QInput` (placeholder "1.0.0") | semver |
| **GEM-03** | `author` | S-03 | `QInput` | 1~50자 |
| **GEM-04** | `resolution` | S-04 | `QSelect` (enum combo) | {1920×1080, 1080×1920, 3840×2160} |
| **GEM-05** | `background_color` | S-05 | `QInput type="color"` | hex |
| **GEM-06** | `colors.badge_check` | GE-07 inputs | `EbsColorPicker` | hex |
| **GEM-07** | `colors.badge_fold` | 동 위 | `EbsColorPicker` | hex |
| **GEM-08** | `colors.badge_win` | 동 위 | `EbsColorPicker` | hex |
| **GEM-09** | `colors.card_back` | GE-01 inputs | `EbsColorPicker` | hex |
| **GEM-10** | `colors.pot_label` | GE-03 inputs | `EbsColorPicker` | hex |
| **GEM-11** | `colors.pot_amount` | 동 위 | `EbsColorPicker` | hex |
| **GEM-12** | `colors.timer_active` | GE-03 inputs | `EbsColorPicker` | hex |
| **GEM-13** | `colors.timer_warning` | 동 위 | `EbsColorPicker` | hex |
| **GEM-14** | `colors.leaderboard_bg` | GE-06 inputs | `EbsColorPicker` | hex |
| **GEM-15** | `fonts.pot.family` | GE-03 inputs | `QSelect` (Google Fonts list) | 폰트 패밀리 |
| **GEM-16** | `fonts.pot.size` | 동 위 | `EbsSlider` | 12~96 px |
| **GEM-17** | `fonts.pot.weight` | 동 위 | `QSelect` | 100~900 in 100 |
| **GEM-18** | `fonts.player_name.family` | GE-07 inputs | `QSelect` | 동 위 |
| **GEM-19** | `fonts.player_name.size` | 동 위 | `EbsSlider` | 12~48 px |
| **GEM-20** | `fonts.player_name.weight` | 동 위 | `QSelect` | 동 위 |
| **GEM-21** | `animations.card_fade_duration_ms` | GE-01 anim | `EbsSlider` | 0~2000 ms |
| **GEM-22** | `animations.badge_pulse_duration_ms` | GE-07 anim | `EbsSlider` | 0~2000 ms |
| **GEM-23** | `animations.pot_update_duration_ms` | GE-03 anim | `EbsSlider` | 0~2000 ms |
| **GEM-24** | `animations.timer_tick_duration_ms` | GE-03 anim | `EbsSlider` | 0~500 ms |
| **GEM-25** | `animations.leaderboard_scroll_duration_ms` | GE-06 anim | `EbsSlider` | 0~5000 ms |

**위젯 구현 위치**: `References/skin-editor/ebs-ui-design-plan.md §2` 의 8 공유 컴포넌트 (`EbsColorPicker`, `EbsSlider` 등) 사용. 컴포넌트 경로는 `src/components/ge/` 아래.

**편집 화면 매핑**:
- GEM-01~05 → Skin Metadata 영역 (상단 전폭, `SkinMetadata.vue`)
- GEM-06~14 → ColourAdjust 영역 (좌중하, `ColourAdjust.vue`)
- GEM-15~20 → VisualSettings 영역 (중앙, `VisualSettings.vue`)
- GEM-21~25 → BehaviourSettings 영역 (우측, `BehaviourSettings.vue`)

자세한 컴포넌트 트리·배치는 `References/skin-editor/ebs-ui-layout-anatomy.md §2 (SkinEditorDialog 트리)` 참조.

---

## 2. 편집 FSM

```
viewing
  ↓ user clicks edit (GER-01 Admin gate)
editing (dirty=false)
  ↓ user modifies field
editing (dirty=true)
  ↓ 로컬 JSON Schema validation (실시간)
  ├→ valid → stay editing (dirty=true)
  └→ invalid → field-level 에러 표시
  ↓ user clicks save
saving
  ↓ PATCH success → viewing (dirty=false, new etag)
  ↓ 412 ETag 충돌 → conflict (refetch 제안)
  ↓ 422 schema 실패 → editing (field 에러)
```

---

## 3. PATCH 요청

### 3.1 요청 구조 (API-07 §5)

```http
PATCH /api/v1/skins/{id}/metadata HTTP/1.1
Authorization: Bearer {adminJwt}
If-Match: W/"{etag}"
Content-Type: application/merge-patch+json

{
  "colors": { "badgeCheck": "#00FF00" },
  "fonts": { "pot": { "size": 48 } }
}
```

- **RFC 7396 JSON Merge Patch**: 부분 갱신. 클라이언트는 변경된 필드만 전송.
- **If-Match**: 이전 GET에서 받은 ETag 필수. 충돌 시 412.

### 3.2 응답

| 상태 | 의미 | 후속 |
|------|------|------|
| 200 OK | 편집 성공, 새 ETag 헤더 동봉 | FSM → viewing |
| 403 Forbidden | Admin 아님 (GER-01) | 편집 UI 차단 |
| 412 Precondition Failed | ETag 충돌 | 최신 상태 refetch 후 재시도 다이얼로그 |
| 422 Unprocessable Entity | 서버 스키마 검증 실패 (path 동봉) | 해당 필드에 에러 표시 |

---

## 4. 실시간 클라이언트 검증

편집 중 사용자가 입력할 때마다 다음을 수행:

1. **Type 검증**: 숫자 필드는 정수/범위 체크
2. **Pattern 검증**: 색상 `#hex`, semver, UTF-8 제한
3. **Cross-field 검증**: `resolution.width`와 `.height` enum 매칭
4. **JSON Schema**: `ajv` compile once + `validate` per change

에러는 필드 하단에 inline 표시. "Save" 버튼은 모든 필드 valid일 때만 활성화.

---

## 5. 프리뷰 동기화

메타데이터 편집 시 오른쪽 패널의 Rive 프리뷰가 즉시 반영되어야 한다.

| 필드 카테고리 | 프리뷰 반영 방식 |
|---------------|------------------|
| `colors.*` | CSS custom properties (`--ebs-color-badge-check` 등)를 Rive state machine inputs에 전달 |
| `fonts.*` | CSS `@font-face` 로드 + Rive text run 업데이트 |
| `animations.*_duration_ms` | Rive state machine 속도 parameter 조정 |
| `resolution` | canvas element 크기 변경 (aspect preview) |

> **경고**: 프리뷰는 PATCH 전 **로컬 상태**만 반영한다. 서버에는 Save 클릭 후에만 전송된다.

---

## 6. 요구사항 매핑

모든 GEM-01~25가 본 문서에서 커버된다. 개별 UI 세부는 `team1-frontend/ui-design/UI-08-graphic-editor.md` 참조.

---

## 7. 연관 문서

- `DATA-07-gfskin-schema.md §3` — 편집 매트릭스 원본
- `API-07-graphic-editor.md §4~5` — GET metadata + PATCH
- `BS-08-04-rbac-guards.md` — Admin gate
- `BS-00 §7.4 GEM-*` — 요구사항 ID 리스트
