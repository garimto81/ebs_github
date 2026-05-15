---
title: CR-conductor-20260410-gfskin-format-unify
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-conductor-20260410-gfskin-format-unify
confluence-page-id: 3818816643
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818816643/EBS+CR-conductor-20260410-gfskin-format-unify
mirror: none
---

# CCR-DRAFT: .gfskin ZIP 포맷 단일화 및 DATA-07 신설

- **제안팀**: conductor
- **제안일**: 2026-04-10
- **영향팀**: [team1, team2, team4]
- **변경 대상 파일**:
  - contracts/data/DATA-07-gfskin-schema.md (add)
  - contracts/specs/BS-07-overlay/BS-07-03-skin-loading.md (modify — §2.1, §6.1)
- **변경 유형**: add + modify
- **변경 근거**: `BS-07-03-skin-loading.md §2.1`은 스킨을 "디렉토리 기반 (skin.riv + skin.skin.json + cards/ + assets/)"으로 정의하지만, `team4-cc/ui-design/UI-06-skin-editor.md:89`는 `.gfskin (ZIP)` 포맷을 가정. 두 포맷은 호환되지 않아 Overlay 런타임(디렉토리 로드)과 GE 산출물(ZIP 업로드)이 불일치. 본 CCR은 `.gfskin` = ZIP 컨테이너로 단일화하고, Overlay가 로드 시점에 압축 해제 또는 in-memory 스트리밍으로 처리하도록 정렬한다. JSON Schema를 DATA-07에 최상위 계약으로 신설한다.

## 변경 요약

1. `.gfskin` = ZIP(`skin.riv` + `skin.json` + `cards/52+back` + `assets/`) 공식 확정
2. `BS-07-03 §2.1` 디렉토리 구조를 "`.gfskin` 압축 해제 후 내부 레이아웃"으로 재정의
3. `DATA-07-gfskin-schema.md` 신설: JSON Schema Draft-07로 `skin.json` 전체 스키마 명세
4. Overlay 로드 경로: `.gfskin` ZIP → in-memory 압축 해제 → `skin.riv` + `skin.json` 읽기 → Rive 렌더러 초기화
5. 클라이언트(Team 1) JSON Schema 검증 + 서버(Team 2) 검증에서 **동일 `$id` 스키마 공유**

## Diff 초안

### A. `contracts/data/DATA-07-gfskin-schema.md` (신설 골격)

````markdown
# DATA-07 .gfskin Schema — Graphic Editor 아티팩트 포맷 SSOT

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | .gfskin ZIP 컨테이너 + skin.json JSON Schema Draft-07 |

## 1. .gfskin ZIP 구조

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

## 2. skin.json JSON Schema ($id: https://ebs/schemas/gfskin-1.0.json)

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
      "required": ["background", "text_primary", "text_secondary", "badge_check", "badge_fold", "badge_bet", "badge_call", "badge_allin"]
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
        "description": "Seat position is owned by Rive artboard. This array only exists for compatibility.",
        "properties": {
          "seat_index": { "type": "integer", "minimum": 0, "maximum": 9 }
        }
      }
    }
  }
}
```

## 3. 편집 가능 / 읽기 전용 매트릭스 (GEM-* 요구사항)

| skin.json property | 편집 가능? | GEM ID |
|--------------------|:---------:|--------|
| skin_name | ✓ | GEM-01 |
| version | ✓ (semver) | GEM-02 |
| author | ✓ | GEM-03 |
| created_at | ✗ (자동) | - |
| modified_at | ✗ (자동) | - |
| resolution.width/height | ✓ (enum) | GEM-04 |
| background.type/color/chromakey_color | ✓ | GEM-05 |
| colors.* (9개 키) | ✓ (color picker) | GEM-06~14 |
| fonts.*.family/size/weight (6개 키) | ✓ | GEM-15~20 |
| animations.*_duration_ms (5개 키) | ✓ (slider) | GEM-21~25 |
| seats | ✗ (Rive artboard 소유) | - |

## 4. 파일 검증 순서

1. ZIP 구조 검증 (`skin.json` + `skin.riv` 필수)
2. `skin.json` JSON parse
3. JSON Schema validation ($id: https://ebs/schemas/gfskin-1.0.json)
4. `skin.riv` Rive 파싱 가능성 (magic bytes)
5. `cards/`, `assets/` 경로 참조 일관성

## 5. 공유 스키마 접근 경로

- 클라이언트 (Team 1 Quasar): `import schema from '@ebs/schemas/gfskin-1.0.json'` (monorepo symlink 또는 npm workspace)
- 서버 (Team 2 FastAPI): `schemas/gfskin-1.0.json` 파일 로드 (fastjsonschema 컴파일)
- 통합 테스트: 동일 파일 참조
````

### B. `contracts/specs/BS-07-overlay/BS-07-03-skin-loading.md` §2.1 수정

```diff
 ## 2. 스킨 파일 구조

-### 2.1 디렉토리 구조
-
-```
-skins/
-  wsop-2026-default/
-    skin.riv              ← Rive 애니메이션 파일
-    skin.skin.json        ← 메타데이터 (레이아웃, 색상, 폰트)
-    cards/                ← 카드 이미지 에셋 (52장 + 뒷면)
-    assets/               ← 기타 에셋 (배경, 아이콘)
-```
+### 2.1 배포 포맷: .gfskin ZIP
+
+스킨은 `.gfskin` 확장자의 ZIP 컨테이너로 배포된다. 상세 스키마는 `DATA-07-gfskin-schema.md` 참조.
+
+```
+my-skin.gfskin (ZIP)
+├── skin.json          ← 메타데이터 (필수, 루트)
+├── skin.riv           ← Rive 애니메이션 파일 (필수)
+├── cards/             ← 카드 이미지 (선택)
+│   └── As.png ... back.png
+└── assets/            ← 기타 에셋 (선택)
+```
+
+Overlay 로드 시에는 `.gfskin`을 in-memory 압축 해제 후 `skin.json` + `skin.riv`를 읽는다. 로컬 캐시(`skins/` 디렉토리)는 구현 세부사항이며 계약 범위가 아니다.
```

### C. `contracts/specs/BS-07-overlay/BS-07-03-skin-loading.md` §6.1 수정

```diff
 ### 6.1 필수 검증 항목

 | 검증 항목 | 조건 | 실패 시 |
 |----------|------|--------|
-| .skin.json 존재 | 파일 존재 + JSON 파싱 성공 | 폴백 전환 |
-| .riv 존재 | 파일 존재 + Rive 파싱 성공 | 폴백 전환 |
+| ZIP 구조 | `.gfskin` 내부에 `skin.json` + `skin.riv` 존재 | 폴백 전환 |
+| JSON Schema | DATA-07 스키마($id: gfskin-1.0.json) 통과 | 폴백 전환 |
+| Rive 파싱 | skin.riv 파싱 성공 | 폴백 전환 |
 | 해상도 일치 | skin resolution == output resolution | 경고 로그 |
-| 좌석 수 | seats 배열 10개 (0~9) | 폴백 전환 |
-| 카드 이미지 | 52장 + back 이미지 존재 | 누락분만 기본 대체 |
+| 카드 이미지 | cards/ 엔트리 존재 시 52+back 검증 | 누락분 기본 대체 |
```

## 영향 분석

| 팀 | 영향 | 공수 |
|----|------|------|
| Team 1 | ajv-js로 DATA-07 스키마 로드, 클라이언트 검증 구현 | 0.5주 |
| Team 2 | fastjsonschema로 DATA-07 스키마 서버 검증, ZIP 파싱 | 0.5주 |
| Team 4 | Overlay 로드 경로 변경: 디렉토리 → in-memory ZIP 압축 해제. Dart `archive` 패키지 사용 | 0.5주 |

## 대안 검토

1. **기존 디렉토리 포맷 유지**: GE가 생성한 ZIP을 서버가 풀어서 디렉토리로 저장 후 Overlay가 읽음. 단점: 서버 스토리지 구조 복잡, 버전 관리 어려움. ❌
2. **본 CCR (.gfskin ZIP 단일화)**: 단일 아티팩트, 버전 관리 쉬움, 배포 간단. ✅

## 검증 방법

1. DATA-07 파일 존재 및 JSON Schema `$id` 정합성
2. BS-07-03 §2.1 `.gfskin` 각주 포함
3. Team 1/2/4 각 구현체가 DATA-07 스키마를 import (파일 경로 동일)
4. Integration test `01-upload-download.http`에서 `.gfskin` 업로드 후 Overlay 로드 성공

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 4 Overlay 로드 경로 변경 수용
- [ ] Team 2 JSON Schema 서버 검증 라이브러리 선택 확정
- [ ] Team 1 ajv-js 번들 크기 수용 확인 (~50KB)
