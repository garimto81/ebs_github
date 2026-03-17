---
name: figma
version: 1.0.0
description: >
  This skill should be used when the user needs Figma design-to-code conversion, component mapping, design system rules, HTML-to-Figma capture, or authentication via Figma MCP.
triggers:
  keywords:
    - "--figma"
    - "figma"
    - "피그마"
    - "디자인 구현"
    - "design implementation"
  context:
    - "Figma URL이 포함된 요청"
    - "디자인→코드 변환 요청"
    - "HTML→Figma 캡처 요청"
auto_trigger: false
---

# Figma 디자인 연동 스킬 (`--figma`)

> `/auto "작업" --figma <url>` — Figma 디자인 연동 (5가지 모드)

---

## 사용법

```
/auto "컴포넌트 구현" --figma https://figma.com/design/KEY/Name?node-id=1-2
/auto "컴포넌트 매핑" --figma connect https://figma.com/design/KEY/Name
/auto "디자인 시스템" --figma rules
/auto "페이지 캡처"   --figma capture [newFile|existingFile|clipboard]
/auto "연결 확인"     --figma auth
```

---

## Step 0: 인증 검증 (MANDATORY — 모든 모드 공통)

**모든 Figma 작업 전에 반드시 실행.**

```
1. mcp__plugin_figma_figma__whoami() 호출
2. 응답 확인:
   - 성공: email, handle, plans 반환 → Step 1 진행
   - 실패: MCP 서버 미연결 또는 인증 만료
3. 실패 시 처리:
   - "Figma MCP 서버가 연결되지 않았습니다." 출력
   - "VS Code Command Palette → 'MCP: List Servers' 에서 figma 서버 상태 확인" 안내
   - "인증 만료 시: MCP 서버 재시작으로 OAuth 재인증" 안내
   - 절대 조용히 스킵 금지 → 즉시 중단
```

### 인증 방식 상세

| 항목 | 내용 |
|------|------|
| **인증 방법** | MCP OAuth (브라우저 기반 자동 인증) |
| **토큰 관리** | MCP 플러그인이 자동 관리 (갱신/저장) |
| **API 키** | 불필요 (`FIGMA_ACCESS_TOKEN` 환경변수 불필요) |
| **검증 도구** | `whoami` → email, handle, plans 반환 |
| **권한 확인** | `plans[].seat` → "Full" = 편집 가능, "View" = 읽기 전용 |

### 권한별 가능한 작업

| 권한 (seat) | implement | connect | rules | capture |
|:-----------:|:---------:|:-------:|:-----:|:-------:|
| Full | O | O | O | O |
| View | O (읽기만) | X | O | X |

---

## Step 1: 모드 판별

| 입력 패턴 | 모드 | 설명 |
|-----------|------|------|
| `--figma <url>` | **implement** | URL에서 디자인 추출 → 코드 변환 |
| `--figma connect <url>` | **connect** | 디자인↔코드 컴포넌트 매핑 |
| `--figma rules` | **rules** | 프로젝트 디자인 시스템 규칙 생성 |
| `--figma capture [mode]` | **capture** | HTML 페이지 → Figma 디자인 변환 |
| `--figma auth` | **auth** | 인증 상태 확인만 (Step 0 실행 후 결과 출력) |

---

## Step 2: URL 파싱 (implement, connect 모드)

```bash
cd C:\claude && python lib/figma/url_parser.py "<figma_url>"
```

### 지원 URL 형식

| 형식 | URL 패턴 | 파싱 결과 |
|------|---------|----------|
| Design | `figma.com/design/:fileKey/:fileName?node-id=X-Y` | `file_key=fileKey, node_id=X:Y, url_type=design` |
| File (legacy) | `figma.com/file/:fileKey/:fileName?node-id=X-Y` | `file_key=fileKey, url_type=design` (design과 동일 처리) |
| Branch | `figma.com/design/:fileKey/branch/:branchKey/:fileName` | `file_key=branchKey, url_type=branch` |
| Board | `figma.com/board/:fileKey/:fileName?node-id=X-Y` | `file_key=fileKey, url_type=board` |
| Make | `figma.com/make/:makeFileKey/:makeFileName` | `file_key=makeFileKey, url_type=make` |

### URL 타입별 MCP 도구 라우팅

| url_type | 사용 도구 |
|----------|----------|
| `design` / `branch` | `get_design_context` (기본) |
| `board` | `get_figjam` (FigJam 전용) |
| `make` | `get_design_context` (makeFileKey 사용) |

---

## 모드별 실행 절차

### Mode A: implement (디자인 → 코드)

```
1. URL 파싱 → fileKey, nodeId 추출
2. url_type == "board" → get_figjam(fileKey, nodeId)
   url_type != "board" → get_design_context(fileKey, nodeId)
3. 응답 분석:
   - Code Connect 스니펫 → 기존 코드베이스 컴포넌트 직접 사용
   - 컴포넌트 문서 링크 → 해당 문서 참고하여 사용법 확인
   - 디자인 어노테이션 → 디자이너의 메모/제약 조건 준수
   - 디자인 토큰 (CSS 변수) → 프로젝트 토큰 시스템에 매핑
   - Raw 값 (hex 색상, 절대 위치) → 스크린샷 참조하여 구현
4. 프로젝트 기존 컴포넌트/레이아웃/토큰과 매칭
5. designer 에이전트에 전달 → 코드 구현
```

**MCP 도구 사용 순서:**

| 순서 | 도구 | 용도 |
|:----:|------|------|
| 1 | `get_design_context` | 레이아웃, 스타일, 코드 힌트 추출 (주력) |
| 2 | `get_screenshot` | 시각적 참조 (1:1 visual parity 검증용) |
| 3 | `get_variable_defs` | 디자인 변수 정의 (토큰 매핑용, 선택) |
| 4 | `get_metadata` | 전체 구조 파악 (대형 파일에서 nodeId 탐색용, 선택) |

### Mode B: connect (컴포넌트 매핑)

```
1. URL 파싱 → fileKey, nodeId 추출
2. get_code_connect_map(fileKey, nodeId) → 기존 매핑 확인
3. get_code_connect_suggestions(fileKey, nodeId) → AI 제안
4. 사용자에게 매핑 제안 검토 요청 (AskUserQuestion)
5. 승인된 매핑 → send_code_connect_mappings(fileKey, nodeId, mappings) 저장
```

**또는 단건 추가:**
```
add_code_connect_map(fileKey, nodeId, source, componentName, label)
```

| label 선택지 |
|-------------|
| React, Vue, Svelte, SwiftUI, Compose, Flutter, Web Components, Storybook, Javascript, Swift UIKit, Objective-C UIKit, Java, Kotlin, Android XML Layout, Markdown |

### Mode C: rules (디자인 시스템 규칙)

```
1. create_design_system_rules() 호출
2. 프로젝트 프레임워크 자동 감지 (clientFrameworks, clientLanguages)
3. 반환된 규칙을 프로젝트에 적용 (.claude/rules/ 또는 프로젝트 설정)
```

### Mode D: capture (HTML → Figma)

```
1. generate_figma_design() 호출 (outputMode 없이 → 옵션 안내)
2. 사용자 outputMode 선택:
   - newFile: 새 Figma 파일 생성 (planKey 선택 필요)
   - existingFile: 기존 파일에 추가 (fileKey 필요)
   - clipboard: 클립보드에 복사
3. 캡처 대상 페이지 준비:
   a. HTML에 <script src="https://mcp.figma.com/mcp/html-to-design/capture.js" async></script> 주입
   b. 캡처 CSS 검증: body에 불필요한 background/padding이 없는지 확인
      - body: margin:0, padding:0, background:transparent, display:inline-block
      - wrapper/container: padding 제거
      - 체커보드/장식 배경 제거
      - capture-reset.css 링크 확인 (mockups/capture/ 내 파일)
   c. 로컬 HTTP 서버 실행 (python -m http.server 또는 npx http-server)
   d. 브라우저에서 URL + hash 파라미터로 열기
4. 캡처 ID로 폴링 (5초 간격, max 10회):
   generate_figma_design(captureId="{id}") → status 확인
   - pending/processing → 재시도
   - completed → Figma 파일 URL 반환
```

**Headless 캡처 (브라우저 창 없음):**
```bash
cd C:\claude && python -c "from lib.mockup_hybrid.export_utils import capture_url; capture_url('http://localhost:{port}/{page}#figmacapture={captureId}&figmaendpoint=https%3A%2F%2Fmcp.figma.com%2Fmcp%2Fcapture%2F{captureId}%2Fsubmit&figmadelay=2000')"
```

**외부 URL 캡처 (EXTERNAL):** Playwright MCP 필요. 로컬 script-tag 방식으로 외부 사이트 캡처 불가.

**Mermaid 다이어그램 → FigJam:**
```
generate_diagram(name="다이어그램 제목", mermaidSyntax="graph LR\n  A --> B")
→ FigJam 다이어그램 URL 반환 (사용자에게 markdown 링크로 표시 필수)
지원 타입: graph, flowchart, sequenceDiagram, stateDiagram, gantt
```

---

## /auto 통합 동작 (Step 2.0)

`--figma` 옵션이 `/auto`에 전달되면 **Phase 2 Step 2.0 (옵션 처리)** 단계에서 실행:

```
1. Step 0: whoami() 인증 검증 (실패 시 즉시 중단)
2. Step 1: 모드 판별 (implement | connect | rules | capture | auth)
3. Step 2: URL 파싱 (implement/connect 모드)
4. 모드별 실행:
   - implement → designer 에이전트에 디자인 컨텍스트 전달 → 코드 구현
   - connect → 매핑 제안 → 사용자 승인 → 저장
   - rules → 규칙 생성 → 프로젝트 적용
   - capture → HTML 캡처 → Figma 파일 생성
   - auth → 인증 상태 출력
5. 결과를 Phase 2 구현에 컨텍스트로 반영
```

---

## MCP 도구 전체 참조

| 도구 | 용도 | 모드 |
|------|------|------|
| `whoami` | 인증 상태 확인 | 공통 |
| `get_design_context` | 디자인 레이아웃/스타일/코드 추출 (주력) | implement |
| `get_screenshot` | 노드 스크린샷 캡처 | implement |
| `get_metadata` | XML 구조 메타데이터 | implement |
| `get_variable_defs` | 디자인 변수 정의 | implement |
| `get_figjam` | FigJam 노드 코드 생성 | implement (board) |
| `get_code_connect_map` | 기존 Code Connect 매핑 조회 | connect |
| `get_code_connect_suggestions` | AI 코드 연결 제안 | connect |
| `send_code_connect_mappings` | 매핑 벌크 저장 | connect |
| `add_code_connect_map` | 단건 매핑 추가 | connect |
| `create_design_system_rules` | 디자인 시스템 규칙 프롬프트 | rules |
| `generate_figma_design` | HTML → Figma 캡처/변환 | capture |
| `generate_diagram` | Mermaid → FigJam 다이어그램 | capture |

---

## 에러 처리

| 에러 | 원인 | 처리 |
|------|------|------|
| `whoami` 실패 | MCP 서버 미연결 | "Figma MCP 서버 미연결. VS Code에서 MCP 서버 상태 확인." 출력 후 **즉시 중단** |
| `whoami` 인증 만료 | OAuth 토큰 만료 | "인증 만료. MCP 서버 재시작으로 재인증 필요." 출력 후 **즉시 중단** |
| 잘못된 URL 형식 | 파싱 실패 | "올바른 Figma URL 형식: figma.com/design/:key/:name?node-id=X-Y" 안내 후 **중단** |
| View 권한으로 connect 시도 | seat=View | "현재 View 권한. 컴포넌트 매핑은 Full 권한 필요." 안내 후 **중단** |
| node-id 미존재 | 삭제된 노드 | `get_metadata`로 전체 구조 탐색 → 유사 노드 제안 |
| 캡처 폴링 10회 초과 | 캡처 실패 | "캡처 실패. 브라우저에서 페이지 로드 확인." 안내 후 **중단** |
| HTTP 서버 포트 충돌 | EACCES / EADDRINUSE | 다른 포트로 재시도 (fallback: python -m http.server) |

**옵션 실패 시: 에러 출력, 절대 조용히 스킵 금지.**

---

## 파일 참조

| 파일 | 역할 |
|------|------|
| `lib/figma/url_parser.py` | URL 파싱 유틸리티 (design/branch/board/make 지원) |
| `.claude/agents/designer.md` | Figma 디자인 컨텍스트 활용 섹션 포함 |
| `.claude/skills/auto/REFERENCE.md` | /auto 통합 실행 코드 블록 |
