# Work Plan: 기획자 관점 Designer PRD 작성

**Plan ID**: designer-prd-rewrite
**Created**: 2026-02-13
**Status**: READY
**Output File**: `C:\claude\ebs\docs\01_PokerGFX_Analysis\PRD-0003-Phase1-Designer-PRD.md`
**Estimated Output**: 400-550줄

---

## 1. Context

### 1.1 Original Request

기존 개발자 관점 PRD(`PRD-0003-Phase1-PokerGFX-Clone.md`, 522줄)와 UI 분석 문서(`PokerGFX-UI-Analysis.md`, 686줄)를 기반으로, 기획자/디자이너가 제품 비전과 사용자 경험을 즉시 파악할 수 있는 새로운 PRD를 작성한다. 기존 문서를 수정하지 않고, 신규 파일 1개를 생성한다.

### 1.2 Problem Statement

기존 PRD의 한계:

| 문제 | 구체적 예시 |
|------|------------|
| **SQL 스키마 중심** | `CREATE TABLE cards (uid TEXT UNIQUE, suit TEXT...)` 등 DB 설계가 전면 배치 |
| **GPIO 핀맵 노출** | ESP32 GPIO5-GPIO32 배선표, SPI 통신 상세 |
| **JSON 프로토콜 상세** | `{"type": "card_read", "uid": "04:A2:B3:C4"}` 등 wire format |
| **149개 기능 ID 평면 나열** | AT-001~AT-026, PS-001~PS-013 등 카테고리별 플랫 리스트 |
| **사용자 여정 부재** | 운영자가 방송 시작부터 종료까지 어떤 흐름으로 작업하는지 서술 없음 |
| **제품 비전 부재** | "왜 이 시스템이 필요한가"에 대한 설명 없음 |
| **시각적 구조 부재** | Mermaid 다이어그램, 우선순위 매트릭스 등 시각화 없음 |

### 1.3 Input Documents

| 문서 | 경로 | 줄 수 | 핵심 내용 |
|------|------|:-----:|----------|
| 개발자 PRD | `C:\claude\ebs\docs\01_PokerGFX_Analysis\PRD-0003-Phase1-PokerGFX-Clone.md` | 522 | 149개 기능, 7 카테고리, 5 Sub-Phase, 성공 기준 |
| UI 분석서 | `C:\claude\ebs\docs\01_PokerGFX_Analysis\PokerGFX-UI-Analysis.md` | 686 | 11개 PokerGFX 탭/창 분석, 268개 UI 요소, 30개 신규 발견 기능 |
| Mockup PNG | `01_Mockups_ngd/` | 9개 | Architecture, Action Tracker, Viewer Overlay wireframe |
| Annotated PNG | `02_Annotated_ngd/` | 22개 | 11개 탭/창의 번호 오버레이 스크린샷 |

### 1.4 Research Findings

**기존 문서에서 추출한 핵심 제품 정보:**

- **제품명**: Bracelet Studio EBS (자체 RFID 방송 시스템)
- **벤치마크**: PokerGFX Server 3.111 (2011-2024, 업계 표준 솔루션)
- **핵심 목표**: PokerGFX 100% 기능 복제 (Phase 1)
- **사용자**: 방송 운영자 (1차), 시청자 (2차), 해설자 (3차)
- **기술 스택**: Flutter + Rive (Frontend), 미정 (Server/Firmware)
- **하드웨어**: ESP32 + RFID 리더 (MFRC522 프로토타입, ST25R3911B 프로덕션)
- **핵심 플로우**: 카드 태그 → RFID 읽기 → DB 조회 → WebSocket → 방송 오버레이 (< 200ms)
- **보안**: Trustless Mode (1~30분 딜레이), Live/Delay 이중 파이프라인
- **149개 기능**: AT 26 + PS 13 + VO 14 + GC 25 + SEC 11 + EQ/ST 19 + HH 11 + Server 30

---

## 2. Work Objectives

### 2.1 Core Objective

개발자 구현 명세서와 UI 분석서를 종합하여, 기획자/디자이너가 제품 비전-사용자 경험-화면 구성-우선순위를 즉시 파악할 수 있는 기획 관점 PRD를 신규 작성한다.

### 2.2 Deliverables

| # | Deliverable | Description |
|---|------------|-------------|
| 1 | `PRD-0003-Phase1-Designer-PRD.md` | 기획자 관점 제품 요구사항 문서 (400-550줄) |

### 2.3 Definition of Done

- [ ] 신규 파일 1개 생성 완료
- [ ] 기존 문서 수정 0건
- [ ] 목표 구조 9개 섹션 + 부록 완성
- [ ] 149개 기능이 시나리오/여정 기반으로 그룹핑되어 누락 없이 포함
- [ ] Mermaid 다이어그램 3개 이상 포함
- [ ] 이미지 참조 경로 검증 완료 (상대 경로)

---

## 3. Guardrails

### 3.1 MUST HAVE

| # | Requirement |
|---|------------|
| 1 | 제품 비전 및 "왜 자체 시스템이 필요한가" 명시 |
| 2 | 사용자 페르소나 3종 (운영자, 시청자, 해설자) 정의 |
| 3 | 운영자 사용자 여정: 방송 준비 → 게임 트래킹 → 방송 종료 전체 플로우 |
| 4 | 시청자 사용자 여정: 방송 시청 시 보이는 정보 흐름 |
| 5 | 시스템 개념도 (Mermaid): 하드웨어-서버-프론트엔드 관계 |
| 6 | 화면 구성도: 운영자 화면(Action Tracker, Pre-Start, GFX Console)과 시청자 화면(Viewer Overlay) 구분 |
| 7 | 149개 기능의 시나리오 기반 그룹핑 (기능 ID 보존, 빠짐 없이) |
| 8 | 우선순위 매트릭스 (Impact vs Effort) |
| 9 | 구현 로드맵 (5 Sub-Phase 시각적 표현) |
| 10 | 성공 지표 (KPI) 정의 |
| 11 | 기존 스크린샷/wireframe 이미지 참조 활용 |
| 12 | 데이터 흐름 개념도 (기술 용어 최소화) |

### 3.2 MUST NOT HAVE

| # | Prohibition | Reason |
|---|------------|--------|
| 1 | SQL CREATE TABLE 구문 | 개발자 구현 상세 - 기존 PRD에서 참조 |
| 2 | GPIO 핀맵 / SPI 통신 상세 | 하드웨어 구현 상세 |
| 3 | JSON 프로토콜 페이로드 | 통신 구현 상세 |
| 4 | ESP32 배선도 | 하드웨어 구현 상세 |
| 5 | 기존 문서 수정 | 신규 파일만 생성 |
| 6 | 코드 블록 (SQL, JSON, Python 등) | 기획서에 코드 불필요 |
| 7 | `한글(영문)` AI 패턴 | 프로젝트 규칙 준수 |

---

## 4. Target Document Structure

| # | Section | Content | Est. Lines | Source Mapping |
|---|---------|---------|:----------:|----------------|
| 1 | 제품 비전 및 핵심 가치 | 왜 EBS가 필요한가, PokerGFX 벤치마크 관계, 핵심 차별점 | 40 | 개발자 PRD 1.1-1.2 |
| 2 | 사용자 페르소나 및 시나리오 | 운영자/시청자/해설자 3종 페르소나, 핵심 Pain Point, Goal | 50 | UI 분석서 전체 + PRD 1.2 |
| 3 | 시스템 개념도 | Mermaid 다이어그램: 하드웨어 → 서버 → 프론트엔드 흐름, 기술 용어 최소화 | 40 | PRD 2.1-2.3, 아키텍처 PNG |
| 4 | 핵심 사용자 여정 | 운영자 여정 (방송 준비→트래킹→종료), 시청자 여정 (방송 시청 경험) | 70 | PRD 3.1-3.2 + UI 분석서 1-8장 |
| 5 | 화면 구성 및 인터랙션 설계 | 4대 화면 영역별 구성 요소, 기존 이미지 참조, 화면 전환 흐름 | 100 | UI 분석서 전체 + wireframe PNG |
| 6 | 데이터 흐름 개념도 | 카드 인식 → 화면 표시 플로우, 보안 모드 분기, 비기술적 서술 | 40 | PRD 2.3-2.4, SEC 카테고리 |
| 7 | 우선순위 매트릭스 | Impact vs Effort 4분면, P0/P1/P2 매핑, 149개 기능 분류표 | 60 | PRD 3.1-3.7 전체 기능 목록 |
| 8 | 구현 로드맵 | 5 Sub-Phase Mermaid Gantt, 마일스톤별 사용자 가치 설명 | 50 | PRD 6.1-6.2 |
| 9 | 성공 지표 | KPI 정의 (인식 속도, 인식률, 무중단 운영, 사용자 만족도) | 30 | PRD 1.3, 9 |
| A | 부록: 기능 전체 목록 | 149개 기능 ID + 이름 + 시나리오 매핑 + 우선순위 (참조용) | 70 | PRD 3.1-3.7 + UI 분석서 12장 |
| | **합계** | | **~550** | |

---

## 5. Functional Grouping Strategy

### 5.1 149개 기능의 시나리오 기반 재그룹핑

기존 PRD의 카테고리별 평면 나열을 사용자 시나리오 기반으로 재구성:

| 시나리오 | 기능 ID 범위 | 개수 | 설명 |
|----------|-------------|:----:|------|
| **방송 준비** | PS-001~013, SEC-001~011 일부, GC-017~020 | ~20 | 이벤트/플레이어/블라인드 설정, 보안 모드 선택 |
| **게임 트래킹** | AT-001~026 전체 | 26 | 실시간 액션 입력, 베팅, 보드 관리 |
| **방송 화면** | VO-001~014 전체 | 14 | 시청자에게 보이는 오버레이 요소 |
| **통계 및 분석** | GC-001~012, EQ-001~012, ST-001~007 | ~27 | VPIP, PFR, Equity, 리더보드 |
| **핸드 기록** | HH-001~011 전체 | 11 | 히스토리 저장, 검색, 리플레이, 내보내기 |
| **보안 관리** | SEC-001~011 | 11 | Trustless/Realtime 모드, 딜레이 설정 |
| **시스템 설정** | GC-013~025, Server 관리 30개 | ~40 | 출력 해상도, 카메라, 스킨, 진단 |

### 5.2 누락 방지 체크

| 카테고리 | 기존 수 | 검증 방법 |
|----------|:-------:|----------|
| Action Tracker | 26 | AT-001~AT-026 전수 확인 |
| Pre-Start Setup | 13 | PS-001~PS-013 전수 확인 |
| Viewer Overlay | 14 | VO-001~VO-014 전수 확인 |
| GFX Console | 25 | GC-001~GC-025 전수 확인 |
| Security | 11 | SEC-001~SEC-011 전수 확인 |
| Equity & Stats | 19 | EQ-001~012, ST-001~007 전수 확인 |
| Hand History | 11 | HH-001~HH-011 전수 확인 |
| Server 관리 | 30 | NEW-001~NEW-030 전수 확인 |
| **합계** | **149** | |

---

## 6. Image Reference Strategy

### 6.1 사용할 이미지 (상대 경로)

문서 위치: `C:\claude\ebs\docs\01_PokerGFX_Analysis\PRD-0003-Phase1-Designer-PRD.md`
이미지 기준: 동일 디렉토리의 하위 폴더

| 용도 | 파일 | 상대 경로 |
|------|------|----------|
| 시스템 아키텍처 | `12-architecture-diagram.png` | `01_Mockups_ngd/12-architecture-diagram.png` |
| Action Tracker wireframe | `13-action-tracker-wireframe.png` | `01_Mockups_ngd/13-action-tracker-wireframe.png` |
| Viewer Overlay wireframe | `14-viewer-overlay-wireframe.png` | `01_Mockups_ngd/14-viewer-overlay-wireframe.png` |
| 메인 윈도우 annotated | `01-main-window.png` | `02_Annotated_ngd/01-main-window.png` |
| System 탭 annotated | `08-system-tab.png` | `02_Annotated_ngd/08-system-tab.png` |
| Skin Editor annotated | `09-skin-editor.png` | `02_Annotated_ngd/09-skin-editor.png` |
| Player Overlay annotated | `11-graphic-editor-player.png` | `02_Annotated_ngd/11-graphic-editor-player.png` |

### 6.2 경로 검증 방법

Task 실행 시 `ls` 명령으로 모든 참조 이미지 파일 존재 여부 확인

---

## 7. Task Flow

### 7.1 Dependency Graph

```
Task 1: 입력 문서 분석 및 기능 매핑 테이블 생성
    |
    v
Task 2: Designer PRD 작성 (9개 섹션 + 부록)
    |
    v
Task 3: 이미지 참조 검증 + 기능 누락 검증
```

### 7.2 Detailed Tasks

---

#### Task 1: 입력 문서 분석 및 기능 매핑 테이블 생성

**Agent**: explore (haiku)
**Estimated Time**: 5분
**Input**: 개발자 PRD + UI 분석서

**목적**: Task 2 작성에 필요한 기능 매핑 데이터 준비

**작업 내용**:
1. 개발자 PRD에서 149개 기능 ID-이름-우선순위 추출
2. UI 분석서에서 30개 신규 기능(NEW-001~030) 확인
3. 기능 → 시나리오 매핑 테이블 작성
4. P0/P1/P2 우선순위별 기능 수 집계

**Acceptance Criteria**:
- [ ] 149개 기능 전체 ID 추출 완료
- [ ] 시나리오 기반 그룹핑 완료
- [ ] P0/P1/P2 분포: P0 약 60개, P1 약 70개, P2 약 19개 (기존 PRD + UI 분석 기준)

---

#### Task 2: Designer PRD 작성

**Agent**: executor-high (opus)
**Estimated Time**: 25분
**Input**: Task 1 매핑 테이블 + 개발자 PRD + UI 분석서 + 이미지 파일 목록
**Output**: `C:\claude\ebs\docs\01_PokerGFX_Analysis\PRD-0003-Phase1-Designer-PRD.md`

**작성 원칙**:

1. **관점 전환 (개발자 → 기획자)**:
   - "RFID UID 읽기" → "카드를 테이블에 올리면 자동으로 인식됩니다"
   - "WebSocket 브로드캐스트" → "인식된 카드 정보가 실시간으로 화면에 표시됩니다"
   - "SQLite DB 조회" → "시스템이 카드 정보를 즉시 식별합니다"
   - "GPIO5 SPI Slave Select" → (제거, 언급하지 않음)

2. **시각화 필수**:
   - 시스템 개념도: Mermaid flowchart (하드웨어 → 서버 → 화면)
   - 사용자 여정: Mermaid journey 또는 sequence diagram
   - 구현 로드맵: Mermaid gantt chart
   - 우선순위 매트릭스: 텍스트 4분면 표

3. **기존 이미지 활용**:
   - Architecture diagram, Action Tracker wireframe, Viewer Overlay wireframe 삽입
   - Annotated 스크린샷 중 핵심 화면 참조

4. **기능 그룹핑**:
   - 149개 기능을 시나리오별로 묶되, 각 기능의 기존 ID(AT-001 등)를 괄호로 보존
   - 예: "실시간 액션 입력 (AT-012): FOLD, CHECK, CALL, BET, ALL-IN 5가지 액션 버튼"

5. **언어 규칙**:
   - 한글 출력, 기술 용어는 영어 유지
   - `한글(영문)` 패턴 금지

**섹션별 가이드**:

| 섹션 | 핵심 질문 | 데이터 소스 |
|------|----------|------------|
| 1. 제품 비전 | 왜 자체 시스템을 만드는가? | PRD 1.1 "PokerGFX 100% 복제" 목표 |
| 2. 페르소나 | 누가, 어떤 상황에서, 무엇을 원하는가? | UI 분석서의 운영자/시청자 관점 |
| 3. 시스템 개념도 | 전체 시스템이 어떻게 연결되는가? | PRD 2.1 아키텍처 |
| 4. 사용자 여정 | 방송 한 세션의 처음부터 끝까지? | PRD 3.1-3.2 + PS 카테고리 |
| 5. 화면 구성 | 각 화면에서 무엇이 보이는가? | UI 분석서 전체 + wireframe |
| 6. 데이터 흐름 | 카드를 올리면 어떤 일이 벌어지는가? | PRD 2.3 6단계 흐름 |
| 7. 우선순위 | 무엇을 먼저 만들어야 하는가? | PRD 전체 P0/P1/P2 |
| 8. 로드맵 | 언제까지 무엇이 완성되는가? | PRD 6.1 Sub-Phase |
| 9. 성공 지표 | 어떻게 성공을 측정하는가? | PRD 1.3, 9 |

**Acceptance Criteria**:
- [ ] 9개 섹션 + 부록 구조 완성
- [ ] 400-550줄 범위
- [ ] Mermaid 다이어그램 3개 이상
- [ ] 149개 기능 전체가 시나리오 기반으로 포함 (ID 보존)
- [ ] SQL/JSON/GPIO 코드 블록 0건
- [ ] 이미지 참조 3개 이상
- [ ] `한글(영문)` 패턴 0건

---

#### Task 3: 이미지 참조 + 기능 누락 검증

**Agent**: architect (opus)
**Estimated Time**: 10분
**Input**: 완성된 Designer PRD
**blockedBy**: Task 2

**검증 항목**:

**A. 이미지 참조 검증**:
- [ ] 참조된 모든 이미지 파일이 실제 존재 (`ls` 확인)
- [ ] 상대 경로 형식 올바름 (문서 위치 기준)

**B. 기능 누락 검증**:
- [ ] AT-001~AT-026 (26개) 전체 문서 내 존재
- [ ] PS-001~PS-013 (13개) 전체 문서 내 존재
- [ ] VO-001~VO-014 (14개) 전체 문서 내 존재
- [ ] GC-001~GC-025 (25개) 전체 문서 내 존재
- [ ] SEC-001~SEC-011 (11개) 전체 문서 내 존재
- [ ] EQ-001~EQ-012 (12개) 전체 문서 내 존재
- [ ] ST-001~ST-007 (7개) 전체 문서 내 존재
- [ ] HH-001~HH-011 (11개) 전체 문서 내 존재
- [ ] NEW-001~NEW-030 (30개): 부록에서 언급 또는 본문에서 참조

**C. 금지 패턴 검증**:
- [ ] `grep "CREATE TABLE"` == 0건
- [ ] `grep "GPIO[0-9]"` == 0건
- [ ] `grep '"type":.*"card_read"'` == 0건 (JSON 프로토콜)
- [ ] `grep "SPI\|MOSI\|MISO\|SCK"` == 0건 (하드웨어 상세)
- [ ] `한글(영문)` 패턴 0건

**D. 구조 검증**:
- [ ] 총 줄 수 400-550 범위
- [ ] Mermaid 다이어그램 3개 이상
- [ ] 기존 문서 변경 0건

**Acceptance Criteria**:
- [ ] 이미지 검증 통과
- [ ] 기능 누락 검증: 149개 전체 확인
- [ ] 금지 패턴 0건
- [ ] 불일치 발견 시 Task 2로 회귀하여 수정

---

## 8. Commit Strategy

| Commit | Content | Message |
|:------:|---------|---------|
| 1 | Designer PRD 신규 작성 | `docs(prd): 기획자 관점 Designer PRD 작성` |

**Commit Message Body**:
```
- 개발자 구현 명세를 기획자/디자이너 관점으로 재구성
- 사용자 페르소나 3종, 사용자 여정, 화면 구성도 포함
- 149개 기능을 시나리오 기반으로 재그룹핑 (기능 ID 보존)
- Mermaid 다이어그램 (시스템 개념도, 사용자 여정, 로드맵)
- 우선순위 매트릭스 및 성공 지표(KPI) 정의
- 기존 wireframe/annotated 스크린샷 이미지 활용
```

---

## 9. Success Criteria

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | 기획자가 5분 내 제품 비전 파악 가능 | 섹션 1-2 완성도 |
| 2 | 149개 기능 누락 없음 | grep 기반 기능 ID 전수 검증 |
| 3 | 개발 상세 제거 | SQL/JSON/GPIO 코드 0건 |
| 4 | 시각화 풍부 | Mermaid 3개 + 이미지 3개 이상 |
| 5 | 독립 문서 | 기존 문서 수정 0건 |
| 6 | 줄 수 범위 | 400-550줄 |

---

## 10. Risk Mitigation

| Risk | Impact | Probability | Mitigation |
|------|:------:|:-----------:|-----------|
| 149개 기능 데이터 누락 | HIGH | MEDIUM | Task 1에서 전체 기능 ID 매핑 테이블 선 작성, Task 3에서 카테고리별 전수 검증 |
| 이미지 참조 경로 오류 | MEDIUM | LOW | 문서 위치와 이미지 디렉토리가 동일 부모 (`01_PokerGFX_Analysis/`) 확인됨, Task 3에서 `ls` 검증 |
| 시나리오 그룹핑 시 기능 중복 배치 | LOW | MEDIUM | 부록에서 기능 ID별 1:1 시나리오 매핑으로 중복 없이 관리 |
| 기존 문서 실수 수정 | HIGH | LOW | Task 대상 파일을 명시적으로 신규 파일만 지정, Write tool 사용 |

---

## 11. Reference Documents

| 문서 | 경로 | 용도 |
|------|------|------|
| 개발자 PRD | `C:\claude\ebs\docs\01_PokerGFX_Analysis\PRD-0003-Phase1-PokerGFX-Clone.md` | 149개 기능, 아키텍처, 성공 기준 소스 |
| UI 분석서 | `C:\claude\ebs\docs\01_PokerGFX_Analysis\PokerGFX-UI-Analysis.md` | 11개 탭/창 분석, 30개 신규 기능, 268개 UI 요소 |
| 역공학 PRD | `C:\claude\ebs_reverse\docs\01-plan\pokergfx-rfid-vpt-prd.md` | 시스템 내부 구조 참고 (직접 인용 금지) |
| Feature Checklist | `C:\claude\ebs\docs\01_PokerGFX_Analysis\PokerGFX-Feature-Checklist.md` | 기능 완성도 추적 |
