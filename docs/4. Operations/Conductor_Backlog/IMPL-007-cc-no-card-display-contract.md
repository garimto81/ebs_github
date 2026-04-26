---
id: IMPL-007
title: "구현: CC 카드 비노출 계약 강화 (회의 D7 후속)"
type: implementation
status: DONE
owner: team4
created: 2026-04-26
resolved: 2026-04-26
spec_ready: true
blocking_spec_gaps: []
implements_chapters:
  - docs/1. Product/Foundation.md §5.4 (Command Center)
  - docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md §5.1
related_code:
  - team4-cc/src/lib/features/command_center/widgets/seat_cell.dart  (line 500-501 + 536-577 변경)
  - tools/check_cc_no_holecard.py  (신규 CI 가드)
---

# IMPL-007 — CC 카드 비노출 계약 강화 (DONE 2026-04-26)

> ✅ **DONE** — Conductor 직접 구현 완료. 사용자 지시 "프로토타입 완성 = 기획서 완결".

## 배경

회의 2026-04-22 D7 결정: **Command Center 화면에 플레이어의 핸드 카드(hole cards) 비노출**. Foundation L275 + Command_Center_UI 에 이미 원칙 명시되어 있으나, 코드 레벨 강제가 부족.

운영자(딜러)가 CC 를 통해 액션을 입력하지만, hole cards 정보가 화면에 노출되면 운영자가 게임 결과를 미리 알게 되어 부정행위 위험. 따라서 **CC 화면 컴포넌트에서 hole_cards 데이터 binding 자체가 금지** 되어야 한다.

## 구현 대상

### 1. UI 레이어 — hole_cards binding 차단

`team4-cc/src/lib/features/command_center/`:
- 위젯 트리에서 `hole_cards` / `card_value` / `card_rank` 필드 참조 grep → 0 hits 보장
- Riverpod provider 가 hole_cards 를 export 하지 않도록 차단
- 설계상 community cards (flop/turn/river) 는 표시 가능 (공개 정보)

### 2. 데이터 레이어 — provider 격리

| Provider | 노출 | 비노출 |
|----------|------|--------|
| `tableStateProvider` (CC 전용) | seats, community_cards, pot, current_action | hole_cards |
| `overlayStateProvider` (Overlay 전용) | 모두 (송출 그래픽) | — |

### 3. 정적 분석 가드

`tools/check_cc_no_holecard.py` 신설 — CI 에서 CC 코드 grep 자동 검사:
```bash
python tools/check_cc_no_holecard.py team4-cc/src/lib/features/command_center/
# fail if "hole_cards" or "card_value" appears outside of /tests/
```

### 4. 문서 강화

`Command_Center_UI/Overview.md` 에 "CC 비노출 정보" 명시 표 추가 + Foundation §5.4 cross-ref.

## 수락 기준 (2026-04-26 검증)

- [x] CC widget 트리에서 hole card 값 (rank/suit) 렌더링 제거 — `seat_cell.dart` `_buildHoleCards`/`_buildMiniCard`/`_suitDisplay` 제거
- [x] 분배 여부는 face-down `?` 표시 (`_buildHoleCardBack`) — 운영자가 분배 진행 인지 가능
- [x] 데이터 layer (seat_provider.holeCards) 보존 — Overlay 송출용
- [x] CI 가드 `tools/check_cc_no_holecard.py` 신설 — exit 0 PASS
- [x] Command_Center_UI/Overview.md §5.1 D7 계약 섹션 신설
- [x] dart analyze seat_cell.dart 0 신규 issue (기존 pre-existing 14 이슈 무관)
- [ ] team4: integration test — CC 화면 렌더 후 hole_cards 텍스트 부재 검증 (후속)

## 구현 메모

- Overlay 와 CC 가 같은 Flutter 코드베이스를 공유하므로 provider 격리가 핵심
- 기존 stub_engine 이 hole_cards 를 dispatch 하면 CC 진입 시 필터링 필요
- 회의 D7 의도는 운영자 부정 방지, 따라서 디버그 모드에서도 노출 금지 (조건 분기 없음)
