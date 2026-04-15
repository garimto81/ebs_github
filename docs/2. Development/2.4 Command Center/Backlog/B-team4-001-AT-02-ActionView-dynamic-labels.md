---
id: B-team4-001
title: AT-02 ActionView — CHECK↔CALL / BET↔RAISE-TO 동적 라벨 구현
status: PENDING
source: docs/2. Development/2.4 Command Center/Backlog.md
---

# [B-team4-001] AT-02 ActionView — CHECK↔CALL / BET↔RAISE-TO 동적 라벨 구현

- **등록일**: 2026-04-15
- **관련 기획**: `docs/2. Development/2.4 Command Center/Command_Center_UI/Action_Buttons.md` §8 truth table
- **현재 상태**: `src/lib/features/command_center/at_01_main.dart` 의 AT-02 영역이 `Placeholder()` 로 남아 있음
- **수락 기준**:
  - `biggest_bet_amt == player.current_bet` → CHECK 표시 / 그 외 → CALL 표시
  - `biggest_bet_amt == 0` → BET 표시 / 그 외 → RAISE-TO 표시
  - FOLD · ALL-IN 은 항상 노출
  - Truth table 4 row × 4 button = 16 테스트 케이스 PASS
- **관련 파일**:
  - 신규: `src/lib/features/command_center/at_02_action_view/action_view.dart`
  - 신규: `src/test/features/command_center/at_02_action_view_test.dart`
  - 수정: `src/lib/features/command_center/at_01_main.dart`
