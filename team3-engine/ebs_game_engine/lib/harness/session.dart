import '../engine.dart';

/// A game session: holds initial state + event log, replays on demand.
class Session {
  final String id;
  final Variant variant;
  final List<Event> events = [];
  final GameState _initial;

  Session({
    required this.id,
    required this.variant,
    required GameState initial,
  }) : _initial = initial;

  /// Replay all events to get the current state.
  GameState get currentState => stateAt(events.length);

  /// Replay first [cursor] events only.
  GameState stateAt(int cursor) {
    var state = _initial;
    final count = cursor.clamp(0, events.length);
    for (var i = 0; i < count; i++) {
      state = Engine.apply(state, events[i]);
    }
    return state;
  }

  /// Add an event and return the resulting state.
  GameState addEvent(Event event) {
    events.add(event);
    _undoCount = 0;
    return currentState;
  }

  /// Add an event and return the result including output events.
  ReduceResult addEventFull(Event event) {
    events.add(event);
    _undoCount = 0;
    return Engine.applyFull(stateAt(events.length - 1), event);
  }

  int _undoCount = 0;
  static const _maxUndoSteps = 5;

  /// Remove the last event (undo). Limited to [_maxUndoSteps] consecutive undos.
  bool undo() {
    if (events.isEmpty || _undoCount >= _maxUndoSteps) return false;
    events.removeLast();
    _undoCount++;
    return true;
  }

  /// Reset the undo counter (call after any non-undo action).
  void resetUndoCount() => _undoCount = 0;

  /// Legal actions at current state.
  List<LegalAction> legalActions() => Engine.legalActions(currentState);

  /// Full JSON representation of the session state.
  Map<String, dynamic> toJson({int? cursor}) {
    final state = cursor != null ? stateAt(cursor) : currentState;
    final effectiveCursor = cursor ?? events.length;

    // Build log entries as structured objects for frontend
    final log = <Map<String, dynamic>>[];
    for (var i = 0; i < events.length; i++) {
      log.add({
        'type': _eventType(events[i]),
        'description': _describeEvent(events[i], i),
      });
    }

    return {
      'sessionId': id,
      'variant': variant.name,
      'street': state.street.name,
      'seats': state.seats.map((s) => _seatToJson(s)).toList(),
      'community': state.community.map((c) => c.notation).toList(),
      'pot': {
        'main': state.pot.main,
        'total': state.pot.total,
        'sides': state.pot.sides
            .map((sp) => {
                  'amount': sp.amount,
                  'eligible': sp.eligible.toList()..sort(),
                })
            .toList(),
      },
      'actionOn': state.actionOn,
      'dealerSeat': state.dealerSeat,
      'legalActions': Engine.legalActions(state).map((a) => a.toJson()).toList(),
      'handNumber': state.handNumber,
      'anteType': state.anteType,
      'anteAmount': state.anteAmount,
      'straddleEnabled': state.straddleEnabled,
      'straddleSeat': state.straddleSeat,
      'bombPotEnabled': state.bombPotEnabled,
      'bombPotAmount': state.bombPotAmount,
      'canvasType': state.canvasType.name,
      'sevenDeuceEnabled': state.sevenDeuceEnabled,
      'sevenDeuceAmount': state.sevenDeuceAmount,
      'runItTimes': state.runItTimes,
      'actionTimeoutMs': state.actionTimeoutMs,
      'isAllInRunout': Engine.isAllInRunout(state),
      'eventCount': events.length,
      'cursor': effectiveCursor,
      'log': log,
    };
  }

  Map<String, dynamic> _seatToJson(Seat seat) => {
        'index': seat.index,
        'label': seat.label,
        'stack': seat.stack,
        'currentBet': seat.currentBet,
        'status': seat.status.name,
        'holeCards': seat.holeCards.map((c) => c.notation).toList(),
        'isDealer': seat.isDealer,
      };

  String _eventType(Event event) => switch (event) {
        HandStart() => 'HandStart',
        DealHoleCards() => 'DealHole',
        DealCommunity() => 'DealComm',
        PineappleDiscard() => 'Discard',
        PlayerAction(action: final a) => _actionVerb(a),
        StreetAdvance() => 'Street',
        PotAwarded() => 'PotAward',
        HandEnd() => 'HandEnd',
        MisDeal() => 'MisDeal',
        BombPotConfig() => 'BombPot',
        RunItChoice() => 'RunIt',
        ManualNextHand() => 'NextHand',
        TimeoutFold() => 'Timeout',
        MuckDecision() => 'Muck',
      };

  String _actionVerb(Action action) => switch (action) {
        Fold() => 'Fold',
        Check() => 'Check',
        Call() => 'Call',
        Bet() => 'Bet',
        Raise() => 'Raise',
        AllIn() => 'AllIn',
      };

  String _describeEvent(Event event, int idx) {
    return switch (event) {
      HandStart(dealerSeat: final d, blinds: final b) =>
        '#$idx HandStart dealer=$d blinds=$b',
      DealHoleCards(cards: final c) =>
        '#$idx DealHoleCards seats=${c.keys.toList()}',
      DealCommunity(cards: final c) =>
        '#$idx DealCommunity [${c.map((x) => x.notation).join(', ')}]',
      PineappleDiscard(seatIndex: final s, discarded: final c) =>
        '#$idx PineappleDiscard seat=$s card=${c.notation}',
      PlayerAction(seatIndex: final s, action: final a) =>
        '#$idx PlayerAction seat=$s ${_describeAction(a)}',
      StreetAdvance(next: final n) => '#$idx StreetAdvance -> ${n.name}',
      PotAwarded(awards: final a) => '#$idx PotAwarded $a',
      HandEnd() => '#$idx HandEnd',
      MisDeal() => '#$idx MisDeal',
      BombPotConfig(amount: final a) => '#$idx BombPotConfig amount=$a',
      RunItChoice(times: final t) => '#$idx RunItChoice times=$t',
      ManualNextHand() => '#$idx ManualNextHand',
      TimeoutFold(seatIndex: final s) => '#$idx TimeoutFold seat=$s',
      MuckDecision(seatIndex: final s, showCards: final show) =>
        '#$idx MuckDecision seat=$s show=$show',
    };
  }

  String _describeAction(Action action) => switch (action) {
        Fold() => 'fold',
        Check() => 'check',
        Call(:final amount) => 'call $amount',
        Bet(:final amount) => 'bet $amount',
        Raise(:final toAmount) => 'raise to $toAmount',
        AllIn(:final amount) => 'allin $amount',
      };
}
