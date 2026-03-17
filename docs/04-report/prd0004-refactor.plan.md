# PRD-0004 리팩토링 계획서

> **작성일**: 2026-02-18
> **대상**: PRD-0004-EBS-Server-UI-Design.md (v10.0.0, 1356줄)
> **목적**: 중복 제거, 목업 중심 설계, 초심자 친화적 구조 확립
> **산출물**: 리팩토링된 PRD-0004 v11.0.0

---

## 1. 현황 분석

### 1.1 현재 문서 구조

| 장/절 | 줄 범위 | 주요 내용 | 중복 여부 |
|------|---------|-----------|----------|
| **1장** | 48-107 | UI 설계 기초 (시간 모델, 주의력, 자동화, 설계 원칙) | ✅ pokergfx-prd-v2 Part I/II와 중복 |
| **2장** | 109-192 | 화면 구조 (네비게이션 맵, 화면 역할, 공통 레이아웃) | ⚠️ 일부 중복 |
| **3장** | 194-489 | GfxServer 탭별 상세 (Main, Sources, Outputs, GFX, Rules, System) | ✅ 유지 (핵심) |
| **4장** | 490-643 | 별도 창 (Skin Editor, Graphic Editor) | ✅ 유지 (핵심) |
| **5장** | 645-744 | Action Tracker | ⚠️ 일부 중복 |
| **6장** | 746-830 | Viewer Overlay | ✅ pokergfx-prd-v2 Part VI와 중복 |
| **7장** | 832-865 | 모니터링 대시보드 | ⚠️ 일부 중복 |
| **8장** | 867-917 | 시스템 상태 UI | ✅ 유지 (핵심) |
| **9장** | 919-1152 | 운영자 워크플로우 | ✅ pokergfx-prd-v2 Part III와 중복 |
| **부록** | 1155-1334 | UI 집계, 단축키, Screen Spec, 용어집, 관련 문서, 다이어그램 목록 | ⚠️ 일부 정리 필요 |

### 1.2 중복 영역 세부 분석

| 중복 섹션 | PRD-0004 위치 | pokergfx-prd-v2 대응 | 중복도 |
|----------|---------------|---------------------|--------|
| **시간 모델** | 1.1 (52-63줄) | Part I §1 + Part III | 90% |
| **주의력 분배** | 1.2 (66-75줄) | Part I §1 + Part III | 85% |
| **자동화 그래디언트** | 1.3 (77-91줄) | Part I §1 + Part II §4 | 80% |
| **방송 준비 프로세스** | 9.1 (924-982줄) | Part III §1 | 95% |
| **핸드 사이클** | 9.2 (984-1041줄) | Part III §2 | 90% |
| **비상 대응** | 9.3-9.4 (1043-1126줄) | Part III §4 | 85% |
| **Viewer Overlay** | 6장 전체 (746-830줄) | Part VI (그래픽 설계) | 75% |

### 1.3 목업 자산 현황

**PNG 목업** (11개):
```
images/mockups/
├── ebs-main.png                # Main Window
├── ebs-sources.png             # Sources 탭
├── ebs-outputs.png             # Outputs 탭
├── ebs-rules.png               # Rules 탭
├── ebs-system.png              # System 탭
├── ebs-gfx-layout.png          # GFX - Layout 서브탭
├── ebs-gfx-visual.png          # GFX - Visual 서브탭
├── ebs-gfx-display.png         # GFX - Display 서브탭
├── ebs-gfx-numbers.png         # GFX - Numbers 서브탭
├── ebs-skin-editor.png         # Skin Editor 별도 창
└── ebs-graphic-editor.png      # Graphic Editor 별도 창
```

**HTML 목업** (3개):
```
mockups/
├── ebs-server-ui.html          # Main + 탭 전환 인터랙션
├── ebs-skin-editor.html        # Skin Editor 목업
└── ebs-graphic-editor.html     # Graphic Editor 목업
```

**위성 문서** (9개):
```
PRD-0004-screens/
├── main-window.md              # M-01~M-20 요소 카탈로그
├── sources-tab.md              # S-00~S-18 요소 카탈로그
├── outputs-tab.md              # O-01~O-20 요소 카탈로그
├── gfx-tab.md                  # G-01~G-51 (4개 서브탭 통합)
├── rules-tab.md                # R-01~R-06 요소 카탈로그
├── system-tab.md               # Y-01~Y-24 요소 카탈로그
├── skin-editor.md              # SK-01~SK-26 요소 카탈로그
├── graphic-editor.md           # Board/Player 요소 카탈로그
└── commentary-tab.md           # ⚠️ 배제 대상 (SV-021, SV-022)
```

---

## 2. 리팩토링 목표

### 2.1 핵심 원칙

1. **중복 제거**: pokergfx-prd-v2와 겹치는 개념 설명은 참조 링크로 대체
2. **목업 우선**: 각 화면 섹션은 목업 이미지 → 설명 → 요소 테이블 순서
3. **초심자 친화**: UI를 처음 보는 사람도 5분 안에 전체 그림 파악 가능
4. **허브 vs 위성**: 허브(PRD-0004)는 전체 조감도, 위성(screen-specs)은 구현 상세
5. **목표 줄 수**: 1356줄 → 600-700줄 (50% 압축)

### 2.2 삭제 대상 섹션

| 섹션 | 줄 범위 | 삭제 사유 | 대체 방안 |
|------|---------|-----------|----------|
| **1.1 시간 모델** | 52-63 | pokergfx-prd-v2 Part I/III 중복 | 참조 링크로 대체 |
| **1.2 주의력 분배** | 66-75 | pokergfx-prd-v2 Part I 중복 | 참조 링크로 대체 |
| **1.3 자동화 그래디언트** | 77-91 | pokergfx-prd-v2 Part I/II 중복 | 참조 링크로 대체 |
| **1.4 설계 원칙** | 94-106 | 일부는 2.1에서 간략 언급으로 충분 | 핵심만 2.1에 통합 |
| **6장 Viewer Overlay** | 746-830 (85줄) | pokergfx-prd-v2 Part VI 중복 | 참조 링크로 대체 |
| **7장 모니터링 대시보드** | 832-865 (34줄) | 9.2 핸드 사이클에서 암묵적 설명됨 | 9.2에 통합 |
| **9.1 방송 준비** | 924-982 (59줄) | pokergfx-prd-v2 Part III §1 중복 | 참조 링크로 대체 |
| **9.2 핸드 사이클** | 984-1041 (58줄) | pokergfx-prd-v2 Part III §2 중복 | 참조 링크로 대체 |
| **9.3-9.4 비상 대응** | 1043-1126 (84줄) | pokergfx-prd-v2 Part III §4 중복 | 참조 링크로 대체 |
| **9.5 예외 처리 흐름** | 1128-1151 (24줄) | 8장 시스템 상태 UI와 중복 | 8장에 통합 |
| **부록 D 용어집** | 1220-1248 (29줄) | pokergfx-prd-v2 부록 용어집과 중복 | 참조 링크로 대체 |
| **부록 F 다이어그램 목록** | 1263-1332 (70줄) | 실제 참조 빈도 낮음 | 삭제 또는 ebs_reverse로 이동 |

**삭제 총량**: ~497줄 (37%)

---

## 3. 새 문서 구조

### 3.1 제안 목차 (v11.0.0)

```markdown
# PRD-0004: EBS Server UI Design

## 메타데이터
- Frontmatter (version, status, dependencies 등)
- 이 문서의 사용법 (읽는 법, 관련 문서 링크)

## 1장: 전체 화면 구조
1.1 네비게이션 맵 (Mermaid 다이어그램)
1.2 화면 역할 한눈에 보기 (테이블)
1.3 설계 원칙 요약 (핵심 3-4개만)
1.4 공통 레이아웃 (Preview Panel + Control Panel + 탭 영역)

## 2장: Main Window
[목업 이미지: ebs-main.png]
2.1 이 화면의 역할
2.2 레이아웃 구역 설명
2.3 핵심 UI 요소 (M-01~M-20 중 P0/P1만)
2.4 더 알아보기 → PRD-0004-screens/main-window.md

## 3장: Sources 탭
[목업 이미지: ebs-sources.png]
3.1 이 화면의 역할
3.2 레이아웃 구역 설명
3.3 핵심 UI 요소 (S-00~S-18 중 P0/P1만)
3.4 더 알아보기 → PRD-0004-screens/sources-tab.md

## 4장: Outputs 탭
[목업 이미지: ebs-outputs.png]
4.1 이 화면의 역할
4.2 레이아웃 구역 설명
4.3 핵심 UI 요소 (O-01~O-20 중 P0/P1만)
4.4 더 알아보기 → PRD-0004-screens/outputs-tab.md

## 5장: GFX 탭 (4개 서브탭)
5.1 GFX 탭 구조 개요
5.2 Layout 서브탭 [ebs-gfx-layout.png]
5.3 Visual 서브탭 [ebs-gfx-visual.png]
5.4 Display 서브탭 [ebs-gfx-display.png]
5.5 Numbers 서브탭 [ebs-gfx-numbers.png]
5.6 더 알아보기 → PRD-0004-screens/gfx-tab.md

## 6장: Rules 탭
[목업 이미지: ebs-rules.png]
6.1 이 화면의 역할
6.2 핵심 UI 요소 (R-01~R-06)
6.3 더 알아보기 → PRD-0004-screens/rules-tab.md

## 7장: System 탭
[목업 이미지: ebs-system.png]
7.1 이 화면의 역할
7.2 레이아웃 구역 설명
7.3 핵심 UI 요소 (Y-01~Y-24 중 P0/P1만)
7.4 더 알아보기 → PRD-0004-screens/system-tab.md

## 8장: Skin Editor (별도 창)
[목업 이미지: ebs-skin-editor.png]
8.1 이 창의 역할
8.2 레이아웃 구역 설명
8.3 핵심 UI 요소 (SK-01~SK-26 중 P1만)
8.4 더 알아보기 → PRD-0004-screens/skin-editor.md

## 9장: Graphic Editor (별도 창)
[목업 이미지: ebs-graphic-editor.png]
9.1 이 창의 역할
9.2 레이아웃 구역 설명
9.3 Board/Player 요소 개요
9.4 더 알아보기 → PRD-0004-screens/graphic-editor.md

## 10장: Action Tracker (별도 앱)
10.1 AT의 역할 (GfxServer와 관계)
10.2 GfxServer와의 상호작용 지점 (M-14, M-18, Y-01~Y-02)
10.3 더 알아보기 → pokergfx-prd-v2 Part IV §3

## 11장: 시스템 상태 UI
11.1 에러 상태 (6가지 유형 + UI 피드백)
11.2 로딩 상태 (6가지 단계 + UI 표시)
11.3 비활성 상태 (7가지 조건 + 시각적 표시)

## 부록
A. UI 요소 전체 집계 (화면별 P0/P1/P2 분포)
B. 전역 단축키 (F5, F7, F8, Ctrl+L 등)
C. 관련 문서 색인 (pokergfx-prd-v2, screen-specs, feature-mapping)

## 변경 이력
v11.0.0 리팩토링 변경 내역
```

### 3.2 장별 템플릿 예시

**[2장: Main Window]**

```markdown
## 2장: Main Window

> **단축키**: 없음 (기본 화면)
> **목업**: `images/mockups/ebs-main.png`
> **HTML**: [ebs-server-ui.html](mockups/ebs-server-ui.html)
> **요소 수**: 20개 (P0: 11, P1: 7, P2: 2)

![Main Window Mockup](images/mockups/ebs-main.png)

### 2.1 이 화면의 역할

Main Window는 GfxServer의 기본 화면으로, **본방송 중 시스템 모니터링과 긴급 조작**을 담당한다.
운영자는 방송 중 주의력의 15%만 이 화면에 할당하며, 나머지 85%는 Action Tracker에 집중한다.

- **모니터링**: Preview Panel로 Venue/Broadcast Canvas 실시간 확인
- **상태 표시**: CPU/GPU/RFID/AT 연결 상태 시각화
- **긴급 조작**: Reset Hand, Register Deck, Lock Toggle 등 즉시 실행 버튼

### 2.2 레이아웃 구역 설명

레이아웃은 좌측 Preview Panel(16:9 Chroma Key Blue)과 우측 Status Panel(CPU/GPU/RFID/AT 상태) + Quick Actions(Reset Hand, Register, Launch AT, Recording)로 구성되며, 하단에 탭 네비게이션이 배치된다.

### 2.3 핵심 UI 요소

아래는 P0/P1 우선순위 요소만 표시. 전체 M-01~M-20 상세는 [main-window.md](PRD-0004-screens/main-window.md) 참조.

| ID | 요소 | 타입 | 설명 | 우선순위 |
|:--:|------|------|------|:--------:|
| M-02 | Preview Panel | Canvas | Broadcast Canvas 실시간 렌더링 (16:9 Chroma Key Blue) | P0 |
| M-03 | CPU Indicator | ProgressBar | CPU 사용률 (Green<60%, Yellow<85%, Red≥85%) | P1 |
| M-04 | GPU Indicator | ProgressBar | GPU 사용률 (동일 색상 코딩) | P0 |
| M-05 | RFID Status | StatusGrid | 12개 리더 상태 (Green/Yellow/Red) | P0 |
| M-07 | Lock Toggle | ToggleButton | 전역 설정 잠금 (Ctrl+L) | P0 |
| M-08 | Secure Delay | ToggleButton | 딜레이 버퍼 활성화 (Ctrl+D) *(추후 개발)* | P2 |
| M-09 | Preview Checkbox | Checkbox | GPU 프리뷰 활성화 | P0 |
| M-11 | Reset Hand | Button | 현재 핸드 초기화 (F5) | P0 |
| M-13 | Register Deck | Button | 52장 UID 매핑 (F7) | P0 |
| M-14 | Launch AT | Button | Action Tracker 실행 (F8) | P0 |
| M-17 | Hand Counter | Label | 현재 핸드 번호 표시 | P1 |
| M-18 | Connection Status | StatusIndicator | AT 연결 상태 (Green/Red) | P0 |

### 2.4 더 알아보기

- **전체 요소 카탈로그**: [PRD-0004-screens/main-window.md](PRD-0004-screens/main-window.md)
- **인터랙션 패턴**: 동일 문서 "Interaction Patterns" 섹션
- **워크플로우**: pokergfx-prd-v2 Part III §2 (핸드 사이클)
```

### 3.3 각 장에서 참조할 pokergfx-prd-v2 섹션

| PRD-0004 장 | 참조할 pokergfx-prd-v2 섹션 | 링크 형식 |
|-------------|------------------------|----------|
| 1장 (전체 구조) | Part II §3 (시스템 조감도) | `> 시스템 전체 아키텍처는 [pokergfx-prd-v2 Part II §3](../../ebs_reverse/docs/01-plan/pokergfx-prd-v2.md#3-시스템-전체-조감도) 참조` |
| 10장 (AT) | Part IV §3 (ActionTracker) | `> AT 화면 구성과 워크플로우는 [pokergfx-prd-v2 Part IV §3](../../ebs_reverse/docs/01-plan/pokergfx-prd-v2.md#actiontracker) 참조` |
| 삭제된 9.1 (방송 준비) | Part III §1 | `> 방송 준비 프로세스는 [pokergfx-prd-v2 Part III §1](../../ebs_reverse/docs/01-plan/pokergfx-prd-v2.md#1-방송-준비-프로세스) 참조` |
| 삭제된 9.2 (핸드 사이클) | Part III §2 | `> 핸드 사이클은 [pokergfx-prd-v2 Part III §2](../../ebs_reverse/docs/01-plan/pokergfx-prd-v2.md#2-핸드-사이클) 참조` |
| 삭제된 9.3-9.4 (비상 대응) | Part III §4 | `> 비상 대응 절차는 [pokergfx-prd-v2 Part III §4](../../ebs_reverse/docs/01-plan/pokergfx-prd-v2.md#4-비상-대응) 참조` |
| 삭제된 6장 (Viewer Overlay) | Part VI | `> Viewer Overlay 상세는 [pokergfx-prd-v2 Part VI](../../ebs_reverse/docs/01-plan/pokergfx-prd-v2.md#part-vi-그래픽-설계) 참조` |

---

## 4. 위성 문서 업데이트 계획

### 4.1 PRD-0004-screen-specs.md

**현재 구조**: 단일 파일에 9개 화면 통합 (main-window, sources-tab 등)

**업데이트 필요 사항**:
1. **목업 이미지 경로 추가**: 각 화면 시작 부분에 `![Mockup](../images/mockups/ebs-xxx.png)` 추가
2. **P2 요소 숨김**: Element Catalog 테이블에서 P2 요소를 접기(collapsible) 또는 하단 섹션으로 이동
3. **허브 문서 역참조**: 각 화면 상단에 "허브 문서: PRD-0004 X장" 명시
4. **Navigation 섹션 강화**: 화면 간 전환 경로를 Mermaid로 시각화

### 4.2 PRD-0004-feature-mapping.md

**현재 상태**: 149개 기능 전체 매핑 완료 (147개 매핑, 2개 배제)

**업데이트 필요 사항**:
1. **매핑 검증**: 리팩토링 후 요소 ID가 변경되지 않았는지 확인
2. **Commentary 배제 명확화**: SV-021, SV-022의 배제 사유를 허브 문서와 동일하게 유지

### 4.3 PRD-0004-technical-specs.md

**현재 상태**: v9.0.0에서 분리된 기술 명세서

**업데이트 필요 사항**:
1. **허브 문서 참조 갱신**: v11.0.0 구조에 맞게 상호 참조 링크 수정
2. **중복 제거 확인**: pokergfx-prd-v2와 중복되는 기술 개념 재점검

---

## 5. 예상 영향 파일 목록

### 5.1 수정 대상 (3개)

| 파일 | 경로 | 수정 내용 |
|------|------|----------|
| **PRD-0004** | `docs/01_PokerGFX_Analysis/PRD-0004-EBS-Server-UI-Design.md` | 전면 리팩토링 (1356줄 → ~650줄) |
| **screen-specs** | `docs/01_PokerGFX_Analysis/PRD-0004-screen-specs.md` | 목업 이미지 추가, 허브 역참조, P2 재배치 |
| **feature-mapping** | `docs/01_PokerGFX_Analysis/PRD-0004-feature-mapping.md` | 매핑 테이블 검증 |

### 5.2 참조 확인 대상 (5개)

| 파일 | 경로 | 확인 사항 |
|------|------|----------|
| **pokergfx-prd-v2** | `C:/claude/ebs_reverse/docs/01-plan/pokergfx-prd-v2.md` | 참조 섹션 존재 여부 (Part III, Part VI 등) |
| **technical-specs** | `docs/01_PokerGFX_Analysis/PRD-0004-technical-specs.md` | 허브 문서 참조 링크 갱신 |
| **PokerGFX-UI-Analysis** | `docs/01_PokerGFX_Analysis/PokerGFX-UI-Analysis.md` | 상호 참조 유지 |
| **PokerGFX-Feature-Checklist** | `docs/01_PokerGFX_Analysis/PokerGFX-Feature-Checklist.md` | feature-mapping 참조 유지 |
| **CLAUDE.md** | `CLAUDE.md` | Key Documents 섹션 갱신 (v11.0.0 명시) |

### 5.3 삭제 대상 (1개)

| 파일 | 경로 | 삭제 사유 |
|------|------|----------|
| **commentary-tab.md** | `docs/01_PokerGFX_Analysis/PRD-0004-screens/commentary-tab.md` | 배제 기능 (SV-021, SV-022) |

---

## 6. 위험 요소 및 완화 전략

### 6.1 식별된 위험

| 위험 | 영향도 | 완화 전략 |
|------|:------:|----------|
| **목업 이미지 경로 오류** | 중 | 리팩토링 후 모든 이미지 링크 검증 (Glob + grep) |
| **pokergfx-prd-v2 참조 끊김** | 고 | 참조 섹션 헤더가 변경되지 않았는지 확인 (ebs_reverse 레포 검증) |
| **Feature Mapping 불일치** | 중 | 요소 ID 변경 여부 확인 (M-01~M-20 등) |
| **Screen Spec 역참조 누락** | 중 | 각 화면 상단에 "더 알아보기" 링크 추가 확인 |
| **줄 수 목표 미달** | 하 | 1차 리팩토링 후 재측정, 필요 시 부록 추가 압축 |

### 6.2 검증 체크리스트

리팩토링 완료 후 반드시 확인할 항목:

- [ ] 모든 목업 이미지 링크 정상 렌더링 확인
- [ ] pokergfx-prd-v2 참조 링크 클릭 가능 확인 (9개)
- [ ] Screen Spec 역참조 링크 클릭 가능 확인 (9개)
- [ ] Feature Mapping 테이블 요소 ID 일치 확인
- [ ] 전역 단축키 테이블 정확성 확인
- [ ] UI 집계 테이블 재계산 (삭제된 섹션 반영)
- [ ] 변경 이력 v11.0.0 작성
- [ ] 줄 수 600-700줄 범위 확인

---

## 7. 실행 계획

### 7.1 단계별 작업 순서

| 단계 | 작업 | 예상 시간 | 산출물 |
|:----:|------|:--------:|--------|
| 1 | 중복 섹션 삭제 (1장, 6장, 9장) | 10분 | PRD-0004 v11.0.0-draft-1 |
| 2 | 새 목차 구조 적용 (1-11장) | 15분 | PRD-0004 v11.0.0-draft-2 |
| 3 | 각 장에 목업 이미지 삽입 | 10분 | PRD-0004 v11.0.0-draft-3 |
| 4 | pokergfx-prd-v2 참조 링크 추가 | 10분 | PRD-0004 v11.0.0-draft-4 |
| 5 | Screen Spec "더 알아보기" 링크 추가 | 10분 | PRD-0004 v11.0.0-draft-5 |
| 6 | 부록 압축 (용어집, 다이어그램 목록 삭제) | 5분 | PRD-0004 v11.0.0-draft-6 |
| 7 | 변경 이력 작성 | 5분 | PRD-0004 v11.0.0 |
| 8 | Screen Spec 목업 이미지 추가 | 10분 | PRD-0004-screen-specs.md 갱신 |
| 9 | 검증 체크리스트 실행 | 15분 | 검증 보고서 |
| 10 | CLAUDE.md 갱신 | 5분 | CLAUDE.md v13.1.0 |

**총 예상 시간**: 95분 (~1.5시간)

### 7.2 검증 명령어

```bash
# 1. 줄 수 확인
wc -l docs/01_PokerGFX_Analysis/PRD-0004-EBS-Server-UI-Design.md

# 2. 목업 이미지 링크 검증
grep -o 'images/mockups/.*\.png' docs/01_PokerGFX_Analysis/PRD-0004-EBS-Server-UI-Design.md | while read img; do
  [ -f "docs/01_PokerGFX_Analysis/$img" ] || echo "Missing: $img"
done

# 3. pokergfx-prd-v2 참조 링크 검증 (ebs_reverse 레포)
grep -o 'ebs_reverse/docs/.*\.md#[^)]*' docs/01_PokerGFX_Analysis/PRD-0004-EBS-Server-UI-Design.md

# 4. Screen Spec 링크 검증
grep -o 'PRD-0004-screens/.*\.md' docs/01_PokerGFX_Analysis/PRD-0004-EBS-Server-UI-Design.md | while read spec; do
  [ -f "docs/01_PokerGFX_Analysis/$spec" ] || echo "Missing: $spec"
done

# 5. 요소 ID 중복 확인
grep -oE '[MSOGRY]-[0-9]{2}' docs/01_PokerGFX_Analysis/PRD-0004-EBS-Server-UI-Design.md | sort | uniq -d
```

---

## 8. 기대 효과

### 8.1 정량적 개선

| 지표 | 현재 (v10.0.0) | 목표 (v11.0.0) | 개선율 |
|------|----------------|----------------|--------|
| **총 줄 수** | 1,356줄 | 600-700줄 | **-48~-52%** |
| **중복 제거** | 497줄 중복 | 0줄 중복 | **100%** |
| **목업 미활용 섹션** | 9개 장 중 4개 | 0개 | **100%** |
| **pokergfx-prd-v2 참조** | 0개 | 9개 | **∞** |
| **초심자 읽기 시간** | 60-90분 | 20-30분 | **-66%** |

### 8.2 정성적 개선

1. **중복 제거**: 독자가 두 문서(PRD-0004, pokergfx-prd-v2)를 오가며 동일 내용을 반복 읽지 않음
2. **목업 우선**: 각 화면의 시각적 이해가 텍스트 설명보다 선행하여 인지 부하 감소
3. **초심자 친화**: "이 문서 하나로 UI 전체를 파악할 수 있다"는 명확한 가이드 제공
4. **허브-위성 분리**: 개요(PRD-0004)와 상세(screen-specs)의 역할이 명확하여 구현 단계에서 참조 효율 증가
5. **유지보수성**: 중복 제거로 향후 변경 사항이 단일 문서(pokergfx-prd-v2)에만 반영되어 일관성 유지

---

## 9. 승인 및 실행

### 9.1 승인 기준

- [ ] Team Lead 확인: 리팩토링 방향 및 목표 줄 수 승인
- [ ] 위험 요소 완화 전략 검토 완료
- [ ] 예상 영향 파일 목록 확정

### 9.2 실행 시점

- **즉시 실행 가능**: 이 계획서 승인 즉시 단계별 작업 시작
- **병렬 작업 불가**: PRD-0004 수정 중 다른 작업자의 동일 파일 수정 금지

### 9.3 롤백 계획

만약 리팩토링 결과가 부적합할 경우:
1. Git에서 v10.0.0 태그로 복원
2. 이 계획서 "위험 요소" 섹션 재검토
3. 수정된 계획서로 재실행

---

**계획서 작성자**: doc-analyst (Agent)
**작성일**: 2026-02-18
**승인 대기**: Team Lead
