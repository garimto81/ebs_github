// HandFSM StateNotifier — 9-state lifecycle.
//
// 권위: docs/2. Development/2.3 Game Engine/Behavioral_Specs/Lifecycle_and_State_Machine.md §2.1 (FSM 다이어그램) + §3.3 (매트릭스 1 Hold'em 상태 상세).
// (구 BS-05-01 + BS-06-01 — 2026-04-27 Lifecycle 도메인 마스터로 통합, B-349.)
//
// State transitions:
//   idle ─→ setupHand ─→ preFlop ─→ flop ─→ turn ─→ river ─→ showdown ─→ handComplete ─→ idle
//                                                       └──→ runItMultiple ──┘
//   Any street with all-fold → handComplete directly.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/enums/hand_fsm.dart';

/// Guard-checked street order for sequential advancement.
const _streetOrder = [
  HandFsm.preFlop,
  HandFsm.flop,
  HandFsm.turn,
  HandFsm.river,
];

class HandFsmNotifier extends StateNotifier<HandFsm> {
  HandFsmNotifier() : super(HandFsm.idle);

  // ---------------------------------------------------------------------------
  // NEW HAND: idle | handComplete → setupHand
  // Guard: activePlayers ≥ 2, dealer assigned.
  // ---------------------------------------------------------------------------

  /// Whether preconditions allow starting a new hand.
  bool canStartHand({required int activePlayers, required bool dealerSet}) {
    final validState =
        state == HandFsm.idle || state == HandFsm.handComplete;
    return validState && activePlayers >= 2 && dealerSet;
  }

  /// Transition to setupHand. Caller must verify [canStartHand] first.
  void startHand() {
    assert(
      state == HandFsm.idle || state == HandFsm.handComplete,
      'startHand requires idle or handComplete, got $state',
    );
    state = HandFsm.setupHand;
  }

  // ---------------------------------------------------------------------------
  // DEAL: setupHand → preFlop
  // Guard: blinds posted.
  // ---------------------------------------------------------------------------

  bool get canDeal => state == HandFsm.setupHand;

  void deal() {
    assert(state == HandFsm.setupHand, 'deal requires setupHand, got $state');
    state = HandFsm.preFlop;
  }

  // ---------------------------------------------------------------------------
  // Street advancement: preFlop → flop → turn → river
  // Guard: board card count matches next street.
  // ---------------------------------------------------------------------------

  /// Current street index in [_streetOrder], or -1 if not on a street.
  int get _streetIndex => _streetOrder.indexOf(state);

  bool get canAdvanceStreet {
    final idx = _streetIndex;
    return idx >= 0 && idx < _streetOrder.length - 1;
  }

  /// Advance to the next street. Only valid during preFlop→flop→turn→river.
  void advanceStreet() {
    final idx = _streetIndex;
    assert(
      idx >= 0 && idx < _streetOrder.length - 1,
      'advanceStreet invalid from $state',
    );
    state = _streetOrder[idx + 1];
  }

  // ---------------------------------------------------------------------------
  // SHOWDOWN: river → showdown (activePlayers ≥ 2)
  // ---------------------------------------------------------------------------

  bool get canEnterShowdown => state == HandFsm.river;

  void enterShowdown() {
    assert(state == HandFsm.river, 'enterShowdown requires river, got $state');
    state = HandFsm.showdown;
  }

  // ---------------------------------------------------------------------------
  // RUN IT MULTIPLE: river → runItMultiple (allIn ≥ 2)
  // ---------------------------------------------------------------------------

  bool get canRunItMultiple => state == HandFsm.river;

  void runItMultiple() {
    assert(
      state == HandFsm.river,
      'runItMultiple requires river, got $state',
    );
    state = HandFsm.runItMultiple;
  }

  // ---------------------------------------------------------------------------
  // HAND COMPLETE: showdown | runItMultiple | any street (all fold) → handComplete
  // ---------------------------------------------------------------------------

  bool get canCompleteHand {
    return state == HandFsm.showdown ||
        state == HandFsm.runItMultiple ||
        _streetIndex >= 0; // any street — all-fold scenario
  }

  void completeHand() {
    assert(canCompleteHand, 'completeHand invalid from $state');
    state = HandFsm.handComplete;
  }

  // ---------------------------------------------------------------------------
  // RESET: handComplete → idle
  // ---------------------------------------------------------------------------

  void reset() {
    assert(
      state == HandFsm.handComplete,
      'reset requires handComplete, got $state',
    );
    state = HandFsm.idle;
  }

  // ---------------------------------------------------------------------------
  // Force set (server sync / reconnect replay)
  // ---------------------------------------------------------------------------

  /// Overwrite FSM state unconditionally (server-authoritative sync).
  void forceState(HandFsm next) => state = next;
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final handFsmProvider = StateNotifierProvider<HandFsmNotifier, HandFsm>(
  (ref) => HandFsmNotifier(),
);
