// Shared test fixtures. Keep realistic-shape payloads here so unit +
// widget + integration tests use the same canonical data.

/// Representative GFSkin manifest that passes DATA-07 validation.
Map<String, dynamic> validGfskinManifest() => {
      'skin_name': 'WSOP 2026 Default',
      'version': '1.0.0',
      'resolution': {'width': 1920, 'height': 1080},
      'colors': {
        'background': '#000000',
        'text_primary': '#FFFFFF',
        'text_secondary': '#B0B0B0',
        'badge_check': '#2E7D32',
        'badge_fold': '#616161',
        'badge_bet': '#1976D2',
        'badge_call': '#0288D1',
        'badge_allin': '#E53935',
      },
      'fonts': {
        'title': {'family': 'Roboto', 'size': 24},
        'body': {'family': 'Inter', 'size': 14},
      },
    };

/// Representative WebSocket HandStarted envelope (publisher §3.1 shape).
Map<String, dynamic> handStartedEvent({
  int handId = 42,
  int handNumber = 15,
  int dealerSeat = 3,
}) =>
    {
      'type': 'HandStarted',
      'hand_id': handId,
      'hand_number': handNumber,
      'dealer_seat': dealerSeat,
      'player_count': 6,
      'blind_level': {'level': 5, 'sb': 200, 'bb': 400, 'ante': 50},
      'game': 'holdem',
      'bet_structure': 'no_limit',
    };

/// Representative ActionPerformed envelope (publisher §3.2 shape).
Map<String, dynamic> actionPerformedEvent({
  required String actionType,
  int seat = 5,
  int amount = 500,
  int potAfter = 1200,
  int stackAfter = 8500,
}) =>
    {
      'type': 'ActionPerformed',
      'hand_id': 42,
      'seat': seat,
      'action_type': actionType,
      'amount': amount,
      'pot_after': potAfter,
      'stack_after': stackAfter,
      'game_phase': 2,
      'action_index': 3,
    };

Map<String, dynamic> handEndedEvent({int handId = 42}) => {
      'type': 'HandEnded',
      'hand_id': handId,
      'winner_seats': [5],
      'pot_total': 1200,
      'duration_ms': 45000,
    };

Map<String, dynamic> cardDetectedEvent({
  required String rank,
  required String suit,
  bool isBoard = true,
  int? seat,
}) =>
    {
      'type': 'CardDetected',
      'hand_id': 42,
      'seat': seat,
      'suit': suit,
      'rank': rank,
      'is_board': isBoard,
      'position': isBoard ? 'flop' : 'hole',
    };

Map<String, dynamic> configChangedPayload({
  bool enabled = true,
  int delaySeconds = 30,
  bool holecardsOnly = false,
}) =>
    {
      'type': 'ConfigChanged',
      'security_delay': {
        'enabled': enabled,
        'delay_seconds': delaySeconds,
        'holecards_only': holecardsOnly,
      },
    };

/// 52-card deck with deterministic UIDs — used by RFID register tests.
List<Map<String, String>> fullDeckRegistration() {
  const suits = ['s', 'h', 'd', 'c'];
  const ranks = [
    'A', 'K', 'Q', 'J', 'T', '9', '8', '7', '6', '5', '4', '3', '2',
  ];
  final out = <Map<String, String>>[];
  for (final s in suits) {
    for (final r in ranks) {
      out.add({'uid': 'UID-$r$s', 'rank': r, 'suit': s});
    }
  }
  return out;
}

/// Representative Statistics GET response (§6.3 of Statistics.md).
Map<String, dynamic> statisticsSnapshot() => {
      'table_id': 5,
      'hand_number': 248,
      'session_hands': 40,
      'total_hands': 1500,
      'avg_pot': 3450,
      'players': [
        {
          'seat_no': 1,
          'player_id': 'p_0042',
          'name': 'Alice',
          'vpip': 0.24,
          'pfr': 0.18,
          'three_bet': 0.07,
          'af': 2.1,
          'hands_played': 248,
          'wtsd': 0.31,
        },
        {
          'seat_no': 2,
          'player_id': 'p_0043',
          'name': 'Bob',
          'vpip': null,
          'pfr': null,
          'three_bet': null,
          'af': null,
          'hands_played': 12,
          'wtsd': null,
        },
      ],
    };
