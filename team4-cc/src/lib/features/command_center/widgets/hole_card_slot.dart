// Hole card slot widget — 5-state FSM (BS-05-04 §카드 슬롯 상태머신, CCR-032).
//
// EMPTY → DETECTING → DEALT / FALLBACK / WRONG_CARD
// - DETECTING: pulse #FFD600 at 600ms interval
// - WRONG_CARD: red border #DD0000 + 400ms shake
// - FALLBACK (>5s timeout): auto-opens AT-03 Card Selector modal
//
// UI-02 변경 (2026-04-13): 카드 슬롯 탭 → 화면 3 (합성 카드 선택) 진입.
// 좌석 위젯 인라인 편집의 일부로, 카드 탭 시 CardSelectorScreen 오픈.

import 'package:flutter/material.dart';

enum HoleCardSlotState { empty, detecting, dealt, fallback, wrongCard }

class HoleCardSlot extends StatelessWidget {
  const HoleCardSlot({
    super.key,
    required this.state,
    this.onTap,
  });

  final HoleCardSlotState state;

  /// Tap to open card selector (inline edit, UI-02 §화면 1 인라인 편집).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: const Placeholder(),
      );
}
