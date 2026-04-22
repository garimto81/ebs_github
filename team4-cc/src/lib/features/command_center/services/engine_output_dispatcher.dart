// Engine outputEvents → CC provider state mapping.
//
// Overview.md §1.1.1 — CC 는 Engine HTTP 응답의 outputEvents[] 를 primary SSOT
// 로 사용. 본 dispatcher 가 event type 별로 seats/pot/handFsm provider 를 업데이트.
//
// 최소 구현 (프로토타입) — 핵심 5 이벤트:
//   HandStarted / ActionPerformed / StreetAdvanced / CardDealt / HandCompleted
// 나머지 이벤트 (21종 총) 는 B-team4-007 Phase 2 에서 확장.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../foundation/logging/debug_log.dart';
import '../../../models/enums/hand_fsm.dart';
import '../../../models/enums/seat_status.dart';
import '../providers/hand_fsm_provider.dart';
import '../providers/seat_provider.dart';

class EngineOutputDispatcher {
  EngineOutputDispatcher._();

  /// Dispatch all outputEvents from Engine response.
  ///
  /// [ref] — WidgetRef from caller (action dispatch site)
  /// [outputEvents] — JSON array from Engine `POST /api/session/:id/event`
  ///                  response (`response.data['outputEvents']`)
  /// [correlationId] — UUID from action dispatch, for trace logging
  static void dispatchAll(
    WidgetRef ref,
    List<dynamic>? outputEvents, {
    String? correlationId,
  }) {
    if (outputEvents == null || outputEvents.isEmpty) {
      DebugLog.d('ENGINE_EVT', 'empty outputEvents',
          {'correlation_id': correlationId});
      return;
    }
    DebugLog.i('ENGINE_EVT', 'dispatching ${outputEvents.length} events',
        {'correlation_id': correlationId});
    for (final raw in outputEvents) {
      if (raw is! Map) continue;
      _dispatchOne(ref, Map<String, dynamic>.from(raw), correlationId);
    }
  }

  static void _dispatchOne(
      WidgetRef ref, Map<String, dynamic> event, String? correlationId) {
    final type = event['type'] as String?;
    final payload = event['payload'] is Map
        ? Map<String, dynamic>.from(event['payload'] as Map)
        : const <String, dynamic>{};

    switch (type) {
      case 'HandStarted':
      case 'hand_started':
        _onHandStarted(ref, payload);
      case 'ActionPerformed':
      case 'action_performed':
        _onActionPerformed(ref, payload);
      case 'StreetAdvanced':
      case 'street_advanced':
        _onStreetAdvanced(ref, payload);
      case 'CardDealt':
      case 'card_dealt':
        _onCardDealt(ref, payload);
      case 'HandCompleted':
      case 'hand_completed':
      case 'HandEnded':
      case 'hand_end':
        _onHandCompleted(ref, payload);
      default:
        DebugLog.d('ENGINE_EVT', 'unhandled type=$type',
            {'correlation_id': correlationId});
    }
  }

  // ---------------------------------------------------------------------------

  static void _onHandStarted(WidgetRef ref, Map<String, dynamic> p) {
    DebugLog.i('ENGINE_EVT', 'HandStarted', p);
    ref.read(handFsmProvider.notifier).forceState(HandFsm.setupHand);
  }

  static void _onActionPerformed(WidgetRef ref, Map<String, dynamic> p) {
    final seat = (p['seat'] ?? p['seatIndex']) as int?;
    final action = p['action_type'] as String?;
    DebugLog.i('ENGINE_EVT', 'ActionPerformed',
        {'seat': seat, 'action': action, ...p});
    if (seat == null || action == null) return;

    final seatsNotifier = ref.read(seatsProvider.notifier);
    switch (action) {
      case 'fold':
        seatsNotifier.setActivity(seat, PlayerActivity.folded);
      case 'allin':
      case 'all_in':
        seatsNotifier.setActivity(seat, PlayerActivity.allIn);
      // bet/call/raise/check: seat.activity 유지, pot 은 별도 이벤트
    }
    final amount = p['amount'] as int?;
    if (amount != null && amount > 0) {
      seatsNotifier.setCurrentBet(seat, amount);
    }
  }

  static void _onStreetAdvanced(WidgetRef ref, Map<String, dynamic> p) {
    final street = (p['street'] ?? p['next']) as String?;
    DebugLog.i('ENGINE_EVT', 'StreetAdvanced', p);
    if (street == null) return;
    final fsm = ref.read(handFsmProvider.notifier);
    final target = _streetToFsm(street);
    if (target != null) {
      fsm.forceState(target);
      ref.read(seatsProvider.notifier).clearBets();
    }
  }

  static HandFsm? _streetToFsm(String street) {
    switch (street.toLowerCase()) {
      case 'flop':
        return HandFsm.flop;
      case 'turn':
        return HandFsm.turn;
      case 'river':
        return HandFsm.river;
      case 'preflop':
      case 'pre_flop':
      case 'pre-flop':
        return HandFsm.preFlop;
      case 'showdown':
        return HandFsm.showdown;
    }
    return null;
  }

  static void _onCardDealt(WidgetRef ref, Map<String, dynamic> p) {
    DebugLog.i('ENGINE_EVT', 'CardDealt', p);
    // Hole card (seat) or community (is_board)
    // Engine 응답 schema 는 Overlay_Output_Events.md 참조 — 최소 구현.
    // TODO(B-team4-007): full schema 파싱.
  }

  static void _onHandCompleted(WidgetRef ref, Map<String, dynamic> p) {
    DebugLog.i('ENGINE_EVT', 'HandCompleted', p);
    ref.read(handFsmProvider.notifier).forceState(HandFsm.handComplete);
    ref.read(seatsProvider.notifier).clearBets();
    ref.read(seatsProvider.notifier).clearAllCards();
  }
}
