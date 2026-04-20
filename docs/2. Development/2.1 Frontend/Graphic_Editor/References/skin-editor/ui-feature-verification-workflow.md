---
title: ui-feature-verification-workflow
owner: team1
tier: internal
last-updated: 2026-04-15
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "UI 검증 워크플로우 (8KB) 완결"
---
# UI Feature Verification Workflow

> **목적**: RE(역설계) 문서 기준으로 UI 모듈의 기능 커버리지를 검증하고, 모듈 간 중복을 식별하여 SSOT를 결정하는 6단계 범용 프로세스.

## 적용 대상

| UI 모듈 | RE 매핑 소스 | 비고 |
|---------|-------------|------|
| Skin Editor 메인 | ConfigurationPreset 전체 | PRD-0006 §2~§5 |
| GE (Board~Strip) | image_element / text_element | PRD-0006 §4 |
| Console GFX 탭 | ConfigurationPreset 일부 | 향후 Console PRD |
| Console AT 탭 | AT 관련 필드 | 향후 Console PRD |

---

## Step 1: Scope Definition

대상 UI 모듈과 RE 매핑 범위를 정의한다.

### 입력

| 항목 | 설명 | 예시 |
|------|------|------|
| **Target Module** | 검증 대상 UI 모듈명 | Skin Editor Main Window |
| **RE Source** | 역설계 문서 내 매핑 범위 | ConfigurationPreset 전체, image_element 41필드 |
| **IN Filter** | 스코프에 포함할 카테고리 | Board, Player, Blinds, Outs, History, LB, Field, Strip |
| **OUT Filter** | 명시적 제외 항목 + 사유 | Ticker (별도 시스템), SSD (별도 시스템), Action Clock (운영 설정) |

### Checkpoint 1

- [ ] IN/OUT 필터 정의 완료
- [ ] OUT 항목마다 제거 사유 1줄 이상 명시

---

## Step 2: Feature Extraction (RE 기준선)

RE 문서에서 대상 필드를 전수 추출하여 기준선 체크리스트를 만든다.

### 추출 대상

```
ConfigurationPreset
  └─ 전체 필드 → 카테고리별 그룹화
image_element
  └─ 41필드 (좌표, 회전, 앵커, 플립 등)
text_element
  └─ 52필드 (폰트, 색상, 정렬, 그림자, 아웃라인 등)
Animation
  └─ skin_transition_type enum + timing 필드
```

### 출력 형식

| # | RE 필드명 | 카테고리 | 데이터 타입 | RE 문서 위치 |
|:-:|----------|---------|-----------|-------------|
| 1 | `_flip_x` | image_element | bool | §3.2 41필드 |
| 2 | `custom_text_renderer` | text_element | class | §3.3 52필드 |
| ... | ... | ... | ... | ... |

### Checkpoint 2

- [ ] 추출 필드 수 = RE 문서 총계 (수동 카운트 대조)

---

## Step 3: Forward GAP Check (RE → UI)

각 RE 필드가 UI에 매핑되었는지 검증한다.

### 상태 분류

| 상태 | 의미 | 후속 조치 |
|:----:|------|----------|
| **OK** | UI 컨트롤에 1:1 매핑됨 | 없음 |
| **GAP** | UI에 대응 컨트롤 없음 | 심각도 분류 → PRD 반영 |
| **PARTIAL** | 일부만 노출 (예: enum 중 3/5만) | 누락 항목 명시 |
| **DROPPED** | 의도적 제외 (Step 1 OUT Filter) | 사유 재확인 |
| **VERIFY** | 매핑 가능하나 동작 확인 필요 | 프로토타입에서 검증 |

### 출력: GAP Table

| # | RE 필드 | 상태 | UI 위치 | 심각도 | 비고 |
|:-:|--------|:----:|---------|:------:|------|
| G1 | `_flip_x` | GAP | — | HIGH | Transform 패널에 QToggle 추가 |
| G2 | `custom_text_renderer` | GAP | — | MED | Text 패널에 Outline 추가 |
| ... | ... | ... | ... | ... | ... |

### 심각도 기준

| 심각도 | 기준 | 처리 |
|:------:|------|------|
| **HIGH** | 사용자가 즉시 필요로 하는 기능 | P1 — 해당 섹션에 컨트롤 추가 |
| **MED** | 없으면 config 직접 편집 필요 | P1 — PRD에 명시, 구현 일정 결정 |
| **LOW** | 고급 기능 또는 사용 빈도 낮음 | P2 — 백로그 기록 |
| **VERIFY** | 매핑 여부 불확실 | 프로토타입 후 재분류 |

### Checkpoint 3

- [ ] 모든 RE 필드가 5개 상태 중 하나로 분류됨
- [ ] DROPPED 항목 전체에 제거 사유 명시

---

## Step 4: Cross-Module Duplication Check

인접 UI 모듈과 동일 필드가 존재하는지 검색한다.

### 검사 매트릭스

```
Target Module ──→ 인접 모듈 1 (필드 비교)
              ──→ 인접 모듈 2 (필드 비교)
              ──→ ...
```

### 중복 유형

| 유형 | 설명 | 예시 |
|:----:|------|------|
| **IDENTICAL** | 동일 필드, 동일 의미 | `board_pos` — Console Layout vs Skin Layout |
| **SEMANTIC** | 다른 필드명, 동일 기능 | Console `animation_speed` vs GE `trans_speed` |
| **PARTIAL** | 부분 중복 (superset/subset) | Console에 5개 중 3개만 노출 |

### 출력: Duplication Table

| # | 필드 그룹 | Module A 위치 | Module B 위치 | 유형 | SSOT 모듈 | Override 정책 |
|:-:|----------|-------------|-------------|:----:|:---------:|-------------|
| D1 | Layout 7필드 | Skin Settings | Console GFX | IDENTICAL | Skin | Console Override |
| D2 | Chipcount 5영역 | Skin Settings | Console Display | IDENTICAL | Skin | Console Override |
| ... | ... | ... | ... | ... | ... | ... |

### 해결 정책 패턴

| 패턴 | 설명 | 적용 조건 |
|------|------|----------|
| **Skin Default → Console Override** | Skin이 디자인 기본값, Console이 런타임 override | 동일 필드가 Skin + Console 양쪽에 존재 |
| **Module Exclusive** | 한 모듈에서만 편집 가능 | 필드가 한 모듈에만 의미 있음 |
| **Sync** | 양쪽 동기화 (양방향) | 두 모듈에서 동등하게 편집 필요 |

### Checkpoint 4-5

- [ ] 중복 항목 전체에 SSOT 모듈 지정됨
- [ ] Override 정책이 명확히 정의됨

---

## Step 5: Reverse Verification (UI → RE)

UI 컨트롤 기준으로 RE 필드 대응을 확인한다 (역방향 검증).

### 상태 분류

| 상태 | 의미 | 후속 조치 |
|:----:|------|----------|
| **MAPPED** | RE 필드에 정확히 대응 | 없음 |
| **EBS-NEW** | EBS에서 신규 추가 (RE에 없음) | 정당성 문서화 |
| **ORPHAN** | RE 대응 없고 신규도 아님 | 제거 검토 |

### 출력 형식

| UI 컨트롤 | Element ID | 상태 | RE 필드 | 비고 |
|-----------|:----------:|:----:|--------|------|
| skin_type QSelect | 07 | EBS-NEW | — | UI 미노출 필드 표면화 |
| Remove Alpha QToggle | 03 | MAPPED | `remove_alpha` | — |

---

## Step 6: Report + PRD Update

### 종합 보고서 구조

```
1. Executive Summary
   - 총 RE 필드 수 / OK / GAP / DROPPED / VERIFY
   - 중복 필드 그룹 수 / SSOT 지정 완료 수

2. GAP Table (Step 3 출력)
   - HIGH/MED 항목 → PRD 즉시 반영
   - LOW 항목 → P2 백로그

3. Duplication Table (Step 4 출력)
   - SSOT 지정 + Override 정책

4. Reverse Check (Step 5 출력)
   - ORPHAN 항목 → 제거 or 정당성 추가

5. Action Items
   - PRD 업데이트 목록 (섹션 + 변경 내용)
   - Changelog 항목
```

### PRD Update 규칙

- GAP 결과 → PRD의 해당 섹션에 컨트롤 추가 명시
- Duplication 결과 → PRD 설계 결정 요약(§7)에 SSOT 정책 추가
- Changelog에 GAP/Duplication 분석 반영 기록

### Checkpoint 6

- [ ] VERIFY 항목 = 0 (모두 재분류 완료)
- [ ] 모든 Action Item에 대상 PRD 파일 + 섹션 명시

---

## Checkpoint Summary

| CP | 통과 기준 | Step |
|:--:|----------|:----:|
| 1 | 스코프 필터 정의 완료, OUT 사유 명시 | 1 |
| 2 | RE 기준선 필드 수 = RE 문서 총계 | 2 |
| 3 | GAP Table 모든 항목이 5개 상태 중 하나 | 3 |
| 4 | DROPPED 항목 전체에 제거 사유 명시 | 3 |
| 5 | 중복 항목 전체에 SSOT 모듈 지정 | 4 |
| 6 | VERIFY 항목 = 0 (모두 재분류) | 6 |

---

## Appendix: 적용 예시

### A. Skin Editor Main Window (PRD-0006)

```
Step 1: Target=Skin Editor, RE=ConfigurationPreset+image_element+text_element
        OUT=Ticker(별도 시스템), SSD(별도), Action Clock(운영 설정)

Step 3: G1~G9 발견 → GAP Table 생성
        HIGH: G1(_flip_x)
        MED:  G2(outline), G4(game_name_in_vanity), G7(cp_strip precision)
        LOW:  G3(gradient), G5(nit_display), G6(sprite frame), G8(effects chain)

Step 4: D1~D5 중복 발견
        Layout/Chipcount/CardDisplay/Statistics/Transition
        정책: Skin Default → Console Override

Step 6: PRD-0006 §5.1 + §7 #8 업데이트
```

### B. Console GFX 탭 (향후)

```
Step 1: Target=Console GFX, RE=ConfigurationPreset
        OUT=Skin 전용 필드 (이미지 에셋 등)

Step 4: Skin Editor와 중복 체크
        → SSOT=Console (런타임 override 모듈)
```
