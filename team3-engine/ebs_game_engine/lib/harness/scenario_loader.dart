import 'dart:io';
import 'package:yaml/yaml.dart';
import '../core/cards/card.dart';
import '../core/actions/event.dart';
import '../core/actions/action.dart';
import '../core/state/game_state.dart';
import 'session.dart';

/// Parsed YAML scenario data.
class Scenario {
  final String variant;
  final List<Map<String, dynamic>> seats;
  final int dealer;
  final Map<String, int> blinds;
  final List<Map<String, dynamic>> events;
  final Map<String, dynamic>? expectations;
  final Map<String, dynamic>? config;

  const Scenario({
    required this.variant,
    required this.seats,
    required this.dealer,
    required this.blinds,
    required this.events,
    this.expectations,
    this.config,
  });
}

/// Loads and saves YAML scenario files.
class ScenarioLoader {
  ScenarioLoader._();

  /// Parse a YAML string into a [Scenario].
  static Scenario parseYaml(String content) {
    final doc = loadYaml(content) as YamlMap;

    final variant = doc['variant'] as String? ?? 'nlh';
    final dealer = (doc['dealer'] as num?)?.toInt() ?? 0;

    // Seats
    final seatsRaw = doc['seats'];
    final seats = <Map<String, dynamic>>[];
    if (seatsRaw is YamlList) {
      for (final s in seatsRaw) {
        if (s is YamlMap) {
          seats.add(_yamlMapToMap(s));
        }
      }
    }

    // Blinds
    final blindsRaw = doc['blinds'];
    final blinds = <String, int>{};
    if (blindsRaw is YamlMap) {
      blindsRaw.forEach((k, v) {
        blinds[k.toString()] = (v as num).toInt();
      });
    }

    // Events
    final eventsRaw = doc['events'];
    final events = <Map<String, dynamic>>[];
    if (eventsRaw is YamlList) {
      for (final e in eventsRaw) {
        if (e is YamlMap) {
          events.add(_yamlMapToMap(e));
        }
      }
    }

    // Expectations (optional)
    Map<String, dynamic>? expectations;
    final expectRaw = doc['expectations'];
    if (expectRaw is YamlMap) {
      expectations = _yamlMapToMap(expectRaw);
    }

    // Config (optional) — sets GameState properties before hand start
    Map<String, dynamic>? config;
    final configRaw = doc['config'];
    if (configRaw is YamlMap) {
      config = _yamlMapToMap(configRaw);
    }

    return Scenario(
      variant: variant,
      seats: seats,
      dealer: dealer,
      blinds: blinds,
      events: events,
      expectations: expectations,
      config: config,
    );
  }

  /// Read a YAML file and parse it.
  static Future<Scenario> loadFile(String path) async {
    final content = await File(path).readAsString();
    return parseYaml(content);
  }

  /// Convert scenario event maps to [Event] objects.
  static List<Event> buildEvents(Scenario scenario) {
    final result = <Event>[];

    for (final eventMap in scenario.events) {
      final event = _buildEvent(eventMap);
      if (event != null) result.add(event);
    }

    return result;
  }

  static Event? _buildEvent(Map<String, dynamic> map) {
    // hand_start: { dealer: 1, blinds: { 2: 5, 0: 10 } }
    if (map.containsKey('hand_start')) {
      final raw = map['hand_start'];
      if (raw is Map) {
        final dealer = (raw['dealer'] as num?)?.toInt() ?? 0;
        final blindsRaw = raw['blinds'];
        final blinds = <int, int>{};
        if (blindsRaw is Map) {
          blindsRaw.forEach((k, v) {
            blinds[int.parse(k.toString())] = (v as num).toInt();
          });
        }
        return HandStart(dealerSeat: dealer, blinds: blinds);
      }
    }

    // deal_hole: {0: [As, Kh], 1: [Qd, Qc]}
    if (map.containsKey('deal_hole')) {
      final raw = map['deal_hole'];
      final holeMap = <int, List<Card>>{};
      if (raw is Map) {
        raw.forEach((k, v) {
          final idx = int.parse(k.toString());
          final cards = <Card>[];
          if (v is List) {
            for (final c in v) {
              cards.add(Card.parse(c.toString()));
            }
          }
          holeMap[idx] = cards;
        });
      }
      return DealHoleCards(holeMap);
    }

    // deal_community: [Qs, Jd, Th]
    if (map.containsKey('deal_community')) {
      final raw = map['deal_community'];
      final cards = <Card>[];
      if (raw is List) {
        for (final c in raw) {
          cards.add(Card.parse(c.toString()));
        }
      }
      return DealCommunity(cards);
    }

    // action: {seat: 0, type: raise, amount: 30}
    if (map.containsKey('action')) {
      final actionMap = map['action'];
      if (actionMap is Map) {
        final seat = (actionMap['seat'] as num?)?.toInt() ?? 0;
        final type = actionMap['type'] as String? ?? '';
        final amount = (actionMap['amount'] as num?)?.toInt() ?? 0;
        final action = _parseAction(type, amount);
        if (action != null) return PlayerAction(seat, action);
      }
      return null;
    }

    // street_advance: flop
    if (map.containsKey('street_advance')) {
      final streetName = map['street_advance'] as String? ?? 'flop';
      final street = _parseStreet(streetName);
      return StreetAdvance(street);
    }

    // pot_awarded: {0: 300}
    if (map.containsKey('pot_awarded')) {
      final raw = map['pot_awarded'];
      final awards = <int, int>{};
      if (raw is Map) {
        raw.forEach((k, v) {
          awards[int.parse(k.toString())] = (v as num).toInt();
        });
      }
      return PotAwarded(awards);
    }

    // hand_end
    if (map.containsKey('hand_end')) {
      return const HandEnd();
    }

    // pineapple_discard: {seat: 0, card: Kh}
    if (map.containsKey('pineapple_discard')) {
      final raw = map['pineapple_discard'];
      if (raw is Map) {
        final seat = (raw['seat'] as num?)?.toInt() ?? 0;
        final cardStr = raw['card'] as String? ?? '';
        final card = Card.parse(cardStr);
        return PineappleDiscard(seat, card);
      }
    }

    // misdeal: true
    if (map.containsKey('misdeal')) {
      return const MisDeal();
    }

    // bomb_pot_config: { amount: 50 }
    if (map.containsKey('bomb_pot_config')) {
      final raw = map['bomb_pot_config'];
      if (raw is Map) {
        final amount = (raw['amount'] as num?)?.toInt() ?? 0;
        return BombPotConfig(amount);
      }
      if (raw is num) {
        return BombPotConfig(raw.toInt());
      }
    }

    // run_it_choice: { times: 2 }
    if (map.containsKey('run_it_choice')) {
      final raw = map['run_it_choice'];
      if (raw is Map) {
        final times = (raw['times'] as num?)?.toInt() ?? 2;
        return RunItChoice(times);
      }
      if (raw is num) {
        return RunItChoice(raw.toInt());
      }
    }

    // manual_next_hand: true
    if (map.containsKey('manual_next_hand')) {
      return const ManualNextHand();
    }

    // timeout_fold: { seat: 2 }
    if (map.containsKey('timeout_fold')) {
      final raw = map['timeout_fold'];
      if (raw is Map) {
        final seat = (raw['seat'] as num?)?.toInt() ?? 0;
        return TimeoutFold(seat);
      }
      if (raw is num) {
        return TimeoutFold(raw.toInt());
      }
    }

    // muck: { seat: 1, show: false }
    if (map.containsKey('muck')) {
      final raw = map['muck'];
      if (raw is Map) {
        final seat = (raw['seat'] as num?)?.toInt() ?? 0;
        final show = raw['show'] as bool? ?? false;
        return MuckDecision(seat, showCards: show);
      }
    }

    return null;
  }

  static Action? _parseAction(String type, int amount) => switch (type) {
        'fold' => const Fold(),
        'check' => const Check(),
        'call' => Call(amount),
        'bet' => Bet(amount),
        'raise' => Raise(amount),
        'allin' => AllIn(amount),
        _ => null,
      };

  static Street _parseStreet(String s) => switch (s) {
        'setupHand' => Street.setupHand,
        'preflop' => Street.preflop,
        'flop' => Street.flop,
        'turn' => Street.turn,
        'river' => Street.river,
        'showdown' => Street.showdown,
        'runItMultiple' => Street.runItMultiple,
        _ => Street.flop,
      };

  /// Save a session to YAML file.
  static Future<void> save(Session session, String path) async {
    final state = session.currentState;
    final buf = StringBuffer();

    buf.writeln('# EBS Game Engine — Saved Session');
    buf.writeln('variant: ${session.variant.name}');
    buf.writeln('dealer: ${state.dealerSeat}');
    buf.writeln();

    buf.writeln('blinds:');
    buf.writeln('  sb: ${state.sbSeat >= 0 ? state.bbAmount ~/ 2 : 5}');
    buf.writeln('  bb: ${state.bbAmount > 0 ? state.bbAmount : 10}');
    buf.writeln();

    buf.writeln('seats:');
    for (final seat in state.seats) {
      buf.writeln('  - index: ${seat.index}');
      buf.writeln('    label: "${seat.label}"');
      buf.writeln('    stack: ${seat.stack}');
    }
    buf.writeln();

    buf.writeln('events:');
    for (final event in session.events) {
      _writeEvent(buf, event);
    }

    await File(path).writeAsString(buf.toString());
  }

  static void _writeEvent(StringBuffer buf, Event event) {
    switch (event) {
      case HandStart():
        // HandStart is auto-generated, skip to avoid double-apply on load
        break;
      case DealHoleCards(cards: final cards):
        buf.writeln('  - deal_hole:');
        cards.forEach((idx, cardList) {
          final notation = cardList.map((c) => c.notation).join(', ');
          buf.writeln('      $idx: [$notation]');
        });
      case DealCommunity(cards: final cards):
        final notation = cards.map((c) => c.notation).join(', ');
        buf.writeln('  - deal_community: [$notation]');
      case PlayerAction(seatIndex: final s, action: final a):
        buf.writeln('  - action:');
        buf.writeln('      seat: $s');
        buf.writeln('      type: ${_actionType(a)}');
        final amt = _actionAmount(a);
        if (amt != null) buf.writeln('      amount: $amt');
      case StreetAdvance(next: final n):
        buf.writeln('  - street_advance: ${n.name}');
      case PotAwarded(awards: final a):
        buf.writeln('  - pot_awarded:');
        a.forEach((k, v) => buf.writeln('      $k: $v'));
      case HandEnd():
        buf.writeln('  - hand_end: true');
      case PineappleDiscard(seatIndex: final s, discarded: final c):
        buf.writeln('  - pineapple_discard:');
        buf.writeln('      seat: $s');
        buf.writeln('      card: ${c.notation}');
      case MisDeal():
        buf.writeln('  - misdeal: true');
      case BombPotConfig(amount: final a):
        buf.writeln('  - bomb_pot_config: $a');
      case RunItChoice(times: final t):
        buf.writeln('  - run_it_choice: $t');
      case ManualNextHand():
        buf.writeln('  - manual_next_hand: true');
      case AnteOverride(amount: final a, type: final t):
        buf.writeln('  - ante_override:');
        buf.writeln('      amount: $a');
        if (t != null) buf.writeln('      type: $t');
      case TimeoutFold(seatIndex: final s):
        buf.writeln('  - timeout_fold: $s');
      case MuckDecision(seatIndex: final s, showCards: final show):
        buf.writeln('  - muck_decision:');
        buf.writeln('      seat: $s');
        buf.writeln('      show: $show');
    }
  }

  static String _actionType(Action a) => switch (a) {
        Fold() => 'fold',
        Check() => 'check',
        Call() => 'call',
        Bet() => 'bet',
        Raise() => 'raise',
        AllIn() => 'allin',
      };

  static int? _actionAmount(Action a) => switch (a) {
        Fold() => null,
        Check() => null,
        Call(:final amount) => amount,
        Bet(:final amount) => amount,
        Raise(:final toAmount) => toAmount,
        AllIn(:final amount) => amount,
      };

  // ── YAML conversion helpers ──────────────────────────────────────────────────

  static Map<String, dynamic> _yamlMapToMap(YamlMap m) {
    final result = <String, dynamic>{};
    m.forEach((k, v) {
      result[k.toString()] = _convertYaml(v);
    });
    return result;
  }

  static dynamic _convertYaml(dynamic v) {
    if (v is YamlMap) return _yamlMapToMap(v);
    if (v is YamlList) return v.map(_convertYaml).toList();
    return v;
  }
}
