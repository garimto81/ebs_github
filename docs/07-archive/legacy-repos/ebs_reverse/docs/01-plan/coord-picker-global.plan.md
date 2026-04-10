# coord-picker 이미지 분석 기반 글로벌 재설계 구현 계획

**버전**: 1.0.0 | **날짜**: 2026-02-23 | **기반 PRD**: coord-picker-global.prd.md v2.0.0
**복잡도**: STANDARD | **우선순위**: P0 → P1 → P2

---

## 1. 배경 및 목표

### 요청 내용

`C:/claude/ebs_reverse/scripts/coord_picker.html`을 WSOP 전용 하드코딩 도구에서
이미지 분석 기반 범용 어노테이션 도구로 재구현한다.

### 해결하려는 문제

| 문제 | 현황 | 목표 |
|------|------|------|
| 요소 목록 고정 | WSOP 10개 요소 하드코딩 (`const ELEMENTS`) | 이미지 분석으로 자동 감지 후 동적 생성 |
| 프로젝트 종속성 | 새 프로젝트마다 HTML 수정 필요 | 설정 파일(JSON) 불러오기로 교체 |
| 도구 위치 미등록 | CLAUDE.md에 Option A/B만 존재 | Option C로 공식 워크플로우 등록 |
| WSOP 기본값 | 로드 즉시 WSOP 요소 표시 | 로드 시 빈 목록, WSOP는 프리셋 파일로만 |

---

## 2. 구현 범위

### IN Scope — 변경 내용

| 항목 | 세부 내용 |
|------|----------|
| Canvas 이미지 분석 | getImageData + 다운샘플링 + BFS 클러스터링 |
| 감지 임계값 슬라이더 | 색차 임계값 10~80, 기본값 30 |
| 감지 결과 시각화 | Canvas 반투명 하이라이트 오버레이 |
| 수동 카운트 입력 | 숫자 입력 → [N개 생성] → 확인 다이얼로그 |
| 동적 요소 목록 | 추가/삭제/인라인 편집/색상 변경 |
| 색상 자동 배정 | HSL 색상환 등간격 (360/N도) |
| 설정 파일 내보내기 | coord-picker-config.json (요소 목록 전용) |
| 설정 파일 불러오기 | input[type=file]로 JSON 로드, 요소 목록 교체 |
| WSOP 프리셋 파일 | wsop-preset.coord-picker-config.json 신규 생성 |
| 상태바 동적 반영 | 요소 수 + 감지 방법 + 활성 설정 이름 표시 |
| CLAUDE.md Option C | ebs_reverse/CLAUDE.md 워크플로우 섹션 추가 |

### OUT of Scope — 유지 내용

| 항목 | 이유 |
|------|------|
| 이미지 로드 (FileReader) | 현행 코드 유지 |
| 드래그 박스 정의 | 현행 코드 유지 |
| overlay-anatomy-coords.json 내보내기 | 포맷 불변 (version/metadata/elements) |
| overlay-anatomy-coords.json 불러오기 | 현행 코드 유지 (박스 복원) |
| Canvas 렌더링 로직 | drawBox, dragToRect 등 유지 |
| 좌표 변환 유틸리티 | scaleFactor 기반 변환 유지 |
| CSS/레이아웃 | 전체 구조 유지, 신규 UI 섹션만 추가 |
| Python 스크립트 | annotate_anatomy.py 등 미수정 |

---

## 3. 영향 파일 목록

### 수정 파일

| 파일 | 변경 유형 | 주요 변경 내용 |
|------|----------|--------------|
| `C:/claude/ebs_reverse/scripts/coord_picker.html` | 전체 재구현 | ELEMENTS 하드코딩 제거, 분석 엔진 추가, UI 확장 |
| `C:/claude/ebs_reverse/CLAUDE.md` | 섹션 추가 | Option C 워크플로우 등록 (PRD §10 내용) |

### 신규 생성 파일

| 파일 | 목적 |
|------|------|
| `C:/claude/ebs_reverse/scripts/wsop-preset.coord-picker-config.json` | WSOP 11개 요소 프리셋 (기존 ELEMENTS 배열 기반) |

---

## 4. 이미지 분석 알고리즘 구현 계획

PRD §4 명세를 기반으로 단계별 구현 순서와 세부 지침을 정의한다.

### 4.1 분석 파이프라인 개요

```
  +------------------+
  | imageLoad 완료   |
  +--------+---------+
           |
           v
  +--------+---------+
  | getImageData()   |  canvas.getContext('2d').getImageData(0,0,W,H)
  +--------+---------+
           |
           v
  +--------+---------+
  | 다운샘플링       |  8x8 블록 평균 RGB → grid[gridH][gridW]
  +--------+---------+
           |
           v
  +--------+---------+
  | 배경색 추출      |  가장자리 2행/2열 블록 → R/G/B 중앙값
  +--------+---------+
           |
           v
  +--------+---------+
  | 전경 마킹        |  colorDelta(block, bgColor) > threshold
  +--------+---------+
           |
           v
  +--------+---------+
  | BFS 클러스터링   |  4-방향 연결, visited[][] 배열
  +--------+---------+
           |
           v
  +--------+---------+
  | 크기 필터        |  bbox.w >= 50 && bbox.h >= 50
  +--------+---------+
           |
           v
  +--------+---------+
  | 요소 목록 생성   |  "Element 1" ~ "Element N" + HSL 색상
  +--------+---------+
```

### 4.2 colorDelta 함수 명세

```javascript
// PRD §4.5 가중치 유클리디안 거리
function colorDelta(c1, c2) {
  const dr = c1.r - c2.r;
  const dg = c1.g - c2.g;
  const db = c1.b - c2.b;
  return Math.sqrt(2*dr*dr + 4*dg*dg + 3*db*db);
}
// 최대값: sqrt((2+4+3)*255^2) ≈ 480.6
// threshold 30 기준: 전체 범위의 약 6%
```

### 4.3 배경색 중앙값 계산

- 수집 대상: 상단 2행 + 하단 2행 + 좌측 2열 + 우측 2열 블록
- R/G/B 각 채널 독립적으로 `Array.sort()` 후 중앙값 추출
- 평균 대신 중앙값 이유: 코너에 UI 요소가 걸쳐있을 때 영향 최소화

### 4.4 BFS 구현 주의사항

- `visited` 배열은 `new Array(gridH).fill(null).map(() => new Array(gridW).fill(false))` 로 초기화
- 큐는 배열 + index 포인터 방식 (shift() 대신 pointer 증가로 O(1) dequeue)
- 4-방향만 사용 (8-방향 금지 — 인접 UI 요소 병합 오류 발생)

### 4.5 감지 결과 시각화 레이어

분석 후 `detectHighlights` 배열에 감지된 bbox 저장. `redrawCanvas()` 호출 시:

1. 이미지 그리기
2. `showHighlights === true` 면 감지 bbox를 `rgba(255,255,0,0.15)` 반투명으로 그리기
3. 정의된 박스 그리기 (기존 로직)
4. 드래그 미리보기 (기존 로직)

---

## 5. UI 변경 계획

### 5.1 툴바 확장

기존 툴바에 섹션 구분자와 신규 컨트롤을 추가한다.

```
+-------------------------------------------------------+
| [파일 열기] [JSON 불러오기] [JSON 내보내기] [초기화]  |
| --- 자동 분석 섹션 ---                                |
| [자동 분석] 요소 수: [____] [N개 생성]                |
| 임계값: [슬라이더 10~80] 30  [재분석] [하이라이트 ON] |
| --- 설정 파일 섹션 ---                                |
| [설정 불러오기] [설정 내보내기]                       |
| ----------- 마우스: x=—, y=— (우측 끝)               |
+-------------------------------------------------------+
```

**세부 컨트롤 목록**:

| 컨트롤 ID | 타입 | 설명 |
|-----------|------|------|
| `btn-auto-detect` | button | 자동 분석 실행 |
| `input-manual-count` | input[type=number] | 수동 요소 수 입력 (min=1, max=50) |
| `btn-generate` | button | N개 생성 |
| `input-threshold` | input[type=range] | min=10 max=80 value=30 step=1 |
| `span-threshold-value` | span | 현재 임계값 숫자 표시 |
| `btn-reanalyze` | button | 현재 임계값으로 재분석 |
| `btn-toggle-highlight` | button | 감지 하이라이트 ON/OFF 토글 |
| `config-import-input` | input[type=file] | 설정 파일 불러오기 (숨김) |
| `label[for=config-import-input]` | label | [설정 불러오기] 버튼 역할 |
| `btn-config-export` | button | 설정 내보내기 |

### 5.2 요소 목록 패널 변경

| 변경 항목 | 기존 | 변경 후 |
|----------|------|---------|
| 헤더 텍스트 | "요소 목록 (11개)" 하드코딩 | "요소 목록 (N개)" 동적 업데이트 |
| [+ 요소 추가] 버튼 | 없음 | 목록 하단에 추가 버튼 배치 |
| elem-name 편집 | 정적 span | 더블클릭 → contenteditable, Enter/Esc 처리 |
| elem-dot 색상 변경 | 불가 | 클릭 → hidden input[type=color] 트리거 |
| elem-delete | 박스만 삭제 | 요소 자체 + 박스 데이터 완전 삭제 |

### 5.3 상태바 동적 반영

```javascript
// 상태바 형식
`요소 ${elements.length}개 | 정의됨: ${definedCount}/${elements.length} |
 감지 방법: ${detectMethod} | 설정: ${configName} |
 활성: [${activeId}] ${activeName}`
```

---

## 6. 기능별 구현 순서 (P0 → P1 → P2)

### P0 태스크 — Must Have

#### T-01: 상태 모델 재설계

**대상**: `coord_picker.html` `<script>` 상단 상태 선언 블록

**현행**:
```javascript
const ELEMENTS = [ /* 10개 하드코딩 */ ];
let state = { image, imageFileName, imageWidth, imageHeight,
              scaleFactor, boxes, activeId, drag, isDragging };
```

**변경 후**:
```javascript
// ELEMENTS 상수 완전 제거
let elements = [];           // 동적 요소 배열 (id, name, color, gfx_type, protocol_cmd)
let nextElemId = 1;          // 단조 증가 ID 카운터
let detectMethod = 'none';   // 'auto' | 'manual' | 'none'
let configName = '';         // 로드된 설정 이름
let detectHighlights = [];   // [{x,y,w,h}] 자동 감지 결과 bbox
let showHighlights = false;  // 하이라이트 표시 여부
let currentThreshold = 30;   // 현재 임계값

let state = { image, imageFileName, imageWidth, imageHeight,
              scaleFactor, boxes, activeId, drag, isDragging };
```

**Acceptance Criteria**:
- `ELEMENTS` 상수 코드 없음
- `elements` 배열이 초기값 `[]`
- 모든 기존 기능(이미지 로드, 드래그, JSON 내보내기)이 `elements` 배열 기반으로 동작

#### T-02: renderElementList 동적화

**대상**: `renderElementList()` 함수 전체

- `ELEMENTS.forEach` → `elements.forEach`
- elem.gfx → elem.gfx_type (필드명 통일)
- 더블클릭 이름 인라인 편집 핸들러 추가
- 색상 도트 클릭 → hidden color picker 트리거
- [+ 요소 추가] 버튼을 목록 하단에 렌더링

**Acceptance Criteria**:
- `elements` 배열이 비어있으면 목록이 비어있음
- `elements` 추가/삭제 후 `renderElementList()` 호출 시 즉시 반영
- 더블클릭 → 편집 모드 전환, Enter로 확정, Esc로 취소
- 색상 도트 클릭 시 color picker 열림

#### T-03: 이미지 분석 엔진 구현

**신규 함수 목록**:

| 함수명 | 역할 |
|--------|------|
| `analyzeImage(threshold)` | 전체 파이프라인 진입점, detectHighlights 갱신 |
| `downsample(pixels, W, H, blockSize)` | 8x8 블록 평균 → grid 반환 |
| `extractBackground(grid)` | 가장자리 2행/2열 블록 중앙값 → bgColor 반환 |
| `markForeground(grid, bgColor, threshold)` | isForeground[y][x] boolean 2D 배열 반환 |
| `colorDelta(c1, c2)` | 가중치 유클리디안 거리 (PRD §4.5) |
| `bfsCluster(isForeground)` | 연결된 전경 블록 클러스터 배열 반환 |
| `filterClusters(clusters, blockSize, minW, minH)` | 최소 크기 필터 + bbox 계산 |
| `assignHslColor(index, total)` | HSL 등간격 색상 → HEX 변환 |

**Acceptance Criteria**:
- 1920x1080 PNG 분석 완료까지 3초 이내
- 빈 Canvas (이미지 미로드) 상태에서 호출 시 에러 없이 "이미지를 먼저 열어주세요" 메시지
- threshold=30 기준 방송용 오버레이 이미지에서 주요 UI 요소 자동 감지

#### T-04: 수동 카운트 입력 모드

**신규 함수**: `generateElements(count, mode)`

- `mode='replace'`: 기존 elements 배열 교체
- `mode='append'`: 기존 배열 끝에 추가
- 확인 다이얼로그: `confirm('기존 요소 목록을 교체하시겠습니까?\n[확인]=교체 / [취소]=추가')` (PRD §5)
  - 확인 → replace 모드
  - 취소 → append 모드

**Acceptance Criteria**:
- 입력값 1~50 범위 외 입력 시 경고 후 차단
- replace 후 elements 길이 = count
- append 후 elements 길이 = 기존 + count
- 신규 요소에 HSL 색상 자동 배정

#### T-05: overlay-anatomy-coords.json 내보내기 호환

**대상**: `btnExport.addEventListener` 블록

- `ELEMENTS.map` → `elements.map`
- `elem.gfx` → `elem.gfx_type`
- `elem.cmd` → `elem.protocol_cmd`
- 내보내기 카운트 메시지: `${definedCount}/${elements.length}개` (하드코딩 제거)

**Acceptance Criteria**:
- 출력 JSON의 최상위 키: `version`, `metadata`, `elements` — 기존 포맷 동일
- 각 요소 필드: `id`, `name`, `box`, `gfx_type`, `protocol_cmd`, `defined` — 기존 포맷 동일
- 기존 `annotate_anatomy.py`가 오류 없이 소비 가능

---

### P1 태스크 — Should Have

#### T-06: 감지 임계값 슬라이더 연동

- `input-threshold` change 이벤트 → `currentThreshold` 갱신 + 숫자 표시
- [재분석] 클릭 → `analyzeImage(currentThreshold)` 호출 → detectHighlights 갱신 → redrawCanvas
- 요소 목록은 재분석해도 자동 교체 안 함 (사용자가 수동으로 [N개 생성] 클릭해야 교체)

**Acceptance Criteria**:
- 슬라이더 드래그 중 숫자 실시간 표시
- [재분석] 후 하이라이트가 새 임계값 기준으로 갱신됨
- 재분석 완료 후 상태바에 "임계값 X — N개 클러스터 감지됨" 표시

#### T-07: 감지 하이라이트 시각화

- `redrawCanvas()` 내에 하이라이트 레이어 추가 (이미지 다음, 박스 이전)
- `showHighlights === true` 시 `detectHighlights` 배열의 각 bbox를 `rgba(255,220,0,0.18)` 채우기
- [하이라이트 ON/OFF] 버튼 토글 시 `showHighlights` 반전 + `redrawCanvas()`

**Acceptance Criteria**:
- 하이라이트 ON 시 Canvas에 노란 반투명 박스 표시됨
- 하이라이트 OFF 시 박스 사라짐, 기존 어노테이션 박스 영향 없음

#### T-08: 요소 추가/삭제/이름 편집

**addElement()**:
- 새 id = `nextElemId++`
- 새 요소를 `elements` 배열에 push
- `renderElementList()` + `updateStatus()` 호출

**deleteElement(id)**:
- `elements` 배열에서 해당 id 제거
- `state.boxes[id]` 삭제
- 활성 id가 삭제된 요소면 첫 번째 요소로 이동
- `renderElementList()` + `redrawCanvas()` + `updateStatus()` 호출

**인라인 이름 편집**:
- 더블클릭 → `contenteditable='true'` 설정 + focus
- Enter: value 저장 → `contenteditable='false'`
- Esc: 원래 이름 복원 → `contenteditable='false'`

**Acceptance Criteria**:
- [+ 요소 추가] 클릭 후 목록에 "Element N" 추가됨
- [×] 클릭 후 목록에서 제거됨, 연결된 박스도 삭제
- 이름 더블클릭 → 편집 가능, Enter/Esc 정상 동작

#### T-09: 설정 파일 내보내기/불러오기

**내보내기 (configExport())**:
```json
{
  "schema_version": "2.0",
  "preset_name": "<configName 또는 'Custom'>",
  "description": "감지 방법: auto/manual",
  "created_at": "<ISO 8601>",
  "detect_method": "<detectMethod>",
  "detect_threshold": <currentThreshold>,
  "elements": [ { id, name, color, gfx_type, protocol_cmd } ]
}
```
- box 데이터 포함 금지
- 파일명: `coord-picker-config.json`

**불러오기 (configImport(data))**:
- schema_version 체크 (없으면 경고 후 진행)
- elements 배열로 `elements` 교체
- `configName` = `data.preset_name`
- `detectMethod` = `data.detect_method || 'manual'`
- `renderElementList()` + `updateStatus()` 호출

**Acceptance Criteria**:
- 내보낸 JSON을 다시 불러오면 요소 목록 동일하게 복원
- box 데이터가 내보내기 JSON에 없음
- 잘못된 JSON 로드 시 `alert()`로 오류 안내

---

### P2 태스크 — Nice to Have

#### T-10: 요소 색상 수동 변경

- `.elem-dot` 클릭 시 해당 요소의 hidden `input[type=color]` 활성화
- color picker 변경 시 `elements[i].color` 갱신 + `renderElementList()` + `redrawCanvas()`

**Acceptance Criteria**:
- 색상 도트 클릭 → 색상 선택기 열림
- 선택 후 목록 도트 색상 + Canvas 박스 색상 즉시 반영

#### T-11: 상태바 완전 동적화

```javascript
function updateStatus(msg) {
  if (msg) { statusBar.textContent = msg; return; }
  const definedCount = Object.keys(state.boxes).length;
  const activeElem = elements.find(e => e.id === state.activeId);
  const method = detectMethod === 'auto' ? '자동감지' :
                 detectMethod === 'manual' ? '수동입력' : '미분석';
  statusBar.textContent =
    `요소 ${elements.length}개 | 정의됨: ${definedCount}/${elements.length} | ` +
    `감지: ${method} | 설정: ${configName || '없음'} | ` +
    `활성: [${state.activeId}] ${activeElem ? activeElem.name : '—'}`;
}
```

**Acceptance Criteria**:
- 자동 분석 후 감지 방법 "자동감지" 표시
- 설정 불러오기 후 preset_name 표시

#### T-12: WSOP 프리셋 파일 생성

**파일**: `C:/claude/ebs_reverse/scripts/wsop-preset.coord-picker-config.json`

기존 `const ELEMENTS` 배열의 10개 요소(id 1,2,3,4,5,7,8,9,10,11)를 PRD §6.1 스키마로 변환:

```json
{
  "schema_version": "2.0",
  "preset_name": "WSOP 2025 Paradise",
  "description": "WSOP 방송 오버레이 10개 UI 요소 (Player Info Panel, 홀카드 표시 등)",
  "created_at": "2026-02-23T00:00:00Z",
  "detect_method": "manual",
  "detect_threshold": 30,
  "elements": [
    { "id": 1, "name": "Player Info Panel", "color": "#FF5252",
      "gfx_type": "Text + Image", "protocol_cmd": "SHOW_PANEL" },
    ...
  ]
}
```

**Acceptance Criteria**:
- 파일 로드 후 요소 목록이 WSOP 10개로 교체됨
- 기존 ELEMENTS 배열의 id/name/color/gfx/cmd와 1:1 대응

#### T-13: CLAUDE.md Option C 등록

**대상**: `C:/claude/ebs_reverse/CLAUDE.md` — "Overlay Anatomy Coordinates Workflow" 섹션

PRD §10의 Option C 내용을 그대로 추가한다.

**Acceptance Criteria**:
- CLAUDE.md에 `### Option C` 섹션 존재
- 7단계 워크플로우 내용 포함 (PRD §10 기준)

---

## 7. 위험 요소 및 대응 방안

### R-01: getImageData CORS 오류 (HIGH)

**시나리오**: `file://` 프로토콜에서 외부 이미지 URL을 img.src에 직접 대입하면 tainted canvas 발생.

**대응**:
- 이미지 로드를 반드시 `<input type="file">` + `FileReader.readAsDataURL()` 경로로만 허용
- 현행 코드 이미 이 방식 사용 중 — 변경 없이 유지
- 분석 시점: img.onload 완료 후 canvas.drawImage 완료 후에만 `getImageData` 호출

**검증**: `try/catch(e)` 로 SecurityError 포착 시 "CORS 오류: file:// 직접 열기 필요" 메시지 표시

### R-02: BFS 스택 오버플로우 (MEDIUM)

**시나리오**: 이미지 전체가 전경 블록인 경우 BFS 큐가 과대화, 브라우저 응답 없음.

**대응**:
- BFS에 최대 클러스터 크기 제한: `cells.length > gridW * gridH * 0.5`이면 조기 종료
- 조기 종료된 클러스터는 "배경과 구분 불가" 처리 후 필터링
- threshold 기본값 30을 유지하여 대부분의 배경 단색 케이스 처리

### R-03: overlay-anatomy-coords.json 포맷 파괴 (HIGH)

**시나리오**: `elements` 동적 배열에서 `gfx_type`/`protocol_cmd` 필드가 누락되면 기존 파이프라인 오류.

**대응**:
- `addElement()` 시 `gfx_type: ""`, `protocol_cmd: ""` 기본값 명시적 설정
- 내보내기 함수에서 `elem.gfx_type ?? ""`, `elem.protocol_cmd ?? ""` 방어 코드
- 불러오기 함수에서 각 요소 필드 기본값 보정 후 저장

**검증**: T-05 완료 후 기존 `annotate_anatomy.py` 실행 테스트

### R-04: 인접 요소 병합 오탐 (MEDIUM)

**시나리오**: 방송 오버레이에서 붙어있는 두 UI 요소(예: Player Panel + Action Badge)가 하나의 클러스터로 합쳐짐.

**대응**:
- 4-방향 BFS 고수 (8-방향 금지) — PRD §4.6 명세
- 감지 결과 시각화로 사용자가 병합 여부를 육안 확인
- [×] 삭제 + [+ 요소 추가] + 수동 드래그로 보정하는 워크플로우 안내 (상태바)

### R-05: localStorage 브라우저별 동작 차이 (LOW)

**시나리오**: `file://` 프로토콜에서 일부 브라우저가 localStorage를 비활성화하여 세션 간 설정 저장 불가.

**대응**:
- 세션 내 메모리 상태만 사용, 영구 저장은 `coord-picker-config.json` 파일 내보내기로만 지원
- localStorage 미사용 (PRD §8.1 제약사항 준수)

### R-06: 단일 파일 원칙 위반 (LOW)

**시나리오**: 분석 엔진 코드 추가로 HTML 파일 크기가 과도하게 증가.

**대응**:
- 모든 CSS/JS를 단일 `.html` 내 `<style>`/`<script>` 태그에 유지
- 외부 파일 참조 금지 (PRD §7.1 단일 파일 원칙)
- 코드 증가량 예상: 약 400~600줄 (기존 787줄에서 1,200~1,400줄 예상, 허용 범위)

---

## 8. 검증 기준 (QA 체크리스트)

### 8.1 기능 검증

| # | 검증 항목 | 확인 방법 | 통과 기준 |
|---|----------|----------|----------|
| Q-01 | 이미지 로드 후 자동 분석 실행 | Chrome에서 파일 열기 후 [자동 분석] 클릭 | "N개 요소 감지됨" 상태바 표시 |
| Q-02 | 요소 목록 동적 생성 | 자동 분석 완료 후 패널 확인 | "Element 1" ~ "Element N" 목록 |
| Q-03 | 수동 카운트 생성 | 숫자 입력 후 [N개 생성] 클릭 | elements 길이 == 입력값 |
| Q-04 | 임계값 슬라이더 동작 | 슬라이더 이동 후 [재분석] | 하이라이트 박스 수 변화 |
| Q-05 | 요소 이름 편집 | 더블클릭 후 Enter | 목록에서 새 이름 표시 |
| Q-06 | 요소 추가/삭제 | [+ 추가] 및 [×] 클릭 | 목록 즉시 반영 |
| Q-07 | 드래그 박스 정의 | 요소 클릭 후 Canvas 드래그 | 박스 확정 및 요소 자동 이동 |
| Q-08 | JSON 내보내기 포맷 | [JSON 내보내기] 후 파일 검사 | version/metadata/elements 최상위 키 |
| Q-09 | 설정 내보내기 | [설정 내보내기] | box 데이터 없음, schema_version: "2.0" |
| Q-10 | 설정 불러오기 | coord-picker-config.json 로드 | 요소 목록 교체, preset_name 상태바 표시 |
| Q-11 | WSOP 프리셋 로드 | wsop-preset.coord-picker-config.json 로드 | 10개 WSOP 요소 복원 |
| Q-12 | 기존 JSON 불러오기 | 기존 overlay-anatomy-coords.json 로드 | 박스 데이터 복원 |

### 8.2 호환성 검증

| # | 검증 항목 | 통과 기준 |
|---|----------|----------|
| C-01 | annotate_anatomy.py 파이프라인 | 내보낸 JSON으로 annotate_anatomy.py 오류 없이 실행 |
| C-02 | Chrome 110+ | 모든 기능 정상 동작 |
| C-03 | file:// 프로토콜 | 로컬 서버 없이 직접 실행 가능 |
| C-04 | 1920x1080 이미지 분석 | 3초 이내 완료 |

### 8.3 회귀 검증

| # | 검증 항목 | 통과 기준 |
|---|----------|----------|
| RG-01 | 기존 드래그 박스 정의 | mousedown/mousemove/mouseup 이벤트 정상 동작 |
| RG-02 | 박스 좌표 정밀도 | displayRectToImageRect 변환 결과 기존과 동일 |
| RG-03 | 초기화 버튼 | boxes 및 elements 초기화 정상 동작 |

---

## 9. 커밋 전략

구현 완료 후 하나의 커밋으로 묶는다.

```
feat(coord-picker): 이미지 분석 기반 글로벌 재설계 v2.0.0

- Canvas getImageData + BFS 클러스터링 자동 요소 감지 구현
- WSOP 하드코딩 제거, 동적 elements 배열로 전환
- 감지 임계값 슬라이더, 수동 카운트 입력 UI 추가
- coord-picker-config.json 설정 내보내기/불러오기 구현
- wsop-preset.coord-picker-config.json WSOP 프리셋 파일 신규 생성
- CLAUDE.md Option C 워크플로우 등록
- overlay-anatomy-coords.json 출력 포맷 완전 호환 유지
```

**수정 파일**:
- `scripts/coord_picker.html`
- `CLAUDE.md`

**신규 파일**:
- `scripts/wsop-preset.coord-picker-config.json`
