import 'dart:io';
import 'package:test/test.dart';
import 'package:ebs_game_engine/harness/scenario_loader.dart';
import 'package:ebs_game_engine/engine.dart';

void main() {
  final dir = Directory('test/scenarios');
  final files = dir.listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.yaml'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    test('scenario: $name', () async {
      final scenario = await ScenarioLoader.loadFile(file.path);
      final variant = variantRegistry[scenario.variant]!();

      final seats = scenario.seats.asMap().entries.map((e) {
        final s = e.value;
        final statusStr = s['status'] as String?;
        return Seat(
          index: e.key,
          label: (s['label'] as String?) ?? 'Seat ${e.key}',
          stack: (s['stack'] as num).toInt(),
          status: statusStr != null
              ? _parseSeatStatus(statusStr)
              : SeatStatus.active,
        );
      }).toList();

      // Apply config section if present
      final cfg = scenario.config ?? {};
      var state = GameState(
        sessionId: 'test-$name',
        variantName: scenario.variant,
        seats: seats,
        deck: variant.createDeck(seed: 42),
        bbAmount: (scenario.blinds['bb'] ?? 10),
        anteType: cfg.containsKey('ante_type')
            ? (cfg['ante_type'] as num).toInt()
            : null,
        anteAmount: cfg.containsKey('ante_amount')
            ? (cfg['ante_amount'] as num).toInt()
            : null,
        straddleEnabled: cfg['straddle_enabled'] as bool? ?? false,
        straddleSeat: cfg.containsKey('straddle_seat')
            ? (cfg['straddle_seat'] as num).toInt()
            : null,
        bombPotEnabled: cfg['bomb_pot_enabled'] as bool? ?? false,
        bombPotAmount: cfg.containsKey('bomb_pot_amount')
            ? (cfg['bomb_pot_amount'] as num).toInt()
            : null,
        canvasType: cfg['canvas_type'] == 'venue'
            ? CanvasType.venue
            : CanvasType.broadcast,
      );

      // Determine blind positions (skip sitting-out seats)
      final n = seats.length;
      int sbSeat, bbSeat;
      if (n == 2) {
        // Heads-up: dealer = SB
        sbSeat = scenario.dealer;
        bbSeat = (scenario.dealer + 1) % n;
      } else {
        // Find active seats after dealer
        final activeSeatIndices = <int>[];
        for (var i = 1; i <= n; i++) {
          final idx = (scenario.dealer + i) % n;
          if (seats[idx].status != SeatStatus.sittingOut) {
            activeSeatIndices.add(idx);
          }
        }
        sbSeat = activeSeatIndices[0];
        bbSeat = activeSeatIndices[1];
      }

      state = Engine.apply(state, HandStart(
        dealerSeat: scenario.dealer,
        blinds: {
          sbSeat: scenario.blinds['sb'] ?? 5,
          bbSeat: scenario.blinds['bb'] ?? 10,
        },
      ));

      final events = ScenarioLoader.buildEvents(scenario);
      for (final event in events) {
        // Engine auto-advances street and deals community cards,
        // so skip explicit StreetAdvance/DealCommunity from scenarios.
        if (event is StreetAdvance || event is DealCommunity) continue;
        state = Engine.apply(state, event);
      }

      // Chip conservation invariant — always enforced
      final totalChips = state.seats.fold<int>(0, (s, seat) => s + seat.stack)
          + state.pot.total;
      final initialChips = scenario.seats.fold<int>(
          0, (s, m) => s + (m['stack'] as num).toInt());
      expect(totalChips, equals(initialChips),
          reason: '$name: chip conservation violated '
              '(total=$totalChips, initial=$initialChips, '
              'delta=${totalChips - initialChips})');

      // Validate expectations if present
      final exp = scenario.expectations;
      if (exp != null) {
        if (exp.containsKey('hand_ended')) {
          expect(state.handInProgress, equals(!(exp['hand_ended'] as bool)),
              reason: '$name: hand_ended');
        }
        if (exp.containsKey('pot_total')) {
          expect(state.pot.total,
              equals((exp['pot_total'] as num).toInt()),
              reason: '$name: pot_total');
        }
        if (exp.containsKey('community_count')) {
          expect(state.community.length,
              equals((exp['community_count'] as num).toInt()),
              reason: '$name: community_count');
        }
        if (exp.containsKey('stacks')) {
          final stacks = exp['stacks'] as Map;
          for (final entry in stacks.entries) {
            final seatIdx = int.parse(entry.key.toString());
            final expected = (entry.value as num).toInt();
            expect(state.seats[seatIdx].stack, equals(expected),
                reason: '$name: seat $seatIdx stack '
                    '(actual=${state.seats[seatIdx].stack})');
          }
        }
        if (exp.containsKey('seat_statuses')) {
          final statuses = exp['seat_statuses'] as Map;
          for (final entry in statuses.entries) {
            final seatIdx = int.parse(entry.key.toString());
            final expected = _parseSeatStatus(entry.value.toString());
            expect(state.seats[seatIdx].status, equals(expected),
                reason: '$name: seat $seatIdx status '
                    '(actual=${state.seats[seatIdx].status})');
          }
        }
        // Legacy keys
        if (exp.containsKey('pot_zero')) {
          expect(state.pot.main, equals(0),
              reason: '$name: pot_zero');
        }
        if (exp.containsKey('stack_0')) {
          expect(state.seats[0].stack,
              equals((exp['stack_0'] as num).toInt()),
              reason: '$name: stack_0');
        }
        // New expectation keys
        if (exp.containsKey('hand_number')) {
          expect(state.handNumber,
              equals((exp['hand_number'] as num).toInt()),
              reason: '$name: hand_number');
        }
        if (exp.containsKey('dealer_seat')) {
          expect(state.dealerSeat,
              equals((exp['dealer_seat'] as num).toInt()),
              reason: '$name: dealer_seat');
        }
        if (exp.containsKey('hand_in_progress')) {
          expect(state.handInProgress,
              equals(exp['hand_in_progress'] as bool),
              reason: '$name: hand_in_progress');
        }
        if (exp.containsKey('street')) {
          final streetName = exp['street'] as String;
          final expectedStreet = _parseStreetName(streetName);
          expect(state.street, equals(expectedStreet),
              reason: '$name: street');
        }
        if (exp.containsKey('hole_cards_empty')) {
          final emptySeats = exp['hole_cards_empty'] as List;
          for (final seatIdx in emptySeats) {
            final idx = (seatIdx as num).toInt();
            expect(state.seats[idx].holeCards, isEmpty,
                reason: '$name: seat $idx hole cards should be empty');
          }
        }
        if (exp.containsKey('run_it_times')) {
          expect(state.runItTimes,
              equals((exp['run_it_times'] as num).toInt()),
              reason: '$name: run_it_times');
        }
      }
    });
  }
}

SeatStatus _parseSeatStatus(String s) => switch (s) {
      'active' => SeatStatus.active,
      'folded' => SeatStatus.folded,
      'allIn' || 'all_in' => SeatStatus.allIn,
      'sittingOut' || 'sitting_out' => SeatStatus.sittingOut,
      _ => throw ArgumentError('Unknown seat status: $s'),
    };

Street _parseStreetName(String s) => switch (s) {
      'setupHand' => Street.setupHand,
      'preflop' => Street.preflop,
      'flop' => Street.flop,
      'turn' => Street.turn,
      'river' => Street.river,
      'showdown' => Street.showdown,
      'runItMultiple' => Street.runItMultiple,
      _ => throw ArgumentError('Unknown street: $s'),
    };
