# overlay-fallback 스킬 Work Plan

**버전**: 1.0.0 | **날짜**: 2026-02-24 | **상태**: Ready

---

## 배경 (Background)

### 요청 내용

`10-image-analysis.md` 룰 기반 OCR/오버레이 분석 파이프라인에 **실패 시 Fallback 경로**를 추가한다.
신규 스킬 `overlay-fallback`을 생성하고, 기존 룰 파일 2개에 참조를 삽입한다.

### 해결하려는 문제

현재 파이프라인은 분석 실패 시 사용자를 막다른 곳에 놓는다:

```
  OCR 실행
      |
      +--- 성공 ---> 결과 반환 (OK)
      |
      +--- 실패 ---> 오류 출력 ---> 종료   <-- 여기서 멈춤
                                              coord_picker.html 안내 없음
```

`coord_picker.html`(v2.0.0)은 이미 존재하는 브라우저 기반 수동 어노테이션 도구이나,
자동 분석 실패 시 이 도구로 연결하는 경로가 없어 사용자가 존재를 알 수 없다.

---

## 구현 범위 (Scope)

### 포함 항목

| 항목 | 설명 |
|------|------|
| SKILL.md 신규 생성 | `overlay-fallback` 스킬 정의 (YAML + 본문) |
| 10-image-analysis.md 수정 | Fallback 섹션 추가 (기존 Step 1-4 변경 없음) |
| 08-skill-routing.md 수정 | 스킬 매핑 테이블에 행 추가 |

### 제외 항목

| 항목 | 이유 |
|------|------|
| `coord_picker.html` 수정 | 도구 자체는 v2.0.0 완성 상태 (CON-1) |
| Python 스크립트 수정 | Fallback은 룰/스킬 레이어 전용 (CON-5) |
| 기존 워크플로우 Step 1-4 변경 | 기존 OCR 파이프라인 유지 (CON-2) |
| 기존 스킬 항목 변경 | 신규 행 추가만 허용 (CON-3) |

---

## 영향 파일 (Affected Files)

| 경로 | 작업 유형 | 변경 크기 | 비고 |
|------|----------|----------|------|
| `C:\claude\.claude\skills\overlay-fallback\SKILL.md` | **신규 생성** | ~80줄 | 디렉토리도 신규 생성 |
| `C:\claude\.claude\rules\10-image-analysis.md` | **수정** | +18줄 | "금지 사항" 앞에 섹션 삽입 |
| `C:\claude\.claude\rules\08-skill-routing.md` | **수정** | +1줄 | 스킬 매핑 테이블 최하단 행 추가 |

---

## 구현 순서 (Implementation Order)

```
  +----------------------------+
  | P1-1: SKILL.md 신규 생성   |
  | (overlay-fallback/)        |
  +------------+---------------+
               |
               v
  +----------------------------+
  | P1-2: 10-image-analysis.md |
  | Fallback 섹션 추가         |
  +------------+---------------+
               |
               v
  +----------------------------+
  | P2-1: 08-skill-routing.md  |
  | 매핑 테이블 행 추가        |
  +----------------------------+
```

**P1이 선행**되어야 P1-2의 스킬 호출 지시(`overlay-fallback 스킬 호출`)가 유효하다.
P2-1은 독립적이나 P1 완료 후 실행하여 일관성을 보장한다.

---

## 태스크 목록 (Tasks)

### Task 1 — SKILL.md 신규 생성 (P1-1)

**대상 파일**: `C:\claude\.claude\skills\overlay-fallback\SKILL.md`

**수행 방법**:

1. 디렉토리 `C:\claude\.claude\skills\overlay-fallback\` 생성
2. SKILL.md 파일 Write — 아래 구조로 작성

**YAML frontmatter**:
```yaml
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
```

**본문 구조**:

```
# /overlay-fallback

## 목적
(1문단 — 자동 Fallback 안내 역할 설명)

## 자동 트리거 조건

| ID | 조건 | 감지 방법 |
|----|------|---------|
| T-1 | OCR 신뢰도 < 30% 또는 추출 텍스트 0개 | OCR 출력 파싱 |
| T-2 | OpenCV 오버레이 감지 결과 0개 | 스크립트 반환값 |
| T-3 | 사용자 키워드 입력 | "수동 어노테이션", "coord picker", "좌표 직접", "요소 감지 실패" |
| T-4 | 분석 실패 메시지 감지 | "요소를 찾을 수 없음", "감지 실패", "0개 요소" |
| T-5 | Hybrid Pipeline Layer1 결과 0개 | --mode coords/ui/full 결과 파싱 |

## 실행 절차

### Step 1: Fallback 사유 출력
어떤 트리거 조건(T-1~T-5)으로 Fallback이 활성화됐는지 명시

### Step 2: coord_picker.html 경로 안내
절대 경로: C:\claude\ebs_reverse\scripts\coord_picker.html
브라우저 열기(Windows): start "" "C:\claude\ebs_reverse\scripts\coord_picker.html"

### Step 3: 단계별 사용법 안내 (5단계)
1. 브라우저에서 coord_picker.html 열기
2. [파일 열기] 버튼으로 오버레이 PNG 이미지 로드
3. [자동 분석] 클릭(자동) 또는 요소 수 입력 후 [N개 생성](수동)
4. Canvas에서 각 요소 드래그로 어노테이션
5. [JSON 내보내기] 클릭

### Step 4: JSON 저장 위치 안내
기본 저장 경로: docs/01-plan/data/overlay-anatomy-coords.json

### Step 5: 다음 단계 안내
JSON 생성 후 annotate_anatomy.py 실행으로 주석 이미지 재생성

## 범용 사용 시 주의
EBS 외 다른 프로젝트에서 사용 시 coord_picker.html 경로와 JSON 출력 경로를
프로젝트에 맞게 조정한다.

## 금지 사항
- 파일 자동 생성 금지 (안내 텍스트 출력만 담당)
- 명령어 자동 실행 금지 (사용자가 직접 수행)
- coord_picker.html 파일 자체 수정 금지
```

**Acceptance Criteria**:
- [ ] 파일 `C:\claude\.claude\skills\overlay-fallback\SKILL.md` 존재
- [ ] YAML frontmatter에 `auto_trigger: true` 포함
- [ ] T-1~T-5 트리거 조건 테이블 존재
- [ ] `C:\claude\ebs_reverse\scripts\coord_picker.html` 절대 경로 명시
- [ ] 실행 절차 5단계 명시

---

### Task 2 — 10-image-analysis.md Fallback 섹션 추가 (P1-2)

**대상 파일**: `C:\claude\.claude\rules\10-image-analysis.md`

**수행 방법**: `## 금지 사항` 섹션 바로 앞에 다음 섹션을 삽입 (Edit 도구 사용)

**삽입할 내용**:

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

**삽입 위치**: `10-image-analysis.md` 파일의 `## 금지 사항` 라인 바로 앞
**현재 58번 라인**: `## 금지 사항`
**기존 Step 1-4 및 옵션 처리 섹션은 변경하지 않는다.**

**Acceptance Criteria**:
- [ ] `## 오버레이 분석 실패 시 Fallback (자동 트리거)` 섹션이 파일에 존재
- [ ] T-1~T-5 조건 테이블이 섹션 내 포함
- [ ] `overlay-fallback 스킬 호출` 지시문 존재
- [ ] 기존 Step 1-4 내용 변경 없음
- [ ] `## 금지 사항` 섹션이 Fallback 섹션 다음에 위치

---

### Task 3 — 08-skill-routing.md 매핑 테이블 행 추가 (P2-1)

**대상 파일**: `C:\claude\.claude\rules\08-skill-routing.md`

**수행 방법**: 스킬 매핑 테이블 최하단 행(현재 15번 라인) 다음에 신규 행 추가

**현재 테이블 최하단**:
```
| `/commit`, `/issue`, `/pr`, `/verify`, `/mockup-hybrid` | 직접 실행 | 각 고유 서브커맨드 |
```

**추가할 행**:
```
| `/overlay-fallback` | 직접 실행 (자동 트리거: T-1~T-5 조건) | — |
```

**Acceptance Criteria**:
- [ ] `| \`/overlay-fallback\`` 행이 스킬 매핑 테이블에 존재
- [ ] "자동 트리거: T-1~T-5 조건" 명시
- [ ] 기존 테이블 행 변경 없음

---

## 위험 요소 (Risks)

### R-1: 기존 룰 파일 편집 충돌

`10-image-analysis.md`와 `08-skill-routing.md`는 전역 룰 파일이다.
다른 세션이나 에이전트가 동시에 수정하면 Edit 충돌이 발생할 수 있다.

**완화**: 편집 전 Read로 최신 내용 확인 → old_string이 정확히 일치하는지 검증 후 Edit 실행.

### R-2: SKILL.md 디렉토리 미생성

`C:\claude\.claude\skills\overlay-fallback\` 디렉토리가 존재하지 않으면
Write 도구가 실패한다.

**완화**: Write 이전 Bash로 디렉토리 생성(`mkdir -p`) 명시적 수행.

### R-3: T-1~T-5 조건 비동기화

SKILL.md와 10-image-analysis.md 양쪽에 트리거 조건이 중복 기재된다.
하나가 수정되면 다른 쪽도 갱신해야 하나 자동화 수단이 없다.

**완화**: Plan 문서에 "T-1~T-5 조건은 SKILL.md와 10-image-analysis.md 양쪽을 동시에 수정" 명시.

### R-4: EBS 경로 하드코딩 범용성 문제

`coord_picker.html` 절대 경로가 EBS 프로젝트 경로로 고정되면
다른 프로젝트에서 오해할 수 있다.

**완화**: SKILL.md에 "기본값(EBS 경로)이며, 다른 프로젝트는 해당 경로로 조정" 주의사항 명시.

### R-5: auto_trigger 메타데이터 미지원 가능성

현재 스킬 시스템이 `auto_trigger: true` YAML 필드를 파싱하지 않으면
자동 트리거는 룰 파일(`10-image-analysis.md`) 지시에만 의존한다.

**완화**: SKILL.md의 auto_trigger는 의도 문서화 역할. 실제 트리거 로직은
10-image-analysis.md 룰 텍스트 지시로 보장. 이중 기재로 안전망 확보.

---

## 검증 기준 (Verification Criteria)

| 항목 | 검증 방법 |
|------|---------|
| SKILL.md 존재 | `Glob C:\claude\.claude\skills\overlay-fallback\SKILL.md` |
| YAML frontmatter 유효 | Read로 파일 열어 `---` 블록 확인 |
| auto_trigger 필드 존재 | SKILL.md에 `auto_trigger: true` 포함 |
| T-1~T-5 조건 명시 | SKILL.md 트리거 조건 테이블 확인 |
| coord_picker.html 절대 경로 | SKILL.md에 `C:\claude\ebs_reverse\scripts\coord_picker.html` 포함 |
| 10-image-analysis.md Fallback 섹션 | Read로 파일 열어 `## 오버레이 분석 실패 시 Fallback` 헤딩 확인 |
| 기존 Step 1-4 변경 없음 | Read로 Step 1~4 내용 원본과 비교 |
| 08-skill-routing.md 행 추가 | Read로 파일 열어 `overlay-fallback` 행 확인 |

---

## 커밋 전략 (Commit Strategy)

```
feat(skills): overlay-fallback 스킬 및 룰 확장 추가

- C:\claude\.claude\skills\overlay-fallback\SKILL.md 신규 생성
  - auto_trigger: true, T-1~T-5 조건 정의
  - coord_picker.html 5단계 사용법 안내
- C:\claude\.claude\rules\10-image-analysis.md 수정
  - 오버레이 분석 실패 시 Fallback 섹션 추가 (기존 워크플로우 변경 없음)
- C:\claude\.claude\rules\08-skill-routing.md 수정
  - /overlay-fallback 스킬 매핑 테이블 행 추가
```

**브랜치**: `feat/overlay-fallback-skill`
**Conventional Commit 타입**: `feat` (신규 스킬 + 룰 확장)
