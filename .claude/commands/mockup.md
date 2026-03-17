---
name: mockup
description: HTML 와이어프레임 + Google Stitch 하이브리드 목업 생성
---

# /mockup - 하이브리드 목업 생성

HTML 와이어프레임과 Google Stitch를 자동 선택하여 최적의 목업을 생성합니다.

## Usage

```bash
/mockup [name] [options]

Options:
  --bnw             (deprecated) B&W Refined Minimal은 이제 기본 스타일. 하위 호환용 파싱만
  --force-html      강제 HTML 와이어프레임
  --force-hifi      강제 Stitch API (고품질)
  --screens=N       생성할 화면 수 (1-5, 기본: 1)
  --prd=PRD-NNNN    연결할 PRD 번호 (자동 삽입)
  --flow            전체 흐름 다이어그램 포함
  --style=TYPE      wireframe (기본) | detailed
```

## 자동 선택 시스템

```
/mockup [name]
      │
      ▼
┌─────────────────────────────────────────────────────┐
│         Design Context Analyzer                      │
├─────────────────────────────────────────────────────┤
│  1. 강제 옵션 확인 (--force-html, --force-hifi)     │
│  2. 키워드 분석 (고품질/빠른)                       │
│  3. 컨텍스트 분석 (PRD 연결, 다중 화면)             │
│  4. 환경 검사 (API 키, Rate Limit)                  │
│  5. 기본값: HTML (가장 빠름)                        │
└─────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────┐
│  HTML 선택 → HTML Adapter → Local Generator         │
│  Stitch 선택 → Stitch Adapter → Google API         │
└─────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────┐
│  Fallback Handler                                    │
│  Stitch 실패 → HTML로 자동 폴백                     │
└─────────────────────────────────────────────────────┘
```

---

## 자동 선택 규칙

### Stitch API 선택 조건

| 조건 | 예시 |
|------|------|
| 고품질 키워드 | "프레젠테이션", "고품질", "리뷰용", "이해관계자", "최종", "공식" |
| PRD 연결 | `--prd=PRD-0001` (문서용 고품질) |
| 강제 옵션 | `--force-hifi` |

### HTML 선택 조건

| 조건 | 예시 |
|------|------|
| 빠른/구조 키워드 | "빠른", "구조", "와이어프레임", "초안", "검토" |
| 다중 화면 | `--screens=3+` (빠른 생성) |
| API 불가 | Stitch API 키 없음 |
| 강제 옵션 | `--force-html` |
| **기본값** | 위 조건 해당 없음 |

---

## 예시

### 자동 선택 예시

```bash
# 자동 선택 → HTML (단순 요청, B&W Refined Minimal 기본 적용)
/mockup "로그인 화면"
# 🤖 선택: HTML Generator (이유: 기본값)

# 자동 선택 → Stitch (고품질 키워드)
/mockup "대시보드 - 이해관계자 프레젠테이션"
# 🤖 선택: Stitch API (이유: 고품질 키워드 감지)

# 자동 선택 → Stitch (PRD 연결)
/mockup "인증 흐름" --prd=PRD-0001
# 🤖 선택: Stitch API (이유: PRD 연결)
```

### 강제 선택 예시

```bash
# 강제 HTML (Stitch 키워드 무시)
/mockup "고품질 대시보드" --force-html
# 📝 선택: HTML Generator (이유: 강제 HTML 옵션)

# 강제 Stitch
/mockup "로그인 화면" --force-hifi
# 🤖 선택: Stitch API (이유: 강제 Stitch 옵션)
```

### 폴백 예시

```bash
# Stitch API 실패 시
/mockup "대시보드 - 최종 리뷰"
# ⚠️ Stitch API 실패 → HTML로 폴백
# 📝 선택: HTML Generator (이유: 폴백)
```

---

## 출력 형식

### 성공

```
🤖 선택: Stitch API (이유: 고품질 키워드 감지)
✅ 생성: docs/mockups/dashboard-hifi.html
📸 캡처: docs/images/mockups/dashboard-hifi.png

📋 Markdown 삽입 코드:
![대시보드](../images/mockups/dashboard-hifi.png)
[HTML 원본](../mockups/dashboard-hifi.html)
```

### 폴백

```
⚠️ Stitch API 실패 → HTML로 폴백
📝 선택: HTML Generator (이유: 폴백)
✅ 생성: docs/mockups/dashboard.html
📸 캡처: docs/images/mockups/dashboard.png
```

---

## 화면 요소

### 선택 가능 요소

| 요소 | 설명 | 예시 |
|------|------|------|
| `header` | 상단 네비게이션 | 로고, 메뉴, 사용자 |
| `sidebar` | 좌측 사이드바 | 메뉴, 필터 |
| `form` | 입력 폼 | 로그인, 회원가입 |
| `table` | 데이터 테이블 | 목록, 관리 화면 |
| `cards` | 카드 그리드 | 대시보드, 갤러리 |
| `modal` | 팝업 모달 | 확인, 상세보기 |

### 레이아웃 옵션

```
┌─────────────────────┐   ┌───────┬─────────────┐   ┌─────────────────────┐
│      1-Column       │   │ Side  │   Content   │   │  Header             │
│      (Default)      │   │ bar   │             │   ├──────────┬──────────┤
│                     │   │       │             │   │  Left    │  Right   │
└─────────────────────┘   └───────┴─────────────┘   └──────────┴──────────┘
```

---

## 스타일 비교

### B&W Refined Minimal (HTML 목업 기본 스타일, --bnw deprecated)

**`designer` 에이전트 내장 Aesthetic Guidelines로 세련된 B&W 목업 생성**

| 항목 | 규칙 |
|------|------|
| 팔레트 | 그레이스케일 (#000~#fff)만 사용 |
| 아이콘 | 사용 금지 (텍스트 레이블만, emoji/SVG 없음) |
| 타이포그래피 | 독창적 선택 (Roboto/Inter/Arial 금지) |
| 레이아웃 | 비대칭, 여백 리듬, 그리드 시스템 적용 |
| 시각적 깊이 | border, shadow, 배경 질감 허용 (색상 없이) |

### --force-html

- 흑백 박스 레이아웃
- 빠른 생성 (5초)
- 구조 중심

### --force-hifi

- AI 생성 고품질 UI
- 현실적인 디자인
- 프레젠테이션용

---

## PRD 연결 (--prd)

```bash
/mockup "인증 화면" --prd=PRD-0003

# 자동 수행:
# 1. Stitch API로 고품질 목업 생성 (PRD 연결 시 자동 선택)
# 2. docs/mockups/PRD-0003/auth-hifi.html 생성
# 3. docs/images/PRD-0003/auth-hifi.png 캡처
# 4. PRD-0003 문서에 시각화 섹션 추가
```

---

## 흐름 다이어그램 (--flow)

```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│  Start  │────▶│  Login  │────▶│ Verify  │────▶│Dashboard│
└─────────┘     └─────────┘     └─────────┘     └─────────┘
                     │
                     ▼
               ┌─────────┐
               │  Error  │
               └─────────┘
```

`--flow` 옵션 사용 시 화면 간 연결 흐름도 함께 생성됩니다.

---

## Google Stitch 비용

| 항목 | 비용 | 월 한도 |
|------|:----:|---------|
| Standard Mode | **무료** | 350 screens/월 |
| Experimental Mode | **무료** | 50-200 screens/월 |

> **참고**: Google Labs 실험 단계로 현재 완전 무료

---

## 환경 변수

```bash
# .env 또는 환경변수 설정
STITCH_API_KEY=your-api-key
STITCH_API_BASE_URL=https://api.stitch.withgoogle.com/v1  # 선택
```

---

## 관련 문서

| 문서 | 용도 |
|------|------|
| `docs/MOCKUP_HYBRID_GUIDE.md` | 상세 가이드 |
| `.claude/skills/mockup-hybrid/SKILL.md` | 스킬 정의 |
| `.claude/templates/mockup-wireframe.html` | HTML 템플릿 |

---

## ASCII 다이어그램 자동 교체 (--mockup `<파일>` 핵심 기능)

`--mockup <파일>` 지정 시 파일 내 ASCII 다이어그램을 **`11-ascii-diagram.md` 디자인 가이드 기준**으로 변환합니다.

> B&W Refined Minimal은 HTML 목업의 기본 스타일입니다 (`--bnw` deprecated). ASCII 교체 워크플로우는 `--mockup <파일>`이 담당합니다.

### 변환 기준 (`11-ascii-diagram.md`)

| ASCII 타입 | 변환 형식 |
|-----------|----------|
| 흐름도 / 시퀀스 / 아키텍처 / 트리 | Mermaid 코드 블록 (저장 파일 기본) |
| UI 화면 / 컴포넌트 목업 | HTML 와이어프레임 + PNG (B&W Refined Minimal 기본 적용) |

### 워크플로우

```
/mockup <파일> --target=docs/example.md
      │
      ▼
┌─────────────────────────────────────────────────────┐
│ Step 1: ASCII 다이어그램 탐지                        │
│   - 대상 Markdown 파일에서 ``` 블록 내 ASCII 검색   │
│   - 박스(┌─┐), 화살표(→, ▼), 선(│, ─) 패턴 감지    │
└─────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────┐
│ Step 2: HTML 목업 생성                               │
│   - 각 ASCII 다이어그램을 HTML 와이어프레임으로 변환│
│   - Black & White 스타일 적용                       │
│   - docs/mockups/{name}-{index}.html 저장           │
└─────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────┐
│ Step 3: PNG 스크린샷 캡처                            │
│   - Playwright로 HTML → PNG 변환                    │
│   - docs/images/{name}-{index}.png 저장             │
└─────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────┐
│ Step 4: Markdown 교체 (핵심)                         │
│   - ASCII 다이어그램 블록을 이미지 참조로 교체      │
│   - ![{caption}](../images/{name}-{index}.png)      │
│   - 원본 ASCII는 주석 또는 삭제                     │
└─────────────────────────────────────────────────────┘
```

### 사용 예시

```bash
# 특정 파일의 ASCII 다이어그램 교체
/mockup "시스템 아키텍처" --target=docs/ARCHITECTURE.md

# PRD 파일의 모든 ASCII 교체
/mockup --target=docs/prds/PRD-0001.md

# 현재 작업 중인 문서 (자동 감지)
/auto --mockup "대시보드 화면"
```

### 교체 전/후 예시

**Before (ASCII):**
```markdown
## 시스템 구조

┌─────────┐     ┌─────────┐
│ Client  │────▶│ Server  │
└─────────┘     └─────────┘
```

**After (이미지):**
```markdown
## 시스템 구조

![시스템 구조](../images/system-architecture-01.png)

[HTML 원본](../mockups/system-architecture-01.html)
```

### 옵션

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `--target=FILE` | 교체 대상 Markdown 파일 | 자동 감지 |
| `--keep-ascii` | 원본 ASCII를 주석으로 보존 | false |
| `--dry-run` | 교체 미리보기 (실제 수정 안함) | false |
| `--all` | 파일 내 모든 ASCII 다이어그램 교체 | true |

### ASCII 감지 패턴

| 패턴 | 설명 | 예시 |
|------|------|------|
| 박스 문자 | `┌ ┐ └ ┘ ├ ┤ ┬ ┴ ┼` | `┌───┐` |
| 선 문자 | `─ │ ═ ║` | `│   │` |
| 화살표 | `→ ← ↑ ↓ ▶ ◀ ▲ ▼` | `──▶` |
| 코너 | `╔ ╗ ╚ ╝` | `╔═══╗` |

### 주의사항

- `--mockup`만으로 HTML 목업 생성 + B&W Refined Minimal 스타일 자동 적용 (`--bnw` deprecated)
- `--target` 없으면 현재 컨텍스트에서 자동 감지
- 교체 전 반드시 확인 질문 표시 (기본값)
- `--force`로 확인 없이 즉시 교체

---

## 관련 커맨드

| 커맨드 | 용도 |
|--------|------|
| `/create prd --visualize` | PRD 생성 시 목업 포함 |
| `/create docs` | API/코드 문서 생성 |

---

## 템플릿 경로

- 와이어프레임: `.claude/templates/mockup-wireframe.html`
- 고품질 폴백: `.claude/templates/mockup-hifi.html`
- 흐름도: `.claude/templates/mockup-flow.html`

---

## 스크린샷 캡처 (여백 없음)

### 기본 명령

```powershell
# 단일 파일 캡처 (900x600 viewport)
npx playwright screenshot "file.html" "output.png" --full-page --viewport-size="900,600"

# 넓은 화면 캡처 (1200x800)
npx playwright screenshot "file.html" "output.png" --full-page --viewport-size="1200,800"
```

### 스크립트 사용

```powershell
# 단일 파일
C:\claude\.claude\scripts\screenshot-capture.ps1 -InputFile "file.html" -OutputFile "output.png"

# 일괄 처리
C:\claude\.claude\scripts\screenshot-capture.ps1 -InputDir "docs/mockups/" -OutputDir "docs/images/"

# 커스텀 viewport
C:\claude\.claude\scripts\screenshot-capture.ps1 -InputFile "file.html" -OutputFile "output.png" -Width 1200 -Height 800
```

### CSS 요구사항 (여백 없는 캡처)

템플릿과 목업 HTML에 적용된 CSS:

```css
body {
    padding: 0;
    margin: 0;
}
.container {
    max-width: 100%;
    margin: 0;
    padding: 15px;  /* 내부 여백만 유지 */
}
```

### 권장 viewport 크기

| 용도 | Width | Height |
|------|:-----:|:------:|
| 표준 목업 | 900 | 600 |
| 넓은 대시보드 | 1200 | 800 |
| 모바일 | 375 | 667 |
| 태블릿 | 768 | 1024 |
