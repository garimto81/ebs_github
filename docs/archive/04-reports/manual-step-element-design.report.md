# PokerGFX 매뉴얼 v3.2.0 Step별 요소 분석 및 EBS 설계 — PDCA 완료 보고서

**보고 일시**: 2026-02-26 | **프로젝트**: PRD-0004 EBS Server UI Design

---

## 1. 작업 개요

### 목표

PRD-0004(v21.0.0)의 Step 1~9 각각에 대해 PokerGFX 매뉴얼 v3.2.0 원문과 완전 대조하여 누락/오류 요소를 식별하고, Step별 완전한 요소 설계 문서를 작성한다.

### 해결 문제

1. PRD-0004 Element Catalog와 매뉴얼 전체 범위 간 완전성 검증이 미수행된 상태
2. `PokerGFX-Manual-v3.2.0-Element-Reference.md`와 PRD-0004 간 1:1 매핑 검증 부재
3. PRD-0004에 `N/A`로 분류된 매뉴얼 요소들의 EBS 설계 결정이 미문서화

### 산출물

| 파일 | 설명 | 규모 |
|------|------|------|
| `docs/01-plan/manual-step-element-design.plan.md` | 계획 문서 | 451줄 |
| `docs/02-design/pokergfx-manual-step-element-design.design.md` | 설계 문서 v2.1.0 | 690줄 |

---

## 2. 작업 결과

### Step별 요소 집계

| Step | PRD 요소 수 | Gap(PRD 누락) | Gap(탭 이동) | EBS 신규 |
|------|:-----------:|:-------------:|:------------:|:--------:|
| Step 1: Main Window | 13 (활성) + 2 (DROP) | 2 | 0 | 7 |
| Step 2: System | 23 | 2 | 0 | 5 |
| Step 3: Sources | 19 | 3 | 1 | 3 |
| Step 4: Outputs | 11 (활성) + 3 (DROP) | 7 | 0 | 3 |
| Step 5: GFX 1 | 28 | 2 | 6 | 6 |
| Step 6: GFX 2 | 20 | 2 | 4 | 7 |
| Step 7: GFX 3 | 12 | 1 | 2 | 0 |
| Step 8: AT (경계) | 0 | 0 | 0 | 0 |
| Step 9: Skin Editor + Graphic Editor | 26 + 19 = 45 | 6 | 0 | 2 |
| **합계** | **176** | **25** | **13** | **33** |

### EBS 설계 결정 분포

| 결정 | 대상 수 | 기준 |
|------|:-------:|------|
| v1.0 Keep | ~66 | MVP 방송 필수, 즉시 구현 |
| v2.0 Defer | ~74 | 운영 편의 기능, Phase 2 이후 |
| v3.0 Defer | ~18 | 고급/선택 기능 |
| Drop | 18 | EBS 운영 불필요 확정 |

---

## 3. 핵심 발견 사항

### 발견 1: 부록 A 집계(184) vs Element Catalog(176) 불일치

PRD-0004 부록 A는 v16.0.0 이전 기준 집계(184개)로, 현재 v21.0.0 Element Catalog(176개)와 8개 차이가 발생한다.

제외된 항목:
- **M-08** (Text Display), **M-10** (Stats Display) → v16.0.0에서 Future 처리 (Main Window -2)
- **O-06~O-13** (8개 Output 요소) → v16.0.0에서 Future 처리, Element Catalog 미포함 (Outputs -6)
- System: 부록 A 24개 기재 → 현재 Catalog 23개

**조치 필요**: 부록 A 집계를 176으로 업데이트하고 Future 처리 요소 명시 필요.

### 발견 2: O-08~O-13 Feature Mapping 참조 불일치

6개 Output 요소(O-08~O-13)가 Element Catalog에는 없으나 Feature Mapping에서 "(추후 개발)"로 참조 중이다. 부록 A와 Feature Mapping 간 일관성 정비 필요.

### 발견 3: 탭 이동 Gap 13개 — 실제 누락 아님

탭 이동 Gap으로 분류된 13개 요소는 PRD에 실제 존재하나, 매뉴얼 설명 위치와 PRD 배치 탭이 다른 경우다. 기능 자체는 구현 대상에 포함되어 있으므로 별도 PRD 수정 불필요.

---

## 4. 긴급 반영 대상 (8개 Gap 요소)

다음 Gap 요소는 방송 운영 필수 기능으로 다음 PRD-0004 개정 시 우선 반영을 권장한다.

| ID | 요소명 | 사유 |
|----|--------|------|
| GAP-1-01 | Secure Delay Icon | 보안 딜레이 표시 — 방송 보안 필수 |
| GAP-4-03 | Recording Status Indicator | 녹화 상태 확인 — 운영 필수 |
| GAP-4-04 | Stream Quality Indicator | 스트리밍 품질 모니터링 |
| GAP-4-05 | Output Preview Toggle | 출력 프리뷰 전환 |
| GAP-4-06 | Audio Level Meter | 오디오 레벨 확인 — 방송 필수 |
| GAP-5-07 | Skin Hot-swap Button | 화면 전환 중 스킨 교체 |
| GAP-5-08 | GFX Sync Indicator | GFX 동기화 상태 |
| GAP-7-03 | Display Side Pot Amount | **방송 필수** — 즉시 PRD-0004 G-50 그룹 추가 권장 |

---

## 5. Architect 검증

| 차수 | 결과 | 사유 |
|------|:----:|------|
| 1차 | REJECT | 합계 불일치 — 부록 A 184 vs Catalog 176 차이 미설명 |
| 2차 | **APPROVE** | 수정 후 합격. 경미 관찰: Step 4 DROP 카운트 수정 반영 완료 |

---

## 6. 다음 액션

1. **PRD-0004 부록 A 업데이트** — 184 → 176, Future 처리 요소 명시
2. **Gap 요소 20개 PRD-0004 반영** — 다음 PRD 개정 시 우선순위에 따라 반영
3. **GAP-7-03 즉시 반영** — Display Side Pot Amount를 PRD-0004 G-50 그룹에 추가 (방송 필수 기능)
4. **O-08~O-13 일관성 정비** — Feature Mapping 참조 주석 업데이트

---

## 변경 이력

| 날짜 | 버전 | 내용 | 작성자 |
|------|------|------|--------|
| 2026-02-26 | v1.0.0 | 최초 작성 | writer |

---

**Version**: v1.0.0 | **Updated**: 2026-02-26
