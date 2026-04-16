// Built-in demo scenarios (Demo_Test_Mode.md §3).
//
// Each scenario is a sequence of WS-format event payloads that can be
// injected via local_dispatcher to drive the CC through a complete
// game flow without RFID or WebSocket.

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class DemoScenario {
  const DemoScenario({
    required this.name,
    required this.description,
    required this.events,
  });

  final String name;
  final String description;
  final List<DemoEvent> events;
}

class DemoEvent {
  const DemoEvent({
    required this.type,
    required this.payload,
    this.delay = const Duration(milliseconds: 500),
    this.uiHint,
  });

  final String type;
  final Map<String, dynamic> payload;
  final Duration delay;
  final String? uiHint;
}

// ---------------------------------------------------------------------------
// Built-in scenarios (§3.1)
// ---------------------------------------------------------------------------

final builtInScenarios = <DemoScenario>[
  quickHand,
  allInPreflop,
  fullStreet,
  missDeal,
  rfidFallback,
  multiAction,
];

/// Quick Hand — 3-player NL Holdem, fold→call→check to showdown.
final quickHand = DemoScenario(
  name: 'Quick Hand',
  description: '3인 NL 홀덤 기본. fold→call→showdown',
  events: [
    const DemoEvent(
      type: 'HandStarted',
      payload: {'type': 'HandStarted', 'hand_id': 1, 'hand_number': 1, 'dealer_seat': 1},
      uiHint: 'Hand #1 시작, 딜러 S1',
    ),
    const DemoEvent(
      type: 'ActionPerformed',
      payload: {'type': 'ActionPerformed', 'seat': 4, 'action_type': 'fold', 'amount': 0, 'pot_after': 150},
      uiHint: 'S4 (Bob) fold',
    ),
    const DemoEvent(
      type: 'ActionPerformed',
      payload: {'type': 'ActionPerformed', 'seat': 7, 'action_type': 'call', 'amount': 100, 'pot_after': 250},
      uiHint: 'S7 (Charlie) call 100',
    ),
    const DemoEvent(
      type: 'ActionPerformed',
      payload: {'type': 'ActionPerformed', 'seat': 1, 'action_type': 'check', 'amount': 0, 'pot_after': 250},
      uiHint: 'S1 (Alice) check',
    ),
    // Flop: Ah Ks 7d
    const DemoEvent(
      type: 'CardDetected',
      payload: {'type': 'CardDetected', 'is_board': true, 'suit': 'h', 'rank': 'A'},
      uiHint: 'Flop 1: A♥',
    ),
    const DemoEvent(
      type: 'CardDetected',
      payload: {'type': 'CardDetected', 'is_board': true, 'suit': 's', 'rank': 'K'},
      uiHint: 'Flop 2: K♠',
    ),
    const DemoEvent(
      type: 'CardDetected',
      payload: {'type': 'CardDetected', 'is_board': true, 'suit': 'd', 'rank': '7'},
      uiHint: 'Flop 3: 7♦ → FLOP',
    ),
    // Post-flop check-check
    const DemoEvent(
      type: 'ActionPerformed',
      payload: {'type': 'ActionPerformed', 'seat': 1, 'action_type': 'check', 'amount': 0, 'pot_after': 250},
      uiHint: 'S1 check',
    ),
    const DemoEvent(
      type: 'ActionPerformed',
      payload: {'type': 'ActionPerformed', 'seat': 7, 'action_type': 'check', 'amount': 0, 'pot_after': 250},
      uiHint: 'S7 check',
    ),
    // Turn: Qc
    const DemoEvent(
      type: 'CardDetected',
      payload: {'type': 'CardDetected', 'is_board': true, 'suit': 'c', 'rank': 'Q'},
      uiHint: 'Turn: Q♣ → TURN',
    ),
    // Check-check → River: 2s
    const DemoEvent(
      type: 'CardDetected',
      payload: {'type': 'CardDetected', 'is_board': true, 'suit': 's', 'rank': '2'},
      uiHint: 'River: 2♠ → RIVER',
    ),
    const DemoEvent(
      type: 'HandEnded',
      payload: {'type': 'HandEnded', 'hand_id': 1},
      uiHint: 'Hand #1 종료',
    ),
  ],
);

/// All-in Preflop — preflop all-in call, runout 5 cards.
final allInPreflop = DemoScenario(
  name: 'All-in Preflop',
  description: '프리플랍 올인 콜. 5장 런아웃.',
  events: [
    const DemoEvent(
      type: 'HandStarted',
      payload: {'type': 'HandStarted', 'hand_id': 2, 'hand_number': 2, 'dealer_seat': 1},
      uiHint: 'Hand #2 시작',
    ),
    const DemoEvent(
      type: 'ActionPerformed',
      payload: {'type': 'ActionPerformed', 'seat': 4, 'action_type': 'allin', 'amount': 10000, 'pot_after': 10150},
      uiHint: 'S4 ALL-IN 10000',
    ),
    const DemoEvent(
      type: 'ActionPerformed',
      payload: {'type': 'ActionPerformed', 'seat': 7, 'action_type': 'fold', 'amount': 0, 'pot_after': 10150},
      uiHint: 'S7 fold',
    ),
    const DemoEvent(
      type: 'ActionPerformed',
      payload: {'type': 'ActionPerformed', 'seat': 1, 'action_type': 'allin', 'amount': 10000, 'pot_after': 20150},
      uiHint: 'S1 ALL-IN call',
    ),
    // Board runout
    const DemoEvent(type: 'CardDetected', payload: {'type': 'CardDetected', 'is_board': true, 'suit': 'h', 'rank': 'T'}, uiHint: 'Flop 1: T♥'),
    const DemoEvent(type: 'CardDetected', payload: {'type': 'CardDetected', 'is_board': true, 'suit': 'd', 'rank': '5'}, uiHint: 'Flop 2: 5♦'),
    const DemoEvent(type: 'CardDetected', payload: {'type': 'CardDetected', 'is_board': true, 'suit': 'c', 'rank': '3'}, uiHint: 'Flop 3: 3♣ → FLOP'),
    const DemoEvent(type: 'CardDetected', payload: {'type': 'CardDetected', 'is_board': true, 'suit': 's', 'rank': '9'}, uiHint: 'Turn: 9♠ → TURN'),
    const DemoEvent(type: 'CardDetected', payload: {'type': 'CardDetected', 'is_board': true, 'suit': 'h', 'rank': '2'}, uiHint: 'River: 2♥ → RIVER'),
    const DemoEvent(
      type: 'HandEnded',
      payload: {'type': 'HandEnded', 'hand_id': 2},
      uiHint: 'Hand #2 종료',
    ),
  ],
);

/// Full Street — all streets with betting on each.
final fullStreet = DemoScenario(
  name: 'Full Street',
  description: '모든 스트리트 진행 (플랍→턴→리버→쇼다운)',
  events: [
    const DemoEvent(type: 'HandStarted', payload: {'type': 'HandStarted', 'hand_id': 3, 'hand_number': 3, 'dealer_seat': 1}, uiHint: 'Hand #3 시작'),
    // Preflop
    const DemoEvent(type: 'ActionPerformed', payload: {'type': 'ActionPerformed', 'seat': 4, 'action_type': 'call', 'amount': 100, 'pot_after': 250}, uiHint: 'S4 call'),
    const DemoEvent(type: 'ActionPerformed', payload: {'type': 'ActionPerformed', 'seat': 7, 'action_type': 'call', 'amount': 100, 'pot_after': 350}, uiHint: 'S7 call'),
    const DemoEvent(type: 'ActionPerformed', payload: {'type': 'ActionPerformed', 'seat': 1, 'action_type': 'check', 'amount': 0, 'pot_after': 350}, uiHint: 'S1 check (BB)'),
    // Flop
    const DemoEvent(type: 'CardDetected', payload: {'type': 'CardDetected', 'is_board': true, 'suit': 'h', 'rank': 'J'}, uiHint: 'Flop 1: J♥'),
    const DemoEvent(type: 'CardDetected', payload: {'type': 'CardDetected', 'is_board': true, 'suit': 's', 'rank': '8'}, uiHint: 'Flop 2: 8♠'),
    const DemoEvent(type: 'CardDetected', payload: {'type': 'CardDetected', 'is_board': true, 'suit': 'd', 'rank': '4'}, uiHint: 'Flop 3: 4♦ → FLOP'),
    const DemoEvent(type: 'ActionPerformed', payload: {'type': 'ActionPerformed', 'seat': 1, 'action_type': 'bet', 'amount': 200, 'pot_after': 550}, uiHint: 'S1 bet 200'),
    const DemoEvent(type: 'ActionPerformed', payload: {'type': 'ActionPerformed', 'seat': 4, 'action_type': 'call', 'amount': 200, 'pot_after': 750}, uiHint: 'S4 call 200'),
    const DemoEvent(type: 'ActionPerformed', payload: {'type': 'ActionPerformed', 'seat': 7, 'action_type': 'fold', 'amount': 0, 'pot_after': 750}, uiHint: 'S7 fold'),
    // Turn
    const DemoEvent(type: 'CardDetected', payload: {'type': 'CardDetected', 'is_board': true, 'suit': 'c', 'rank': '6'}, uiHint: 'Turn: 6♣ → TURN'),
    const DemoEvent(type: 'ActionPerformed', payload: {'type': 'ActionPerformed', 'seat': 1, 'action_type': 'check', 'amount': 0, 'pot_after': 750}, uiHint: 'S1 check'),
    const DemoEvent(type: 'ActionPerformed', payload: {'type': 'ActionPerformed', 'seat': 4, 'action_type': 'bet', 'amount': 400, 'pot_after': 1150}, uiHint: 'S4 bet 400'),
    const DemoEvent(type: 'ActionPerformed', payload: {'type': 'ActionPerformed', 'seat': 1, 'action_type': 'call', 'amount': 400, 'pot_after': 1550}, uiHint: 'S1 call 400'),
    // River
    const DemoEvent(type: 'CardDetected', payload: {'type': 'CardDetected', 'is_board': true, 'suit': 'h', 'rank': 'K'}, uiHint: 'River: K♥ → RIVER'),
    const DemoEvent(type: 'ActionPerformed', payload: {'type': 'ActionPerformed', 'seat': 1, 'action_type': 'check', 'amount': 0, 'pot_after': 1550}, uiHint: 'S1 check'),
    const DemoEvent(type: 'ActionPerformed', payload: {'type': 'ActionPerformed', 'seat': 4, 'action_type': 'check', 'amount': 0, 'pot_after': 1550}, uiHint: 'S4 check'),
    // Showdown
    const DemoEvent(type: 'HandEnded', payload: {'type': 'HandEnded', 'hand_id': 3}, uiHint: 'Hand #3 종료 — 쇼다운'),
  ],
);

/// Miss Deal — hand starts then miss deal declared.
final missDeal = DemoScenario(
  name: 'Miss Deal',
  description: '핸드 시작 후 Miss Deal 선언 → 핸드 무효화',
  events: [
    const DemoEvent(type: 'HandStarted', payload: {'type': 'HandStarted', 'hand_id': 4, 'hand_number': 4, 'dealer_seat': 1}, uiHint: 'Hand #4 시작'),
    const DemoEvent(type: 'ActionPerformed', payload: {'type': 'ActionPerformed', 'seat': 4, 'action_type': 'call', 'amount': 100, 'pot_after': 250}, uiHint: 'S4 call'),
    const DemoEvent(type: 'HandEnded', payload: {'type': 'HandEnded', 'hand_id': 4}, uiHint: 'Miss Deal — 핸드 무효'),
  ],
);

/// RFID Fallback — RFID fails, manual card entry used.
final rfidFallback = DemoScenario(
  name: 'RFID Fallback',
  description: 'RFID 감지 실패 → 수동 카드 입력 → 계속 진행',
  events: [
    const DemoEvent(type: 'HandStarted', payload: {'type': 'HandStarted', 'hand_id': 5, 'hand_number': 5, 'dealer_seat': 1}, uiHint: 'Hand #5 시작'),
    const DemoEvent(
      type: 'RfidStatusChanged',
      payload: {'type': 'RfidStatusChanged', 'status': 'connectionFailed'},
      uiHint: 'RFID 연결 실패 → 배너 표시',
    ),
    // Manual card input for board
    const DemoEvent(type: 'CardDetected', payload: {'type': 'CardDetected', 'is_board': true, 'suit': 's', 'rank': 'A'}, uiHint: '수동 입력: A♠'),
    const DemoEvent(type: 'CardDetected', payload: {'type': 'CardDetected', 'is_board': true, 'suit': 'h', 'rank': 'K'}, uiHint: '수동 입력: K♥'),
    const DemoEvent(type: 'CardDetected', payload: {'type': 'CardDetected', 'is_board': true, 'suit': 'd', 'rank': 'Q'}, uiHint: '수동 입력: Q♦ → FLOP'),
    const DemoEvent(type: 'ActionPerformed', payload: {'type': 'ActionPerformed', 'seat': 1, 'action_type': 'check', 'amount': 0, 'pot_after': 150}, uiHint: 'S1 check'),
    const DemoEvent(type: 'ActionPerformed', payload: {'type': 'ActionPerformed', 'seat': 4, 'action_type': 'check', 'amount': 0, 'pot_after': 150}, uiHint: 'S4 check'),
    // RFID recovers
    const DemoEvent(
      type: 'RfidStatusChanged',
      payload: {'type': 'RfidStatusChanged', 'status': 'connected'},
      uiHint: 'RFID 재연결 → 배너 숨김',
    ),
    const DemoEvent(type: 'CardDetected', payload: {'type': 'CardDetected', 'is_board': true, 'suit': 'c', 'rank': 'J'}, uiHint: 'Turn: J♣ (RFID 복구)'),
    const DemoEvent(type: 'HandEnded', payload: {'type': 'HandEnded', 'hand_id': 5}, uiHint: 'Hand #5 종료'),
  ],
);

/// Multi-action — raise, re-raise, call, fold combinations.
final multiAction = DemoScenario(
  name: 'Multi-action',
  description: '다양한 액션 조합 (raise→re-raise→call→fold)',
  events: [
    const DemoEvent(type: 'HandStarted', payload: {'type': 'HandStarted', 'hand_id': 6, 'hand_number': 6, 'dealer_seat': 1}, uiHint: 'Hand #6 시작'),
    const DemoEvent(type: 'ActionPerformed', payload: {'type': 'ActionPerformed', 'seat': 4, 'action_type': 'raise', 'amount': 300, 'pot_after': 450}, uiHint: 'S4 raise 300'),
    const DemoEvent(type: 'ActionPerformed', payload: {'type': 'ActionPerformed', 'seat': 7, 'action_type': 'raise', 'amount': 900, 'pot_after': 1350}, uiHint: 'S7 re-raise 900'),
    const DemoEvent(type: 'ActionPerformed', payload: {'type': 'ActionPerformed', 'seat': 1, 'action_type': 'fold', 'amount': 0, 'pot_after': 1350}, uiHint: 'S1 fold'),
    const DemoEvent(type: 'ActionPerformed', payload: {'type': 'ActionPerformed', 'seat': 4, 'action_type': 'call', 'amount': 600, 'pot_after': 1950}, uiHint: 'S4 call 600'),
    // Flop
    const DemoEvent(type: 'CardDetected', payload: {'type': 'CardDetected', 'is_board': true, 'suit': 'h', 'rank': '9'}, uiHint: 'Flop 1: 9♥'),
    const DemoEvent(type: 'CardDetected', payload: {'type': 'CardDetected', 'is_board': true, 'suit': 's', 'rank': '5'}, uiHint: 'Flop 2: 5♠'),
    const DemoEvent(type: 'CardDetected', payload: {'type': 'CardDetected', 'is_board': true, 'suit': 'c', 'rank': '2'}, uiHint: 'Flop 3: 2♣ → FLOP'),
    const DemoEvent(type: 'ActionPerformed', payload: {'type': 'ActionPerformed', 'seat': 4, 'action_type': 'bet', 'amount': 500, 'pot_after': 2450}, uiHint: 'S4 bet 500'),
    const DemoEvent(type: 'ActionPerformed', payload: {'type': 'ActionPerformed', 'seat': 7, 'action_type': 'raise', 'amount': 1500, 'pot_after': 3950}, uiHint: 'S7 raise 1500'),
    const DemoEvent(type: 'ActionPerformed', payload: {'type': 'ActionPerformed', 'seat': 4, 'action_type': 'fold', 'amount': 0, 'pot_after': 3950}, uiHint: 'S4 fold'),
    const DemoEvent(type: 'HandEnded', payload: {'type': 'HandEnded', 'hand_id': 6}, uiHint: 'Hand #6 종료 — S7 wins'),
  ],
);
