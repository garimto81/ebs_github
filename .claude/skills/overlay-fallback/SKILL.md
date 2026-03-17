---
name: overlay-fallback
description: >
  This skill should be used when image analysis or overlay element detection fails, guiding users to coord_picker.html manual annotation tool.
version: 1.0.0
triggers:
  keywords:
    - "수동 어노테이션"
    - "coord picker"
    - "좌표 직접"
    - "요소 감지 실패"
    - "overlay fallback"
    - "오버레이 좌표 직접"
auto_trigger: true
---

# /overlay-fallback

## 목적

이미지 분석 또는 오버레이 요소 감지가 실패했을 때 자동으로 Fallback 경로를 제공한다.
OCR 신뢰도가 낮거나 OpenCV 자동 감지가 0개를 반환하는 경우, 사용자를
`coord_picker.html` 브라우저 기반 수동 어노테이션 도구로 안내한다.
외부 Python 패키지(opencv, labelme) 없이 `file://` 프로토콜로 즉시 실행 가능하며,
JSON 내보내기로 `overlay-anatomy-coords.json`을 생성한다.

## 자동 트리거 조건

| ID | 조건 | 감지 방법 |
|----|------|-----------|
| T-1 | OCR 신뢰도 < 30% 또는 추출 텍스트 0개 | OCR 출력 파싱 |
| T-2 | OpenCV 오버레이 감지 결과 0개 | 스크립트 반환값 |
| T-3 | 사용자 키워드 입력 | "수동 어노테이션", "coord picker", "좌표 직접", "요소 감지 실패" |
| T-4 | 분석 실패 메시지 감지 | "요소를 찾을 수 없음", "감지 실패", "0개 요소" 패턴 |
| T-5 | Hybrid Pipeline Layer1 결과 0개 | --mode coords/ui/full 결과 파싱 |

## 실행 절차

### Step 1: Fallback 사유 출력

어떤 트리거 조건(T-1~T-5)으로 Fallback이 활성화됐는지 명시한다. 예시:

```
[overlay-fallback] T-2 트리거: OpenCV 자동 감지 결과 0개
수동 어노테이션 도구(coord_picker.html)로 안내합니다.
```

### Step 2: coord_picker.html 경로 안내

절대 경로: `C:\claude\ebs_reverse\scripts\coord_picker.html`

브라우저 열기 명령 (OS별):
- Windows: `start "" "C:\claude\ebs_reverse\scripts\coord_picker.html"`
- macOS: `open "/path/to/coord_picker.html"`
- Linux: `xdg-open "/path/to/coord_picker.html"`

> 범용 사용 시: 프로젝트에 맞는 절대 경로로 교체한다.

### Step 3: 단계별 사용법 안내 (5단계)

1. 브라우저에서 `coord_picker.html` 열기 (더블클릭 또는 위 명령어 실행)
2. [파일 열기] 버튼으로 오버레이 PNG 이미지 로드
3. [자동 분석] 클릭(자동) 또는 요소 수 입력 후 [N개 생성](수동)
4. Canvas에서 각 요소 드래그로 어노테이션
5. [JSON 내보내기] 클릭

### Step 4: JSON 저장 위치 안내

기본 저장 경로: `docs/01-plan/data/overlay-anatomy-coords.json`

> 범용 사용 시: 프로젝트의 좌표 JSON 저장 경로로 조정한다.

### Step 5: 다음 단계 안내

JSON 생성 후 아래 명령어로 주석 이미지를 재생성한다:

```bash
python scripts/annotate_anatomy.py
# 출력: docs/01-plan/images/prd/overlay-anatomy.png
```

## 범용 사용 시 주의

EBS 외 다른 프로젝트에서 사용 시 아래 항목을 프로젝트에 맞게 조정한다:

| 항목 | 기본값 (EBS) | 조정 방법 |
|------|-------------|-----------|
| coord_picker.html 경로 | `C:\claude\ebs_reverse\scripts\coord_picker.html` | 프로젝트 경로로 교체 |
| JSON 출력 경로 | `docs/01-plan/data/overlay-anatomy-coords.json` | 프로젝트 경로로 교체 |
| annotate_anatomy.py 경로 | `scripts/annotate_anatomy.py` | 프로젝트 경로로 교체 |

## 금지 사항

- 파일 자동 생성 금지 (안내 텍스트 출력만 담당)
- 명령어 자동 실행 금지 (사용자가 직접 수행)
- `coord_picker.html` 파일 자체 수정 금지
