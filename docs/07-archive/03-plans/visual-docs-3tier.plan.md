# 3-Tier 시각적 문서화 시스템 Work Plan

## 배경 (Background)

### 요청 내용
`generate_annotations.py`에 `--crop` 모드를 추가하여 각 UI 박스를 원본 이미지에서 크롭한 이미지를 생성하고,
`PokerGFX-UI-Analysis.md`를 3-tier 구조로 재편하는 작업.

### 해결하려는 문제
현재 문서 구조는 Tier 1 (원본 스크린샷)과 Tier 2 (번호 박스 오버레이) 두 계층만 제공.
화면당 20~40개 박스가 밀집된 오버레이에서 특정 요소를 눈으로 찾아야 하는 참조 비용이 높음.
Tier 3 (개별 요소 크롭 이미지)를 인라인 삽입하면 독자가 "맥락 → 위치 → 세부"를 단계적으로 이해 가능.

---

## 구현 범위 (Scope)

### 포함 항목
- `generate_annotations.py`에 `--crop` / `--label` 플래그 추가
- `crop_boxes()` 함수 신규 구현 (원본에서 8px 패딩 포함 크롭)
- `process_image()`에 `mode='crop'` 분기 추가
- 출력 디렉토리 `docs/01_PokerGFX_Analysis/03_Cropped_ngd/` 자동 생성
- 11개 화면에 대한 크롭 이미지 일괄 생성
- `PokerGFX-UI-Analysis.md` 11개 섹션에 Tier 3 인라인 이미지 참조 추가

### 제외 항목
- 기존 Tier 1 / Tier 2 생성 로직 변경 없음
- OCR 분석 재실행 없음
- HTML mockup 변경 없음
- 크롭 이미지에 GFX 오버레이 합성 없음 (순수 원본 픽셀만)

---

## 영향 파일 (Affected Files)

### 수정 예정 파일
- `C:/claude/ebs/tools/generate_annotations.py` — `--crop`/`--label` 플래그, `crop_boxes()`, `mode='crop'` 분기 추가
- `C:/claude/ebs/docs/01_PokerGFX_Analysis/PokerGFX-UI-Analysis.md` — 11개 섹션에 Tier 3 인라인 이미지 블록 추가

### 신규 생성 파일 (디렉토리)
- `C:/claude/ebs/docs/01_PokerGFX_Analysis/03_Cropped_ngd/` — 크롭 출력 루트
- `C:/claude/ebs/docs/01_PokerGFX_Analysis/03_Cropped_ngd/01-main-window/` — 10개 크롭 이미지
- `C:/claude/ebs/docs/01_PokerGFX_Analysis/03_Cropped_ngd/02-sources-tab/` — 12개 크롭 이미지
- `C:/claude/ebs/docs/01_PokerGFX_Analysis/03_Cropped_ngd/03-outputs-tab/` — 13개 크롭 이미지
- `C:/claude/ebs/docs/01_PokerGFX_Analysis/03_Cropped_ngd/04-gfx1-tab/` — 29개 크롭 이미지
- `C:/claude/ebs/docs/01_PokerGFX_Analysis/03_Cropped_ngd/05-gfx2-tab/` — 21개 크롭 이미지
- `C:/claude/ebs/docs/01_PokerGFX_Analysis/03_Cropped_ngd/06-gfx3-tab/` — 23개 크롭 이미지
- `C:/claude/ebs/docs/01_PokerGFX_Analysis/03_Cropped_ngd/07-commentary-tab/` — 8개 크롭 이미지
- `C:/claude/ebs/docs/01_PokerGFX_Analysis/03_Cropped_ngd/08-system-tab/` — 28개 크롭 이미지
- `C:/claude/ebs/docs/01_PokerGFX_Analysis/03_Cropped_ngd/09-skin-editor/` — 37개 크롭 이미지
- `C:/claude/ebs/docs/01_PokerGFX_Analysis/03_Cropped_ngd/10-graphic-editor-board/` — 39개 크롭 이미지
- `C:/claude/ebs/docs/01_PokerGFX_Analysis/03_Cropped_ngd/11-graphic-editor-player/` — 48개 크롭 이미지 (숫자 40개 + 알파벳 8개)

---

## 위험 요소 (Risks)

### 위험 1: OCR JSON 좌표 vs. 하드코딩 박스 좌표 우선순위 불명확
- **문제**: `02_Annotated_ngd/`의 `*-ocr.json` 파일에는 edge-snap+OCR 보정된 좌표가 있음.
  `IMAGES` 딕셔너리 하드코딩 좌표와 일치하지 않는 경우 어느 쪽을 크롭 기준으로 사용할지 결정 필요.
- **결정**: OCR JSON이 존재하면 JSON 좌표를 우선 사용 (보정 결과가 더 정확).
  JSON 없으면 `IMAGES` 딕셔너리 하드코딩 좌표 사용.
- **구현 위치**: `process_image()` 의 `mode='crop'` 분기에서 JSON sidecar 로드 시도 후 fallback.

### 위험 2: 레이블이 숫자가 아닌 박스 (A, B, C, ... H)
- **문제**: `11-graphic-editor-player` 화면에는 숫자 레이블 외 `A`~`H` 문자 레이블 박스 8개 포함 (line 926~933).
  파일명 규칙 `{screen-id}-crop-{NN}.png`에서 `{NN}`이 알파벳인 경우 처리 필요.
- **결정**: 숫자는 zero-pad 2자리 (`01`, `02`), 알파벳은 소문자 변환 (`a`, `b`, ... `h`).
  파일명 예: `11-graphic-editor-player-crop-a.png`
- **Edge case**: 동일 화면에 숫자+문자 혼합 존재 시 정렬 순서 보장 (숫자 먼저, 알파벳 나중).

### 위험 3: 크롭 영역이 이미지 경계를 초과하는 경우
- **문제**: 8px 패딩 추가 시 박스가 이미지 외곽에 붙어 있는 경우 음수 좌표 또는 이미지 크기 초과 발생.
  예: `01-main-window`의 박스 1 `(0, 0, 765, 32)` — 상단/좌측 경계 접촉.
- **결정**: 클램핑 처리 — `max(0, x - pad)`, `min(img_width, x + w + pad)`.

### 위험 4: `PokerGFX-UI-Analysis.md` 테이블 내 인라인 이미지 Markdown 호환성
- **문제**: Markdown 테이블 셀 내 `![img](path)` 삽입 시 일부 렌더러에서 레이아웃 깨짐.
  테이블 행마다 이미지 삽입하면 파일 크기가 급증 (현재 약 400줄 → 3000줄 이상).
- **결정**: PRD R4 명세 준수하되 기존 테이블은 유지. 각 섹션 테이블 하단에 "크롭 참조" 별도 테이블 블록 추가.
  (기존 기능 테이블 변경 없음, 섹션당 새 테이블 1개 추가)
- **대형 문서 프로토콜**: 섹션별 Edit 분할 작업 필수 (단일 Write 금지).

---

## 태스크 목록 (Tasks)

### Task 1: `crop_boxes()` 함수 구현

**설명**: `generate_annotations.py`에 `crop_boxes()` 신규 함수 추가. 원본 이미지에서 각 박스를 8px 패딩 포함 크롭.

**수행 방법**:
- 파일: `C:/claude/ebs/tools/generate_annotations.py`
- 삽입 위치: `process_image()` 함수 직전 (약 line 940, `# MAIN` 섹션 하단)
- 함수 시그니처: `def crop_boxes(img, boxes, pad=8, label_overlay=False)`
- 로직:
  1. `img_w, img_h = img.size`
  2. 각 박스 `(x, y, w, h)` 에서 `left = max(0, x-pad)`, `top = max(0, y-pad)`, `right = min(img_w, x+w+pad)`, `bottom = min(img_h, y+h+pad)` 계산
  3. `img.crop((left, top, right, bottom))` 호출
  4. `label_overlay=True`인 경우 PIL ImageDraw로 좌상단에 레이블 배지 (빨간 배경, 흰 텍스트, 13px bold font)
  5. 크롭 이미지 리스트 반환

**Acceptance Criteria**:
- `crop_boxes(img, boxes)` 호출 시 `len(boxes)` 개수의 PIL Image 객체 리스트 반환
- 패딩 8px 적용 후 이미지 경계 클램핑 보장 (음수 좌표, 이미지 크기 초과 없음)
- `label_overlay=True` 시 각 크롭 이미지 좌상단에 레이블 텍스트 표시

---

### Task 2: `process_image()`에 `mode='crop'` 분기 추가

**설명**: 기존 `calibrate` / `ocr` / `debug` / `normal` 분기 앞에 `crop` 분기 추가.

**수행 방법**:
- 파일: `C:/claude/ebs/tools/generate_annotations.py`
- 삽입 위치: `process_image()` 내 `if mode == 'calibrate':` 블록 앞 (약 line 956)
- 분기 로직:
  ```
  if mode == 'crop':
      CROP_OUTPUT_DIR = "C:/claude/ebs/docs/01_PokerGFX_Analysis/03_Cropped_ngd"
      screen_dir = os.path.join(CROP_OUTPUT_DIR, name)
      os.makedirs(screen_dir, exist_ok=True)

      # OCR JSON 우선 로드 (없으면 IMAGES 딕셔너리 boxes 사용)
      json_path = os.path.join(OUTPUT_DIR, f"{name}-ocr.json")
      crop_boxes_src = boxes
      if os.path.exists(json_path):
          with open(json_path, encoding='utf-8') as f:
              json_data = json.load(f)
          crop_boxes_src = [{'rect': tuple(b['rect']), 'label': b['label']}
                            for b in json_data['boxes']]

      crops = crop_boxes(img, crop_boxes_src, pad=8, label_overlay=label_flag)
      saved = 0
      for box, crop_img in zip(crop_boxes_src, crops):
          lbl = str(box['label'])
          lbl_fmt = f"{int(lbl):02d}" if lbl.isdigit() else lbl.lower()
          fname = f"{name}-crop-{lbl_fmt}.png"
          crop_img.save(os.path.join(screen_dir, fname))
          saved += 1
      print(f"CROP: {screen_dir}/ ({saved} files)")
      return saved
  ```
- `label_flag`는 `main()`에서 `args.label`로 전달 (process_image 시그니처에 `label=False` 파라미터 추가)

**Acceptance Criteria**:
- `--crop --target 02` 실행 시 `03_Cropped_ngd/02-sources-tab/` 에 12개 파일 생성
- 숫자 레이블 `1` → `01`, 알파벳 레이블 `A` → `a` 변환 정상 동작
- `01-main-window-ocr.json` 존재 시 JSON 좌표 사용, 없는 화면은 IMAGES 딕셔너리 좌표 사용

---

### Task 3: `argparse`에 `--crop` / `--label` 플래그 추가

**설명**: `main()` 함수의 argparse와 mode 결정 로직, docstring 업데이트.

**수행 방법**:
- 파일: `C:/claude/ebs/tools/generate_annotations.py`
- 위치 1 (docstring): 파일 상단 docstring (line 1~20) Usage 블록에 2줄 추가:
  ```
  python generate_annotations.py --crop                # Crop all screens to 03_Cropped_ngd/
  python generate_annotations.py --crop --target 02   # Crop single screen
  ```
- 위치 2 (argparse, 약 line 1155~1165):
  ```python
  parser.add_argument('--crop', action='store_true',
                      help='Crop UI elements to 03_Cropped_ngd/{screen-id}/')
  parser.add_argument('--label', action='store_true',
                      help='Add label badge overlay to cropped images (use with --crop)')
  ```
- 위치 3 (mode 결정 로직, 약 line 1170~1178): `if args.crop: mode = 'crop'` 을 최상위에 추가
- 위치 4 (process_image 호출, 약 line 1191): `label=args.label` 파라미터 전달

**Acceptance Criteria**:
- `python generate_annotations.py --help` 에서 `--crop`, `--label` 설명 출력
- `--crop --ocr` 동시 사용 시 `--crop` 우선 (mode = 'crop')
- `--label` 단독 사용 시 mode='normal' 진행 (label 무시)

---

### Task 4: 크롭 이미지 일괄 생성 실행 및 검증

**설명**: Task 1~3 완료 후 전체 11개 화면 크롭 실행 및 출력 파일 수/크기 검증.

**수행 방법**:
- 실행 명령어: `python C:/claude/ebs/tools/generate_annotations.py --crop`
- 검증 명령어:
  ```bash
  # 서브디렉토리 수 확인 (11개)
  ls C:/claude/ebs/docs/01_PokerGFX_Analysis/03_Cropped_ngd/ | wc -l
  # 총 파일 수 확인 (268개)
  find C:/claude/ebs/docs/01_PokerGFX_Analysis/03_Cropped_ngd/ -name "*.png" | wc -l
  ```

**Acceptance Criteria**:
- 11개 서브디렉토리 생성 확인
- 총 PNG 파일 수 = 268개 (10+12+13+29+21+23+8+28+37+39+48)
- Pillow crop 오류 없이 정상 완료
- 각 PNG 파일 크기 < 200KB

---

### Task 5: `PokerGFX-UI-Analysis.md` 3-tier 구조 업데이트

**설명**: 11개 화면 섹션 각각에 "크롭 참조 (Tier 3)" 테이블 블록 추가. 섹션별 Edit 분할 적용.

**수행 방법**:
- 파일: `C:/claude/ebs/docs/01_PokerGFX_Analysis/PokerGFX-UI-Analysis.md`
- 각 섹션 기능 테이블 하단, `> **EBS 설계 시사점**` 블록 직전에 삽입할 패턴:

```markdown
### 크롭 참조 (Tier 3)

| # | 크롭 이미지 | 기능명 |
|:-:|:-----------:|--------|
| 1 | ![01](../01-pokergfx-analysis/03_Cropped_ngd/01-main-window/01-main-window-crop-01.png) | Title Bar |
| 2 | ![02](../01-pokergfx-analysis/03_Cropped_ngd/01-main-window/01-main-window-crop-02.png) | Preview |
...
```

- 경로 형식: `../01-pokergfx-analysis/03_Cropped_ngd/{screen-id}/{screen-id}-crop-{lbl}.png` (상대 경로, `PokerGFX-UI-Analysis.md` 기준)
- 알파벳 레이블 박스 (`A`~`H`)는 동일 테이블에 포함
- 11개 섹션을 별도 Edit 호출로 분할 작업 (대형 문서 프로토콜 준수)

**섹션별 삽입 anchor 위치**:

| 섹션 | 현재 anchor 텍스트 | 크롭 이미지 수 |
|------|--------------------|:--------------:|
| 1. 메인 윈도우 | `> **EBS 설계 시사점**` (line ~69) | 10 |
| 2. Sources 탭 | `> **EBS 설계 시사점**` (line ~103) | 12 |
| 3. Outputs 탭 | `> **EBS 설계 시사점**` (line ~138) | 13 |
| 4. GFX 1 탭 | `> **EBS 설계 시사점**` | 29 |
| 5. GFX 2 탭 | `> **EBS 설계 시사점**` | 21 |
| 6. GFX3 탭 | `> **EBS 설계 시사점**` | 23 |
| 7. Commentary 탭 | `> **EBS 설계 시사점**` | 8 |
| 8. System 탭 | `> **EBS 설계 시사점**` | 28 |
| 9. Skin Editor | `> **EBS 설계 시사점**` | 37 |
| 10. Graphic Editor - Board | `> **EBS 설계 시사점**` | 39 |
| 11. Graphic Editor - Player | `> **EBS 설계 시사점**` | 48 (숫자 40 + 알파벳 8) |

**Acceptance Criteria**:
- 11개 섹션 각각에 "크롭 참조 (Tier 3)" 테이블 존재 확인
- 각 테이블 행 수 = 해당 화면의 박스 수와 일치
- Markdown 테이블 파이프 문법 오류 없음
- 이미지 경로 상대 경로 형식 일관성 (`../01-pokergfx-analysis/03_Cropped_ngd/...`)

---

## 커밋 전략 (Commit Strategy)

2개 커밋으로 분리:

```
feat(tools): generate_annotations.py --crop 모드 추가
```
> Task 1~3 완료 후 커밋

```
feat(docs): PokerGFX-UI-Analysis.md Tier 3 크롭 참조 테이블 추가
```
> Task 4~5 완료 후 커밋

---

## 의존성 및 실행 순서

```
  Task 1 (crop_boxes 함수 구현)
       |
       v
  Task 2 (mode='crop' 분기 추가)
       |
       v
  Task 3 (argparse 플래그 추가)
       |
       v
  Task 4 (실행 검증 — 이미지 268개 생성)
       |
       v
  Task 5 (UI-Analysis.md Tier 3 추가)
```

Task 5는 Task 4에서 실제 크롭 파일이 생성된 후 경로 확인 후 진행.

---

## 변경 이력

---
**Version**: 1.0.0 | **Updated**: 2026-02-19
