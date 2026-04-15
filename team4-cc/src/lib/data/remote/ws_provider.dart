// WebSocket + REST Riverpod providers for CC (CCR-021, CCR-022).
//
// - boWsClientProvider: owns the [BoWebSocketClient] lifecycle —
//   connect on creation, disconnect on dispose.
// - wsConnectionStateProvider: mirrors [WsConnectionState] stream for UI
//   (Top Bar connection indicator).
// - Token-aware [BoApiClient] is created inside the provider scope so that
//   fetchReplayEvents (CCR-021 seq-gap replay) uses the correct JWT.
//
// Incoming event routing (_dispatchIncomingEvent) implements the consumer-
// side of the state-transition contract in
//   docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md §3.3
// Publisher-emitted event names are authoritative (measured 2026-04-15
// against team2-backend/src/websocket/cc_handler.py:44-52):
//   HandStarted, HandEnded, ActionPerformed, CardDetected, GameChanged,
//   RfidStatusChanged, OutputStatusChanged, OperatorConnected/Disconnected,
//   event_flight_summary, clock_tick, clock_level_changed, Ack.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_provider.dart';
import '../../features/command_center/providers/action_button_provider.dart';
import '../../features/command_center/providers/hand_display_provider.dart';
import '../../features/command_center/providers/hand_fsm_provider.dart';
import '../../features/command_center/providers/undo_provider.dart';
import '../../features/overlay/services/skin_consumer.dart';
import '../../foundation/audio/audio_player_provider.dart';
import '../../foundation/configs/security_delay_config.dart';
import '../../models/enums/hand_fsm.dart';
import '../../rfid/abstract/i_rfid_reader.dart';
import '../../rfid/providers/rfid_reader_provider.dart';
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
    onEvent: (payload) =>
        _dispatchIncomingEvent(<T>(p) => ref.read(p), payload),
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
// Incoming event router (§3.3 consumer contract)
// ---------------------------------------------------------------------------

/// Reader closure: same `read(provider)` semantics for both [Ref] and
/// [ProviderContainer]. Lets the dispatcher be unit-tested with a plain
/// container without pulling in a full widget tree.
typedef ProviderReadFn = T Function<T>(ProviderListenable<T> provider);

/// Test-only entry point. Production flow uses `ref.read` via
/// [boWsClientProvider].
@visibleForTesting
void dispatchIncomingEventForTest(
  ProviderContainer container,
  Map<String, dynamic> payload,
) =>
    _dispatchIncomingEvent(<T>(p) => container.read(p), payload);

/// Fires an SFX through the active AudioController. Errors are swallowed
/// so missing assets (e.g. in widget tests) never break the dispatcher.
void _fireSfx(ProviderReadFn read, SfxId? sfx) {
  if (sfx == null) return;
  // ignore: discarded_futures
  read(audioSfxPortProvider).playSfx(sfx).catchError((_) {});
}

/// Parses the wire `status` string into RfidReaderStatus. Unknown values
/// return null — caller should ignore the event.
RfidReaderStatus? _parseRfidStatus(String name) {
  switch (name) {
    case 'connected':
      return RfidReaderStatus.connected;
    case 'connecting':
      return RfidReaderStatus.connecting;
    case 'reconnecting':
      return RfidReaderStatus.reconnecting;
    case 'connectionFailed':
    case 'connection_failed':
      return RfidReaderStatus.connectionFailed;
    case 'disconnected':
      return RfidReaderStatus.disconnected;
  }
  return null;
}

/// Builds the RfidNotification payload per Manual_Fallback.md §5.5 + §5.6.
/// Returns null when the reader is `connected` (banner hidden).
RfidNotification? buildRfidNotification(RfidReaderStatus status) {
  switch (status) {
    case RfidReaderStatus.connected:
      return null;
    case RfidReaderStatus.connecting:
      return RfidNotification(
        message: 'RFID 리더 연결 중…',
        isError: false,
        timestamp: DateTime.now(),
      );
    case RfidReaderStatus.reconnecting:
      return RfidNotification(
        message: 'RFID 재연결 중 — 수동 입력으로 진행 가능',
        isError: false,
        timestamp: DateTime.now(),
      );
    case RfidReaderStatus.connectionFailed:
      return RfidNotification(
        message: 'RFID 연결 실패 — 수동 입력으로 진행하세요',
        isError: true,
        timestamp: DateTime.now(),
      );
    case RfidReaderStatus.disconnected:
      return RfidNotification(
        message: 'RFID 장애 — 수동 입력 모드',
        isError: true,
        timestamp: DateTime.now(),
      );
  }
}

/// Maps an ActionPerformed action_type to the BS-07-05 SFX catalogue.
SfxId? _sfxForAction(String actionType) {
  switch (actionType) {
    case 'fold':
      return SfxId.foldSound;
    case 'check':
      return SfxId.checkTap;
    case 'call':
      return SfxId.chipSlide;
    case 'bet':
    case 'raise':
      return SfxId.chipSlide;
    case 'allin':
      return SfxId.allInDramatic;
    default:
      return null;
  }
}

void _dispatchIncomingEvent(ProviderReadFn read, Map<String, dynamic> payload) {
  final type = payload['type'] as String? ?? '';

  switch (type) {
    // §3.3.1 HandStarted — new hand begins; phase auto-advances to PRE_FLOP.
    case 'HandStarted':
      final handNumber = payload['hand_number'] as int? ?? 0;
      read(handFsmProvider.notifier).forceState(HandFsm.preFlop);
      read(handNumberProvider.notifier).state = handNumber;
      read(potTotalProvider.notifier).state = 0;
      read(boardCardsProvider.notifier).state = const [];
      read(hasBetToMatchProvider.notifier).state = false;
      _fireSfx(read, SfxId.newHandShuffle);

    // §3.3.1 ActionPerformed — pot updated, action-on bet context derived
    // from action_type. Pre-flop seat bets update triggers hasBetToMatch.
    case 'ActionPerformed':
      final pot = payload['pot_after'] as int? ?? 0;
      final actionType = payload['action_type'] as String? ?? '';
      read(potTotalProvider.notifier).state = pot;
      if (actionType == 'bet' ||
          actionType == 'raise' ||
          actionType == 'allin') {
        read(hasBetToMatchProvider.notifier).state = true;
      }
      _fireSfx(read, _sfxForAction(actionType));

    // §3.3.1 HandEnded — phase -> HAND_COMPLETE, clear undo, reset context.
    case 'HandEnded':
      read(handFsmProvider.notifier).forceState(HandFsm.handComplete);
      read(undoStackProvider.notifier).clearOnHandComplete();
      read(hasBetToMatchProvider.notifier).state = false;
      _fireSfx(read, SfxId.potWin);

    // §3.3.4 CardDetected board branch — publishes don't emit StreetAdvanced,
    // so the CC derives street phase from cumulative community_cards count
    // (3=FLOP, 4=TURN, 5=RIVER).
    case 'CardDetected':
      final isBoard = payload['is_board'] as bool? ?? false;
      if (!isBoard) break;
      final suit = payload['suit'] as String? ?? '';
      final rank = payload['rank'] as String? ?? '';
      if (suit.isEmpty || rank.isEmpty) break;
      final current = read(boardCardsProvider);
      final next = [...current, '$rank$suit'];
      read(boardCardsProvider.notifier).state = next;
      _fireSfx(read, SfxId.cardDeal);
      switch (next.length) {
        case 3:
          read(handFsmProvider.notifier).forceState(HandFsm.flop);
          read(hasBetToMatchProvider.notifier).state = false;
        case 4:
          read(handFsmProvider.notifier).forceState(HandFsm.turn);
          read(hasBetToMatchProvider.notifier).state = false;
        case 5:
          read(handFsmProvider.notifier).forceState(HandFsm.river);
          read(hasBetToMatchProvider.notifier).state = false;
      }

    // CCR-015 skin_updated — forwards payload to SkinConsumer which
    // re-fetches the skin bundle from BO and notifies the Overlay renderer.
    case 'skin_updated':
      read(skinConsumerProvider.notifier).handleSkinUpdatedEvent(payload);

    // API-05 §5 ConfigChanged — BO pushes operator config updates, incl.
    // Security Delay (BS-07-07). Parse + publish to securityDelayConfigProvider.
    case 'ConfigChanged':
      final cfg = SecurityDelayConfig.fromConfigChanged(payload);
      read(securityDelayConfigProvider.notifier).state = cfg;

    // BS-04-03 §5.5 RfidStatusChanged — drives the AT-01 banner +
    // slot-timer fallback policy. Server pushes one of the
    // RfidReaderStatus names verbatim.
    case 'RfidStatusChanged':
      final statusName = payload['status'] as String? ?? '';
      final status = _parseRfidStatus(statusName);
      if (status != null) {
        read(rfidNotificationProvider.notifier).state =
            buildRfidNotification(status);
      }

    // §3.3.4 operational — no FSM effect on CC. Observability only.
    case 'GameChanged':
    case 'OutputStatusChanged':
      debugPrint('[WS→CC] Operational event: $type');

    // Lobby-only. CC sees Ack responses to its own commands elsewhere.
    case 'OperatorConnected':
    case 'OperatorDisconnected':
    case 'Ack':
      break;

    // Forward-compatible (§3.3 version drift): log + ignore unknown types.
    default:
      debugPrint('[WS→CC] Unknown event type (ignored): $type');
  }
}
