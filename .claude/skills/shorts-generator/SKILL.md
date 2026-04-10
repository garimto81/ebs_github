---
name: shorts-generator
description: >
  쇼츠 영상 생성 통합 Skill. Claude Vision으로 이미지 분석,
  Phase 분류, 자막 생성, TTS 음성, FFmpeg 영상 합성 자동화.
version: 2.0.0

triggers:
  keywords:
    - "shorts"
    - "쇼츠"
    - "영상 생성"
    - "마케팅 영상"
    - "휠 복원 영상"
  file_patterns:
    - "**/shorts-generator/**"
    - "**/output/*.mp4"
  context:
    - "쇼츠 영상 제작"
    - "이미지 기반 영상 생성"
    - "마케팅 콘텐츠 제작"

capabilities:
  - list_groups
  - list_photos
  - analyze_images_claude
  - generate_subtitles
  - generate_tts
  - create_video
  - batch_workflow

model_preference: opus
auto_trigger: false
token_budget: 5000
---

# Shorts Generator Skill

PocketBase에서 사진을 가져와 마케팅용 쇼츠 영상을 생성합니다.
Claude Read 도구로 이미지를 직접 분석하여 자막과 Phase를 생성합니다.

## 워크플로우

### Phase 1: 사진 다운로드

PocketBase에서 그룹별 사진을 다운로드합니다.

```bash
node .claude/skills/shorts-generator/scripts/download-photos.js <group_id> --limit=50
```

**출력:**
```json
{
  "count": 15,
  "files": ["l7v0rfmav504yup.jpg", "49zhdkcixcjmgos.jpg", ...]
}
```

### Phase 2: Claude Vision 분석

각 이미지를 Read 도구로 분석합니다.

**이미지 분석 방법:**
```
Read("temp/l7v0rfmav504yup.jpg")
```

**분석 프롬프트:**
```
이 휠 복원 작업 이미지를 분석하세요.

JSON 형식으로 반환:
{
  "phase": "overview|before|process|after",
  "subtitle": "15자 이내 마케팅 문구",
  "confidence": 0.0-1.0
}

Phase 분류 기준:
- overview: 차량 전체 모습, 작업장 전경
- before: 손상/오염 상태, 스크래치, 브레이크 더스트
- process: 작업 중, 세척, 도장, 연마
- after: 복원 완료, 깨끗한 상태, 광택
```

**분석 결과 수집:**
모든 이미지 분석 결과를 배열로 수집:
```json
{
  "subtitles": [
    {
      "id": "l7v0rfmav504yup",
      "file": "l7v0rfmav504yup.jpg",
      "phase": "after",
      "subtitle": "6시간의 정성이 담긴 결과",
      "confidence": 0.95
    },
    ...
  ]
}
```

### Phase 3: 결과 저장

분석 결과를 JSON 파일로 저장합니다.

```bash
node .claude/skills/shorts-generator/scripts/save-subtitles.js --input='{"subtitles":[...]}'
```

**출력:**
- `output/subtitles.json` 파일 생성
- Phase 순서로 자동 정렬 (overview → before → process → after)

### Phase 4: 영상 생성

기존 CLI를 호출하여 영상을 생성합니다.

```bash
node src/index.js create -g <group_id> --auto -n 50 --subtitle-json ./output/subtitles.json --tts
```

**주요 옵션:**
- `--auto`: 대화형 프롬프트 생략
- `-n 50`: 그룹 전체 사진 사용
- `--subtitle-json`: Claude Vision 자막 적용
- `--tts`: TTS 음성 생성
- `--tts-voice sunhi`: 음성 선택 (sunhi/hyunsu/jimin 등)

### Phase 5: 결과 보고

생성된 영상 정보를 보고합니다.

| 항목 | 값 |
|------|-----|
| 출력 파일 | `output/shorts_*.mp4` |
| 해상도 | 1080x1920 |
| 코덱 | H.264 High Profile |
| AI 모델 | Claude Opus 4.5 |

## Phase 분류 기준

| Phase | 시각적 특징 | 자막 톤 |
|-------|------------|---------|
| **overview** | 차량 전체, 작업장 전경 | 소개, 기대감 |
| **before** | 손상, 스크래치, 오염 | 문제 인식 |
| **process** | 세척, 연마, 도장 | 전문성, 꼼꼼함 |
| **after** | 깨끗, 광택, 완성 | 결과, 만족감 |

## 자막 작성 규칙

1. **15자 이내** - 한글 기준
2. **순한글 사용** - 외래어 최소화
3. **Phase에 맞는 톤** - before는 손상, after는 완성
4. **다양한 표현** - 동일 패턴 반복 금지

**예시:**

| Phase | 좋은 예 | 나쁜 예 |
|-------|---------|---------|
| overview | "오늘의 주인공, 마이바흐 GLS" | "차량입니다" |
| before | "브레이크 더스트와 스크래치 가득" | "완벽한 휠 광택" |
| process | "꼼꼼한 세척이 기본입니다" | "정밀 복원 완료" |
| after | "6시간의 정성이 담긴 결과" | "정밀 복원으로 완성된 휠" |

## 관련 파일

| 파일 | 설명 |
|------|------|
| `src/index.js` | CLI 진입점 (영상 생성) |
| `src/api/pocketbase.js` | PocketBase API |
| `src/video/generator.js` | FFmpeg 파이프라인 |
| `src/audio/tts.js` | Edge TTS 음성 생성 |
| `scripts/download-photos.js` | 사진 다운로드 래퍼 |
| `scripts/save-subtitles.js` | 자막 저장 래퍼 |

## 주의사항

1. **이미지 수 제한**: 한 번에 최대 20개 권장 (토큰 제한)
2. **이미지 크기**: 큰 이미지는 자동으로 리사이즈됨
3. **지원 형식**: JPG, PNG, WebP
4. **temp 폴더**: 분석 후 자동 정리되지 않음
