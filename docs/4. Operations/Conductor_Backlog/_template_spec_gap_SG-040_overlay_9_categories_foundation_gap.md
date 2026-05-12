---
id: SG-040
title: "기획 공백 + 모순: User 9 카테고리 vs Foundation Scene 1 (8 그래픽) vs RIVE Ch.2 (11 카테고리) 부정합"
type: spec_gap_inconsistency
status: IN_PROGRESS
owner: conductor
created: 2026-05-13
affects_chapter:
  - docs/1. Product/Foundation.md §Ch.2 Scene 1 (현재 8 그래픽)
  - docs/1. Product/RIVE_Standards.md §Ch.2 (현재 11 카테고리)
  - docs/1. Product/Command_Center.md (User 9 cat 매핑 부록 신규)
  - docs/2. Development/2.3 Game Engine/APIs/OutputEvent_Serialization.md (21 OE ↔ 9 cat 매핑)
  - docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md (overlay/layer1 widget 3종 spec)
protocol: Spec_Gap_Triage
audit_report: docs/4. Operations/Reports/Overlay_9_Categories_Mapping_Audit_2026-05-13.md
cycle: 17
broker_topic: pipeline:gap-classified (Cycle 16 trigger, S10-W 수행)
related_sg:
  - SG-041 (overlay/layer1 widget 3종 누락 — 본 SG 의 구현 cascade)
  - B-356 (OE-12~21 번호 매핑 — D-5 와 함께 closure)
---

# SG-040 — User 9 카테고리 vs Foundation Scene 1 vs RIVE Ch.2 부정합

## 공백 서술

사용자가 2026-05-13 Cycle 16 에서 **시청자 시선 기반 9 카테고리** (포커 그래픽 오버레이) 를 명시 인텐트로 제시했다. 그러나 현재 3 spec source 가 서로 다른 분류 base 를 사용하여 정합이 깨져 있다.

```
+---------------------------+----------+--------------------------------------+
| 소스                       | 카테고리 수  | 분류 base                              |
+---------------------------+----------+--------------------------------------+
| User 9 cat (Cycle 16)     | 9        | 시청자 시선 (한 화면 동시 인지)           |
| RIVE_Standards §Ch.2      | 11       | 기술 구현 단위 (RIVE 파일)              |
| Foundation §Ch.2 Scene 1  | 8        | EBS 책임 그래픽 (디자인팀 제외 후 잔여)     |
| OutputEvent (Game Engine) | 21       | 이벤트 발생 단위                        |
+---------------------------+----------+--------------------------------------+
```

**Type B (기획 공백) 3건** + **Type C (기획 모순) 3건** = 9 카테고리 재편 인텐트 미반영 6 gap.

| 분류 | ID | 영역 | 갭 |
|------|:--:|------|----|
| Type B | B-1 | Foundation §Ch.2 Scene 1 | **Branding** (WSOP/APT 로고) 미정의. Scene 2 의 "사전 제작 = 디자인팀" 으로 명시 제외. User 9 #6 으로 포함됨. EBS 책임 영역 불명확. |
| Type B | B-2 | Foundation §Ch.2 Scene 1 | **Blind** (레벨 + 앤티) 미정의. RIVE #7 / backend API 모두 존재. Foundation 만 누락. |
| Type B | B-3 | Foundation §Ch.2 Scene 1 | **Field** (참가자 / ITM / FT) 미정의. RIVE #8 "토너먼트 상태" 로 존재. Foundation 만 누락. |
| Type C | C-1 | User 9 vs RIVE Ch.2 / Foundation Scene 1 | User 9 에 **시계 (Hand Clock + Level Clock)** 누락. RIVE #9 + Foundation Scene 1 핵심 그래픽. 실제 방송 필수. |
| Type C | C-2 | RIVE Ch.2 #3 vs User 9 #2 + #5 | RIVE = **카드 #3 단일** (홀+커뮤), User 9 = **#2 핸드 그래픽 + #5 보드 분리**. 시청자(분리) vs 기술(단일) 충돌. |
| Type C | C-3 | RIVE Ch.2 #1+#2 vs User 9 #1 | RIVE = **Player Card #1 + Stack/Bet #2 분리**, User 9 = **플레이어 대시보드 #1 통합** (Name+국적+포지션+칩스택). 분류 base 충돌. |

## 발견 경위

- **트리거**: 사용자 명시 — 포커 그래픽 오버레이 9 카테고리 (시청자 시선 기반 인지 단위) 인텐트 제시 (2026-05-13 Cycle 16).
- **S10-A audit**: `Reports/Overlay_9_Categories_Mapping_Audit_2026-05-13.md` (PR #395 merged) — 4-way 매트릭스 (User 9 ↔ RIVE 11 ↔ Foundation 8 ↔ OutputEvent 21 ↔ team1~4 코드).
- **실패 분류**: Type B 3건 (기획 공백) + Type C 3건 (기획 모순). 빌드/테스트 실패 신호 아닌 **사용자 인텐트 vs spec 정합 점검** 으로 발견.
- **연결 ID**: SG-041 (overlay/layer1 widget 3종 누락 — Type D drift, 본 SG 의 구현 cascade). B-356 carry-over (OE-12~21 번호 매핑, D-5 와 함께 closure).
- **rebase 노트**: 작업 당시 SG-038 등재 시도했으나 Cycle 15 audit (PR #392) 이 같은 ID 를 `sync_cursors` D2 regression 으로 먼저 점유 → SG-040 재할당. 작업 내용은 보존.

## 영향받는 챕터 / 구현

| 챕터 | 결정 비어있는 부분 / 상충 | Gap ID |
|------|--------------------------|:------:|
| `Foundation.md` §Ch.2 Scene 1 | "8 그래픽" 정의 — Branding/Blind/Field 미정의 (3건). User 9 base 로 재편 필요. | B-1, B-2, B-3 |
| `Foundation.md` §Ch.2 Scene 1 | 시계 (Hand Clock + Level Clock) — User 9 외부지만 Foundation Scene 1 은 핵심 그래픽으로 정의. User 9 표가 spec base 면 시계 누락 위험. | C-1 |
| `RIVE_Standards.md` §Ch.2 | #3 카드 — 홀+커뮤 단일 vs User 9 분리. #1+#2 Player Card+Stack/Bet 분리 vs User 9 통합. | C-2, C-3 |
| `RIVE_Standards.md` §Ch.2 | #9 시계 / #11 운영자 표식 — 시청자 화면 영역과 분리 필요. | C-1 |
| `Command_Center.md` (외부 인계 PRD) | 9 카테고리 ↔ CC 이벤트 발행 매핑 부록 미존재 — 외부 개발팀이 어떤 이벤트가 어떤 그래픽을 변경하는지 추적 불가. | B-1~3 cascade |
| `OutputEvent_Serialization.md` §Ch.X | 21 OE ↔ 9 cat 매핑 컬럼 없음. OE-12~21 번호 정렬 미완 (B-356 carry-over). | D-5 cascade |
| `Command_Center_UI/Overview.md` | overlay/layer1 widget 3종 (branding_layer / blind_panel / field_status) spec 부재 → SG-041 구현 cascade 의 진입점. | SG-041 cascade |

## 결정 방안 후보

| 대안 | 장점 | 단점 | WSOP LIVE 패턴 정렬 |
|------|------|------|---------------------|
| **1. Foundation 9 카테고리 base 재편 + RIVE 재배열** (S10-A audit §5 권고) | 사용자 인텐트 직접 정합. SSOT root (Foundation) 우선. cascade 의존성 명확 (§5.1). | Foundation §Ch.2 MAJOR rewrite — Reader Panel 재실행 필요. 5 derivative 문서 동기화 부담. | ✅ |
| 2. RIVE 11 카테고리 그대로 + User 9 는 시청자용 별 부록 | Foundation/RIVE 변경 최소. | "spec base" 가 분리되어 외부 개발팀 혼란. 결국 새 사용자 명시 인텐트 (9 cat) 가 무시됨. | ❌ |
| 3. User 9 카테고리에 시계 추가 (10 cat 으로 확장) + Foundation 재편 | 시계 누락 위험 (C-1) 동시 해소. | 사용자 명시 인텐트 (9) 변경 — 사용자 결정 영역. | △ |
| 4. SUPERSEDE: 사용자에게 9 vs 11 분류 base 결정 요청 | 결정 모호성 차단. | 사용자 진입점 추가 — Core Philosophy 위반 가능. 다만 분류 base 는 product 결정이라 *의미 차원* — 허용 범위. | △ |

## 결정

- **채택**: **대안 1** (Foundation 9 카테고리 base 재편 + RIVE 재배열) + **시계는 별 챕터 (Operating Graphics)** 로 분리 — Type C 1건 (C-1) 자율 해소.
- **이유**:
  1. 사용자 명시 인텐트 (시청자 시선 기반 9 cat) 가 SSOT 결정. spec 은 인텐트를 따른다.
  2. SSOT root = Foundation. §Ch.2 가 재편되면 RIVE/CC/OE/UI 가 derivative cascade.
  3. 시계는 9 cat 외부이나 운영 필수 — Foundation 별 챕터 "Operating Graphics" (시계/운영자 표식) 분리 명시.
  4. 홀+커뮤니티 분리 (C-2) + Player Dashboard 통합 (C-3) = User 9 base 채택으로 자동 결정.
- **영향 챕터 업데이트 PR**: 본 PR (S10-W cycle 17). S10-A audit §5 cascade 매트릭스 5 문서 동시 정합 — 단, **본 PR (Cycle 17 S10-W) 범위 = SG-040/041 카드 + Registry 등재** 만 우선. 5 문서 cascade 본문 정합은 후속 S10-W cycle (도메인 owner 머지 권한 분리).
  1. `Foundation.md §Ch.2` (MAJOR rewrite — 8 그래픽 → 9 카테고리 + 별 챕터 운영 그래픽) — 후속 cycle
  2. `RIVE_Standards.md §Ch.2` (MAJOR restructure — 11 cat 재배열 + User 9 base) — 후속 cycle
  3. `Command_Center.md` (MINOR append — 9 cat ↔ CC 이벤트 매핑 부록) — 후속 cycle
  4. `OutputEvent_Serialization.md` (MINOR append + critical fix — OE-12~21 번호 정렬 = B-356 closure) — 후속 cycle
  5. `Command_Center_UI/Overview.md` (NEW spec sections — overlay/layer1 widget 3종) — 후속 cycle
- **후속 구현 Backlog 이전**: `../Implementation/B-CC-OVERLAY-WIDGETS-3.md` (team4 cascade — branding_layer / blind_panel / field_status, SG-041 본체)

## 결정 후 follow-up

| 후속 항목 | 담당 stream | 우선순위 | trigger |
|----------|------------|:-------:|---------|
| Foundation §Ch.2 9 cat MAJOR rewrite (Reader Panel 재실행 포함) | S10-W (후속 cycle) | **P0** | 본 PR 머지 후 즉시 |
| RIVE_Standards §Ch.2 MAJOR restructure (#3 카드 분리 + #1+#2 Player 통합) | S10-W (후속 cycle) | **P0** | Foundation 정합 후 동시 |
| Command_Center.md 9 cat ↔ CC 이벤트 매핑 부록 | S10-W (후속 cycle) | P1 | Foundation 정합 후 |
| OutputEvent_Serialization.md 21 OE ↔ 9 cat 매핑 + B-356 closure | S10-W (후속 cycle) | P1 | RIVE 정합 후 |
| Command_Center_UI/Overview.md overlay widget 3종 spec NEW section | S10-W (후속 cycle) | P1 | Foundation 정합 후 |
| team4-cc overlay/layer1 widget 3종 implementation (SG-041 본체) | S2 (Lobby/CC) | P0 | UI spec 후 SG-041 cascade |
| team2-backend `field_status` 전용 API (ITM/remaining/FT) | S7 (Backend) | P1 | UI spec 후 |
| Equity progress bar 보강 (% 텍스트 → progress bar, UI-02) | S2 (CC) | P1 | OE 매핑 후 |
| 시계 (Hand Clock + Level Clock) Operating Graphics 별 챕터 명시 | S10-W (후속 cycle) | P2 | Foundation §Ch.2 분리 시 |

## P2+ 추가 검토 (사용자 결정 영역)

| 항목 | 사용자 결정 필요 | 우선순위 |
|------|:--------------:|:-------:|
| User 9 카테고리에 시계 추가하여 10 cat 으로 확장 — vs Operating Graphics 별 챕터 분리 | △ (현 결정: 별 챕터) | P2 |
| Player Dashboard 의 Name + 국적 + 포지션 + 칩스택 — 단일 카드 vs 2 카드 분리 | △ (현 결정: 통합 = User 9 base) | P2 |

---

## Edit History

| 날짜 | 작성자 | 변경 |
|------|--------|------|
| 2026-05-13 | S10-W | 초판 — Cycle 17 SG-040 신규 카드. Cycle 16 audit (PR #395) 의 §7 SG-040 신규 등재 권고 후속. Type B 3 + Type C 3 분류. cascade 5 문서 매트릭스 결정 (대안 1 채택). 본 PR 범위는 카드+Registry 등재. 본문 cascade 는 후속 S10-W cycle 위임. |
