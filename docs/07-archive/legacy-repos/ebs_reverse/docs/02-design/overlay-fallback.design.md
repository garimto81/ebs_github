# overlay-fallback 스킬 설계 문서

**버전**: 1.0.0 | **날짜**: 2026-02-24 | **상태**: Draft

---

## 1. 개요

### 1.1 목적

`10-image-analysis.md` 룰 기반 OCR/오버레이 분석 파이프라인에 **실패 시 Fallback 경로**를 추가한다.
신규 스킬 `overlay-fallback`을 생성하고, 기존 룰 파일 2개에 참조를 삽입함으로써
분석 실패 시 사용자가 `coord_picker.html` 수동 어노테이션 도구로 자동 연결되도록 한다.

### 1.2 범위

| 항목 | 설명 |
|------|------|
| SKILL.md 신규 생성 | `C:\claude\.claude\skills\overlay-fallback\SKILL.md` |
| 10-image-analysis.md 수정 | Fallback 섹션 추가 (기존 Step 1-4 변경 없음) |
| 08-skill-routing.md 수정 | 스킬 매핑 테이블에 행 추가 |

### 1.3 구현 방식 요약

1. Claude 룰/스킬 레이어에서만 처리 (Python 스크립트 수정 없음)
2. 텍스트 안내 출력만 담당 (파일 자동 생성, 명령어 자동 실행 금지)
3. `auto_trigger: true` YAML 메타데이터 + 룰 파일 지시 이중 안전망
4. 기존 OCR 파이프라인 Step 1-4 전혀 변경하지 않음

---

## 2. 파일 구조 설계

### 2.1 SKILL.md 전체 내용 설계

**파일 경로**: `C:\claude\.claude\skills\overlay-fallback\SKILL.md`

아래 내용이 실제 파일에 그대로 작성되어야 한다 (executor가 이 블록을 복사하여 Write 실행).

```markdown
---
name: overlay-fallback
description: "이미지 분석 또는 오버레이 요소 감지가 실패했을 때 coord_picker.html
  수동 어노테이션 도구로 안내하는 스킬. OCR 신뢰도 < 30%, OpenCV 0개 감지,
  사용자 수동 어노테이션 요청 시 자동 트리거."
version: 1.0.0
triggers:
  keywords:
    - "수동 어노테이션"
    - "coord picker"
    - "좌표 직접"
    - "요소 감지 실패"
    - "overlay fallback"
    - "오버레이 좌표 직접"
auto_trigger: true
model_preference: sonnet
---

# /overlay-fallback

## 목적

이미지 분석 또는 오버레이 요소 감지가 실패했을 때 자동으로 Fallback 경로를 제공한다.
OCR 신뢰도가 낮거나 OpenCV 자동 감지가 0개를 반환하는 경우, 사용자를
`coord_picker.html` 브라우저 기반 수동 어노테이션 도구로 안내한다.
외부 Python 패키지(opencv, labelme) 없이 `file://` 프로토콜로 즉시 실행 가능하며,
JSON 내보내기로 `overlay-anatomy-coords.json`을 생성한다.

## 자동 트리거 조건

| ID | 조건 | 감지 방법 |
|----|------|---------|
| T-1 | OCR 신뢰도 < 30% 또는 추출 텍스트 0개 | OCR 출력 파싱 |
| T-2 | OpenCV 오버레이 감지 결과 0개 | 스크립트 반환값 |
| T-3 | 사용자 키워드 입력 | "수동 어노테이션", "coord picker", "좌표 직접", "요소 감지 실패" |
| T-4 | 분석 실패 메시지 감지 | "요소를 찾을 수 없음", "감지 실패", "0개 요소" 패턴 |
| T-5 | Hybrid Pipeline Layer1 결과 0개 | --mode coords/ui/full 결과 파싱 |

## 실행 절차

### Step 1: Fallback 사유 출력

어떤 트리거 조건(T-1~T-5)으로 Fallback이 활성화됐는지 명시한다. 예시:

```
[overlay-fallback] T-2 트리거: OpenCV 자동 감지 결과 0개
수동 어노테이션 도구(coord_picker.html)로 안내합니다.
```

### Step 2: coord_picker.html 경로 안내

절대 경로: `C:\claude\ebs_reverse\scripts\coord_picker.html`

브라우저 열기 명령 (OS별):
- Windows: `start "" "C:\claude\ebs_reverse\scripts\coord_picker.html"`
- macOS: `open "/path/to/coord_picker.html"`
- Linux: `xdg-open "/path/to/coord_picker.html"`

> 범용 사용 시: 프로젝트에 맞는 절대 경로로 교체한다.

### Step 3: 단계별 사용법 안내 (5단계)

1. 브라우저에서 `coord_picker.html` 열기 (더블클릭 또는 위 명령어 실행)
2. [파일 열기] 버튼으로 오버레이 PNG 이미지 로드
3. [자동 분석] 클릭(자동) 또는 요소 수 입력 후 [N개 생성](수동)
4. Canvas에서 각 요소 드래그로 어노테이션
5. [JSON 내보내기] 클릭

### Step 4: JSON 저장 위치 안내

기본 저장 경로: `docs/01-plan/data/overlay-anatomy-coords.json`

> 범용 사용 시: 프로젝트의 좌표 JSON 저장 경로로 조정한다.

### Step 5: 다음 단계 안내

JSON 생성 후 아래 명령어로 주석 이미지를 재생성한다:

```bash
python scripts/annotate_anatomy.py
# 출력: docs/01-plan/images/prd/overlay-anatomy.png
```

## 범용 사용 시 주의

EBS 외 다른 프로젝트에서 사용 시 아래 항목을 프로젝트에 맞게 조정한다:

| 항목 | 기본값 (EBS) | 조정 방법 |
|------|------------|---------|
| coord_picker.html 경로 | `C:\claude\ebs_reverse\scripts\coord_picker.html` | 프로젝트 경로로 교체 |
| JSON 출력 경로 | `docs/01-plan/data/overlay-anatomy-coords.json` | 프로젝트 경로로 교체 |
| annotate_anatomy.py 경로 | `scripts/annotate_anatomy.py` | 프로젝트 경로로 교체 |

## 금지 사항

- 파일 자동 생성 금지 (안내 텍스트 출력만 담당)
- 명령어 자동 실행 금지 (사용자가 직접 수행)
- `coord_picker.html` 파일 자체 수정 금지
```

### 2.2 10-image-analysis.md 수정 설계

**파일 경로**: `C:\claude\.claude\rules\10-image-analysis.md`

**삽입 위치**: `## 금지 사항` 헤딩 바로 앞

**삽입 방법**: Edit 도구 사용. `old_string`을 `## 금지 사항` 앞 빈 줄로 잡아 정확히 삽입.

**삽입할 내용** (아래 블록을 `## 금지 사항` 앞에 추가):

```markdown
## 오버레이 분석 실패 시 Fallback (자동 트리거)

분석 결과가 다음 조건 중 하나라도 충족되면 **반드시** `overlay-fallback` 스킬을 실행한다:

| 조건 | 감지 방법 |
|------|---------|
| T-1: OCR 신뢰도 < 30% 또는 추출 텍스트 0개 | OCR 출력 파싱 |
| T-2: OpenCV 오버레이 자동 감지 결과 0개 | 스크립트 반환값 확인 |
| T-3: 사용자 키워드 입력 | "수동 어노테이션", "coord picker", "좌표 직접", "요소 감지 실패" |
| T-4: 분석 실패 출력 감지 | "요소를 찾을 수 없음", "감지 실패", "0개 요소" 패턴 |
| T-5: Hybrid Pipeline Layer1 결과 0개 | --mode coords/ui/full 파이프라인 결과 |

**Fallback 실행**: overlay-fallback 스킬 호출 → coord_picker.html 수동 어노테이션 안내

```

**편집 시 주의사항**:
- 기존 Step 1-4 내용 절대 변경 금지
- `## 금지 사항` 섹션은 Fallback 섹션 다음에 위치해야 함
- 빈 줄 1개로 섹션 구분

### 2.3 08-skill-routing.md 수정 설계

**파일 경로**: `C:\claude\.claude\rules\08-skill-routing.md`

**수정 위치**: 스킬 매핑 테이블 최하단 행 다음

**현재 테이블 최하단 행**:
```
| `/commit`, `/issue`, `/pr`, `/verify`, `/mockup-hybrid` | 직접 실행 | 각 고유 서브커맨드 |
```

**추가할 행**:
```
| `/overlay-fallback` | 직접 실행 (자동 트리거: T-1~T-5 조건) | — |
```

**편집 방법**: Edit 도구로 기존 최하단 행을 `old_string`으로 잡고, `new_string`에 기존 행 + 신규 행을 함께 포함.

**편집 시 주의사항**:
- 기존 테이블의 다른 행은 절대 변경 금지
- 신규 행만 최하단에 추가

---

## 3. 트리거 조건 상세 (T-1~T-5)

각 트리거 조건의 감지 방법과 Claude 판단 기준을 명시한다.

### T-1: OCR 신뢰도 < 30% 또는 추출 텍스트 0개

| 항목 | 내용 |
|------|------|
| 감지 방법 | Tesseract OCR 출력 파싱 (신뢰도 점수, 추출 텍스트 수) |
| Claude 판단 기준 | OCR 출력에서 confidence 값 30 미만 OR 추출 텍스트 문자열이 공백/빈값 |
| 우선순위 | P1 (가장 빈번한 실패 시나리오) |
| 예시 감지 | `confidence: 12.3`, 추출 결과 `""` 또는 `[]` |

### T-2: OpenCV 오버레이 자동 감지 결과 0개

| 항목 | 내용 |
|------|------|
| 감지 방법 | `extract_overlay_bbox.py` 스크립트 반환값 파싱 |
| Claude 판단 기준 | 반환 JSON에 요소 배열이 비어있거나(`[]`), "0개 요소 감지" 메시지 출력 |
| 우선순위 | P1 (OCR과 동등한 빈도) |
| 예시 감지 | `{"elements": []}`, `감지된 요소: 0개` |

### T-3: 사용자 키워드 입력

| 항목 | 내용 |
|------|------|
| 감지 방법 | 사용자 입력 텍스트 키워드 매칭 |
| Claude 판단 기준 | 아래 키워드 중 하나라도 포함 시 트리거 |
| 키워드 목록 | "수동 어노테이션", "coord picker", "좌표 직접", "요소 감지 실패", "overlay fallback", "오버레이 좌표 직접" |
| 우선순위 | P2 (사용자 명시적 요청) |

### T-4: 분석 실패 메시지 감지

| 항목 | 내용 |
|------|------|
| 감지 방법 | 스크립트/OCR 출력 텍스트 패턴 매칭 |
| Claude 판단 기준 | 출력에서 실패 패턴 문자열 발견 시 트리거 |
| 패턴 목록 | "요소를 찾을 수 없음", "감지 실패", "0개 요소" |
| 우선순위 | P2 (추가 감지 경로) |

### T-5: Hybrid Pipeline Layer1 결과 0개

| 항목 | 내용 |
|------|------|
| 감지 방법 | `--mode coords` / `--mode ui` / `--mode full` 실행 결과 파싱 |
| Claude 판단 기준 | Hybrid Pipeline Layer1(그래픽 레이어) BBox 검출 결과가 0개 |
| 우선순위 | P2 (Hybrid 모드 전용) |
| 예시 감지 | Layer1 결과: `{"bboxes": [], "count": 0}` |

---

## 4. 실행 흐름도 (ASCII)

### 4.1 전체 파이프라인 (기존 + Fallback)

```
  이미지 분석 요청
        |
        v
  [10-image-analysis.md 워크플로우]
        |
        +--- Step 1: 이미지 경로 확인
        |
        +--- Step 2: Tesseract OCR 실행
        |
        +--- Step 3: Claude Vision 맥락 분석
        |
        +--- Step 4: 결과 통합 제시
        |
        v
  [결과 평가]
        |
        +--- OCR 신뢰도 OK + 요소 감지 OK ---> 결과 반환 (완료)
        |
        +--- 실패 조건 T-1 ~ T-5 감지 -------+
                                              |
                                              v
                              [overlay-fallback 스킬 자동 트리거]
                                              |
                              +---------------+---------------+
                              |               |               |
                              v               v               v
                         Step 1          Step 2          Step 3
                       Fallback       coord_picker    단계별 사용법
                       사유 출력       경로 안내       5단계 안내
                              |
                              v
                         Step 4: JSON 저장 위치 안내
                              |
                              v
                         Step 5: 다음 단계 안내
                         (annotate_anatomy.py)
```

### 4.2 트리거 감지 상세

```
  분석 실행 결과
        |
        +--- T-1: OCR 신뢰도 < 30%? ---YES---> Fallback
        |          OR 텍스트 0개?
        |
        +--- T-2: OpenCV 감지 0개? ----YES---> Fallback
        |
        +--- T-3: 사용자 키워드 ---YES---------+
        |         포함 여부?                   |
        |                                     v
        +--- T-4: 실패 메시지 ---YES---> overlay-fallback
        |         패턴 감지?                  스킬 실행
        |
        +--- T-5: Hybrid Layer1 ---YES---> Fallback
                  결과 0개?
                  |
                  NO (모두)
                  |
                  v
            정상 결과 반환
```

### 4.3 파일 관계도

```
  10-image-analysis.md (룰)
        |
        |-- 기존 Step 1-4 (변경 없음)
        |
        +-- [신규] Fallback 섹션 (T-1~T-5 조건 명시)
                    |
                    v (overlay-fallback 스킬 호출)
        C:\claude\.claude\skills\overlay-fallback\SKILL.md
                    |
                    v (사용자 안내)
        C:\claude\ebs_reverse\scripts\coord_picker.html
                    |
                    v (JSON 내보내기)
        docs\01-plan\data\overlay-anatomy-coords.json

  08-skill-routing.md (룰)
        |
        +-- 기존 스킬 테이블 (변경 없음)
        +-- [신규 행] /overlay-fallback | 직접 실행 (자동 트리거: T-1~T-5 조건) | —
```

---

## 5. 제약사항

| ID | 제약사항 | 설계 결정 |
|----|---------|---------|
| CON-1 | `coord_picker.html` 파일 자체 수정 없음 | 스킬은 경로 안내만 담당. 파일 내용 변경 없음 |
| CON-2 | 기존 `10-image-analysis.md` Step 1~4 변경 없음 | Fallback 섹션을 `## 금지 사항` 앞에 삽입만 함 |
| CON-3 | `08-skill-routing.md` 기존 행 변경 없음 | 테이블 최하단에 신규 행 1개만 추가 |
| CON-4 | 파일 자동 생성 / 명령어 자동 실행 금지 | 스킬 출력은 텍스트 안내만. 실행은 사용자가 직접 |
| CON-5 | Python 코드 수정 없음 | `extract_overlay_bbox.py`, `annotate_anatomy.py` 등 무변경 |
| CON-6 | 글로벌 스킬 경로 준수 | `C:\claude\.claude\skills\overlay-fallback\` (서브프로젝트 로컬 생성 금지) |
| CON-7 | `auto_trigger: true`는 의도 문서화 역할 | 실제 트리거 로직은 10-image-analysis.md 룰 텍스트 지시로 보장 |

### 위험 요소 및 완화

| 위험 | 완화 방법 |
|------|---------|
| R-1: 룰 파일 편집 충돌 | Edit 전 Read로 최신 내용 확인 → old_string 정확 일치 검증 |
| R-2: 디렉토리 미생성 | Write 전 `mkdir -p` 명시적 실행 |
| R-3: T-1~T-5 조건 비동기화 | SKILL.md와 10-image-analysis.md 동시 수정 원칙 준수 |
| R-4: EBS 경로 하드코딩 | SKILL.md "범용 사용 시 주의" 섹션에 조정 방법 명시 |
| R-5: auto_trigger 미지원 | 룰 파일 텍스트 지시로 이중 보장 (YAML 미지원 시에도 동작) |

---

## 6. 검증 기준

Plan.md Acceptance Criteria를 설계 수준으로 구체화한다.

### 6.1 SKILL.md 검증

| 항목 | 검증 방법 | 기대 결과 |
|------|---------|---------|
| 파일 존재 | `Glob C:\claude\.claude\skills\overlay-fallback\SKILL.md` | 파일 반환 |
| YAML frontmatter | Read → `---` 블록 파싱 | `name`, `version`, `auto_trigger: true` 존재 |
| T-1~T-5 트리거 조건 | Read → `## 자동 트리거 조건` 섹션 확인 | 5행 테이블 존재 |
| coord_picker.html 절대 경로 | Read → `C:\claude\ebs_reverse\scripts\coord_picker.html` 검색 | 문자열 포함 |
| 실행 절차 5단계 | Read → `### Step 1` ~ `### Step 5` 헤딩 확인 | 5개 Step 헤딩 존재 |
| 금지 사항 섹션 | Read → `## 금지 사항` 확인 | 3개 항목 존재 |

### 6.2 10-image-analysis.md 검증

| 항목 | 검증 방법 | 기대 결과 |
|------|---------|---------|
| Fallback 섹션 존재 | Read → `## 오버레이 분석 실패 시 Fallback` 헤딩 검색 | 헤딩 포함 |
| T-1~T-5 조건 테이블 | Read → Fallback 섹션 내 테이블 확인 | 5행 테이블 존재 |
| 스킬 호출 지시 | Read → `overlay-fallback 스킬 호출` 텍스트 검색 | 문자열 포함 |
| 기존 Step 1-4 보존 | Read → `### Step 1: 이미지 경로 확인` 등 원본 비교 | 내용 변경 없음 |
| 섹션 순서 | Read → Fallback 섹션 다음에 `## 금지 사항` 위치 확인 | 순서 정확 |

### 6.3 08-skill-routing.md 검증

| 항목 | 검증 방법 | 기대 결과 |
|------|---------|---------|
| overlay-fallback 행 존재 | Read → `/overlay-fallback` 검색 | 행 포함 |
| 자동 트리거 표시 | Read → `자동 트리거: T-1~T-5 조건` 검색 | 문자열 포함 |
| 기존 행 변경 없음 | Read → 기존 최하단 행 확인 | `/commit`, `/issue` 등 원본 유지 |

### 6.4 통합 검증

| 항목 | 검증 방법 |
|------|---------|
| T-1~T-5 조건 동기화 | SKILL.md와 10-image-analysis.md 양쪽 조건 테이블 비교 → 동일한 5개 조건 |
| 범용성 문구 | SKILL.md "범용 사용 시 주의" 섹션에 경로 조정 안내 존재 |
| 커밋 전략 일치 | `feat(skills): overlay-fallback 스킬 및 룰 확장 추가` 메시지 형식 준수 |
