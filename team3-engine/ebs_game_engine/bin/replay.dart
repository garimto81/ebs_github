import 'dart:io';
import 'package:ebs_game_engine/harness/scenario_loader.dart';
import 'package:ebs_game_engine/harness/session.dart';
import 'package:ebs_game_engine/engine.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run bin/replay.dart <scenario.yaml>');
    exit(1);
  }

  final path = args[0];
  if (!File(path).existsSync()) {
    stderr.writeln('File not found: $path');
    exit(1);
  }

  print('Loading scenario: $path');
  final scenario = await ScenarioLoader.loadFile(path);

  // Resolve variant
  final factory = variantRegistry[scenario.variant];
  if (factory == null) {
    stderr.writeln('Unknown variant: ${scenario.variant}');
    exit(1);
  }
  final variant = factory();

  // Build initial state
  final seatCount = scenario.seats.length;
  final dealer = scenario.dealer;
  final seats = List.generate(seatCount, (i) {
    final seatData = scenario.seats[i];
    return Seat(
      index: i,
      label: seatData['label'] as String? ?? 'Seat ${i + 1}',
      stack: (seatData['stack'] as num?)?.toInt() ?? 1000,
      isDealer: i == dealer,
    );
  });

  final sb = scenario.blinds['sb'] ?? 5;
  final bb = scenario.blinds['bb'] ?? 10;
  final sbIdx = (dealer + 1) % seatCount;
  final bbIdx = (dealer + 2) % seatCount;

  final deck = variant.createDeck();
  final initial = GameState(
    sessionId: 'replay',
    variantName: variant.name,
    seats: seats,
    deck: deck,
    dealerSeat: dealer,
  );

  final session = Session(id: 'replay', variant: variant, initial: initial);

  // Apply HandStart
  session.addEvent(HandStart(
    dealerSeat: dealer,
    blinds: {sbIdx: sb, bbIdx: bb},
  ));
  _printStep(0, 'HandStart', session);

  // Build and apply scenario events
  final events = ScenarioLoader.buildEvents(scenario);
  for (var i = 0; i < events.length; i++) {
    session.addEvent(events[i]);
    _printStep(i + 1, _describeEvent(events[i]), session);
  }

  print('\n=== Final State ===');
  final state = session.currentState;
  print('Street: ${state.street.name}');
  print('Pot: ${state.pot.total}');
  print('ActionOn: ${state.actionOn}');
  print('Community: [${state.community.map((c) => c.notation).join(', ')}]');
  for (final seat in state.seats) {
    print(
        '  Seat ${seat.index} (${seat.label}): stack=${seat.stack} status=${seat.status.name}');
  }

  if (scenario.expectations != null) {
    print('\n=== Expectations ===');
    scenario.expectations!.forEach((k, v) => print('  $k: $v'));
  }
}

void _printStep(int step, String desc, Session session) {
  final state = session.currentState;
  print(
      'Step $step | $desc | street=${state.street.name} pot=${state.pot.total} actionOn=${state.actionOn}');
}

String _describeEvent(Event event) => switch (event) {
      HandStart(dealerSeat: final d) => 'HandStart dealer=$d',
      DealHoleCards() => 'DealHoleCards',
      DealCommunity(cards: final c) =>
        'DealCommunity [${c.map((x) => x.notation).join(', ')}]',
      PineappleDiscard(seatIndex: final s) => 'PineappleDiscard seat=$s',
      PlayerAction(seatIndex: final s, action: final a) =>
        'PlayerAction seat=$s ${_describeAction(a)}',
      StreetAdvance(next: final n) => 'StreetAdvance -> ${n.name}',
      PotAwarded(awards: final a) => 'PotAwarded $a',
      HandEnd() => 'HandEnd',
      MisDeal() => 'MisDeal',
      BombPotConfig(amount: final a) => 'BombPotConfig amount=$a',
      RunItChoice(times: final t) => 'RunItChoice times=$t',
      ManualNextHand() => 'ManualNextHand',
      TimeoutFold(seatIndex: final s) => 'TimeoutFold seat=$s',
      MuckDecision(seatIndex: final s, showCards: final show) =>
        'MuckDecision seat=$s show=$show',
    };

String _describeAction(Action action) => switch (action) {
      Fold() => 'fold',
      Check() => 'check',
      Call(:final amount) => 'call $amount',
      Bet(:final amount) => 'bet $amount',
      Raise(:final toAmount) => 'raise to $toAmount',
      AllIn(:final amount) => 'allin $amount',
    };
