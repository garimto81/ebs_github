# coord-picker 이미지 분석 기반 글로벌 재설계 PRD

**버전**: 2.0.0 | **날짜**: 2026-02-23 | **상태**: Draft

---

## 1. 배경 및 목적

### 현황

`coord_picker.html`은 EBS WSOP 오버레이 이미지에서 UI 요소의 bounding box를 수작업 드래그로 정의하는 순수 HTML/CSS/JS 도구다. 현재 요소 목록(`ELEMENTS` 배열)이 파일 내부에 WSOP 11개 요소로 완전히 하드코딩되어 있어 다른 방송 프로젝트에서 재사용이 불가능하다.

기존 오버레이 좌표 워크플로우(CLAUDE.md):

```
Option A — OpenCV 자동 검출 (빠름, 근사값)
Option B — LabelMe 수동 어노테이션 (pixel-perfect)
```

`coord_picker.html`은 Option A/B의 중간에 위치하는 **Option C**로, 외부 Python 패키지(opencv, labelme) 없이 브라우저만으로 실행 가능한 수작업 어노테이션 방식이다. 그러나 현재는 공식 워크플로우에 포함되지 않고 WSOP 전용으로만 고정되어 있다.

### 기존 PRD v1.0.0의 한계

v1.0.0 설계는 WSOP 11개 요소를 외부 JSON 설정으로 분리하는 수준에 머물렀다. 핵심 문제인 "어떤 프로젝트에서 요소 수를 어떻게 결정하는가"를 사용자의 수동 판단에 의존했으며, 이미지 자체에서 정보를 추출하는 능력이 없었다.

| 항목 | v1.0.0 접근 | v2.0.0 접근 |
|------|------------|------------|
| 요소 수 결정 방식 | 사용자 수동 정의 | 이미지 자동 분석(Auto-Detect) |
| WSOP 요소 목록 위치 | HTML 내장 기본값 | 불러오기 전용 프리셋 파일 |
| 신규 프로젝트 진입점 | 처음부터 수동 입력 | 이미지 로드 후 자동 감지 |
| 적용 범위 | WSOP 종속 | 이미지가 있는 모든 방송 오버레이 |

### 재설계 방향

**핵심 전환**: WSOP 고정 도구 → 이미지 분석 기반 범용 도구

1. 이미지 로드 후 Canvas 2D API `getImageData`로 픽셀을 분석하여 요소 수(카운터 넘버)를 자동 감지
2. 감지된 요소 수를 기준으로 "Element 1", "Element 2" ... 동적 목록 자동 생성
3. 자동 감지 불가 시, 사용자가 숫자를 직접 입력하면 그 수만큼 빈 요소 목록 생성
4. 분석 결과를 `coord-picker-config.json`으로 저장하여 프로젝트 간 재사용
5. WSOP는 HTML 기본값이 아닌, 불러올 수 있는 프리셋 파일로만 존재

---

## 2. 요구사항

### A. 이미지 분석 — 핵심

| # | 요구사항 | 설명 |
|---|----------|------|
| R-01 | 자동 요소 감지 | 이미지 로드 시 Canvas `getImageData`로 픽셀 분석, 배경과 다른 직사각형 클러스터를 자동 감지한다. |
| R-02 | 감지 결과 표시 | 감지된 요소 수를 "N개 요소 감지됨" 형태로 상태바에 표시하고, "Element 1" ~ "Element N" 동적 목록을 자동 생성한다. |
| R-03 | 수동 카운트 입력 | 자동 감지 불가 또는 부정확 시, 사용자가 요소 수를 직접 숫자로 입력하면 해당 수만큼 빈 요소 목록을 생성한다. |
| R-04 | 감지 임계값 조절 | 슬라이더로 배경-전경 색차 임계값을 조절하여 감지 민감도를 실시간으로 변경할 수 있다. |
| R-05 | 감지 결과 시각화 | 자동 감지된 클러스터 영역을 Canvas 위에 반투명 하이라이트로 표시한다 (확인용). |

### B. 동적 요소 목록

| # | 요구사항 | 설명 |
|---|----------|------|
| R-06 | 요소 이름 인라인 편집 | 자동 생성된 "Element N" 이름을 더블클릭하면 인라인 편집 모드로 전환된다. Enter로 확정, Esc로 취소. |
| R-07 | 요소 추가 | [+ 요소 추가] 버튼으로 빈 요소를 수동 추가할 수 있다. |
| R-08 | 요소 삭제 | [×] 버튼으로 요소와 연결된 박스 데이터를 즉시 삭제한다. |
| R-09 | 색상 자동 배정 | 요소 생성 시 색상환 등간격(360 / N도 HSL)으로 고유 색상을 자동 배정한다. |
| R-10 | 요소 색상 수동 변경 | 색상 도트 클릭으로 `<input type="color">` color picker를 열어 색상을 수동 변경한다. |

### C. 설정 파일

| # | 요구사항 | 설명 |
|---|----------|------|
| R-11 | 설정 내보내기 | 현재 요소 목록을 `coord-picker-config.json`으로 다운로드한다. 박스 데이터는 포함하지 않는다. |
| R-12 | 설정 불러오기 | `<input type="file">`으로 기존 `coord-picker-config.json`을 불러와 요소 목록을 교체한다. WSOP 프리셋도 이 방식으로 로드한다. |
| R-13 | 설정 파일 스키마 정의 | `coord-picker-config.json` 포맷을 명확히 정의한다. |

### D. 워크플로우 통합

| # | 요구사항 | 설명 |
|---|----------|------|
| R-14 | 출력 포맷 완전 호환 | 기존 `overlay-anatomy-coords.json` 포맷(version, metadata, elements 배열)과 완전 호환한다. |
| R-15 | 상태바 동적 반영 | 상태바에 현재 요소 수, 감지 방법(자동/수동), 활성 설정 이름을 동적으로 표시한다. |
| R-16 | CLAUDE.md Option C 등록 | 워크플로우 문서에 Option C로 공식 등록한다. |

---

## 3. 기능 범위

### IN Scope

| 항목 | 상세 |
|------|------|
| Canvas getImageData 자동 분석 | 배경색 추출, 다운샘플링, BFS 클러스터링 |
| 감지 임계값 실시간 조절 | 슬라이더 UI, 결과 즉시 업데이트 |
| 수동 카운트 입력 모드 | 숫자 입력 후 빈 요소 목록 생성 |
| 동적 요소 목록 관리 | 추가, 삭제, 이름 인라인 편집, 색상 변경 |
| 색상 자동 배정 | 색상환 등간격 HSL 계산 |
| 설정 파일 내보내기/불러오기 | coord-picker-config.json (요소 목록 전용) |
| WSOP 프리셋 파일 제공 | wsop-preset.coord-picker-config.json (별도 파일로만 존재) |
| 기존 어노테이션 기능 유지 | 이미지 로드, 드래그 박스, JSON 내보내기/불러오기 |
| overlay-anatomy-coords.json 호환 | 기존 파이프라인 완전 호환 |
| CLAUDE.md Option C 등록 | 문서 업데이트 |

### OUT of Scope

| 항목 | 이유 |
|------|------|
| AI/ML 기반 객체 인식 | 외부 라이브러리 금지, 순수 JS 픽셀 분석만 허용 |
| 서버 저장/동기화 | file:// 프로토콜, 외부 서버 불가 |
| 다중 이미지 동시 작업 | 단일 세션 단일 이미지 도구 유지 |
| Undo/Redo | 현재 스코프 외 |
| 박스 크기 조절 핸들 | 재드래그로 재정의 방식 유지 |
| 다국어(i18n) | 한국어/영어 혼용 유지 |
| 요소 그룹핑/계층 구조 | 플랫 목록으로 충분 |
| WSOP HTML 내장 기본값 | v2.0에서 제거. 프리셋 파일로만 존재 |

---

## 4. 자동 분석 알고리즘 명세

### 4.1 개요

Canvas 2D API의 `getImageData`를 활용하여 이미지 픽셀을 직접 분석한다. 외부 라이브러리 없이 순수 JS로 구현하며, 속도를 위해 다운샘플링(블록 평균)을 적용한다.

```
이미지 로드
    |
    v
getImageData(0, 0, width, height)
    |
    v
다운샘플링 (8x8 블록 평균)
    |
    v
배경색 추출 (가장자리 픽셀 샘플링)
    |
    v
전경 블록 마킹 (delta > 임계값)
    |
    v
BFS 클러스터링 (연결된 전경 블록 묶기)
    |
    v
최소 크기 필터 (50x50px 미만 제거)
    |
    v
요소 후보 목록 반환 (N개)
    |
    v
"Element 1" ~ "Element N" 자동 생성
```

### 4.2 Step 1: 픽셀 데이터 취득

```javascript
const canvas = document.getElementById('mainCanvas');
const ctx = canvas.getContext('2d');
ctx.drawImage(img, 0, 0);
const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
const pixels = imageData.data; // [R,G,B,A, R,G,B,A, ...]
```

- `pixels` 배열은 RGBA 4채널, 총 `width * height * 4`개의 Uint8 값
- 픽셀 i의 색상: `pixels[i*4]` = R, `pixels[i*4+1]` = G, `pixels[i*4+2]` = B
- `file://` 프로토콜에서 로컬 이미지는 CORS 제한 없이 `getImageData` 접근 가능

### 4.3 Step 2: 다운샘플링 (블록 평균)

전체 픽셀을 8×8 블록으로 나누어 각 블록의 평균 RGB를 계산한다. 이미지 크기에 무관하게 처리 속도를 일정하게 유지한다.

```
의사코드:
BLOCK_SIZE = 8
gridW = ceil(imageWidth / BLOCK_SIZE)
gridH = ceil(imageHeight / BLOCK_SIZE)

for y in 0..gridH:
  for x in 0..gridW:
    blockPixels = pixels in rect(x*8, y*8, min(8, W-x*8), min(8, H-y*8))
    grid[y][x] = {
      r: mean(blockPixels.r),
      g: mean(blockPixels.g),
      b: mean(blockPixels.b)
    }
```

1920x1080 이미지 기준: 240x135 = 32,400 블록으로 축소 (원본 픽셀 2,073,600개 대비 약 64분의 1)

### 4.4 Step 3: 배경색 추출

이미지 가장자리(상단 2행, 하단 2행, 좌측 2열, 우측 2열) 블록의 RGB 중앙값(median)을 배경색으로 추정한다. 평균 대신 중앙값을 사용하는 이유는 코너에 UI 요소가 걸쳐있어도 영향을 최소화하기 위함이다.

```
의사코드:
edgeBlocks = []
edgeBlocks += grid[0][0..gridW]       // 상단 1행
edgeBlocks += grid[1][0..gridW]       // 상단 2행
edgeBlocks += grid[gridH-1][0..gridW] // 하단 1행
edgeBlocks += grid[gridH-2][0..gridW] // 하단 2행
edgeBlocks += grid[0..gridH][0]       // 좌측 1열
edgeBlocks += grid[0..gridH][1]       // 좌측 2열
edgeBlocks += grid[0..gridH][gridW-1] // 우측 1열
edgeBlocks += grid[0..gridH][gridW-2] // 우측 2열

bgColor = {
  r: median(edgeBlocks.map(b => b.r)),
  g: median(edgeBlocks.map(b => b.g)),
  b: median(edgeBlocks.map(b => b.b))
}
```

### 4.5 Step 4: 전경 블록 마킹

각 블록과 배경색의 차이를 RGB 가중치 유클리디안 거리로 계산한다. 인간 눈의 색 민감도 차이를 반영하여 G 채널에 높은 가중치를 부여한다.

```
의사코드:
function colorDelta(c1, c2):
  dr = c1.r - c2.r
  dg = c1.g - c2.g
  db = c1.b - c2.b
  return sqrt(2*dr*dr + 4*dg*dg + 3*db*db)
  // G 채널 가중치 x4: 인간 눈이 녹색에 가장 민감

THRESHOLD = 30  // 기본값, 슬라이더로 10~80 범위 조절

for y in 0..gridH:
  for x in 0..gridW:
    isForeground[y][x] = (colorDelta(grid[y][x], bgColor) > THRESHOLD)
```

**임계값 선택 기준**:

| 임계값 범위 | 효과 | 적합한 케이스 |
|------------|------|--------------|
| 10~20 (낮음) | 미세한 색차도 전경 분류, 노이즈 증가 | 배경과 유사한 반투명 오버레이 |
| 25~35 (기본) | 일반적인 오버레이 요소 감지 | 방송용 고대비 오버레이 |
| 40~80 (높음) | 뚜렷한 차이만 전경 분류, 요소 누락 위험 | 배경이 복잡한 이미지 |

### 4.6 Step 5: BFS 클러스터링

인접한 전경 블록을 연결하여 하나의 클러스터(요소 후보)로 묶는다. 4-방향 연결성 사용 (8-방향 연결 시 분리된 UI 요소가 하나로 합쳐지는 오류 발생).

```
의사코드:
visited = 2D boolean array (gridW x gridH), 초기값 false
clusters = []

for y in 0..gridH:
  for x in 0..gridW:
    if isForeground[y][x] and not visited[y][x]:
      cluster = BFS(x, y)
      if cluster is not null:
        clusters.append(cluster)

function BFS(startX, startY):
  queue = [(startX, startY)]
  cells = []
  while queue is not empty:
    (x, y) = queue.dequeue()
    if visited[y][x]: continue
    visited[y][x] = true
    cells.append((x, y))
    for (nx, ny) in [(x-1,y), (x+1,y), (x,y-1), (x,y+1)]:  // 4-방향
      if inBounds(nx, ny) and isForeground[ny][nx] and not visited[ny][nx]:
        queue.enqueue((nx, ny))
  return cells  // 클러스터 구성 블록 목록
```

### 4.7 Step 6: 최소 크기 필터링 및 bounding box 계산

노이즈 클러스터를 제거하고, 남은 클러스터를 원본 픽셀 좌표의 bounding box로 변환한다.

```
의사코드:
MIN_PIXEL_WIDTH = 50
MIN_PIXEL_HEIGHT = 50

validClusters = []
for i, cluster in enumerate(clusters):
  // 블록 좌표 → 원본 픽셀 좌표 역산
  minBlockX = min(cell.x for cell in cluster)
  minBlockY = min(cell.y for cell in cluster)
  maxBlockX = max(cell.x for cell in cluster)
  maxBlockY = max(cell.y for cell in cluster)

  bbox = {
    x: minBlockX * BLOCK_SIZE,
    y: minBlockY * BLOCK_SIZE,
    w: (maxBlockX - minBlockX + 1) * BLOCK_SIZE,
    h: (maxBlockY - minBlockY + 1) * BLOCK_SIZE
  }

  if bbox.w >= MIN_PIXEL_WIDTH and bbox.h >= MIN_PIXEL_HEIGHT:
    hue = (i * 360 / len(clusters)) % 360  // 색상환 등간격
    validClusters.append({
      id: i + 1,
      name: "Element " + (i + 1),
      bbox: bbox,
      color: "hsl(" + hue + ", 80%, 55%)"
    })
```

### 4.8 감지 정확도 한계

| 한계 상황 | 설명 | 권장 처리 방법 |
|-----------|------|--------------|
| 배경이 단색이 아님 | 그라디언트/이미지 배경은 가장자리 중앙값이 실제 배경을 대표하지 못함 | 임계값 낮추기 또는 수동 카운트 입력 |
| 배경과 유사한 색상의 요소 | 투명 패널, 배경색과 비슷한 UI 요소는 미감지 | 임계값 낮추기 (10~20) |
| 인접 요소 병합 | 붙어있는 두 요소가 하나의 클러스터로 합쳐짐 | 감지 후 수동 요소 추가로 보완 |
| 과다 감지 | 복잡한 텍스처 이미지에서 노이즈 클러스터 다수 생성 | 임계값 높이기 + 불필요 요소 [×] 삭제 |
| 반투명 오버레이 | 알파값이 낮은 반투명 요소는 배경색과 혼합되어 색차 감소 | 임계값 낮추기 (10~15) |
| 이미지 압축 아티팩트 | JPEG 압축 노이즈로 인한 작은 클러스터 다수 생성 | 최소 크기 필터를 100px로 상향 (코드 조정) |

### 4.9 수동 보정 절차

자동 감지 결과가 부정확할 때 다음 단계로 수동 보정한다:

1. **Canvas 위 하이라이트 확인**: 반투명 색상 박스로 감지 영역을 시각적으로 확인
2. **임계값 슬라이더 조절**: 좌(낮춤, 더 많이 감지) 또는 우(높임, 적게 감지)로 조절 후 결과 확인
3. **과다 감지 처리**: 노이즈 요소를 요소 목록에서 [×]로 개별 삭제
4. **미감지 보완**: [+ 요소 추가]로 누락된 요소를 수동 추가, 드래그로 박스 정의
5. **전체 재생성**: 수동 카운트 입력 필드에 정확한 수를 입력 → "N개 생성" 클릭 → 목록 교체
6. **이름 편집**: "Element N" 이름을 더블클릭하여 실제 요소 이름으로 편집

---

## 5. 수동 카운트 입력 모드

자동 분석 버튼 옆에 수동 입력 필드를 항상 표시한다. 자동 감지와 수동 입력은 배타적이지 않다.

```
+--------------------------------------------------+
| [자동 분석]   요소 수: [  5  ] [N개 생성]         |
| 임계값: [====|====] 30         [재분석]           |
+--------------------------------------------------+
```

수동 입력 시 동작:

1. 숫자 입력 (1~50 범위)
2. [N개 생성] 클릭
3. 확인 다이얼로그: "기존 요소 목록을 교체하시겠습니까?"
   - 교체: 기존 목록 전체를 "Element 1" ~ "Element N"으로 대체
   - 추가: 기존 목록 끝에 "Element N+1" ~ "Element N+M" 추가
4. 색상환 등간격으로 새 요소들에 색상 자동 배정

---

## 6. 설정 파일 스키마

### 6.1 coord-picker-config.json

```json
{
  "schema_version": "2.0",
  "preset_name": "Custom Project A",
  "description": "자동 분석 결과",
  "created_at": "2026-02-23T00:00:00Z",
  "detect_method": "auto",
  "detect_threshold": 30,
  "elements": [
    {
      "id": 1,
      "name": "Element 1",
      "color": "#FF5252",
      "gfx_type": "",
      "protocol_cmd": ""
    }
  ]
}
```

| 필드 | 필수 | 설명 |
|------|------|------|
| schema_version | 필수 | 포맷 버전 ("2.0") |
| preset_name | 필수 | 설정 이름 (상태바/타이틀 표시용) |
| description | 선택 | 설명 텍스트 |
| created_at | 선택 | 생성 시각 (ISO 8601) |
| detect_method | 선택 | "auto" 또는 "manual" |
| detect_threshold | 선택 | 자동 분석 시 사용된 임계값 (재현용) |
| elements | 필수 | 요소 배열 |
| elements[].id | 필수 | 1부터 단조 증가 정수 |
| elements[].name | 필수 | 요소 이름 |
| elements[].color | 필수 | HEX 색상 코드 |
| elements[].gfx_type | 선택 | 그래픽 타입 메타데이터 (WSOP 호환용) |
| elements[].protocol_cmd | 선택 | 프로토콜 명령어 메타데이터 (WSOP 호환용) |

**박스 데이터(`box`)는 포함하지 않는다.** 박스 데이터는 `overlay-anatomy-coords.json`에만 저장된다.

### 6.2 WSOP 프리셋 파일 정책

`wsop-preset.coord-picker-config.json`은 `scripts/` 폴더에 별도 파일로 제공한다. `coord_picker.html`에 내장하지 않는다. [설정 불러오기] 버튼으로 로드한다.

이 정책으로 인한 변화:

- 기존: HTML 로드 시 WSOP 11개 요소가 자동으로 표시됨
- 변경: HTML 로드 시 요소 목록 비어있음 (또는 마지막 사용 설정 복원)
- WSOP 작업 시: [설정 불러오기] → wsop-preset.coord-picker-config.json 선택

---

## 7. 비기능 요구사항

### 7.1 기술 스택 제약

| 항목 | 요구사항 |
|------|----------|
| 런타임 | 순수 HTML/CSS/JS — 외부 라이브러리(npm, CDN) 없음 |
| 프로토콜 | `file://`에서 직접 실행 가능 (로컬 서버 불필요) |
| 브라우저 API | Canvas 2D, FileReader, Blob, getImageData |
| 단일 파일 | 모든 CSS/JS가 하나의 `.html` 파일에 포함 |

### 7.2 성능

| 항목 | 요구사항 |
|------|----------|
| 자동 분석 처리 시간 | 1920x1080 이미지 기준 3초 이내 (8x8 다운샘플링 적용) |
| 임계값 재분석 반응 | 재분석 버튼 클릭 후 결과 업데이트 1초 이내 |
| 드래그 반응 | mousemove 이벤트 처리 16ms 이하 (60fps 목표) |
| 요소 목록 렌더링 | 50개 이하에서 지연 없음 |

### 7.3 호환성

| 항목 | 요구사항 |
|------|----------|
| 브라우저 | Chrome 110+, Edge 110+ |
| 화면 해상도 | 1920x1080 이상에서 레이아웃 깨짐 없음 |
| 운영체제 | Windows 10/11 (file:// 직접 열기) |

---

## 8. 제약사항

### 8.1 기술적 제약

| 제약 | 내용 |
|------|------|
| CORS 제한 | `file://` 프로토콜에서 `getImageData`는 동일 로컬 이미지만 허용. 반드시 `<input type="file">`으로 로드. |
| FileReader 보안 | 외부 설정 파일 로드는 `<input type="file">` 통해서만 가능. 경로 직접 입력 불가. |
| localStorage | `file://` 프로토콜에서 브라우저별 동작 차이. 세션 내 상태 유지에만 사용, 영구 저장 미보장. |

### 8.2 설계 제약

| 제약 | 내용 |
|------|------|
| overlay-anatomy-coords.json 포맷 불변 | `version`, `metadata`, `elements` 최상위 키와 각 요소의 `id`, `name`, `box`, `gfx_type`, `protocol_cmd`, `defined` 필드 변경 불가. |
| Python 스크립트 수정 금지 | `annotate_anatomy.py`, `labelme2anatomy.py` 등 기존 스크립트는 이번 범위에서 수정하지 않음. |
| 단일 파일 원칙 | `coord_picker.html`은 반드시 단일 파일 유지. `coord-picker-config.json`은 외부 파일. |

---

## 9. 우선순위

### P0 — Must Have (핵심 기능)

| # | 요구사항 | 근거 |
|---|----------|------|
| R-01 | 자동 요소 감지 | 재설계의 핵심 컨셉. 이 기능 없으면 v2.0 목적 불성립. |
| R-02 | 감지 결과 표시 및 목록 자동 생성 | 자동 감지 결과를 사용자에게 전달하는 핵심 UI. |
| R-03 | 수동 카운트 입력 | 자동 감지 실패 시 fallback. 사용성 보장. |
| R-09 | 색상 자동 배정 | 요소 시각 구분의 기본 조건. |
| R-14 | 출력 포맷 완전 호환 | 기존 파이프라인 파괴 금지. |

### P1 — Should Have (주요 기능)

| # | 요구사항 | 근거 |
|---|----------|------|
| R-04 | 감지 임계값 조절 | 다양한 이미지에서 최적 결과를 얻기 위한 필수 도구. |
| R-05 | 감지 결과 시각화 | 사용자가 감지 결과를 신뢰할 수 있는 근거. |
| R-06 | 요소 이름 인라인 편집 | "Element 1" → 실제 이름 변환. 실무 사용의 핵심 단계. |
| R-07 | 요소 추가 | 미감지 요소 수동 보완 수단. |
| R-08 | 요소 삭제 | 과다 감지 요소 제거 수단. |
| R-11 | 설정 내보내기 | 프로젝트 재사용을 위한 저장 수단. |
| R-12 | 설정 불러오기 | WSOP 프리셋 등 기존 설정 로드. |

### P2 — Nice to Have (편의 기능)

| # | 요구사항 | 근거 |
|---|----------|------|
| R-10 | 요소 색상 수동 변경 | 시각적 구분 자유도. 자동 배정으로 대체 가능. |
| R-13 | 설정 파일 스키마 정의 | 문서화. 팀 간 호환 기준. |
| R-15 | 상태바 동적 반영 | UX 개선. 핵심 기능과 무관. |
| R-16 | CLAUDE.md Option C 등록 | 문서화. 도구 자체 기능과 무관. |

---

## 10. CLAUDE.md Option C 명세

`C:/claude/ebs_reverse/CLAUDE.md`의 "Overlay Anatomy Coordinates Workflow" 섹션에 아래 내용을 추가한다.

```markdown
### Option C — coord_picker.html 이미지 분석 기반 어노테이션 (외부 패키지 없음, 범용)

브라우저에서 직접 실행. 이미지 로드 후 자동 요소 감지, 또는 기존 설정 파일 로드.

1. `scripts/coord_picker.html`을 Chrome에서 열기 (file:// 직접)
2. [파일 열기] → 오버레이 PNG 선택
3. 이미지 로드 후 자동 분석 실행 → "N개 요소 감지됨" 확인
   - 정확도 부족 시: 임계값 슬라이더 조절 → [재분석]
   - 완전 수동 모드: "요소 수" 입력 → [N개 생성]
   - WSOP 작업 시: [설정 불러오기] → wsop-preset.coord-picker-config.json 선택
4. 감지된 요소 이름을 더블클릭하여 실제 이름으로 편집
5. 각 요소 클릭 후 Canvas에서 드래그로 bounding box 정의
6. [JSON 내보내기] → overlay-anatomy-coords.json 저장
7. docs/01-plan/data/에 배치 후 python scripts/annotate_anatomy.py 실행

설정 저장: [설정 내보내기] → coord-picker-config.json (다음 프로젝트에서 재사용 가능)
```

---

## 11. 용어 정의

| 용어 | 정의 |
|------|------|
| 카운터 넘버 | 이미지에서 감지된 UI 요소의 수. 자동 분석 또는 수동 입력으로 결정됨. |
| Auto-Detect | Canvas getImageData + BFS 클러스터링으로 이미지에서 자동으로 UI 요소 후보를 감지하는 기능. |
| delta (색차) | 두 색상 간의 지각적 차이를 나타내는 값. 이 PRD에서는 RGB 가중치 유클리디안 거리를 사용. |
| 전경 블록 | 배경색과의 색차가 임계값을 초과하는 다운샘플링 블록. UI 요소 후보로 마킹됨. |
| BFS 클러스터링 | 인접한 전경 블록을 너비 우선 탐색으로 연결하여 하나의 요소 후보로 묶는 알고리즘. |
| 클러스터 | BFS로 연결된 전경 블록의 집합. 최소 크기 필터 통과 시 요소 후보가 됨. |
| ELEMENTS | 어노테이션 대상 UI 요소 목록. 자동 감지 또는 수동 정의. |
| coord-picker-config.json | 요소 목록 전용 설정 파일. 박스 데이터 미포함. 프로젝트 간 재사용 가능. |
| overlay-anatomy-coords.json | 박스 좌표를 포함한 기존 출력 포맷. annotate_anatomy.py 등 기존 파이프라인이 소비. |
| WSOP 프리셋 | wsop-preset.coord-picker-config.json. 11개 WSOP 요소 정의 파일. HTML 기본값이 아닌 불러오기 전용. |
