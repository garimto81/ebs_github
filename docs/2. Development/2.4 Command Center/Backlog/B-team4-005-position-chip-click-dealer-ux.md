---
id: B-team4-005
title: 포지션 뱃지 클릭 → 포지션 재지정 메뉴 UX 구현 (Seat_Management.md §2 준수)
status: PENDING
source: docs/2. Development/2.4 Command Center/Backlog.md
---

# [B-team4-005] 포지션 뱃지 클릭 → 포지션 재지정 UX 구현

- **등록일**: 2026-04-21
- **기획 SSOT**: `docs/2. Development/2.4 Command Center/Command_Center_UI/Seat_Management.md` §2 (line 86)
- **Type 분류**: Type D (기획 있음 + 구현 미완) — Type B (기획 공백) 아님

## 배경

2026-04-21 NEW HAND 작동 안 함 사용자 제보 → debug log 로 root cause 확정:
`canStartHand=false — no dealer assigned`.

임시 fix commit `3bb1c26` 에서 Long-press context menu 에 "Set Dealer" 메뉴를 **자의적으로** 추가했으나, 이는 **기획 위반**:

### 기획 실제 명세 (Seat_Management.md)

| Line | 내용 |
|:---:|------|
| 86 | "**포지션 뱃지**: 포지션 재지정 메뉴 (IDLE에서만)" |
| 87 | "좌석 전체 롱프레스: 컨텍스트 메뉴: Move/Swap/Remove/Sit Out" (Set Dealer 없음) |
| 163-167 | Context menu 3 항목: Move to Seat / Swap with Seat / Remove from Seat |
| 217 | "딜러 버튼 자동 이동 (다음 좌석)" — 핸드 진행 중 자동 전진 |
| 280 | 포지션 뱃지 시각: Dealer 🔴 빨간 원 + "D" |

**기획 설계 의도**: 초기 dealer 설정은 **포지션 뱃지 클릭 → IDLE 에서만 재지정 가능**. 이후 핸드 완료 시 자동 이동.

### 제 위반 (rolled back at commit `???`)

- Long-press context menu 에 "Set Dealer" 항목 자의적 추가 (기획 87 line 위반)
- SnackBar 에 "Long-press → Set Dealer" 잘못된 가이드 제시

## 구현 요구사항

`seat_cell.dart` 의 `_buildOccupiedSeat` 또는 `_buildPositionChip` 위치:

1. **포지션 뱃지 (BTN/SB/BB 원) 를 GestureDetector 로 래핑**
2. **IDLE 상태에서만 tap 가능** (Hand FSM != idle/handComplete 면 disabled)
3. Tap 시 모달 표시:
   - Dealer 를 이 좌석에 지정
   - Cancel
4. 확인 시 `seatsProvider.notifier.setDealer(seatNo)` 호출
5. 핸드 진행 중 클릭 시 "핸드 중에는 변경 불가" 경고 (기획 §3 "핸드 중 제한" 준수)

## 추가 검토 사항 (기획 보강 후보)

### ✅ 해소됨 (2026-04-21) — Seat_Management.md §2.3 신설

초기 딜러 배정 공백 해소. 채택 결정:

- **§2.3.1 자동 배정**: 첫 플레이어 착석 시 해당 좌석 auto BTN (옵션 A 채택)
- **§2.3.2 수동 재지정**: 포지션 뱃지 클릭 → IDLE-only 재지정 다이얼로그 (line 86 직접 구현)
- **§2.3.3 자동 전진**: 핸드 완료 시 auto-rotate (기존 line 217 재수록 + skip + Heads-up)
- **§2.3.4 Edge Cases**: 5 건 (vacate, move, sit-out, all-vacant, self-redirect)
- **§2.3.5 Scope 제외**: Dead button / missed blinds / 이동 애니메이션 = Phase 2
- **§2.3.6 WSOP LIVE divergence**: Staff App dealer UX 없음 확인, EBS 고유 justify

옵션 B (빈 좌석 click → "Set as Dealer") 는 포커 규약 위반 (플레이어 없는 좌석에 BTN 금지) 으로 제외. 옵션 C (별도 UI) 는 프로토타입 오버엔지니어링으로 제외.

### critic 반박 5 반영

"Heads-up 렌더링 책임 불명확" 반박에 대응하여 §2.3.3 에 한 줄 cross-ref 추가:
> CC UI 는 `dealerSeatProvider` 만 시각화, 포커 규약 연산은 Game Engine 책임.

## 완료 기준

- [ ] 포지션 뱃지 클릭 시 "포지션 재지정" 모달 노출 (IDLE only)
- [ ] 재지정 모달에서 현재 이 좌석에 dealer 배정 가능
- [ ] 핸드 중 클릭 시 차단 경고 (Seat_Management.md §3)
- [ ] 기획 Seat_Management.md 의 "초기 딜러 배정" 공백 해소 (별도 critic + 기획 보강)
- [ ] SnackBar 메시지가 이 경로를 정확히 안내

## 참조

- 기획 SSOT: `docs/2. Development/2.4 Command Center/Command_Center_UI/Seat_Management.md` §2 (좌석 상세 편집)
- 코드 target: `team4-cc/src/lib/features/command_center/widgets/seat_cell.dart` `_positionLabel`, `_buildOccupiedSeat`
- Revert 대상 commit: `3bb1c26` (seat_cell.dart Set Dealer 메뉴 자의적 추가)
- MEMORY 원칙: `project_intent_spec_validation`, `feedback_prototype_failure_as_spec_signal`
