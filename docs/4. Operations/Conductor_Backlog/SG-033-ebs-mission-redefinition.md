---
id: SG-033
title: "EBS 미션 재선언 — 속도 KPI 폐기, 정확성·안정성·단단한 HW 5 가치 채택"
type: SPEC_GAP_TYPE_C
status: RESOLVED
created: 2026-05-05
resolved: 2026-05-05
owner: conductor
classification: Type C (기획 정렬 PR — 기획서 간 충돌 해소)
trigger: "사용자 critic directive 2026-05-05"
related-docs:
  - docs/1. Product/Foundation.md (§Ch.1.4 미션 / Stat Block / §Ch.3.4 / §Ch.6.4)
  - docs/1. Product/Command_Center_PRD.md (Ch.3, §3.3, §7.1)
  - docs/1. Product/Back_Office_PRD.md (§7.1, §7.2)
  - docs/1. Product/Lobby_PRD.md (Ch.1.94-96, §3.2.196-198)
  - docs/2. Development/2.5 Shared/Card_Flow_Index.md (§5, §7)
  - docs/4. Operations/Roadmap.md (§품질 기준)
  - docs/1. Product/References/foundation-visual/prd-ebs-4steps.html
---

# SG-033 — EBS 미션 재선언

## Trigger (사용자 directive 2026-05-05)

사용자 critic 핵심 인용:

> "베팅 액션을 딜러가 입력하는게 아니라, 딜러는 플레이어의 액션을 리드하여 처리해주고, 이 처리된 액션을 후방의 컨트롤룸이에서 오퍼레이터가 액션을 입력하는 형태야. 그리고 빨리 인식되는게 중요한게 아니라, 정확하게 인식되는게 중요한거야. 0.1초 100ms 이내같은 기술적인 용어는 EBS 에서 전혀 중요하지 않음. 장비간 안정성, 명확하게 연결되고 문제 없이 처리되는 단단한 하드웨어가 중요해."

## 발견된 모순 (Type C — 기획서 간 충돌)

### 결함 #1 — 베팅 액션 입력 주체 잘못 표기

| 위치 | 잘못된 표기 | 정정 |
|------|-----------|------|
| Foundation.md line 225 (Mermaid) | `B[딜러<br/>액션 입력]` | `B[CC 오퍼레이터<br/>액션 입력]` |
| Foundation.md line 239 본문 | "딜러가 입력한 베팅 액션" | "CC 오퍼레이터가 후방 컨트롤룸에서 입력한 베팅 액션" |
| Command_Center_PRD.md line 206 | "운영자(딜러)" | "CC 오퍼레이터" (역할 분리 명시) |

### 결함 #2 — EBS 핵심 가치가 속도로 정의됨

| 위치 | 잘못된 표기 | 정정 |
|------|-----------|------|
| Foundation.md line 20 (첫 줄) | "100ms 이내 송출" | "정확하고 안정된 송출" |
| Foundation.md line 22 (Stat Block 첫 칼럼) | "100ms / 처리 SLA" | "0 / 누락·오류" |
| Foundation.md §Ch.1.4 챕터명 | "0.1초의 번역가" | "**완벽한 번역가**" |
| Foundation.md line 241 미션 선언 | "100ms 이내에... 번역해 송출" | "정확하고 빠짐없이, 단단한 장비 사슬을 통해..." |
| Command_Center_PRD.md Ch.3 챕터명 | "0.1초의 마법" | "RFID 자동 인식의 마법" |
| Back_Office_PRD.md §7.2 챕터명 | "100ms 약속의 의미" | "안정된 동기화의 의미" |

### 결함 #3 — 운영자 / 딜러 역할 미분리

EBS 의 운영 모델 (오프라인 라이브 포커):

```
  ┌─ 테이블 (live, 무대 위) ──┐    ┌─ 컨트롤룸 (back, 무대 뒤) ─┐
  │                            │    │                              │
  │  [딜러]                    │    │  [CC 오퍼레이터]              │
  │  플레이어 액션을 리드/처리  │    │  플레이어 액션을 눈으로 보고   │
  │  (콜/레이즈/폴드 진행)     │    │  CC 화면에 액션 입력           │
  │                            │    │                              │
  │  RFID 자동 카드 인식 ────────────→ Engine + Overlay            │
  │                            │    │                              │
  └────────────────────────────┘    └──────────────────────────────┘

   * 딜러 ≠ CC 오퍼레이터 (서로 다른 사람, 다른 위치, 다른 역할)
```

## 결정 — EBS 핵심 가치 5종 (재정의)

```
  1. 정확한 인식                  RFID 가 카드 1장 1장을 빠짐없이 정확히 읽는다
  2. 장비 간 안정성                RFID 리더 / Engine / CC / Overlay 가 단단히 연결
  3. 명확한 연결                   문제 발생 시 어디서 끊겼는지 즉시 식별 가능
  4. 단단한 하드웨어               12 안테나 + RFID 칩 + 인클로저가 12시간+ 안정 동작
  5. 오류 없는 처리 흐름            카드 1장도 누락 없음, 액션 1건도 중복 없음
```

**속도 KPI (100ms / 0.1초) 위치 변경**:
- 이전: EBS 미션 / 핵심 가치 / 가장 강한 약속
- 이후: 운영 안정성 메트릭 (NFR — Non-Functional Requirements). 시스템 동작 기준점으로만 보존, EBS 정체성 정의에서 제거.

## Cascade 처리 (5 Phase)

| Phase | 영역 | 처리 결과 |
|:-----:|------|-----------|
| A | Foundation.md (Tier 1, SSOT) | ✅ §Ch.1.4 + Stat Block + 첫 줄 + Mermaid + 본문 + §Ch.3.4 + §Ch.6.4 정정 + Edit History 1행 |
| B | Command_Center_PRD + Back_Office_PRD (Tier 2) | ✅ Ch.3 챕터명 + 본문 + 역할 분리 / §7.2 챕터명 + 운영 메트릭 강등 + Changelog |
| C | Lobby_PRD + Roadmap + HTML 자산 (Tier 3) | ✅ 인용 표현 정합 + Lobby_PRD v1.2.0 Changelog + HTML badge |
| D | Card_Flow_Index + 기술 SLA 선별 (Tier 4) | ✅ "SLA 목표" → "운영 메트릭 (NFR — 핵심 가치 아님)" 표현 정합. 86 파일 중 가치 표현만 정정, NFR 보존 |
| E | SG-033 + B-Q12 (Tier 5) | ✅ 본 문서 + B-Q12 재명명 |

## 사용자 directive 채택 근거

| 사용자 명문 | 본 SG 처리 |
|------------|-----------|
| "딜러는 플레이어 액션 리드, 오퍼레이터가 입력" | Mermaid + 본문 + §3.3 정정 |
| "정확하게 인식되는게 중요" | "완벽한 번역가" 미션 + 5 가치 정의 |
| "0.1초 100ms 같은 기술 용어 EBS 에서 전혀 중요하지 않음" | EBS 핵심 가치 영역에서 제거 |
| "장비간 안정성, 단단한 하드웨어 중요" | 5 가치 중 2-4 항목 명시 |
| "운영 안정성 메트릭은 보존, 핵심 가치 표현만 제거" | NFR / SLO 표 보존, "약속의 의미" 같은 가치 표현만 정정 |

## 영향 통계

| 분류 | 파일 수 | 변경 라인 |
|------|:------:|:---------:|
| Tier 1 (Foundation) | 1 | ~20줄 |
| Tier 2 (외부 PRD) | 2 | ~30줄 |
| Tier 3 (derivative) | 4 | ~10줄 |
| Tier 4 (기술 SLA 선별) | ~10 | ~20줄 |
| Tier 5 (Backlog) | 2 | ~10줄 |
| 신규 (본 SG) | 1 | 신규 |
| **합계** | **20 파일** | **~90줄 변경 + 1 신규 SG** |

## 후속 작업

| Backlog | 처리 |
|---------|:----:|
| B-Q12-100ms-sla-measurement.md | ✅ 본 cascade 에서 재명명 — "안정성 측정" 으로 |
| B-Q7-quality-criteria-production.md | ⏳ "정확성/안정성" 가치 추가 (선택, 후속 turn) |

## Changelog

| 날짜 | 변경 |
|------|------|
| 2026-05-05 | 신규 작성 + RESOLVED — 5 Phase cascade 자율 진행 완료 (사용자 directive: "운영 안정성 메트릭은 보존하되 핵심 가치 표현만 제거하고 모든 문서 수정 작업 자율 진행 iteration") |
