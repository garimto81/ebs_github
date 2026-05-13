---
id: B-team4-011
title: "CC Visual Uplift — React 프로토타입 시각 자산 7종 흡수 (D7 보안 유지)"
backlog-status: open
source: docs/2. Development/2.4 Command Center/Backlog.md
created: 2026-05-06
owner: team4
appetite: Small (~3-5d, 5 위젯 신설 + 1 위젯 보강)
related_archive: claude-design-archive/2026-05-06/
related_critic: docs/4. Operations/CC_Design_Prototype_Critic_2026_05_06.md
related_specs:
  - docs/2. Development/2.4 Command Center/Command_Center_UI/UI.md  # §Visual Uplift
  - docs/2. Development/2.4 Command Center/Command_Center_UI/Keyboard_Shortcuts.md  # §5
  - docs/2. Development/2.4 Command Center/Command_Center_UI/Seat_Management.md  # §8
  - docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md  # §12 Widget Inventory
mirror: none
---

# B-team4-011 — CC Visual Uplift

## 배경

2026-05-05 디자인팀이 전달한 React 프로토타입 (`claude-design/EBS Command Center (2).zip`) 을 Conductor 가 critic 판정한 결과:

- **production 부적격** (D7 위반 + CDN 의존 + 통신 모델 부재)
- **시각 디자인은 우월** (Flutter CC 보다 정보 밀도 / 인라인 편집 UX / 미니맵 / 키보드 힌트 시각화 우위)

Flutter CC 가 시각 자산 7종을 흡수하면 production-ready 인 동시에 시각적으로도 디자인 시안 수준 도달 가능.

## 수락 기준

7개 시각 자산을 Flutter CC 에 흡수하되, 다음 가드레일 절대 준수:

### 가드레일 (HARD)

| # | 가드 | 검증 |
|:-:|------|------|
| 1 | hole card 값 노출 금지 (D7) — face-down 만 표시 | `tools/check_cc_no_holecard.py` CI 통과 |
| 2 | CDN 의존 도입 금지 — 모든 자산은 Flutter assets/ 또는 packages/ 로 자족 | `pubspec.yaml` review |
| 3 | 통신 모델 변경 금지 — WS / Engine HTTP / correlation_id 흐름 그대로 유지 | `engine_output_dispatcher.dart` 변경 없음 확인 |
| 4 | HandFSM 9-state 전이 룰 변경 금지 | `hand_fsm_provider.dart` test 통과 |

### 13개 흡수 항목 (2026-05-06 시각 검토 후 V8~V13 추가)

| ID | 위젯 / 변경 | 신규/보강 | 예상 줄수 |
|:--:|------------|:--------:|:--------:|
| V1 | `keyboard_hint_bar.dart` (F/C/B/A/N/M 칩) | 신규 | ~140 ✅ |
| V2 | `cc_status_bar.dart` (BO/RFID/Engine 통합 한 줄) + V10 결합 | 신규 | ~180 |
| V3 | `mini_table_diagram.dart` (좌측 상단 미니 oval) + R2 가드 | 신규 | ~220 |
| V4 | `position_shift_chip.dart` (D/SB/BB/STR ‹ ›) | 신규 | ~120 |
| V5 | `seat_cell.dart` 7행 + V11/V12 결합 (acting strip / country / 베팅 칩 / + ADD) | 보강 | ~280 |
| V6 | ACTING 펄스 글로우 + V9 결합 (명시 박스) | 보강 | ~80 |
| V7 | `tweaks_panel.dart` (debug 모드 hue/옵션 조절) | 신규 | ~180 |
| **V8** | **FLOP 1·2·3 / TURN / RIVER 슬롯 라벨** (community board 강화) | 보강 | ~40 |
| **V9** | **ACTING 우측 명시 박스** ("S8 · Choi · Stack $5,750") | V6 일부 | (V6 포함) |
| **V10** | **POT 좌상단 강조 박스** (V2/V3 영역과 결합) | V2/V3 일부 | (V2/V3 포함) |
| **V11** | **베팅 칩 부유 시각** (좌석 위 $ 칩) | V5 일부 | (V5 포함) |
| **V12** | **카드 슬롯 + ADD affordance** | V5 일부 | (V5 포함) |
| **V13** | **IDLE 시 액션 disabled visual hint** (현 Flutter 정합 확인) | — | 0 (확인만) |

**합계**: ~1,240 줄 — Adaptive Conductor 기준 **full PDCA** (200줄+ 카테고리)

### 거절 / 보류 항목 (R1~R3)

| ID | 시안 패턴 | 판정 | 이유 |
|:--:|----------|:----:|------|
| R1 | layout 스위처 (Bottom/Left/Right) | **거절** | 1 CC = 1 운영자 가정 |
| R2 | SB·BB 이중 표시 (미니맵 + 좌석) | **V3 가드** | 단일 source 정책 명문화 |
| R3 | CardPicker 의 face-up 임의 선택 | **D7 강제 거절** | Flutter 는 RFID 또는 Manual_Card_Input 폴백만 |

## 진행 단계 (자율)

| Phase | 작업 | 트리거 |
|:-----:|------|--------|
| A | archive + Backlog 등재 | ✅ 2026-05-06 (이 turn 완료) |
| B | V1 (keyboard_hint_bar) — 가장 단순, 가치 명확 | 후속 turn |
| C | V2 (cc_status_bar) — 통합 status, 분산된 banner 정리 | 후속 turn |
| D | V3 (mini_table_diagram) + V4 (position_shift_chip) — CustomPaint 기반 | 후속 turn |
| E | V5 (seat_cell 7행 보강) — 가장 큰 변경, executor 위임 권장 | 후속 turn |
| F | V6 (glow) + V7 (tweaks_panel) — polish | 후속 turn |
| G | screenshot diff + critic verify | 모든 V* 완료 후 |

## 영향 범위

| 영역 | 영향 |
|------|------|
| 코드 | `team4-cc/src/lib/features/command_center/widgets/` (5 신규 + 2 보강) |
| 문서 | `docs/2. Development/2.4 Command Center/Command_Center_UI/` (위젯 명세 보강) |
| 테스트 | widget test 7개 신규 |
| Overlay | 변경 없음 (CC 시각만, 송출 데이터 동일) |
| 통신 | 변경 없음 (WS / Engine HTTP 흐름 보존) |

## 참조

| 문서 | 링크 |
|------|------|
| **Critic 분석 SSOT** | `docs/4. Operations/CC_Design_Prototype_Critic_2026_05_06.md` |
| **시각 명세 SSOT** | `Command_Center_UI/UI.md §Visual Uplift` |
| **단축키 시각 정책** | `Command_Center_UI/Keyboard_Shortcuts.md §5 KeyboardHintBar` |
| **좌석 7행 + Position Shift** | `Command_Center_UI/Seat_Management.md §8 Visual Uplift` |
| **위젯 인벤토리** | `Command_Center_UI/Overview.md §12 Widget Inventory` |
| Archive | `claude-design-archive/2026-05-06/README.md` |
| 기존 seat_cell | `team4-cc/src/lib/features/command_center/widgets/seat_cell.dart` |
| 기존 main screen | `team4-cc/src/lib/features/command_center/screens/at_01_main_screen.dart` |
| D7 정책 SSOT | Foundation.md §5.4 + IMPL-007 + `tools/check_cc_no_holecard.py` |

## 금지

- React 코드 (.jsx) 직접 이식 시도 금지 — 시각 reference 만
- D7 우회 시도 (운영자에게 카드 미리 보여주는 어떤 형태든) 금지
- CDN 도입 (Inter 폰트 등) 금지 — Flutter assets/ 로 번들
- 본 항목을 5개 이상 PR 로 쪼개지 말 것 (V1-V7 묶음 흐름이 self-consistent — V5 가 V2 의 status bar 와 시각 어울림 검증 필요)
