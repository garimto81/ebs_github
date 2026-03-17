---
name: mockup-hybrid
description: >
  This skill should be used when the user needs UI mockups via 3-Tier hybrid system: Mermaid diagrams, HTML wireframes, or Google Stitch AI.
version: 2.0.0

triggers:
  keywords:
    - "mockup"
    - "/mockup"
    - "목업"
    - "와이어프레임"
    - "wireframe"
    - "ui mockup"
    - "다이어그램"
    - "diagram"
    - "mermaid"
  file_patterns:
    - "docs/mockups/*.html"
    - "docs/mockups/*.mermaid.md"
    - "docs/images/mockups/*.png"
  context:
    - "UI 디자인"
    - "화면 설계"
    - "프로토타입"
    - "시스템 구조"
    - "흐름도"

auto_trigger: true
---

# Mockup Hybrid Skill v2.0

3-Tier 자동 선택 목업 생성 시스템. `--mockup`만으로 최적의 시각화 방식을 자동 결정합니다.

## 동작 모드

### Mode 1: 문서 기반 (Document-Driven)
```
/auto --mockup docs/02-design/feature.md
      │
      ▼
┌─────────────────────────────────┐
│      Document Scanner           │
│  ## 헤딩 기준 섹션 분리 + 분류  │
│  NEED / SKIP / EXIST 판단      │
└─────────────────────────────────┘
      │
      ├─ NEED 섹션들 ──▶ 3-Tier Router ──▶ 일괄 생성
      ├─ EXIST 섹션   ──▶ 스킵 (--force 시 재생성)
      └─ SKIP 섹션    ──▶ 스킵 (서술형)
      │
      ▼
┌─────────────────────────────────┐
│      Document Embedder          │
│  Mermaid → 인라인 코드 블록    │
│  HTML    → ![](이미지 참조)    │
└─────────────────────────────────┘
```

### Mode 2: 단건 (Prompt-Driven)
```
/auto "요청" --mockup
      │
      ▼
  3-Tier Router
      ├─ 다이어그램 키워드 ──▶ Mermaid (~2초)
      ├─ UI/화면 키워드    ──▶ HTML Wireframe (~5초)
      └─ 고품질/발표 키워드 ─▶ Stitch AI (~15초)
```

## 자동 라우팅 규칙

### 우선순위

1. **강제 옵션** (사용자 명시)
   - `--mockup mermaid` → Mermaid 고정
   - `--mockup html` → HTML 고정
   - `--mockup hifi` → Stitch 고정
   - `--mockup --quasar` → HTML + Quasar Material Design 스타일
   - `--mockup-q` → HTML + Quasar White Tone Minimal 스타일

2. **키워드 감지** (자동)

| Tier | 키워드 | 출력 |
|:----:|--------|------|
| Mermaid | 흐름, 플로우, 시퀀스, API 호출, DB, 스키마, ER, 클래스, 아키텍처, 파이프라인, 상태, 워크플로우 | `.mermaid.md` |
| HTML | 화면, UI, 레이아웃, 페이지, 대시보드, 폼, 카드, 사이드바, 와이어프레임 | `.html` + `.png` |
| Stitch | 프레젠테이션, 고품질, 최종, 데모, 발표, 리뷰용, 이해관계자 | `.html` + `.png` (HiFi) |

3. **프로젝트 타입 감지** (자동)
   - Quasar 프로젝트 감지 시 (`package.json` quasar dep 또는 `quasar.config.*`) → `style="quasar"` 자동 적용 (명시적 `--quasar` 불필요)
   - React/Next.js 프로젝트 감지 시 → 기존 HTML B&W Refined Minimal (향후 React 스타일 확장 가능)

4. **컨텍스트** — `--prd=PRD-NNNN` → Stitch, `--screens=3+` → HTML
5. **환경** — Stitch API 불가 → HTML
6. **기본값** → HTML

## Mermaid 다이어그램 타입

| 타입 | 트리거 | 용도 |
|------|--------|------|
| `flowchart` | 흐름, 프로세스, 파이프라인 | 워크플로우, 결정 트리 |
| `sequenceDiagram` | 시퀀스, API 호출, 통신, 인증 | API 흐름, 인증 플로우 |
| `erDiagram` | DB, 스키마, ER, 테이블 관계 | 데이터 모델 |
| `classDiagram` | 클래스, 인터페이스, 상속 | OOP 구조 |
| `stateDiagram-v2` | 상태, 상태 머신, 라이프사이클 | 상태 전이 |
| `gitGraph` | 브랜치, 커밋, 머지 | Git 전략 |

## 사용 예시

```bash
# 문서 기반 자동 목업 (핵심 기능)
/auto --mockup docs/02-design/auth.design.md
# → 문서 스캔 → 시각화 필요 섹션 자동 발견 → 일괄 생성 + 삽입

# 미리보기 (실제 수정 없이 어떤 목업이 생성될지 확인)
/auto --mockup docs/02-design/auth.design.md --dry-run

# 기존 목업도 재생성
/auto --mockup docs/02-design/auth.design.md --force

# 단건 자동 선택 (프롬프트 기반)
/auto "API 인증 흐름 설계" --mockup
/auto "대시보드 화면 설계" --mockup

# 강제 지정
/auto "시스템 구조" --mockup mermaid
/auto "로그인 화면" --mockup html
/auto "데모 페이지" --mockup hifi
```

## 출력 형식

```bash
# Mermaid 선택 시
📊 선택: Mermaid sequenceDiagram (이유: 다이어그램 키워드 감지)
✅ 생성: docs/mockups/인증흐름.mermaid.md

# HTML 선택 시
📝 선택: HTML Generator (이유: 기본값)
✅ 생성: docs/mockups/dashboard.html
📸 캡처: docs/images/mockups/dashboard.png

# Stitch 선택 시
🤖 선택: Stitch API (이유: 고품질 키워드 감지)
✅ 생성: docs/mockups/landing-hifi.html
📸 캡처: docs/images/mockups/landing-hifi.png
```

## 모듈 구조

```
.claude/skills/mockup-hybrid/
├── SKILL.md
├── adapters/
│   ├── mermaid_adapter.py      # Mermaid 코드 생성 (NEW)
│   ├── html_adapter.py         # HTML 와이어프레임 생성
│   └── stitch_adapter.py       # Stitch API 연동
├── core/
│   ├── analyzer.py             # 3-Tier 프롬프트 분석
│   ├── router.py               # 백엔드 라우팅
│   └── fallback_handler.py     # 폴백 처리
└── config/
    └── selection_rules.yaml    # 자동 선택 규칙 (v2.0)

lib/mockup_hybrid/
├── __init__.py                 # 타입 정의 (MERMAID 추가)
├── stitch_client.py            # Stitch API 클라이언트
└── export_utils.py             # 내보내기 유틸리티
```

## 환경 변수

```bash
# Google Stitch (무료 - 350 screens/월) — Tier 3 전용
STITCH_API_KEY=your-api-key
STITCH_API_BASE_URL=https://api.stitch.withgoogle.com/v1
```

## Quasar Material Design (--quasar 스타일)

`--mockup --quasar` 시 B&W Refined Minimal 대신 Quasar Framework Material Design 적용.

### 동작 방식

```
/auto "요청" --mockup --quasar
      │
      ▼
  MockupOptions(style="quasar")
      │
      ▼
  HTMLAdapter → mockup-quasar.html 템플릿 선택
      │
      ▼
  designer 에이전트 (Quasar 컴포넌트 어휘로 스타일링)
      │
      ▼
  Playwright PNG 캡처 (networkidle 대기 → CDN 로드 완료)
```

### Quasar 컴포넌트 매핑

| B&W 요소 | Quasar 대응 |
|----------|------------|
| header | `q-toolbar` + `q-toolbar-title` |
| input | `q-input outlined` |
| button | `q-btn color="primary"` |
| card | `q-card` + `q-card-section` |
| table | `q-table` |
| sidebar | `q-drawer` |

### UMD 제약

- CDN: Vue 3 + Quasar 2 UMD + Material Icons
- **self-closing 태그 금지**: `<q-input />` 불가 → `<q-input></q-input>` 필수
- B&W 팔레트 적용 스킵 (Quasar 자체 Material Design 색상 사용)

## Quasar White Tone Minimal (--mockup-q 스타일)

`--mockup-q` 시 Quasar 컴포넌트 구조를 유지하면서 White Tone Minimal 디자인 적용.

### 동작 방식

```
/auto "요청" --mockup-q
      │
      ▼
  MockupOptions(style="quasar-white")
      │
      ▼
  HTMLAdapter → mockup-quasar-white.html 템플릿 선택
      │
      ▼
  designer 에이전트 (White Minimal 어휘로 스타일링)
      │
      ▼
  Playwright PNG 캡처 (networkidle 대기 → CDN 로드 완료)
```

### White Minimal 팔레트

| 용도 | 값 |
|------|-----|
| Primary | `#374151` (차콜) |
| Secondary | `#6b7280` (그레이) |
| Page BG | `#ffffff` |
| Card BG | `#ffffff` + border `#e5e7eb` |
| Text primary | `#111827` |
| Text secondary | `#6b7280` |
| Text muted | `#9ca3af` |
| Border | `#e5e7eb` |

### 컴포넌트 매핑 (vs 기존 Quasar)

| 요소 | Quasar (컬러) | White Minimal |
|------|--------------|---------------|
| Header | `bg-primary text-white` | `bg-white text-dark` + border-bottom |
| Card | default shadow | `flat bordered` |
| Button | `color="primary"` | `color="grey-8"` |
| Page BG | `#f5f5f5` | `#ffffff` |

### UMD 제약

기존 Quasar와 동일: self-closing 태그 금지, Vue 3 + Quasar 2 UMD CDN.

## B&W Refined Minimal (기본 스타일)

HTML 목업은 항상 Refined Minimal (Linear Style) B&W 디자인으로 생성된다. `--bnw` 플래그는 deprecated (하위 호환용 파싱만, 무시됨).

### 동작 방식

```
/auto "요청" --mockup
      │
      ▼
3-Tier 라우터 (키워드 기반 — 라우팅 우선)
      │
      ├─ 다이어그램 키워드 → Mermaid 생성
      │   (흐름, 시퀀스, API, DB, ER, 클래스, 상태, 아키텍처 등)
      │   (Mermaid는 기본 흑백 계열)
      │
      └─ UI/화면 키워드 → designer 에이전트 (B&W Refined Minimal 적용)
              (화면, UI, 레이아웃, 페이지, 대시보드, 폼, 와이어프레임 등)
              │
              ├── 팔레트: #222326, #555555, #8a8a8a, #767676, #e5e5e5, #F4F5F8, #ffffff
              ├── 아이콘 없음 (텍스트 레이블만, emoji/SVG/icon font 금지)
              ├── 단일 서체 Inter 400/500/600 — Refined Minimal (Linear Style)
              ├── 균등 padding, 8px grid, 3-layer shadow 깊이감
              └── border-radius 12px, 1px solid #e5e5e5 border
```

### 크기 및 텍스트 규칙 (필수 적용)

| 항목 | 규칙 |
|------|------|
| **최대 규격** | 너비 720px × 높이 1280px (`max-width: 720px; max-height: 1280px`) |
| **폰트 크기** | body 15px, caption 12px, heading max 30px (hero max 36px) |
| **텍스트 우선** | 텍스트로 표현 가능한 요소는 이미지/SVG/아이콘 삽입 금지 — 레이블/텍스트로만 표현 |

### B&W 팔레트 규칙 — Refined Minimal (Linear Style)

| 용도 | 색상 |
|------|------|
| 주요 텍스트 | `#222326` (Nordic Gray) |
| 보조 텍스트 | `#555555` |
| 뮤트/캡션 | `#8a8a8a` |
| 비활성/플레이스홀더 | `#767676` (WCAG AA 4.54:1) |
| 구분선/보더 | `#e5e5e5` (1px only) |
| 페이지 배경 | `#F4F5F8` (Mercury White) |
| 카드/surface | `#ffffff` |

### designer 에이전트 미사용 시 폴백

`designer` 에이전트를 사용할 수 없는 경우 `html_adapter.py`의 기본 템플릿으로 폴백:
- Inter 400/500/600 단일 서체 (Refined Minimal)
- 8px grid, 3-layer shadow 깊이감
- #F4F5F8 page background + #ffffff card + border-radius 12px

## 변경 로그

### v2.1.0 (2026-02-19)

**Features:**
- `--bnw` 복원 (frontend-design 에이전트 기반 모노크롬 디자인)
- B&W 팔레트 규칙 정의 (그레이스케일 #000~#fff만)
- `html_adapter.py` 폴백 템플릿 품질 개선 (Roboto 제거, 독창적 타이포그래피)

### v2.0.0 (2026-02-16)

**Features:**
- 3-Tier 자동 선택 (Mermaid/HTML/Stitch)
- Mermaid 다이어그램 어댑터 (6가지 다이어그램 타입)
- `--mockup`만으로 자동 라우팅
- `--mockup mermaid/html/hifi` 강제 지정 옵션

### v1.0.0 (2026-01-23)

- 초기 버전 (HTML + Stitch 2-tier)

## /auto 연동 (4-Step 워크플로우)

`/auto --mockup` 실행 시 아래 워크플로우가 적용된다. 상세: `/auto REFERENCE.md` Step 2.0.

### Step 2.0.1: 라우팅 + 기본 HTML 생성 (Lead 직접 Python 호출)

MockupRouter.route()로 3-Tier 라우팅 실행. `options.bnw=True` 시 html_adapter가 B&W 기본 팔레트 자동 적용.

### Step 2.0.2: designer 스타일링 (HTML 선택 시)

조건: `backend == HTML`일 때 실행.
designer(sonnet) 에이전트를 스폰하여 Refined Minimal B&W 스타일링. Mermaid 선택 시 스킵.

### Step 2.0.3: PNG 캡처 (Lead 직접 Bash 실행)

```bash
python -c "
import sys; sys.path.insert(0, 'C:/claude')
from pathlib import Path
from lib.mockup_hybrid.export_utils import capture_screenshot, get_output_paths
html_path = Path('docs/mockups/{name}.html')
_, img_path = get_output_paths('{name}')
result = capture_screenshot(html_path, img_path, auto_size=True)
print(f'CAPTURED: {result}' if result else 'CAPTURE_FAILED')
"
```

- 성공: `docs/images/mockups/{name}.png` 생성 -> Step 2.0.4 성공 경로
- 실패 (Playwright 미설치 등): `CAPTURE_FAILED` 출력 -> Step 2.0.4 폴백 경로

### Step 2.0.4: 문서 삽입 (Lead 직접 Edit 실행 -- 대상 문서가 있는 경우만)

- **캡처 성공 시**: `generate_markdown_embed()` 결과를 Edit로 대상 문서에 삽입
  - `![{name}](docs/images/mockups/{name}.png)` + `[HTML 원본](docs/mockups/{name}.html)`
- **캡처 실패 시 (CAPTURE_FAILED)**: HTML 링크로 폴백
  - `[{name} 목업](docs/mockups/{name}.html)` + 경고 메시지
- **대상 문서 없음**: 삽입 스킵 (HTML/PNG 파일만 생성된 상태로 완료)

### 금지 사항

- executor 또는 executor-high가 `docs/mockups/*.html`을 직접 Write하는 것은 금지
- UI 목업 생성 시 반드시 designer 에이전트 경유
- `--bnw`: deprecated (하위 호환용 파싱만). B&W Refined Minimal은 HTML 목업의 기본 스타일
