import 'package:test/test.dart';
import 'package:ebs_game_engine/harness/scenario_loader.dart';
import 'package:ebs_game_engine/engine.dart';

const _basicNlhYaml = '''
variant: nlh
dealer: 0

blinds:
  sb: 5
  bb: 10

seats:
  - index: 0
    label: "Seat 1"
    stack: 1000
  - index: 1
    label: "Seat 2"
    stack: 1000
  - index: 2
    label: "Seat 3"
    stack: 1000

events:
  - deal_hole:
      0: [As, Kh]
      1: [Qd, Qc]
      2: [7h, 2c]
  - action:
      seat: 0
      type: call
      amount: 10
  - action:
      seat: 1
      type: fold
  - action:
      seat: 2
      type: check
  - street_advance: flop
  - deal_community: [Ac, Ks, Qh]

expectations:
  winner: seat_0
  pot_after_flop: 30
''';

const _potAwardYaml = '''
variant: nlh
dealer: 0

blinds:
  sb: 5
  bb: 10

seats:
  - index: 0
    label: "Seat 1"
    stack: 500
  - index: 1
    label: "Seat 2"
    stack: 500

events:
  - deal_hole:
      0: [As, Kh]
      1: [Qd, Qc]
  - action:
      seat: 0
      type: call
      amount: 5
  - action:
      seat: 1
      type: check
  - pot_awarded:
      0: 20
  - hand_end: true
''';

void main() {
  group('ScenarioLoader.parseYaml', () {
    test('parses variant and dealer', () {
      final scenario = ScenarioLoader.parseYaml(_basicNlhYaml);
      expect(scenario.variant, equals('nlh'));
      expect(scenario.dealer, equals(0));
    });

    test('parses seats', () {
      final scenario = ScenarioLoader.parseYaml(_basicNlhYaml);
      expect(scenario.seats, hasLength(3));
      expect(scenario.seats[0]['label'], equals('Seat 1'));
      expect(scenario.seats[0]['stack'], equals(1000));
    });

    test('parses blinds', () {
      final scenario = ScenarioLoader.parseYaml(_basicNlhYaml);
      expect(scenario.blinds['sb'], equals(5));
      expect(scenario.blinds['bb'], equals(10));
    });

    test('parses events list', () {
      final scenario = ScenarioLoader.parseYaml(_basicNlhYaml);
      expect(scenario.events, hasLength(6));
    });

    test('parses expectations', () {
      final scenario = ScenarioLoader.parseYaml(_basicNlhYaml);
      expect(scenario.expectations, isNotNull);
      expect(scenario.expectations!['winner'], equals('seat_0'));
    });

    test('expectations null when absent', () {
      const minimalYaml = '''
variant: nlh
dealer: 0
blinds:
  sb: 5
  bb: 10
seats:
  - index: 0
    stack: 1000
events: []
''';
      final scenario = ScenarioLoader.parseYaml(minimalYaml);
      expect(scenario.expectations, isNull);
    });
  });

  group('ScenarioLoader.buildEvents', () {
    test('returns correct event types for basic scenario', () {
      final scenario = ScenarioLoader.parseYaml(_basicNlhYaml);
      final events = ScenarioLoader.buildEvents(scenario);

      expect(events, hasLength(6));
      expect(events[0], isA<DealHoleCards>());
      expect(events[1], isA<PlayerAction>());
      expect(events[2], isA<PlayerAction>());
      expect(events[3], isA<PlayerAction>());
      expect(events[4], isA<StreetAdvance>());
      expect(events[5], isA<DealCommunity>());
    });

    test('DealHoleCards has correct card map', () {
      final scenario = ScenarioLoader.parseYaml(_basicNlhYaml);
      final events = ScenarioLoader.buildEvents(scenario);
      final deal = events[0] as DealHoleCards;

      expect(deal.cards[0], hasLength(2));
      expect(deal.cards[0]![0].notation, equals('As'));
      expect(deal.cards[0]![1].notation, equals('Kh'));
      expect(deal.cards[1]![0].notation, equals('Qd'));
      expect(deal.cards[1]![1].notation, equals('Qc'));
    });

    test('PlayerAction has correct action type for call', () {
      final scenario = ScenarioLoader.parseYaml(_basicNlhYaml);
      final events = ScenarioLoader.buildEvents(scenario);
      final pa = events[1] as PlayerAction;

      expect(pa.seatIndex, equals(0));
      expect(pa.action, isA<Call>());
      expect((pa.action as Call).amount, equals(10));
    });

    test('PlayerAction fold', () {
      final scenario = ScenarioLoader.parseYaml(_basicNlhYaml);
      final events = ScenarioLoader.buildEvents(scenario);
      final pa = events[2] as PlayerAction;

      expect(pa.seatIndex, equals(1));
      expect(pa.action, isA<Fold>());
    });

    test('StreetAdvance targets correct street', () {
      final scenario = ScenarioLoader.parseYaml(_basicNlhYaml);
      final events = ScenarioLoader.buildEvents(scenario);
      final sa = events[4] as StreetAdvance;

      expect(sa.next, equals(Street.flop));
    });

    test('DealCommunity has correct cards', () {
      final scenario = ScenarioLoader.parseYaml(_basicNlhYaml);
      final events = ScenarioLoader.buildEvents(scenario);
      final dc = events[5] as DealCommunity;

      expect(dc.cards, hasLength(3));
      expect(dc.cards[0].notation, equals('Ac'));
      expect(dc.cards[1].notation, equals('Ks'));
      expect(dc.cards[2].notation, equals('Qh'));
    });

    test('PotAwarded and HandEnd events', () {
      final scenario = ScenarioLoader.parseYaml(_potAwardYaml);
      final events = ScenarioLoader.buildEvents(scenario);

      // deal_hole, call, check, pot_awarded, hand_end
      expect(events, hasLength(5));
      expect(events[3], isA<PotAwarded>());
      expect(events[4], isA<HandEnd>());

      final pa = events[3] as PotAwarded;
      expect(pa.awards[0], equals(20));
    });

    test('all action types parse correctly', () {
      const yaml = '''
variant: nlh
dealer: 0
blinds:
  sb: 5
  bb: 10
seats:
  - index: 0
    stack: 1000
  - index: 1
    stack: 1000
events:
  - action:
      seat: 0
      type: fold
  - action:
      seat: 0
      type: check
  - action:
      seat: 0
      type: call
      amount: 10
  - action:
      seat: 0
      type: bet
      amount: 20
  - action:
      seat: 0
      type: raise
      amount: 60
  - action:
      seat: 0
      type: allin
      amount: 900
''';
      final scenario = ScenarioLoader.parseYaml(yaml);
      final events = ScenarioLoader.buildEvents(scenario);

      expect(events[0], isA<PlayerAction>());
      expect((events[0] as PlayerAction).action, isA<Fold>());
      expect((events[1] as PlayerAction).action, isA<Check>());
      expect((events[2] as PlayerAction).action, isA<Call>());
      expect((events[3] as PlayerAction).action, isA<Bet>());
      expect((events[4] as PlayerAction).action, isA<Raise>());
      expect((events[5] as PlayerAction).action, isA<AllIn>());
    });
  });

  group('ScenarioLoader integration — engine apply', () {
    test('events apply cleanly with Engine', () {
      final scenario = ScenarioLoader.parseYaml(_basicNlhYaml);
      final variant = variantRegistry['nlh']!();
      final seats = List.generate(3, (i) => Seat(
            index: i,
            label: 'Seat ${i + 1}',
            stack: 1000,
            isDealer: i == 0,
          ));
      var state = GameState(
        sessionId: 'test',
        variantName: 'nlh',
        seats: seats,
        deck: variant.createDeck(seed: 42),
        dealerSeat: 0,
      );

      // HandStart
      state = Engine.apply(
        state,
        HandStart(dealerSeat: 0, blinds: {1: 5, 2: 10}),
      );

      // Apply all scenario events (skip StreetAdvance/DealCommunity —
      // Engine auto-advances and deals community cards)
      final events = ScenarioLoader.buildEvents(scenario);
      for (final event in events) {
        if (event is StreetAdvance || event is DealCommunity) continue;
        state = Engine.apply(state, event);
      }

      // After preflop complete: Engine auto-advances to flop with 3 cards
      expect(state.community, hasLength(3));
      expect(state.street, equals(Street.flop));
    });
  });
}
