# PokerGFX 매뉴얼 v3.2.0 기반 Step별 요소 설계 Work Plan

## 배경 (Background)

- **요청 내용**: PRD-0004(v21.0.0, 1,757줄)의 Step 1~9 각각에 대해, PokerGFX 매뉴얼 v3.2.0 원문과 완전 대조하여 누락/오류 요소를 식별하고, Step별 완전한 요소 설계 문서를 작성
- **해결하려는 문제**:
  1. PRD-0004의 Element Catalog는 역설계/OCR 기반 추론 + 매뉴얼 부분 인용으로 구성됨. 매뉴얼 전체 범위와의 완전성 검증이 미수행
  2. `PokerGFX-Manual-v3.2.0-Element-Reference.md`(393줄)에 매뉴얼 원문이 정리되었으나, 이 참조 문서와 PRD-0004 Element Catalog 간 1:1 매핑 검증이 없음
  3. PRD-0004에 `N/A` (PRD ID 없음)로 분류된 매뉴얼 요소들이 다수 존재하며, 이들의 EBS 설계 결정(Keep/Drop/Defer)이 명시적으로 문서화되지 않음
- **선행 작업**:
  - `prd0004-manual-update.plan.md`: 매뉴얼 설명을 PRD-0004 Element Catalog에 통합 (완료, v21.0.0 반영)
  - `prd0004-design-implications.plan.md`: 설계 시사점 4개 섹션 품질 개선 (완료)

## 구현 범위 (Scope)

### 포함 항목
1. 매뉴얼 v3.2.0 전체 섹션을 Step 0~9에 1:1 매핑
2. 각 Step의 Element Catalog와 매뉴얼 요소 간 완전 대조 (Gap Analysis)
3. PRD-0004에 없지만 매뉴얼에 있는 요소 식별 → EBS 설계 결정 부여 (Keep/Drop/Defer + 근거)
4. PRD-0004에 있지만 매뉴얼에 없는 요소 식별 → 신규 추가 근거 문서화
5. Step별 요소 완전 목록 (ID, 요소명, 매뉴얼 원문 설명, 매뉴얼 페이지, EBS 설계 결정)
6. PokerGFX 대비 EBS 변경점 명시

### 제외 항목
- PRD-0004 원본 수정 (본 계획의 산출물은 별도 설계 문서)
- Command Center 상세 요소 (기존 Action Tracker → CC로 이름 변경. 별도 설계: `ebs-command-center.design.md` 범위)
- Skin Editor / Graphic Editor 개별 요소의 픽셀 스펙 (SK/GE 레벨 스펙은 범위 외)
- 매뉴얼 PDF 원본 번역

## 영향 파일 (Affected Files)

### 입력 파일 (읽기 전용)
| 파일 | 용도 |
|------|------|
| `C:\claude\ebs\docs\01_PokerGFX_Analysis\PRD-0004-EBS-Server-UI-Design.md` | 현재 설계 문서 (1,757줄, v21.0.0) — Step별 Element Catalog 추출 |
| `C:\claude\ebs\docs\01_PokerGFX_Analysis\PokerGFX-Manual-v3.2.0-Element-Reference.md` | 매뉴얼 원문 참조 (393줄) — 공식 설명 + 페이지 번호 |
| `C:\claude\ebs\docs\01_PokerGFX_Analysis\03_Reference_ngd\user-manual_split\user-manual_p021-040.pdf` | 매뉴얼 PDF p.33-40 (Main Window, Sources) |
| `C:\claude\ebs\docs\01_PokerGFX_Analysis\03_Reference_ngd\user-manual_split\user-manual_p041-060.pdf` | 매뉴얼 PDF p.41-60 (Outputs, GFX 1/2/3, System) |
| `C:\claude\ebs\docs\01_PokerGFX_Analysis\03_Reference_ngd\user-manual_split\user-manual_p061-080.pdf` | 매뉴얼 PDF p.61-80 (Skin Editor, Graphic Editor) |
| `C:\claude\ebs\docs\01_PokerGFX_Analysis\03_Reference_ngd\user-manual_split\user-manual_p081-100.pdf` | 매뉴얼 PDF p.81-100 (Action Tracker) |
| `C:\claude\ebs\docs\01_PokerGFX_Analysis\03_Reference_ngd\user-manual_split\user-manual_p101-113.pdf` | 매뉴얼 PDF p.101-113 (MultiGFX, Appendix) |
| `C:\claude\ebs\docs\00-prd\ebs-console.prd.md` | 상위 PRD — 트리아지 기준 (v1.0 Keep / v2.0 Defer / v3.0 Defer / Drop) |
| `C:\claude\ebs\docs\01_PokerGFX_Analysis\ebs-console-feature-triage.md` | 149개 기능 트리아지 결과 |

### 신규 생성 파일
| 파일 | 설명 |
|------|------|
| `C:\claude\ebs\docs\02-design\pokergfx-manual-step-element-design.design.md` | 최종 산출물 — Step별 완전 요소 설계 문서 |

## 위험 요소 (Risks)

1. **PDF 직접 읽기 불가**: 현재 환경에서 `pdftoppm`이 설치되어 있지 않아 매뉴얼 PDF를 직접 렌더링할 수 없음. 대응: `PokerGFX-Manual-v3.2.0-Element-Reference.md`(393줄)가 매뉴얼 핵심 내용을 이미 텍스트로 정리하고 있으므로 이를 1차 소스로 사용. PDF는 Element Reference에 누락된 세부사항 확인 시에만 참조.

2. **Element Reference 문서의 불완전성**: Element Reference에는 `N/A (AT 전용)` 태그가 붙은 요소가 40개 이상 존재하며, 이들은 매뉴얼에 있지만 PRD-0004 Element Catalog에 미포함. 이 요소들의 상당수는 Action Tracker 범위이므로 본 문서 범위에서 제외해야 하나, Server UI에 해당하는 요소가 섞여 있을 가능성이 있음. 대응: N/A 요소를 하나씩 검토하여 Server UI 해당 여부를 판단.

3. **매뉴얼 페이지와 PRD Step 간 경계 모호**: 매뉴얼은 기능별로, PRD-0004는 탭별로 구성됨. Secure Delay처럼 Outputs 탭(Step 4)에서 설정하지만 매뉴얼 p.44-46에 걸쳐 별도 섹션으로 설명되는 기능이 있음. 대응: 매뉴얼 섹션을 PRD Step에 매핑할 때 "설정 위치 기준"을 적용 (예: Secure Delay → Step 4 Outputs).

4. **산출물 크기 초과 위험**: Step 10개 x 요소 평균 20개 = 약 200행 테이블 + 설명 = 400~600줄 예상. 대응: 스켈레톤-퍼스트 + 섹션별 Edit 패턴으로 작성. 단일 Write 금지.

5. **ebs-console-feature-triage.md와 PRD-0004 간 ID 불일치**: Feature Triage는 `AT-001`~`SV-030` 체계를, PRD-0004는 `M-01`~`SK-26` 체계를 사용. 크로스 레퍼런스가 PRD-0004 부록 C에 부분적으로 존재하나 완전하지 않음. 대응: 두 체계의 매핑은 본 산출물에서 명시적으로 수행.

## 분석 전략 (Analysis Strategy)

### 데이터 소스 우선순위

```
  +----------------------------+     +---------------------------+
  | 1차 소스                   |     | 2차 소스                  |
  | Element-Reference.md       |     | 매뉴얼 PDF (6개 분할)     |
  | (393줄, 텍스트 정리 완료)  |     | (직접 읽기 제한적)        |
  +-------------+--------------+     +-------------+-------------+
                |                                  |
                v                                  v
  +----------------------------+     +---------------------------+
  | PRD-0004 Element Catalog   |     | ebs-console-feature-      |
  | (184개 요소, Step별 분류)  |     | triage.md (149개 결정)    |
  +-------------+--------------+     +-------------+-------------+
                |                                  |
                +----------------------------------+
                |
                v
  +------------------------------------------------+
  | 산출물: Step별 완전 요소 설계 문서              |
  | pokergfx-manual-step-element-design.design.md   |
  +------------------------------------------------+
```

### 3-Pass 분석 방법론

**Pass 1: Forward Mapping (매뉴얼 → PRD)**
- Element Reference의 모든 행을 순회하며 PRD-0004 Element Catalog에서 대응 요소 탐색
- 대응 없는 행 = "매뉴얼에 있으나 PRD 누락" → Gap 리스트에 추가
- AT 전용(`N/A (AT 전용)`) 요소는 분리하여 AT Gap 리스트로 관리

**Pass 2: Reverse Mapping (PRD → 매뉴얼)**
- PRD-0004 Element Catalog의 모든 요소를 순회하며 Element Reference에서 대응 매뉴얼 설명 탐색
- 대응 없는 요소 = "EBS 신규 추가 요소" → 신규 요소 리스트에 추가 + 추가 근거 확인

**Pass 3: Decision Assignment (Gap → 설계 결정)**
- Pass 1에서 발견된 Gap 요소에 설계 결정 부여
- 결정 기준: ebs-console-feature-triage.md의 트리아지 결과 우선 적용
- 트리아지 미포함 요소는 다음 기준으로 판단:
  - "방송 필수 / 대체 불가" → v1.0 Keep
  - "방송 가능하나 품질 향상" → v2.0 Defer
  - "RFID/DB 인프라 전제" → v3.0 Defer
  - "Commentary / 외부 SNS / 편집" → Drop

### Step별 매뉴얼 페이지 참조 전략

매뉴얼 PDF를 직접 읽을 수 없으므로, Element Reference 문서의 페이지 번호 컬럼을 활용하여 간접 참조한다. Element Reference에 없는 세부사항이 필요한 경우에만 PDF를 시도한다.

## 매뉴얼-Step 매핑 테이블 (Manual-Step Mapping)

Element Reference 문서의 섹션을 PRD-0004 Step에 매핑한다. 매핑 기준은 "설정 위치" (어느 탭에서 설정하는가).

| Element Reference 섹션 | 매뉴얼 페이지 | PRD-0004 Step | PRD 요소 ID 범위 | 요소 수 (Ref) | 요소 수 (PRD) |
|------------------------|:------------:|:-------------:|:----------------:|:------------:|:------------:|
| System Status Icons (Main Window) | p.33-34 | Step 1: Main Window | M-01 ~ M-20 | 10 | 20 |
| Settings (전역 설정) | p.33 | Step 1: Main Window | M-07 | 2 | 1 |
| System 탭 (Y-*) | p.58-60 | Step 2: System | Y-01 ~ Y-24 | 21 | 24 |
| Sources 탭 (S-*) | p.35-40 | Step 3: Sources | S-00 ~ S-18 | 22 | 19 |
| Outputs 탭 (O-*) | p.42-47 | Step 4: Outputs | O-01 ~ O-20 | 13 | 20 |
| Secure Delay 상세 | p.44-46 | Step 4: Outputs | O-06~O-07 (Future) | 7 | 2 |
| GFX 탭 공통 — 레이아웃 설정 | p.48-49 | Step 5: GFX 1 | G-01 ~ G-13 | 13 | 13+3(Skin) |
| GFX 탭 공통 — 애니메이션 | p.49 | Step 5: GFX 1 | G-17 ~ G-18 | 2 | 2 |
| GFX 탭 공통 — 텍스트 및 스폰서 | p.49-50 | Step 5: GFX 1 | G-10 ~ G-13 | 5 | 4 |
| GFX 탭 공통 — 블라인드 및 리더보드 표시 | p.50 | Step 5/6 | G-22~G-24, G-26~G-31 | 6 | 9 |
| GFX 탭 공통 — 카드 공개 및 폴드 처리 | p.50-52 | Step 5: GFX 1 | G-14 ~ G-16 | 8 | 3 |
| GFX 탭 공통 — Outs 및 액션 표시 | p.51-52 | Step 5/6 | G-19~G-25, G-35 | 7 | 7 |
| GFX 탭 공통 — 칩 카운트 및 통화 표시 | p.52-53 | Step 7: GFX 3 | G-47~G-51 | 12 | 5 |
| GFX 탭 공통 — 리더보드 및 Strip | p.53 | Step 6/7 | G-26~G-31, G-43~G-44 | 7 | 8 |
| GFX 탭 공통 — Action Clock | p.54 | Step 5: GFX 1 | G-21 | 1 | 1 |
| Skin System | p.64-79 | Step 9: Skin Editor | SK-01 ~ SK-26 | 16 | 26 |
| Action Tracker 인터페이스 | p.84-100 | Step 8: AT (범위 외) | N/A (AT 전용) | 40+ | 0 |
| MultiGFX | p.101-103 | Step 2: System | Y-16 ~ Y-19 | 4 | 4 |
| Twitch ChatBot | p.47 | Step 4: Outputs | O-16 | 1 | 1 |

### 주요 차이점 사전 식별

| 유형 | 설명 | 예상 개수 |
|------|------|:---------:|
| **매뉴얼에 있으나 PRD 누락** | Element Ref에서 `N/A`이면서 AT 전용이 아닌 요소 | 15~25개 |
| **PRD에 있으나 매뉴얼에 없음** | EBS 신규 추가 요소 (S-00, O-18~O-20, M-17/M-18 등) | 10~15개 |
| **설명 불일치** | 매뉴얼 원문과 PRD 설명이 다른 요소 | 5~10개 |

## 태스크 목록 (Tasks)

---

### Task 0: 산출물 스켈레톤 생성

- **설명**: `pokergfx-manual-step-element-design.design.md` 파일의 전체 구조(헤더, Step 0~9 섹션, 부록)를 스켈레톤으로 생성
- **수행 방법**: Write 도구로 섹션 헤더 + placeholder 생성
- **Acceptance Criteria**: 파일이 존재하고, Step 0~9 + 부록 섹션 헤더가 모두 포함됨

---

### Task 1: Pass 1 — Forward Mapping (매뉴얼 → PRD)

- **설명**: Element Reference 393줄 전체를 순회하며, 각 행의 `PRD ID` 컬럼이 PRD-0004 Element Catalog에 존재하는지 확인
- **수행 방법**:
  1. `PokerGFX-Manual-v3.2.0-Element-Reference.md` 전체 읽기
  2. `PRD ID` 컬럼이 `N/A`이면서 `(AT 전용)` 태그가 없는 행 추출 → Server UI Gap 리스트
  3. `PRD ID` 컬럼이 `N/A (AT 전용)`인 행 → AT Gap 리스트 (범위 외, 참고용 기록)
  4. `PRD ID`가 있지만 Element Reference 설명과 PRD-0004 설명이 다른 행 → 불일치 리스트
- **Acceptance Criteria**:
  - Server UI Gap 리스트 완성 (요소명, 매뉴얼 설명, 페이지, 해당 Step)
  - AT Gap 리스트 완성 (요소 수만 기록)
  - 불일치 리스트 완성 (양측 설명 병기)

---

### Task 2: Pass 2 — Reverse Mapping (PRD → 매뉴얼)

- **설명**: PRD-0004 Element Catalog 184개 요소를 순회하며, Element Reference에 대응 매뉴얼 설명이 있는지 확인
- **수행 방법**:
  1. PRD-0004 Step별 Element Catalog 읽기 (Step 1 L174~L237, Step 2 L304~L331, Step 3 L430~L453, Step 4 L547~L564, Step 5 L710~L754, Step 6 L858~L898, Step 7 L1006~L1034, Step 9 L1132~L1161, Graphic Editor L1222~L1251)
  2. 각 요소의 `PGX` 컬럼이 "신규"인 행 추출 → EBS 신규 요소 리스트
  3. 매뉴얼 인용이 없는(`매뉴얼:` 태그 없음) 기존 요소 추출 → 매뉴얼 보강 대상 리스트
- **Acceptance Criteria**:
  - EBS 신규 요소 리스트 (ID, 요소명, 추가 근거)
  - 매뉴얼 보강 대상 리스트 (ID, 요소명, 현재 설명, 필요 매뉴얼 원문)

---

### Task 3: Pass 3 — Gap 요소 설계 결정 부여

- **설명**: Task 1의 Server UI Gap 리스트 각 요소에 EBS 설계 결정 부여
- **수행 방법**:
  1. Gap 요소를 ebs-console-feature-triage.md의 149개 기능과 매칭 시도
  2. 트리아지 결과가 있으면 그 결정을 적용
  3. 트리아지에 없으면 다음 기준 적용:
     - 매뉴얼 p.33-60 (Server UI 탭): 해당 Step의 설계 원칙과 v1.0 Keep 기준 대조
     - 매뉴얼 p.64-79 (Skin): v2.0 Defer 기본 (스킨 편집은 방송 필수 아님)
     - 매뉴얼 p.101-113 (MultiGFX 등): P2 기본
  4. 각 결정에 1줄 근거 작성
- **Acceptance Criteria**:
  - 모든 Gap 요소에 결정(v1.0 Keep / v2.0 Defer / v3.0 Defer / Drop) + 근거 1줄이 부여됨
  - "미결정" 상태 요소 0개

---

### Task 4: Step 1 (Main Window) 완전 요소 설계 작성

- **설명**: Main Window의 모든 요소(PRD 20개 + Gap 요소)를 통합 테이블로 작성
- **수행 방법**:
  1. PRD-0004 L174~L237의 Element Catalog 20개 요소 추출
  2. Element Reference "System Status Icons" + "Settings" 섹션에서 Gap 요소 병합
  3. 매뉴얼 공식 설명 인용 (페이지 번호 포함)
  4. 누락/오류 요소 별도 표기
  5. PokerGFX 대비 EBS 변경점 요약
- **파일/라인**: 산출물 `## Step 1: Main Window` 섹션에 Edit append
- **Acceptance Criteria**:
  - 통합 테이블에 PRD 요소 20개 + Gap 요소 전부 포함
  - 모든 행에 매뉴얼 원문 설명 또는 "매뉴얼 미수록 (EBS 신규)" 명시
  - 변경점 요약 3줄 이상

---

### Task 5: Step 2 (System) 완전 요소 설계 작성

- **설명**: System 탭의 모든 요소(PRD 24개 + Gap 요소) 통합 테이블 작성
- **수행 방법**: Task 4와 동일 패턴
  - PRD-0004 L304~L331
  - Element Reference "System 탭 (Y-*)" 섹션
  - 매뉴얼 p.58-60 범위
- **Acceptance Criteria**: Task 4와 동일 기준

---

### Task 6: Step 3 (Sources) 완전 요소 설계 작성

- **설명**: Sources 탭의 모든 요소(PRD 19개 + Gap 요소) 통합 테이블 작성
- **수행 방법**: Task 4와 동일 패턴
  - PRD-0004 L430~L453
  - Element Reference "Sources 탭 (S-*)" 섹션
  - 매뉴얼 p.35-40 범위
  - 특히 주의: Follow Board/Follow Players/Post Bet/Post Hand 등 자동 카메라 제어 관련 매뉴얼 요소가 PRD에서 어떻게 매핑되었는지 확인
- **Acceptance Criteria**: Task 4와 동일 기준

---

### Task 7: Step 4 (Outputs) 완전 요소 설계 작성

- **설명**: Outputs 탭의 모든 요소(PRD 20개 + Gap 요소) 통합 테이블 작성
- **수행 방법**: Task 4와 동일 패턴
  - PRD-0004 L547~L564
  - Element Reference "Outputs 탭 (O-*)" + "Secure Delay 상세" 섹션
  - 매뉴얼 p.42-47 범위
  - 특히 주의: Secure Delay 관련 요소 7개가 Element Reference에 별도 섹션으로 존재. PRD에서는 O-06/O-07(Future)로 통합되어 있으므로 매핑 정확성 확인
- **Acceptance Criteria**: Task 4와 동일 기준

---

### Task 8: Step 5 (GFX 1) 완전 요소 설계 작성

- **설명**: GFX 1 탭의 모든 요소(PRD 25개+3 Skin = 28개 + Gap 요소) 통합 테이블 작성
- **수행 방법**: Task 4와 동일 패턴
  - PRD-0004 L710~L754
  - Element Reference "GFX 탭 공통" 중 레이아웃/애니메이션/텍스트/스폰서/카드공개/Outs/Action Clock 섹션
  - 매뉴얼 p.48-54 범위
  - GFX 1/2/3 경계 판단: PRD-0004의 그룹 분류를 따름 (Layout + Visual = GFX 1)
- **Acceptance Criteria**: Task 4와 동일 기준

---

### Task 9: Step 6 (GFX 2) 완전 요소 설계 작성

- **설명**: GFX 2 탭의 모든 요소(PRD 20개 + Gap 요소) 통합 테이블 작성
- **수행 방법**: Task 4와 동일 패턴
  - PRD-0004 L858~L898
  - Element Reference "GFX 탭 공통" 중 블라인드/리더보드 표시, 리더보드/Strip 섹션
  - 매뉴얼 p.50-53 범위
- **Acceptance Criteria**: Task 4와 동일 기준

---

### Task 10: Step 7 (GFX 3) 완전 요소 설계 작성

- **설명**: GFX 3 탭의 모든 요소(PRD 12개 + Gap 요소) 통합 테이블 작성
- **수행 방법**: Task 4와 동일 패턴
  - PRD-0004 L1006~L1034
  - Element Reference "GFX 탭 공통" 중 칩 카운트/통화, 리더보드/Strip 섹션
  - 매뉴얼 p.52-54 범위
- **Acceptance Criteria**: Task 4와 동일 기준

---

### Task 11: Step 8 (Action Tracker) 경계 문서화

- **설명**: Action Tracker는 별도 PRD 범위이므로, 본 산출물에서는 경계만 문서화
- **수행 방법**:
  1. Element Reference "Action Tracker 인터페이스" 섹션에서 요소 수 집계
  2. PRD-0004 Step 8 현재 내용(L1050~L1060) 확인
  3. AT 전용 요소 중 Server UI와 상호작용하는 요소(GfxServer ↔ AT 통신) 식별
- **Acceptance Criteria**:
  - AT 전용 요소 총 수 기록
  - Server-AT 상호작용 요소 목록 (5개 이내 예상)
  - 별도 PRD 참조 링크

---

### Task 12: Step 9 (Skin Editor / Graphic Editor) 완전 요소 설계 작성

- **설명**: Skin Editor 26개 + Graphic Editor 18개 + Gap 요소 통합 테이블 작성
- **수행 방법**: Task 4와 동일 패턴
  - PRD-0004 L1132~L1161 (Skin), L1222~L1251 (Graphic)
  - Element Reference "Skin System" 섹션
  - 매뉴얼 p.64-79 범위
- **Acceptance Criteria**: Task 4와 동일 기준

---

### Task 13: 부록 — 크로스 레퍼런스 테이블 작성

- **설명**: 전체 요소의 3-way 매핑 테이블 작성 (PRD ID ↔ 매뉴얼 ↔ Feature Triage ID)
- **수행 방법**:
  1. PRD-0004 부록 C (L1479~) GFX ID 크로스 레퍼런스 읽기
  2. Feature Triage 149개 ID와 PRD 184개 ID 매핑
  3. 매핑 불가 항목 = 커버리지 갭
- **Acceptance Criteria**:
  - 3-way 매핑 테이블 완성
  - 커버리지 갭 0개 또는 갭 사유 명시

---

### Task 14: 최종 검증 및 통계

- **설명**: 산출물 전체의 정합성 검증 + 요약 통계 생성
- **수행 방법**:
  1. Step별 요소 수 합산 → PRD-0004 부록 A 집계(184개)와 비교
  2. Gap 요소 수 + 신규 요소 수 집계
  3. 모든 요소에 설계 결정이 부여되었는지 확인
  4. "미결정" / "N/A" 상태 0개 확인
- **Acceptance Criteria**:
  - 요약 통계 테이블 포함: 총 요소 수, Gap 수, 신규 수, 결정별 분포
  - PRD-0004 184개와의 차이 설명

## 산출물 구조 (Output Structure)

산출물 파일: `C:\claude\ebs\docs\02-design\pokergfx-manual-step-element-design.design.md`

```
  # PokerGFX 매뉴얼 v3.2.0 기반 Step별 요소 설계

  ## 요약 통계
  | Step | PRD 요소 | Gap 요소 | 신규 요소 | 총 요소 |

  ## Step 0: 전체 네비게이션 (참조만)

  ## Step 1: Main Window
  ### 매뉴얼 해당 범위
  - 페이지: p.33-34
  - Element Reference 섹션: System Status Icons, Settings
  ### 완전 요소 목록
  | # | PRD ID | 요소명 | 매뉴얼 원문 설명 | 페이지 | EBS 설계 결정 | 비고 |
  ### 누락/오류 요소
  ### PokerGFX 대비 EBS 변경점

  ## Step 2: System
  (동일 구조)

  ## Step 3: Sources
  (동일 구조)

  ## Step 4: Outputs
  (동일 구조)

  ## Step 5: GFX 1
  (동일 구조)

  ## Step 6: GFX 2
  (동일 구조)

  ## Step 7: GFX 3
  (동일 구조)

  ## Step 8: Action Tracker (경계 문서)
  ### Server-AT 상호작용 요소
  ### AT 전용 요소 총 수
  ### 별도 PRD 참조

  ## Step 9: Skin Editor / Graphic Editor
  (동일 구조)

  ## 부록 A: 크로스 레퍼런스 테이블
  | PRD ID | 매뉴얼 요소 | Feature Triage ID | 설계 결정 |

  ## 부록 B: 전체 Gap 요소 목록
  | 요소명 | 매뉴얼 설명 | 페이지 | 해당 Step | 설계 결정 | 근거 |

  ## 변경 이력
```

### 각 Step 섹션의 테이블 컬럼 정의

| 컬럼 | 설명 |
|------|------|
| `#` | 행 번호 (Step 내 순서) |
| `PRD ID` | PRD-0004 요소 ID. Gap 요소는 `GAP-{Step}-{N}` 형식 |
| `요소명` | 요소 이름 (영문) |
| `매뉴얼 원문 설명` | Element Reference 또는 매뉴얼 PDF에서 인용한 공식 설명 |
| `페이지` | 매뉴얼 페이지 번호. 없으면 `-` |
| `EBS 설계 결정` | v1.0 Keep / v2.0 Defer / v3.0 Defer / Drop / EBS 신규 |
| `비고` | 불일치 사항, Drop 사유, 변경 근거 등 |

## 커밋 전략 (Commit Strategy)

| 커밋 | 메시지 | 포함 내용 |
|:----:|--------|----------|
| 1 | `docs(design): Step별 요소 설계 스켈레톤 생성` | Task 0 — 스켈레톤 파일 생성 |
| 2 | `docs(design): Gap Analysis 완료 (Pass 1-3)` | Task 1-3 — Forward/Reverse Mapping + 설계 결정 |
| 3 | `docs(design): Step 1-4 완전 요소 설계 작성` | Task 4-7 — Main Window, System, Sources, Outputs |
| 4 | `docs(design): Step 5-7 완전 요소 설계 작성` | Task 8-10 — GFX 1/2/3 |
| 5 | `docs(design): Step 8-9 + 부록 완성` | Task 11-13 — AT 경계, Skin/Graphic, 크로스 레퍼런스 |
| 6 | `docs(design): 최종 검증 + 통계 반영` | Task 14 — 정합성 검증, 요약 통계 |

---

## 실행 순서 의존성

```
  Task 0 (스켈레톤)
    |
    +---> Task 1 (Forward) --+
    |                        |
    +---> Task 2 (Reverse) --+--> Task 3 (Decision)
                                    |
                    +---------------+---------------+
                    |               |               |
                Task 4-7       Task 8-10       Task 11-12
              (Step 1-4)      (Step 5-7)     (Step 8-9)
                    |               |               |
                    +---------------+---------------+
                                    |
                                Task 13 (Cross-ref)
                                    |
                                Task 14 (Verify)
```

- Task 1, 2는 병렬 실행 가능
- Task 4~12는 Task 3 완료 후 병렬 실행 가능
- Task 13, 14는 순차 실행

---

## 변경 이력

| 날짜 | 버전 | 변경 내용 |
|------|------|---------|
| 2026-02-26 | v1.0.0 | 최초 작성 |
