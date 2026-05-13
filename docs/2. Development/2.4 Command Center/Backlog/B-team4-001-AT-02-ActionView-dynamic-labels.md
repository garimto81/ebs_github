---
id: B-team4-001
title: AT-02 ActionView — CHECK↔CALL / BET↔RAISE-TO 동적 라벨 구현
backlog-status: done
source: docs/2. Development/2.4 Command Center/Backlog.md
mirror: none
close-date: 2026-05-13
---

# [B-team4-001] AT-02 ActionView — CHECK↔CALL / BET↔RAISE-TO 동적 라벨 구현

- **등록일**: 2026-04-15
- **완료일**: 2026-04-15 (기존 구현 확인으로 클로즈)
- **관련 기획**: `docs/2. Development/2.4 Command Center/Command_Center_UI/Action_Buttons.md` §8 truth table

## 결론

기능은 이미 구현·테스트되어 있었다. 별도 작업 없이 클로즈한다.

- 동적 라벨 로직: `src/lib/features/command_center/providers/action_button_provider.dart:150-151`
  ```dart
  checkCallLabel: hasBet ? 'CALL' : 'CHECK',
  betRaiseLabel:  hasBet ? 'RAISE' : 'BET',
  ```
- 8-button UI + 키패드: `src/lib/features/command_center/widgets/action_panel.dart` (507줄)
- 화면 연결: `src/lib/features/command_center/screens/at_01_main_screen.dart` 내부 `_ActionPanel`
- 단위 테스트: `src/test/providers/action_button_test.dart` §"ActionButton — dynamic labels" (L176-188)

## 부수 정리

- `src/lib/features/command_center/screens/at_02_action_view.dart` 는 12줄 `Placeholder()` 스텁이었고 어디서도 참조되지 않았다 → 삭제.
