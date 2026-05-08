---
title: GFSkin Schema
owner: team2
tier: internal
legacy-id: DATA-07
last-updated: 2026-04-15
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "DATA-07 GFSkin 스키마 (SG-004 RESOLVED 반영)"
confluence-page-id: 3820552801
confluence-parent-id: 3811770578
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3820552801/EBS+GFSkin+Schema
---
# DATA-07 .gfskin Schema — Graphic Editor 아티팩트 포맷 SSOT

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | `.gfskin` ZIP 컨테이너 + `skin.json` JSON Schema Draft-07 (CCR-012) |

---

## 개요

`.gfskin`은 EBS Graphic Editor(Team 1 Lobby)가 생성하고 Overlay(Team 4)가 소비하는 **단일 아티팩트 포맷**이다. ZIP 컨테이너 내부에 `skin.json` 메타데이터, `skin.riv` 애니메이션, 선택적 `cards/`·`assets/` 폴더를 포함한다.

> **배경**: 기존 `BS-07-03 §2.1`은 디렉토리 기반 스킨(`skin.riv + skin.skin.json + cards/`)을 전제했고, `team4-cc/ui-design/UI-06-skin-editor.md`는 `.gfskin` ZIP 포맷을 전제해 불일치가 발생했다. 본 문서는 `.gfskin` ZIP으로 단일화한다.

---

## 1. `.gfskin` ZIP 구조

```
my-skin.gfskin (ZIP)
├── skin.json          ← 메타데이터 (필수, 루트)
├── skin.riv           ← Rive 애니메이션 파일 (필수)
├── cards/             ← 카드 이미지 (선택)
│   ├── As.png ~ 2c.png (52장)
│   └── back.png
└── assets/            ← 기타 에셋 (선택)
    ├── background.png
    └── dealer-button.png
```

**필수 엔트리**:
- `skin.json` — 루트에 존재, UTF-8
- `skin.riv` — 루트에 존재, Rive 바이너리

**선택 엔트리**:
- `cards/` — 52장 카드 이미지 + 뒷면 (누락 시 기본 이미지)
- `assets/` — 기타 리소스 (배경, 딜러버튼 등)

---

## 2. `skin.json` JSON Schema

스키마 ID: `https://ebs/schemas/gfskin-1.0.json`

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://ebs/schemas/gfskin-1.0.json",
  "type": "object",
  "required": ["skin_name", "version", "resolution", "colors", "fonts"],
  "additionalProperties": false,
  "properties": {
    "skin_name": { "type": "string", "minLength": 1, "maxLength": 40 },
    "version": { "type": "string", "pattern": "^\\d+\\.\\d+\\.\\d+$" },
    "author": { "type": "string", "maxLength": 80 },
    "created_at": { "type": "string", "format": "date-time" },
    "modified_at": { "type": "string", "format": "date-time" },
    "resolution": {
      "type": "object",
      "required": ["width", "height"],
      "properties": {
        "width": { "type": "integer", "enum": [1920, 2560, 3840] },
        "height": { "type": "integer", "enum": [1080, 1440, 2160] }
      }
    },
    "background": {
      "type": "object",
      "properties": {
        "type": { "enum": ["image", "color", "chromakey"] },
        "file": { "type": "string" },
        "color": { "type": "string", "pattern": "^#[0-9A-Fa-f]{6}$" },
        "chromakey_color": { "type": "string", "pattern": "^#[0-9A-Fa-f]{6}$" }
      }
    },
    "colors": {
      "type": "object",
      "additionalProperties": { "type": "string", "pattern": "^#[0-9A-Fa-f]{6}$" },
      "required": [
        "background",
        "text_primary",
        "text_secondary",
        "badge_check",
        "badge_fold",
        "badge_bet",
        "badge_call",
        "badge_allin"
      ]
    },
    "fonts": {
      "type": "object",
      "additionalProperties": {
        "type": "object",
        "required": ["family", "size"],
        "properties": {
          "family": { "type": "string" },
          "size": { "type": "integer", "minimum": 8, "maximum": 96 },
          "weight": { "enum": ["regular", "bold", "italic", "bold-italic"] }
        }
      }
    },
    "animations": {
      "type": "object",
      "description": "Duration only. Type/curve is out-of-scope (Rive editor).",
      "properties": {
        "card_fade_duration_ms": { "type": "integer", "minimum": 0, "maximum": 5000 },
        "board_slide_duration_ms": { "type": "integer", "minimum": 0, "maximum": 5000 },
        "board_stagger_delay_ms": { "type": "integer", "minimum": 0, "maximum": 1000 },
        "glint_sequence_duration_ms": { "type": "integer", "minimum": 0, "maximum": 5000 },
        "reset_duration_ms": { "type": "integer", "minimum": 0, "maximum": 5000 }
      }
    },
    "seats": {
      "type": "array",
      "minItems": 10,
      "maxItems": 10,
      "items": {
        "type": "object",
        "description": "Seat position is owned by the Rive artboard. This array exists only for metadata compatibility.",
        "properties": {
          "seat_index": { "type": "integer", "minimum": 0, "maximum": 9 }
        }
      }
    }
  }
}
```

---

## 3. 편집 가능 / 읽기 전용 매트릭스

Lobby GE에서 편집 가능한 필드를 `GEM-*` 요구사항 ID에 매핑한다 (BS-00 §7.4 참조).

| skin.json path | 편집 | GEM ID | UI 유형 |
|----------------|:----:|--------|---------|
| `skin_name` | ✓ | GEM-01 | text input (1~40) |
| `version` | ✓ | GEM-02 | text input (semver) |
| `author` | ✓ | GEM-03 | text input (0~80) |
| `created_at` | ✗ | — | 자동 (서버) |
| `modified_at` | ✗ | — | 자동 (서버) |
| `resolution.width` / `.height` | ✓ | GEM-04 | dropdown (enum) |
| `background.type` | ✓ | GEM-05 | dropdown |
| `background.color` | ✓ | GEM-05 | color picker |
| `background.chromakey_color` | ✓ | GEM-05 | color picker |
| `colors.*` (9 키) | ✓ | GEM-06 ~ GEM-14 | color picker (#hex) |
| `fonts.*.family` / `.size` / `.weight` | ✓ | GEM-15 ~ GEM-20 | family+size+weight |
| `animations.*_duration_ms` (5 키) | ✓ | GEM-21 ~ GEM-25 | slider |
| `seats` | ✗ | — | Rive artboard 소유 |

---

## 4. 파일 검증 순서

`.gfskin` 업로드 시 클라이언트(Team 1)와 서버(Team 2) 모두 동일 순서로 검증한다.

1. **ZIP 구조 검증**: `skin.json` + `skin.riv`가 루트에 존재
2. **`skin.json` JSON parse**: UTF-8 디코딩 + JSON 파싱
3. **JSON Schema validation**: `$id: https://ebs/schemas/gfskin-1.0.json`
4. **`skin.riv` Rive 파싱 가능성**: magic bytes 확인
5. **`cards/`, `assets/` 경로 참조 일관성**: `skin.json`이 참조하는 파일이 ZIP 내에 존재

실패 시 에러 응답 형식: `Graphic_Editor_API.md §1 Upload` (legacy-id: API-07) 참조.

---

## 5. 공유 스키마 접근 경로

JSON Schema 파일은 단일 소스(본 문서의 §2)에서 관리되며, 구현체는 다음 경로로 접근한다:

| 구현체 | 접근 방식 |
|--------|----------|
| Team 1 Flutter (클라이언트) | `schemas/gfskin-1.0.json` 을 Dart asset 로 번들 (`pubspec.yaml` assets) 또는 `dart_json_schema` 패키지로 컴파일 |
| Team 2 FastAPI (서버) | `schemas/gfskin-1.0.json` 파일 로드 (`fastjsonschema` 또는 `jsonschema` 컴파일) |
| Integration tests | 동일 파일 참조 |

세 경로 모두 동일 파일을 가리켜 스키마 드리프트를 방지한다.

---

## 6. 연관 문서

| 문서 | 관계 |
|------|------|
| `BS-07-03-skin-loading.md` | Overlay 로드 시점에 `.gfskin`을 in-memory 해제 |
| `BS-08-01-import-flow.md` | 클라이언트 업로드 FSM |
| `BS-08-02-metadata-editing.md` | PATCH API + 편집 가능 필드 매트릭스 |
| `Graphic_Editor_API.md` (legacy-id: API-07) | 8 엔드포인트 |
| `CCR-012` | 본 문서 신설 근거 |
