---
title: Examples
owner: conductor
tier: internal
last-updated: 2026-04-20
mirror: none
---

# examples/

EBS 참조 예제 파일 모음.

## 파일 목록

| 파일 | 용도 | 관련 SG |
|------|------|---------|
| `gfskin-manifest-example.json` | `.gfskin` ZIP 내부 `manifest.json` 예시 (schema 검증 통과) | SG-004 |

## .gfskin 샘플 ZIP 구성 (참조)

실제 `.gfskin` 은 ZIP 컨테이너입니다. CLI 로 생성 예시:

```bash
# 1. 작업 디렉토리 구성
mkdir default_skin
cd default_skin
cp ../docs/examples/gfskin-manifest-example.json manifest.json
# overlay.riv  ← Rive 에디터에서 export (placeholder 필요)
# preview.png  ← 512x288 썸네일
mkdir -p assets/audio assets/fonts i18n
# i18n/{ko,en,es}.json 추가

# 2. ZIP 패키징 (.gfskin 확장자)
zip -r ../default.gfskin manifest.json overlay.riv preview.png assets/ i18n/

# 3. 검증
python -c "
import json, zipfile, jsonschema
with zipfile.ZipFile('../default.gfskin') as z:
    m = json.loads(z.read('manifest.json'))
    s = json.loads(open('schemas/gfskin-manifest-v1.json').read())
    jsonschema.validate(m, s)
print('OK')
"
```

## manifest.json 스키마 검증

```bash
# python 예시
import jsonschema
schema = json.load(open('schemas/gfskin-manifest-v1.json'))
manifest = json.load(open('docs/examples/gfskin-manifest-example.json'))
jsonschema.validate(manifest, schema)  # 통과해야 함
```

## 관련

- `schemas/gfskin-manifest-v1.json` — JSON Schema (SG-004 SSOT)
- `docs/4. Operations/Conductor_Backlog/SG-004-gfskin-zip-format.md` — 포맷 결정 배경
- `docs/2. Development/2.2 Backend/Database/` — DATA-07 (team2 실구현)
- `docs/2. Development/2.1 Frontend/Graphic_Editor/` — Import 플로우 (team1)
- `docs/2. Development/2.4 Command Center/Overlay/` — Skin Consumer (team4)
