# UI-06 Skin Editor — SE + GE 웹 에디터

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | SE 메인 + GE 8종 모드 웹 전환 와이어프레임 |

---

## 개요

Skin Editor(SE)와 Graphic Editor(GE)는 오버레이 스킨을 편집하는 웹 앱이다. 기존 Quasar 데스크톱 앱(EBS-Skin-Editor PRD v3)을 Next.js + shadcn/ui 웹 앱으로 전환한다.

> 참조: 컨트롤 상세는 `C:\claude\ebs_ui\ebs-skin-editor\docs\EBS-Skin-Editor_v3.prd.md`, BS-03-02 §7

## 1. 라우트 구조

| 라우트 | 화면 | 설명 |
|--------|------|------|
| `/editor/:skinId` | SE 메인 | 스킨 메타데이터/설정 편집 |
| `/editor/:skinId/ge/:mode` | GE 모드별 | 8종 요소 편집 (Board/Player/Blinds/Outs/History/Leaderboard/Field/Strip) |
| `/editor/preview/:skinId` | 미리보기 | 별도 화면, 실시간 갱신 |

## 2. SE 메인 화면 (`/editor/:skinId`)

섹션은 **세로(종적)** 쌓임. 섹션 내부 항목은 **가로(횡적)** 나열.

### 2.1 헤더
- 스킨 이름 드롭다운, Import, Export, Save, Open Preview 버튼

### 2.2 섹션 구성

| 섹션 | Element ID | 컨트롤 수 | 내용 |
|------|:----------:|:--------:|------|
| Skin Metadata | 01~05 | 5 | 이름, 설명, 투명도 제거, 4K, 스케일 |
| Element Grid | 06 | 7 버튼 | 클릭 시 GE 진입 (4+3 Grid) |
| Text/Font | 07~10 | 4 | 대문자, 등장 속도, 폰트, 다국어 |
| Cards | 11~13 | 3 | 카드 미리보기, 세트 관리, 뒷면 |
| Player/Flags | 14~20, 72 | 8 | Variant, Player Set, 원형 마스크, 국기 |
| Action Bar | 21~26 | 6 | Import/Export/Download/Reset/Discard/Use |

### 2.3 Quasar → shadcn/ui 매핑

| Quasar | shadcn/ui |
|--------|----------|
| QInput | Input |
| QSlider | Slider |
| QToggle | Switch |
| QSelect | Select |
| QExpansionItem | Accordion |
| QBtn | Button |
| QColor + QPopupProxy | react-colorful + Popover |
| QImg + QBtn (Import) | FileUpload 커스텀 |

## 3. GE 화면 (`/editor/:skinId/ge/:mode`)

### 3.1 공통 섹션 (전 모드)

| 섹션 | GE ID | 컨트롤 | 내용 |
|------|:-----:|:------:|------|
| Element Selector | GE-02 | Select | 서브요소 선택 (Pattern A만 사이드바) |
| Transform | GE-03~08 | 10 | 좌표, 크기, 회전, 앵커, 마진, 라운드 |
| Animation | GE-09~14 | 6 | Transition In/Out, 커스텀 애니메이션, 속도 |
| Text | GE-15~22 | 8 | 표시, 폰트, 색상, 강조, 정렬, 그림자, 다국어 |
| Background | GE-23 | 1 | 배경 이미지 Import/Delete |

### 3.2 모드별 치수

| 모드 | 패턴 | Canvas (px) | 서브요소 |
|------|:----:|:-----------:|:--------:|
| Board | A | 296x197 | 14 |
| Field | A | 270x90 | 3 |
| Strip | A | 270x90 | 6 |
| Blinds | B | 790x52 | 4 |
| History | B | 345x33 | 3 |
| Player | C | 465x120 | 9 |
| Outs | C | 465x84 | 3 |
| Leaderboard | C | 800x103 | 9 |

## 4. 미리보기 화면 (`/editor/preview/:skinId`)

- 별도 탭/화면, 1920x1080 비율 유지
- SE/GE에서 Save 시 WebSocket으로 자동 갱신
- 듀얼 모니터 또는 별도 브라우저 탭 사용 가정

## 5. 데이터 흐름

| 동작 | 흐름 |
|------|------|
| Import | .gfskin (ZIP) → 클라이언트 JSZip 파싱 → skin.json + 에셋 |
| Save | skin.json → BO REST API → DB 저장 |
| Export | skin.json + 에셋 → .gfskin (ZIP) 다운로드 |
| USE | ConfigurationPreset → WebSocket → Overlay 즉시 반영 |
| Preview | Save 이벤트 → WebSocket → 미리보기 화면 리렌더링 |

## 6. 기술 스택

| 항목 | 기술 |
|------|------|
| 프레임워크 | Next.js 15 (App Router) — Lobby와 동일 |
| UI | shadcn/ui + Tailwind CSS |
| ZIP 처리 | JSZip (브라우저 내) |
| 컬러 피커 | react-colorful |
| 상태 관리 | Zustand (Lobby와 동일) |

## 참조

| 문서 | 경로 |
|------|------|
| SE/GE PRD v3 | `C:\claude\ebs_ui\ebs-skin-editor\docs\EBS-Skin-Editor_v3.prd.md` |
| 스킨 로드/전환 | `docs/02-behavioral/BS-07-overlay/BS-07-03-skin-loading.md` |
| Settings GFX | `docs/02-behavioral/BS-03-settings/BS-03-02-gfx.md` |
| 오버레이 출력 | `docs/03-ui-design/UI-04-overlay-output.md` |
