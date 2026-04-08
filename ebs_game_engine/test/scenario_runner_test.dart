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
        return Seat(
          index: e.key,
          label: (s['label'] as String?) ?? 'Seat ${e.key}',
          stack: (s['stack'] as num).toInt(),
        );
      }).toList();

      var state = GameState(
        sessionId: 'test-$name',
        variantName: scenario.variant,
        seats: seats,
        deck: variant.createDeck(seed: 42),
        bbAmount: (scenario.blinds['bb'] ?? 10),
      );

      // Determine blind positions
      final n = seats.length;
      int sbSeat, bbSeat;
      if (n == 2) {
        // Heads-up: dealer = SB
        sbSeat = scenario.dealer;
        bbSeat = (scenario.dealer + 1) % n;
      } else {
        sbSeat = (scenario.dealer + 1) % n;
        bbSeat = (scenario.dealer + 2) % n;
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
        state = Engine.apply(state, event);
      }

      // Basic assertion: didn't crash and state is valid
      expect(state, isNotNull);

      // Validate expectations if present
      final exp = scenario.expectations;
      if (exp != null) {
        if (exp.containsKey('pot_zero')) {
          expect(state.pot.main, equals(0));
        }
        if (exp.containsKey('hand_ended')) {
          expect(state.handInProgress, isFalse);
        }
        if (exp.containsKey('community_count')) {
          expect(state.community.length,
              equals((exp['community_count'] as num).toInt()));
        }
        if (exp.containsKey('stack_0')) {
          expect(state.seats[0].stack,
              equals((exp['stack_0'] as num).toInt()));
        }
      }
    });
  }
}
