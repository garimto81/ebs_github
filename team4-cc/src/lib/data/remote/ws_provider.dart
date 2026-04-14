// WebSocket + REST Riverpod providers for CC (CCR-021, CCR-022).
//
// - boWsClientProvider: owns the [BoWebSocketClient] lifecycle —
//   connect on creation, disconnect on dispose.
// - wsConnectionStateProvider: mirrors [WsConnectionState] stream for UI
//   (Top Bar connection indicator).
// - Token-aware [BoApiClient] is created inside the provider scope so that
//   fetchReplayEvents (CCR-021 seq-gap replay) uses the correct JWT.
//
// Incoming event routing (_dispatchIncomingEvent) forwards server pushes to:
//   HandFsmNotifier  — forceState on HandFsmUpdated
//   TableStateNotifier — forceState on TableFsmUpdated
//   hasBetToMatchProvider — updated on ActionOnUpdated
//   handNumberProvider, potTotalProvider, boardCardsProvider — display state
//   undoStackProvider — clearOnHandComplete on HandFsmUpdated(handComplete)

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_provider.dart';
import '../../features/command_center/providers/action_button_provider.dart';
import '../../features/command_center/providers/hand_display_provider.dart';
import '../../features/command_center/providers/hand_fsm_provider.dart';
import '../../features/command_center/providers/table_state_provider.dart';
import '../../features/command_center/providers/undo_provider.dart';
import '../../models/enums/hand_fsm.dart';
import '../../models/enums/table_fsm.dart';
import 'bo_api_client.dart';
import 'bo_websocket_client.dart';

// Re-export so UI only needs to import ws_provider.dart.
export 'bo_websocket_client.dart' show WsConnectionState;

// ---------------------------------------------------------------------------
// Connection state (UI-visible)
// ---------------------------------------------------------------------------

/// Reactive WebSocket connection state for Top Bar indicator.
final wsConnectionStateProvider =
    StateProvider<WsConnectionState>((ref) => WsConnectionState.disconnected);

// ---------------------------------------------------------------------------
// WebSocket client provider
// ---------------------------------------------------------------------------

/// Owns [BoWebSocketClient] lifecycle tied to [LaunchConfig].
///
/// Returns `null` when [launchConfigProvider] has not been set (pre-launch).
/// On creation: connects and starts listening.
/// On dispose: disconnects and cancels connection state subscription.
final boWsClientProvider = Provider<BoWebSocketClient?>((ref) {
  final launchConfig = ref.watch(launchConfigProvider);
  if (launchConfig == null) return null;

  // Token-aware REST client for CCR-021 seq-gap replay via real REST call.
  final apiClient = BoApiClient(
    baseUrl: launchConfig.boBaseUrl,
    token: launchConfig.token,
  );

  final client = BoWebSocketClient(
    wsUrl: launchConfig.wsUrl,
    tableId: launchConfig.tableId,
    token: launchConfig.token,
    onEvent: (payload) => _dispatchIncomingEvent(ref, payload),
    fetchReplay: apiClient.fetchReplayEvents,
  );

  // Mirror connection state changes into the Riverpod StateProvider so the
  // Top Bar indicator rebuilds automatically.
  final stateSub = client.connectionState.listen((state) {
    ref.read(wsConnectionStateProvider.notifier).state = state;
  });

  client.connect();

  ref.onDispose(() {
    stateSub.cancel();
    client.disconnect();
  });

  return client;
});

// ---------------------------------------------------------------------------
// Incoming event router
// ---------------------------------------------------------------------------

/// Routes server-pushed events to appropriate Riverpod notifiers.
///
/// Called by [BoWebSocketClient.onEvent] after seq validation and
/// gap-replay (CCR-021).
void _dispatchIncomingEvent(Ref ref, Map<String, dynamic> payload) {
  final type = payload['type'] as String? ?? '';

  switch (type) {
    // ---- Hand FSM (server-authoritative sync) --------------------------------
    case 'HandFsmUpdated':
      final next = _parseHandFsm(payload['state'] as String? ?? '');
      if (next != null) {
        ref.read(handFsmProvider.notifier).forceState(next);
        if (next == HandFsm.handComplete) {
          // Clear undo stack on hand completion (BS-05-05).
          ref.read(undoStackProvider.notifier).clearOnHandComplete();
        }
      }

    // ---- Table FSM (server-authoritative sync) -------------------------------
    case 'TableFsmUpdated':
      final next = _parseTableFsm(payload['state'] as String? ?? '');
      if (next != null) {
        ref.read(tableStateProvider.notifier).forceState(next);
      }

    // ---- Action-on seat (which player must act) ------------------------------
    case 'ActionOnUpdated':
      final hasBet = payload['has_bet'] as bool? ?? false;
      ref.read(hasBetToMatchProvider.notifier).state = hasBet;

    // ---- Board cards updated (community cards) --------------------------------
    case 'BoardUpdated':
      final cards =
          (payload['cards'] as List<dynamic>?)?.cast<String>() ?? const [];
      ref.read(boardCardsProvider.notifier).state = cards;

    // ---- Pot total updated ---------------------------------------------------
    case 'PotUpdated':
      final amount = payload['amount'] as int? ?? 0;
      ref.read(potTotalProvider.notifier).state = amount;

    // ---- Hand number updated -------------------------------------------------
    case 'HandNumberUpdated':
      final number = payload['hand_number'] as int? ?? 0;
      ref.read(handNumberProvider.notifier).state = number;

    default:
      debugPrint('[WS→CC] Unhandled event: $type');
  }
}

// ---------------------------------------------------------------------------
// Parse helpers
// ---------------------------------------------------------------------------

HandFsm? _parseHandFsm(String s) => switch (s) {
      'idle' => HandFsm.idle,
      'setup_hand' => HandFsm.setupHand,
      'pre_flop' => HandFsm.preFlop,
      'flop' => HandFsm.flop,
      'turn' => HandFsm.turn,
      'river' => HandFsm.river,
      'showdown' => HandFsm.showdown,
      'hand_complete' => HandFsm.handComplete,
      'run_it_multiple' => HandFsm.runItMultiple,
      _ => null,
    };

TableFsm? _parseTableFsm(String s) => switch (s) {
      'empty' => TableFsm.empty,
      'setup' => TableFsm.setup,
      'live' => TableFsm.live,
      'paused' => TableFsm.paused,
      'closed' => TableFsm.closed,
      'reserved_table' => TableFsm.reservedTable,
      _ => null,
    };
