// Local event dispatcher for Demo Mode (Demo_Test_Mode.md §6).
//
// Injects events into CC providers WITHOUT a WebSocket connection.
// Reuses the same _dispatchIncomingEvent() path as production WS,
// ensuring provider state updates are identical.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/remote/ws_provider.dart' show dispatchLocalDemoEvent;
import '../../../models/enums/hand_fsm.dart';
import '../providers/hand_display_provider.dart';
import '../providers/hand_fsm_provider.dart';
import '../providers/seat_provider.dart';

/// Dispatches a raw event payload into the provider graph, exactly
/// as if it arrived over WebSocket.
void dispatchLocalEvent(
  ProviderContainer container,
  Map<String, dynamic> payload,
) {
  dispatchLocalDemoEvent(container, payload);
}

// ---------------------------------------------------------------------------
// Demo-specific helper actions (not WS events)
// ---------------------------------------------------------------------------

/// Seed demo players into seats (Demo_Test_Mode.md §1.3).
void seedDemoPlayers(ProviderContainer container) {
  final notifier = container.read(seatsProvider.notifier);

  notifier.seatPlayer(
    1,
    const PlayerInfo(id: 101, name: 'Alice', stack: 10000, countryCode: 'US'),
  );
  notifier.seatPlayer(
    4,
    const PlayerInfo(id: 102, name: 'Bob', stack: 10000, countryCode: 'KR'),
  );
  notifier.seatPlayer(
    7,
    const PlayerInfo(id: 103, name: 'Charlie', stack: 10000, countryCode: 'JP'),
  );

  // Set dealer to S1 (prerequisite for hand start).
  notifier.setDealer(1);
}

/// Reset all demo state to clean IDLE.
void resetDemoState(ProviderContainer container) {
  container.read(seatsProvider.notifier).resetAll();
  container.read(handFsmProvider.notifier).forceState(HandFsm.idle);
  container.read(potTotalProvider.notifier).state = 0;
  container.read(boardCardsProvider.notifier).state = [];
  container.read(handNumberProvider.notifier).state = 0;
}
