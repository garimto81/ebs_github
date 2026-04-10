# overlay-fallback 스킬 PRD

**버전**: 2.0.0 | **날짜**: 2026-02-24 | **상태**: Draft

---

## 1. 배경 및 목적

### 현황

`10-image-analysis.md` 룰은 Tesseract OCR + Claude Vision 2단계 분석 파이프라인을 정의한다. 그러나 현재 룰에는 **분석 실패 시 Fallback 경로가 없다**:

- OCR 신뢰도가 낮거나 0개 결과가 반환될 때 → 그대로 "분석 완료" 주장하거나 오류 출력 후 종료
- OpenCV 기반 오버레이 자동 감지(`extract_overlay_bbox.py`)가 0개 결과를 반환할 때 → 수동 대안 안내 없음
- 사용자가 "요소 감지 실패", "좌표 직접 지정" 등 키워드를 입력할 때 → 대응 스킬 없음

### 문제

```
현재 파이프라인:
  OCR 실행 → (실패) → 오류 출력 → 종료
                                     ^
                                     여기서 coord_picker.html 안내가 있어야 함
```

`coord_picker.html`(v2.0.0)은 Canvas getImageData + BFS 클러스터링 기반의 브라우저 전용 오버레이 요소 어노테이션 도구다. 외부 Python 패키지(opencv, labelme) 없이 `file://` 프로토콜로 즉시 실행 가능하며, JSON 내보내기로 `overlay-anatomy-coords.json`을 생성한다.

이 도구는 이미 존재하지만 **분석 결과의 적합성은 사용자가 판단해야 하며, 사용자의 명시적 판단 없이 시스템이 자동으로 Fallback을 트리거하는 것은 부적절하다.**

### v2.0.0 변경 사유

> **이미지 분석 실패의 정의는 시스템이 아닌 사용자가 판단한다.**

v1.0.0에서는 T-1~T-5 조건을 시스템이 감지하면 overlay-fallback이 자동 실행되는 모델이었다. 그러나 OCR 신뢰도나 감지 결과가 낮더라도 사용자가 "결과가 충분하다"고 판단할 수 있고, 반대로 수치상 정상이어도 사용자가 "잘못 분석됐다"고 볼 수 있다.

v2.0.0은 이미지 분석 완료 후 **사용자에게 결과 확인을 요청**하고, 사용자가 재처리가 필요하다고 판단할 때만 overlay-fallback 옵션을 제공한다.

### 목적

이미지 분석 완료 후 사용자 확인 플로우를 통해, 사용자가 재어노테이션이 필요하다고 판단할 때 `coord_picker.html`을 **Fallback 경로로 안내**하는 스킬과 룰 확장을 구현한다. 사용자는 별도 설치 없이 브라우저만으로 수동 어노테이션을 수행하고 좌표 JSON을 얻을 수 있다.

### 대상 독자

- EBS 오버레이 개발자 (주 사용자)
- 향후 범용 오버레이 프로젝트 사용자

---

## 2. 요구사항 목록

### 2.1 사용자 확인 플로우 (FR-1)

**FR-1**: 이미지 분석 완료 후 사용자에게 결과 확인을 요청하고, 사용자 판단에 따라 overlay-fallback을 제공한다.

| 번호 | 요구사항 | 설명 |
|------|---------|------|
| FR-1-1 | 분석 완료 후 사용자 확인 요청 | 이미지 분석 결과 제시 후 "오버레이 처리를 계속할까요? 분석 결과를 확인해 주세요." 메시지 출력 |
| FR-1-2 | 사용자 재처리 의사 감지 | "아니오", "잘못됨", "재어노테이션", "다시 분석", "잘못 분석됨", "재분석 필요" 등 부정 판단 키워드 감지 |
| FR-1-3 | overlay-fallback 옵션 제시 | 사용자가 재처리 의사를 표시하면 overlay-fallback 옵션(텍스트 버튼 형태)을 제공 |
| FR-1-4 | 선택적 참고 조건 (T-1~T-5) | 아래 T-1~T-5 조건은 자동 트리거가 아닌 "사용자 확인 요청 시 함께 표시하는 참고 정보"로만 활용 |

**선택적 참고 조건 (T-1~T-5)** — 자동 트리거 아님, 사용자 안내용 참고:

| ID | 조건 | 표시 방법 |
|----|------|----------|
| T-1 | Tesseract OCR 신뢰도 < 30% 또는 추출 텍스트 0개 | 사용자 확인 요청 시 "OCR 신뢰도가 낮습니다" 참고 표시 |
| T-2 | OpenCV 오버레이 자동 감지 결과 0개 (`extract_overlay_bbox.py`) | 사용자 확인 요청 시 "감지된 요소가 없습니다" 참고 표시 |
| T-3 | 사용자 키워드: "수동 어노테이션", "coord picker", "좌표 직접", "요소 감지 실패" | 사용자가 명시적으로 요청 → 즉시 overlay-fallback 옵션 제시 |
| T-4 | 오버레이 분석 실패 메시지 감지: "요소를 찾을 수 없음", "감지 실패", "0개 요소" | 사용자 확인 요청 시 "분석 실패가 감지됐습니다" 참고 표시 |
| T-5 | `--mode coords` / `--mode ui` / `--mode full` 파이프라인에서 Layer1 결과 0개 | 사용자 확인 요청 시 "레이어 감지 결과가 없습니다" 참고 표시 |

### 2.2 스킬 실행 내용 (FR-2)

**FR-2**: overlay-fallback 스킬이 활성화되면 다음을 순서대로 실행한다.

| 번호 | 요구사항 | 설명 |
|------|---------|------|
| FR-2-1 | Fallback 사유 출력 | 사용자 판단 또는 어떤 참고 조건(T-1~T-5)이 해당됐는지 표시 |
| FR-2-2 | coord_picker.html 경로 안내 | 절대 경로와 브라우저 열기 방법 안내 |
| FR-2-3 | 단계별 사용법 안내 | 파일 열기 → 이미지 로드 → 자동/수동 분석 → 드래그 → JSON 내보내기 5단계 |
| FR-2-4 | JSON 내보내기 위치 안내 | 출력 파일 저장 경로 (`docs/01-plan/data/overlay-anatomy-coords.json`) 명시 |
| FR-2-5 | 프리셋 파일 안내 (옵션) | WSOP 프로젝트인 경우 `wsop-preset.coord-picker-config.json` 안내 |
| FR-2-6 | 다음 단계 안내 | JSON 생성 후 `annotate_anatomy.py` 실행으로 주석 이미지 재생성 방법 안내 |

### 2.3 룰 확장 요구사항 (FR-3)

**FR-3**: `10-image-analysis.md`에 "사용자 확인 기반 Fallback" 섹션을 추가한다.

| 번호 | 요구사항 | 설명 |
|------|---------|------|
| FR-3-1 | 사용자 확인 플로우 섹션 추가 | 기존 "금지 사항" 섹션 앞에 사용자 확인 요청 → Fallback 절차 삽입 |
| FR-3-2 | 참고 조건 테이블 | T-1~T-5 조건을 "선택적 참고 조건"으로 룰 문서에 기재 |
| FR-3-3 | 스킬 호출 지시 | 사용자가 재처리 의사 표시 시 `/overlay-fallback` 스킬 호출 명시 |

### 2.4 스킬 파일 생성 요구사항 (FR-4)

**FR-4**: `C:\claude\.claude\skills\overlay-fallback\SKILL.md` 파일을 신규 생성한다.

| 번호 | 요구사항 | 설명 |
|------|---------|------|
| FR-4-1 | SKILL.md 메타데이터 | name, description, version, triggers, auto_trigger 필드 포함 (`auto_trigger: false`) |
| FR-4-2 | 트리거 키워드 정의 | 사용자 재처리 의사 키워드 목록 명시 (T-3 조건 + 부정 판단 키워드) |
| FR-4-3 | 실행 절차 정의 | FR-2 내용을 SKILL.md 실행 지시로 명세화 |
| FR-4-4 | coord_picker.html 경로 | `C:\claude\ebs_reverse\scripts\coord_picker.html` 절대 경로 명시 |
| FR-4-5 | 범용성 보장 | EBS 프로젝트 외 다른 오버레이 프로젝트에서도 사용 가능하도록 설계 |

### 2.5 스킬 라우팅 테이블 업데이트 (FR-5)

**FR-5**: `08-skill-routing.md` 스킬 매핑 테이블에 `overlay-fallback` 항목을 추가한다.

| 번호 | 요구사항 | 설명 |
|------|---------|------|
| FR-5-1 | 스킬 매핑 테이블 추가 | `/overlay-fallback` 항목을 "직접 실행" 방식으로 추가 |
| FR-5-2 | 사용자 트리거 표시 | `auto_trigger: false`, 사용자 판단 기반 트리거 명시 |

---

## 3. 기능 범위

### 3.1 생성 대상 파일

| 파일 경로 | 작업 유형 | 설명 |
|----------|----------|------|
| `C:\claude\.claude\skills\overlay-fallback\SKILL.md` | **신규 생성** | overlay-fallback 스킬 정의 파일 |

### 3.2 수정 대상 파일

| 파일 경로 | 작업 유형 | 변경 내용 |
|----------|----------|----------|
| `C:\claude\.claude\rules\10-image-analysis.md` | **수정** | "사용자 확인 기반 Fallback" 섹션 추가 (FR-3) |
| `C:\claude\.claude\rules\08-skill-routing.md` | **수정** | 스킬 매핑 테이블에 `/overlay-fallback` 행 추가 (FR-5) |

### 3.3 변경 없는 파일

| 파일 경로 | 이유 |
|----------|------|
| `C:\claude\ebs_reverse\scripts\coord_picker.html` | 도구 자체는 수정 없음 (제약사항 참조) |
| `C:\claude\ebs_reverse\scripts\extract_overlay_bbox.py` | 감지 스크립트 수정 없음 |
| `C:\claude\ebs_reverse\scripts\annotate_anatomy.py` | 주석 스크립트 수정 없음 |
| 기타 기존 스킬 파일 | 영향 없음 |

### 3.4 데이터 흐름

```
이미지 분석 요청
      |
      v
[10-image-analysis.md 워크플로우]
      |
      v
분석 결과 제시
      |
      v
[사용자 확인 요청]
"오버레이 처리를 계속할까요? 분석 결과를 확인해 주세요."
(참고: T-1~T-5 해당 조건 있으면 함께 표시)
      |
      +--- 사용자: "확인/계속" --------> 기존 결과 반환 (변경 없음)
      |
      +--- 사용자: "잘못됨/재어노테이션" -> [overlay-fallback 옵션 제시]
                                              |
                                              v
                                    Fallback 사유 출력
                                              |
                                              v
                                    coord_picker.html 경로 안내
                                              |
                                              v
                                    단계별 사용법 5단계 안내
                                              |
                                              v
                                    JSON 내보내기 위치 안내
                                              |
                                              v
                                    다음 단계 (annotate_anatomy.py) 안내
```

---

## 4. 비기능 요구사항

### 4.1 범용성

| 항목 | 요구사항 |
|------|---------|
| NFR-1 | 스킬은 EBS 프로젝트에 종속되지 않는다. 어떤 오버레이 프로젝트에서도 사용 가능해야 한다. |
| NFR-2 | coord_picker.html 경로는 파라미터로 전달받거나 기본값(`C:\claude\ebs_reverse\scripts\coord_picker.html`)을 사용한다. |
| NFR-3 | 스킬 안내 출력은 프로젝트별 JSON 출력 경로를 컨텍스트에 따라 조정한다. |

### 4.2 브라우저 실행 방식

| 항목 | 요구사항 |
|------|---------|
| NFR-4 | coord_picker.html은 `file://` 프로토콜로 직접 열기 가능해야 한다 (서버 불필요). |
| NFR-5 | 스킬 안내 출력에 브라우저 열기 명령어를 포함한다 (Windows: `start`, macOS: `open`, Linux: `xdg-open`). |
| NFR-6 | 외부 Python 패키지(opencv, labelme) 없이도 동작 가능한 경로를 안내한다. |

### 4.3 응답 속도

| 항목 | 요구사항 |
|------|---------|
| NFR-7 | 사용자 재처리 의사 감지 후 스킬 안내 출력까지 추가 지연이 없어야 한다 (즉시 응답). |
| NFR-8 | 스킬은 외부 API 호출이나 파일 생성 없이 텍스트 안내만으로 완결된다. |

### 4.4 유지보수성

| 항목 | 요구사항 |
|------|---------|
| NFR-9 | `10-image-analysis.md` 룰 변경이 최소화되어야 한다 (섹션 추가만 허용, 기존 내용 수정 최소). |
| NFR-10 | 참고 조건(T-1~T-5)은 SKILL.md와 10-image-analysis.md 양쪽에 동기화된다. |

---

## 5. 제약사항

| ID | 제약사항 | 이유 |
|----|---------|------|
| CON-1 | `coord_picker.html` 파일 자체를 수정하지 않는다 | 도구는 이미 완성된 상태 (v2.0.0). 스킬은 "안내자" 역할만 담당 |
| CON-2 | 기존 `10-image-analysis.md` 워크플로우(Step 1~4)를 변경하지 않는다 | 기존 OCR 파이프라인은 그대로 유지. Fallback 섹션만 추가 |
| CON-3 | `08-skill-routing.md`의 기존 스킬 항목을 변경하지 않는다 | 신규 행 추가만 허용 |
| CON-4 | 스킬은 파일을 자동 생성하거나 명령어를 자동 실행하지 않는다 | 안내(텍스트 출력)만 담당. 실제 파일 작업은 사용자가 직접 수행 |
| CON-5 | Python 코드 수정 없음 (`extract_overlay_bbox.py`, `annotate_anatomy.py` 등) | Fallback은 Claude 룰/스킬 레이어에서만 처리 |
| CON-6 | 글로벌 스킬 경로 준수 (`C:\claude\.claude\skills\`) | `09-global-only.md` 규칙: 서브프로젝트에 리소스 로컬 생성 금지 |
| CON-7 | API 키 방식 사용 금지 | CLAUDE.md 핵심 원칙 (Browser OAuth만 허용) — 이 스킬은 API 호출 없음으로 해당 없음 |
| CON-8 | 시스템 자동 트리거 금지 (`auto_trigger: false`) | 분석 실패 판단 권한은 사용자에게 있음. 시스템이 임의로 Fallback 실행 불가 |

---

## 6. 우선순위

### P1 — 핵심 (Must Have)

| ID | 항목 | 근거 |
|----|------|------|
| P1-1 | `SKILL.md` 신규 생성 (FR-4) | 스킬이 없으면 Fallback 자체가 불가능 |
| P1-2 | `10-image-analysis.md` 사용자 확인 플로우 섹션 추가 (FR-3) | 사용자 확인 요청 룰 없으면 스킬이 수동 호출에만 의존 |
| P1-3 | 사용자 재처리 의사 키워드 감지 구현 (FR-1-2) | 사용자 판단 기반 트리거의 핵심 메커니즘 |
| P1-4 | coord_picker.html 사용법 5단계 안내 (FR-2-3) | 사용자가 도구를 처음 접하는 경우 단계별 안내 필수 |

### P2 — 권장 (Should Have)

| ID | 항목 | 근거 |
|----|------|------|
| P2-1 | `08-skill-routing.md` 테이블 업데이트 (FR-5) | 스킬 라우팅 일관성 유지 (없어도 스킬 자체는 동작) |
| P2-2 | T-1~T-5 참고 조건 사용자 안내 (FR-1-4) | 사용자 판단을 돕는 보조 정보 제공 |
| P2-3 | WSOP 프리셋 파일 안내 (FR-2-5) | EBS 프로젝트 전용이라 범용성 낮음 |

### 구현 순서

```
P1-1 (SKILL.md 생성)
    |
    v
P1-2 (10-image-analysis.md 수정)
    |
    v
P2-1 (08-skill-routing.md 수정)
    |
    v
P2-2, P2-3 (참고 조건 및 프리셋 안내 확장)
```

---

## 참조

| 문서 | 경로 |
|------|------|
| 이미지 분석 룰 | `C:\claude\.claude\rules\10-image-analysis.md` |
| 스킬 라우팅 룰 | `C:\claude\.claude\rules\08-skill-routing.md` |
| coord_picker.html | `C:\claude\ebs_reverse\scripts\coord_picker.html` |
| 오버레이 좌표 JSON | `C:\claude\ebs_reverse\docs\01-plan\data\overlay-anatomy-coords.json` |
| 글로벌 스킬 경로 | `C:\claude\.claude\skills\` |
| 관련 PRD | `C:\claude\ebs_reverse\docs\00-prd\coord-picker-global.prd.md` |

---

## Changelog

- v2.0.0 (2026-02-24): 트리거 모델 변경 — 시스템 자동 감지 → 사용자 판단 기반 확인 플로우
- v1.0.0 (2026-02-24): 최초 작성 (T-1~T-5 자동 트리거 모델)
