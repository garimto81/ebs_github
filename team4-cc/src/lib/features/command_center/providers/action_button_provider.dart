// Action button state provider (BS-05-02, CCR-031).
//
// Computes enabled/disabled for each CC action based on
// HandFSM x TableFSM matrix. Labels switch dynamically:
//   CHECK <-> CALL (based on biggest_bet > 0)
//   BET <-> RAISE-TO (based on whether a bet already exists)

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/enums/hand_fsm.dart';
import '../../../models/enums/table_fsm.dart';
import 'hand_fsm_provider.dart';
import 'table_state_provider.dart';

// ---------------------------------------------------------------------------
// CC action enum (UI-level, not game engine ActionType)
// ---------------------------------------------------------------------------

/// Actions available on the CC action panel (BS-05-02).
enum CcAction {
  newHand,
  deal,
  fold,
  checkCall,
  betRaise,
  allIn,
  undo,
  missDeal,
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ActionButtonState {
  const ActionButtonState({
    this.enabled = const {},
    this.checkCallLabel = 'CHECK',
    this.betRaiseLabel = 'BET',
  });

  /// Which actions are currently enabled.
  final Map<CcAction, bool> enabled;

  /// Dynamic label: 'CHECK' when no bet to match, 'CALL' otherwise.
  final String checkCallLabel;

  /// Dynamic label: 'BET' when opening, 'RAISE' when facing a bet.
  final String betRaiseLabel;

  bool isEnabled(CcAction action) => enabled[action] ?? false;
}

// ---------------------------------------------------------------------------
// Betting context (injected from outside)
// ---------------------------------------------------------------------------

/// Whether the current biggest bet is > 0 (determines CHECK vs CALL).
final hasBetToMatchProvider = StateProvider<bool>((ref) => false);

/// Whether action_on response has been received from engine.
final actionOnReceivedProvider = StateProvider<bool>((ref) => false);

// ---------------------------------------------------------------------------
// Derived provider — HandFSM x Button activation matrix (BS-05-02 Matrix 1)
// ---------------------------------------------------------------------------

final actionButtonProvider = Provider<ActionButtonState>((ref) {
  final handFsm = ref.watch(handFsmProvider);
  final tableFsm = ref.watch(tableStateProvider);
  final hasBet = ref.watch(hasBetToMatchProvider);

  // Table must be LIVE for any action.
  if (tableFsm != TableFsm.live) {
    return const ActionButtonState(
      enabled: {
        CcAction.newHand: false,
        CcAction.deal: false,
        CcAction.fold: false,
        CcAction.checkCall: false,
        CcAction.betRaise: false,
        CcAction.allIn: false,
        CcAction.undo: false,
        CcAction.missDeal: false,
      },
    );
  }

  // HandFSM x Button matrix.
  final Map<CcAction, bool> enabled;

  switch (handFsm) {
    case HandFsm.idle:
    case HandFsm.handComplete:
      enabled = {
        CcAction.newHand: true,
        CcAction.deal: false,
        CcAction.fold: false,
        CcAction.checkCall: false,
        CcAction.betRaise: false,
        CcAction.allIn: false,
        CcAction.undo: false,
        CcAction.missDeal: false,
      };

    case HandFsm.setupHand:
      enabled = {
        CcAction.newHand: false,
        CcAction.deal: true,
        CcAction.fold: false,
        CcAction.checkCall: false,
        CcAction.betRaise: false,
        CcAction.allIn: false,
        CcAction.undo: true, // can undo setup
        CcAction.missDeal: false,
      };

    case HandFsm.preFlop:
    case HandFsm.flop:
    case HandFsm.turn:
    case HandFsm.river:
      enabled = {
        CcAction.newHand: false,
        CcAction.deal: false,
        CcAction.fold: true,
        CcAction.checkCall: true,
        CcAction.betRaise: true,
        CcAction.allIn: true,
        CcAction.undo: true,
        CcAction.missDeal: true,
      };

    case HandFsm.showdown:
    case HandFsm.runItMultiple:
      // Engine-driven — no operator actions.
      enabled = {
        CcAction.newHand: false,
        CcAction.deal: false,
        CcAction.fold: false,
        CcAction.checkCall: false,
        CcAction.betRaise: false,
        CcAction.allIn: false,
        CcAction.undo: false,
        CcAction.missDeal: false,
      };
  }

  return ActionButtonState(
    enabled: enabled,
    checkCallLabel: hasBet ? 'CALL' : 'CHECK',
    betRaiseLabel: hasBet ? 'RAISE' : 'BET',
  );
});
