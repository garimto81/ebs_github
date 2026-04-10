---
name: mockup-hybrid
description: >
  HTML 와이어프레임 + Google Stitch 하이브리드 목업 생성 시스템.
  프롬프트 분석 기반 자동 백엔드 선택, Stitch API 연동, 폴백 지원.
version: 1.0.0

triggers:
  keywords:
    - "mockup"
    - "/mockup"
    - "목업"
    - "와이어프레임"
    - "wireframe"
    - "ui mockup"
    - "--hifi"
    - "--bnw"
    - "stitch"
  file_patterns:
    - "docs/mockups/*.html"
    - "docs/images/mockups/*.png"
  context:
    - "UI 디자인"
    - "화면 설계"
    - "프로토타입"

capabilities:
  - auto_backend_selection
  - html_wireframe_generation
  - stitch_api_integration
  - playwright_screenshot
  - fallback_handling

model_preference: sonnet

auto_trigger: true
---

# Mockup Hybrid Skill

HTML 와이어프레임과 Google Stitch API를 통합한 하이브리드 목업 생성 시스템입니다.

## Plan Mode 안내

Plan mode에서는 이 스킬 사용 불가 (Write/Bash 금지). 대신 `/plan` 커맨드를 사용하여 ASCII 와이어프레임 + mockup-spec을 생성한 후, ExitPlanMode 이후 이 스킬로 실제 목업을 생성한다.

## 아키텍처

```
/mockup [name] --bnw
      │
      ▼
┌──────────────────────────────────────────────────┐
│        Design Context Analyzer (내장)             │
├──────────────────────────────────────────────────┤
│  1. 프롬프트 분석 (키워드, 복잡도)               │
│  2. 환경 검사 (Stitch API 키 유효?)              │
│  3. 자동 선택 규칙 적용                          │
└──────────────────────────────────────────────────┘
      │
      ▼
┌──────────────────────────────────────────────────┐
│              백엔드 라우터                        │
├──────────────────────────────────────────────────┤
│  Stitch 선택 → Stitch Adapter → Stitch API      │
│  HTML 선택   → HTML Adapter   → Local Generator │
└──────────────────────────────────────────────────┘
      │
      ▼
┌──────────────────────────────────────────────────┐
│           Fallback Handler                        │
│  Stitch API 실패 → HTML로 자동 폴백             │
└──────────────────────────────────────────────────┘
      │
      ▼
┌──────────────────────────────────────────────────┐
│           Export Manager                          │
│  HTML + PNG 저장 + 선택 이유 출력                │
└──────────────────────────────────────────────────┘
```

## 옵션

| 옵션 | 동작 | 백엔드 선택 |
|------|------|-------------|
| `--bnw` (기본) | **자동 선택** | 프롬프트 분석 → HTML or Stitch |
| `--force-html` | 강제 HTML | Local HTML 고정 |
| `--force-hifi` | 강제 Stitch | Stitch API 고정 |

## 자동 선택 규칙

### 우선순위

1. **강제 옵션** (사용자 명시)
   - `--force-html` → HTML
   - `--force-hifi` → Stitch

2. **키워드 감지**
   - Stitch 트리거: "프레젠테이션", "고품질", "리뷰용", "이해관계자", "최종", "공식"
   - HTML 트리거: "빠른", "구조", "와이어프레임", "초안", "검토"

3. **컨텍스트**
   - `--prd=PRD-NNNN` → Stitch (문서용 고품질)
   - `--screens=3+` → HTML (빠른 생성)

4. **환경 검사**
   - Stitch API 키 없음 → HTML
   - Rate Limit 초과 → HTML

5. **기본값** → HTML (가장 빠름)

## 핵심 기능: ASCII 다이어그램 → 이미지 교체

`--bnw` 옵션의 **핵심 목적**은 Markdown 파일의 ASCII 다이어그램을 이미지로 교체하는 것입니다.

### 워크플로우

```
ASCII 다이어그램 감지 → HTML 목업 생성 → PNG 캡처 → Markdown 교체
```

### 단계별 동작

| 단계 | 동작 | 출력 |
|:----:|------|------|
| 1 | 대상 파일에서 ASCII 다이어그램 탐지 | 박스/화살표/선 패턴 |
| 2 | 각 ASCII를 HTML 와이어프레임으로 변환 | `docs/mockups/*.html` |
| 3 | Playwright로 스크린샷 캡처 | `docs/images/*.png` |
| 4 | **원본 Markdown의 ASCII를 이미지 참조로 교체** | `![](../images/*.png)` |

### ASCII 감지 패턴

```python
ASCII_PATTERNS = [
    r'[┌┐└┘├┤┬┴┼]',  # 박스 코너/교차점
    r'[─│═║]',        # 선
    r'[→←↑↓▶◀▲▼]',    # 화살표
    r'[╔╗╚╝╠╣╦╩╬]',   # 이중선 박스
]
```

### 교체 옵션

| 옵션 | 설명 |
|------|------|
| `--target=FILE` | 교체 대상 Markdown 파일 지정 |
| `--keep-ascii` | 원본 ASCII를 HTML 주석으로 보존 |
| `--dry-run` | 미리보기 (실제 수정 안함) |
| `--force` | 확인 질문 없이 즉시 교체 |

## 사용 예시

```bash
# ASCII 다이어그램 교체 (핵심 용례)
/mockup "시스템 구조" --bnw --target=docs/ARCHITECTURE.md

# PRD 파일의 모든 ASCII 교체
/mockup --bnw --target=docs/prds/PRD-0001.md

# 자동 선택 → HTML (단순 요청)
/mockup "로그인 화면" --bnw

# 자동 선택 → Stitch (고품질 키워드)
/mockup "대시보드 - 이해관계자 프레젠테이션" --bnw

# 자동 선택 → Stitch (PRD 연결)
/mockup "인증 흐름" --bnw --prd=PRD-0001

# 강제 HTML
/mockup "대시보드" --bnw --force-html

# 강제 Stitch
/mockup "랜딩 페이지" --bnw --force-hifi
```

## 출력 형식

```bash
# 성공 시
🤖 선택: Stitch API (이유: 고품질 키워드 감지)
✅ 생성: docs/mockups/dashboard-hifi.html
📸 캡처: docs/images/mockups/dashboard-hifi.png

# 폴백 시
⚠️ Stitch API 실패 → HTML로 폴백
✅ 생성: docs/mockups/dashboard.html
📸 캡처: docs/images/mockups/dashboard.png
```

## 모듈 구조

```
.claude/skills/mockup-hybrid/
├── SKILL.md                    # 이 파일
├── adapters/
│   ├── html_adapter.py         # HTML 와이어프레임 생성
│   └── stitch_adapter.py       # Stitch API 연동
├── core/
│   ├── analyzer.py             # 프롬프트 분석 + 자동 선택
│   ├── router.py               # 백엔드 라우팅
│   └── fallback_handler.py     # Stitch → HTML 폴백
└── config/
    └── selection_rules.yaml    # 자동 선택 규칙

lib/mockup_hybrid/
├── __init__.py
├── stitch_client.py            # Stitch API 클라이언트
└── export_utils.py             # 내보내기 유틸리티
```

## 환경 변수

```bash
# Google Stitch (무료 - 350 screens/월)
STITCH_API_KEY=your-api-key
STITCH_API_BASE_URL=https://api.stitch.withgoogle.com/v1
```

## Google Stitch 비용

| 항목 | 비용 | 월 한도 |
|------|:----:|---------|
| Standard Mode (Gemini 2.5 Flash) | **무료** | 350 screens/월 |
| Experimental Mode (Gemini 2.5 Pro) | **무료** | 50-200 screens/월 |

> **참고**: Google Labs 실험 단계로 현재 완전 무료. 향후 변경 가능성 있음.

## 연동

| 스킬/에이전트 | 연동 시점 |
|---------------|----------|
| `google-workspace` | Google Drive 업로드 |
| `frontend-dev` | UI 구현 |
| `docs-writer` | PRD 문서 삽입 |

## 관련 문서

- `docs/MOCKUP_HYBRID_GUIDE.md` - 상세 가이드
- `.claude/commands/mockup.md` - 커맨드 정의
- `.claude/templates/mockup-wireframe.html` - HTML 템플릿

## 변경 로그

### v1.0.0 (2026-01-23)

**Features:**
- 초기 버전 릴리스
- HTML 와이어프레임 + Stitch API 하이브리드 지원
- 프롬프트 기반 자동 백엔드 선택
- Stitch → HTML 자동 폴백
