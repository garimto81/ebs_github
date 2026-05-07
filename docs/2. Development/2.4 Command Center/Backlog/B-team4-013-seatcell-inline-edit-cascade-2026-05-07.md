---
id: B-team4-013
title: "SeatCell 7행 onTap 인라인 편집 cascade — HTML 시안 vs Flutter drift"
status: PENDING
source: docs/2. Development/2.4 Command Center/Backlog.md
created: 2026-05-07
owner: prototype-session
appetite: Small (~2-3h, 5 다이얼로그 + 5 _RowCell onTap)
related_user_directive: |
  "플레이어 창의 모든 요소들 이름/시트/포지션/카드/액션/칩/스택 을
   개별적으로 입력하도록 html 버전에는 설계되어 있는데 반영되지 않은 이유"
  + "기획문서는 이슈만 발행하고 실제 코드구현 autonomous iteration"
related_specs:
  - docs/2. Development/2.4 Command Center/Command_Center_UI/Player_Edit_Modal.md  # 모달 진입 (BS-05-09)
  - docs/2. Development/2.4 Command Center/Command_Center_UI/Seat_Management.md  # 인라인 편집 우선 (UI-02 2026-04-13)
  - docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md
related_code:
  - team4-cc/src/lib/features/command_center/widgets/seat_cell.dart
related_reference:
  - C:/Users/AidenKim/Downloads/EBS Command Center (1)/PlayerColumn.jsx
predecessors:
  - B-team4-011  # CC Visual Uplift V5 SeatCell 7행 (2026-05-06)
  - B-team4-012  # 1×10 grid cascade (2026-05-07)
---

# B-team4-013 — SeatCell 7행 인라인 편집 cascade

## 배경

2026-05-07 사용자가 HTML 시안 (`PlayerColumn.jsx`) 의 행별 인라인 편집 패턴이 Flutter 에 반영 안 됐음을 지적:

> "플레이어 창의 모든 요소들 이름/시트/포지션/카드/액션/칩/스택 을 개별적으로 입력하도록 html 버전에는 설계되어 있는데 반영되지 않은 이유"

진단 결과 **7개 편집 가능 행 중 2개만 onTap 연결** (NAME + STACK), 5개 누락 (S#/POS/CTRY/BET/LAST).

## 7-Row onTap 매핑 비교 (drift 표)

| ROW | HTML 시안 (PlayerColumn.jsx) | Flutter (현재) | drift |
|:---:|------------------------------|----------------|:----:|
| 1 SEAT (S#) | `editField("seatNo")` "click to vacate" (line 50) | onTap **없음** | ❌ |
| 2 POSITION | `onEditPos={editField("pos")}` (line 55) | onTap **없음** | ❌ |
| 3a CTRY (flag) | `editField("flag")` "edit country" (line 58) | onTap **없음** | ❌ |
| 3b NAME | `editField("name")` "edit name" (line 64) | `_editName(seat)` ✅ | OK |
| 4 CARDS | `onCardClick(...)` (CardPicker, line 73) | onTap 없음 (D7 의도) | ⚠ D7 가드 — 의도적 |
| 5 STACK | `editField("stack")` "edit stack" (line 94) | `_editStack(seat)` ✅ | OK |
| 6 BET | `editField("bet")` "edit bet" (line 101) | onTap **없음** | ❌ |
| 7 LAST | `editField("lastAction")` "override last" (line 108) | onTap **없음** | ❌ |

## Spec drift 원인

| # | 원인 | 근거 |
|:--:|------|------|
| 1 | `Player_Edit_Modal.md` (BS-05-09) §2 진입 경로 = "롱프레스 → Context menu → Edit Player" 로 **모달 통합 패턴** 만 명시 — 행별 인라인 패턴 미문서화 | line 41 |
| 2 | `Seat_Management.md` UI-02 변경 (2026-04-13) 의 "인라인 편집 우선 원칙" 은 일반론만 — 행별 매핑 표 미등재 | edit history 2026-04-13 |
| 3 | B-team4-011 V5 (2026-05-06) 가 SeatCell 7행 시각 자산만 명시, onTap 매핑 누락 | B-team4-011 §V5 |
| 4 | `seat_cell.dart` 에 `_editPos` / `_editFlag` / `_editBet` / `_editLastAction` 함수 **자체 미구현** | seat_cell.dart grep `_edit[A-Z]` = 2개 |

## 기획 문서 갱신 요청 (이슈만 발행 — 사용자 지시)

본 backlog 항목 외 기획 문서 변경 **금지** (사용자 명시: "기획문서는 이슈만 발행"). 기획 문서 갱신은 별도 turn 에서 사용자 승인 후 진행:

| 문서 | 요청 변경 |
|------|----------|
| `Player_Edit_Modal.md §2` | "행별 인라인 편집 — 단일 필드 수정 시 권장 (2026-05-07 추가)" 항목 추가. 기존 모달 통합 = 다중 필드 동시 편집 시 |
| `Seat_Management.md §1` | 7-Row onTap 매핑 표 신규 (위 drift 표를 SSOT 로 등재) |
| `Overview.md §3.3` | "인라인 편집 우선 원칙" 의 행별 구체 매핑 link |

## 코드 구현 범위 (본 cascade autonomous iteration)

| 변경 | 줄수 (추정) |
|------|:----------:|
| `_editPos(seat)` — D/SB/BB/STR 토글 다이얼로그 | ~50 |
| `_editFlag(seat)` — 2-letter country code 입력 + 검증 | ~50 |
| `_editBet(seat)` — currentBet 직접 편집 (dev fallback) | ~50 |
| `_editLastAction(seat)` — activity enum 토글 | ~50 |
| `_vacateInline(seat)` — S# 클릭 → vacate confirm (기존 _confirmVacate 재사용) | ~10 |
| `_RowCell onTap` 5건 추가 (SEAT/POS/CTRY/BET/LAST) | ~10 |
| **합계** | **~220** |

## 가드레일

| # | 가드 | 검증 |
|:-:|------|------|
| 1 | hole card 값 노출 금지 (D7) — CARDS 행 onTap 추가 금지 | `tools/check_cc_no_holecard.py` CI |
| 2 | 핸드 진행 중 stack/bet 편집 차단 (Player_Edit_Modal §4) | dialog 안 disabled |
| 3 | RBAC — Viewer 는 onTap 비활성 (Player_Edit_Modal §7) | dialog 안 enabled 가드 |
| 4 | 통신 모델 보존 — 편집 결과는 `seatsProvider.notifier` 만 호출 | engine_output_dispatcher.dart 변경 0 |

## 후속 (다음 turn)

- [ ] 기획 문서 3 건 갱신 (Player_Edit_Modal / Seat_Management / Overview) — 사용자 승인 대기
- [ ] BO PATCH `/seats/{n}/player` 연동 (현재는 local seatsProvider 만)
- [ ] WebSocket `PlayerUpdated` broadcast 통합

## Changelog

| 날짜 | 변경 | 트리거 |
|------|------|--------|
| 2026-05-07 | 최초 작성 + 코드 cascade autonomous start | 사용자 지시 "이슈 발행 + 코드 자율 구현" |
