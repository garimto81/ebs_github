// Engine state response → CC provider state mapping.
//
// 2026-04-22 재작성: 실제 Engine Harness (team3 bin/harness.dart) 응답은
// OutputEvent 배열이 아닌 **full state snapshot** (seats[]/community/pot/
// actionOn/street/legalActions 등). 따라서 event dispatch 방식이 아니라
// **state-diff 덮어쓰기** 방식으로 provider 업데이트.
//
// Overview.md §1.1.1 SSOT = Engine 응답 — 본 dispatcher 가 그 응답을 그대로
// CC provider 에 반영.
//
// Engine 응답 schema (확인됨):
//   sessionId, variant, street (preflop/flop/turn/river/showdown),
//   seats[{index, label, stack, currentBet, status, holeCards[], isDealer}],
//   community[], pot{main, total, sides[]}, actionOn, dealerSeat,
//   legalActions[], handNumber, eventCount, cursor, log[]

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../foundation/logging/debug_log.dart';
import '../../../models/enums/hand_fsm.dart';
import '../../../models/enums/seat_status.dart';
import '../providers/hand_display_provider.dart';
import '../providers/hand_fsm_provider.dart';
import '../providers/seat_provider.dart';

class EngineOutputDispatcher {
  EngineOutputDispatcher._();

  /// Dispatch Engine state snapshot to CC providers.
  ///
  /// [state] — Engine HTTP response body (POST /api/session or /event).
  /// [correlationId] — UUID for trace logging.
  static void dispatchState(
    WidgetRef ref,
    Map<String, dynamic> state, {
    String? correlationId,
  }) {
    DebugLog.i('ENGINE_STATE', 'dispatching state snapshot', {
      'correlation_id': correlationId,
      'street': state['street'],
      'actionOn': state['actionOn'],
      'eventCount': state['eventCount'],
    });

    _updateStreet(ref, state['street'] as String?);
    _updateSeats(ref, state['seats'] as List<dynamic>?);
    _updateCommunity(ref, state['community'] as List<dynamic>?);
    _updatePot(ref, state['pot']);
    _updateActionOn(ref, state['actionOn'] as int?);
    _updateDealer(ref, state['dealerSeat'] as int?);
  }

  // ---------------------------------------------------------------------------

  static void _updateStreet(WidgetRef ref, String? street) {
    if (street == null) return;
    final fsm = _streetToFsm(street);
    if (fsm == null) return;
    ref.read(handFsmProvider.notifier).forceState(fsm);
  }

  static HandFsm? _streetToFsm(String street) {
    switch (street.toLowerCase()) {
      case 'preflop':
      case 'pre_flop':
        return HandFsm.preFlop;
      case 'flop':
        return HandFsm.flop;
      case 'turn':
        return HandFsm.turn;
      case 'river':
        return HandFsm.river;
      case 'showdown':
        return HandFsm.showdown;
      case 'complete':
      case 'handcomplete':
      case 'hand_complete':
        return HandFsm.handComplete;
    }
    return null;
  }

  static void _updateSeats(WidgetRef ref, List<dynamic>? seats) {
    if (seats == null) return;
    final notifier = ref.read(seatsProvider.notifier);

    for (final raw in seats) {
      if (raw is! Map) continue;
      final seat = Map<String, dynamic>.from(raw);
      final index = seat['index'] as int?;
      if (index == null) continue;
      final seatNo = index + 1; // Engine 0-based → CC 1-based

      // status
      final status = seat['status'] as String?;
      final activity = _statusToActivity(status);
      if (activity != null) {
        notifier.setActivity(seatNo, activity);
      }

      // currentBet
      final currentBet = seat['currentBet'] as int?;
      if (currentBet != null) {
        notifier.setCurrentBet(seatNo, currentBet);
      }

      // stack
      final stack = seat['stack'] as int?;
      if (stack != null) {
        notifier.updateStack(seatNo, stack);
      }

      // holeCards (Engine: ["7c","Qc"] → CC: [HoleCard(rank:"7",suit:"c"), ...])
      final holeRaw = seat['holeCards'];
      if (holeRaw is List) {
        final cards = <HoleCard>[];
        for (final c in holeRaw) {
          if (c is! String || c.length != 2) continue;
          cards.add(HoleCard(rank: c[0], suit: c[1]));
        }
        if (cards.isNotEmpty) {
          notifier.setHoleCards(seatNo, cards);
        }
      }
    }
  }

  static PlayerActivity? _statusToActivity(String? status) {
    switch (status) {
      case 'active':
        return PlayerActivity.active;
      case 'folded':
        return PlayerActivity.folded;
      case 'allin':
      case 'all_in':
        return PlayerActivity.allIn;
      case 'sitting_out':
      case 'sittingOut':
        return PlayerActivity.sittingOut;
    }
    return null;
  }

  static void _updateCommunity(WidgetRef ref, List<dynamic>? community) {
    if (community == null) return;
    final cards = community.whereType<String>().toList();
    ref.read(boardCardsProvider.notifier).state = cards;
  }

  static void _updatePot(WidgetRef ref, dynamic pot) {
    if (pot is! Map) return;
    final total = pot['total'] as int?;
    if (total != null) {
      ref.read(potTotalProvider.notifier).state = total;
    }
  }

  static void _updateActionOn(WidgetRef ref, int? actionOn) {
    if (actionOn == null) {
      ref.read(seatsProvider.notifier).setActionOn(null);
      return;
    }
    final seatNo = actionOn + 1; // 0-based → 1-based
    ref.read(seatsProvider.notifier).setActionOn(seatNo);
  }

  static void _updateDealer(WidgetRef ref, int? dealerSeat) {
    if (dealerSeat == null) return;
    final seatNo = dealerSeat + 1;
    ref.read(seatsProvider.notifier).setDealer(seatNo);
  }
}
